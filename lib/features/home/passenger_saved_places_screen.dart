import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/network/trips_api.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/passenger_success_toast.dart';
import '../../gen_l10n/app_localizations.dart';
import 'home_quick_slots.dart';
import 'widgets/passenger_home_look.dart';

enum SavedPlacesPurpose {
  requestTrip,
  pickOrigin,
  pickDestination;

  static SavedPlacesPurpose fromQuery(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'origin':
        return SavedPlacesPurpose.pickOrigin;
      case 'destination':
        return SavedPlacesPurpose.pickDestination;
      default:
        return SavedPlacesPurpose.requestTrip;
    }
  }
}

/// Lista compartida de lugares guardados. No muestra aeropuerto, trabajo ni casa.
class PassengerSavedPlacesScreen extends StatefulWidget {
  const PassengerSavedPlacesScreen({super.key, required this.purpose});

  final SavedPlacesPurpose purpose;

  static const int nameMaxLength = 32;
  static const int placeLimit = 5;

  @override
  State<PassengerSavedPlacesScreen> createState() =>
      _PassengerSavedPlacesScreenState();
}

class _PassengerSavedPlacesScreenState
    extends State<PassengerSavedPlacesScreen> {
  List<PassengerSavedPlace> _all = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  Future<TripsApi?> _api() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return null;
    return TripsApi(token: token);
  }

  Future<void> _reload() async {
    final api = await _api();
    if (!mounted) return;
    if (api == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await api.getPassengerSavedPlaces(limit: 30);
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(AppLocalizations.of(context)!.commonError, error: true);
    }
  }

  List<PassengerSavedPlace> _visible(AppLocalizations l10n) {
    return HomeQuickSlots.favoritesOnly(_all, l10n: l10n);
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    PassengerSuccessToast.show(
      context,
      message: message,
      icon: error ? Icons.error_outline_rounded : Icons.check_rounded,
      accent: error ? AppColors.error : AppColors.primary,
    );
  }

  Future<void> _addPlace(AppLocalizations l10n) async {
    final atLimit =
        _visible(l10n).length >= PassengerSavedPlacesScreen.placeLimit;
    if (_busy || atLimit) {
      if (atLimit) {
        _toast(
          l10n.tripSavedPlacesLimitReached(
            PassengerSavedPlacesScreen.placeLimit,
          ),
          error: true,
        );
      }
      return;
    }
    final picked = await context.pushNamed(
      AppRouter.homeQuickPlace,
      queryParameters: {
        'slot': HomeQuickSlotKind.favorite.name,
        'capture': '1',
        'title': l10n.savedPlacesPickerTitle,
      },
    );
    if (!mounted || picked is! HomeQuickPlaceResult) return;
    final address = (picked.address ?? '').trim();
    if (address.length < 3) {
      _toast(l10n.savedPlacesNeedStreet, error: true);
      return;
    }
    final name = await _askName(l10n);
    if (!mounted || name == null) return;
    if (HomeQuickSlots.isPrincipalSavedLabel(name, l10n: l10n)) {
      _toast(l10n.savedPlacesReservedName, error: true);
      return;
    }
    final api = await _api();
    if (api == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await api.savePassengerPlace(
        label: name,
        address: address.length > 180 ? address.substring(0, 180) : address,
        lat: picked.lat,
        lng: picked.lng,
        isFavorite: true,
      );
      await _reload();
      if (!mounted) return;
      _toast(l10n.tripSavedPlaceSaved);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = TexiBackendError.codeFromResponse(e.response?.data);
      _toast(
        code == 'SAVED_PLACES_LIMIT_REACHED'
            ? l10n.tripSavedPlacesLimitReached(
                PassengerSavedPlacesScreen.placeLimit,
              )
            : code == 'INVALID_PLACE_LABEL'
            ? l10n.savedPlacesReservedName
            : l10n.commonError,
        error: true,
      );
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.commonError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askName(AppLocalizations l10n) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: PassengerHomeLook.card,
          title: Text(
            l10n.savedPlacesNameTitle,
            style: const TextStyle(color: PassengerHomeLook.ink),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: PassengerSavedPlacesScreen.nameMaxLength,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: PassengerHomeLook.ink),
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                PassengerSavedPlacesScreen.nameMaxLength,
              ),
            ],
            decoration: InputDecoration(
              labelText: l10n.tripSavedPlaceNameLabel,
              hintText: l10n.savedPlacesNameHint,
              counterStyle: const TextStyle(color: PassengerHomeLook.muted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.length < 2) return;
                Navigator.pop(ctx, value);
              },
              child: Text(l10n.tripSavedPlaceSaveCta),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return name;
  }

  Future<void> _delete(PassengerSavedPlace place, AppLocalizations l10n) async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PassengerHomeLook.card,
        title: Text(
          l10n.savedPlacesDeleteTitle,
          style: const TextStyle(color: PassengerHomeLook.ink),
        ),
        content: Text(
          place.label,
          style: const TextStyle(color: PassengerHomeLook.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.tripSavedPlaceDeleteCta),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = await _api();
    if (api == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await api.deletePassengerSavedPlace(place.id);
      await _reload();
      if (!mounted) return;
      _toast(l10n.savedPlacesDeleted);
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.commonError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final places = _visible(l10n);
    final atLimit = places.length >= PassengerSavedPlacesScreen.placeLimit;
    final hint = widget.purpose == SavedPlacesPurpose.requestTrip
        ? l10n.savedPlacesRideHint
        : l10n.savedPlacesPickHint;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: PassengerHomeLook.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeFavoriteCta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PassengerHomeLook.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PassengerHomeLook.muted,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                l10n.tripSavedPlacesMax(PassengerSavedPlacesScreen.placeLimit),
                style: const TextStyle(
                  color: PassengerHomeLook.muted,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : places.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.profileStateEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PassengerHomeLook.muted,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: places.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return _PlaceRow(
                          place: place,
                          onOpen: () => Navigator.of(context).pop(place),
                          onDelete: () => _delete(place, l10n),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
              child: FilledButton.icon(
                onPressed: (_busy || atLimit) ? null : () => _addPlace(l10n),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: PassengerHomeLook.cardLift,
                  disabledForegroundColor: PassengerHomeLook.muted,
                  minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                ),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: Text(l10n.savedPlacesAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.onOpen,
    required this.onDelete,
  });

  final PassengerSavedPlace place;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PassengerHomeLook.card,
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: PassengerHomeLook.cardLift,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              place.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PassengerHomeLook.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              place.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PassengerHomeLook.muted,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: PassengerHomeLook.muted,
              tooltip: AppLocalizations.of(context)!.tripSavedPlaceDeleteCta,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF243044),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: AppSizes.circleButton,
          height: AppSizes.circleButton,
          child: Icon(
            icon,
            color: PassengerHomeLook.ink,
            semanticLabel: tooltip,
          ),
        ),
      ),
    );
  }
}
