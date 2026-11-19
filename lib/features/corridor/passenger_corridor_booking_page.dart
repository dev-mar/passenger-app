import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_corridor_repository.dart';

String corridorBookingStatus(AppLocalizations l10n, String status) {
  switch (status) {
    case 'pending':
      return l10n.texiRutaStatusPending;
    case 'confirmed':
      return l10n.texiRutaStatusConfirmed;
    case 'boarded':
      return l10n.texiRutaStatusBoarded;
    case 'in_trip':
      return l10n.texiRutaStatusInTrip;
    case 'completed':
      return l10n.texiRutaStatusCompleted;
    case 'no_show':
      return l10n.texiRutaStatusNoShow;
    case 'cancelled':
      return l10n.texiRutaStatusCancelled;
    default:
      return status;
  }
}

String corridorBookingWhen(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month · $hour:$minute';
}

class PassengerCorridorBookingsPage extends StatelessWidget {
  const PassengerCorridorBookingsPage({
    super.key,
    required this.bookings,
    required this.onOpen,
  });

  final List<CorridorBooking> bookings;
  final ValueChanged<CorridorBooking> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.texiRutaMine)),
      body: bookings.isEmpty
          ? Center(child: Text(l10n.texiRutaNoBookings))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xxx),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = bookings[index];
                return _BookingTile(booking: item, onOpen: () => onOpen(item));
              },
            ),
    );
  }
}

class PassengerCorridorBookingPage extends StatefulWidget {
  const PassengerCorridorBookingPage({
    super.key,
    required this.booking,
    required this.onCancel,
    this.justSaved = false,
  });

  final CorridorBooking booking;
  final Future<void> Function() onCancel;
  final bool justSaved;

  @override
  State<PassengerCorridorBookingPage> createState() => _PassengerCorridorBookingPageState();
}

class _PassengerCorridorBookingPageState extends State<PassengerCorridorBookingPage> {
  bool _busy = false;

  Future<void> _copy(AppLocalizations l10n) async {
    final code = widget.booking.publicCode;
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.texiRutaCopied)));
  }

  Future<void> _cancel(AppLocalizations l10n) async {
    setState(() => _busy = true);
    try {
      await widget.onCancel();
      if (!mounted) return;
      Navigator.of(context).pop('cancelled');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(corridorErrorText(error, l10n.texiRutaGenericError))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.booking;
    final who = [
      item.givenName,
      item.plate,
      [item.color, item.model].where((part) => part.isNotEmpty).join(' '),
    ].where((part) => part.isNotEmpty).join(' · ');
    final total = (item.fareAmount * (item.seatCount < 1 ? 1 : item.seatCount)).toStringAsFixed(0);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.texiRutaMine)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xxx),
        children: [
          if (widget.justSaved) ...[
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxx),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(l10n.texiRutaSaved)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxx),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.texiRutaCode, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.publicCode,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          letterSpacing: 4,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: AppSizes.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: item.publicCode.isEmpty ? null : () => _copy(l10n),
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.texiRutaCopy),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxx),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    corridorBookingStatus(l10n, item.status),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${item.fromName} → ${item.toName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(corridorBookingWhen(item.departureAt)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${l10n.texiRutaSeatCount(item.seatCount)} · ${l10n.texiRutaTotal(total)}'),
                  if (who.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(who, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.texiRutaCash, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          if (item.fromLatitude != 0 || item.fromLongitude != 0) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => PassengerCorridorBoardMap(
                        latitude: item.fromLatitude,
                        longitude: item.fromLongitude,
                        label: item.fromName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.texiRutaBoardMap),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSizes.buttonHeight,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => Navigator.of(context).pop('again'),
              icon: const Icon(Icons.add_road),
              label: Text(l10n.texiRutaAnother),
            ),
          ),
          if (item.status == 'confirmed') ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: TextButton(
                onPressed: _busy ? null : () => _cancel(l10n),
                child: Text(l10n.texiRutaCancel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, required this.onOpen});

  final CorridorBooking booking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxx),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${booking.fromName} → ${booking.toName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${corridorBookingWhen(booking.departureAt)} · ${corridorBookingStatus(l10n, booking.status)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                booking.publicCode,
                style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PassengerCorridorBoardMap extends StatefulWidget {
  const PassengerCorridorBoardMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;

  @override
  State<PassengerCorridorBoardMap> createState() => _PassengerCorridorBoardMapState();
}

class _PassengerCorridorBoardMapState extends State<PassengerCorridorBoardMap> {
  LatLng? _me;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    try {
      final allowed = await Geolocator.isLocationServiceEnabled();
      if (!allowed) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _me = LatLng(position.latitude, position.longitude));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final board = LatLng(widget.latitude, widget.longitude);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('board'),
        position: board,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: l10n.texiRutaBoardPoint, snippet: widget.label),
      ),
      if (_me != null)
        Marker(
          markerId: const MarkerId('me'),
          position: _me!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: l10n.texiRutaYou),
        ),
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.texiRutaBoardMap)),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: board, zoom: 14),
        markers: markers,
        myLocationEnabled: _me != null,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }
}
