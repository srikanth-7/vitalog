// Renders the launcher icons from VitalogMarkPainter, so the icon and the
// animated splash are the same drawing. Run, then resize with tool/icons.sh:
//   flutter test tool/generate_app_icons_test.dart && sh tool/icons.sh
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/brand/vitalog_mark.dart';

Future<void> _render(String path, {required bool rounded}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  VitalogMarkPainter(rounded: rounded)
      .paint(Canvas(recorder), const Size.square(size));
  final image =
      await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('render launcher icons', () async {
    Directory('build/icons').createSync(recursive: true);
    // iOS masks the corners itself and rejects transparency.
    await _render('build/icons/ios_1024.png', rounded: false);
    await _render('build/icons/android_1024.png', rounded: true);
  });
}
