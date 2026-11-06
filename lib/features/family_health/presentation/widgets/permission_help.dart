import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

const _settings = MethodChannel('vitalog/app_settings');

/// Opens this app's page in the phone's Settings ([notifications]: straight
/// to its notification settings where the phone allows).
Future<void> openAppSettings({bool notifications = false}) async {
  try {
    await _settings.invokeMethod<void>(
        'open', notifications ? 'notifications' : null);
  } on MissingPluginException {
    // Tests / desktop: nothing to open.
  } on PlatformException {
    // Settings couldn't open; the message already says where to go.
  }
}

/// A permission was refused: say what's off in plain words, with a button
/// that goes straight to the right Settings page. Stays up long enough to
/// read slowly.
void showPermissionOff(
    ScaffoldMessengerState? messenger, AppLocalizations l10n, String message,
    {bool notifications = false}) {
  messenger?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 10),
      content: Text(message),
      action: SnackBarAction(
          label: l10n.openSettings,
          onPressed: () => openAppSettings(notifications: notifications))));
}
