import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'passenger_marketing_events.dart';

class PassengerMarketingAnalytics {
  PassengerMarketingAnalytics._();

  static final Set<String> _terminalOnce = <String>{};

  static void logSignUp() {
    _log('sign_up');
  }

  static void logRideRequest() {
    _log('ride_request');
  }

  static void logRideCancelled(String tripId) {
    _logTerminal(tripId, 'ride_cancelled');
  }

  static void onLiveStatus({
    required String? tripId,
    required String? previous,
    required String? next,
  }) {
    switch (passengerMarketingSignalForStatus(previous: previous, next: next)) {
      case PassengerMarketingTripSignal.completed:
        _logTerminal(tripId ?? '', 'ride_completed');
      case PassengerMarketingTripSignal.cancelled:
        _logTerminal(tripId ?? '', 'ride_cancelled');
      case PassengerMarketingTripSignal.none:
        break;
    }
  }

  static void _logTerminal(String tripId, String name) {
    final id = tripId.trim();
    if (id.isEmpty) return;
    if (!_terminalOnce.add('$id|$name')) return;
    _log(name);
  }

  static void _log(String name) {
    try {
      unawaited(_sendFirebase(name));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[marketing-analytics] $name: $e');
      }
    }
  }

  static Future<void> _sendFirebase(String name) async {
    try {
      if (Firebase.apps.isEmpty) return;
      if (name == 'sign_up') {
        await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'passenger');
      } else {
        await FirebaseAnalytics.instance.logEvent(name: name);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[marketing-analytics] firebase $name: $e');
      }
    }
  }
}
