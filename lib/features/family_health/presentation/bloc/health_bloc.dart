import 'package:bloc/bloc.dart';

import '../../domain/usecases/load_family_health.dart';
import 'health_event.dart';
import 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  static const navigationTabCount = 4;

  HealthBloc(this._loadFamilyHealth) : super(HealthInitial()) {
    on<LoadHealthData>((event, emit) async {
      final previous = state;
      emit(HealthLoading());
      try {
        final data = await _loadFamilyHealth();
        final previousMemberId =
            previous is HealthLoaded ? previous.selectedMemberId : null;
        final selectedMemberId =
            data.members.any((member) => member.id == previousMemberId)
                ? previousMemberId!
                : (data.members.isEmpty ? '' : data.members.first.id);
        emit(HealthLoaded(
          data: data,
          selectedMemberId: selectedMemberId,
          selectedTab: previous is HealthLoaded ? previous.selectedTab : 0,
        ));
      } catch (error) {
        emit(HealthLoadFailure(error.toString()));
      }
    });

    on<SelectFamilyMember>((event, emit) {
      final current = state;
      if (current is HealthLoaded &&
          current.data.members.any((member) => member.id == event.memberId)) {
        emit(
            current.copyWith(selectedMemberId: event.memberId, selectedTab: 0));
      }
    });

    on<SelectNavigationTab>((event, emit) {
      final current = state;
      if (current is HealthLoaded &&
          event.index >= 0 &&
          event.index < navigationTabCount) {
        emit(current.copyWith(selectedTab: event.index));
      }
    });
  }

  final LoadFamilyHealth _loadFamilyHealth;
}
