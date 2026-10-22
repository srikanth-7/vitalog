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
  });

  final String id;
  final String profileId;
  final String fileName;
  final String lab;
  final DateTime reportDate;
  final DateTime uploadDate;
  final String status;
  final int resultCount;
}
