import 'package:flutter/material.dart';

import '../../../../core/backend/backend.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/sign_in_screen.dart';
import '../health_presentation.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/display_settings.dart';
import '../widgets/health_widgets.dart';
import '../widgets/motion.dart';
import '../../domain/entities/family_health_snapshot.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen(
      {super.key,
      required this.snapshot,
      required this.selectedProfileId,
      required this.onSelect});
  final FamilyHealthSnapshot snapshot;
  final String selectedProfileId;
  final ValueChanged<String> onSelect;

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
                      ),
                    ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    key: const ValueKey('add-member'),
                    onPressed: () => showAddMemberSheet(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(l10n.addFamilyMember),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const DisplaySettingsCard(),
                  const SizedBox(height: 16),
                  const _AccountCard(),
                  const SizedBox(height: 16),
                  InfoNote(l10n.sampleDataNote),
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
            ]),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard(
      {required this.member,
      required this.selected,
      required this.reports,
      required this.onTap});
  final FamilyMember member;
  final bool selected;
  final int reports;
  final VoidCallback onTap;

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
