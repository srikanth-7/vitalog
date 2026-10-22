import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase connection + auth. Configured at build time so no keys live in
/// source control:
///
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// Without those defines the app runs fully offline and Sync/Sign-in report
/// that the backend isn't configured.
class Backend {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Deep link Supabase redirects back to after Google sign-in. Must match
  /// CFBundleURLSchemes in ios/Runner/Info.plist and the Supabase
  /// "Redirect URLs" allow-list.
  static const authRedirect = 'com.vitalog.app://login-callback';

  static bool get configured => _url.isNotEmpty && _key.isNotEmpty;

  static Future<void> init() async {
    if (configured) await Supabase.initialize(url: _url, publishableKey: _key);
  }

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static bool get signedIn => configured && _auth.currentUser != null;
  static String? get userEmail => configured ? _auth.currentUser?.email : null;

  static Stream<AuthState> get authChanges =>
      configured ? _auth.onAuthStateChange : const Stream.empty();

  static Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  /// Returns true when the account still needs its email confirmed.
  static Future<bool> signUpWithEmail(String email, String password) async {
    final res = await _auth.signUp(
        email: email, password: password, emailRedirectTo: authRedirect);
    return res.session == null;
  }

  static Future<void> resetPassword(String email) =>
      _auth.resetPasswordForEmail(email, redirectTo: authRedirect);

  /// Opens Google's consent page in the browser; the session arrives via the
  /// [authRedirect] deep link and is reported on [authChanges].
  static Future<void> signInWithGoogle() =>
      _auth.signInWithOAuth(OAuthProvider.google,
          redirectTo: authRedirect,
          authScreenLaunchMode: LaunchMode.externalApplication);

  static Future<void> signOut() => _auth.signOut();
}
