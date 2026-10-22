import '../../domain/entities/family_health_snapshot.dart';

abstract class HealthState {}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthLoadFailure extends HealthState {
  HealthLoadFailure(this.message);
  final String message;
}

class HealthLoaded extends HealthState {
  HealthLoaded({
    required this.data,
    required this.selectedMemberId,
    this.selectedTab = 0,
  });

  final FamilyHealthSnapshot data;
  final String selectedMemberId;
  final int selectedTab;

  HealthLoaded copyWith({String? selectedMemberId, int? selectedTab}) {
    return HealthLoaded(
      data: data,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}
