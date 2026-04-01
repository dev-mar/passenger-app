import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/config/locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/session/passenger_internal_tools_gate.dart';
import '../../core/network/trips_api.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/location/passenger_geolocation_permission_cache.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../data/models/nearby_driver.dart';
import '../../gen_l10n/app_localizations.dart';

/// Pantalla Home: mapa con tu ubicación y conductores cercanos.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _nearbyRefreshSeconds = 12;

  Position? _userPosition;
  List<NearbyDriver> _drivers = [];
  String? _error;
  bool _loadingLocation = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initLocationAndDrivers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndDrivers() async {
    final permission =
        await PassengerGeolocationPermissionCache.ensureLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _loadingLocation = false;
        _error = AppLocalizations.of(context)!.homeLocationError;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _userPosition = position;
          _loadingLocation = false;
          _error = null;
        });
        _fetchNearbyDrivers();
        _timer = Timer.periodic(
          const Duration(seconds: _nearbyRefreshSeconds),
          (_) => _fetchNearbyDrivers(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _error = AppLocalizations.of(context)!.homeLocationErrorGps;
        });
      }
    }
  }

  Future<void> _fetchNearbyDrivers() async {
    final pos = _userPosition;
    if (pos == null || !mounted) return;

    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return;

    try {
      final api = TripsApi(token: token);
      final response = await api.getNearbyDrivers(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusKm: 5,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _drivers = response.drivers;
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final code = TexiBackendError.codeFromDio(e);
      final msg = (code != null && code.startsWith('RBAC_'))
          ? localizedTripApiError(AppLocalizations.of(context)!, code)
          : null;
      setState(() {
        _drivers = [];
        if (msg != null) _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolsAsync = ref.watch(passengerInternalToolsVisibleProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appName),
        actions: [
          if (toolsAsync.hasValue && toolsAsync.value == true)
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Labs (beta)',
              onPressed: () {
                TexiUiFeedback.lightTap();
                context.pushNamed(AppRouter.labs);
              },
            ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: AppLocalizations.of(context)!.homeTooltipLanguage,
            onPressed: () {
              TexiUiFeedback.lightTap();
              _showLanguageMenu(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppLocalizations.of(context)!.homeTooltipProfile,
            onPressed: () {
              TexiUiFeedback.lightTap();
              context.pushNamed(AppRouter.passengerProfile);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomSheet: _userPosition != null ? _buildBottomSheet() : null,
      floatingActionButton: _userPosition != null
          ? TexiScalePress(
              minScale: 0.96,
              child: FloatingActionButton.extended(
                onPressed: () {
                  TexiUiFeedback.lightTap();
                  final lat = _userPosition!.latitude;
                  final lng = _userPosition!.longitude;
                  context.push(
                    '/trip/request?lat=${lat.toStringAsFixed(6)}&lng=${lng.toStringAsFixed(6)}',
                  );
                },
                icon: const Icon(Icons.directions_car_rounded),
                label: Text(AppLocalizations.of(context)!.homeRequestRide),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loadingLocation) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          children: [
            PremiumSkeletonBox(height: 180, radius: 22),
            SizedBox(height: 12),
            PremiumSkeletonBox(height: 96, radius: 16),
            SizedBox(height: 10),
            PremiumSkeletonBox(height: 96, radius: 16),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PremiumStateView(
            icon: Icons.location_off_rounded,
            title: AppLocalizations.of(context)!.homeLocationMissingTitle,
            message: _error!,
            actionLabel: AppLocalizations.of(context)!.homeRetry,
            onAction: () {
              TexiUiFeedback.lightTap();
              setState(() {
                _error = null;
                _loadingLocation = true;
              });
              _initLocationAndDrivers();
            },
          ),
        ),
      );
    }

    final pos = _userPosition!;
    final initialPosition = LatLng(pos.latitude, pos.longitude);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 15,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _buildMarkers(initialPosition),
    );
  }

  Set<Marker> _buildMarkers(LatLng userLatLng) {
    final markers = <Marker>{};

    markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: userLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: AppLocalizations.of(context)!.homeMapMe),
      ),
    );

    for (final d in _drivers) {
      markers.add(
        Marker(
          markerId: MarkerId('driver_${d.driverId}'),
          position: LatLng(d.lat, d.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: AppLocalizations.of(context)!.homeMapDriverTitle(d.driverId),
            snippet: AppLocalizations.of(context)!.homeDriverDistanceKm(d.distanceKm.toStringAsFixed(1)),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  TexiUiFeedback.lightTap();
                  context.pushNamed(AppRouter.passengerProfile);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.homeProfileQuickAccess,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            Text(
                              l10n.homeProfileQuickAccessSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _drivers.isEmpty
                  ? l10n.homeNearbyDriversNone
                  : l10n.homeNearbyDrivers(_drivers.length),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.homeUpdatesEvery(_nearbyRefreshSeconds),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.settingsLanguage,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l10n.languageSpanish),
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('es');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l10n.languageEnglish),
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
