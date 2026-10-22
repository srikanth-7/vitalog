import '../entities/family_health_snapshot.dart';

abstract class FamilyHealthRepository {
  Future<FamilyHealthSnapshot> loadFamilyHealth();
}
