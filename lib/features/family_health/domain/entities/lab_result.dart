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
    this.reportId,
    this.edited = false,
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

  /// The uploaded report this value was extracted from (null for sample data).
  final String? reportId;

  /// True once the user has corrected what was read from the report.
  final bool edited;

  LabResult copyWith({
    String? name,
    List<String>? categoryIds,
    String? value,
    String? unit,
    String? referenceRange,
    ResultStatus? status,
    bool? edited,
  }) =>
      LabResult(
        id: id,
        profileId: profileId,
        name: name ?? this.name,
        categoryIds: categoryIds ?? this.categoryIds,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        referenceRange: referenceRange ?? this.referenceRange,
        status: status ?? this.status,
        reportDate: reportDate,
        lab: lab,
        collectionDate: collectionDate,
        previousValue: previousValue,
        reportId: reportId,
        edited: edited ?? this.edited,
      );
}
