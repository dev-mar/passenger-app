import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/locale_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/network/trips_api.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/location/passenger_geolocation_permission_cache.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/maps/trip_route_tracking_policy.dart';
import '../../core/network/geocoding_service.dart';
import '../../core/network/passenger_map_telemetry_service.dart';
import '../../core/network/places_autocomplete_service.dart';
import '../../data/models/quote_response.dart';
import '../../core/router/app_router.dart';
import '../../core/notifications/passenger_fcm_navigation.dart'
    show
        passengerTripChatOpenBump,
        takePendingPassengerChatTripIdFromNotification;
import '../../gen_l10n/app_localizations.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../core/compliance/passenger_play_permission_disclosures.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/ui/app_safe_scrolling.dart';
import 'trip_request_state.dart';
import '../../core/notifications/passenger_trip_chat_visibility.dart';
import 'passenger_realtime_controller.dart'
    show
        PassengerRealtimeState,
        passengerRealtimeProvider,
        displayDriverName,
        passengerTripChatPhaseActive;
import 'trip_recovery_feedback.dart';
import 'passenger_trip_chat_l10n.dart';
import 'passenger_trip_submit_helper.dart';
import 'widgets/passenger_rating_sheet.dart';
import 'widgets/passenger_profile_menu_action_tile.dart';
import 'widgets/passenger_trip_quote_bottom_sheet.dart';
import 'widgets/passenger_trip_draft_bottom_bar.dart';
import 'widgets/passenger_trip_draft_header.dart';
import 'widgets/trip_request_shell_widgets.dart';
import 'widgets/trip_tracking_widgets.dart';
import 'trip_driver_marker.dart';
import 'trip_request_route_service.dart';
import 'trip_request_trip_phase_helpers.dart';

part 'trip_request_screen.listeners.dart';
part 'trip_request_screen.map.dart';
part 'trip_request_screen.overlays.dart';
part 'trip_request_screen.draft.dart';
part 'trip_request_screen.trip_ops.dart';
part 'trip_request_screen.sync.dart';
part 'trip_request_screen.bootstrap.dart';
part 'trip_request_screen.scaffold.dart';

/// Pantalla unificada: Origen, destino y precios en la misma ventana.
/// Si originLat/originLng son null, se obtiene la ubicaciÃ³n actual al abrir.
class TripRequestScreen extends ConsumerStatefulWidget {
  const TripRequestScreen({super.key, this.originLat, this.originLng});

  final double? originLat;
  final double? originLng;

  @override
  ConsumerState<TripRequestScreen> createState() => _TripRequestScreenState();
}

enum ActiveStop { none, origin, destination }

