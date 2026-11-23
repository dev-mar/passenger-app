import 'dart:async';
import 'dart:io' show Platform, exit;

import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/locale_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/money_formatter.dart';
import '../../core/network/trips_api.dart';
import '../promotions/passenger_promo_request.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/location/passenger_geolocation_permission_cache.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/maps/trip_route_tracking_policy.dart';
import '../../core/maps/passenger_google_maps_health.dart';
import '../../core/maps/passenger_maps_bootstrap.dart';
import '../../core/network/geocoding_service.dart';
import '../../core/network/passenger_map_telemetry_service.dart';
import '../../core/network/places_autocomplete_service.dart';
import '../../data/models/quote_response.dart';
import '../../data/models/nearby_driver.dart';
import '../../core/router/app_router.dart';
import '../../core/notifications/passenger_fcm_navigation.dart'
    show
        passengerTripChatOpenBump,
        takePendingPassengerChatTripIdFromNotification;
import '../../core/notifications/passenger_notification_service.dart';
import '../home/home_quick_slots.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../core/compliance/passenger_play_permission_disclosures.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/ui/app_safe_scrolling.dart';
import '../../core/ui/passenger_inline_notice.dart';
import 'trip_request_state.dart';
import 'passenger_pickup_wait.dart';
import 'trip_cancel_reason.dart';
import 'widgets/trip_cancel_reason_sheet.dart';
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
import '../login/passenger_phone_link_navigation.dart';
import 'widgets/passenger_trip_toast.dart';
import 'widgets/passenger_rating_sheet.dart';
import 'widgets/passenger_fan_menu.dart';
import 'widgets/passenger_trip_quote_bottom_sheet.dart';
import 'widgets/passenger_trip_draft_bottom_bar.dart';
import 'widgets/passenger_trip_request_details_sheet.dart';
import 'trip_payment_method.dart';
import 'widgets/passenger_trip_draft_header.dart';
import 'widgets/trip_request_shell_widgets.dart';
import 'widgets/trip_tracking_widgets.dart';
import 'widgets/passenger_offerable_bids_panel.dart';
import 'widgets/passenger_search_fare_bump.dart';
import 'widgets/passenger_searching_map_radar.dart';
import 'widgets/passenger_map_picking_needle.dart';
import 'widgets/passenger_trip_recovery_panel.dart';
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

class TripRequestScreen extends ConsumerStatefulWidget {
  const TripRequestScreen({
    super.key,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
    this.destLabel,
    this.destStreet,
  });

  final double? originLat;
  final double? originLng;
  final double? destLat;
  final double? destLng;
  final String? destLabel;

  final String? destStreet;

  @override
  ConsumerState<TripRequestScreen> createState() => _TripRequestScreenState();
}

enum ActiveStop { none, origin, destination }

const double _kLiveOriginHoldMeters = 18;

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
  LatLng? _origin;
  String?
  _originDisplayLabel;
  bool _loadingOrigin = false;
  String? _originError;

  bool _deviceGpsFixOk = false;

  bool _mapMyLocationDotEnabled = true;
  bool _originConfirmed = false;
  bool _pickingOrigin = false;

  LatLng? _originEditAnchor;

  bool _originPinAdjusted = false;
  bool _pickingDestination = false;

  bool _destinationMapPickArmed = false;
  LatLng? _destination;
  String? _destinationDisplayLabel;

  String? _destinationDriverAddress;
  String? _originDriverAddress;

  bool _destinationPoiLabelLocked = false;
  LatLng? _mapCenter;

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

  bool _lastDraftSearchFocusState = false;
  Timer? _draftSearchDebounce;

  PassengerDraftEditTarget _draftEditTarget = PassengerDraftEditTarget.none;

  List<PlaceSuggestion> _draftSuggestions = const <PlaceSuggestion>[];
  bool _loadingDraftSuggestions = false;
  String _draftPlacesSessionToken = '';
  Timer? _mapConfirmIdleTimer;
  bool _mapConfirmInstructionHiddenWhileDragging = false;
  String? _mapNeedleAddressPreview;

  int _draftSearchCollapseToken = 0;

  int _draftSearchExpandToken = 0;
  int _autoQuoteRouteGeneration = 0;
  bool _submittingTrip = false;
  List<TripRecentPlaceItem> _recentOriginPlaces = const <TripRecentPlaceItem>[];
  List<TripRecentPlaceItem> _recentDestinationPlaces =
      const <TripRecentPlaceItem>[];
  List<LatLng>? _routePoints;

  String? _routeOverviewEncoded;
  bool _loadingRoute = false;

  int _routeRequestToken = 0;

  List<LatLng>? _passengerEnRouteToDestPoints;
  Timer? _passengerEnRouteRouteDebounce;
  int _passengerEnRouteRouteRequestToken = 0;
  DateTime? _lastPassengerEnRouteCameraFitAt;

  bool _recenterInProgress = false;
  String? _ratingSheetShownForTripId;
  String? _ratingDoneTripId;
  bool _ratingDone = false;
  String? _cancelHelpShownForTripId;

  String? _completedStaleAutoResetTripId;

  bool _tripEndResetInProgress = false;

  int _lastConsumedPassengerTripMapUiTick = 0;
  ActiveStop _activeStop = ActiveStop.none;

  bool _tripChatSheetDisplayed = false;
  int _lastHandledTripChatOpenBump = 0;
  int _tripChatUnreadCount = 0;
  int _tripChatReadCursor = 0;
  late final AnimationController _chatAttentionController;

  Timer? _tripStatusSyncTimer;
  String? _tripStatusSyncTimerTripId;
  Duration _tripStatusSyncInterval = const Duration(seconds: 60);
  bool _tripStatusSyncInFlight = false;
  DateTime _lastTripStatusSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
  BitmapDescriptor? _driverOnTripIcon;
  BitmapDescriptor? _originOnTripIcon;
  BitmapDescriptor? _destinationOnTripIcon;
  late final AnimationController _driverPulseController;

  late final AnimationController _searchingMapRadarController;
  Timer? _driverMotionTimer;
  Timer? _searchingNearbyTimer;
  List<NearbyDriver> _searchingNearbyDrivers = const [];

  bool _searchingHoldUi = false;

  bool _matchingSubmitUi = false;

  bool _keepDraftAfterMatchingCancel = false;

  QuoteResponse? _matchingRetryQuote;
  QuoteOption? _matchingRetryOption;
  LatLng? _matchingRetryOrigin;
  LatLng? _matchingRetryDestination;
  String? _matchingRetryOriginLabel;
  String? _matchingRetryDestinationLabel;
  String? _matchingRetryRouteEncoded;

  int _tripSubmitGeneration = 0;

  int _searchingOverlayGeneration = 0;
  bool _searchingStage3CancelInFlight = false;

  bool _searchingOriginCameraDone = false;
  bool? _nearbyPollingWanted;
  final ValueNotifier<Offset?> _searchingRadarAnchor = ValueNotifier<Offset?>(
    null,
  );
  DateTime _lastRadarAnchorAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _radarAnchorInFlight = false;
  bool _tripSheetFullyExpanded = false;
  LatLng? _animatedDriverLatLng;

  LatLng? _passengerAboardLatLng;
  double _passengerAboardBearing = 0;
  StreamSubscription<Position>? _passengerAboardGpsSub;
  bool _passengerAboardGpsStarting = false;
  bool _passengerAboardGpsAttempted = false;
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
