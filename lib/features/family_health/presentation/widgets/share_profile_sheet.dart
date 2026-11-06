import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/backend/backend.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/sign_in_screen.dart';
import '../../domain/entities/sharing.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../bloc/health_bloc.dart';
import '../health_presentation.dart';
import 'apple_menus.dart';
import 'health_widgets.dart';

/// The family card for one member (docs/SHARING.md): who can see their
/// reports, invites still waiting, and "Invite someone", which uploads the
/// profile (sealed) and opens the phone's share sheet with a one-use link.
Future<void> showShareProfileSheet(BuildContext context, FamilyMember member) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(member: member),
    );

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.member});
  final FamilyMember member;
  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  late final _bloc = context.read<HealthBloc>();
  Future<ProfileSharing>? _sharing;
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
    setState(() => _sharing = _bloc.sharingFor(widget.member.id));
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      _load();
    } on CannotShare {
      _error = l10n.shareSample;
    } on RecoveryKeyNeeded {
      // The bloc asks for the recovery key; this sheet steps aside.
      if (mounted) Navigator.pop(context);
      return;
    } catch (_) {
      _error = l10n.shareFailed;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _invite(BuildContext anchor) => _run(() async {
        final l10n = context.l10n;
        final name = widget.member.name;
        // iPad / open Duo: the share popover points at the button.
        final box = anchor.findRenderObject() as RenderBox?;
        final origin =
            box == null ? null : box.localToGlobal(Offset.zero) & box.size;
        final out = await _bloc.inviteTo(widget.member.id);
        await SharePlus.instance.share(ShareParams(
          text: l10n.shareMessage(name, out.link.toString()),
          subject: l10n.shareSubject(name),
          sharePositionOrigin: origin,
        ));
      });

  Future<void> _remove(SharedPerson person) async {
    final l10n = context.l10n;
    final who = person.name ?? l10n.shareSomeone;
    final ok = await showDestructiveSheet(
      context,
      title: l10n.shareRemoveTitle(widget.member.name, who),
      message: l10n.shareRemoveMessage(who),
      confirmLabel: l10n.shareRemoveConfirm,
      cancelLabel: l10n.cancel,
    );
    if (ok) {
      await _run(() => _bloc.removeAccess(widget.member.id, person.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final name = widget.member.name;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              MemberAvatar(member: widget.member, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.shareMember(name),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: c.textPrimary)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(l10n.shareIntro(name),
                style: TextStyle(color: c.textSecondary, height: 1.4)),
            const SizedBox(height: 16),
            if (!Backend.configured)
              InfoNote(l10n.noticeBackendNotConfigured)
            else if (!Backend.signedIn) ...[
              InfoNote(l10n.shareSignIn),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute<void>(
                        builder: (_) => const SignInScreen())),
                icon: const Icon(Icons.login_rounded),
                label: Text(l10n.signIn),
              ),
            ] else
              _body(context),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return FutureBuilder<ProfileSharing>(
      future: _sharing,
      builder: (context, snap) {
        final sharing = snap.data;
        final people = sharing?.people ?? const <SharedPerson>[];
        final pending = sharing?.pending ?? const <PendingInvite>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (people.length > 1 || pending.isNotEmpty) ...[
              Eyebrow(l10n.sharePeople),
              const SizedBox(height: 4),
              for (final p in people)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline_rounded, color: c.brand),
                  title: Text(p.isYou
                      ? (p.name == null
                          ? l10n.shareYouPlain
                          : l10n.shareYou(p.name!))
                      : p.name ?? l10n.shareSomeone),
                  trailing: p.isYou || _busy
                      ? null
                      : TextButton(
                          onPressed: () => _remove(p),
                          style:
                              TextButton.styleFrom(foregroundColor: c.danger),
                          child: Text(l10n.shareRemove)),
                ),
              for (final i in pending)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.schedule_rounded, color: c.textMuted),
                  title: Text(l10n.sharePending),
                  subtitle:
                      Text(l10n.sharePendingUntil(formatDate(i.expiresAt))),
                  trailing: _busy
                      ? null
                      : TextButton(
                          onPressed: () => _run(() => _bloc.cancelInvite(i.id)),
                          child: Text(l10n.shareCancelInvite)),
                ),
              const SizedBox(height: 8),
            ],
            if (snap.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    Text(l10n.shareFailed, style: TextStyle(color: c.danger)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: c.danger)),
              ),
            Builder(
              builder: (anchor) => FilledButton.icon(
                key: const ValueKey('invite-someone'),
                onPressed: _busy ? null : () => _invite(anchor),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share_rounded),
                label: Text(l10n.shareInvite),
              ),
            ),
            const SizedBox(height: 10),
            Text(l10n.shareUploadNote(widget.member.name),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          ],
        );
      },
    );
  }
}
