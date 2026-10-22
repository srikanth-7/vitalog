import '../../domain/entities/family_health_snapshot.dart';
import '../../domain/health_categories.dart';
import '../datasources/family_health_data_source.dart';
import 'mock_family_health_data.dart';

class MockFamilyHealthDataSource implements FamilyHealthDataSource {
  @override
  Future<FamilyHealthSnapshot> fetchFamilyHealth() async =>
      FamilyHealthSnapshot(
        members: familyMembers,
        categories: healthCategories,
        results: mockResults,
        reports: mockReports,
      );
}
