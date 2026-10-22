import 'package:flutter/material.dart';

import '../health_presentation.dart';

class ProfilePicker extends StatelessWidget {
  const ProfilePicker({super.key, required this.profile, required this.onTap});
  final FamilyMember profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EAE6))),
          child: Row(children: [
            MemberAvatar(member: profile, size: 44),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('VIEWING HEALTH FOR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF7B8981),
                          letterSpacing: .8,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(profile.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF18231F)))
                ])),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF53645C)),
          ]),
        ),
      );
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.size = 48});
  final FamilyMember member;
  final double size;
  @override
  Widget build(BuildContext context) => CircleAvatar(
      radius: size / 2,
      backgroundColor: member.color,
      child: Text(member.initials,
          style: TextStyle(
              color: const Color(0xFF263B33),
              fontWeight: FontWeight.w700,
              fontSize: size * .28)));
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
      {super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF18231F),
                    fontWeight: FontWeight.w700))),
        if (action != null)
          TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      color: Color(0xFF247A68), fontWeight: FontWeight.w700)))
      ]);
}

class CategoryCard extends StatelessWidget {
  const CategoryCard(
      {super.key,
      required this.category,
      required this.testCount,
      required this.lastDate,
      required this.flaggedCount,
      required this.onTap});
  final HealthCategory category;
  final int testCount;
  final DateTime? lastDate;
  final int flaggedCount;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8ECE9))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: category.color.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(11)),
                        child: Icon(category.icon,
                            size: 19, color: category.color)),
                    const Spacer(),
                    if (flaggedCount > 0)
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFEFEA),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('$flaggedCount review',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFAC5543),
                                  fontWeight: FontWeight.w700)))
                  ]),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF24322C),
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                            lastDate == null
                                ? '$testCount tests'
                                : '$testCount tests · ${formatDate(lastDate!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF78867F)))
                      ]),
                ]),
          ),
        ),
      );
}

class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.result, required this.onTap});
  final LabResult result;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = result.status == ResultStatus.withinRange
        ? const Color(0xFF287D65)
        : (result.status == ResultStatus.needsReview
            ? const Color(0xFF9A7735)
            : const Color(0xFFB35A45));
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(result.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF26332D))),
                    const SizedBox(height: 5),
                    Text(formatDate(result.reportDate),
                        style: const TextStyle(
                            color: Color(0xFF7C8982), fontSize: 12)),
                    const SizedBox(height: 9),
                    StatusPill(status: result.status)
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(result.value,
                    style: TextStyle(
                        color: color,
                        fontSize: 21,
                        fontWeight: FontWeight.w700)),
                if (result.unit.isNotEmpty)
                  Text(result.unit,
                      style: const TextStyle(
                          color: Color(0xFF78867F), fontSize: 12)),
                const SizedBox(height: 5),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF8D9992), size: 19)
              ]),
            ])),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final ResultStatus status;
  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    Color bg;
    if (status == ResultStatus.withinRange) {
      label = 'Within lab range';
      color = const Color(0xFF26775F);
      bg = const Color(0xFFE6F3EC);
    } else if (status == ResultStatus.high) {
      label = 'High · per report';
      color = const Color(0xFFA64E41);
      bg = const Color(0xFFFFECE7);
    } else if (status == ResultStatus.low) {
      label = 'Low · per report';
      color = const Color(0xFFA64E41);
      bg = const Color(0xFFFFECE7);
    } else {
      label = 'Needs review';
      color = const Color(0xFF8B6B2E);
      bg = const Color(0xFFFFF4DB);
    }
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)));
  }
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({super.key, required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(message,
            style: const TextStyle(color: Color(0xFF718078), height: 1.4))
      ]));
}

class PageTitle extends StatelessWidget {
  const PageTitle(
      {super.key, required this.eyebrow, required this.title, this.subtitle});
  final String eyebrow;
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFF718078),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF18231F))),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!,
              style: const TextStyle(color: Color(0xFF718078), height: 1.4))
        ]
      ]));
}
