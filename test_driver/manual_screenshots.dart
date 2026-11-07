import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves each screenshot from integration_test/manual_screenshots_test.dart
/// into docs/manual/screens/ (the user manual's pictures).
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        File('docs/manual/screens/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        return true;
      },
    );
