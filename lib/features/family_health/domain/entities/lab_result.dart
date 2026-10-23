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
    this.reviewed = false,
    this.usualRange,
    this.usualSource,
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

  /// True once the user has checked the value against the report (edited it,
  /// or tapped "Looks right"). A result that still can't be judged (no range)
  /// then stops asking for review. Phone-only; never synced.
  final bool reviewed;

  /// Waiting on the user: can't be judged and nobody has checked it yet.
  bool get awaitingReview => status == ResultStatus.needsReview && !reviewed;

  /// Set when the report printed no range and the status was judged against
  /// the app's built-in usual range instead (e.g. "30–100 ng/mL"), with its
  /// source (e.g. "Indian lab convention"). Phone-only; never synced.
  final String? usualRange;
  final String? usualSource;

  bool get judgedByUsualRange => usualRange != null;

  LabResult copyWith({
    String? profileId,
    String? name,
    List<String>? categoryIds,
    String? value,
    String? unit,
    String? referenceRange,
    ResultStatus? status,
    bool? edited,
    bool? reviewed,
    String? usualRange,
    String? usualSource,
    bool clearUsual = false,
  }) =>
      LabResult(
        id: id,
        profileId: profileId ?? this.profileId,
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
        reviewed: reviewed ?? this.reviewed,
        usualRange: clearUsual ? null : (usualRange ?? this.usualRange),
        usualSource: clearUsual ? null : (usualSource ?? this.usualSource),
      );
}
