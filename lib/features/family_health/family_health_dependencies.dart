import 'data/mock/mock_family_health_data_source.dart';
import 'data/repositories/family_health_repository_impl.dart';
import 'domain/repositories/family_health_repository.dart';

/// Composition point for the active Family Health data implementation.
/// Replace the mock source with an API source here when the backend is ready.
FamilyHealthRepository createFamilyHealthRepository() =>
    FamilyHealthRepositoryImpl(MockFamilyHealthDataSource());
