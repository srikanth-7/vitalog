import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_flutter/main.dart';

void main() {
  testWidgets('dashboard switches family profiles and updates mock results',
      (tester) async {
    await tester.pumpWidget(const FamilyHealthApp());
    await tester.pumpAndSettle();

    expect(find.text('Maya Sharma'), findsOneWidget);
    expect(find.text('Fasting glucose'), findsOneWidget);

    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arjun Sharma'));
    await tester.pumpAndSettle();

    expect(find.text('Arjun Sharma'), findsOneWidget);
    expect(find.text('LDL cholesterol'), findsOneWidget);
    expect(find.text('Maya Sharma'), findsNothing);
  });

  testWidgets('report review prototype is reachable from reports',
      (tester) async {
    await tester.pumpWidget(const FamilyHealthApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a report'));
    await tester.pumpAndSettle();

    expect(find.text('Review report'), findsOneWidget);
    expect(find.text('Confirm sample review'), findsOneWidget);
  });
}
