enum ReportStatus { processing, ready, needsReview, failed }

class HealthReport {
  const HealthReport({
    required this.id,
    required this.profileId,
    required this.fileName,
    required this.lab,
    required this.reportDate,
    required this.uploadDate,
    required this.status,
    required this.resultCount,
    this.collectionDate,
    this.filePath,
    this.synced = false,
    this.unsupported = false,
  });

  final String id;
  final String profileId;
  final String fileName;
  final String lab;
  final DateTime reportDate;
  final DateTime uploadDate;
  final DateTime? collectionDate;
  final ReportStatus status;
  final int resultCount;

  /// On-device copy of the original document, if this report was uploaded.
  final String? filePath;

  /// True once the report and its results have been pushed to the backend.
  final bool synced;

  /// Failed because the file type has no readable report text (video, zip,
  /// old .doc…). Kept on the phone only; the server just sees "failed".
  final bool unsupported;

  HealthReport copyWith({
    String? lab,
    DateTime? reportDate,
    DateTime? collectionDate,
    ReportStatus? status,
    int? resultCount,
    bool? synced,
    bool? unsupported,
  }) =>
      HealthReport(
        id: id,
        profileId: profileId,
        fileName: fileName,
        lab: lab ?? this.lab,
        reportDate: reportDate ?? this.reportDate,
        uploadDate: uploadDate,
        collectionDate: collectionDate ?? this.collectionDate,
        status: status ?? this.status,
        resultCount: resultCount ?? this.resultCount,
        filePath: filePath,
        synced: synced ?? this.synced,
        unsupported: unsupported ?? this.unsupported,
      );
}
