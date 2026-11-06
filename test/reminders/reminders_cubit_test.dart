import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/reminders/reminder.dart';
import 'package:vitalog/features/reminders/reminders_cubit.dart';

class _FakeScheduler implements ReminderScheduler {
  _FakeScheduler({this.allowed = true, this.broken = false});
  final bool allowed;
  final bool broken;
  final scheduled = <String, (List<DateTime>, String, String)>{};
  var asked = 0;
  @override
  Future<bool> isAllowed() async => true;
  @override
  Future<bool> requestPermission() async {
    asked++;
    if (broken) throw StateError('no timezone');
    return allowed;
  }

  @override
  Future<void> schedule(Reminder r, List<DateTime> times,
      {required String body, String channel = ''}) async {
    if (broken) throw StateError('no timezone');
    scheduled[r.id] = (times, r.title, body);
  }

  @override
  Future<void> cancel(Reminder r) async {
    if (broken) throw StateError('no timezone');
    scheduled.remove(r.id);
  }
}

void main() {
  final now = DateTime(2026, 10, 27, 9);
  late _FakeScheduler scheduler;
  late List<Reminder> saved;
  late RemindersCubit cubit;

  setUp(() async {
    scheduler = _FakeScheduler();
    saved = [];
    cubit = RemindersCubit(
        load: () async => saved,
        save: (all) async => saved = all,
        scheduler: scheduler,
        now: () => now);
    await cubit.start();
    cubit.syncMembers({'maya': 'Maya', 'arjun': 'Arjun'},
        bodyFor: (name) => 'Reminder for $name');
  });

  test('adding a reminder saves it and schedules what comes next', () async {
    await cubit.add(
        memberId: 'maya',
        title: 'Get tested',
        firstAt: DateTime(2026, 11, 1, 8),
        repeat: ReminderRepeat.every3Months);
    expect(saved, hasLength(1));
    final (times, title, body) = scheduler.scheduled[saved.single.id]!;
    expect(times.first, DateTime(2026, 11, 1, 8));
    expect(times, hasLength(4));
    expect(title, 'Get tested');
    expect(body, 'Reminder for Maya'); // no test names or values
    expect(scheduler.asked, 1);
  });

  test('deleting or turning off a reminder cancels it', () async {
    await cubit.add(
        memberId: 'maya',
        title: 'Get tested',
        firstAt: DateTime(2026, 11, 1, 8),
        repeat: ReminderRepeat.monthly);
    final r = saved.single;
    await cubit.setEnabled(r.id, false);
    expect(scheduler.scheduled, isEmpty);
    await cubit.setEnabled(r.id, true);
    expect(scheduler.scheduled, contains(r.id));
    await cubit.delete(r.id);
    expect(scheduler.scheduled, isEmpty);
    expect(saved, isEmpty);
  });

  test("a removed member's reminders go with them", () async {
    await cubit.add(
        memberId: 'arjun',
        title: 'Add latest report',
        firstAt: DateTime(2026, 11, 1, 8),
        repeat: ReminderRepeat.yearly);
    await cubit
        .syncMembers({'maya': 'Maya'}, bodyFor: (name) => 'Reminder for $name');
    expect(saved, isEmpty);
    expect(scheduler.scheduled, isEmpty);
  });

  test('on start, every enabled reminder is scheduled again', () async {
    saved = [
      Reminder(
          id: 'a',
          memberId: 'maya',
          title: 'A',
          firstAt: DateTime(2026, 12, 1, 8),
          repeat: ReminderRepeat.monthly),
      Reminder(
          id: 'b',
          memberId: 'maya',
          title: 'B',
          firstAt: DateTime(2026, 12, 1, 8),
          repeat: ReminderRepeat.monthly,
          enabled: false),
    ];
    final fresh = _FakeScheduler();
    final again = RemindersCubit(
        load: () async => saved,
        save: (all) async => saved = all,
        scheduler: fresh,
        now: () => now);
    await again.start();
    await again
        .syncMembers({'maya': 'Maya'}, bodyFor: (name) => 'Reminder for $name');
    expect(fresh.scheduled.keys, ['a']);
  });

  RemindersCubit cubitWith(_FakeScheduler fake) => RemindersCubit(
      load: () async => saved,
      save: (all) async => saved = all,
      scheduler: fake,
      now: () => now);

  test('a one-off time already past is refused, not saved silently', () async {
    final result = await cubit.add(
        memberId: 'maya',
        title: 'Old',
        firstAt: DateTime(2026, 10, 27, 8), // an hour ago
        repeat: ReminderRepeat.once);
    expect(result, ReminderSaveResult.inPast);
    expect(saved, isEmpty);
  });

  test('with notifications turned off it is saved, and says so', () async {
    final c = cubitWith(_FakeScheduler(allowed: false));
    await c.start();
    final result = await c.add(
        memberId: 'maya',
        title: 'Get tested',
        firstAt: DateTime(2026, 11, 1, 8),
        repeat: ReminderRepeat.monthly);
    expect(result, ReminderSaveResult.notificationsOff);
    expect(saved, hasLength(1));
  });

  test('a scheduling failure never loses the reminder', () async {
    final c = cubitWith(_FakeScheduler(broken: true));
    await c.start();
    await c.add(
        memberId: 'maya',
        title: 'Get tested',
        firstAt: DateTime(2026, 11, 1, 8),
        repeat: ReminderRepeat.monthly);
    expect(saved, hasLength(1));
    await c.syncMembers({'maya': 'Maya'}, bodyFor: (n) => n); // no throw
  });
}
