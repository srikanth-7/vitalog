import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/backend/backend.dart';
import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/sign_in_screen.dart';
import '../../../reminders/reminders_screen.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../health_presentation.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/apple_menus.dart';
import '../widgets/display_settings.dart';
import '../widgets/header_wash.dart';
import '../widgets/health_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/share_profile_sheet.dart';
import 'claim_invite_screen.dart';
import '../../domain/entities/family_health_snapshot.dart';

enum FamilyPart { all, people, settings }

class ProfileScreen extends StatelessWidget {
  const ProfileScreen(
      {super.key,
      required this.snapshot,
      required this.selectedProfileId,
      required this.onSelect,
      this.onAddMember,
      this.part = FamilyPart.all});
  final FamilyHealthSnapshot snapshot;
  final String selectedProfileId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onAddMember;

  /// People, settings or both: one per pane on wide screens.
  final FamilyPart part;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final people = part != FamilyPart.settings;
    final settings = part != FamilyPart.people;
    return Scaffold(
      body: HeaderWash(
          child: SafeArea(
        bottom: false, // scrolls on under the frosted tray
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            people
                ? PageTitle(
                    eyebrow: l10n.familyEyebrow,
                    title: l10n.familyTitle,
                    subtitle: l10n.familySubtitle,
                  )
                : PageTitle(
                    eyebrow: '',
                    title: l10n.settingsTitle,
                    subtitle: l10n.settingsSubtitle),
            Expanded(
              child: ScrollCut(
                  child: ListView(
                padding: EdgeInsets.fromLTRB(
                    20, 4, 20, 24 + MediaQuery.paddingOf(context).bottom),
                children: [
                  if (people && snapshot.members.isEmpty) ...[
                    _FamilyEmptyCard(onAddMember: onAddMember),
                    const SizedBox(height: 16),
                  ],
                  if (people)
                    for (final (i, member) in snapshot.members.indexed)
                      Reveal(
                        index: i,
                        child: _ProfileCard(
                          member: member,
                          selected: member.id == selectedProfileId,
                          reports: snapshot.reports
                              .where((report) => report.profileId == member.id)
                              .length,
                          onTap: () => onSelect(member.id),
                          onLongPress: () => _memberActions(
                              context,
                              member,
                              snapshot.reports
                                  .where(
                                      (report) => report.profileId == member.id)
                                  .length),
                        ),
                      ),
                  const SizedBox(height: 4),
                  if (people && snapshot.members.isNotEmpty) ...[
                    OutlinedButton.icon(
                      key: const ValueKey('add-member'),
                      onPressed:
                          onAddMember ?? () => showAddMemberSheet(context),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(l10n.addFamilyMember),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (settings) ...[
                    _RowGroup(
                      child: ListTile(
                        key: const ValueKey('open-reminders'),
                        leading: _RowIcon(Icons.alarm_outlined,
                            color: context.colors.brand),
                        title: Text(l10n.remindersTitle),
                        subtitle: Text(l10n.remindersRowSubtitle),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: context.colors.textMuted),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const RemindersScreen())),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RowGroup(
                      child: ListTile(
                        key: const ValueKey('open-invite'),
                        leading: _RowIcon(Icons.link_rounded,
                            color: context.colors.brand),
                        title: Text(l10n.openInviteRow),
                        subtitle: Text(l10n.openInviteRowDetail),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: context.colors.textMuted),
                        onTap: () => showPasteInviteSheet(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const DisplaySettingsCard(),
                    const SizedBox(height: 16),
                    _AccountCard(snapshot: snapshot),
                  ],
                ],
              )),
            ),
          ],
        ),
      )),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.snapshot});
  final FamilyHealthSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    // Rebuilds on sign-in / sign-out.
    return ListenableBuilder(
      listenable: Backend.googleUser,
      builder: (context, _) => StreamBuilder<Object>(
        stream: Backend.authChanges,
        builder: (context, _) => AccountSection(
          email: Backend.userEmail,
          name: greetingName(Backend.displayName) == null
              ? null
              : Backend.displayName,
          members: snapshot.members.length,
          reports: snapshot.reports.where((r) => !r.isSample).length,
          unsynced: snapshot.unsyncedCount,
          // Full screen even from the settings pane.
          onSignIn: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(builder: (_) => const SignInScreen())),
          onSignOut: Backend.signOut,
          onDeleteAccount: () => confirmDeleteAccount(context),
          onRecoveryKey: () =>
              context.read<HealthBloc>().add(ShowRecoveryKey()),
        ),
      ),
    );
  }
}

