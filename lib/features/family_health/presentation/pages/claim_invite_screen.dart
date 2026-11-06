import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/backend/backend.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/sign_in_screen.dart';
import '../../domain/entities/sharing.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../bloc/health_bloc.dart';
import '../health_presentation.dart';
import '../widgets/health_widgets.dart';

/// Opened from an invite link (or one pasted on the Family tab): says who
/// shared whom, asks "Who is Ramesh to you?" and adds them to the family.
/// Nothing is used up until "Add to my family"; "Not now" leaves the link
/// working.
class ClaimInviteScreen extends StatefulWidget {
  const ClaimInviteScreen({super.key, required this.link});
  final String link;

  /// Pushes the screen on the root navigator (over any sheet or pane).
  static Future<void> open(BuildContext context, String link) =>
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
          builder: (_) => ClaimInviteScreen(link: link)));

  @override
  State<ClaimInviteScreen> createState() => _ClaimInviteScreenState();
}

class _ClaimInviteScreenState extends State<ClaimInviteScreen> {
  late final _bloc = context.read<HealthBloc>();
  Future<InvitePreview>? _preview;
  String _relation = 'Parent';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Backend.signedInUser.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    Backend.signedInUser.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!mounted || !Backend.signedIn) return;
    setState(() => _preview = _bloc.previewInvite(widget.link));
  }

  Future<void> _accept() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final out = await _bloc.acceptInvite(widget.link, relation: _relation);
      if (!mounted) return;
      if (out.memberId != null) {
        Navigator.of(context).pop();
        return;
      }
      _error = _statusText(l10n, out.status);
    } on RecoveryKeyNeeded {
      _error = l10n.claimRecoveryKey;
    } catch (_) {
      _error = l10n.claimFailed;
    }
    if (mounted) setState(() => _busy = false);
  }

  static String _statusText(AppLocalizations l10n, InviteStatus s) =>
      switch (s) {
        InviteStatus.used => l10n.claimUsed,
        InviteStatus.expired => l10n.claimExpired,
        InviteStatus.limited => l10n.claimLimited,
        InviteStatus.invalid => l10n.claimInvalid,
        InviteStatus.already => l10n.claimAlready,
        InviteStatus.gone || InviteStatus.ok => l10n.claimGone,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.claimTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            if (!Backend.configured)
              InfoNote(l10n.noticeBackendNotConfigured)
            else if (!Backend.signedIn) ...[
              InfoNote(l10n.claimSignIn),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const SignInScreen())),
                icon: const Icon(Icons.login_rounded),
                label: Text(l10n.signIn),
              ),
            ] else
              FutureBuilder<InvitePreview>(
                future: _preview,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _Problem(l10n.claimFailed, onRetry: _load);
                  }
                  final p = snap.data;
                  if (p == null) {
                    return const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(child: CircularProgressIndicator()));
                  }
                  return switch (p.status) {
                    InviteStatus.ok => _offer(context, p),
                    InviteStatus.already => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Problem(l10n.claimAlready),
                            const SizedBox(height: 16),
                            FilledButton(
                                onPressed: _busy ? null : _accept,
                                child: Text(l10n.claimOpen)),
                          ]),
                    _ => _Problem(_statusText(l10n, p.status)),
                  };
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _offer(BuildContext context, InvitePreview p) {
    final l10n = context.l10n;
    final c = context.colors;
    final name = p.name ?? l10n.shareSomeone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: c.brandSoft,
            child: Text(FamilyMember.initialsOf(name),
                style: TextStyle(
                    color: c.brand, fontWeight: FontWeight.w700, fontSize: 22)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
            p.from == null
                ? l10n.claimSharedNoFrom(name)
                : l10n.claimShared(p.from!, name),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 6),
        Text(l10n.reportCount(p.reports),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary)),
        const SizedBox(height: 24),
        Text(l10n.claimWho(name),
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in relationKeys)
            ChoiceChip(
                label: Text(relationName(l10n, k)),
                selected: _relation == k,
                onSelected: (_) => setState(() => _relation = k)),
        ]),
        const SizedBox(height: 20),
        InfoNote(l10n.claimPrivacy(name)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: c.danger)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('accept-invite'),
          onPressed: _busy ? null : _accept,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.claimAccept),
        ),
        const SizedBox(height: 8),
        TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.claimNotNow)),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem(this.text, {this.onRetry});
  final String text;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InfoNote(text),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ]),
      );
}

/// Opens [ClaimInviteScreen] for invite links that arrive while the app runs
/// or that launched it (app links / the web page's hand-over).
class InviteLinkListener extends StatefulWidget {
  const InviteLinkListener(
      {super.key, required this.child, required this.links});
  final Widget child;

  /// Incoming links (`AppLinks().uriLinkStream` in the app, which also
  /// delivers the one that launched it).
  final Stream<Uri> links;
  @override
  State<InviteLinkListener> createState() => _InviteLinkListenerState();
}

class _InviteLinkListenerState extends State<InviteLinkListener> {
  late final _sub = widget.links.listen((uri) {
    final link = uri.toString();
    // Sign-in callbacks share the stream; only invite links open here.
    if (HealthBloc.isInviteLink(link) && mounted) {
      ClaimInviteScreen.open(context, link);
    }
  }, onError: (Object _) {}); // no plugin (tests, desktop): no links

  @override
  void initState() {
    super.initState();
    _sub;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Open an invite link" (Family tab): for links that didn't open the app
/// by themselves — paste the message or the link and go.
Future<void> showPasteInviteSheet(BuildContext context) async {
  final link = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _PasteSheet(),
  );
  if (link != null && context.mounted) {
    await ClaimInviteScreen.open(context, link);
  }
}

class _PasteSheet extends StatefulWidget {
  const _PasteSheet();
  @override
  State<_PasteSheet> createState() => _PasteSheetState();
}

class _PasteSheetState extends State<_PasteSheet> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _open() {
    if (HealthBloc.isInviteLink(_text.text)) {
      Navigator.pop(context, _text.text);
    } else {
      setState(() => _error = context.l10n.claimInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.pasteInviteTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('invite-link-field'),
              controller: _text,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration:
                  InputDecoration(hintText: 'https://…', errorText: _error),
              onSubmitted: (_) => _open(),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _open, child: Text(l10n.pasteInviteOpen)),
          ],
        ),
      ),
    );
  }
}
