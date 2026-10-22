import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../health_presentation.dart';
import '../widgets/apple_menus.dart';
import '../widgets/health_widgets.dart';
import '../widgets/motion.dart';
import 'navigation.dart';

/// Timeline of every report for the selected member, newest upload first.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen(
      {super.key,
      required this.profile,
      required this.snapshot,
      required this.isSyncing});
  final FamilyMember profile;
  final FamilyHealthSnapshot snapshot;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reports = snapshot.reports
        .where((r) => r.profileId == profile.id)
        .toList()
      ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    final unsynced = snapshot.reports
        .where((r) =>
            r.filePath != null &&
            !r.synced &&
            r.status != ReportStatus.processing)
        .length;

    return Scaffold(
        body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageTitle(
          eyebrow: profile.name,
          title: l10n.reportsTitle,
          subtitle: l10n.reportsSubtitle),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Row(children: [
          Expanded(
            child: FilledButton.icon(
                onPressed: () => showAddReportSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addReport)),
          ),
          const SizedBox(width: 10),
          _SyncButton(unsynced: unsynced, isSyncing: isSyncing),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 20, 8),
        child: Text(
            unsynced == 0 ? l10n.allSynced : l10n.unsyncedCount(unsynced),
            style: TextStyle(color: context.colors.textMuted, fontSize: 11)),
      ),
      Expanded(
          child: reports.isEmpty
              ? ListView(padding: const EdgeInsets.all(20), children: [
                  EmptyMessage(
                      icon: Icons.document_scanner_outlined,
                      title: l10n.reportsEmptyTitle,
                      message: l10n.reportsEmptyMessage)
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: reports.length,
                  itemBuilder: (context, i) => Reveal(
                      key: ValueKey(reports[i].id),
                      index: i,
                      child: _TimelineEntry(
                          report: reports[i],
                          isFirst: i == 0,
                          isLast: i == reports.length - 1)),
                )),
    ])));
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.unsynced, required this.isSyncing});
  final int unsynced;
  final bool isSyncing;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OutlinedButton.icon(
      onPressed: isSyncing
          ? null
          : () => context.read<HealthBloc>().add(SyncReports()),
      style: OutlinedButton.styleFrom(foregroundColor: c.brand),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSyncing
            ? SizedBox(
                key: const ValueKey('spin'),
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: c.brand))
            : Badge(
                key: const ValueKey('icon'),
                isLabelVisible: unsynced > 0,
                label: Text('$unsynced'),
                child: const Icon(Icons.cloud_upload_outlined)),
      ),
      label: Text(isSyncing ? context.l10n.syncing : context.l10n.sync),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry(
      {required this.report, required this.isFirst, required this.isLast});
  final HealthReport report;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final (color, bg) = switch (report.status) {
      ReportStatus.processing => (c.brand, c.brandSoft),
      ReportStatus.ready => (c.success, c.successSoft),
      ReportStatus.needsReview => (c.warning, c.warningSoft),
      ReportStatus.failed => (c.danger, c.dangerSoft),
    };
    final isUploaded = report.filePath != null;
    final processing = report.status == ReportStatus.processing;

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Rail: line + status dot, linking entries into a timeline.
        SizedBox(
          width: 22,
          child: Column(children: [
            Container(width: 2, height: 18, color: isFirst ? null : c.border),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: bg, width: 3)),
            ),
            Expanded(
                child: Container(width: 2, color: isLast ? null : c.border)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TapCard(
              onTap: processing ? null : () => openReport(context, report),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                          report.fileName.toLowerCase().endsWith('.pdf')
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          size: 18,
                          color: c.brand),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(report.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary))),
                      if (isUploaded && !processing) _EntryMenu(report: report),
                    ]),
                    const SizedBox(height: 6),
                    if (!processing)
                      Text(
                          '${report.lab.isEmpty ? l10n.labNotDetected : report.lab} · ${formatDate(report.reportDate)}',
                          style:
                              TextStyle(fontSize: 12, color: c.textSecondary)),
                    Text(
                        '${l10n.uploadedOn(formatDate(report.uploadDate))}${processing ? '' : ' · ${l10n.resultsCount(report.resultCount)}'}',
                        style: TextStyle(fontSize: 11, color: c.textMuted)),
                    if (processing) ...[
                      const SizedBox(height: 10),
                      // The user can keep using the app; a notice with a
                      // "View" button appears when this finishes.
                      Row(children: [
                        ScanBeam(color: c.brand, background: c.brandSoft),
                        const SizedBox(width: 12),
                        Icon(Icons.lock_outline, size: 14, color: c.textMuted),
                        const SizedBox(width: 5),
                        Expanded(
                            child: Text(l10n.readingSecurely,
                                style: TextStyle(
                                    fontSize: 12, color: c.textSecondary))),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Pill(
                            key: ValueKey(report.status),
                            label: reportStatusLabel(l10n, report.status),
                            color: color,
                            background: bg),
                      ),
                      if (!isUploaded)
                        Pill(
                            label: l10n.sampleBadge,
                            color: c.textMuted,
                            background: c.canvas)
                      else if (report.synced)
                        Pill(
                            icon: Icons.cloud_done_outlined,
                            label: l10n.syncedBadge,
                            color: c.success,
                            background: c.successSoft)
                      else if (!processing)
                        Pill(
                            icon: Icons.phone_iphone,
                            label: l10n.onDeviceBadge,
                            color: c.textSecondary,
                            background: c.canvas),
                    ]),
                    if (report.unsupported) ...[
                      const SizedBox(height: 8),
                      Text(l10n.unsupportedFileLine,
                          style: TextStyle(fontSize: 12, color: c.danger)),
                    ] else if (report.status == ReportStatus.failed) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                          onPressed: () => context
                              .read<HealthBloc>()
                              .add(RetryReport(report.id)),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l10n.retry)),
                    ],
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _EntryMenu extends StatelessWidget {
  const _EntryMenu({required this.report});
  final HealthReport report;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MoreButton(
      label: l10n.moreActions,
      onPressed: (anchor) async {
        final bloc = context.read<HealthBloc>();
        final action = await showPullDownMenu<String>(anchor, items: [
          // Re-reading an unsupported file type can't help.
          if (!report.unsupported)
            PullDownItem(
                value: 'retry', label: l10n.retry, icon: Icons.refresh_rounded),
          PullDownItem(
              value: 'delete',
              label: l10n.delete,
              icon: Icons.delete_outline_rounded,
              destructive: true),
        ]);
        if (!context.mounted) return;
        if (action == 'retry') {
          bloc.add(RetryReport(report.id));
        } else if (action == 'delete' &&
            await confirmDeleteReport(context, report) &&
            context.mounted) {
          bloc.add(DeleteReport(report.id));
        }
      },
    );
  }
}

