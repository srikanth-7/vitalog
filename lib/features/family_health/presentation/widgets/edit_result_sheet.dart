import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../../domain/health_categories.dart';
import '../health_presentation.dart';
import '../../../../core/theme/app_shape.dart';

/// Lets the user correct a value the on-device reader got wrong. The status
/// is re-judged from the printed range when it's saved.
Future<void> showEditResultSheet(BuildContext context, LabResult result,
    {HealthReport? report}) {
  final bloc = context.read<HealthBloc>();
  final repository = context.read<FamilyHealthRepository>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: RepositoryProvider.value(
          value: repository,
          child: _EditResultSheet(result: result, report: report)),
    ),
  );
}

class _EditResultSheet extends StatefulWidget {
  const _EditResultSheet({required this.result, this.report});
  final LabResult result;
  final HealthReport? report;
  @override
  State<_EditResultSheet> createState() => _EditResultSheetState();
}

class _EditResultSheetState extends State<_EditResultSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.result.name);
  late final _value = TextEditingController(text: widget.result.value);
  late final _unit = TextEditingController(text: widget.result.unit);
  late final _range = TextEditingController(text: widget.result.referenceRange);
  // Unfiled ("Other tests") results start with no pick, so the user must
  // choose one; the choice is remembered for this test name.
  late String? _category = widget.result.categoryIds.contains('other')
      ? null
      : widget.result.categoryIds.firstOrNull;

  @override
  void dispose() {
    for (final c in [_name, _value, _unit, _range]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    context.read<HealthBloc>().add(EditResult(widget.result.copyWith(
          name: _name.text.trim(),
          value: _value.text.trim(),
          unit: _unit.text.trim(),
          referenceRange: _range.text.trim(),
          categoryIds: [_category!],
        )));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final report = widget.report;
    final canCompare = report?.filePath != null &&
        !report!.fileName.toLowerCase().endsWith('.pdf');
    InputDecoration field(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: c.canvas,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none));

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.editResultTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 6),
                Text(l10n.editResultHint,
                    style: TextStyle(color: c.textMuted, height: 1.4)),
                if (canCompare) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                        onPressed: () => _showOriginal(context, report),
                        icon: const Icon(Icons.image_search_outlined),
                        label: Text(l10n.compareOriginal)),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                    key: const ValueKey('edit-name'),
                    controller: _name,
                    decoration: field(l10n.fieldTestName),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.fieldRequired : null),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                        key: const ValueKey('edit-value'),
                        controller: _value,
                        autofocus: true,
                        decoration: field(l10n.fieldValue),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? l10n.fieldRequired
                            : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      flex: 2,
                      child: TextFormField(
                          key: const ValueKey('edit-unit'),
                          controller: _unit,
                          decoration: field(l10n.fieldUnit))),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                    key: const ValueKey('edit-range'),
                    controller: _range,
                    decoration:
                        field(l10n.fieldRange).copyWith(hintText: '0.4 - 4.0')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('edit-category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: field(l10n.fieldCategory),
                  hint: Text(l10n.chooseCategory),
                  items: [
                    for (final cat in healthCategories)
                      if (cat.id != 'other')
                        DropdownMenuItem(
                            value: cat.id,
                            child: Row(children: [
                              Icon(cat.icon, size: 18, color: cat.color),
                              const SizedBox(width: 10),
                              Flexible(
                                  child: Text(cat.label(l10n),
                                      overflow: TextOverflow.ellipsis)),
                            ])),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? l10n.chooseCategory : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                    key: const ValueKey('edit-save'),
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(l10n.save)),
              ]),
        ),
      ),
    );
  }

  /// Decrypts the photo in memory and shows it zoomable, for side-by-side
  /// checking. Nothing is written to disk.
  Future<void> _showOriginal(BuildContext context, HealthReport report) async {
    final bytes =
        await context.read<FamilyHealthRepository>().readOriginal(report);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(children: [
          Positioned.fill(
              child: InteractiveViewer(
                  maxScale: 6,
                  child: Image.memory(bytes, fit: BoxFit.contain))),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton.filledTonal(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ),
          ),
        ]),
      ),
    );
  }
}
