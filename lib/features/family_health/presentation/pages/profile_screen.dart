import 'package:flutter/material.dart';

import '../health_presentation.dart';
import '../widgets/health_widgets.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageTitle(
              eyebrow: 'Your household',
              title: 'Family profiles',
              subtitle: 'Choose whose health timeline you want to view.',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  for (final member in snapshot.members)
                    _ProfileCard(
                      member: member,
                      selected: member.id == selectedProfileId,
                      reports: snapshot.reports
                          .where((report) => report.profileId == member.id)
                          .length,
                      onTap: () => onSelect(member.id),
                    ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Adding family members will be available when accounts are connected.')),
                    ),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add family member'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF247A68),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(18)),
                    child: const Text(
                      'Profiles and results shown here are sample data stored locally in this prototype.',
                      style: TextStyle(
                          color: Color(0xFF53645C), height: 1.45, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFF247A68)
                    : const Color(0xFFE7ECE8),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                MemberAvatar(member: member, size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name,
                          style: const TextStyle(
                              color: Color(0xFF23312B),
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${member.relation} · ${member.age} years',
                          style: const TextStyle(
                              color: Color(0xFF78867F), fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                          '$reports sample ${reports == 1 ? 'report' : 'reports'}',
                          style: const TextStyle(
                              color: Color(0xFF52645A), fontSize: 11)),
                    ],
                  ),
                ),
                Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected
                        ? const Color(0xFF247A68)
                        : const Color(0xFFBBC5BE)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
