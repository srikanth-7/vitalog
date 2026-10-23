import '../../domain/entities/lab_result.dart';
import '../../domain/reference/reference_range.dart';

abstract class HealthEvent {}

class LoadHealthData extends HealthEvent {}

/// Reload without the loading screen (pull to refresh).
class RefreshHealthData extends HealthEvent {}

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

/// Stop reading a report and keep nothing from it.
class CancelReport extends HealthEvent {
  CancelReport(this.reportId);
  final String reportId;
}

/// File a report under [profileId] (also: "yes, it's this person's").
class AssignReport extends HealthEvent {
  AssignReport(this.reportId, this.profileId);
  final String reportId;
  final String profileId;
}

class AddFamilyMember extends HealthEvent {
  AddFamilyMember(
      {required this.name,
      required this.relation,
      required this.age,
      this.sex});
  final String name;
  final String relation;
  final int age;
  final Sex? sex;
}
