import 'dart:math' as math;

/// How often a reminder comes back. Months, not days: lab tests are
/// scheduled "every three months", not "every 91 days".
enum ReminderRepeat {
  once(0),
  monthly(1),
  every3Months(3),
  every6Months(6),
  yearly(12);

  const ReminderRepeat(this.months);
  final int months;
}

/// A reminder set on this phone for one family member: get tested, add the
/// latest report… Stored encrypted with the rest of the phone's data.
class Reminder {
  const Reminder({
    required this.id,
    required this.memberId,
    required this.title,
    required this.firstAt,
    required this.repeat,
    this.enabled = true,
  });

  final String id;
  final String memberId;

  /// What the person typed; it's what the lock screen shows, so it's theirs
  /// to choose (the app never adds test names or values).
  final String title;

  /// The first time it fires, in local time. Repeats count from here.
  final DateTime firstAt;
  final ReminderRepeat repeat;
  final bool enabled;

  Reminder copyWith(
          {String? memberId,
          String? title,
          DateTime? firstAt,
          ReminderRepeat? repeat,
          bool? enabled}) =>
      Reminder(
          id: id,
          memberId: memberId ?? this.memberId,
          title: title ?? this.title,
          firstAt: firstAt ?? this.firstAt,
          repeat: repeat ?? this.repeat,
          enabled: enabled ?? this.enabled);

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'title': title,
        'firstAt': firstAt.toIso8601String(),
        'repeat': repeat.name,
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        memberId: j['memberId'] as String,
        title: j['title'] as String,
        firstAt: DateTime.parse(j['firstAt'] as String),
        repeat: ReminderRepeat.values.byName(j['repeat'] as String),
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// [d] moved by [months], clamped to the last day of the target month
/// (31 January + 1 month = 28/29 February).
DateTime _addMonths(DateTime d, int months) {
  final first = DateTime(d.year, d.month + months);
  final days = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(
      first.year, first.month, math.min(d.day, days), d.hour, d.minute);
}

/// The next times [r] fires after [now], up to [count]. Each one is counted
/// from [Reminder.firstAt], so a month-end reminder never drifts.
List<DateTime> upcoming(Reminder r, DateTime now, {int count = 4}) {
  if (!r.enabled) return const [];
  if (r.repeat == ReminderRepeat.once) {
    return r.firstAt.isAfter(now) ? [r.firstAt] : const [];
  }
  final step = r.repeat.months;
  // Skip whole periods already past, then walk forward.
  final behind = (now.year - r.firstAt.year) * 12 + now.month - r.firstAt.month;
  var k = math.max(0, behind ~/ step - 1);
  final times = <DateTime>[];
  while (times.length < count) {
    final t = _addMonths(r.firstAt, k * step);
    if (t.isAfter(now)) times.add(t);
    k++;
  }
  return times;
}

/// When [r] fires next, or null (past one-off, or turned off).
DateTime? nextFire(Reminder r, DateTime now) =>
    upcoming(r, now, count: 1).firstOrNull;
