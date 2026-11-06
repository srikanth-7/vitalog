import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../health_presentation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'health_widgets.dart';
import '../bloc/health_state.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/reference/reference_range.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import 'permission_help.dart';

/// Name, relation, age and sex: what the app needs to file reports and pick
/// usual ranges. Saved on this phone only. With [editing], the same sheet
/// opens filled in and saves the changes.
Future<void> showAddMemberSheet(BuildContext context, {FamilyMember? editing}) {
  final bloc = context.read<HealthBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: _AddMember(editing: editing)),
  );
}

class _AddMember extends StatefulWidget {
  const _AddMember({this.editing});
  final FamilyMember? editing;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final m = widget.editing;
    if (m == null || _name.text.isNotEmpty) return;
    _name.text = m.name;
    _age.text = '${m.age}';
    _sex = m.sex;
    // Saved as a fixed key; older saves hold the label in the language of
    // the day, so match that too. Anything unknown is "Other".
    var i = relationKeys.indexOf(m.relation);
    if (i < 0) {
      i = [for (final k in relationKeys) relationName(context.l10n, k)]
          .indexOf(m.relation);
    }
    _relation = i < 0 ? relationKeys.length - 1 : i;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final m = widget.editing;
    if (m != null) {
      context.read<HealthBloc>().add(UpdateFamilyMember(FamilyMember(
          id: m.id,
          name: _name.text.trim(),
          relation: relationKeys[_relation],
          initials: m.initials,
          colorValue: m.colorValue,
          age: int.parse(_age.text.trim()),
          sex: _sex)));
      Navigator.pop(context);
      return;
    }
    context.read<HealthBloc>().add(AddFamilyMember(
        name: _name.text.trim(),
        relation: relationKeys[_relation],
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
                Text(
                    widget.editing == null
                        ? l10n.addMemberTitle
                        : l10n.editMember,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 16),
                if (widget.editing != null) ...[
                  _PhotoRow(memberId: widget.editing!.id),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const ValueKey('member-name'),
                  controller: _name,
                  autofocus: widget.editing == null,
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
                  for (final (i, r) in [
                    for (final k in relationKeys) relationName(l10n, k)
                  ].indexed)
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
                    child: Text(widget.editing == null
                        ? l10n.saveMember
                        : l10n.saveChanges)),
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

/// The member's picture with Take / Choose / Remove. Saved (encrypted, on
/// this phone) as soon as it's picked; the avatar here follows the bloc.
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.memberId});
  final String memberId;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final bloc = context.read<HealthBloc>();
    // Avatar-sized is plenty, and keeps the encrypted copy small.
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
          source: source, maxWidth: 600, maxHeight: 600, imageQuality: 85);
    } on PlatformException {
      // Camera / Photos access denied, or no camera here.
      if (context.mounted) {
        showPermissionOff(ScaffoldMessenger.maybeOf(context), context.l10n,
            context.l10n.pickerFailed);
      }
      return;
    }
    if (picked != null) bloc.add(SetMemberPhoto(memberId, picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        final member = state is HealthLoaded
            ? state.data.members.where((m) => m.id == memberId).firstOrNull
            : null;
        if (member == null) return const SizedBox.shrink();
        return Row(children: [
          MemberAvatar(member: member, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(spacing: 4, runSpacing: 0, children: [
              TextButton.icon(
                  key: const ValueKey('photo-camera'),
                  onPressed: () => _pick(context, ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(l10n.photoTake)),
              TextButton.icon(
                  key: const ValueKey('photo-library'),
                  onPressed: () => _pick(context, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.photoChoose)),
              if (member.photo != null)
                TextButton.icon(
                    key: const ValueKey('photo-remove'),
                    onPressed: () => context
                        .read<HealthBloc>()
                        .add(SetMemberPhoto(memberId, null)),
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: context.colors.danger),
                    label: Text(l10n.photoRemove,
                        style: TextStyle(color: context.colors.danger))),
            ]),
          ),
        ]);
      },
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
