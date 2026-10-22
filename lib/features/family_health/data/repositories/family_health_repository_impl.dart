import '../../domain/entities/family_health_snapshot.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../datasources/family_health_data_source.dart';

class FamilyHealthRepositoryImpl implements FamilyHealthRepository {
  const FamilyHealthRepositoryImpl(this._dataSource);

  final FamilyHealthDataSource _dataSource;

  @override
  Future<FamilyHealthSnapshot> loadFamilyHealth() =>
      _dataSource.fetchFamilyHealth();
}
