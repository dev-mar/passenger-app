import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/service_type_display.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/auth/auth_service.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../core/network/trips_api.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/location/passenger_geolocation_permission_cache.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import 'trip_request_state.dart';
import 'passenger_active_trip_guard.dart';
import 'passenger_realtime_controller.dart';
import 'trip_recovery_feedback.dart';

/// Pantalla Confirmar viaje: resumen y botón Solicitar.
class TripConfirmScreen extends ConsumerStatefulWidget {
  const TripConfirmScreen({super.key});

  @override
  ConsumerState<TripConfirmScreen> createState() => _TripConfirmScreenState();
}

class _TripConfirmScreenState extends ConsumerState<TripConfirmScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _requestTrip() async {
    final state = ref.read(tripRequestProvider);
    final origin = state.origin;
    final destination = state.destination;
    final quote = state.quote;
    final option = state.selectedOption;

    if (origin == null || destination == null || quote == null || option == null) return;

    final permission =
        await PassengerGeolocationPermissionCache.ensureLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.tripRequireGpsForRequest;
        });
      }
      return;
    }
    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.tripRequireGpsForRequest;
        });
      }
      return;
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
      final api = TripsApi(token: token);

      final guard = await reconcileActiveTripBeforeCreateTrip(
        ref: ref,
        api: api,
        quoteForSocket: quote,
      );
      if (guard == ActiveTripGuardResult.recoveredExisting) {
        if (!mounted) return;
        setState(() => _loading = false);
        final tid = ref.read(tripRequestProvider).tripId;
        if (tid != null && tid.isNotEmpty) {
          showTripRecoveredSnackBarOncePerTrip(ref, context, tid);
        }
        context.goNamed('trip_request');
        return;
      }

      final result = await api.createTrip(
        originLat: origin.lat,
        originLng: origin.lng,
        destinationLat: destination.lat,
        destinationLng: destination.lng,
        // Enviamos también textos para que backend/conductor muestren
        // origen/destino en formato humano.
        originAddress:
            '${origin.lat.toStringAsFixed(6)},${origin.lng.toStringAsFixed(6)}',
        destinationAddress:
            '${destination.lat.toStringAsFixed(6)},${destination.lng.toStringAsFixed(6)}',
        cityId: quote.city.id,
        serviceTypeId: option.serviceTypeId,
        estimatedPrice: option.estimatedPrice,
      );
      ref.read(tripRequestProvider.notifier).setTripId(result.tripId);
      await TripSessionStorage.saveActiveTripId(result.tripId);
      await TripSessionStorage.saveActiveTripUiSnapshot(
        tripId: result.tripId,
        originLat: origin.lat,
        originLng: origin.lng,
        destLat: destination.lat,
        destLng: destination.lng,
        originLabel:
            '${origin.lat.toStringAsFixed(6)},${origin.lng.toStringAsFixed(6)}',
        destLabel:
            '${destination.lat.toStringAsFixed(6)},${destination.lng.toStringAsFixed(6)}',
        quote: quote,
        selectedOption: option,
      );
      // Conectar realtime para escuchar trip:accepted / trip:status para este trip.
      ref.read(passengerRealtimeProvider.notifier).connect(
            tripId: result.tripId,
            quote: quote,
          );
      if (!mounted) return;
      context.goNamed('trip_request');
    } catch (e) {
      if (!mounted) return;
      debugPrint('[CreateTrip] Error: $e');
      if (e is DioException) {
        debugPrint('[CreateTrip] statusCode=${e.response?.statusCode} data=${e.response?.data}');
      }
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.commonError;
      if (e is DioException) {
        final data = e.response?.data;
        final code = TexiBackendError.codeFromResponse(data);
        final rawMsg = TexiBackendError.messageFromResponse(data);
        message = localizedTripApiError(l10n, code, fallbackMessage: rawMsg);
        if (message == l10n.commonError && e.response?.statusCode != null) {
          message = '${e.response?.statusCode}: ${e.message ?? message}';
        }
      }
      setState(() {
        _loading = false;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(tripRequestProvider);
    final quote = state.quote;
    final option = state.selectedOption;

    if (quote == null || option == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.confirmTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PremiumStateView(
              icon: Icons.route_rounded,
              title: l10n.tripMissingDataTitle,
              message: l10n.commonError,
              actionLabel: 'Volver',
              onAction: () => context.goNamed('trip_request'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.confirmTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _card(context, l10n.confirmFrom, '${state.origin!.lat.toStringAsFixed(4)}, ${state.origin!.lng.toStringAsFixed(4)}'),
          const SizedBox(height: 12),
          _card(context, l10n.confirmTo, '${state.destination!.lat.toStringAsFixed(4)}, ${state.destination!.lng.toStringAsFixed(4)}'),
          const SizedBox(height: 12),
          _card(
            context,
            l10n.quoteTitle,
            '${displayServiceTypeName(option.serviceTypeName, l10n)} — ${option.estimatedPrice.toStringAsFixed(1)}',
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          ],
          const Spacer(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TexiScalePress(
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          TexiUiFeedback.lightTap();
                          _requestTrip();
                        },
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(l10n.confirmRequestRide),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
