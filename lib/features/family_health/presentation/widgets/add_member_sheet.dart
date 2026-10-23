import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/reference/reference_range.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';

/// Name, relation, age and sex: what the app needs to file reports and pick
/// usual ranges. Saved on this phone only.
Future<void> showAddMemberSheet(BuildContext context) {
  final bloc = context.read<HealthBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: bloc, child: const _AddMember()),
  );
}

class _AddMember extends StatefulWidget {
  const _AddMember();
  @override
  State<_AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<_AddMember> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  int _relation = 0;
  Sex? _sex;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  List<String> _relations(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.relationSelf,
      l10n.relationPartner,
      l10n.relationChild,
      l10n.relationParent,
      l10n.relationSibling,
      l10n.relationGrandparent,
      l10n.relationOther,
    ];
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<HealthBloc>().add(AddFamilyMember(
        name: _name.text.trim(),
        relation: _relations(context)[_relation],
        age: int.parse(_age.text.trim()),
        sex: _sex));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final label = TextStyle(
        color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w600);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Text(l10n.addMemberTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('member-name'),
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.memberNameLabel),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.memberNameRequired : null,
                ),
                const SizedBox(height: 10),
                _NameCheckNote(controller: _name),
                const SizedBox(height: 18),
                Text(l10n.relationLabel, style: label),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final (i, r) in _relations(context).indexed)
                    ChoiceChip(
                        label: Text(r),
                        selected: _relation == i,
                        onSelected: (_) => setState(() => _relation = i)),
                ]),
                const SizedBox(height: 18),
                TextFormField(
                  key: const ValueKey('member-age'),
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.ageLabel),
                  validator: (v) {
                    final age = int.tryParse((v ?? '').trim());
                    return age == null || age < 0 || age > 120
                        ? l10n.ageInvalid
                        : null;
                  },
                ),
                const SizedBox(height: 18),
                Text(l10n.sexLabel, style: label),
                const SizedBox(height: 8),
                SegmentedButton<Sex?>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: Sex.female, label: Text(l10n.sexFemale)),
                    ButtonSegment(value: Sex.male, label: Text(l10n.sexMale)),
                    ButtonSegment(value: null, label: Text(l10n.sexUnset)),
                  ],
                  selected: {_sex},
                  onSelectionChanged: (s) => setState(() => _sex = s.first),
                ),
                const SizedBox(height: 6),
                Text(l10n.sexHelp,
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
                const SizedBox(height: 20),
                FilledButton(
                    key: const ValueKey('save-member'),
                    onPressed: _save,
                    child: Text(l10n.saveMember)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.lock_outline, size: 14, color: c.textMuted),
                  const SizedBox(width: 6),
                  Text(l10n.memberPrivacy,
                      style: TextStyle(color: c.textMuted, fontSize: 12)),
                ]),
              ]),
        ),
      ),
    );
  }
}

/// Tells the user, while they type, that the name is how reports are matched
/// to this person: which word a report must contain, or that what they typed
/// looks like a nickname no lab would print.
class _NameCheckNote extends StatelessWidget {
  const _NameCheckNote({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final first = FamilyMember.firstNameOf(value.text);
        final nickname = FamilyMember.looksLikeNickname(value.text);
        final shown = first == null
            ? null
            : value.text.split(RegExp(r'\s+')).firstWhere(
                (w) => w.toLowerCase().contains(first),
                orElse: () => first);
        final (fg, bg, icon) = nickname
            ? (c.warning, c.warningSoft, Icons.warning_amber_rounded)
            : (c.brand, c.brandSoft, Icons.fact_check_outlined);
        return AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: AppShape.decoration(radius: AppRadius.sm, color: bg),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nameCheckNote,
                        style: TextStyle(
                            color: c.textSecondary, fontSize: 12, height: 1.4)),
                    if (shown != null) ...[
                      const SizedBox(height: 6),
                      Text(
                          nickname
                              ? l10n.nameLooksLikeNickname(shown)
                              : l10n.nameMustInclude(shown),
                          key: const ValueKey('name-check-line'),
                          style: TextStyle(
                              color: fg,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w700)),
                    ],
                  ]),
            ),
          ]),
        );
      },
    );
  }
}
