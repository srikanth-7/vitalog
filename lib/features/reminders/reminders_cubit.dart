import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'reminder.dart';

/// Puts reminders on the phone's notification schedule. The real one wraps
/// flutter_local_notifications ([LocalReminderScheduler]); tests use a fake.
abstract class ReminderScheduler {
  /// Asks once, the first time a reminder is added (not at launch).
  Future<bool> requestPermission();

  /// Whether the phone shows our notifications now (never asks).
  Future<bool> isAllowed();

  /// [channel] is the name Android shows for these in notification settings.
  Future<void> schedule(Reminder r, List<DateTime> times,
      {required String body, String channel});
  Future<void> cancel(Reminder r);
}

/// How a save went: [inPast] wasn't saved (it would never fire);
/// [notificationsOff] was saved, but the phone won't show it until
/// notifications are allowed.
enum ReminderSaveResult { saved, notificationsOff, inPast }

/// Reminders set on this phone, soonest first. Each enabled one has its next
/// few times scheduled; [start] and [syncMembers] schedule them all again
/// (after a restart, or when members change), and a removed member's
/// reminders are dropped.
class RemindersCubit extends Cubit<List<Reminder>> {
  RemindersCubit(
      {required Future<List<Reminder>> Function() load,
      required Future<void> Function(List<Reminder>) save,
      required ReminderScheduler scheduler,
      DateTime Function()? now})
      : _load = load,
        _save = save,
        _scheduler = scheduler,
        _now = now ?? DateTime.now,
        super(const []);

  final Future<List<Reminder>> Function() _load;
  final Future<void> Function(List<Reminder>) _save;
  final ReminderScheduler _scheduler;
  final DateTime Function() _now;

  /// Member names by id (the notification says whose reminder it is).
  Map<String, String> _names = const {};
  String Function(String name) _bodyFor = (name) => name;
  String _channel = 'Reminders';
  bool? _allowed;

  Future<void>? _starting;

  /// Checked before a save, so the app can explain before the phone asks.
  Future<bool> notificationsAllowed() async =>
      _allowed = await _quietly(_scheduler.isAllowed) ?? false;

  /// The phone's own question, once the user has read why it's needed.
  Future<bool> askForNotifications() async =>
      _allowed = await _quietly(_scheduler.requestPermission) ?? false;

  /// Loads the saved reminders (once; later calls wait for the same load).
  Future<void> start() => _starting ??= _load().then(_emit);

  /// The family as it is now, and the localized notification text. Drops
  /// reminders of members no longer here and schedules the rest again.
  Future<void> syncMembers(Map<String, String> names,
      {required String Function(String name) bodyFor, String? channel}) async {
    // The family can load before the reminders do: wait for them.
    await start();
    _names = names;
    _bodyFor = bodyFor;
    if (channel != null) _channel = channel;
    final kept = <Reminder>[];
    for (final r in state) {
      if (names.containsKey(r.memberId)) {
        kept.add(r);
        await _reschedule(r);
      } else {
        await _quietly(() => _scheduler.cancel(r));
      }
    }
    if (kept.length != state.length) await _store(kept);
  }

  Future<ReminderSaveResult> add(
      {required String memberId,
      required String title,
      required DateTime firstAt,
      required ReminderRepeat repeat}) async {
    final r = Reminder(
        id: _newId(),
        memberId: memberId,
        title: title.trim(),
        firstAt: firstAt,
        repeat: repeat);
    if (nextFire(r, _now()) == null) return ReminderSaveResult.inPast;
    // Asked once, with the first reminder (not at launch).
    _allowed ??= await _quietly(_scheduler.requestPermission) ?? false;
    // Stored first: a scheduling failure must never lose what was typed.
    await _store([...state, r]);
    await _reschedule(r);
    return _allowed!
        ? ReminderSaveResult.saved
        : ReminderSaveResult.notificationsOff;
  }

  Future<ReminderSaveResult> update(Reminder r) async {
    if (r.enabled && nextFire(r, _now()) == null) {
      return ReminderSaveResult.inPast;
    }
    await _store([for (final x in state) x.id == r.id ? r : x]);
    await _reschedule(r);
    return _allowed == false
        ? ReminderSaveResult.notificationsOff
        : ReminderSaveResult.saved;
  }

  Future<void> setEnabled(String id, bool on) async {
    final r = state.where((x) => x.id == id).firstOrNull;
    if (r == null) return;
    await _store(
        [for (final x in state) x.id == id ? r.copyWith(enabled: on) : x]);
    await _reschedule(r.copyWith(enabled: on));
  }

  Future<void> delete(String id) async {
    final r = state.where((x) => x.id == id).firstOrNull;
    if (r == null) return;
    await _quietly(() => _scheduler.cancel(r));
    await _store([
      for (final x in state)
        if (x.id != id) x
    ]);
  }

  /// Cancels what was scheduled for [r], then schedules what's still ahead.
  Future<void> _reschedule(Reminder r) async {
    await _quietly(() => _scheduler.cancel(r));
    final times = upcoming(r, _now());
    if (times.isEmpty) return;
    await _quietly(() => _scheduler.schedule(r, times,
        body: _bodyFor(_names[r.memberId] ?? ''), channel: _channel));
  }

  /// The phone's notification system failed (timezone, plugin): the
  /// reminder stays saved and is scheduled again on the next start.
  Future<T?> _quietly<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(List<Reminder> all) async {
    await _save(all);
    _emit(all);
  }

  void _emit(List<Reminder> all) {
    final now = _now();
    // Soonest first; past and turned-off ones at the end.
    int key(Reminder r) => nextFire(r, now)?.millisecondsSinceEpoch ?? 1 << 62;
    emit([...all]..sort((a, b) => key(a).compareTo(key(b))));
  }

  static final _random = Random.secure();
  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 32).toRadixString(36)}';
}
