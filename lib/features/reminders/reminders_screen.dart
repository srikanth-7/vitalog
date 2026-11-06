import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../family_health/presentation/bloc/health_bloc.dart';
import '../family_health/presentation/bloc/health_state.dart';
import '../family_health/presentation/health_presentation.dart';
import '../family_health/presentation/widgets/apple_menus.dart';
import '../family_health/presentation/widgets/health_widgets.dart';
import '../family_health/presentation/widgets/permission_help.dart';
import 'reminder.dart';
import 'reminders_cubit.dart';

/// Keeps scheduled reminders in step with the family and the language: on
/// mount (the family may already be loaded), when the app language changes,
/// and whenever members change (a removed member's reminders go).
class ReminderSync extends StatefulWidget {
  const ReminderSync({super.key, required this.child});
  final Widget child;
  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(context.read<HealthBloc>().state);
  }

  void _sync(HealthState state) {
    if (state is! HealthLoaded) return;
    context.read<RemindersCubit>().syncMembers(
        {for (final m in state.data.members) m.id: m.name},
        bodyFor: context.l10n.reminderBody,
        channel: context.l10n.remindersTitle);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt on a language change too, which re-runs the sync above.
    Localizations.localeOf(context);
    return BlocListener<HealthBloc, HealthState>(
      listenWhen: (a, b) =>
          b is HealthLoaded &&
          (a is! HealthLoaded || !identical(a.data.members, b.data.members)),
      listener: (context, state) => _sync(state),
      child: widget.child,
    );
  }
}

String repeatLabel(BuildContext context, ReminderRepeat r) {
  final l10n = context.l10n;
  return switch (r) {
    ReminderRepeat.once => l10n.repeatOnce,
    ReminderRepeat.monthly => l10n.repeatMonthly,
    ReminderRepeat.every3Months => l10n.repeatEvery3Months,
    ReminderRepeat.every6Months => l10n.repeatEvery6Months,
    ReminderRepeat.yearly => l10n.repeatYearly,
  };
}

String _when(BuildContext context, DateTime t) =>
    '${formatDate(t)}, ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(t))}';

List<FamilyMember> _members(BuildContext context) {
  final s = context.read<HealthBloc>().state;
  return s is HealthLoaded ? s.data.members : const [];
}

/// Reminders set on this phone, soonest first. Add is a bottom button, in
/// thumb reach; tap a reminder to change it, the switch pauses it.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: FilledButton.icon(
            key: const ValueKey('add-reminder'),
            onPressed: () => showReminderSheet(context),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.add_alarm_outlined),
            label: Text(l10n.addReminder),
          ),
        ),
      ),
      body: BlocBuilder<RemindersCubit, List<Reminder>>(
        builder: (context, reminders) {
          final members = {for (final m in _members(context)) m.id: m};
          final now = DateTime.now();
          return ScrollCut(
              bottom: true,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  Text(l10n.remindersSubtitle,
                      style: TextStyle(color: c.textSecondary, height: 1.4)),
                  const SizedBox(height: 16),
                  if (reminders.isEmpty)
                    EmptyMessage(
                        title: l10n.remindersEmptyTitle,
                        message: l10n.remindersEmptyMessage),
                  for (final r in reminders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReminderTile(
                          reminder: r, member: members[r.memberId], now: now),
                    ),
                ],
              ));
        },
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile(
      {required this.reminder, required this.member, required this.now});
  final Reminder reminder;
  final FamilyMember? member;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final next = nextFire(reminder, now);
    return TapCard(
      onTap: () => showReminderSheet(context, editing: reminder),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(children: [
        if (member != null) MemberAvatar(member: member!, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reminder.title,
                style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 3),
            Text(
                '${member?.name ?? ''} · ${repeatLabel(context, reminder.repeat)}',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
                next == null
                    ? l10n.reminderNoMore
                    : l10n.reminderNext(_when(context, next)),
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          ]),
        ),
        // Names what it turns on/off, not just "switch, on".
        Semantics(
          label: reminder.title,
          child: Switch(
            value: reminder.enabled,
            onChanged: (on) =>
                context.read<RemindersCubit>().setEnabled(reminder.id, on),
          ),
        ),
      ]),
    );
  }
}

