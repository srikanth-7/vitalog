import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/backend/backend.dart';
import '../../core/theme/app_theme.dart';

/// Google or email/password sign-in via Supabase Auth. Signing in is only
/// needed for Sync; the rest of the app works offline without an account.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  StreamSubscription<Object>? _auth;

  @override
  void initState() {
    super.initState();
    // Google sign-in completes via deep link; close once a session arrives.
    _auth = Backend.authChanges.listen((_) {
      if (Backend.signedIn && mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _auth?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _toast(l10n.authFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final confirmText = context.l10n.confirmEmailSent;
    await _run(() async {
      if (_creating) {
        final needsConfirm =
            await Backend.signUpWithEmail(email, _password.text);
        if (needsConfirm) _toast(confirmText);
      } else {
        await Backend.signInWithEmail(email, _password.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    if (!Backend.configured) {
      return Scaffold(
          appBar: AppBar(),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noticeBackendNotConfigured,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textSecondary)))));
    }
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text(_creating ? l10n.createAccountTitle : l10n.signInTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(l10n.signInSubtitle,
                style: TextStyle(color: c.textMuted, height: 1.4)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(Backend.signInWithGoogle),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text(l10n.continueWithGoogle),
              style: OutlinedButton.styleFrom(
                  foregroundColor: c.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(children: [
                Expanded(child: Divider(color: c.border)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l10n.orDivider,
                        style: TextStyle(color: c.textMuted))),
                Expanded(child: Divider(color: c.border)),
              ]),
            ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l10n.emailLabel),
              validator: (v) =>
                  v != null && RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())
                      ? null
                      : l10n.emailInvalid,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: [
                _creating ? AutofillHints.newPassword : AutofillHints.password
              ],
              decoration: InputDecoration(labelText: l10n.passwordLabel),
              validator: (v) =>
                  (v ?? '').length >= 8 ? null : l10n.passwordTooShort,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (!_creating)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (!RegExp(r'^\S+@\S+\.\S+$')
                                .hasMatch(_email.text.trim())) {
                              _toast(l10n.emailInvalid);
                              return;
                            }
                            _run(() async {
                              await Backend.resetPassword(_email.text.trim());
                              _toast(l10n.resetSent);
                            });
                          },
                    child: Text(l10n.forgotPassword)),
              ),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_creating
                        ? l10n.createAccountButton
                        : l10n.signInButton)),
            TextButton(
                onPressed: () => setState(() => _creating = !_creating),
                child: Text(_creating ? l10n.haveAccount : l10n.noAccount)),
          ]),
        ),
      ),
    );
  }
}
