import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';

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
