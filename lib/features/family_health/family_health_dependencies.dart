import 'package:flutter/widgets.dart';

import 'data/datasources/empty_family_health_data_source.dart';
import 'data/extraction/report_text_recognizer.dart';
import 'data/local/local_report_store.dart';
import 'data/repositories/family_health_repository_impl.dart';
import 'data/sync/report_sync_service.dart';
import 'domain/repositories/family_health_repository.dart';

/// Composition point for the real app. New installs start with no seeded
/// family members or reports; user data is stored on-device and reaches
/// Supabase only after the user explicitly taps Sync.
FamilyHealthRepository createFamilyHealthRepository() {
  final store = LocalReportStore();
  _relockVaultAfterAway(store);
  return FamilyHealthRepositoryImpl(
    EmptyFamilyHealthDataSource(),
    store: store,
    recognizer: ReportTextRecognizer(),
    sync: ReportSyncService(),
  );
}

/// Original documents ask for Face ID / passcode again once the app has been
/// in the background for a while; a quick switch away doesn't re-prompt.
/// Lives as long as the app (the binding holds the listener).
void _relockVaultAfterAway(LocalReportStore store,
    {Duration grace = const Duration(minutes: 2)}) {
  DateTime? hiddenAt;
  AppLifecycleListener(
    onHide: () => hiddenAt ??= DateTime.now(),
    onShow: () {
      final away = hiddenAt == null
          ? Duration.zero
          : DateTime.now().difference(hiddenAt!);
      hiddenAt = null;
      if (away > grace) store.lockVault();
    },
  );
}
