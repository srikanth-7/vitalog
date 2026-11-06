import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/reminders/reminder.dart';

Reminder _r(DateTime first, ReminderRepeat repeat, {bool enabled = true}) =>
    Reminder(
        id: 'r1',
        memberId: 'maya',
        title: 'Get tested',
        firstAt: first,
        repeat: repeat,
        enabled: enabled);

void main() {
  final now = DateTime(2026, 10, 27, 9);

  test('a one-off reminder fires once, and not if it is past', () {
    final future = DateTime(2026, 11, 1, 8);
    expect(nextFire(_r(future, ReminderRepeat.once), now), future);
    expect(
        nextFire(_r(DateTime(2026, 10, 1), ReminderRepeat.once), now), isNull);
  });

  test('a turned-off reminder never fires', () {
    expect(
        nextFire(
            _r(DateTime(2026, 11, 1), ReminderRepeat.monthly, enabled: false),
            now),
        isNull);
  });

  test('monthly from the 31st clamps to the month end, without drifting', () {
    final r = _r(DateTime(2026, 1, 31, 8), ReminderRepeat.monthly);
    expect(nextFire(r, DateTime(2026, 2, 1)), DateTime(2026, 2, 28, 8));
    expect(nextFire(r, DateTime(2026, 3, 1)), DateTime(2026, 3, 31, 8));
  });

  test('every 3 months skips to the next one still ahead', () {
    final r = _r(DateTime(2026, 1, 15, 8), ReminderRepeat.every3Months);
    expect(nextFire(r, now), DateTime(2027, 1, 15, 8));
    expect(upcoming(r, now, count: 3), [
      DateTime(2027, 1, 15, 8),
      DateTime(2027, 4, 15, 8),
      DateTime(2027, 7, 15, 8),
    ]);
  });

  test('yearly on 29 February falls on the 28th in other years', () {
    final r = _r(DateTime(2028, 2, 29, 8), ReminderRepeat.yearly);
    expect(nextFire(r, DateTime(2028, 3, 1)), DateTime(2029, 2, 28, 8));
  });

  test('a reminder survives a save and load', () {
    final r = _r(DateTime(2026, 11, 1, 8, 30), ReminderRepeat.every6Months);
    final back = Reminder.fromJson(r.toJson());
    expect(back.toJson(), r.toJson());
  });
}
