import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../trip/passenger_trip_submit_helper.dart';
import 'widgets/passenger_phone_verification_gate_overlay.dart';

void navigateToPassengerPhoneLink(
  BuildContext context, {
  String? returnTo,
}) {
  context.pushNamed(
    AppRouter.phoneLink,
    queryParameters: {
      if (returnTo != null && returnTo.isNotEmpty) 'return_to': returnTo,
    },
  );
}

Future<bool> handlePassengerTripPhoneRequired(
  BuildContext context,
  WidgetRef ref,
  PassengerTripSubmitResultKind kind, {
  String? returnTo,
}) async {
  if (kind != PassengerTripSubmitResultKind.phoneRequired) return false;

  final emailOnly = await isPassengerEmailOnlyLimitedSession(ref);
  if (!context.mounted) return true;

  if (emailOnly) {
    await showPassengerPhoneVerificationGateOverlay(
      context,
      returnTo: returnTo,
    );
  } else {
    navigateToPassengerPhoneLink(context, returnTo: returnTo);
  }
  return true;
}
