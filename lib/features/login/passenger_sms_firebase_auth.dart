import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Firebase Phone Auth — Fase 4 pasajero (SMS enviado por Firebase en el cliente).
class PassengerSmsFirebaseAuth {
  PassengerSmsFirebaseAuth._();

  static String? _verificationId;

  static void resetVerificationSession() {
    _verificationId = null;
  }

  static Future<void> _ensureFirebaseReady() async {
    final expected = DefaultFirebaseOptions.currentPlatform;
    if (Firebase.apps.isNotEmpty) {
      final current = Firebase.app().options;
      final aligned = current.projectId == expected.projectId &&
          current.appId == expected.appId;
      if (aligned) return;
      await Firebase.app().delete();
    }
    await Firebase.initializeApp(options: expected)
        .timeout(const Duration(seconds: 12));
  }

  static Future<void> startPhoneVerification({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String code, String? message) onFailed,
    required Future<void> Function(String idToken) onAutoVerified,
  }) async {
    resetVerificationSession();
    try {
      await _ensureFirebaseReady();
    } catch (e) {
      onFailed('firebase_init_failed', e.toString());
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          final token = await userCredential.user?.getIdToken(true);
          if (token != null && token.isNotEmpty) {
            await onAutoVerified(token);
          } else {
            onFailed('missing_id_token', null);
          }
        } catch (e) {
          if (e is FirebaseAuthException) {
            onFailed(e.code, e.message);
          } else {
            onFailed('verification_completed_error', e.toString());
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.code, e.message);
      },
      codeSent: (verificationId, forceResendingToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  static Future<String?> confirmSmsCode(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) return null;
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user?.getIdToken(true);
  }
}
