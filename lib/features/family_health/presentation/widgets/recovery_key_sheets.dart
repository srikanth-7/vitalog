import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/backend/backend.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';

/// Shown once, right after the first encrypted Sync made the account key
/// (and again from the Family tab). The key also lives in iCloud Keychain
/// on iPhones; "Save to my passwords" hands it to the phone's own password
/// manager (Google Password Manager on Android), tied to the user's account.
Future<void> showRecoveryKeySheet(BuildContext context, String key) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) => _SaveKeySheet(recoveryKey: key),
    );

class _SaveKeySheet extends StatefulWidget {
  const _SaveKeySheet({required this.recoveryKey});
  final String recoveryKey;
  @override
  State<_SaveKeySheet> createState() => _SaveKeySheetState();
}

class _SaveKeySheetState extends State<_SaveKeySheet> {
  late final _user =
      TextEditingController(text: Backend.userEmail ?? context.l10n.appTitle);
  late final _key = TextEditingController(text: widget.recoveryKey);
  final _keyFocus = FocusNode();

  @override
  void dispose() {
    _user.dispose();
    _key.dispose();
    _keyFocus.dispose();
    super.dispose();
  }

  /// The system's own "Save password?" prompt: focusing the field opens the
  /// autofill session, finishing it with save asks the password manager.
  void _saveToPasswords() {
    _key.text = widget.recoveryKey;
    _keyFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => TextInput.finishAutofillContext(shouldSave: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final mono = TextStyle(
        fontFamily: 'Menlo',
        fontFamilyFallback: const ['monospace', 'Courier'],
        color: c.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.key_rounded, size: 40, color: c.brand),
              const SizedBox(height: 12),
              Text(l10n.recoveryKeyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(l10n.recoveryKeyBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textPrimary)),
              if (Platform.isIOS) ...[
                const SizedBox(height: 8),
                Text(l10n.recoveryKeyICloud,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textMuted)),
              ],
              const SizedBox(height: 16),
              // Kept off-screen-simple: the account name the password
              // manager files the key under.
              Offstage(
                child: TextField(
                    controller: _user,
                    autofillHints: const [AutofillHints.username]),
              ),
              TextField(
                key: const ValueKey('recovery-key-text'),
                controller: _key,
                focusNode: _keyFocus,
                autofillHints: const [AutofillHints.newPassword],
                maxLines: 3,
                minLines: 2,
                style: mono,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: c.canvas,
                    border: InputBorder.none),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('recovery-key-save'),
                onPressed: _saveToPasswords,
                icon: const Icon(Icons.password_rounded),
                label: Text(l10n.recoveryKeySave),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.recoveryKey));
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(content: Text(l10n.recoveryKeyCopied)));
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(l10n.recoveryKeyCopy),
              ),
              TextButton(
                key: const ValueKey('recovery-key-done'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.recoveryKeyDone),
              ),
              Text(l10n.recoveryKeyLater,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A new or reset phone: the backup is sealed with a key it doesn't hold.
/// The field accepts the password manager's autofill, a paste, or typing.
Future<void> askRecoveryKey(BuildContext context) async {
  final bloc = context.read<HealthBloc>();
  final text = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _EnterKeySheet(),
  );
  if (text != null && text.trim().isNotEmpty) bloc.add(UseRecoveryKey(text));
}

class _EnterKeySheet extends StatefulWidget {
  const _EnterKeySheet();
  @override
  State<_EnterKeySheet> createState() => _EnterKeySheetState();
}

class _EnterKeySheetState extends State<_EnterKeySheet> {
  final _key = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    void submit() => Navigator.of(context).pop(_key.text);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.key_rounded, size: 40, color: c.brand),
              const SizedBox(height: 12),
              Text(l10n.recoveryKeyAskTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(l10n.recoveryKeyAskBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('recovery-key-input'),
                controller: _key,
                autofocus: true,
                autofillHints: const [AutofillHints.password],
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                maxLines: 3,
                minLines: 2,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                    hintText: l10n.recoveryKeyHint,
                    filled: true,
                    fillColor: c.canvas,
                    border: InputBorder.none),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('recovery-key-use'),
                onPressed: submit,
                child: Text(l10n.recoveryKeyUse),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.recoveryKeyNotNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
