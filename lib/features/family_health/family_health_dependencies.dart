import 'data/extraction/report_text_recognizer.dart';
import 'data/local/local_report_store.dart';
import 'data/mock/mock_family_health_data_source.dart';
import 'data/repositories/family_health_repository_impl.dart';
import 'data/sync/report_sync_service.dart';
import 'domain/repositories/family_health_repository.dart';

/// Composition point for the active Family Health data implementation.
/// Members and categories still come from the mock source; uploaded reports
/// live on-device in [LocalReportStore] and reach Supabase only via Sync.
FamilyHealthRepository createFamilyHealthRepository() =>
    FamilyHealthRepositoryImpl(
      MockFamilyHealthDataSource(),
      store: LocalReportStore(),
      recognizer: ReportTextRecognizer(),
      sync: ReportSyncService(),
    );
