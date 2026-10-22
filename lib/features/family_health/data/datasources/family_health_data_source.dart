import '../../domain/entities/family_health_snapshot.dart';

/// Data-layer contract implemented by mock and remote API data sources.
abstract class FamilyHealthDataSource {
  Future<FamilyHealthSnapshot> fetchFamilyHealth();
}
