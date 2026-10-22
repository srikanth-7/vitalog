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