/// Who is signed in, then Sign out, then Delete account in a group of its
/// own so the irreversible one is never a mis-tap away. Signed out: one
/// Sign in button.
class AccountSection extends StatelessWidget {
  const AccountSection(
      {super.key,
      required this.email,
      required this.name,
      required this.members,
      required this.reports,
      required this.unsynced,
      required this.onSignIn,
      required this.onSignOut,
      required this.onDeleteAccount,
      this.onRecoveryKey});
  final String? email;
  final String? name;
  final int members;
  final int reports;
  final int unsynced;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onRecoveryKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final signedIn = email != null;
    final title = name ?? (signedIn ? email! : l10n.accountTitle);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Eyebrow(l10n.accountTitle),
      ),
      TapCard(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            // Initials / cloud glyph repeat the name and status beside it.
            ExcludeSemantics(
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                    shape: const CircleBorder(), color: c.brandSoft),
                child: signedIn
                    ? Text(FamilyMember.initialsOf(title),
                        style: TextStyle(
                            color: c.brand,
                            fontWeight: FontWeight.w700,
                            fontSize: 18))
                    : Icon(Icons.cloud_off_outlined, color: c.brand),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                        signedIn && name != null
                            ? email!
                            : signedIn
                                ? l10n.signedInAs(email!)
                                : l10n.signedOutMessage,
                        style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  ]),
            ),
          ]),
          const SizedBox(height: 14),
          if (signedIn)
            Row(children: [
              _StatTile(value: members, label: l10n.accountStatMembers),
              const SizedBox(width: 8),
              _StatTile(value: reports, label: l10n.accountStatReports),
              const SizedBox(width: 8),
              _StatTile(value: unsynced, label: l10n.accountStatUnsynced),
            ])
          else
            FilledButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login_rounded),
                label: Text(l10n.signIn)),
        ]),
      ),
      if (signedIn) ...[
        const SizedBox(height: 12),
        _RowGroup(
          child: ListTile(
            leading: _RowIcon(Icons.logout_rounded, color: c.brand),
            title: Text(l10n.signOut),
            subtitle: Text(l10n.signOutDetail),
            trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
            onTap: onSignOut,
          ),
        ),
        if (onRecoveryKey != null) ...[
          const SizedBox(height: 12),
          _RowGroup(
            child: ListTile(
              leading: _RowIcon(Icons.key_rounded, color: c.brand),
              title: Text(l10n.recoveryKeyRow),
              subtitle: Text(l10n.recoveryKeyRowDetail),
              trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
              onTap: onRecoveryKey,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _RowGroup(
          child: ListTile(
            leading: _RowIcon(Icons.delete_forever_outlined, color: c.danger),
            title: Text(l10n.deleteAccountButton,
                style: TextStyle(color: c.danger, fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.deleteAccountDetail),
            onTap: onDeleteAccount,
          ),
        ),
      ],
    ]);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: AppShape.decoration(radius: AppRadius.sm, color: c.canvas),
        child: Column(children: [
          Text('$value',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textMuted, fontSize: 11)),
        ]),
      ),
    );
  }
}

/// A grouped settings row: one card, no padding, so the ListTile's own
/// ink fills it.
class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
        color: context.colors.surface,
        shape: AppShape.of(AppRadius.lg,
            side: BorderSide(color: context.colors.border)),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon, {required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: ShapeDecoration(
            shape: const CircleBorder(), color: color.withValues(alpha: .12)),
        child: Icon(icon, color: color, size: 20),
      );
}

class _FamilyEmptyCard extends StatelessWidget {
  const _FamilyEmptyCard({this.onAddMember});
  final VoidCallback? onAddMember;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return TapCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: c.brandSoft, borderRadius: BorderRadius.circular(18)),
            child:
                Icon(Icons.family_restroom_rounded, color: c.brand, size: 28)),
        const SizedBox(height: 14),
        Text(l10n.emptyFamilyTitle,
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        const SizedBox(height: 6),
        Text(l10n.emptyFamilyMessage,
            style:
                TextStyle(color: c.textSecondary, height: 1.45, fontSize: 13)),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('add-first-member-family'),
          onPressed: onAddMember ?? () => showAddMemberSheet(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(l10n.addFamilyMember),
        ),
      ]),
    );
  }
}

