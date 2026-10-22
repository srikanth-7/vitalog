import '../entities/family_health_snapshot.dart';
import '../repositories/family_health_repository.dart';

class LoadFamilyHealth {
  const LoadFamilyHealth(this._repository);

  final FamilyHealthRepository _repository;

  Future<FamilyHealthSnapshot> call() => _repository.loadFamilyHealth();
}
