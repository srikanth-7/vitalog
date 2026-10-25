import 'data/datasources/empty_family_health_data_source.dart';
import 'data/extraction/report_text_recognizer.dart';
import 'data/local/local_report_store.dart';
import 'data/repositories/family_health_repository_impl.dart';
import 'data/sync/report_sync_service.dart';
import 'domain/repositories/family_health_repository.dart';

/// Composition point for the real app. New installs start with no seeded
/// family members or reports; user data is stored on-device and reaches
/// Supabase only after the user explicitly taps Sync.
FamilyHealthRepository createFamilyHealthRepository() =>
    FamilyHealthRepositoryImpl(
      EmptyFamilyHealthDataSource(),
      store: LocalReportStore(),
      recognizer: ReportTextRecognizer(),
      sync: ReportSyncService(),
    );
