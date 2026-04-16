import 'dart:async';
import 'dart:math' as math;
import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/auth/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/service_type_display.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/utils/money_formatter.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/network/trips_api.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/location/passenger_geolocation_permission_cache.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/network/geocoding_service.dart';
import '../../core/network/directions_service.dart';
import '../../core/network/passenger_map_telemetry_service.dart';
import '../../core/network/places_autocomplete_service.dart';
import '../../data/models/quote_response.dart';
import '../../core/router/app_router.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/ui/app_safe_scrolling.dart';
import 'trip_request_state.dart';
import 'passenger_active_trip_guard.dart';
import 'passenger_realtime_controller.dart'
    show
        PassengerRealtimeState,
        passengerRealtimeProvider,
        displayDriverName,
        passengerTripChatPhaseActive;
import 'trip_recovery_feedback.dart';
import 'widgets/quote_bottom_sheet_widgets.dart';
import 'widgets/trip_request_shell_widgets.dart';
import 'widgets/trip_tracking_widgets.dart';
import 'trip_driver_marker.dart';

/// Ajustes GPS para recogida: alta precisión y sin filtro de distancia para
/// acercar el pin amarillo al punto azul del sistema cuando el GPS ya tiene fix.
LocationSettings _passengerPickupLocationSettings() =>
    const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);

/// Pantalla unificada: Origen, destino y precios en la misma ventana.
/// Si originLat/originLng son null, se obtiene la ubicación actual al abrir.
class TripRequestScreen extends ConsumerStatefulWidget {
  const TripRequestScreen({super.key, this.originLat, this.originLng});

  final double? originLat;
  final double? originLng;

  @override
  ConsumerState<TripRequestScreen> createState() => _TripRequestScreenState();
}

enum ActiveStop { none, origin, destination }

