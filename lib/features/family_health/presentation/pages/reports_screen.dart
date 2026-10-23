import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_shape.dart';
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
    final unsynced = snapshot.unsyncedCount;

    return Scaffold(
        body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageTitle(
          eyebrow: profile.name,
          title: l10n.reportsTitle,
          subtitle: l10n.reportsSubtitle),
      // Add and Sync live in the bottom dock, within thumb reach.
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 20, 8),
        child: Text(
            unsynced == 0 ? l10n.allSynced : l10n.unsyncedCount(unsynced),
            style: TextStyle(color: context.colors.textMuted, fontSize: 11)),
      ),
      Expanded(
          // Pull down to check on reports still being read.
          child: RefreshIndicator(
        onRefresh: () async {
          final bloc = context.read<HealthBloc>();
          final next = bloc.stream.first;
          bloc.add(RefreshHealthData());
          await next;
        },
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
                        profile: profile,
                        members: snapshot.members,
                        isFirst: i == 0,
                        isLast: i == reports.length - 1)),
              ),
      )),
    ])));
  }
}

/// Round Sync button with the unsynced count, for the bottom dock.
class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.unsynced, required this.isSyncing});
  final int unsynced;
  final bool isSyncing;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton.outlined(
      key: const ValueKey('sync'),
      tooltip: isSyncing ? context.l10n.syncing : context.l10n.sync,
      onPressed: isSyncing
          ? null
          : () => context.read<HealthBloc>().add(SyncReports()),
      style: IconButton.styleFrom(
          foregroundColor: c.brand,
          side: BorderSide(color: c.border),
          shape: AppShape.of(AppRadius.lg),
          minimumSize: const Size.square(52)),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSyncing
            ? SizedBox(
                key: const ValueKey('spin'),
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: c.brand))
            : Badge(
                key: const ValueKey('icon'),
                isLabelVisible: unsynced > 0,
                label: Text('$unsynced'),
                child: const Icon(Icons.cloud_upload_outlined)),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry(
      {required this.report,
      required this.profile,
      required this.members,
      required this.isFirst,
      required this.isLast});
  final HealthReport report;
  final FamilyMember profile;
  final List<FamilyMember> members;
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
              onLongPress: isUploaded && !processing
                  ? () => _showEntryActions(context, report)
                  : null,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                            key: ValueKey('cancel-${report.id}'),
                            onPressed: () => context
                                .read<HealthBloc>()
                                .add(CancelReport(report.id)),
                            style: TextButton.styleFrom(
                                foregroundColor: c.textSecondary),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(l10n.cancelReading)),
                      ),
                    ],
                    if (report.patientName case final printed?
                        when !processing &&
                            !profile.matchesPrintedName(printed)) ...[
                      const SizedBox(height: 10),
                      _NameMismatch(
                          report: report,
                          printed: printed,
                          profile: profile,
                          members: members),
                    ],
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      // The status pops in place when reading finishes.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, a) => ScaleTransition(
                            scale: CurvedAnimation(
                                parent: a, curve: Curves.easeOutBack),
                            child: FadeTransition(opacity: a, child: child)),
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
                    if (report.timedOut) ...[
                      const SizedBox(height: 8),
                      Text(l10n.timedOutLine,
                          style: TextStyle(fontSize: 12, color: c.danger)),
                    ],
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

/// The name printed on the report isn't the member it's filed under: keep
/// it (the name is just written differently) or move it to the right person.
class _NameMismatch extends StatelessWidget {
  const _NameMismatch(
      {required this.report,
      required this.printed,
      required this.profile,
      required this.members});
  final HealthReport report;
  final String printed;
  final FamilyMember profile;
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final bloc = context.read<HealthBloc>();
    final others = members.where((m) => m.id != profile.id).toList();
    final match =
        others.where((m) => m.matchesPrintedName(printed)).firstOrNull;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      decoration:
          AppShape.decoration(radius: AppRadius.sm, color: c.warningSoft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.person_search_outlined, size: 18, color: c.warning),
          const SizedBox(width: 8),
          Expanded(
              child: Text(l10n.nameMismatchLine(printed, profile.name),
                  style:
                      TextStyle(fontSize: 12, color: c.warning, height: 1.35))),
        ]),
        Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
          TextButton(
              onPressed: () => bloc.add(AssignReport(report.id, profile.id)),
              child: Text(l10n.keepHere)),
          if (others.isNotEmpty)
            TextButton(
                onPressed: () async {
                  final id =
                      match?.id ?? await _pickMember(context, others, printed);
                  if (id != null) bloc.add(AssignReport(report.id, id));
                },
                child: Text(match == null
                    ? l10n.moveReport
                    : l10n.moveToMember(match.name))),
        ]),
      ]),
    );
  }

  static Future<String?> _pickMember(
          BuildContext context, List<FamilyMember> others, String printed) =>
      showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.l10n.moveReportTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 8),
            for (final m in others)
              ListTile(
                leading: MemberAvatar(member: m, size: 38),
                title: Text(m.name),
                subtitle: Text(m.relation),
                onTap: () => Navigator.pop(context, m.id),
              ),
            const SizedBox(height: 8),
          ]),
        ),
      );
}

/// Long-press actions, as a sheet from the bottom (thumb reach).
Future<void> _showEntryActions(
    BuildContext context, HealthReport report) async {
  HapticFeedback.mediumImpact();
  final bloc = context.read<HealthBloc>();
  final l10n = context.l10n;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!report.unsupported)
          ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: Text(l10n.retry),
              onTap: () => Navigator.pop(context, 'retry')),
        ListTile(
            leading: Icon(Icons.delete_outline_rounded,
                color: context.colors.danger),
            title: Text(l10n.delete,
                style: TextStyle(color: context.colors.danger)),
            onTap: () => Navigator.pop(context, 'delete')),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (!context.mounted) return;
  if (action == 'retry') {
    bloc.add(RetryReport(report.id));
  } else if (action == 'delete' &&
      await confirmDeleteReport(context, report) &&
      context.mounted) {
    bloc.add(DeleteReport(report.id));
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
const _scanner = MethodChannel('vitalog/document_scanner');

/// The phone's document camera: finds the page edges, flattens and crops,
/// which reads far better than a plain photo. Returns a PDF path, null if
/// the user cancelled, or '' if there's no document camera here (simulator,
/// phones without Play services): then the plain camera is used.
Future<String?> _scan() async {
  try {
    return await _scanner.invokeMethod<String>('scan');
  } on PlatformException catch (e) {
    return e.code == 'unavailable' ? '' : null;
  } on MissingPluginException {
    return '';
  }
}

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
            option('camera', Icons.document_scanner_outlined, l10n.takePhoto),
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
    final scanned = source == 'camera' ? await _scan() : '';
    if (scanned != '') {
      // Scanned, or null if the user cancelled.
      path = scanned;
      name = scanned?.split('/').last;
    } else {
      final image = await ImagePicker().pickImage(
          source:
              source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 92);
      path = image?.path;
      name = image?.name;
    }
  }
  if (path != null && name != null) {
    bloc.add(UploadReport(sourcePath: path, fileName: name));
  }
}
