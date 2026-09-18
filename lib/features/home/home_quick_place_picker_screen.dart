import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';
import '../trip/widgets/passenger_map_picking_needle.dart';
import 'home_quick_slots.dart';
import 'widgets/passenger_home_look.dart';

/// Mapa con pin central para guardar destino de trabajo / casa / favorito.
class HomeQuickPlacePickerScreen extends StatefulWidget {
  const HomeQuickPlacePickerScreen({
    super.key,
    required this.slot,
    this.initialLat,
    this.initialLng,
  });

  final HomeQuickSlotKind slot;
  final double? initialLat;
  final double? initialLng;

  @override
  State<HomeQuickPlacePickerScreen> createState() =>
      _HomeQuickPlacePickerScreenState();
}

class _HomeQuickPlacePickerScreenState extends State<HomeQuickPlacePickerScreen> {
  static const _fallback = LatLng(-17.7833, -63.1821);

  GoogleMapController? _map;
  late LatLng _target;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) {
      _target = LatLng(lat, lng);
    } else {
      _target = _fallback;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryGps();
    });
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _tryGps() async {
    if (widget.initialLat != null && widget.initialLng != null) return;
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 6));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null || !mounted) return;
      final next = LatLng(pos.latitude, pos.longitude);
      if (_map == null) {
        setState(() => _target = next);
        return;
      }
      setState(() => _target = next);
      await _map!.animateCamera(CameraUpdate.newLatLngZoom(next, 16));
    } catch (_) {}
  }

  String _title(AppLocalizations l10n) {
    switch (widget.slot) {
      case HomeQuickSlotKind.work:
        return l10n.homeQuickPlacePickerTitleWork;
      case HomeQuickSlotKind.home:
        return l10n.homeQuickPlacePickerTitleHome;
      case HomeQuickSlotKind.favorite:
        return l10n.homeQuickPlacePickerTitleFavorite;
      case HomeQuickSlotKind.airport:
        return l10n.homeAirportCta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _target, zoom: 15.5),
            onMapCreated: (c) {
              _map = c;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            buildingsEnabled: false,
            indoorViewEnabled: false,
            trafficEnabled: false,
            onCameraMove: (pos) => _target = pos.target,
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, -PassengerMapPickingNeedle.tipOffsetFromCenter),
                child: const PassengerMapPickingNeedle(forOrigin: false),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                    decoration: BoxDecoration(
                      color: const Color(0xF2141C28),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Material(
                          color: const Color(0xFF243044),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(context).pop(),
                            child: SizedBox(
                              width: AppSizes.circleButton,
                              height: AppSizes.circleButton,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: PassengerHomeLook.ink,
                                semanticLabel: MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _title(l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: PassengerHomeLook.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.homeQuickPlacePickerHint,
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.xxx,
            right: AppSpacing.xxx,
            bottom: 16 + bottom,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  HomeQuickPlaceResult(
                    lat: _target.latitude,
                    lng: _target.longitude,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              ),
              child: Text(l10n.homeQuickPlaceSave),
            ),
          ),
        ],
      ),
    );
  }
}
