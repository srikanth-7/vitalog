import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_bloc.dart';
import 'package:vitalog/features/family_health/presentation/widgets/recovery_key_sheets.dart';

// Security review 2026-11-06: no readable secret or report is left lying
// around (clipboard, temp folders).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('leftover scan copies are swept; other temp files stay', () async {
    final dir = await Directory.systemTemp.createTemp('vitalog_sweep');
    addTearDown(() => dir.delete(recursive: true));
    final scan = File('${dir.path}/scan-123.pdf')..writeAsStringSync('x');
    final other = File('${dir.path}/report.pdf')..writeAsStringSync('x');

    await HealthBloc.sweepScanCopies([dir.path, '${dir.path}/missing']);

    expect(scan.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
  });

  testWidgets('a copied recovery key is cleared after a minute',
      (tester) async {
    final writes = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        writes.add((call.arguments as Map)['text'] as String?);
      }
      return null;
    });

    await copySecret('KEY');
    expect(writes, ['KEY']);
    await tester.pump(const Duration(seconds: 59));
    expect(writes, ['KEY']);
    await tester.pump(const Duration(seconds: 2));
    expect(writes, ['KEY', '']);
  });
}
