import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/presentation/pages/dash_board_screen.dart';

void main() {
  testWidgets('a notice with a View action closes by itself', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                noticeSnackBar('Report ready',
                    action: SnackBarAction(label: 'View', onPressed: () {}),
                    simple: false)),
            child: const Text('show'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Report ready'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Report ready'), findsNothing);
  });

  test('Simple mode keeps a notice up for 10 seconds', () {
    expect(noticeSnackBar('x', simple: true).duration,
        const Duration(seconds: 10));
    expect(noticeSnackBar('x', simple: false).duration,
        const Duration(seconds: 4));
  });

  test('a notice waits for the person when a screen reader is on', () {
    expect(
        noticeSnackBar('x', simple: false, screenReader: true).persist, isTrue);
    expect(noticeSnackBar('x', simple: false).persist, isFalse);
  });
}
