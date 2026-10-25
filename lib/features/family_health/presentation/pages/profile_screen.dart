import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/backend/backend.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/sign_in_screen.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../health_presentation.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/apple_menus.dart';
import '../widgets/display_settings.dart';
import '../widgets/health_widgets.dart';
import '../widgets/motion.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../../domain/entities/family_member.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen(
      {super.key,
      required this.snapshot,
      required this.selectedProfileId,
      required this.onSelect,
      this.onAddMember});
  final FamilyHealthSnapshot snapshot;
  final String selectedProfileId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onAddMember;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitle(
              eyebrow: l10n.familyEyebrow,
              title: l10n.familyTitle,
              subtitle: l10n.familySubtitle,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  if (snapshot.members.isEmpty) ...[
                    _FamilyEmptyCard(onAddMember: onAddMember),
                    const SizedBox(height: 16),
                  ],
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
                        onLongPress: () => confirmRemoveMember(
                            context,
                            member,
                            snapshot.reports
                                .where((report) => report.profileId == member.id)
                                .length),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (snapshot.members.isNotEmpty) ...[
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
                  const DisplaySettingsCard(),
                  const SizedBox(height: 16),
                  const _AccountCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    // Rebuilds on sign-in / sign-out.
    return ListenableBuilder(
      listenable: Backend.googleUser,
      builder: (context, _) => StreamBuilder<Object>(
        stream: Backend.authChanges,
        builder: (context, _) {
          final email = Backend.userEmail;
          return TapCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(
                  email == null
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_done_outlined,
                  color: c.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(l10n.accountTitle),
                      const SizedBox(height: 3),
                      Text(
                          email == null
                              ? l10n.signedOutMessage
                              : l10n.signedInAs(email),
                          style:
                              TextStyle(color: c.textSecondary, fontSize: 12)),
                    ]),
              ),
              TextButton(
                onPressed: email == null
                    ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const SignInScreen()))
                    : Backend.signOut,
                child: Text(email == null ? l10n.signIn : l10n.signOut),
              ),
              if (email != null)
                IconButton(
                  tooltip: l10n.deleteAccountButton,
                  icon: const Icon(Icons.person_remove_outlined),
                  color: c.danger,
                  onPressed: () => confirmDeleteAccount(context),
                ),
            ]),
          );
        },
      ),
    );
  }
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

/// Long-press on a member: the destructive ask (remove from this phone and,
/// when signed in, the account's backup). A member with reports can't be
/// removed yet — the bloc answers with the move-or-delete hint instead.
Future<void> confirmRemoveMember(
    BuildContext context, FamilyMember member, int reportCount) async {
  final l10n = context.l10n;
  final bloc = context.read<HealthBloc>();
  if (reportCount > 0) {
    bloc.add(DeleteFamilyMember(member)); // answered with the hint notice
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

class _ProfileCard extends StatelessWidget {  const _ProfileCard(
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
                  Text(l10n.relationAge(member.relation, member.age),
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
              child: Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                  key: ValueKey(selected),
                  color: selected ? c.brand : c.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}