/// Long-press on a member: share, edit their details, or remove them.
Future<void> _memberActions(
    BuildContext context, FamilyMember member, int reportCount) async {
  final l10n = context.l10n;
  final c = context.colors;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            key: const ValueKey('share-member'),
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(l10n.shareMember(member.name)),
            onTap: () => Navigator.pop(context, 'share')),
        ListTile(
            key: const ValueKey('edit-member'),
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.editMember),
            onTap: () => Navigator.pop(context, 'edit')),
        ListTile(
            leading: Icon(Icons.person_remove_outlined, color: c.danger),
            title: Text(l10n.memberRemoveConfirm,
                style: TextStyle(color: c.danger)),
            onTap: () => Navigator.pop(context, 'remove')),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (!context.mounted) return;
  if (action == 'share') {
    await showShareProfileSheet(context, member);
  } else if (action == 'edit') {
    await showAddMemberSheet(context, editing: member);
  } else if (action == 'remove') {
    await confirmRemoveMember(context, member, reportCount);
  }
}

/// Long-press on a member: the destructive ask (remove from this phone and,
/// when signed in, the account's backup). With reports, the sheet says how
/// many go with them, so nothing is removed that the person didn't see.
Future<void> confirmRemoveMember(
    BuildContext context, FamilyMember member, int reportCount) async {
  final l10n = context.l10n;
  final bloc = context.read<HealthBloc>();
  if (reportCount > 0) {
    final ok = await showDestructiveSheet(
      context,
      title: l10n.memberRemoveWithReports(member.name, reportCount),
      message: l10n.memberRemoveWithReportsDetail,
      note: Backend.signedIn ? l10n.memberRemoveSyncedNote : null,
      confirmLabel: l10n.memberRemoveWithReportsConfirm,
      cancelLabel: l10n.cancel,
    );
    if (ok) bloc.add(DeleteFamilyMember(member, withReports: true));
    return;
  }
  final ok = await showDestructiveSheet(
    context,
    title: l10n.memberRemoveNamed(member.name),
    message: l10n.memberRemoveDetail,
    note: Backend.signedIn ? l10n.memberRemoveSyncedNote : null,
    confirmLabel: l10n.memberRemoveConfirm,
    cancelLabel: l10n.cancel,
  );
  if (ok) bloc.add(DeleteFamilyMember(member));
}

/// "Delete account", tucked inside the account card: removes the signed-in
/// user's Supabase account (its rows go by FK cascade) and clears this
/// phone's copy. Another account's records are never in scope, so a shared
/// viewer keeps what is theirs.
Future<void> confirmDeleteAccount(BuildContext context) async {
  final l10n = context.l10n;
  final bloc = context.read<HealthBloc>();
  final ok = await showDestructiveSheet(
    context,
    title: l10n.deleteAccountTitle,
    message: l10n.deleteAccountMessage,
    confirmLabel: l10n.deleteAccountConfirm,
    cancelLabel: l10n.cancel,
  );
  if (ok) bloc.add(DeleteAccount());
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard(
      {required this.member,
      required this.selected,
      required this.reports,
      required this.onTap,
      this.onLongPress});
  final FamilyMember member;
  final bool selected;
  final int reports;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // The check mark and border say "selected" to the eye only.
      child: Semantics(
        selected: selected,
        child: TapCard(
          onTap: onTap,
          onLongPress: onLongPress,
          padding: const EdgeInsets.all(16),
          borderColor: selected ? c.brand : null,
          child: Row(
            children: [
              MemberAvatar(member: member, size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                        l10n.relationAge(
                            relationName(l10n, member.relation), member.age),
                        style: TextStyle(color: c.textMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(l10n.reportCount(reports),
                        style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: motion,
                transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween(begin: .6, end: 1.0).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack)),
                    child: FadeTransition(opacity: animation, child: child)),
                child: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    key: ValueKey(selected),
                    color: selected ? c.brand : c.textDisabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
