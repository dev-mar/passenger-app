import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';

/// Google Sign-In pasajero — entrega `id_token` para backend `/auth/google`.
class PassengerGoogleSignInService {
  GoogleSignIn? get _client {
    final serverClientId = AppConfig.googleOAuthServerClientId;
    if (serverClientId == null) return null;
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverClientId,
    );
  }

  bool get isConfigured => _client != null;

  Future<String?> signInAndGetIdToken() async {
    final creds = await signInAndGetCredentials();
    return creds?.idToken;
  }

  /// Google Sign-In del dispositivo — token + email para gate SMS.
  Future<({String idToken, String email})?> signInAndGetCredentials() async {
    final client = _client;
    if (client == null) return null;
    final account = await client.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final token = auth.idToken;
    final email = account.email.trim();
    if (token == null || token.trim().isEmpty) return null;
    if (email.isEmpty || !email.contains('@')) return null;
    return (idToken: token.trim(), email: email);
  }

  /// Solo obtiene email de la cuenta Google del dispositivo (sin login backend).
  Future<String?> pickAccountEmail() async {
    final client = _client;
    if (client == null) return null;
    var account = await client.signInSilently();
    account ??= await client.signIn();
    final email = account?.email.trim();
    if (email == null || email.isEmpty || !email.contains('@')) return null;
    return email;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.signOut();
  }
}
