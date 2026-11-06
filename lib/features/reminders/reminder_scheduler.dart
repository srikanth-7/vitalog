import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder.dart';
import 'reminders_cubit.dart';

/// Reminders as the phone's own scheduled notifications: nothing leaves the
/// phone. Inexact on Android (no exact-alarm permission to ask for): a
/// "get tested" nudge a few minutes late is fine.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  /// Up to this many upcoming times per reminder hold a notification slot
  /// (iOS keeps 64 pending in all).
  static const _slots = 8;

  Future<void> _init() => _ready ??= () async {
        tzdata.initializeTimeZones();
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
        await _plugin.initialize(
            settings: const InitializationSettings(
                // Android draws small icons as a white silhouette: a full-colour
                // launcher icon becomes a square.
                android: AndroidInitializationSettings('ic_notification'),
                // Permission is asked when the first reminder is added.
                iOS: DarwinInitializationSettings(
                    requestAlertPermission: false,
                    requestBadgePermission: false,
                    requestSoundPermission: false)));
      }();

  /// No plugin on this platform (widget tests, desktop): reminders are kept
  /// but nothing is scheduled.
  Future<T?> _safely<T>(Future<T> Function() body) async {
    try {
      await _init();
      return await body();
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> requestPermission() async =>
      await _safely(() async {
        if (Platform.isAndroid) {
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.requestNotificationsPermission() ??
              false;
        }
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      }) ??
      false;

  @override
  Future<bool> isAllowed() async =>
      await _safely(() async {
        if (Platform.isAndroid) {
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.areNotificationsEnabled() ??
              false;
        }
        return (await _plugin
                    .resolvePlatformSpecificImplementation<
                        IOSFlutterLocalNotificationsPlugin>()
                    ?.checkPermissions())
                ?.isEnabled ??
            false;
      }) ??
      false;

  @override
  Future<void> schedule(Reminder r, List<DateTime> times,
      {required String body, String channel = 'Reminders'}) async {
    await _safely(() async {
      for (final (i, at) in times.take(_slots).indexed) {
        await _plugin.zonedSchedule(
          id: _id(r, i),
          title: r.title,
          body: body,
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          // Same channel id always; Android shows the latest name given.
          notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails('reminders', channel,
                  icon: 'ic_notification',
                  importance: Importance.high,
                  priority: Priority.high),
              iOS: const DarwinNotificationDetails()),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    });
  }

  @override
  Future<void> cancel(Reminder r) async {
    await _safely(() async {
      for (var i = 0; i < _slots; i++) {
        await _plugin.cancel(id: _id(r, i));
      }
    });
  }

  /// A stable notification id per reminder and slot (FNV-1a of the id).
  static int _id(Reminder r, int slot) {
    var h = 0x811c9dc5;
    for (final c in r.id.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return (h % 0x0fffffff) * _slots + slot;
  }
}
