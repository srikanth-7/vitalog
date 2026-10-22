import 'package:flutter/material.dart';

import '../health_presentation.dart';
import '../widgets/health_widgets.dart';
import '../../domain/entities/family_health_snapshot.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {super.key,
      required this.snapshot,
      required this.profile,
      required this.onProfileTap,
      required this.onCategoryTap,
      required this.onResultTap,
      required this.onReportsTap});

  final FamilyHealthSnapshot snapshot;
  final FamilyMember profile;
  final VoidCallback onProfileTap;
  final ValueChanged<HealthCategory> onCategoryTap;
  final ValueChanged<LabResult> onResultTap;
  final VoidCallback onReportsTap;

  @override
  Widget build(BuildContext context) {
    final results = snapshot.resultsFor(profile.id);
    final latestReport = snapshot.reportsFor(profile.id);
    final latestDate =
        latestReport.isEmpty ? null : latestReport.first.reportDate;
    final categories = snapshot.categories
        .where((category) =>
            results.any((r) => r.categoryIds.contains(category.id)))
        .toList();
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            sliver: SliverList.list(children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('FAMILY HEALTH',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF718078),
                                  fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text('A clearer picture,\ntogether.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.08,
                                  color: const Color(0xFF18231F))),
                    ])),
                IconButton.filledTonal(
                    onPressed: onProfileTap,
                    icon: const Icon(Icons.people_alt_outlined),
                    tooltip: 'Switch family profile'),
              ]),
              const SizedBox(height: 22),
              ProfilePicker(profile: profile, onTap: onProfileTap),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: const Color(0xFF173D35),
                    borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.calendar_month_outlined,
                          color: Color(0xFFD4EBDD))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('LATEST REPORT',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: const Color(0xFFB8D5C9),
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(
                            latestDate == null
                                ? 'No reports yet'
                                : formatDate(latestDate),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                      ])),
                  TextButton(
                      onPressed: onReportsTap,
                      child: const Text('Reports',
                          style: TextStyle(color: Color(0xFFD4EBDD)))),
                ]),
              ),
              const SizedBox(height: 26),
              SectionHeading(
                  title: 'Health categories',
                  action: 'See all',
                  onAction: () => onCategoryTap(categories.isEmpty
                      ? snapshot.categories.first
                      : categories.first)),
              const SizedBox(height: 13),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final matching = results
                      .where((r) => r.categoryIds.contains(category.id))
                      .toList();
                  final latest = matching.isEmpty ? null : matching.first;
                  final flagged = matching
                      .where((r) =>
                          r.status == ResultStatus.high ||
                          r.status == ResultStatus.low)
                      .length;
                  return CategoryCard(
                      category: category,
                      testCount: matching.length,
                      lastDate: latest?.reportDate,
                      flaggedCount: flagged,
                      onTap: () => onCategoryTap(category));
                },
              ),
              const SizedBox(height: 26),
              SectionHeading(
                  title: 'Recent results',
                  action: 'All results',
                  onAction: () => onCategoryTap(snapshot.categories.first)),
              const SizedBox(height: 6),
              if (results.isEmpty)
                const EmptyMessage(
                    title: 'No results yet',
                    message:
                        'Add a report to begin a timeline for this family member.')
              else
                ...results.take(5).map((result) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ResultTile(
                        result: result, onTap: () => onResultTap(result)))),
              const SizedBox(height: 18),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEAF1ED),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 19, color: Color(0xFF4C665C)),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'Lab ranges can vary. Status labels in this sample reflect the range printed with each result; they are not a diagnosis.',
                                style: TextStyle(
                                    color: Color(0xFF53645C),
                                    height: 1.4,
                                    fontSize: 12)))
                      ])),
            ]),
          ),
        ]),
      ),
    );
  }
}
