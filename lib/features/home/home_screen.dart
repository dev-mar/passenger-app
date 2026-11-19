import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/compliance/passenger_legal_links.dart';
import '../../core/compliance/passenger_play_permission_disclosures.dart';
import '../../core/config/passenger_legal_config.dart';
import '../../core/constants/app_assets.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/location/passenger_geolocation_permission_cache.dart';
import '../../core/network/geocoding_service.dart';
import '../../core/network/trips_api.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/router/app_router.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/app_safe_scrolling.dart';
import '../../core/ui/passenger_success_toast.dart';
import '../../gen_l10n/app_localizations.dart';
import '../notices/passenger_notices_bell.dart';
import '../notices/passenger_notices_repository.dart';
import '../trip/trip_request_state.dart';
import '../trip/widgets/passenger_fan_menu.dart';
import 'home_quick_slots.dart';
import 'widgets/passenger_home_banner_carousel.dart';
import 'widgets/passenger_home_look.dart';
import 'widgets/passenger_home_quick_trips_carousel.dart';
import 'widgets/passenger_home_recent_list.dart';
import 'widgets/passenger_home_where_to_cta.dart';

/// Hub post-login: atajos, anuncios y GPS en segundo plano.
/// No bloquea la UI si faltan permisos; el mapa de viaje sigue intacto.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Position? _position;
  bool _locationReady = false;
  bool _requestingLocation = false;
  List<PassengerHomeBanner> _banners = const [];
  String? _landingUrl;
  PassengerHomeAirport? _airport;
  List<PassengerSavedPlace> _saved = const [];
  List<PassengerRecentPlace> _recent = const [];
  bool _loadingHub = true;
  String? _greetingName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    final storedId = await TripSessionStorage.getActiveTripId();
    if (!mounted) return;
    if (storedId != null && storedId.isNotEmpty) {
      ref.read(tripRequestProvider.notifier).setTripId(storedId);
      context.goNamed(AppRouter.tripRequest);
      return;
    }
    await Future.wait<void>([
      _probeLocation(requestIfDenied: false),
      _loadPlaces(),
      _loadGreetingName(),
    ]);
    await _loadHub();
    if (mounted) ref.invalidate(passengerNoticesUnreadProvider);
  }

  Future<void> _loadGreetingName() async {
    var raw = (await AuthService.getPassengerDisplayName())?.trim();
    if (raw == null || raw.isEmpty) {
      try {
        final data = await ref
            .read(passengerMeProfileServiceProvider)
            .fetchData();
        raw = data['display_name']?.toString().trim();
        if (raw != null && raw.isNotEmpty) {
          await AuthService.savePassengerDisplayName(raw);
        }
      } catch (_) {}
    }
    final next = passengerGreetingFirstName(raw);
    if (!mounted || next == _greetingName) return;
    setState(() => _greetingName = next);
  }

  Future<TripsApi?> _api() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return null;
    return TripsApi(token: token);
  }

  Future<void> _probeLocation({required bool requestIfDenied}) async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (mounted) {
          setState(() {
            _locationReady = false;
            _position = null;
          });
        }
        return;
      }
      final permission =
          await PassengerGeolocationPermissionCache.ensureLocationPermission(
            requestIfDenied: requestIfDenied,
          );
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationReady = false;
            _position = null;
          });
        }
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (!mounted) return;
      setState(() {
        _position = pos;
        _locationReady = pos != null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationReady = false;
      });
    }
  }

  Future<void> _loadHub() async {
    final api = await _api();
    if (api == null || !mounted) {
      if (mounted) setState(() => _loadingHub = false);
      return;
    }
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final hub = await api.getPassengerHomeHub(
        lat: _position?.latitude,
        lng: _position?.longitude,
        locale: locale,
      );
      if (!mounted) return;
      setState(() {
        _banners = hub.banners;
        _landingUrl = hub.landingUrl;
        _airport = hub.nearestAirport;
        _loadingHub = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHub = false);
    }
  }

  Future<void> _loadPlaces() async {
    final api = await _api();
    if (api == null) return;
    try {
      final saved = await api.getPassengerSavedPlaces(limit: 5);
      final recent = await api.getPassengerRecentPlaces(limit: 5);
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _recent = _dedupeRecent(recent);
      });
    } catch (_) {}
  }

  List<PassengerRecentPlace> _dedupeRecent(List<PassengerRecentPlace> rows) {
    final seen = <String>{};
    final out = <PassengerRecentPlace>[];
    for (final p in rows) {
      if (p.lat == 0 && p.lng == 0) continue;
      final key =
          '${p.label.trim().toLowerCase()}|${p.lat.toStringAsFixed(4)}|${p.lng.toStringAsFixed(4)}';
      if (!seen.add(key)) continue;
      out.add(p);
      if (out.length >= 5) break;
    }
    return out;
  }

  Future<bool> _ensureGpsForTrip() async {
    if (_locationReady && _position != null) return true;
    if (!mounted) return false;
    setState(() => _requestingLocation = true);
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      final ok = await passengerEnsureLocationDisclosureForMap(context, l10n);
      if (!ok || !mounted) {
        setState(() => _requestingLocation = false);
        return false;
      }
    }
    PassengerGeolocationPermissionCache.clear();
    await _probeLocation(requestIfDenied: true);
    if (_locationReady && _position != null) {
      await _loadHub();
    }
    if (mounted) setState(() => _requestingLocation = false);
    return _locationReady && _position != null;
  }

  void _openMap({
    required double destLat,
    required double destLng,
    String? destLabel,
    String? destStreet,
  }) {
    final origin = _position;
    if (origin == null) return;
    final notifier = ref.read(tripRequestProvider.notifier);
    notifier.reset();
    notifier.setOrigin(origin.latitude, origin.longitude);
    notifier.setDestination(destLat, destLng);
    context.pushNamed(
      AppRouter.tripRequest,
      queryParameters: {
        'lat': origin.latitude.toStringAsFixed(6),
        'lng': origin.longitude.toStringAsFixed(6),
        'destLat': destLat.toStringAsFixed(6),
        'destLng': destLng.toStringAsFixed(6),
        if (destLabel != null && destLabel.trim().isNotEmpty)
          'destLabel': destLabel.trim(),
        if (destStreet != null && destStreet.trim().isNotEmpty)
          'destStreet': destStreet.trim(),
      },
    );
  }

  Future<void> _openNormalFlow() async {
    TexiUiFeedback.lightTap();
    final ok = await _ensureGpsForTrip();
    if (!ok || !mounted) {
      _showNeedLocation();
      return;
    }
    final origin = _position!;
    ref.read(tripRequestProvider.notifier).reset();
    ref
        .read(tripRequestProvider.notifier)
        .setOrigin(origin.latitude, origin.longitude);
    context.pushNamed(
      AppRouter.tripRequest,
      queryParameters: {
        'lat': origin.latitude.toStringAsFixed(6),
        'lng': origin.longitude.toStringAsFixed(6),
      },
    );
  }

  Future<void> _openAirport() async {
    TexiUiFeedback.lightTap();
    final ok = await _ensureGpsForTrip();
    if (!ok || !mounted) {
      _showNeedLocation();
      return;
    }
    var airport = _airport;
    if (airport == null) {
      await _loadHub();
      airport = _airport;
    }
    if (!mounted) return;
    if (airport == null) {
      final l10n = AppLocalizations.of(context)!;
      PassengerSuccessToast.show(
        context,
        message: l10n.homeAirportUnavailable,
        icon: Icons.flight_takeoff_rounded,
        accent: PassengerHomeLook.sky,
      );
      return;
    }
    _openMap(
      destLat: airport.lat,
      destLng: airport.lng,
      destLabel: airport.name,
    );
  }

  Future<void> _openPlace({
    required double lat,
    required double lng,
    required String label,
    String? driverAddress,
  }) async {
    TexiUiFeedback.lightTap();
    final ok = await _ensureGpsForTrip();
    if (!ok || !mounted) {
      _showNeedLocation();
      return;
    }
    _openMap(
      destLat: lat,
      destLng: lng,
      destLabel: label,
      destStreet: driverAddress,
    );
  }

  /// Casa, trabajo y favoritos: el pasajero ve el nombre y la calle.
  /// Al conductor solo se le manda la calle, o las coordenadas si no hay calle.
  Future<void> _openSavedDestination(PassengerSavedPlace place) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final reference = HomeQuickSlots.savedPlaceReferenceName(place.label, l10n);
    var street = HomeQuickSlots.savedPlaceStreet(
      place.address,
      reference: reference,
    );
    if (street == null) {
      street = await GeocodingService().reverseGeocodeStreet(
        lat: place.lat,
        lng: place.lng,
      );
      street = HomeQuickSlots.savedPlaceStreet(street, reference: reference);
    }
    if (!mounted) return;
    final driver = HomeQuickSlots.savedPlaceDriverAddress(
      street: street,
      lat: place.lat,
      lng: place.lng,
    );
    final display = HomeQuickSlots.savedPlacePassengerLabel(
      reference: reference,
      streetOrCoords: driver,
    );
    await _openPlace(
      lat: place.lat,
      lng: place.lng,
      label: display,
      driverAddress: driver,
    );
  }

  PassengerSavedPlace? _placeForSlot(HomeQuickSlotKind kind) {
    if (!mounted) return HomeQuickSlots.match(_saved, kind);
    return HomeQuickSlots.match(
      _saved,
      kind,
      l10n: AppLocalizations.of(context),
    );
  }

  Future<void> _openFavorites() async {
    TexiUiFeedback.lightTap();
    if (!mounted) return;
    final result = await context.pushNamed(
      AppRouter.savedPlaces,
      queryParameters: const {'purpose': 'trip'},
    );
    if (!mounted || result is! PassengerSavedPlace) return;
    await _openSavedDestination(result);
  }

  Future<void> _onQuickTrip(HomeQuickSlotKind kind) async {
    if (kind == HomeQuickSlotKind.airport) {
      await _openAirport();
      return;
    }
    final place = _placeForSlot(kind);
    if (place != null) {
      await _openSavedDestination(place);
      return;
    }
    await _pickAndSaveSlot(kind);
  }

  Future<void> _editSlot(HomeQuickSlotKind kind) async {
    TexiUiFeedback.lightTap();
    if (!mounted) return;
    final place = _placeForSlot(kind);
    if (place == null) {
      await _pickAndSaveSlot(kind);
      return;
    }
    final result = await context.pushNamed(
      AppRouter.homeQuickPlace,
      queryParameters: {
        'slot': kind.name,
        'capture': '1',
        'lat': place.lat.toStringAsFixed(6),
        'lng': place.lng.toStringAsFixed(6),
      },
    );
    if (!mounted || result is! HomeQuickPlaceResult) return;
    await _persistSlot(kind, result);
  }

  Future<void> _pickAndSaveSlot(HomeQuickSlotKind kind) async {
    TexiUiFeedback.lightTap();
    if (!mounted) return;
    final origin = _position;
    final result = await context.pushNamed(
      AppRouter.homeQuickPlace,
      queryParameters: {
        'slot': kind.name,
        'capture': '1',
        if (origin != null) 'lat': origin.latitude.toStringAsFixed(6),
        if (origin != null) 'lng': origin.longitude.toStringAsFixed(6),
      },
    );
    if (!mounted || result is! HomeQuickPlaceResult) return;
    await _persistSlot(kind, result);
  }

  Future<void> _persistSlot(
    HomeQuickSlotKind kind,
    HomeQuickPlaceResult point,
  ) async {
    final api = await _api();
    if (api == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final existing = _placeForSlot(kind);
    final label = existing?.label.trim().isNotEmpty == true
        ? existing!.label.trim()
        : HomeQuickSlots.storageLabel(kind, l10n);
    var address = HomeQuickSlots.savedPlaceStreet(
      point.address,
      reference: label,
    );
    address ??= HomeQuickSlots.savedPlaceStreet(
      await GeocodingService().reverseGeocodeStreet(
        lat: point.lat,
        lng: point.lng,
      ),
      reference: label,
    );
    final storedAddress = HomeQuickSlots.savedPlaceDriverAddress(
      street: address,
      lat: point.lat,
      lng: point.lng,
    );
    try {
      if (existing != null) {
        await api.updatePassengerSavedPlace(
          placeId: existing.id,
          address: storedAddress,
          lat: point.lat,
          lng: point.lng,
          isFavorite: kind == HomeQuickSlotKind.favorite
              ? true
              : existing.isFavorite,
        );
      } else {
        await api.savePassengerPlace(
          label: label,
          address: storedAddress,
          lat: point.lat,
          lng: point.lng,
          isFavorite: kind == HomeQuickSlotKind.favorite,
        );
      }
      await _loadPlaces();
      if (!mounted) return;
      PassengerSuccessToast.show(context, message: l10n.homeQuickPlaceSaved);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = TexiBackendError.codeFromResponse(e.response?.data);
      PassengerSuccessToast.show(
        context,
        message: code == 'SAVED_PLACES_LIMIT_REACHED'
            ? l10n.tripSavedPlacesLimitReached(5)
            : l10n.commonError,
        icon: Icons.error_outline_rounded,
        accent: AppColors.error,
      );
    } catch (_) {
      if (!mounted) return;
      PassengerSuccessToast.show(
        context,
        message: l10n.commonError,
        icon: Icons.error_outline_rounded,
        accent: AppColors.error,
      );
    }
  }

  void _showNeedLocation() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    PassengerSuccessToast.show(
      context,
      message: l10n.homeLocationNeededForTrip,
      icon: Icons.location_off_rounded,
      accent: PassengerHomeLook.gps,
    );
  }

  Future<void> _openAnnouncements() async {
    TexiUiFeedback.lightTap();
    final locale = Localizations.localeOf(context);
    final url = (_landingUrl != null && _landingUrl!.trim().isNotEmpty)
        ? _landingUrl!.trim()
        : PassengerLegalConfig.announcementsUrl(locale);
    await openPassengerExternalUrl(url);
  }

  Future<void> _openFanMenu(Offset anchor) async {
    final action = await showPassengerFanMenu(
      context: context,
      anchorGlobal: anchor,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case PassengerFanMenuAction.home:
        break;
      case PassengerFanMenuAction.safety:
        context.pushNamed(AppRouter.safetyHub);
      case PassengerFanMenuAction.operator:
        context.pushNamed(AppRouter.operatorTexi);
      case PassengerFanMenuAction.profile:
        await context.pushNamed(AppRouter.passengerProfile);
        if (mounted) await _loadGreetingName();
      case PassengerFanMenuAction.history:
        context.pushNamed(AppRouter.tripHistory);
      case PassengerFanMenuAction.logout:
        await _confirmLogout();
    }
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: PassengerHomeLook.cardLift,
                borderRadius: BorderRadius.circular(AppRadii.dialog),
                border: Border.all(color: PassengerHomeLook.hairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.menuLogoutConfirmTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: PassengerHomeLook.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.menuLogoutConfirmMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PassengerHomeLook.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxx),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE05140),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    ),
                    child: Text(l10n.menuLogoutConfirmAction),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      l10n.menuLogoutConfirmBack,
                      style: const TextStyle(color: PassengerHomeLook.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    await AuthService.logout();
    if (!mounted) return;
    context.goNamed(AppRouter.login);
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: PassengerHomeLook.muted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = AppSafeScrolling.systemNavBottom(context);
    final work = _placeForSlot(HomeQuickSlotKind.work);
    final homePlace = _placeForSlot(HomeQuickSlotKind.home);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.loginBackground,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: AppColors.background),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.85),
                radius: 1.15,
                colors: [Color(0x33FFD600), Color(0x00000000)],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.38),
                  Colors.black.withValues(alpha: 0.62),
                  const Color(0xF2070605),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxx,
                    AppSpacing.md,
                    AppSpacing.xxx,
                    AppSpacing.lg,
                  ),
                  child: SizedBox(
                    height: AppSizes.circleButton,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Semantics(
                          label: l10n.homeHubTitle,
                          image: true,
                          child: Image.asset(
                            AppAssets.logoAmaBlanco,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(height: 40),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PassengerNoticesBell(
                            unread:
                                ref
                                    .watch(passengerNoticesUnreadProvider)
                                    .asData
                                    ?.value ??
                                0,
                            tooltip: l10n.noticesInboxTitle,
                            onPressed: () {
                              TexiUiFeedback.lightTap();
                              context.pushNamed(AppRouter.notices);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_banners.isNotEmpty || _loadingHub)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxx,
                      0,
                      AppSpacing.xxx,
                      AppSpacing.section,
                    ),
                    child: _banners.isNotEmpty
                        ? PassengerHomeBannerCarousel(
                            banners: _banners,
                            onTap: _openAnnouncements,
                          )
                        : const _BannerSkeleton(),
                  ),
                Expanded(
                  child: ClipRect(
                    child: RefreshIndicator(
                      color: PassengerHomeLook.sky,
                      backgroundColor: PassengerHomeLook.card,
                      onRefresh: () async {
                        await _probeLocation(requestIfDenied: false);
                        await Future.wait<void>([
                          _loadPlaces(),
                          _loadHub(),
                          _loadGreetingName(),
                        ]);
                        if (mounted) {
                          ref.invalidate(passengerNoticesUnreadProvider);
                        }
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xxx,
                          0,
                          AppSpacing.xxx,
                          108 + bottom,
                        ),
                        children: [
                          if (!_locationReady) ...[
                            _GpsBanner(
                              message: l10n.homeLocationBanner,
                              actionLabel: l10n.homeEnableLocation,
                              loading: _requestingLocation,
                              onAction: () async {
                                TexiUiFeedback.lightTap();
                                final ok = await _ensureGpsForTrip();
                                if (!ok) _showNeedLocation();
                              },
                            ),
                            const SizedBox(height: AppSpacing.xxxx),
                          ],
                          PassengerHomeWhereToCta(
                            greeting: _greetingName == null
                                ? null
                                : l10n.homeHelloName(_greetingName!),
                            title: l10n.homeWhereToToday,
                            actionLabel: l10n.homeChooseOriginDestination,
                            onPressed: _openNormalFlow,
                          ),
                          const SizedBox(height: AppSpacing.xxx),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                TexiUiFeedback.lightTap();
                                context.pushNamed(AppRouter.texiRuta);
                              },
                              child: Text(l10n.homeTexiRutaEntry),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.homeTexiRutaHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.section),
                          _sectionLabel(context, l10n.homeShortcutsTitle),
                          const SizedBox(height: AppSpacing.xs),
                          PassengerHomeQuickTripsCarousel(
                            cards: [
                              PassengerHomeQuickTripCardData(
                                kind: HomeQuickSlotKind.airport,
                                title: l10n.homeAirportCta,
                                subtitle: _airport != null
                                    ? l10n.homeAirportSubtitle(_airport!.name)
                                    : l10n.homeAirportCardSubtitle,
                                configured: true,
                                onTap: () => unawaited(
                                  _onQuickTrip(HomeQuickSlotKind.airport),
                                ),
                              ),
                              PassengerHomeQuickTripCardData(
                                kind: HomeQuickSlotKind.work,
                                title: l10n.homeWorkCta,
                                subtitle: l10n.homeWorkSubtitle,
                                configured: work != null,
                                onTap: () => unawaited(
                                  _onQuickTrip(HomeQuickSlotKind.work),
                                ),
                                onEdit: work == null
                                    ? null
                                    : () => unawaited(
                                        _editSlot(HomeQuickSlotKind.work),
                                      ),
                              ),
                              PassengerHomeQuickTripCardData(
                                kind: HomeQuickSlotKind.home,
                                title: l10n.homeHomeCta,
                                subtitle: l10n.homeHomeSubtitle,
                                configured: homePlace != null,
                                onTap: () => unawaited(
                                  _onQuickTrip(HomeQuickSlotKind.home),
                                ),
                                onEdit: homePlace == null
                                    ? null
                                    : () => unawaited(
                                        _editSlot(HomeQuickSlotKind.home),
                                      ),
                              ),
                              PassengerHomeQuickTripCardData(
                                kind: HomeQuickSlotKind.favorite,
                                title: l10n.homeFavoriteCta,
                                subtitle: l10n.homeFavoriteSubtitle,
                                configured: true,
                                onTap: () => unawaited(_openFavorites()),
                              ),
                            ],
                          ),
                          if (_recent.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.section),
                            _sectionLabel(context, l10n.profileRecentPlaces),
                            const SizedBox(height: AppSpacing.lg),
                            PassengerHomeRecentList(
                              places: _recent,
                              onTap: (p) => _openPlace(
                                lat: p.lat,
                                lng: p.lng,
                                label: p.label,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.xxx,
            bottom: 16 + bottom,
            child: PassengerFanMenuFab(
              tooltip: l10n.menuOpenTooltip,
              onPressed: (anchor) => unawaited(_openFanMenu(anchor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsBanner extends StatelessWidget {
  const _GpsBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.loading,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: PassengerHomeLook.card,
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
        border: Border.all(
          color: PassengerHomeLook.gps.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PassengerHomeLook.gps.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: PassengerHomeLook.gps,
              size: AppIconSizes.md,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: PassengerHomeLook.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton(
            onPressed: loading ? null : onAction,
            style: TextButton.styleFrom(foregroundColor: PassengerHomeLook.sky),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PassengerHomeLook.sky,
                    ),
                  )
                : Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: PassengerHomeLook.card,
        borderRadius: BorderRadius.circular(AppRadii.lg + 4),
        border: Border.all(color: PassengerHomeLook.hairline),
      ),
    );
  }
}

/// Primer nombre del registro. Ignora el resto y un correo suelto.
String? passengerGreetingFirstName(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty || text.contains('@')) return null;
  final first = text.split(RegExp(r'\s+')).first.trim();
  if (first.length < 2) return null;
  return first;
}
