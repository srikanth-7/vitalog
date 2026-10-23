import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    // Restore a previous Google sign-in without showing any UI.
    try {
      await _initGoogle();
      googleUser.value =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (_) {
      // No Google config on this platform/build: Google stays signed out.
    }
  }

  /// The Google account on this phone, signed in even when Supabase isn't
  /// configured (so Google sign-in can be checked on its own).
  static final googleUser = ValueNotifier<GoogleSignInAccount?>(null);

  /// Name to greet the user with: Google's display name, else the email.
  static String? get displayName {
    final g = googleUser.value;
    if (g != null) return g.displayName ?? g.email;
    final meta = configured ? _auth.currentUser?.userMetadata : null;
    return meta?['full_name'] as String? ?? meta?['name'] as String?;
  }

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static bool get signedIn => configured && _auth.currentUser != null;
  static String? get userEmail =>
      (configured ? _auth.currentUser?.email : null) ?? googleUser.value?.email;

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

  /// Google's "Web application" OAuth client (google-services.json,
  /// client_type 3). It's the audience of the ID token Supabase checks; the
  /// iOS client id comes from GIDClientID in ios/Runner/Info.plist. Client
  /// ids are public, not secrets.
  static const googleWebClientId =
      '773366904535-i0d13bjm4e39o3sj4kohg4jel5g1s7ip.apps.googleusercontent.com';
  static bool _googleReady = false;

  /// Native Google account picker, then the ID token is exchanged for a
  /// Supabase session (reported on [authChanges]). Cancelling is not an
  /// error. Falls back to the browser flow where there's no native picker.
  /// Returns true once a Google account was chosen (false if cancelled).
  static Future<bool> signInWithGoogle() async {
    await _initGoogle();
    final google = GoogleSignIn.instance;
    if (!google.supportsAuthenticate()) {
      if (!configured) return false;
      await _auth.signInWithOAuth(OAuthProvider.google,
          redirectTo: authRedirect,
          authScreenLaunchMode: LaunchMode.externalApplication);
      return false;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      // On Android a missing/mismatched OAuth client (package + SHA-1 not
      // registered) also arrives as "canceled", e.g. "[16] Account reauth
      // failed". Only a real user cancel stays silent.
      final why = e.description ?? '';
      final userCancelled = e.code == GoogleSignInExceptionCode.canceled &&
          (why.isEmpty || why.toLowerCase().contains('user'));
      if (userCancelled) return false;
      throw StateError(
          'Google sign-in failed (${e.code.name}${why.isEmpty ? '' : ': $why'})');
    }
    googleUser.value = account;
    if (configured) {
      final idToken = account.authentication.idToken;
      if (idToken == null) throw StateError('Google returned no ID token.');
      await _auth.signInWithIdToken(
          provider: OAuthProvider.google, idToken: idToken);
    }
    return true;
  }

  static Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(serverClientId: googleWebClientId);
    _googleReady = true;
  }

  static Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    googleUser.value = null;
    if (configured) await _auth.signOut();
  }
}