/// Add (or, with [editing], change) a reminder: what, for whom, when, how
/// often. The title is what the lock screen shows.
Future<void> showReminderSheet(BuildContext context, {Reminder? editing}) {
  final cubit = context.read<RemindersCubit>();
  final bloc = context.read<HealthBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => MultiBlocProvider(providers: [
      BlocProvider.value(value: cubit),
      BlocProvider.value(value: bloc),
    ], child: _ReminderSheet(editing: editing)),
  );
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({this.editing});
  final Reminder? editing;
  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.editing?.title);
  late String? _memberId = widget.editing?.memberId;
  late DateTime _at = widget.editing?.firstAt ?? _tomorrowAtNine();
  late ReminderRepeat _repeat =
      widget.editing?.repeat ?? ReminderRepeat.every3Months;

  static DateTime _tomorrowAtNine() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 9);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // New reminders start with the person being viewed.
    final s = context.read<HealthBloc>().state;
    _memberId ??= s is HealthLoaded ? s.selectedMemberId : null;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: _at.isBefore(now) ? now : _at,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 5));
    if (d != null) {
      setState(
          () => _at = DateTime(d.year, d.month, d.day, _at.hour, _at.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_at));
    if (t != null) {
      setState(() {
        _at = DateTime(_at.year, _at.month, _at.day, t.hour, t.minute);
        _whenError = null;
      });
    }
  }

  String? _whenError;

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _memberId == null) return;
    final cubit = context.read<RemindersCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final e = widget.editing;
    // Explain first, in plain words; the phone's own prompt says nothing
    // about why (and on Android, nothing at all).
    if (!await cubit.notificationsAllowed()) {
      if (!mounted) return;
      if (await _explainNotifications(context)) {
        await cubit.askForNotifications();
      }
      if (!mounted) return;
    }
    final result = e == null
        ? await cubit.add(
            memberId: _memberId!,
            title: _title.text,
            firstAt: _at,
            repeat: _repeat)
        : await cubit.update(e.copyWith(
            memberId: _memberId,
            title: _title.text.trim(),
            firstAt: _at,
            repeat: _repeat,
            enabled: true));
    if (!mounted) return;
    if (result == ReminderSaveResult.inPast) {
      setState(() => _whenError = l10n.reminderInPast);
      return;
    }
    Navigator.pop(context);
    if (result == ReminderSaveResult.notificationsOff) {
      showPermissionOff(messenger, l10n, l10n.remindersNotificationsOff,
          notifications: true);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final cubit = context.read<RemindersCubit>();
    final ok = await showDestructiveSheet(context,
        title: l10n.deleteReminderTitle(widget.editing!.title),
        message: l10n.deleteReminderDetail,
        confirmLabel: l10n.deleteReminder,
        cancelLabel: l10n.cancel);
    if (!ok) return;
    await cubit.delete(widget.editing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final label = TextStyle(
        color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w600);
    final members = _members(context);
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
                        ? l10n.addReminder
                        : l10n.editReminder,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('reminder-title'),
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                      labelText: l10n.reminderTitleLabel,
                      helperText: l10n.reminderTitleHint),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.reminderTitleRequired
                      : null,
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final preset in [
                    l10n.reminderPresetTest,
                    l10n.reminderPresetReport
                  ])
                    ActionChip(
                        label: Text(preset),
                        onPressed: () => _title.text = preset),
                ]),
                const SizedBox(height: 18),
                Text(l10n.reminderForLabel, style: label),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in members)
                    ChoiceChip(
                        avatar: MemberAvatar(member: m, size: 24),
                        label: Text(m.name.split(' ').first),
                        selected: _memberId == m.id,
                        onSelected: (_) => setState(() => _memberId = m.id)),
                ]),
                const SizedBox(height: 18),
                Text(l10n.reminderWhenLabel, style: label),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(formatDate(_at))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule_outlined, size: 18),
                        label: Text(MaterialLocalizations.of(context)
                            .formatTimeOfDay(TimeOfDay.fromDateTime(_at)))),
                  ),
                ]),
                if (_whenError != null) ...[
                  const SizedBox(height: 6),
                  Text(_whenError!,
                      style: TextStyle(color: c.danger, fontSize: 12)),
                ],
                const SizedBox(height: 18),
                Text(l10n.reminderRepeatLabel, style: label),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final r in ReminderRepeat.values)
                    ChoiceChip(
                        label: Text(repeatLabel(context, r)),
                        selected: _repeat == r,
                        onSelected: (_) => setState(() {
                              _repeat = r;
                              _whenError = null;
                            })),
                ]),
                const SizedBox(height: 22),
                FilledButton(
                    key: const ValueKey('save-reminder'),
                    onPressed: _save,
                    child: Text(l10n.saveReminder)),
                if (widget.editing != null) ...[
                  const SizedBox(height: 6),
                  TextButton(
                      onPressed: _delete,
                      style: TextButton.styleFrom(foregroundColor: c.danger),
                      child: Text(l10n.deleteReminder)),
                ],
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.lock_outline, size: 14, color: c.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(l10n.reminderPrivacy,
                        style: TextStyle(color: c.textMuted, fontSize: 12)),
                  ),
                ]),
              ]),
        ),
      ),
    );
  }
}

/// Before the phone asks for notifications: what they're for, what they
/// show, and which button to tap next. True = go on to the phone's prompt.
Future<bool> _explainNotifications(BuildContext context) async {
  final yes = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final l10n = context.l10n;
      final c = context.colors;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 40, color: c.brand),
              const SizedBox(height: 12),
              Text(l10n.notifyAskTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(l10n.notifyAskBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(l10n.notifyAskNext,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('notify-ask-continue'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.notifyAskContinue),
              ),
              TextButton(
                key: const ValueKey('notify-ask-not-now'),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.notifyAskNotNow),
              ),
              Text(l10n.notifyAskLater,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    },
  );
  return yes ?? false;
}
