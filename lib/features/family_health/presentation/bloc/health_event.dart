import '../../domain/entities/lab_result.dart';

abstract class HealthEvent {}

class LoadHealthData extends HealthEvent {}

class SelectFamilyMember extends HealthEvent {
  SelectFamilyMember(this.memberId);
  final String memberId;
}

class SelectNavigationTab extends HealthEvent {
  SelectNavigationTab(this.index);
  final int index;
}

/// A document picked by the user for the currently selected family member.
class UploadReport extends HealthEvent {
  UploadReport({required this.sourcePath, required this.fileName});
  final String sourcePath;
  final String fileName;
}

class RetryReport extends HealthEvent {
  RetryReport(this.reportId);
  final String reportId;
}

class DeleteReport extends HealthEvent {
  DeleteReport(this.reportId);
  final String reportId;
}

class SyncReports extends HealthEvent {}

/// The user corrected a value that was read wrongly from a report.
class EditResult extends HealthEvent {
  EditResult(this.result);
  final LabResult result;
}
