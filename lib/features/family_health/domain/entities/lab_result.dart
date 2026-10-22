enum ResultStatus { withinRange, high, low, needsReview }

class LabResult {
  LabResult({
    required this.id,
    required this.profileId,
    required this.name,
    required List<String> categoryIds,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
    required this.reportDate,
    required this.lab,
    this.collectionDate,
    this.previousValue,
  }) : categoryIds = List.unmodifiable(categoryIds);

  final String id;
  final String profileId;
  final String name;
  final List<String> categoryIds;
  final String value;
  final String unit;
  final String referenceRange;
  final ResultStatus status;
  final DateTime reportDate;
  final DateTime? collectionDate;
  final String lab;
  final String? previousValue;
}