/// Destructive confirm: deleting also removes the encrypted original, and
/// can't be undone.
Future<bool> confirmDeleteReport(BuildContext context, HealthReport report) {
  final l10n = context.l10n;
  return showDestructiveSheet(
    context,
    title: l10n.deleteReportNamed(report.fileName),
    message: l10n.deleteReportDetail(report.resultCount),
    note: report.synced ? l10n.deleteReportSyncedNote : null,
    confirmLabel: l10n.deleteReportConfirm,
    cancelLabel: l10n.cancel,
  );
}

/// Camera / Photos / PDF picker. The chosen file is handed to the bloc, which
/// stores and reads it on-device.
Future<void> showAddReportSheet(BuildContext context) async {
  final bloc = context.read<HealthBloc>();
  final source = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = context.l10n;
      final c = context.colors;
      Widget option(String value, IconData icon, String label) => ListTile(
            leading: Icon(icon, color: c.brand),
            title: Text(label),
            onTap: () => Navigator.pop(context, value),
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.addReportSheetTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 8),
            option('camera', Icons.photo_camera_outlined, l10n.takePhoto),
            option('photos', Icons.photo_library_outlined, l10n.choosePhoto),
            option('file', Icons.upload_file_outlined, l10n.chooseFile),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Icon(Icons.lock_outline, size: 16, color: c.textMuted),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(l10n.addReportPrivacy,
                        style: TextStyle(color: c.textMuted, fontSize: 12))),
              ]),
            ),
          ]),
        ),
      );
    },
  );
  if (source == null) return;

  String? path;
  String? name;
  if (source == 'file') {
    // Any type: the type is detected from the bytes when the report is read.
    final picked = await FilePicker.pickFile(type: FileType.any);
    path = picked?.path;
    name = picked?.name;
  } else {
    final image = await ImagePicker().pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 92);
    path = image?.path;
    name = image?.name;
  }
  if (path != null && name != null) {
    bloc.add(UploadReport(sourcePath: path, fileName: name));
  }
}
