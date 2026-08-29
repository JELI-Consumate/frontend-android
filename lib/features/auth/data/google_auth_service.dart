import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web OAuth Client ID (bukan Android Client ID) — dipakai sebagai audience
/// supaya `access_token` yang didapat bisa diverifikasi backend lewat
/// Socialite. Sama dengan `GOOGLE_CLIENT_ID` di backend/.env.
const _serverClientId =
    '783775692011-94t7r2bhg8m3tpo8prgbeun7v6aha2ka.apps.googleusercontent.com';

const _scopes = <String>['email', 'profile'];

class GoogleAuthService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Return `null` kalau user membatalkan pemilihan akun — bukan error.
  Future<String?> signInAndGetAccessToken() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final authorization = await account.authorizationClient.authorizeScopes(
      _scopes,
    );
    return authorization.accessToken;
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});
