import '../../domain/entities/family_health_snapshot.dart';

/// Data-layer contract implemented by empty, mock, and remote data sources.
abstract class FamilyHealthDataSource {
  Future<FamilyHealthSnapshot> fetchFamilyHealth();
}
