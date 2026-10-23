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
    this.timedOut = false,
    this.patientName,
    this.fileHash,
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

  /// Failed because reading took longer than the repository's time limit.
  final bool timedOut;

  /// The patient name printed on the report, used only to warn when it was
  /// filed under someone else. Phone-only; never synced. Cleared once the
  /// user confirms who the report belongs to.
  final String? patientName;

  /// SHA-256 of the original file, to spot the same file added twice.
  /// Phone-only: on a server it would let anyone holding a report file
  /// confirm it's stored there.
  final String? fileHash;

  HealthReport copyWith({
    String? profileId,
    String? lab,
    DateTime? reportDate,
    DateTime? collectionDate,
    ReportStatus? status,
    int? resultCount,
    bool? synced,
    bool? unsupported,
    bool? timedOut,
    String? patientName,
    bool clearPatientName = false,
  }) =>
      HealthReport(
        id: id,
        profileId: profileId ?? this.profileId,
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
        timedOut: timedOut ?? this.timedOut,
        patientName:
            clearPatientName ? null : (patientName ?? this.patientName),
        fileHash: fileHash,
      );
}
