import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/compliance/passenger_play_permission_disclosures.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/network/trips_api.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../data/models/quote_response.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_active_trip_guard.dart';
import 'passenger_realtime_controller.dart';
import 'trip_recovery_feedback.dart';
import 'trip_request_state.dart';

/// Resultado de intentar crear el viaje desde cotización (sheet o barra superior).
enum PassengerTripSubmitResultKind {
  success,
  recoveredExisting,
  phoneRequired,
  error,
}

class PassengerTripSubmitResult {
  const PassengerTripSubmitResult(this.kind, {this.message});

  final PassengerTripSubmitResultKind kind;
  final String? message;
}

/// Lógica compartida entre el bottom sheet de cotización y el flujo inline.
Future<PassengerTripSubmitResult> submitPassengerTripFromQuote({
  required WidgetRef ref,
  required BuildContext context,
  required QuoteResponse quote,
  required QuoteOption option,
  required double originLat,
  required double originLng,
  required double destinationLat,
  required double destinationLng,
  required String? originAddress,
  required String? destinationAddress,
  required String? routeOverviewEncoded,
  required Future<bool> Function() ensureDeviceGpsForNewTrip,
}) async {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) {
    return const PassengerTripSubmitResult(PassengerTripSubmitResultKind.error);
  }

  final gpsOk = await ensureDeviceGpsForNewTrip();
  if (!gpsOk) {
    return PassengerTripSubmitResult(
      PassengerTripSubmitResultKind.error,
      message: l10n.tripRequireGpsForRequest,
    );
  }

  if (!context.mounted) {
    return const PassengerTripSubmitResult(PassengerTripSubmitResultKind.error);
  }
  if (!await passengerEnsureNotificationDisclosureForTripUpdates(context, l10n)) {
    return PassengerTripSubmitResult(
      PassengerTripSubmitResultKind.error,
      message: l10n.passengerPlayNotificationDisclosureRequired,
    );
  }

  final token = await AuthService.getValidToken();
  if (token == null || token.isEmpty) {
    return PassengerTripSubmitResult(
      PassengerTripSubmitResultKind.error,
      message: l10n.commonError,
    );
  }

  try {
    final meData = await ref
        .read(passengerMeProfileServiceProvider)
        .fetchData(forceRefresh: true);
    if (meData['phone_verified'] != true) {
      return PassengerTripSubmitResult(
        PassengerTripSubmitResultKind.phoneRequired,
        message: l10n.tripPhoneRequired,
      );
    }
  } catch (_) {
    // Si falla /auth/me, el gate server-side responderá 403.
  }

  try {
    final api = TripsApi(token: token);

    final guard = await reconcileActiveTripBeforeCreateTrip(
      ref: ref,
      api: api,
      quoteForSocket: quote,
    );
    if (guard == ActiveTripGuardResult.recoveredExisting) {
      final tid = ref.read(tripRequestProvider).tripId;
      if (tid != null && tid.isNotEmpty && context.mounted) {
        showTripRecoveredSnackBarOncePerTrip(ref, context, tid);
      }
      return const PassengerTripSubmitResult(
        PassengerTripSubmitResultKind.recoveredExisting,
      );
    }

    CreateTripResponse result;
    int createAttempt = 0;
    while (true) {
      createAttempt += 1;
      try {
        result = await api.createTrip(
          originLat: originLat,
          originLng: originLng,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          originAddress:
              originAddress ??
              '${originLat.toStringAsFixed(6)},${originLng.toStringAsFixed(6)}',
          destinationAddress:
              destinationAddress ??
              '${destinationLat.toStringAsFixed(6)},${destinationLng.toStringAsFixed(6)}',
          cityId: quote.city.id,
          serviceTypeId: option.serviceTypeId,
          estimatedPrice: option.estimatedPrice,
          routeOverviewEncoded: routeOverviewEncoded,
        );
        break;
      } on DioException catch (e) {
        final data = e.response?.data;
        final code = TexiBackendError.codeFromResponse(data);
        if (code == 'TRIP_CREATE_RATE_LIMITED' && createAttempt < 2) {
          final waitMs = TripsApi.retryAfterMsForCreateTrip(e)
              .clamp(300, 5000)
              .toInt();
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          if (!context.mounted) {
            return const PassengerTripSubmitResult(
              PassengerTripSubmitResultKind.error,
            );
          }
          continue;
        }
        rethrow;
      }
    }

    ref.read(tripRequestProvider.notifier).selectOption(option);
    ref.read(tripRequestProvider.notifier).setTripId(result.tripId);
    await TripSessionStorage.saveActiveTripId(result.tripId);
    await TripSessionStorage.saveActiveTripUiSnapshot(
      tripId: result.tripId,
      originLat: originLat,
      originLng: originLng,
      destLat: destinationLat,
      destLng: destinationLng,
      originLabel: originAddress,
      destLabel: destinationAddress,
      quote: quote,
      selectedOption: option,
    );
    ref.read(passengerRealtimeProvider.notifier).disconnect();
    ref
        .read(passengerRealtimeProvider.notifier)
        .connect(
          tripId: result.tripId,
          quote: quote,
          assumeAwaitingDriver: true,
        );

    return const PassengerTripSubmitResult(PassengerTripSubmitResultKind.success);
  } catch (e) {
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
                .connect(tripId: activeTripId, quote: quote);
            await ref
                .read(passengerRealtimeProvider.notifier)
                .syncTripStatusFromApi(tripId: activeTripId);
            if (context.mounted) {
              showTripRecoveredSnackBarOncePerTrip(ref, context, activeTripId);
            }
            return const PassengerTripSubmitResult(
              PassengerTripSubmitResultKind.recoveredExisting,
            );
          }
        }
      }
      final message = localizedTripApiError(
        l10n,
        code,
        fallbackMessage: rawMsg,
      );
      if (code == 'PASS_AUTH_PHONE_REQUIRED') {
        return PassengerTripSubmitResult(
          PassengerTripSubmitResultKind.phoneRequired,
          message: message,
        );
      }
      return PassengerTripSubmitResult(
        PassengerTripSubmitResultKind.error,
        message: message,
      );
    }
    return PassengerTripSubmitResult(
      PassengerTripSubmitResultKind.error,
      message: l10n.commonError,
    );
  }
}