class _TripRequestScreenState extends ConsumerState<TripRequestScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  final GlobalKey _needleRenderKey = GlobalKey();
  final BitmapDescriptor _originFallbackIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  final BitmapDescriptor _destFallbackIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  final BitmapDescriptor _driverFallbackIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  LatLng? _origin; // Origen resuelto (widget o ubicación actual)
  String?
  _originDisplayLabel; // null = "Tu ubicación actual", si no texto elegido por el usuario
  bool _loadingOrigin = false;
  String? _originError;

  /// true solo tras leer coordenadas reales del dispositivo (no bastan origen en mapa/búsqueda).
  bool _deviceGpsFixOk = false;

  /// Reinicio suave de la capa nativa del puntito azul (útil tras cold start con viaje restaurado).
  bool _mapMyLocationDotEnabled = true;
  // Cuando el destino es null, forzamos una confirmación explícita del origen
  // para que el flujo siga el comportamiento requerido (Uber/Lyft-style).
  bool _originConfirmed = false;
  bool _pickingOrigin = false;
  bool _pickingDestination = false;
  LatLng? _destination;
  String? _destinationDisplayLabel; // null = coordenadas o placeholder
  LatLng? _mapCenter;

  /// Invalida refinados GPS diferidos si [_resolveOrigin] se vuelve a ejecutar.
  int _originResolveGeneration = 0;
  bool _loading = false;
  String? _error;
  final TextEditingController _originSearchController = TextEditingController();
  final TextEditingController _destinationSearchController =
      TextEditingController();
  final GeocodingService _geocoding = GeocodingService();
  final DirectionsService _directions = DirectionsService();
  final PlacesAutocompleteService _places = PlacesAutocompleteService();
  bool _searchingOriginAddress = false;
  bool _searchingDestinationAddress = false;
  bool _loadingOriginSuggestions = false;
  bool _loadingDestinationSuggestions = false;
  List<PlaceSuggestion> _originSuggestions = const <PlaceSuggestion>[];
  List<PlaceSuggestion> _destinationSuggestions = const <PlaceSuggestion>[];
  Timer? _originSearchDebounce;
  Timer? _destinationSearchDebounce;
  String _originPlacesSessionToken = '';
  String _destinationPlacesSessionToken = '';
  List<TripRecentPlaceItem> _recentOriginPlaces = const <TripRecentPlaceItem>[];
  List<TripRecentPlaceItem> _recentDestinationPlaces =
      const <TripRecentPlaceItem>[];
  List<TripSavedPlaceItem> _savedOriginPlaces = const <TripSavedPlaceItem>[];
  List<TripSavedPlaceItem> _savedDestinationPlaces =
      const <TripSavedPlaceItem>[];
  List<LatLng>? _routePoints;
  /// Misma polyline codificada que Directions (se envía al crear viaje para el mapa del conductor).
  String? _routeOverviewEncoded;
  bool _loadingRoute = false;

  /// Se incrementa al cancelar ruta / fin de viaje y al iniciar cada [_fetchRoute]; evita aplicar polilínea y pines viejos.
  int _routeRequestToken = 0;
  bool _recenterInProgress = false;
  String? _ratingSheetShownForTripId;
  String? _ratingDoneTripId;
  bool _ratingDone = false;

  /// Evita encolar varios auto-resets cuando el viaje ya está completado y el rating constaba hecho.
  String? _completedStaleAutoResetTripId;

  /// Último [passengerTripMapUiResetTickProvider] ya aplicado al estado local del mapa.
  int _lastConsumedPassengerTripMapUiTick = 0;
  ActiveStop _activeStop = ActiveStop.none;

  /// `true` mientras el bottom sheet del chat está visible (para cerrarlo al cambiar fase del viaje).
  bool _tripChatSheetDisplayed = false;

  // Resiliencia: si falta el último evento por WebSocket (p. ej. driver finaliza offline),
  // refrescamos el status vía REST cada cierto tiempo.
  Timer? _tripStatusSyncTimer;
  String? _tripStatusSyncTimerTripId;
  Duration _tripStatusSyncInterval = const Duration(seconds: 60);
  bool _tripStatusSyncInFlight = false;
  DateTime _lastTripStatusSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
  BitmapDescriptor? _driverOnTripIcon;
  BitmapDescriptor? _originOnTripIcon;
  BitmapDescriptor? _destinationOnTripIcon;
  late final AnimationController _driverPulseController;
  Timer? _driverMotionTimer;
  LatLng? _animatedDriverLatLng;
  double? _lastDriverRawLat;
  double? _lastDriverRawLng;
  bool _appInForeground = true;
  bool _driverLikelyIdle = false;
  final Battery _battery = Battery();
  int? _batteryLevel;
  final String _appVersion = 'passenger-app';
  String? _lastOptimizationModeTelemetry;

  static const String _tripCleanMapStyleDay = '''
[
  { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
  { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
  { "featureType": "administrative.land_parcel", "stylers": [{ "visibility": "off" }] },
  { "featureType": "road", "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] }
]
''';

  static const String _tripCleanMapStyleNight = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#111111" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#8A8A8A" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#111111" }] },
  { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
  { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
  { "featureType": "administrative.land_parcel", "stylers": [{ "visibility": "off" }] },
  { "featureType": "road", "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#232323" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#0C1B2A" }] }
]
''';
  static const int _lowBatteryThresholdPercent = 20;

  void _requireOriginConfirmation() {
    setState(() {
      _originConfirmed = false;
      _activeStop = ActiveStop.none;
      _pickingOrigin = true;
      _pickingDestination = false;
      _mapCenter = _origin ?? _mapCenter;
    });
  }

  double _distanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
    final dLng = (b.longitude - a.longitude) * (math.pi / 180.0);
    final lat1 = a.latitude * (math.pi / 180.0);
    final lat2 = b.latitude * (math.pi / 180.0);

    final sinDLat = math.sin(dLat / 2.0);
    final sinDLng = math.sin(dLng / 2.0);
    final h =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    return 2.0 * earthRadiusKm * math.asin(math.min(1.0, math.sqrt(h)));
  }

  double _estimateZoomForDistanceKm(double distanceKm) {
    if (distanceKm < 1.0) return 15.0;
    if (distanceKm < 3.0) return 14.5;
    if (distanceKm < 8.0) return 13.5;
    return 12.8;
  }

  /// Rehidrata origen, destino y cotización desde almacenamiento (mismo [tripId] activo).
  void _applyTripUiSnapshot(Map<String, dynamic> raw) {
    final oLat = raw['originLat'];
    final oLng = raw['originLng'];
    final dLat = raw['destLat'];
    final dLng = raw['destLng'];
    if (oLat == null || oLng == null || dLat == null || dLng == null) return;

    final quoteVal = raw['quote'];
    if (quoteVal is! Map) return;
    final quoteMap = Map<String, dynamic>.from(quoteVal);
    final QuoteResponse quote;
    try {
      quote = QuoteResponse.fromJson(quoteMap);
    } catch (_) {
      return;
    }

    final selRaw = raw['selectedServiceTypeId'];
    int? selId;
    if (selRaw is int) {
      selId = selRaw;
    } else if (selRaw is num) {
      selId = selRaw.toInt();
    } else if (selRaw != null) {
      selId = int.tryParse(selRaw.toString());
    }

    QuoteOption? sel;
    if (selId != null) {
      for (final o in quote.options) {
        if (o.serviceTypeId == selId) {
          sel = o;
          break;
        }
      }
    }
    sel ??= quote.options.isNotEmpty ? quote.options.first : null;
    if (sel == null) return;

    final origin = LatLng((oLat as num).toDouble(), (oLng as num).toDouble());
    final dest = LatLng((dLat as num).toDouble(), (dLng as num).toDouble());

    if (!mounted) return;
    setState(() {
      _origin = origin;
      _destination = dest;
      final ol = raw['originLabel']?.toString();
      final dl = raw['destLabel']?.toString();
      _originDisplayLabel = (ol != null && ol.isNotEmpty) ? ol : null;
      _destinationDisplayLabel = (dl != null && dl.isNotEmpty) ? dl : null;
      _originConfirmed = true;
      _pickingOrigin = false;
      _pickingDestination = false;
      _activeStop = ActiveStop.none;
      _mapCenter = dest;
      _routePoints = null;
      _loadingOrigin = false;
      _originError = null;
    });

    ref
        .read(tripRequestProvider.notifier)
        .setOrigin(origin.latitude, origin.longitude);
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(dest.latitude, dest.longitude);
    ref.read(tripRequestProvider.notifier).setQuote(quote);
    ref.read(tripRequestProvider.notifier).selectOption(sel);

    unawaited(_loadPinIcons());
    _fetchRoute();
  }

  /// Obtiene un arreglo GPS sin modificar origen/destino del viaje (reapertura con snapshot).
  Future<void> _refreshPassengerGpsDot({
    required bool preserveTripGeometry,
  }) async {
    if (!mounted) return;

    final permission =
        await PassengerGeolocationPermissionCache.ensureLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        if (!preserveTripGeometry || !_deviceGpsFixOk) {
          _deviceGpsFixOk = false;
        }
      });
      return;
    }

    try {
      await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _deviceGpsFixOk = true;
        _mapMyLocationDotEnabled = false;
      });
      // Dos tiempos para que la capa de Maps (puntito azul) se reinicie bien tras cold start.
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      setState(() => _mapMyLocationDotEnabled = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!preserveTripGeometry || !_deviceGpsFixOk) {
          _deviceGpsFixOk = false;
        }
      });
    }
  }

  Future<bool> _ensureDeviceGpsForNewTrip() async {
    if (_deviceGpsFixOk) return true;
    final hasTrip = ref.read(tripRequestProvider).tripId != null;
    await _refreshPassengerGpsDot(preserveTripGeometry: hasTrip);
    return _deviceGpsFixOk;
  }

  Future<void> _recenterMapForPassenger({
    double? driverLat,
    double? driverLng,
  }) async {
    if (_recenterInProgress) return;
    setState(() => _recenterInProgress = true);
    final c = _controller;
    if (c == null) {
      if (mounted) setState(() => _recenterInProgress = false);
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      final passenger = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _deviceGpsFixOk = true);
      }

      // Si tenemos conductor, encuadramos ambos puntos para dar contexto.
      if (driverLat != null && driverLng != null) {
        final driver = LatLng(driverLat, driverLng);
        final mid = LatLng(
          (passenger.latitude + driver.latitude) / 2.0,
          (passenger.longitude + driver.longitude) / 2.0,
        );
        final distKm = _distanceKm(passenger, driver);
        final zoom = _estimateZoomForDistanceKm(distKm);
        await c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: mid, zoom: zoom),
          ),
        );
        return;
      }

      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: passenger, zoom: 16),
        ),
      );
    } catch (_) {
      // Silencioso: es una acción de conveniencia.
    } finally {
      if (mounted) setState(() => _recenterInProgress = false);
    }
  }

  void _fitCameraToOriginDestination() {
    if (_controller == null || _origin == null || _destination == null) return;
    final o = _origin!;
    final d = _destination!;
    final mid = LatLng(
      (o.latitude + d.latitude) / 2.0,
      (o.longitude + d.longitude) / 2.0,
    );
    final distKm = _distanceKm(o, d);
    final zoom = _estimateZoomForDistanceKm(distKm);
    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: mid, zoom: zoom)),
    );
  }

  /// Tras un viaje terminado, alinear origen y pin del mapa con el GPS actual (no dejar el centro en el destino).
  Future<void> _recenterMapToDeviceGpsAfterTripEnd() async {
    if (!mounted) return;

    Future<void> apply(LatLng latLng) async {
      if (!mounted) return;
      setState(() {
        _origin = latLng;
        _mapCenter = latLng;
        _originDisplayLabel = null;
        _deviceGpsFixOk = true;
      });
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(latLng.latitude, latLng.longitude);
      final c = _controller;
      if (c != null) {
        await c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 16),
          ),
        );
      }
      if (!mounted) return;
      unawaited(_refreshPassengerGpsDot(preserveTripGeometry: false));
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      await apply(LatLng(position.latitude, position.longitude));
    } catch (_) {
      if (!mounted) return;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          await apply(LatLng(last.latitude, last.longitude));
          return;
        }
      } catch (_) {
        // seguir al fallback
      }
      if (!mounted) return;
      final fallback = _origin;
      if (fallback != null) {
        setState(() => _mapCenter = fallback);
        final c = _controller;
        if (c != null) {
          await c.animateCamera(CameraUpdate.newLatLngZoom(fallback, 16));
        }
      }
    }
  }

  /// Limpia sesión de viaje en memoria y almacenamiento; mismo resultado que cerrar el sheet de calificación.
  Future<void> _resetHomeAfterTripEnded(String tripId) async {
    _routeRequestToken++;
    ref.read(passengerRealtimeProvider.notifier).disconnect();
    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    // Como el backend no persiste rating (pending/submitted/skipped),
    // lo guardamos en el almacenamiento local para poder recordar
    // el recordatorio al reabrir la app.
    await TripSessionStorage.setRatingDone(tripId, true);
    await TripSessionStorage.clearActiveTripId();
    _ratingDoneTripId = tripId;
    _ratingDone = true;
    _ratingSheetShownForTripId = tripId;
    _completedStaleAutoResetTripId = null;
    if (mounted) {
      setState(() {
        _destination = null;
        _destinationDisplayLabel = null;
        _routePoints = null;
        _loadingRoute = false;
        _originConfirmed = false;
        _pickingOrigin = false;
        _pickingDestination = false;
        _error = null;
        if (_origin != null) {
          // Para el siguiente viaje, empezamos forzando confirmación del origen.
          _pickingOrigin = true;
          _activeStop = ActiveStop.none;
        }
      });
    }
    await _recenterMapToDeviceGpsAfterTripEnd();
    unawaited(_loadRecentPlaces());
    unawaited(_loadSavedPlaces());
  }

  /// Tras [clearPassengerTripSessionFromContainer] (p. ej. tap en notificación con viaje ya terminal):
  /// los providers ya están limpios; esto alinea pines, polilínea y flags que viven solo en este State.
  void _resetLocalMapAfterExternalTripSessionClear() {
    _routeRequestToken++;
    _completedStaleAutoResetTripId = null;
    if (!mounted) return;
    setState(() {
      _ratingDoneTripId = null;
      _ratingDone = false;
      _ratingSheetShownForTripId = null;
      _destination = null;
      _destinationDisplayLabel = null;
      _routePoints = null;
      _loadingRoute = false;
      _originConfirmed = false;
      _pickingOrigin = false;
      _pickingDestination = false;
      _error = null;
      _loading = false;
      _activeStop = ActiveStop.none;
      if (_origin != null) {
        _pickingOrigin = true;
      }
    });
    unawaited(_recenterMapToDeviceGpsAfterTripEnd());
    unawaited(_loadRecentPlaces());
    unawaited(_loadSavedPlaces());
  }

  Future<void> _showRatingSheet(
    BuildContext context,
    String tripId,
    String? driverName,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PassengerRatingSheetContent(
        driverName: displayDriverName(driverName, l10n.tripDriverNameFallback),
        title: l10n.tripRateDriver,
        subtitle: l10n.tripRateDriverSubtitle,
        sendLabel: l10n.tripSendRating,
        skipLabel: l10n.tripSkipRating,
        onSubmitted: (stars, feedbackCodes) {
          unawaited(
            _submitPassengerRating(
              tripId: tripId,
              stars: stars,
              feedbackCodes: feedbackCodes,
            ),
          );
          Navigator.of(ctx).pop();
          unawaited(_resetHomeAfterTripEnded(tripId));
        },
        onSkipped: () {
          Navigator.of(ctx).pop();
          unawaited(_resetHomeAfterTripEnded(tripId));
        },
      ),
    );

    // Si el usuario cerró el sheet sin pulsar botones, igual reseteamos para permitir pedir otro viaje.
    final rt = ref.read(passengerRealtimeProvider);
    if (rt.status == 'completed' &&
        ref.read(tripRequestProvider).tripId == tripId) {
      await _resetHomeAfterTripEnded(tripId);
    }
  }

  Future<void> _submitPassengerRating({
    required String tripId,
    required int stars,
    List<String> feedbackCodes = const [],
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) return;
      await TripsApi(token: token).submitPassengerTripRating(
        tripId: tripId,
        stars: stars,
        feedbackCodes: feedbackCodes,
      );
    } catch (_) {}
  }

  Future<void> _openTripChatSheet({required String tripId}) async {
    if (!passengerTripChatPhaseActive(ref.read(passengerRealtimeProvider).status)) {
      return;
    }
    final controller = ref.read(passengerRealtimeProvider.notifier);
    final textController = TextEditingController();
    const quickTemplates = <Map<String, String>>[
      {'code': 'CANT_FIND_VEHICLE', 'label': 'No veo tu vehículo'},
      {'code': 'WHERE_ARE_YOU', 'label': '¿Dónde estás exactamente?'},
      {'code': 'IM_WAITING_HERE', 'label': 'Estoy esperando aquí'},
    ];
    String formatTime(DateTime? dt) {
      if (dt == null) return 'Ahora';
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    _tripChatSheetDisplayed = true;
    try {
      await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: mq.viewInsets.bottom,
            left: 10,
            right: 10,
            top: 8,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Consumer(
              builder: (context, ref, _) {
                final rt = ref.watch(passengerRealtimeProvider);
                return Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        10,
                        14,
                        12 + mq.viewPadding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Chat del viaje',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rt.connected
                                      ? AppColors.success.withValues(alpha: 0.12)
                                      : AppColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  rt.connected ? 'En línea' : 'Sin conexión',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: rt.connected ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          Text(
                            'Conversación activa con el conductor en tiempo real.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: quickTemplates.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final it = quickTemplates[index];
                                return OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: () {
                                    textController.text = it['label']!;
                                    textController.selection = TextSelection.collapsed(
                                      offset: textController.text.length,
                                    );
                                  },
                                  child: Text(
                                    it['label']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (rt.tripChatErrorCode != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                (rt.tripChatErrorCode == '42P01' ||
                                        rt.tripChatErrorCode ==
                                            'TRIP_CHAT_STORAGE_UNAVAILABLE')
                                    ? 'Chat no disponible: falta configuración en el servidor. Contactá soporte.'
                                    : rt.tripChatErrorCode == 'TRIP_CHAT_NOT_AVAILABLE'
                                        ? 'El chat solo está disponible antes de iniciar el viaje.'
                                        : 'No se pudo enviar/recibir chat (${rt.tripChatErrorCode!}). Revisa la conexión.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.border.withValues(alpha: 0.45),
                                ),
                              ),
                              child: rt.chatMessages.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Aún no hay mensajes.\nEnvía uno para iniciar la conversación.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(10),
                                      itemCount: rt.chatMessages.length,
                                      itemBuilder: (context, index) {
                                        final msg = rt.chatMessages[index];
                                        final mine = msg.senderRole == 'passenger';
                                        return Align(
                                          alignment: mine
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Container(
                                            constraints: const BoxConstraints(maxWidth: 280),
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 9,
                                            ),
                                            decoration: BoxDecoration(
                                              color: mine
                                                  ? AppColors.primary.withValues(alpha: 0.2)
                                                  : AppColors.surface,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(14),
                                                topRight: const Radius.circular(14),
                                                bottomLeft: Radius.circular(mine ? 14 : 4),
                                                bottomRight: Radius.circular(mine ? 4 : 14),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  msg.messageText,
                                                  style: const TextStyle(height: 1.25),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${mine ? 'Tú' : 'Conductor'} · ${formatTime(msg.createdAt)}',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    color: AppColors.textSecondary.withValues(
                                                      alpha: 0.85,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.border.withValues(alpha: 0.55),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: textController,
                                      minLines: 1,
                                      maxLines: 4,
                                      decoration: const InputDecoration(
                                        hintText: 'Escribe un mensaje',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    height: 40,
                                    child: FilledButton(
                                      onPressed: () {
                                        final t = textController.text.trim();
                                        if (t.isEmpty) return;
                                        controller.sendTripChatText(
                                          tripId: tripId,
                                          text: t,
                                        );
                                        textController.clear();
                                      },
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        minimumSize: const Size(44, 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                      ),
                                      child: const Icon(Icons.send_rounded, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    } finally {
      _tripChatSheetDisplayed = false;
      textController.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _appInForeground = true;
    _driverPulseController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1150),
          )
          ..addListener(() {
            if (!mounted) return;
            if (_animatedDriverLatLng == null) return;
            setState(() {});
          })
          ..repeat(reverse: true);
    _originPlacesSessionToken = _newPlacesSessionToken();
    _destinationPlacesSessionToken = _newPlacesSessionToken();
    unawaited(_loadRecentPlaces());
    unawaited(_loadSavedPlaces());
    unawaited(_refreshBatteryLevel());
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDriverTripIcon());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final tripState = ref.read(tripRequestProvider);
      final rtState = ref.read(passengerRealtimeProvider);
      if (tripState.tripId != null && _ratingDoneTripId != tripState.tripId) {
        final activeTrip = tripState.tripId!;
        unawaited(() async {
          _ratingDoneTripId = activeTrip;
          _ratingDone = await TripSessionStorage.isRatingDone(activeTrip);
          if (!mounted) return;
          setState(() {});
        }());
      }

      if (tripState.tripId != null) {
        final activeTrip = tripState.tripId!;
        unawaited(() async {
          final cached = await TripSessionStorage.getCachedDriverInfo(
            activeTrip,
          );
          if (!mounted) return;
          if (cached == null) return;
          ref
              .read(passengerRealtimeProvider.notifier)
              .hydrateDriverInfoFromLocalCache(
                tripId: activeTrip,
                driverName: cached['driverName'],
                carColor: cached['carColor'],
                carPlate: cached['carPlate'],
                carModel: cached['carModel'],
                driverRating: double.tryParse(cached['driverRating'] ?? ''),
                driverRatingsCount:
                    int.tryParse(cached['driverRatingsCount'] ?? ''),
                currencyCode: cached['currencyCode'],
                driverPhotoUrl: cached['driverPhotoUrl'],
                driverPhotoExpiresAt: cached['driverPhotoExpiresAt'],
              );
        }());
      }

      final storedTripId = await TripSessionStorage.getActiveTripId();
      if (!mounted) return;

      // Viaje persistido: evitamos _resolveOrigin() para no pisar O/D con el GPS.
      if (storedTripId != null && storedTripId.isNotEmpty) {
        final currentTripId = ref.read(tripRequestProvider).tripId;
        if (currentTripId == null) {
          ref.read(tripRequestProvider.notifier).setTripId(storedTripId);
        } else if (currentTripId != storedTripId) {
          ref.read(tripRequestProvider.notifier).setTripId(storedTripId);
        }

        _ratingDoneTripId = storedTripId;
        _ratingDone = await TripSessionStorage.isRatingDone(storedTripId);
        if (!mounted) return;
        setState(() {});

        final uiSnap = await TripSessionStorage.getActiveTripUiSnapshot();
        if (!mounted) return;
        if (uiSnap != null && uiSnap['tripId']?.toString() == storedTripId) {
          _applyTripUiSnapshot(uiSnap);
          // Puntito azul: tras cold start no pasamos por _resolveOrigin(); forzamos lectura GPS sin pisar O/D del viaje.
          unawaited(_refreshPassengerGpsDot(preserveTripGeometry: true));
        } else {
          // Instalaciones sin snapshot guardado (cotización antes de este cambio).
          _resolveOrigin();
        }

        await ref
            .read(passengerRealtimeProvider.notifier)
            .syncTripStatusFromApi(tripId: storedTripId, force: true);

        final cached = await TripSessionStorage.getCachedDriverInfo(
          storedTripId,
        );
        if (cached != null && mounted) {
          ref
              .read(passengerRealtimeProvider.notifier)
              .hydrateDriverInfoFromLocalCache(
                tripId: storedTripId,
                driverName: cached['driverName'],
                carColor: cached['carColor'],
                carPlate: cached['carPlate'],
                carModel: cached['carModel'],
                driverRating: double.tryParse(cached['driverRating'] ?? ''),
                driverRatingsCount:
                    int.tryParse(cached['driverRatingsCount'] ?? ''),
                currencyCode: cached['currencyCode'],
                driverPhotoUrl: cached['driverPhotoUrl'],
                driverPhotoExpiresAt: cached['driverPhotoExpiresAt'],
              );
        }

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final tid = ref.read(tripRequestProvider).tripId;
            if (tid != null && tid.isNotEmpty) {
              showTripRecoveredSnackBarOncePerTrip(ref, context, tid);
            }
          });
        }

        final latestTrip = ref.read(tripRequestProvider);
        final rt = ref.read(passengerRealtimeProvider);
        if (!rt.connected && !rt.connecting) {
          ref
              .read(passengerRealtimeProvider.notifier)
              .connect(tripId: storedTripId, quote: latestTrip.quote);
        }
        return;
      }

      // Sin viaje persistido: mismo flujo que antes.
      if (tripState.tripId != null &&
          !rtState.connected &&
          !rtState.connecting &&
          rtState.errorCode == null) {
        final tripId = tripState.tripId!;
        unawaited(() async {
          await ref
              .read(passengerRealtimeProvider.notifier)
              .syncTripStatusFromApi(tripId: tripId, force: true);
          if (!mounted) return;
          ref
              .read(passengerRealtimeProvider.notifier)
              .connect(tripId: tripId, quote: tripState.quote);
        }());
      }
      if (tripState.origin != null) {
        _origin = LatLng(tripState.origin!.lat, tripState.origin!.lng);
        _mapCenter = _origin;
        _loadingOrigin = false;
        _originError = null;
        if (tripState.destination != null) {
          _originConfirmed = true;
          _pickingOrigin = false;
          _pickingDestination = false;
          _activeStop = ActiveStop.none;
          _destination = LatLng(
            tripState.destination!.lat,
            tripState.destination!.lng,
          );
          _mapCenter = _destination;
          _fetchRoute();
        } else {
          _originConfirmed = false;
          _pickingOrigin = true;
          _pickingDestination = false;
          _activeStop = ActiveStop.none;
        }
        _loadPinIcons();
        setState(() {});
        return;
      }
      if (widget.originLat != null && widget.originLng != null) {
        _origin = LatLng(widget.originLat!, widget.originLng!);
        _mapCenter = _origin;
        _loadingOrigin = false;
        ref
            .read(tripRequestProvider.notifier)
            .setOrigin(_origin!.latitude, _origin!.longitude);
        _originConfirmed = false;
        _pickingOrigin = true;
        _pickingDestination = false;
        _activeStop = ActiveStop.none;
        _loadPinIcons();
        setState(() {});
        return;
      }
      _resolveOrigin();
    });
    _loadingOrigin = true;
  }

  /// Tras el primer fix, un segundo intento corrige desfase típico vs el punto azul del mapa.
  Future<void> _refinePassengerOriginOnce(int generation) async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted || generation != _originResolveGeneration) return;
    if (_originConfirmed || !_pickingOrigin || _destination != null) return;
    final prev = _origin;
    if (prev == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 12));
      if (!mounted || generation != _originResolveGeneration) return;
      if (_originConfirmed || !_pickingOrigin) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      final movedM = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        latLng.latitude,
        latLng.longitude,
      );
      if (movedM < 12) return;
      setState(() {
        _origin = latLng;
        _mapCenter = latLng;
        _deviceGpsFixOk = true;
        _originError = null;
      });
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(latLng.latitude, latLng.longitude);
      final c = _controller;
      if (c != null) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      }
    } catch (_) {
      // Silencioso: el usuario ya tiene un origen usable.
    }
  }

  Future<void> _resolveOrigin() async {
    if (!mounted) return;
    _originResolveGeneration++;
    final refineGen = _originResolveGeneration;
    final permission =
        await PassengerGeolocationPermissionCache.ensureLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LatLng? lastKnownLatLng;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          lastKnownLatLng = LatLng(last.latitude, last.longitude);
        }
      } catch (_) {
        // seguimos sin lastKnown
      }
      if (mounted) {
        setState(() {
          _loadingOrigin = false;
          _deviceGpsFixOk = lastKnownLatLng != null;
          _originError = lastKnownLatLng == null
              ? AppLocalizations.of(context)!.homeLocationError
              : null;
          _origin = lastKnownLatLng;
          _mapCenter = lastKnownLatLng;
          if (_destination == null) {
            _originConfirmed = false;
            _pickingOrigin = true;
            _pickingDestination = false;
            _activeStop = ActiveStop.none;
          }
        });
      }
      if (lastKnownLatLng != null) {
        ref
            .read(tripRequestProvider.notifier)
            .setOrigin(lastKnownLatLng.latitude, lastKnownLatLng.longitude);
        await _loadPinIcons();
        unawaited(_refinePassengerOriginOnce(refineGen));
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _origin = LatLng(position.latitude, position.longitude);
        _mapCenter = _origin;
        _loadingOrigin = false;
        _originError = null;
        _deviceGpsFixOk = true;
        if (_destination == null) {
          _originConfirmed = false;
          _pickingOrigin = true;
          _pickingDestination = false;
          _activeStop = ActiveStop.none;
        }
      });
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(_origin!.latitude, _origin!.longitude);
      await _loadPinIcons();
      unawaited(_refinePassengerOriginOnce(refineGen));
    } catch (e) {
      if (!mounted) return;
      LatLng? lastKnownLatLng;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          lastKnownLatLng = LatLng(last.latitude, last.longitude);
        }
      } catch (_) {
        // seguimos sin lastKnown
      }
      setState(() {
        _loadingOrigin = false;
        _deviceGpsFixOk = lastKnownLatLng != null;
        _originError = lastKnownLatLng == null
            ? AppLocalizations.of(context)!.homeLocationErrorGps
            : null;
        _origin = lastKnownLatLng;
        _mapCenter = lastKnownLatLng;
        if (_destination == null) {
          _originConfirmed = false;
          _pickingOrigin = true;
          _pickingDestination = false;
          _activeStop = ActiveStop.none;
        }
      });
      if (lastKnownLatLng != null) {
        ref
            .read(tripRequestProvider.notifier)
            .setOrigin(lastKnownLatLng.latitude, lastKnownLatLng.longitude);
        unawaited(_refinePassengerOriginOnce(refineGen));
      }
      await _loadPinIcons();
    }
  }

  @override
  void dispose() {
    _driverMotionTimer?.cancel();
    _driverPulseController.dispose();
    _originSearchDebounce?.cancel();
    _destinationSearchDebounce?.cancel();
    _tripStatusSyncTimer?.cancel();
    _tripStatusSyncTimer = null;
    _tripStatusSyncTimerTripId = null;
    _tripStatusSyncInterval = const Duration(seconds: 60);
    WidgetsBinding.instance.removeObserver(this);
    _originSearchController.dispose();
    _destinationSearchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  bool _isFinalTripStatus(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s == 'completed' || s == 'cancelled' || s == 'expired';
  }

  bool _isTrackingDriverStatus(String? status) {
    final s = status?.toLowerCase();
    return s == 'accepted' ||
        s == 'arrived' ||
        s == 'started' ||
        s == 'in_trip';
  }

  bool get _lowBatteryModeActive =>
      _batteryLevel != null && _batteryLevel! <= _lowBatteryThresholdPercent;

  Future<void> _refreshBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (!mounted) return;
      if (_batteryLevel == level) return;
      setState(() => _batteryLevel = level);
    } catch (_) {
      // Fallo silencioso: no bloquea flujo del mapa.
    }
  }

  String _currentOptimizationMode() {
    if (!_appInForeground) return 'background';
    if (_lowBatteryModeActive) return 'low_battery';
    if (_driverLikelyIdle) return 'idle_driver';
    return 'normal';
  }

  void _emitMapOptimizationTelemetryIfNeeded(String? tripId) {
    if (tripId == null || tripId.isEmpty) return;
    final mode = _currentOptimizationMode();
    final modeKey = '$tripId:$mode';
    if (_lastOptimizationModeTelemetry == modeKey) return;
    _lastOptimizationModeTelemetry = modeKey;
    unawaited(
      PassengerMapTelemetryService.sendMapOptimizationMode(
        mode: mode,
        appState: _appInForeground ? 'foreground' : 'background',
        isLowBattery: _lowBatteryModeActive,
        isDriverIdle: _driverLikelyIdle,
        tripId: tripId,
        batteryLevel: _batteryLevel,
        platform: defaultTargetPlatform.toString(),
        appVersion: _appVersion,
      ),
    );
  }

  Future<void> _syncTripStatusOnceThrottled(String tripId) async {
    if (_tripStatusSyncInFlight) return;
    final now = DateTime.now();
    final rt = ref.read(passengerRealtimeProvider);
    final trackingDriver = _isTrackingDriverStatus(rt.status);
    // Si la URL firmada de la foto está por expirar o ya expiró, refrescamos
    // el GET de inmediato para evitar avatar roto al cargar de red.
    final expiresAt = rt.driverPhotoExpiresAt;
    final photoExpiryBuffer = const Duration(seconds: 45);
    final mustRefreshPhotoNow =
        trackingDriver &&
        expiresAt != null &&
        !now.isBefore(expiresAt.subtract(photoExpiryBuffer));
    // En seguimiento al conductor: polling más frecuente (coordenadas vía GET + socket).
    final minGap = trackingDriver
        ? const Duration(seconds: 10)
        : const Duration(seconds: 55);
    if (!mustRefreshPhotoNow && now.difference(_lastTripStatusSyncAt) < minGap) {
      return;
    }
    _tripStatusSyncInFlight = true;
    _lastTripStatusSyncAt = now;
    try {
      await ref
          .read(passengerRealtimeProvider.notifier)
          .syncTripStatusFromApi(tripId: tripId);
    } finally {
      _tripStatusSyncInFlight = false;
    }
  }

  void _startTripStatusPeriodicSync(
    String tripId, {
    Duration interval = const Duration(seconds: 60),
  }) {
    if (_tripStatusSyncTimer != null &&
        _tripStatusSyncTimerTripId == tripId &&
        _tripStatusSyncInterval == interval) {
      return;
    }
    _tripStatusSyncTimer?.cancel();
    _tripStatusSyncTimer = null;
    _tripStatusSyncTimerTripId = tripId;
    _tripStatusSyncInterval = interval;

    unawaited(_syncTripStatusOnceThrottled(tripId));

    _tripStatusSyncTimer = Timer.periodic(interval, (_) {
      unawaited(_syncTripStatusOnceThrottled(tripId));
    });
  }

  void _stopTripStatusPeriodicSync() {
    _tripStatusSyncTimer?.cancel();
    _tripStatusSyncTimer = null;
    _tripStatusSyncTimerTripId = null;
    _tripStatusSyncInterval = const Duration(seconds: 60);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    if (!_appInForeground) {
      _driverMotionTimer?.cancel();
      _driverMotionTimer = null;
      if (mounted) setState(() {});
      return;
    }
    unawaited(_refreshBatteryLevel());
    final tripId = ref.read(tripRequestProvider).tripId;
    if (tripId == null || tripId.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    unawaited(() async {
      // Recargamos el status por REST para compensar la falta de replay por WS.
      await ref
          .read(passengerRealtimeProvider.notifier)
          .syncTripStatusFromApi(tripId: tripId, force: true);

      final cached = await TripSessionStorage.getCachedDriverInfo(tripId);
      if (cached != null && mounted) {
        ref
            .read(passengerRealtimeProvider.notifier)
            .hydrateDriverInfoFromLocalCache(
              tripId: tripId,
              driverName: cached['driverName'],
              carColor: cached['carColor'],
              carPlate: cached['carPlate'],
              carModel: cached['carModel'],
              driverRating: double.tryParse(cached['driverRating'] ?? ''),
              driverRatingsCount:
                  int.tryParse(cached['driverRatingsCount'] ?? ''),
              currencyCode: cached['currencyCode'],
              driverPhotoUrl: cached['driverPhotoUrl'],
              driverPhotoExpiresAt: cached['driverPhotoExpiresAt'],
            );
      }

      unawaited(_refreshPassengerGpsDot(preserveTripGeometry: true));

      // Cargamos flag local de rating para que la sheet decida bien.
      if (_ratingDoneTripId != tripId) {
        final done = await TripSessionStorage.isRatingDone(tripId);
        if (!mounted) return;
        setState(() {
          _ratingDoneTripId = tripId;
          _ratingDone = done;
        });
      }

      final rt = ref.read(passengerRealtimeProvider);
      if (!rt.connected && !rt.connecting && rt.errorCode == null) {
        ref
            .read(passengerRealtimeProvider.notifier)
            .connect(
              tripId: tripId,
              quote: ref.read(tripRequestProvider).quote,
            );
      }
    }());
    if (mounted) setState(() {});
  }

  void _startPickOriginOnMap() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _error = null;
      _activeStop = ActiveStop.none;
      _originConfirmed = false;
      _pickingOrigin = true;
      _pickingDestination = false;
      _mapCenter = _origin;
    });
    _controller?.animateCamera(
      CameraUpdate.newLatLng(_origin ?? const LatLng(-16.5, -68.1)),
    );
    _showSubtleSnack(l10n.tripMoveMapSetPickup);
  }

  void _startPickDestinationOnMap() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _error = null;
      _activeStop = ActiveStop.none;
      _pickingDestination = true;
      _pickingOrigin = false;
      _mapCenter = _destination ?? _origin;
    });
    final center = _destination ?? _origin ?? const LatLng(-16.5, -68.1);
    _controller?.animateCamera(CameraUpdate.newLatLng(center));
    _showSubtleSnack(l10n.tripMoveMapSetDestination);
  }

  void _collapseStops() {
    setState(() {
      _activeStop = ActiveStop.none;
      _pickingOrigin = false;
      _pickingDestination = false;
    });
  }

  void _showSubtleSnack(String message) {
    TexiUiFeedback.lightTap();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Backend exige label 2–60 y address 3–180 caracteres.
  String _ensureSavedPlaceLabel(String primary, String backupMin2) {
    var a = primary.trim();
    if (a.length > 60) a = a.substring(0, 60);
    if (a.length >= 2) return a;
    var b = backupMin2.trim();
    if (b.length > 60) b = b.substring(0, 60);
    if (b.length >= 2) return b;
    return 'Lugar';
  }

  String _ensureSavedPlaceAddress(String primary, double lat, double lng) {
    final a = primary.trim();
    if (a.length > 180) return a.substring(0, 180);
    if (a.length >= 3) return a;
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  Future<void> _loadRecentPlaces() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    try {
      final api = TripsApi(token: token);
      final rows = await api.getPassengerRecentPlaces(limit: 24);
      if (!mounted) return;
      TripRecentPlaceItem fromRow(PassengerRecentPlace e) =>
          TripRecentPlaceItem(
            label: e.label,
            subtitle: e.subtitle,
            lat: e.lat,
            lng: e.lng,
          );
      bool usable(PassengerRecentPlace e) =>
          e.label.trim().isNotEmpty && e.lat.abs() <= 90 && e.lng.abs() <= 180;
      final origins = rows
          .where((e) => usable(e) && e.placeType.toLowerCase() == 'origin')
          .map(fromRow)
          .take(5)
          .toList(growable: false);
      final dests = rows
          .where((e) => usable(e) && e.placeType.toLowerCase() == 'destination')
          .map(fromRow)
          .take(5)
          .toList(growable: false);
      setState(() {
        _recentOriginPlaces = origins;
        _recentDestinationPlaces = dests;
      });
    } catch (_) {}
  }

  Future<void> _loadSavedPlaces() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    try {
      final api = TripsApi(token: token);
      final rows = await api.getPassengerSavedPlaces(limit: 12);
      if (!mounted) return;
      final mapped = rows
          .where((e) => e.label.trim().isNotEmpty)
          .map(
            (e) => TripSavedPlaceItem(
              id: e.id,
              label: e.label,
              address: e.address,
              lat: e.lat,
              lng: e.lng,
              isFavorite: e.isFavorite,
            ),
          )
          .toList(growable: false);
      setState(() {
        _savedOriginPlaces = mapped.take(8).toList(growable: false);
        _savedDestinationPlaces = mapped.take(8).toList(growable: false);
      });
    } catch (_) {}
  }

  void _pickOriginRecentPlace(TripRecentPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _origin = p;
      _originDisplayLabel = place.label;
      _routePoints = null;
    });
    ref.read(tripRequestProvider.notifier).setOrigin(p.latitude, p.longitude);
    _controller?.animateCamera(CameraUpdate.newLatLng(p));
    if (_destination != null) {
      _originConfirmed = true;
      _pickingOrigin = false;
      _pickingDestination = false;
      _collapseStops();
      unawaited(_fetchRoute());
    } else {
      _requireOriginConfirmation();
    }
  }

  void _pickDestinationRecentPlace(TripRecentPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _destination = p;
      _destinationDisplayLabel = place.label;
      _routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(p.latitude, p.longitude);
    _controller?.animateCamera(CameraUpdate.newLatLng(p));
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
  }

  void _pickOriginSavedPlace(TripSavedPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _origin = p;
      _originDisplayLabel = place.address.isNotEmpty
          ? place.address
          : place.label;
      _routePoints = null;
    });
    ref.read(tripRequestProvider.notifier).setOrigin(p.latitude, p.longitude);
    _controller?.animateCamera(CameraUpdate.newLatLng(p));
    if (_destination != null) {
      _originConfirmed = true;
      _pickingOrigin = false;
      _pickingDestination = false;
      _collapseStops();
      unawaited(_fetchRoute());
    } else {
      _requireOriginConfirmation();
    }
  }

  void _pickDestinationSavedPlace(TripSavedPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _destination = p;
      _destinationDisplayLabel = place.address.isNotEmpty
          ? place.address
          : place.label;
      _routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(p.latitude, p.longitude);
    _controller?.animateCamera(CameraUpdate.newLatLng(p));
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
  }

  Future<void> _saveCurrentOriginPlace() async {
    if (_origin == null) return;
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final rawLabel = (_originDisplayLabel ?? l10n.tripOrigin)
        .split(',')
        .first
        .trim();
    final rawAddress =
        (_originDisplayLabel ??
                '${_origin!.latitude.toStringAsFixed(6)},${_origin!.longitude.toStringAsFixed(6)}')
            .trim();
    final label = _ensureSavedPlaceLabel(rawLabel, l10n.tripOrigin);
    final address = _ensureSavedPlaceAddress(
      rawAddress,
      _origin!.latitude,
      _origin!.longitude,
    );
    try {
      await TripsApi(token: token).savePassengerPlace(
        label: label.isNotEmpty ? label : l10n.tripOrigin,
        address: address,
        lat: _origin!.latitude,
        lng: _origin!.longitude,
      );
      await _loadSavedPlaces();
      if (!mounted) return;
      _showSubtleSnack(l10n.profileSavedPlaces);
    } catch (_) {
      if (!mounted) return;
      _showSubtleSnack(l10n.commonError);
    }
  }

  Future<void> _saveCurrentDestinationPlace() async {
    if (_destination == null) return;
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final rawLabel = (_destinationDisplayLabel ?? l10n.tripDestination)
        .split(',')
        .first
        .trim();
    final rawAddress =
        (_destinationDisplayLabel ??
                '${_destination!.latitude.toStringAsFixed(6)},${_destination!.longitude.toStringAsFixed(6)}')
            .trim();
    final label = _ensureSavedPlaceLabel(rawLabel, l10n.tripDestination);
    final address = _ensureSavedPlaceAddress(
      rawAddress,
      _destination!.latitude,
      _destination!.longitude,
    );
    try {
      await TripsApi(token: token).savePassengerPlace(
        label: label.isNotEmpty ? label : l10n.tripDestination,
        address: address,
        lat: _destination!.latitude,
        lng: _destination!.longitude,
      );
      await _loadSavedPlaces();
      if (!mounted) return;
      _showSubtleSnack(l10n.profileSavedPlaces);
    } catch (_) {
      if (!mounted) return;
      _showSubtleSnack(l10n.commonError);
    }
  }

  static const _kMaxSavedPlaces = 5;

  Future<void> _openSavedPlacesManager({required bool forOrigin}) async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await _loadSavedPlaces();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final places = forOrigin
                ? _savedOriginPlaces
                : _savedDestinationPlaces;
            final atLimit = places.length >= _kMaxSavedPlaces;
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.profileSavedPlaces,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Máximo $_kMaxSavedPlaces lugares.',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: atLimit
                            ? null
                            : () async {
                                final labelCtrl = TextEditingController(
                                  text: forOrigin
                                      ? (_originDisplayLabel ?? '').trim()
                                      : (_destinationDisplayLabel ?? '').trim(),
                                );
                                final ok = await showDialog<bool>(
                                  context: ctx,
                                  builder: (dCtx) => AlertDialog(
                                    title: const Text('Nuevo lugar guardado'),
                                    content: TextField(
                                      controller: labelCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre',
                                        hintText: 'Ej.: Casa, Trabajo',
                                      ),
                                      autofocus: true,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dCtx, false),
                                        child: Text(l10n.commonCancel),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dCtx, true),
                                        child: const Text('Guardar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true || !mounted) return;
                                final label = _ensureSavedPlaceLabel(
                                  labelCtrl.text,
                                  forOrigin ? l10n.tripOrigin : l10n.tripDestination,
                                );
                                final latLng = forOrigin
                                    ? _origin
                                    : _destination;
                                if (latLng == null) {
                                  _showSubtleSnack(l10n.commonError);
                                  return;
                                }
                                final addr = _ensureSavedPlaceAddress(
                                  forOrigin
                                      ? (_originDisplayLabel ?? '')
                                      : (_destinationDisplayLabel ?? ''),
                                  latLng.latitude,
                                  latLng.longitude,
                                );
                                try {
                                  await TripsApi(token: token).savePassengerPlace(
                                    label: label,
                                    address: addr,
                                    lat: latLng.latitude,
                                    lng: latLng.longitude,
                                  );
                                  await _loadSavedPlaces();
                                  if (!mounted) return;
                                  setSheet(() {});
                                  _showSubtleSnack('Lugar guardado');
                                } catch (e) {
                                  if (!mounted) return;
                                  final code = e is DioException
                                      ? TexiBackendError.codeFromResponse(
                                          e.response?.data,
                                        )
                                      : null;
                                  _showSubtleSnack(
                                    code == 'SAVED_PLACES_LIMIT_REACHED'
                                        ? 'Límite de $_kMaxSavedPlaces lugares alcanzado.'
                                        : l10n.commonError,
                                  );
                                }
                              },
                        icon: const Icon(Icons.add_location_alt_rounded),
                        label: const Text('Guardar ubicación en el mapa'),
                      ),
                      const SizedBox(height: 10),
                      if (places.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(l10n.profileStateEmpty),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: places.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = places[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  p.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.place_rounded,
                                  color: p.isFavorite
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                title: Text(
                                  p.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  p.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  if (forOrigin) {
                                    _pickOriginSavedPlace(p);
                                  } else {
                                    _pickDestinationSavedPlace(p);
                                  }
                                  Navigator.of(ctx).pop();
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    final api = TripsApi(token: token);
                                    if (action == 'favorite') {
                                      await api.updatePassengerSavedPlace(
                                        placeId: p.id,
                                        isFavorite: !p.isFavorite,
                                      );
                                      await _loadSavedPlaces();
                                      if (!mounted) return;
                                      setSheet(() {});
                                    }
                                    if (action == 'delete') {
                                      await api.deletePassengerSavedPlace(p.id);
                                      await _loadSavedPlaces();
                                      if (!mounted) return;
                                      setSheet(() {});
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'favorite',
                                      child: Text(l10n.placeFavorite),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _newPlacesSessionToken() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now ^ (now >> 7) ^ (now << 11);
    return '$now$random';
  }

  void _onOriginSearchChanged(
    String query, [
    void Function(void Function())? setModalState,
  ]) {
    void bumpModal() => setModalState?.call(() {});
    _originSearchDebounce?.cancel();
    if (query.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _originSuggestions = const <PlaceSuggestion>[];
        _loadingOriginSuggestions = false;
      });
      bumpModal();
      return;
    }
    _originSearchDebounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      setState(() => _loadingOriginSuggestions = true);
      bumpModal();
      final center = _mapCenter ?? _origin;
      final result = await _places.fetchSuggestions(
        query: query,
        sessionToken: _originPlacesSessionToken,
        nearLat: center?.latitude,
        nearLng: center?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _originSuggestions = result;
        _loadingOriginSuggestions = false;
      });
      bumpModal();
    });
  }

  void _onDestinationSearchChanged(
    String query, [
    void Function(void Function())? setModalState,
  ]) {
    void bumpModal() => setModalState?.call(() {});
    _destinationSearchDebounce?.cancel();
    if (query.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _destinationSuggestions = const <PlaceSuggestion>[];
        _loadingDestinationSuggestions = false;
      });
      bumpModal();
      return;
    }
    _destinationSearchDebounce = Timer(
      const Duration(milliseconds: 320),
      () async {
        if (!mounted) return;
        setState(() => _loadingDestinationSuggestions = true);
        bumpModal();
        final center = _mapCenter ?? _destination ?? _origin;
        final result = await _places.fetchSuggestions(
          query: query,
          sessionToken: _destinationPlacesSessionToken,
          nearLat: center?.latitude,
          nearLng: center?.longitude,
        );
        if (!mounted) return;
        setState(() {
          _destinationSuggestions = result;
          _loadingDestinationSuggestions = false;
        });
        bumpModal();
      },
    );
  }

  Future<void> _selectOriginSuggestion(
    PlaceSuggestion suggestion,
    BuildContext sheetContext,
  ) async {
    setState(() => _searchingOriginAddress = true);
    final details = await _places.fetchPlaceDetails(
      placeId: suggestion.placeId,
      sessionToken: _originPlacesSessionToken,
    );
    _originPlacesSessionToken = _newPlacesSessionToken();
    if (!mounted) return;
    if (!sheetContext.mounted) return;
    if (details == null) {
      setState(() => _searchingOriginAddress = false);
      await _searchAndSetOrigin(suggestion.fullText, sheetContext);
      return;
    }
    setState(() {
      _origin = LatLng(details.lat, details.lng);
      _originDisplayLabel = details.formattedAddress.isNotEmpty
          ? details.formattedAddress
          : suggestion.fullText;
      _mapCenter = _origin;
      _routePoints = null;
      _searchingOriginAddress = false;
      _originSuggestions = const <PlaceSuggestion>[];
    });
    ref.read(tripRequestProvider.notifier).setOrigin(details.lat, details.lng);
    _controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(details.lat, details.lng)),
    );
    if (_destination != null) _fetchRoute();
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (_destination == null) {
      _requireOriginConfirmation();
    } else {
      _originConfirmed = true;
      _collapseStops();
    }
  }

  Future<void> _selectDestinationSuggestion(
    PlaceSuggestion suggestion,
    BuildContext sheetContext,
  ) async {
    setState(() => _searchingDestinationAddress = true);
    final details = await _places.fetchPlaceDetails(
      placeId: suggestion.placeId,
      sessionToken: _destinationPlacesSessionToken,
    );
    _destinationPlacesSessionToken = _newPlacesSessionToken();
    if (!mounted) return;
    if (!sheetContext.mounted) return;
    if (details == null) {
      setState(() => _searchingDestinationAddress = false);
      await _searchAndSetDestination(suggestion.fullText, sheetContext);
      return;
    }
    setState(() {
      _destination = LatLng(details.lat, details.lng);
      _destinationDisplayLabel = details.formattedAddress.isNotEmpty
          ? details.formattedAddress
          : suggestion.fullText;
      _routePoints = null;
      _searchingDestinationAddress = false;
      _destinationSuggestions = const <PlaceSuggestion>[];
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(details.lat, details.lng);
    _controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(details.lat, details.lng)),
    );
    _fetchRoute();
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    _fitCameraToOriginDestination();
    _collapseStops();
  }

  void _showOriginSearchSheet() {
    final l10n = AppLocalizations.of(context)!;
    _originPlacesSessionToken = _newPlacesSessionToken();
    _originSuggestions = const <PlaceSuggestion>[];
    _originSearchController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom +
                AppSafeScrolling.systemNavBottom(ctx),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.tripSearchAddress,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _originSearchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.tripSearchPlaceholder,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      onChanged: (q) => _onOriginSearchChanged(q, setModal),
                      onSubmitted: (q) => _searchAndSetOrigin(q, ctx),
                    ),
                    if (_loadingOriginSuggestions) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (_originSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _originSuggestions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _originSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(
                                item.mainText.isNotEmpty
                                    ? item.mainText
                                    : item.fullText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: item.secondaryText.isNotEmpty
                                  ? Text(
                                      item.secondaryText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () =>
                                  unawaited(_selectOriginSuggestion(item, ctx)),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: TexiScalePress(
                        child: FilledButton(
                          onPressed: () {
                            final q = _originSearchController.text.trim();
                            if (q.isNotEmpty) _searchAndSetOrigin(q, ctx);
                          },
                          child: Text(l10n.tripSearchAddress),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchAndSetOrigin(
    String query,
    BuildContext sheetContext,
  ) async {
    if (query.isEmpty) return;
    setState(() => _searchingOriginAddress = true);
    try {
      final result = await _geocoding.searchAddress(query);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _searchingOriginAddress = false;
          _error = AppLocalizations.of(context)!.tripSearchError;
        });
        if (sheetContext.mounted) Navigator.pop(sheetContext);
        return;
      }
      setState(() {
        _origin = LatLng(result.lat, result.lng);
        _originDisplayLabel = result.formattedAddress ?? query;
        _mapCenter = _origin;
        _searchingOriginAddress = false;
        _routePoints = null;
        _originSuggestions = const <PlaceSuggestion>[];
      });
      ref.read(tripRequestProvider.notifier).setOrigin(result.lat, result.lng);
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(result.lat, result.lng)),
      );
      if (_destination != null) _fetchRoute();
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      if (_destination == null) {
        _requireOriginConfirmation();
      } else {
        _originConfirmed = true;
        _collapseStops();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchingOriginAddress = false;
          _error = AppLocalizations.of(context)!.tripSearchError;
          _originSuggestions = const <PlaceSuggestion>[];
        });
        if (sheetContext.mounted) Navigator.pop(sheetContext);
      }
    }
  }

  Future<void> _setOriginFromCurrentLocation() async {
    setState(() => _loadingOrigin = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _error = null;
        _origin = LatLng(position.latitude, position.longitude);
        _originDisplayLabel = null;
        _mapCenter = _origin;
        _loadingOrigin = false;
        _routePoints = null;
        _deviceGpsFixOk = true;
      });
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(position.latitude, position.longitude);
      _controller?.animateCamera(CameraUpdate.newLatLng(_origin!));
      if (_destination != null) _fetchRoute();
      if (_destination == null) {
        _requireOriginConfirmation();
      } else {
        _originConfirmed = true;
        _collapseStops();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingOrigin = false;
          _error = AppLocalizations.of(context)!.homeLocationErrorGps;
        });
      }
    }
  }

  void _setOriginFromMapCenter() {
    final center = _mapCenter ?? _origin ?? const LatLng(-16.5, -68.1);
    setState(() {
      _origin = center;
      _originDisplayLabel =
          '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}';
      _originConfirmed = true;
      _pickingOrigin = false;
      _pickingDestination = false;
      // Flujo "solo Confirmar": tras confirmar origen, seguimos confirmando destino
      // sin abrir detalles ni opciones; los detalles aparecen recién tras confirmar destino.
      _activeStop = ActiveStop.none;
      _routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setOrigin(center.latitude, center.longitude);
    if (_destination != null) _fetchRoute();
  }

  Future<void> _loadPinIcons() async {
    if (!mounted) return;
    try {
      final originIcon = await buildPassengerWaypointMapPinIcon(
        fill: const Color(0xFFF9AB00),
      );
      final destinationIcon = await buildPassengerWaypointMapPinIcon(
        fill: const Color(0xFF111111),
      );
      if (!mounted) return;
      setState(() {
        _originOnTripIcon = originIcon;
        _destinationOnTripIcon = destinationIcon;
      });
    } catch (_) {
      // Ignoramos fallos de precarga; los markers siguen funcionando con fallback.
    }
  }

  Future<void> _loadDriverTripIcon() async {
    if (!mounted) return;
    try {
      final icon = await buildPassengerDriverOnTripMapIcon();
      if (!mounted) return;
      setState(() => _driverOnTripIcon = icon);
    } catch (_) {
      // Fallback: pin verde por defecto.
    }
  }

  void _syncAnimatedDriverMarker({
    required String? tripId,
    required String? status,
    required double? rawDriverLat,
    required double? rawDriverLng,
  }) {
    final shouldTrackDriver =
        tripId != null &&
        _isTrackingDriverStatus(status) &&
        rawDriverLat != null &&
        rawDriverLng != null;
    if (!shouldTrackDriver) {
      if (_animatedDriverLatLng != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _animatedDriverLatLng = null);
        });
      }
      _driverMotionTimer?.cancel();
      _driverMotionTimer = null;
      _lastDriverRawLat = null;
      _lastDriverRawLng = null;
      _driverLikelyIdle = false;
      return;
    }
    if (_lastDriverRawLat != null && _lastDriverRawLng != null) {
      final movedMeters = Geolocator.distanceBetween(
        _lastDriverRawLat!,
        _lastDriverRawLng!,
        rawDriverLat,
        rawDriverLng,
      );
      _driverLikelyIdle = movedMeters < 3.5;
    } else {
      _driverLikelyIdle = false;
    }
    if (!_appInForeground) {
      _driverMotionTimer?.cancel();
      _driverMotionTimer = null;
      if (_animatedDriverLatLng == null ||
          (_animatedDriverLatLng!.latitude - rawDriverLat).abs() > 0.000001 ||
          (_animatedDriverLatLng!.longitude - rawDriverLng).abs() > 0.000001) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _animatedDriverLatLng = LatLng(rawDriverLat, rawDriverLng));
        });
      }
      _lastDriverRawLat = rawDriverLat;
      _lastDriverRawLng = rawDriverLng;
      return;
    }
    if (_lastDriverRawLat == rawDriverLat &&
        _lastDriverRawLng == rawDriverLng) {
      return;
    }
    _lastDriverRawLat = rawDriverLat;
    _lastDriverRawLng = rawDriverLng;
    final target = LatLng(rawDriverLat, rawDriverLng);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animateDriverMarkerTo(target);
    });
  }

  void _animateDriverMarkerTo(LatLng target) {
    _driverMotionTimer?.cancel();
    if (!_appInForeground) {
      setState(() => _animatedDriverLatLng = target);
      return;
    }
    final from = _animatedDriverLatLng ?? target;
    if ((from.latitude - target.latitude).abs() < 0.000001 &&
        (from.longitude - target.longitude).abs() < 0.000001) {
      setState(() => _animatedDriverLatLng = target);
      return;
    }
    final lowPowerVisual = _lowBatteryModeActive || _driverLikelyIdle;
    final totalSteps = lowPowerVisual ? 5 : 9;
    final stepDuration =
        lowPowerVisual
            ? const Duration(milliseconds: 120)
            : const Duration(milliseconds: 85);
    var step = 0;
    _driverMotionTimer = Timer.periodic(stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      final t = step / totalSteps;
      final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
      final lat = from.latitude + (target.latitude - from.latitude) * eased;
      final lng = from.longitude + (target.longitude - from.longitude) * eased;
      setState(() => _animatedDriverLatLng = LatLng(lat, lng));
      if (step >= totalSteps) {
        timer.cancel();
      }
    });
  }

  String _activeTripMapStyleFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? _tripCleanMapStyleNight
        : _tripCleanMapStyleDay;
  }

  Color _activeRouteColorForStatus(String? status) {
    switch (status) {
      case 'accepted':
      case 'arrived':
        return const Color(0xFFF9AB00); // Texi amber
      case 'started':
      case 'in_trip':
        return const Color(0xFF2E7DFF); // Blue while riding
      default:
        return AppColors.primary;
    }
  }

  void _onMapCreated(GoogleMapController c) {
    _controller = c;
  }

  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;
    // Si solo falta confirmar destino (origen listo, destino nulo) y el usuario
    // está moviendo el mapa, ocultamos opciones expandidas para mantener
    // una experiencia tipo Uber/Lyft.
    if (_destination == null &&
        !_pickingOrigin &&
        !_pickingDestination &&
        _activeStop != ActiveStop.none) {
      setState(() {
        _activeStop = ActiveStop.none;
      });
    }
  }

  /// Obtiene el `LatLng` a confirmar desde el centro de cámara.
  ///
  /// Volvimos el pin al centro de la pantalla, así que el punto confirmado debe ser
  /// el centro real del mapa (como el flujo original).
  Future<LatLng> _getLatLngFromNeedle() async {
    final fallback = _mapCenter ?? _origin ?? const LatLng(-16.5, -68.1);
    return fallback;
  }

  Future<void> _updateOriginStreetLabel(LatLng p) async {
    final label = await _geocoding.reverseGeocodeStreet(
      lat: p.latitude,
      lng: p.longitude,
    );
    if (!mounted) return;
    if (_origin == null) return;
    final samePoint =
        (_origin!.latitude - p.latitude).abs() < 0.00001 &&
        (_origin!.longitude - p.longitude).abs() < 0.00001;
    if (!samePoint) return;
    if (label == null || label.isEmpty) return;
    setState(() => _originDisplayLabel = label);
  }

  Future<void> _updateDestinationStreetLabel(LatLng p) async {
    final label = await _geocoding.reverseGeocodeStreet(
      lat: p.latitude,
      lng: p.longitude,
    );
    if (!mounted) return;
    if (_destination == null) return;
    final samePoint =
        (_destination!.latitude - p.latitude).abs() < 0.00001 &&
        (_destination!.longitude - p.longitude).abs() < 0.00001;
    if (!samePoint) return;
    if (label == null || label.isEmpty) return;
    setState(() => _destinationDisplayLabel = label);
  }

  Future<void> _setOriginFromNeedle() async {
    final p = await _getLatLngFromNeedle();
    setState(() {
      _origin = p;
      _originDisplayLabel =
          '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
      _originConfirmed = true;
      _pickingOrigin = false;
      _pickingDestination = false;
      _activeStop = ActiveStop.none;
      _routePoints = null;
    });
    ref.read(tripRequestProvider.notifier).setOrigin(p.latitude, p.longitude);
    if (_destination != null) _fetchRoute();
    _updateOriginStreetLabel(p);
  }

  Future<void> _setDestinationFromNeedle() async {
    final p = await _getLatLngFromNeedle();
    setState(() {
      _destination = p;
      _destinationDisplayLabel =
          '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
      _pickingDestination = false;
      _routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(p.latitude, p.longitude);
    await _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
    _updateDestinationStreetLabel(p);
  }

  void _useMapCenterAsDestination() {
    final center = _mapCenter ?? _origin ?? const LatLng(-16.5, -68.1);
    setState(() {
      _destination = center;
      _routePoints = null;
    });
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
  }

  /// Menú de cuenta: acceso a perfil y cierre de sesión.
  Future<void> _showProfileMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 16),
                child: child,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface.withValues(alpha: 0.98),
                    const Color(0xFF2A2822),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TexiScalePress(
                      minScale: 0.98,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.pushNamed(AppRouter.passengerProfile);
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.profileScreenTitle,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        _MenuActionTile(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.tripHistoryTitle,
                          subtitle: l10n.tripHistoryMenu,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            context.pushNamed(AppRouter.tripHistory);
                          },
                        ),
                        const SizedBox(height: 8),
                        _MenuActionTile(
                          icon: Icons.logout_rounded,
                          title: l10n.tripLogout,
                          subtitle: l10n.profileLogoutSubtitle,
                          danger: true,
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await AuthService.logout();
                            if (!context.mounted) return;
                            context.goNamed(AppRouter.login);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchRoute() async {
    if (_destination == null || _origin == null) return;
    final token = ++_routeRequestToken;
    setState(() {
      _loadingRoute = true;
      _routePoints = null;
      _routeOverviewEncoded = null;
    });
    final origin = _origin!;
    final dest = _destination!;
    final routeFirst = await _directions.getRouteWithOverview(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destinationLat: dest.latitude,
      destinationLng: dest.longitude,
    );
    if (!mounted) return;
    if (token != _routeRequestToken) return;
    final points = routeFirst?.points;
    // Snap visual + coordenadas para precisión: si el usuario marca lejos de la vía,
    // buscamos el punto más cercano de la polyline para ajustar origen/destino
    // (mejora la precisión para el conductor).
    if (points != null && points.isNotEmpty) {
      final oTarget = origin;
      final dTarget = dest;

      LatLng? closestO;
      LatLng? closestD;
      double? minDO;
      double? minDD;

      for (final p in points) {
        final d1 = _distanceKm(oTarget, p);
        if (minDO == null || d1 < minDO) {
          minDO = d1;
          closestO = p;
        }
        final d2 = _distanceKm(dTarget, p);
        if (minDD == null || d2 < minDD) {
          minDD = d2;
          closestD = p;
        }
      }

      // Umbral: si el punto está muy lejos de la vía (ej. > 0.8km),
      // evitamos snap agresivo.
      final snapThresholdKm = 0.8;
      final shouldSnapO = closestO != null && (minDO ?? 0) <= snapThresholdKm;
      final shouldSnapD = closestD != null && (minDD ?? 0) <= snapThresholdKm;

      final snappedOrigin = shouldSnapO ? closestO : oTarget;
      final snappedDestination = shouldSnapD ? closestD : dTarget;

      // Segunda consulta con coordenadas finales: misma referencia de calles que verá el conductor.
      final routeAligned = await _directions.getRouteWithOverview(
        originLat: snappedOrigin.latitude,
        originLng: snappedOrigin.longitude,
        destinationLat: snappedDestination.latitude,
        destinationLng: snappedDestination.longitude,
      );
      if (!mounted) return;
      if (token != _routeRequestToken) return;

      setState(() {
        _origin = snappedOrigin;
        _destination = snappedDestination;
        _routePoints = routeAligned?.points ?? points;
        _routeOverviewEncoded =
            routeAligned?.overviewEncoded ?? routeFirst?.overviewEncoded;
        _loadingRoute = false;
      });

      // Actualizamos el provider para que quote/createTrip usen coordenadas snap.
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(snappedOrigin.latitude, snappedOrigin.longitude);
      ref
          .read(tripRequestProvider.notifier)
          .setDestination(
            snappedDestination.latitude,
            snappedDestination.longitude,
          );

      // Actualizamos etiquetas de calle si cambió el punto.
      unawaited(() async {
        if (shouldSnapO) {
          await _updateOriginStreetLabel(snappedOrigin);
        }
        if (shouldSnapD) {
          await _updateDestinationStreetLabel(snappedDestination);
        }
      }());
    } else {
      setState(() {
        _routePoints = null;
        _routeOverviewEncoded = null;
        _loadingRoute = false;
      });
    }
  }

  void _showDestinationSearchSheet() {
    final l10n = AppLocalizations.of(context)!;
    _destinationPlacesSessionToken = _newPlacesSessionToken();
    _destinationSuggestions = const <PlaceSuggestion>[];
    _destinationSearchController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom +
                AppSafeScrolling.systemNavBottom(ctx),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.tripSearchAddress,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _destinationSearchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.tripSearchPlaceholder,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      onChanged: (q) =>
                          _onDestinationSearchChanged(q, setModal),
                      onSubmitted: (q) => _searchAndSetDestination(q, ctx),
                    ),
                    if (_loadingDestinationSuggestions) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (_destinationSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _destinationSuggestions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _destinationSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(
                                item.mainText.isNotEmpty
                                    ? item.mainText
                                    : item.fullText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: item.secondaryText.isNotEmpty
                                  ? Text(
                                      item.secondaryText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () => unawaited(
                                _selectDestinationSuggestion(item, ctx),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: TexiScalePress(
                        child: FilledButton(
                          onPressed: () {
                            final q = _destinationSearchController.text.trim();
                            if (q.isNotEmpty) _searchAndSetDestination(q, ctx);
                          },
                          child: Text(l10n.tripSearchAddress),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchAndSetDestination(
    String query,
    BuildContext sheetContext,
  ) async {
    if (query.isEmpty) return;
    setState(() => _searchingDestinationAddress = true);
    try {
      final result = await _geocoding.searchAddress(query);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _searchingDestinationAddress = false;
          _error = AppLocalizations.of(context)!.tripSearchError;
        });
        if (sheetContext.mounted) Navigator.pop(sheetContext);
        return;
      }
      setState(() {
        _destination = LatLng(result.lat, result.lng);
        _destinationDisplayLabel = result.formattedAddress ?? query;
        _routePoints = null;
        _destinationSuggestions = const <PlaceSuggestion>[];
      });
      ref
          .read(tripRequestProvider.notifier)
          .setDestination(result.lat, result.lng);
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(result.lat, result.lng)),
      );
      _fetchRoute();
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      _fitCameraToOriginDestination();
      _collapseStops();
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchingDestinationAddress = false;
          _error = AppLocalizations.of(context)!.tripSearchError;
          _destinationSuggestions = const <PlaceSuggestion>[];
        });
        if (sheetContext.mounted) Navigator.pop(sheetContext);
      }
    } finally {
      if (mounted) setState(() => _searchingDestinationAddress = false);
    }
  }

  Future<void> _setDestinationFromCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _error = null;
        _destination = LatLng(position.latitude, position.longitude);
        _destinationDisplayLabel = null;
        _routePoints = null;
        _deviceGpsFixOk = true;
      });
      ref
          .read(tripRequestProvider.notifier)
          .setDestination(position.latitude, position.longitude);
      _controller?.animateCamera(CameraUpdate.newLatLng(_destination!));
      _fetchRoute();
      _fitCameraToOriginDestination();
      _collapseStops();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context)!.homeLocationErrorGps,
        );
      }
    }
  }

  void _setDestinationFromMapCenter() {
    final center =
        _mapCenter ?? _destination ?? _origin ?? const LatLng(-16.5, -68.1);
    setState(() {
      _destination = center;
      _destinationDisplayLabel =
          '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}';
      _pickingDestination = false;
      _routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(center.latitude, center.longitude);
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
  }

  /// Devuelve la etiqueta localizada del estado del viaje para el panel retráctil.
  String _tripStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'accepted':
        return l10n.tripStatusLabelEnRoute;
      case 'arrived':
        return l10n.tripStatusLabelArrived;
      case 'started':
        return l10n.tripStatusLabelStarted;
      case 'completed':
        return l10n.tripStatusLabelCompleted;
      default:
        return l10n.tripStatusLabelDefault;
    }
  }

  Future<void> _fetchQuote() async {
    if (_destination == null) return;

    if (ref.read(tripRequestProvider).tripId == null) {
      final gpsOk = await _ensureDeviceGpsForNewTrip();
      if (!gpsOk) {
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context)!.tripRequireGpsForRequest;
          });
        }
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.commonError;
      });
      return;
    }

    try {
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(_origin!.latitude, _origin!.longitude);
      ref
          .read(tripRequestProvider.notifier)
          .setDestination(_destination!.latitude, _destination!.longitude);
      final api = TripsApi(token: token);
      final quote = await api.quoteTrip(
        originLat: _origin!.latitude,
        originLng: _origin!.longitude,
        destinationLat: _destination!.latitude,
        destinationLng: _destination!.longitude,
      );
      ref.read(tripRequestProvider.notifier).setQuote(quote);
      if (!mounted) return;
      _showQuoteSheet(quote);
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[Quote] Error: $e');
      if (e is DioException) {
        debugPrint(
          '[Quote] statusCode=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      debugPrint('[Quote] stack: $st');

      final l10nQ = AppLocalizations.of(context)!;
      String message = l10nQ.commonError;
      if (e is DioException) {
        final data = e.response?.data;
        final code = TexiBackendError.codeFromResponse(data);
        final rawMsg = TexiBackendError.messageFromResponse(data);
        message = localizedTripApiError(l10nQ, code, fallbackMessage: rawMsg);
        if (message == l10nQ.commonError && e.response?.statusCode != null) {
          message = '${e.response?.statusCode}: ${e.message ?? message}';
        }
      }
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showQuoteSheet(QuoteResponse quote) {
    final originAddress =
        (_originDisplayLabel != null && _originDisplayLabel!.trim().isNotEmpty)
        ? _originDisplayLabel!.trim()
        : (_origin != null
              ? '${_origin!.latitude.toStringAsFixed(6)},${_origin!.longitude.toStringAsFixed(6)}'
              : null);
    final destinationAddress =
        (_destinationDisplayLabel != null &&
            _destinationDisplayLabel!.trim().isNotEmpty)
        ? _destinationDisplayLabel!.trim()
        : (_destination != null
              ? '${_destination!.latitude.toStringAsFixed(6)},${_destination!.longitude.toStringAsFixed(6)}'
              : null);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuoteBottomSheet(
        quote: quote,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        routeOverviewEncoded: _routeOverviewEncoded,
        ensureDeviceGpsForNewTrip: _ensureDeviceGpsForNewTrip,
        onClose: () => Navigator.of(ctx).pop(),
        onSuccess: () {
          // Solo cerrar el sheet: volver a montar `trip_request` con goNamed
          // recrea TripRequestScreen, pierde estado local del mapa y dispara initState
          // como "viaje persistido" (snack "Solicitud recuperada" + UI rota).
          Navigator.of(ctx).pop();
        },
      ),
    ).whenComplete(() {
      if (!mounted) return;
      // Si el sheet se cerró sin llegar a solicitar conductor (tripId sigue null),
      // limpiamos cotización, ruta y destino para poder rearmar el viaje.
      final s = ref.read(tripRequestProvider);
      if (s.tripId == null && s.quote != null) {
        _cancelQuoteDraft();
      }
    });
  }

  /// Solo antes de solicitar conductor: quita cotización, ruta y destino del mapa.
  /// No aplica a viaje ya creado / en curso (tripId != null).
  void _cancelQuoteDraft() {
    if (!mounted) return;
    if (ref.read(tripRequestProvider).tripId != null) return;

    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    _routeRequestToken++;
    setState(() {
      _destination = null;
      _destinationDisplayLabel = null;
      _routePoints = null;
      _loadingRoute = false;
      _originDisplayLabel = null;
      _originConfirmed = false;
      _pickingOrigin = true;
      _pickingDestination = false;
      _activeStop = ActiveStop.none;
      _error = null;
    });
    if (_origin != null) {
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(_origin!.latitude, _origin!.longitude);
    }
    _controller?.animateCamera(
      CameraUpdate.newLatLng(_origin ?? const LatLng(-16.5, -68.1)),
    );
  }

  /// Cancela la búsqueda: **POST /passengers/trips/:id/cancel** para invalidar ofertas en servidor
  /// y que los conductores no sigan viendo la solicitud. Si falla la red, no limpiamos estado.
  Future<void> _cancelSearchingTrip() async {
    final tripId = ref.read(tripRequestProvider).tripId;
    final token = await AuthService.getValidToken();
    if (tripId != null &&
        tripId.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      try {
        await TripsApi(token: token).cancelPassengerTrip(tripId: tripId);
      } catch (e, st) {
        debugPrint('[CancelTrip] $e\n$st');
        if (mounted) {
          final loc = AppLocalizations.of(context);
          if (loc != null) {
            ScaffoldMessenger.maybeOf(
              context,
            )?.showSnackBar(SnackBar(content: Text(loc.commonError)));
          }
        }
        return;
      }
    }
    if (!mounted) return;
    ref.read(passengerRealtimeProvider.notifier).disconnect();
    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    unawaited(TripSessionStorage.clearActiveTripId());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mapUiResetTick = ref.watch(passengerTripMapUiResetTickProvider);
    if (mapUiResetTick > _lastConsumedPassengerTripMapUiTick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latest = ref.read(passengerTripMapUiResetTickProvider);
        if (latest <= _lastConsumedPassengerTripMapUiTick) return;
        _lastConsumedPassengerTripMapUiTick = latest;
        _resetLocalMapAfterExternalTripSessionClear();
      });
    }

    if (_loadingOrigin || _origin == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                l10n.splashGettingLocation,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (_originError != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _originError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final origin = _origin!;
    final tripState = ref.watch(tripRequestProvider);
    final tripId = tripState.tripId;
    final rtState = ref.watch(passengerRealtimeProvider);
    final driverLat = rtState.driverLat;
    final driverLng = rtState.driverLng;
    final driverBearing = rtState.driverBearing;

    ref.listen<PassengerRealtimeState>(passengerRealtimeProvider, (previous, next) {
      final was = passengerTripChatPhaseActive(previous?.status);
      final now = passengerTripChatPhaseActive(next.status);
      if (was && !now && _tripChatSheetDisplayed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).maybePop();
        });
      }
    });

    // Sincroniza flags de calificación cuando cambia el trip (p. ej. creado en esta sesión sin pasar por splash).
    ref.listen<TripRequestState>(tripRequestProvider, (previous, next) {
      final id = next.tripId;
      final prevId = previous?.tripId;
      if (id == prevId) return;

      void schedule(VoidCallback fn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          fn();
        });
      }

      if (id == null) {
        schedule(() {
          setState(() {
            _ratingDoneTripId = null;
            _ratingDone = false;
            _ratingSheetShownForTripId = null;
          });
        });
        return;
      }

      schedule(() {
        setState(() => _ratingSheetShownForTripId = null);
        unawaited(() async {
          final done = await TripSessionStorage.isRatingDone(id);
          if (!mounted) return;
          if (ref.read(tripRequestProvider).tripId != id) return;
          setState(() {
            _ratingDoneTripId = id;
            _ratingDone = done;
          });
        }());
      });
    });

    final isSearchingDriver =
        tripId != null &&
        (rtState.status == 'searching' ||
            (rtState.connecting &&
                (rtState.status == null || rtState.status == 'searching')));
    final isRecoveringActiveTrip = tripId != null && rtState.status == null;
    final isTripActive =
        tripId != null &&
        (rtState.status == 'accepted' ||
            rtState.status == 'arrived' ||
            rtState.status == 'started' ||
            rtState.status == 'in_trip' ||
            rtState.status == 'completed');
    _syncAnimatedDriverMarker(
      tripId: tripId,
      status: rtState.status,
      rawDriverLat: driverLat,
      rawDriverLng: driverLng,
    );
    final animatedDriver = _animatedDriverLatLng;
    final showDriverMarker = tripId != null && animatedDriver != null;
    final showDriverPulse =
        showDriverMarker &&
        _appInForeground &&
        !_driverLikelyIdle &&
        !_lowBatteryModeActive;
    _emitMapOptimizationTelemetryIfNeeded(tripId);
    final shouldPeriodicSync =
        tripId != null &&
        rtState.status != null &&
        !_isFinalTripStatus(rtState.status);

    if (shouldPeriodicSync) {
      final resolvedTripId = tripId;
      final trackingDriver = _isTrackingDriverStatus(rtState.status);
      _startTripStatusPeriodicSync(
        resolvedTripId,
        interval: trackingDriver
            ? const Duration(seconds: 15)
            : const Duration(seconds: 60),
      );
    } else {
      _stopTripStatusPeriodicSync();
    }
    final hasConnectionError = tripId != null && rtState.errorCode != null;
    final brightness = Theme.of(context).brightness;
    final activeRouteColor = _activeRouteColorForStatus(rtState.status);
    final needsOriginConfirm =
        tripId == null &&
        !_originConfirmed &&
        _destination == null &&
        !_pickingOrigin &&
        !_pickingDestination;
    final needsDestinationConfirm =
        tripId == null &&
        _originConfirmed &&
        _destination == null &&
        !_pickingOrigin &&
        !_pickingDestination;
    final needsAnyMapConfirm = needsOriginConfirm || needsDestinationConfirm;
    final isMapConfirmMode =
        tripId == null &&
        _activeStop == ActiveStop.none &&
        (_pickingOrigin || _pickingDestination || needsAnyMapConfirm);
    final confirmingOrigin = _pickingOrigin || needsOriginConfirm;

    // Al completarse el viaje, mostrar una sola vez el sheet de calificación
    // únicamente si el pasajero todavía no lo resolvió (localmente).
    if (tripId != null &&
        rtState.status == 'completed' &&
        tripId != _ratingSheetShownForTripId &&
        !_ratingDone) {
      _ratingSheetShownForTripId = tripId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRatingSheet(context, tripId, rtState.driverName);
      });
    }

    // Completado pero el rating ya figuraba hecho (p. ej. storage desincronizado): no se abre el sheet
    // y el panel de estado bloqueaba el flujo; volvemos al inicio como con "Omitir".
    if (tripId != null && rtState.status == 'completed' && _ratingDone) {
      if (_completedStaleAutoResetTripId != tripId) {
        _completedStaleAutoResetTripId = tripId;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (ref.read(tripRequestProvider).tripId != tripId ||
              ref.read(passengerRealtimeProvider).status != 'completed') {
            _completedStaleAutoResetTripId = null;
            return;
          }
          await _resetHomeAfterTripEnded(tripId);
        });
      }
    } else if (tripId == null || rtState.status != 'completed') {
      _completedStaleAutoResetTripId = null;
    }

    // Si el viaje termina en estados finales sin rating (cancelled/expired), resetear automáticamente.
    if (tripId != null &&
        (rtState.status == 'cancelled' || rtState.status == 'expired')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _routeRequestToken++;
        ref.read(passengerRealtimeProvider.notifier).disconnect();
        clearTripRecoverySnackTracking(ref);
        ref.read(tripRequestProvider.notifier).reset();
        unawaited(() async {
          await TripSessionStorage.clearActiveTripId();
        }());
        setState(() {
          _destination = null;
          _destinationDisplayLabel = null;
          _routePoints = null;
          _loadingRoute = false;
          _originConfirmed = false;
          _pickingOrigin = false;
          _pickingDestination = false;
          _error = null;
          if (_origin != null) {
            _pickingOrigin = true;
            _activeStop = ActiveStop.none;
          }
        });
        unawaited(_recenterMapToDeviceGpsAfterTripEnd());
      });
    }

    // Marcadores: al confirmar, deben quedar visibles en el mapa (como antes).
    // Durante confirmación de ORIGEN, el marcador de origen sigue el centro.
    final originMarkerPos = confirmingOrigin ? (_mapCenter ?? origin) : origin;
    // Marcador de destino: solo cuando ya está confirmado (no mientras se está eligiendo).
    final LatLng? destMarkerPos = (_destination != null && !_pickingDestination)
        ? _destination
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: origin, zoom: 15),
                onMapCreated: _onMapCreated,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                buildingsEnabled: false,
                indoorViewEnabled: false,
                trafficEnabled: false,
                style: isTripActive ? _activeTripMapStyleFor(brightness) : null,
                myLocationEnabled: _mapMyLocationDotEnabled,
                // Recentrado unificado en barra superior (mismo círculo que idioma/perfil); evita duplicar el FAB nativo.
                myLocationButtonEnabled: false,
                // Con viaje activo solo bloqueamos colocar destino tocando el mapa (onTap abajo), no zoom ni pan.
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                onTap:
                    (tripId == null &&
                        !_pickingOrigin &&
                        !_pickingDestination &&
                        !needsAnyMapConfirm)
                    ? (pos) {
                        setState(() {
                          _destination = pos;
                          _destinationDisplayLabel = null;
                          _routePoints = null;
                        });
                        ref
                            .read(tripRequestProvider.notifier)
                            .setDestination(pos.latitude, pos.longitude);
                        _fetchRoute();
                      }
                    : null,
                onCameraMove: _onCameraMove,
                markers: {
                  // Con aguja centrada no mostramos el pin amarillo duplicado (evita desalineación visual).
                  if (!(confirmingOrigin && isMapConfirmMode))
                    Marker(
                      markerId: const MarkerId('origin'),
                      position: originMarkerPos,
                      icon: _originOnTripIcon ?? _originFallbackIcon,
                      // Ancla por defecto (0.5, 1.0): la punta inferior del pin marca el punto real.
                    ),
                  if (destMarkerPos != null)
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: destMarkerPos,
                      icon: _destinationOnTripIcon ?? _destFallbackIcon,
                    ),
                  if (showDriverMarker)
                    Marker(
                      markerId: const MarkerId('driver'),
                      position: animatedDriver,
                      icon: _driverOnTripIcon ?? _driverFallbackIcon,
                      rotation: driverBearing ?? 0,
                      flat: true,
                      anchor: _driverOnTripIcon != null
                          ? const Offset(0.5, 0.5)
                          : const Offset(0.5, 1.0),
                    ),
                },
                circles: showDriverPulse
                    ? {
                        Circle(
                          circleId: const CircleId('driver_pulse'),
                          center: animatedDriver,
                          radius: 18 + (10 * _driverPulseController.value),
                          fillColor: AppColors.primary.withValues(
                            alpha: 0.11 - (_driverPulseController.value * 0.05),
                          ),
                          strokeColor: AppColors.primary.withValues(
                            alpha: 0.34 - (_driverPulseController.value * 0.14),
                          ),
                          strokeWidth: 2,
                        ),
                      }
                    : const {},
                polylines: _destination != null
                    ? {
                        Polyline(
                          polylineId: const PolylineId('route_casing'),
                          points:
                              (_routePoints != null && _routePoints!.isNotEmpty)
                              ? _routePoints!
                              : [origin, _destination!],
                          color: brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.12),
                          width: 10,
                          geodesic: true,
                          zIndex: 0,
                        ),
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points:
                              (_routePoints != null && _routePoints!.isNotEmpty)
                              ? _routePoints!
                              : [origin, _destination!],
                          color: activeRouteColor,
                          width: 6,
                          geodesic: true,
                          zIndex: 1,
                        ),
                      }
                    : {},
              ),
            ),
            // Barra superior fija: idioma y perfil; «recentrar» siempre bajo perfil (mismo control con o sin viaje).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TripCircleButton(
                            icon: Icons.menu_rounded,
                            onPressed: () => _showProfileMenu(context),
                          ),
                          if (!hasConnectionError) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Tooltip(
                              message: l10n.tripMapRecenterShort,
                              child: TripCircleButton(
                                icon: Icons.my_location_rounded,
                                isLoading: _recenterInProgress,
                                onPressed: () => _recenterMapForPassenger(
                                  driverLat: tripId != null ? driverLat : null,
                                  driverLng: tripId != null ? driverLng : null,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isMapConfirmMode)
              Positioned(
                top: 0,
                left: 10,
                right: 72,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                        child: Row(
                          children: [
                            Icon(
                              confirmingOrigin
                                  ? Icons.trip_origin_rounded
                                  : Icons.flag_rounded,
                              size: 18,
                              color: confirmingOrigin
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                confirmingOrigin
                                    ? 'Ajusta el mapa para definir tu punto de partida'
                                    : 'Ajusta el mapa para definir tu destino',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
                ),
              ),
            if (isTripActive &&
                !isSearchingDriver &&
                rtState.status != null &&
                !isMapConfirmMode)
              Positioned(
                top: 0,
                left: 10,
                right: 72,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Material(
                      color: AppColors.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car_rounded,
                              size: 18,
                              color: _activeRouteColorForStatus(rtState.status),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tripStatusLabel(l10n, rtState.status!),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Aguja: el centro del mapa (_mapCenter) debe coincidir con la *punta* del pin,
            // igual que los Marker por defecto (ancla inferior). Subimos el ícono para alinear.
            if (isMapConfirmMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      key: _needleRenderKey,
                      width: 56,
                      height: 72,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Sombra en el suelo, en el punto del mapa (centro de la cámara).
                          Transform.translate(
                            offset: const Offset(0, 3),
                            child: Container(
                              width: 16,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          // El Icon se dibuja centrado en su caja; la punta visual va ~medio tamaño por debajo → subimos.
                          Transform.translate(
                            // size 52 → centro del widget ~26 px sobre la punta; alineamos punta con el target del mapa.
                            offset: const Offset(0, -27),
                            child: Icon(
                              confirmingOrigin
                                  ? Icons.place_rounded
                                  : Icons.location_on_rounded,
                              size: 52,
                              color: confirmingOrigin
                                  ? AppColors.primary
                                  : const Color(0xFF111111),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Overlay "Buscando conductor" en el mismo mapa (sin cambiar de pantalla)
            if (isSearchingDriver)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSafeScrolling.systemNavBottom(context),
                child: TripSearchingDriverOverlay(
                  onCancel: () => unawaited(_cancelSearchingTrip()),
                  searchingTitle: l10n.searchingTitle,
                  searchingSubtitle: l10n.searchingSubtitle,
                  cancelLabel: l10n.commonCancel,
                ),
              ),
            if (isRecoveringActiveTrip && !isSearchingDriver)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + AppSafeScrolling.systemNavBottom(context),
                child: Material(
                  color: AppColors.surface,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.tripRecoveringStateTitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Panel retráctil de estado del viaje + datos del conductor y del viaje
            if (isTripActive && !isSearchingDriver && rtState.status != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.34,
                  minChildSize: 0.14,
                  maxChildSize: 0.72,
                  builder: (context, scrollController) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        TripStatusCard(
                          status: rtState.status!,
                          statusLabel: _tripStatusLabel(l10n, rtState.status!),
                          driverName: displayDriverName(
                            rtState.driverName,
                            l10n.tripDriverNameFallback,
                          ),
                          driverPhotoUrl: rtState.driverPhotoUrl,
                          driverRating: rtState.driverRating,
                          showAvatarRefreshingRing: (() {
                            final expiresAt = rtState.driverPhotoExpiresAt;
                            if (expiresAt == null) return false;
                            final now = DateTime.now();
                            return !now.isBefore(
                              expiresAt.subtract(const Duration(seconds: 45)),
                            );
                          })(),
                          carColor: rtState.carColor,
                          carPlate: rtState.carPlate,
                          carModel: rtState.carModel,
                          originLabel:
                              _originDisplayLabel ?? l10n.tripYourLocation,
                          destinationLabel:
                              _destinationDisplayLabel ?? l10n.tripDestination,
                          durationMinutes:
                              tripState.quote?.durationMinutes ??
                              rtState.quote?.durationMinutes ??
                              0,
                          distanceKm:
                              tripState.quote?.distanceKm ??
                              rtState.quote?.distanceKm ??
                              0.0,
                          estimatedPrice:
                              tripState.selectedOption?.estimatedPrice ??
                              tripState
                                  .quote
                                  ?.options
                                  .firstOrNull
                                  ?.estimatedPrice ??
                              rtState
                                  .quote
                                  ?.options
                                  .firstOrNull
                                  ?.estimatedPrice ??
                              0.0,
                          currencyCode:
                              tripState.selectedOption?.currencyCode ??
                              tripState.quote?.currencyCode ??
                              rtState.quote?.currencyCode ??
                              rtState.currencyCode,
                          statusFromLabel: l10n.tripStatusFrom,
                          statusToLabel: l10n.tripStatusTo,
                          driverAssignedLabel: l10n.tripStatusDriverAssigned,
                          statusMinutesLabel: (int c) =>
                              l10n.tripStatusMinutes(c),
                          statusKmLabel: (String v) => l10n.tripStatusKm(v),
                          onFinishedClose: rtState.status == 'completed'
                              ? () =>
                                    unawaited(_resetHomeAfterTripEnded(tripId))
                              : null,
                          finishedCloseLabel: rtState.status == 'completed'
                              ? l10n.tripFinishedBackToHome
                              : null,
                          onOpenChat: passengerTripChatPhaseActive(rtState.status)
                              ? () => _openTripChatSheet(tripId: tripId)
                              : null,
                          chatLabel: 'Chat seguro',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Error de conexión Socket: tripId existe pero falló connect (NO_TOKEN, SOCKET, etc.)
            if (hasConnectionError)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSafeScrolling.systemNavBottom(context),
                child: TripConnectionErrorOverlay(
                  message: localizedPassengerRealtimeError(
                    l10n,
                    rtState.errorCode,
                  ),
                  onRetry: () {
                    final quote = tripState.quote;
                    ref
                        .read(passengerRealtimeProvider.notifier)
                        .connect(tripId: tripId, quote: quote);
                  },
                  onCancel: () => unawaited(_cancelSearchingTrip()),
                  retryLabel: l10n.homeRetry,
                  cancelLabel: l10n.commonCancel,
                ),
              ),
            // Card inferior: paradas + acciones (altura máxima para que el mapa siga visible)
            if (!isSearchingDriver &&
                !isRecoveringActiveTrip &&
                !isTripActive &&
                !hasConnectionError &&
                !isMapConfirmMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: DraggableScrollableSheet(
                  // Cuando se abren las opciones (origen/destino), permitimos
                  // que la sección crezca por encima de la mitad de pantalla.
                  initialChildSize:
                      (_activeStop == ActiveStop.origin ||
                          _activeStop == ActiveStop.destination)
                      ? 0.32
                      : 0.33,
                  minChildSize:
                      (_activeStop == ActiveStop.origin ||
                          _activeStop == ActiveStop.destination)
                      ? 0.18
                      : 0.16,
                  maxChildSize:
                      (_activeStop == ActiveStop.origin ||
                          _activeStop == ActiveStop.destination)
                      ? 0.68
                      : 0.55,
                  builder: (context, scrollController) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ListView(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            bottom: AppSafeScrolling.systemNavBottom(context) + 110,
                          ),
                          children: [
                            TripBottomRequestCardContent(
                              scrollController: scrollController,
                              showSeePricesButton: false,
                          originDisplayText:
                              _originDisplayLabel ?? l10n.tripYourLocation,
                          originSubtitle: l10n.tripOrigin,
                          onOriginTap: () {
                            setState(() {
                              _activeStop = _activeStop == ActiveStop.origin
                                  ? ActiveStop.none
                                  : ActiveStop.origin;
                            });
                          },
                          onOriginUseMyLocation: _setOriginFromCurrentLocation,
                          onOriginSearch: _showOriginSearchSheet,
                          onOriginPickOnMap: _startPickOriginOnMap,
                          onPickOriginSaved: _pickOriginSavedPlace,
                          onPickOriginRecent: _pickOriginRecentPlace,
                          recentOriginPlaces: _recentOriginPlaces,
                          recentDestinationPlaces: _recentDestinationPlaces,
                          savedOriginPlaces: _savedOriginPlaces,
                          savedDestinationPlaces: _savedDestinationPlaces,
                          onSaveCurrentOrigin: () =>
                              unawaited(_saveCurrentOriginPlace()),
                          onSaveCurrentDestination: () =>
                              unawaited(_saveCurrentDestinationPlace()),
                          onManageSavedOrigin: () => unawaited(
                            _openSavedPlacesManager(forOrigin: true),
                          ),
                          onManageSavedDestination: () => unawaited(
                            _openSavedPlacesManager(forOrigin: false),
                          ),
                          destinationLabel: l10n.tripWhereTo,
                          destinationDisplayText: _destination != null
                              ? (_destinationDisplayLabel ??
                                    '${_destination!.latitude.toStringAsFixed(4)}, ${_destination!.longitude.toStringAsFixed(4)}')
                              : null,
                          destinationPlaceholder: l10n.tripTapMapDestination,
                          loadingRoute: _loadingRoute,
                          loadingQuote: _loading,
                          error: _error,
                          routeHint: l10n.tripSearchingAddress,
                          isPickingOrigin: _pickingOrigin,
                          isPickingDestination: _pickingDestination,
                          expandOrigin: _activeStop == ActiveStop.origin,
                          expandDestination:
                              _activeStop == ActiveStop.destination,
                          useMapCenterLabel: l10n.tripUseMapCenter,
                          useAsPickupLabel: l10n.tripUseAsPickup,
                          useAsDestinationLabel: l10n.tripUseAsDestination,
                          seePricesLabel: l10n.tripSeePrices,
                          onUseMapCenter: _useMapCenterAsDestination,
                          onSetOriginFromMap: _setOriginFromMapCenter,
                          onSetDestinationFromMap: _setDestinationFromMapCenter,
                          onDestinationTap: () {
                            if (!_originConfirmed && _destination == null) {
                              _showSubtleSnack(l10n.tripConfirmOriginFirst);
                              return;
                            }
                            setState(() {
                              _activeStop =
                                  _activeStop == ActiveStop.destination
                                  ? ActiveStop.none
                                  : ActiveStop.destination;
                            });
                          },
                          onDestinationUseMyLocation:
                              _setDestinationFromCurrentLocation,
                          onDestinationSearch: _showDestinationSearchSheet,
                          onDestinationPickOnMap: _startPickDestinationOnMap,
                          onPickDestinationSaved: _pickDestinationSavedPlace,
                          onPickDestinationRecent: _pickDestinationRecentPlace,
                          onSeePrices:
                              (_destination != null &&
                                  _origin != null &&
                                  !_pickingOrigin &&
                                  !_pickingDestination &&
                                  !_loadingRoute)
                              ? _fetchQuote
                              : null,
                          showCancelQuoteDraft:
                              tripId == null &&
                              _origin != null &&
                              _destination != null,
                          cancelQuoteDraftLabel: l10n.tripCancelQuoteDraft,
                          onCancelQuoteDraft: _cancelQuoteDraft,
                        ),
                          ],
                        ),
                        if (!_pickingOrigin && !_pickingDestination)
                          Positioned(
                            left: AppSpacing.xxx,
                            right: AppSpacing.xxx,
                            bottom: AppSafeScrolling.systemNavBottom(context) + 16,
                            child: SizedBox(
                              height: AppSizes.buttonHeight,
                              child: TexiScalePress(
                                child: FilledButton(
                                  onPressed:
                                      (_destination != null &&
                                              _origin != null &&
                                              !_loadingRoute &&
                                              !_loading)
                                          ? _fetchQuote
                                          : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.md,
                                      ),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: AppSizes.progressBtn,
                                          width: AppSizes.progressBtn,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          l10n.tripSeePrices,
                                          style: const TextStyle(
                                            fontSize: AppTypography.title,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            // Botón flotante de confirmación cuando el usuario está eligiendo en el mapa.
            if (isMapConfirmMode)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: TexiScalePress(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: confirmingOrigin
                                      ? AppColors.primary
                                      : const Color(0xFF111111),
                                  foregroundColor: confirmingOrigin
                                      ? Colors.black87
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () async {
                                  TexiUiFeedback.lightTap();
                                  if (confirmingOrigin) {
                                    await _setOriginFromNeedle();
                                  } else {
                                    await _setDestinationFromNeedle();
                                  }
                                },
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    confirmingOrigin
                                        ? l10n.tripConfirmOrigin
                                        : l10n.tripConfirmDestination,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.black87,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                setState(() {
                                  _pickingOrigin = false;
                                  _pickingDestination = false;
                                  _activeStop = confirmingOrigin
                                      ? ActiveStop.origin
                                      : ActiveStop.destination;
                                });
                              },
                              child: const SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading ||
                _searchingOriginAddress ||
                _searchingDestinationAddress)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sheet de calificación con estrellas (pasajero califica al conductor).
/// Layout y animación alineados con `driver_home_screen.dart` → [_RatingSheetContent].
class _PassengerRatingSheetContent extends StatefulWidget {
  const _PassengerRatingSheetContent({
    this.driverName,
    required this.title,
    required this.subtitle,
    required this.sendLabel,
    required this.skipLabel,
    required this.onSubmitted,
    required this.onSkipped,
  });

  final String? driverName;
  final String title;
  final String subtitle;
  final String sendLabel;
  final String skipLabel;
  final void Function(int stars, List<String> feedbackCodes) onSubmitted;
  final VoidCallback onSkipped;

  @override
  State<_PassengerRatingSheetContent> createState() =>
      _PassengerRatingSheetContentState();
}

class _PassengerRatingSheetContentState extends State<_PassengerRatingSheetContent>
    with SingleTickerProviderStateMixin {
  int _rating = 5;
  bool _loadingCatalog = true;
  List<TripRatingFeedbackItem> _feedbackLow = const [];
  List<TripRatingFeedbackItem> _feedbackHigh = const [];
  final Set<String> _selectedFeedbackCodes = <String>{};
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  List<TripRatingFeedbackItem> get _displayedOptions =>
      _rating <= 3 ? _feedbackLow : _feedbackHigh;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: AppMotion.sheetEntrance,
    );
    _fade = CurvedAnimation(parent: _entrance, curve: AppMotion.standard);
    _slide = Tween<Offset>(
      begin: Offset(0, AppMotion.slideDySubtle),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: AppMotion.standard));
    _entrance.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_preloadFeedbackCatalogs());
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _preloadFeedbackCatalogs() async {
    setState(() => _loadingCatalog = true);
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        _applyFallbackCatalogs();
        return;
      }
      final api = TripsApi(token: token);
      final results = await Future.wait([
        api.getPassengerRatingFeedbackCatalog(stars: 3),
        api.getPassengerRatingFeedbackCatalog(stars: 5),
      ]);
      if (!mounted) return;
      final lowRaw = results[0];
      final highRaw = results[1];
      setState(() {
        _feedbackLow = (lowRaw.isEmpty ? _fallbackFeedback(2) : lowRaw)
            .take(5)
            .toList(growable: false);
        _feedbackHigh = (highRaw.isEmpty ? _fallbackFeedback(5) : highRaw)
            .take(5)
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      _applyFallbackCatalogs();
    } finally {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  void _applyFallbackCatalogs() {
    if (!mounted) return;
    setState(() {
      _feedbackLow = _fallbackFeedback(2).take(5).toList(growable: false);
      _feedbackHigh = _fallbackFeedback(5).take(5).toList(growable: false);
    });
  }

  void _setRating(int stars) {
    HapticFeedback.selectionClick();
    final prevBucket = _rating <= 3;
    final nextBucket = stars <= 3;
    setState(() {
      _rating = stars;
      if (prevBucket != nextBucket) {
        _selectedFeedbackCodes.removeWhere(
          (code) => !_displayedOptions.any((item) => item.code == code),
        );
      }
    });
  }

  List<TripRatingFeedbackItem> _fallbackFeedback(int stars) {
    if (stars <= 3) {
      return const [
        TripRatingFeedbackItem(
          code: 'fallback_delay',
          label: 'Tardó en llegar',
          minStars: 1,
          maxStars: 3,
        ),
        TripRatingFeedbackItem(
          code: 'fallback_route',
          label: 'Ruta poco conveniente',
          minStars: 1,
          maxStars: 3,
        ),
        TripRatingFeedbackItem(
          code: 'fallback_cleanliness',
          label: 'Vehículo poco cómodo',
          minStars: 1,
          maxStars: 3,
        ),
        TripRatingFeedbackItem(
          code: 'fallback_attitude',
          label: 'Trato mejorable',
          minStars: 1,
          maxStars: 3,
        ),
        TripRatingFeedbackItem(
          code: 'fallback_other',
          label: 'Otro motivo',
          minStars: 1,
          maxStars: 3,
        ),
      ];
    }
    return const [
      TripRatingFeedbackItem(
        code: 'fallback_safe',
        label: 'Conducción segura',
        minStars: 4,
        maxStars: 5,
      ),
      TripRatingFeedbackItem(
        code: 'fallback_clean',
        label: 'Vehículo limpio',
        minStars: 4,
        maxStars: 5,
      ),
      TripRatingFeedbackItem(
        code: 'fallback_kind',
        label: 'Muy amable',
        minStars: 4,
        maxStars: 5,
      ),
      TripRatingFeedbackItem(
        code: 'fallback_punctual',
        label: 'Llegó rápido',
        minStars: 4,
        maxStars: 5,
      ),
      TripRatingFeedbackItem(
        code: 'fallback_excellent',
        label: 'Excelente servicio',
        minStars: 4,
        maxStars: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driverChip =
        widget.driverName != null && widget.driverName!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.75),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.onPrimary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.tripRatingSheetHeaderTitle,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.96,
                            ),
                          ),
                        ),
                        if (driverChip) ...[
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: AppColors.background,
                                  border: Border.all(
                                    color: AppColors.border.withValues(
                                      alpha: 0.62,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 17,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.driverName!,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          l10n.tripRatingYourRating,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final filled = _rating >= index + 1;
                            return IconButton(
                              onPressed: () => _setRating(index + 1),
                              icon: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 38,
                                color: filled
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            );
                          }),
                        ),
                        if (_rating > 0) ...[
                          const SizedBox(height: 12),
                          Text(
                            _rating <= 3
                                ? l10n.tripRatingFeedbackPromptLow
                                : l10n.tripRatingFeedbackPromptHigh,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_loadingCatalog)
                            const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_displayedOptions.isNotEmpty)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: _displayedOptions.map((item) {
                                final selected =
                                    _selectedFeedbackCodes.contains(item.code);
                                return FilterChip(
                                  selected: selected,
                                  onSelected: (value) {
                                    setState(() {
                                      if (value) {
                                        _selectedFeedbackCodes.add(item.code);
                                      } else {
                                        _selectedFeedbackCodes.remove(
                                          item.code,
                                        );
                                      }
                                    });
                                  },
                                  label: Text(item.label),
                                );
                              }).toList(growable: false),
                            ),
                        ],
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _rating == 0 || _loadingCatalog
                              ? null
                              : () {
                                  TexiUiFeedback.lightTap();
                                  widget.onSubmitted(
                                    _rating,
                                    _selectedFeedbackCodes.toList(
                                      growable: false,
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            widget.sendLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            TexiUiFeedback.lightTap();
                            widget.onSkipped();
                          },
                          child: Text(
                            widget.skipLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: opciones de precio y envío directo de la solicitud.
class _QuoteBottomSheet extends ConsumerStatefulWidget {
  const _QuoteBottomSheet({
    required this.quote,
    this.originAddress,
    this.destinationAddress,
    this.routeOverviewEncoded,
    required this.ensureDeviceGpsForNewTrip,
    required this.onClose,
    required this.onSuccess,
  });

  final QuoteResponse quote;
  final String? originAddress;
  final String? destinationAddress;
  final String? routeOverviewEncoded;
  final Future<bool> Function() ensureDeviceGpsForNewTrip;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  @override
  ConsumerState<_QuoteBottomSheet> createState() => _QuoteBottomSheetState();
}

class _QuoteBottomSheetState extends ConsumerState<_QuoteBottomSheet> {
  QuoteOption? _selected;
  bool _requesting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.quote.options.isNotEmpty) {
      _selected = widget.quote.options.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tripRequestProvider.notifier).selectOption(_selected!);
      });
    }
  }

  Future<void> _requestTrip() async {
    final state = ref.read(tripRequestProvider);
    final origin = state.origin;
    final destination = state.destination;
    final quote = state.quote;
    final option = _selected;

    if (origin == null ||
        destination == null ||
        quote == null ||
        option == null) {
      return;
    }

    final gpsOk = await widget.ensureDeviceGpsForNewTrip();
    if (!gpsOk) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.tripRequireGpsForRequest;
      });
      return;
    }

    setState(() {
      _requesting = true;
      _errorMessage = null;
    });

    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _errorMessage = AppLocalizations.of(context)!.commonError;
      });
      return;
    }

    try {
      final api = TripsApi(token: token);

      final guard = await reconcileActiveTripBeforeCreateTrip(
        ref: ref,
        api: api,
        quoteForSocket: quote,
      );
      if (guard == ActiveTripGuardResult.recoveredExisting) {
        if (!mounted) return;
        setState(() => _requesting = false);
        final tid = ref.read(tripRequestProvider).tripId;
        if (tid != null && tid.isNotEmpty) {
          showTripRecoveredSnackBarOncePerTrip(ref, context, tid);
        }
        widget.onSuccess();
        return;
      }

      final result = await api.createTrip(
        originLat: origin.lat,
        originLng: origin.lng,
        destinationLat: destination.lat,
        destinationLng: destination.lng,
        originAddress:
            widget.originAddress ??
            '${origin.lat.toStringAsFixed(6)},${origin.lng.toStringAsFixed(6)}',
        destinationAddress:
            widget.destinationAddress ??
            '${destination.lat.toStringAsFixed(6)},${destination.lng.toStringAsFixed(6)}',
        cityId: quote.city.id,
        serviceTypeId: option.serviceTypeId,
        estimatedPrice: option.estimatedPrice,
        routeOverviewEncoded: widget.routeOverviewEncoded,
      );
      ref.read(tripRequestProvider.notifier).selectOption(option);
      ref.read(tripRequestProvider.notifier).setTripId(result.tripId);
      await TripSessionStorage.saveActiveTripId(result.tripId);
      await TripSessionStorage.saveActiveTripUiSnapshot(
        tripId: result.tripId,
        originLat: origin.lat,
        originLng: origin.lng,
        destLat: destination.lat,
        destLng: destination.lng,
        originLabel: widget.originAddress,
        destLabel: widget.destinationAddress,
        quote: quote,
        selectedOption: option,
      );
      // Conectar Socket.IO para recibir trip:accepted, trip:status y trip:driver_location
      ref
          .read(passengerRealtimeProvider.notifier)
          .connect(tripId: result.tripId, quote: widget.quote);
      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      final l10nErr = AppLocalizations.of(context)!;
      if (e is DioException) {
        final data = e.response?.data;
        final code = TexiBackendError.codeFromResponse(data);
        final rawMsg = TexiBackendError.messageFromResponse(data);
        if (code == 'PASSENGER_ACTIVE_TRIP_EXISTS' && data is Map) {
          final envelope = Map<String, dynamic>.from(data);
          final errorObj = envelope['error'];
          if (errorObj is Map) {
            final errorMap = Map<String, dynamic>.from(errorObj);
            final activeTripId = errorMap['active_trip_id']?.toString().trim();
            if (activeTripId != null && activeTripId.isNotEmpty) {
              ref.read(tripRequestProvider.notifier).setTripId(activeTripId);
              await TripSessionStorage.saveActiveTripId(activeTripId);
              ref
                  .read(passengerRealtimeProvider.notifier)
                  .connect(tripId: activeTripId, quote: widget.quote);
              await ref
                  .read(passengerRealtimeProvider.notifier)
                  .syncTripStatusFromApi(tripId: activeTripId);
              if (!mounted) return;
              showTripRecoveredSnackBarOncePerTrip(ref, context, activeTripId);
              setState(() => _requesting = false);
              widget.onSuccess();
              return;
            }
          }
        }
        final message = localizedTripApiError(
          l10nErr,
          code,
          fallbackMessage: rawMsg,
        );
        setState(() {
          _requesting = false;
          _errorMessage = message;
        });
        return;
      }
      setState(() {
        _requesting = false;
        _errorMessage = l10nErr.commonError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quote = widget.quote;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.quoteSheetTopMargin),
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  AppSizes.quoteSheetMaxHeightFactor,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.sheetTop),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
                width: AppBorders.thin,
              ),
              boxShadow: AppShadows.sheetLiftStrong,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Container(
                    width: AppSizes.dragHandleQuoteW,
                    height: AppSizes.dragHandleQuoteH,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                TripQuoteHeader(
                  title: l10n.quoteTitle,
                  summary:
                      '${quote.distanceKm.toStringAsFixed(1)} km · ${quote.durationMinutes} min · ${quote.city.name}',
                ),
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxx,
                      AppSpacing.md,
                      AppSpacing.xxx,
                      AppSpacing.xxx,
                    ),
                    shrinkWrap: true,
                    itemCount: quote.options.length,
                    itemBuilder: (context, index) {
                      final option = quote.options[index];
                      final isSelected =
                          _selected?.serviceTypeId == option.serviceTypeId;
                      return TripQuoteOptionTile(
                        serviceName: displayServiceTypeName(
                          option.serviceTypeName,
                          l10n,
                        ),
                        priceText:
                            '${formatMoney(option.estimatedPrice, currencyCode: option.currencyCode, decimals: 1)} ${l10n.quotePerTrip}',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selected = option);
                          ref
                              .read(tripRequestProvider.notifier)
                              .selectOption(option);
                        },
                      );
                    },
                  ),
                ),
                if (_errorMessage != null) ...[
                  TripQuoteErrorBanner(message: _errorMessage!),
                ],
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sheetH,
                    AppSpacing.md,
                    AppSpacing.sheetH,
                    MediaQuery.of(context).padding.bottom + AppSpacing.xxx,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TripQuoteConfirmButton(
                        enabled: _selected != null && !_requesting,
                        loading: _requesting,
                        label: l10n.quoteConfirm,
                        onPressed: _requestTrip,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuActionTile extends StatefulWidget {
  const _MenuActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  State<_MenuActionTile> createState() => _MenuActionTileState();
}

class _MenuActionTileState extends State<_MenuActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.danger ? AppColors.error : AppColors.textSecondary;
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    widget.icon,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.danger
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
