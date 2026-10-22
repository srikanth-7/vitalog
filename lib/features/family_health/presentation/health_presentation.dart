import 'package:flutter/material.dart';

import '../domain/entities/family_member.dart';
import '../domain/entities/health_category.dart';
import '../domain/entities/lab_result.dart';

export '../domain/entities/family_member.dart';
export '../domain/entities/health_category.dart';
export '../domain/entities/health_report.dart';
export '../domain/entities/lab_result.dart';

extension FamilyMemberPresentation on FamilyMember {
  Color get color => Color(colorValue);
}

extension HealthCategoryPresentation on HealthCategory {
  Color get color => Color(colorValue);

  IconData get icon => _categoryIcons[iconKey] ?? Icons.category_outlined;
}

const _categoryIcons = <String, IconData>{
  'bloodtype_outlined': Icons.bloodtype_outlined,
  'water_drop_outlined': Icons.water_drop_outlined,
  'filter_alt_outlined': Icons.filter_alt_outlined,
  'spa_outlined': Icons.spa_outlined,
  'monitor_heart_outlined': Icons.monitor_heart_outlined,
  'bubble_chart_outlined': Icons.bubble_chart_outlined,
  'wb_sunny_outlined': Icons.wb_sunny_outlined,
  'grain': Icons.grain,
  'opacity_outlined': Icons.opacity_outlined,
};

String formatDate(DateTime date) =>
    '${_month(date.month)} ${date.day}, ${date.year}';

String _month(int month) => const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month];

String statusLabel(ResultStatus status) {
  switch (status) {
    case ResultStatus.withinRange:
      return 'Within lab range';
    case ResultStatus.high:
      return 'High';
    case ResultStatus.low:
      return 'Low';
    case ResultStatus.needsReview:
      return 'Needs review';
  }
}
