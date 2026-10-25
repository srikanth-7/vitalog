import '../../domain/entities/family_health_snapshot.dart';
import '../../domain/health_categories.dart';
import 'family_health_data_source.dart';

/// Empty starting state for a real tester. Sample fixtures remain available
/// to automated tests, but are not injected into normal app launches.
class EmptyFamilyHealthDataSource implements FamilyHealthDataSource {
  @override
  Future<FamilyHealthSnapshot> fetchFamilyHealth() async =>
      FamilyHealthSnapshot(
        members: const [],
        categories: healthCategories,
        results: const [],
        reports: const [],
      );
}
