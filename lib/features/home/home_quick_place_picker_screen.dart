import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/network/geocoding_service.dart';
import '../../core/network/places_autocomplete_service.dart';
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
    this.titleOverride,
    this.captureAddress = false,
  });

  final HomeQuickSlotKind slot;
  final double? initialLat;
  final double? initialLng;
  final String? titleOverride;

  /// Si es true, al guardar adjunta la calle (búsqueda o geocodificación).
  final bool captureAddress;

  @override
  State<HomeQuickPlacePickerScreen> createState() =>
      _HomeQuickPlacePickerScreenState();
}

class _HomeQuickPlacePickerScreenState
    extends State<HomeQuickPlacePickerScreen> {
  static const _fallback = LatLng(-17.7833, -63.1821);

  final _places = PlacesAutocompleteService();
  final _geocoding = GeocodingService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  GoogleMapController? _map;
  late LatLng _target;
  Timer? _searchDebounce;
  String _sessionToken = '';
  List<PlaceSuggestion> _suggestions = const [];
  bool _searchOpen = false;
  bool _searching = false;
  bool _saving = false;
  int _searchGen = 0;
  String? _pickedAddress;
  LatLng? _addressAnchor;

  @override
  void initState() {
    super.initState();
    _sessionToken = _newSessionToken();
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _map?.dispose();
    super.dispose();
  }

  String _newSessionToken() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now ^ (now >> 7) ^ (now << 11);
    return '$now$random';
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _suggestions = const [];
        _searching = false;
        _searchController.clear();
      }
    });
    if (_searchOpen) {
      _searchFocus.requestFocus();
    } else {
      _searchFocus.unfocus();
    }
  }

  void _onSearchChanged(String raw) {
    _searchDebounce?.cancel();
    final query = raw.trim();
    if (query.length < PlacesAutocompleteService.minQueryLength) {
      setState(() {
        _suggestions = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      unawaited(_fetchSuggestions(query));
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final gen = ++_searchGen;
    final list = await _places.fetchSuggestions(
      query: query,
      sessionToken: _sessionToken,
      nearLat: _target.latitude,
      nearLng: _target.longitude,
    );
    if (!mounted || gen != _searchGen) return;
    setState(() {
      _suggestions = list;
      _searching = false;
    });
  }

  Future<void> _pickSuggestion(PlaceSuggestion suggestion) async {
    _searchFocus.unfocus();
    setState(() => _searching = true);
    final details = await _places.fetchPlaceDetails(
      placeId: suggestion.placeId,
      sessionToken: _sessionToken,
    );
    _sessionToken = _newSessionToken();
    var lat = details?.lat;
    var lng = details?.lng;
    if (lat == null || lng == null) {
      final address = suggestion.fullText.trim().isNotEmpty
          ? suggestion.fullText
          : suggestion.mainText;
      final geo = await _geocoding.searchAddress(address);
      lat = geo?.lat;
      lng = geo?.lng;
    }
    if (!mounted) return;
    if (lat == null || lng == null) {
      setState(() => _searching = false);
      return;
    }
    final next = LatLng(lat, lng);
    final street = (details?.formattedAddress.trim().isNotEmpty == true)
        ? details!.formattedAddress.trim()
        : (suggestion.fullText.trim().isNotEmpty
              ? suggestion.fullText.trim()
              : suggestion.mainText.trim());
    setState(() {
      _target = next;
      _pickedAddress = street.length >= 3 ? street : null;
      _addressAnchor = next;
      _searchOpen = false;
      _searching = false;
      _suggestions = const [];
      _searchController.clear();
    });
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(next, 16));
  }

  void _onCameraMove(CameraPosition pos) {
    _target = pos.target;
    if (!widget.captureAddress) return;
    final anchor = _addressAnchor;
    if (anchor == null || _pickedAddress == null) return;
    final meters = Geolocator.distanceBetween(
      anchor.latitude,
      anchor.longitude,
      pos.target.latitude,
      pos.target.longitude,
    );
    if (meters > 30) {
      _pickedAddress = null;
      _addressAnchor = null;
    }
  }

  Future<void> _savePin() async {
    if (!widget.captureAddress) {
      Navigator.of(context).pop(
        HomeQuickPlaceResult(lat: _target.latitude, lng: _target.longitude),
      );
      return;
    }
    setState(() => _saving = true);
    var address = _pickedAddress?.trim();
    if (address == null || address.length < 3) {
      address = (await _geocoding.reverseGeocodeStreet(
        lat: _target.latitude,
        lng: _target.longitude,
      ))?.trim();
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(
      HomeQuickPlaceResult(
        lat: _target.latitude,
        lng: _target.longitude,
        address: (address != null && address.length >= 3) ? address : null,
      ),
    );
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
    final override = widget.titleOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
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
            onCameraMove: _onCameraMove,
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(
                  0,
                  -PassengerMapPickingNeedle.tipOffsetFromCenter,
                ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
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
                                    semanticLabel: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _searchOpen
                                  ? TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocus,
                                      onChanged: _onSearchChanged,
                                      textInputAction: TextInputAction.search,
                                      style: const TextStyle(
                                        color: PassengerHomeLook.ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      cursorColor: AppColors.primary,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        hintText: l10n.tripDraftSearchHint,
                                        hintStyle: const TextStyle(
                                          color: PassengerHomeLook.muted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                            Material(
                              color: const Color(0xFF243044),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _toggleSearch,
                                child: SizedBox(
                                  width: AppSizes.circleButton,
                                  height: AppSizes.circleButton,
                                  child: Icon(
                                    _searchOpen
                                        ? Icons.close_rounded
                                        : Icons.search_rounded,
                                    color: PassengerHomeLook.ink,
                                    semanticLabel: _searchOpen
                                        ? MaterialLocalizations.of(
                                            context,
                                          ).closeButtonTooltip
                                        : l10n.tripSearchAddress,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_searchOpen && (_searching || _suggestions.isNotEmpty))
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          color: const Color(0xF2141C28),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: _searching && _suggestions.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                itemBuilder: (context, index) {
                                  final item = _suggestions[index];
                                  return InkWell(
                                    onTap: () =>
                                        unawaited(_pickSuggestion(item)),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 48,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.mainText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: PassengerHomeLook.ink,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (item.secondaryText
                                                .trim()
                                                .isNotEmpty)
                                              Text(
                                                item.secondaryText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color:
                                                      PassengerHomeLook.muted,
                                                  fontSize: 12,
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
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.xxx,
            right: AppSpacing.xxx,
            bottom: 16 + bottom,
            child: FilledButton(
              onPressed: _saving ? null : () => unawaited(_savePin()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(l10n.homeQuickPlaceSave),
            ),
          ),
        ],
      ),
    );
  }
}