class _TripRequestScreenState extends ConsumerState<TripRequestScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        _TripRequestScreenListenersMixin,
        _TripRequestScreenMapMixin,
        _TripRequestScreenTripOpsMixin,
        _TripRequestScreenOverlaysMixin,
        _TripRequestScreenDraftMixin,
        _TripRequestScreenSyncMixin,
        _TripRequestScreenBootstrapMixin,
        _TripRequestScreenScaffoldMixin {
  GoogleMapController? _controller;
  final GlobalKey _needleRenderKey = GlobalKey();
  final BitmapDescriptor _originFallbackIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  final BitmapDescriptor _destFallbackIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  final BitmapDescriptor _driverFallbackIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  LatLng? _origin; // Origen resuelto (widget o ubicaciÃ³n actual)
  String?
  _originDisplayLabel; // null = "Tu ubicaciÃ³n actual", si no texto elegido por el usuario
  bool _loadingOrigin = false;
  String? _originError;

  /// true solo tras leer coordenadas reales del dispositivo (no bastan origen en mapa/bÃºsqueda).
  bool _deviceGpsFixOk = false;

  /// Reinicio suave de la capa nativa del puntito azul (Ãºtil tras cold start con viaje restaurado).
  bool _mapMyLocationDotEnabled = true;
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
  final TextEditingController _draftSearchController = TextEditingController();
  final FocusNode _draftSearchFocus = FocusNode();
  final GeocodingService _geocoding = GeocodingService();
  final TripRequestRouteService _routeService = TripRequestRouteService();
  final PlacesAutocompleteService _places = PlacesAutocompleteService();
  bool _searchingOriginAddress = false;
  bool _searchingDestinationAddress = false;
  String _originPlacesSessionToken = '';
  String _destinationPlacesSessionToken = '';

  /// Cache para filtrar el listener del FocusNode y rebuildear solo cuando el focus cambia.
  bool _lastDraftSearchFocusState = false;
  Timer? _draftSearchDebounce;

  /// En borrador con origen y destino ya fijados, fuerza bÃºsqueda/GPS/guardados hacia un punto al editar.
  PassengerDraftEditTarget _draftEditTarget = PassengerDraftEditTarget.none;

  List<PlaceSuggestion> _draftSuggestions = const <PlaceSuggestion>[];
  bool _loadingDraftSuggestions = false;
  String _draftPlacesSessionToken = '';
  Timer? _mapConfirmIdleTimer;
  bool _mapConfirmInstructionHiddenWhileDragging = false;
  String? _mapNeedleAddressPreview;
  int _autoQuoteRouteGeneration = 0;
  bool _submittingTrip = false;
  List<TripRecentPlaceItem> _recentOriginPlaces = const <TripRecentPlaceItem>[];
  List<TripRecentPlaceItem> _recentDestinationPlaces =
      const <TripRecentPlaceItem>[];
  List<TripSavedPlaceItem> _savedOriginPlaces = const <TripSavedPlaceItem>[];
  List<TripSavedPlaceItem> _savedDestinationPlaces =
      const <TripSavedPlaceItem>[];
  List<LatLng>? _routePoints;

  /// Misma polyline codificada que Directions (se envÃ­a al crear viaje para el mapa del conductor).
  String? _routeOverviewEncoded;
  bool _loadingRoute = false;

  /// Se incrementa al cancelar ruta / fin de viaje y al iniciar cada [_fetchRoute]; evita aplicar polilÃ­nea y pines viejos.
  int _routeRequestToken = 0;

  /// Ruta dinÃ¡mica conductor â†’ destino cuando el viaje ya iniciÃ³ (`started` / `in_trip`).
  List<LatLng>? _passengerEnRouteToDestPoints;
  Timer? _passengerEnRouteRouteDebounce;
  int _passengerEnRouteRouteRequestToken = 0;
  DateTime? _lastPassengerEnRouteCameraFitAt;

  bool _recenterInProgress = false;
  String? _ratingSheetShownForTripId;
  String? _ratingDoneTripId;
  bool _ratingDone = false;

  /// Evita encolar varios auto-resets cuando el viaje ya estÃ¡ completado y el rating constaba hecho.
  String? _completedStaleAutoResetTripId;

  /// Evita que el listener de `tripId == null` borre flags durante [_resetHomeAfterTripEnded].
  bool _tripEndResetInProgress = false;

  /// Ãšltimo [passengerTripMapUiResetTickProvider] ya aplicado al estado local del mapa.
  int _lastConsumedPassengerTripMapUiTick = 0;
  ActiveStop _activeStop = ActiveStop.none;

  /// `true` mientras el bottom sheet del chat estÃ¡ visible (para cerrarlo al cambiar fase del viaje).
  bool _tripChatSheetDisplayed = false;
  int _lastHandledTripChatOpenBump = 0;
  int _tripChatUnreadCount = 0;
  int _tripChatReadCursor = 0;
  late final AnimationController _chatAttentionController;

  // Resiliencia: si falta el Ãºltimo evento por WebSocket (p. ej. driver finaliza offline),
  // refrescamos el status vÃ­a REST cada cierto tiempo.
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

  @override
  void initState() {
    super.initState();
    initTripRequestScreen();
  }

  @override
  void dispose() {
    disposeTripRequestScreen();
    super.dispose();
  }
}
