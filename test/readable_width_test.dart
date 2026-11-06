import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/layout/readable_width.dart';

Future<double> _widthAt(WidgetTester tester, double screen) async {
  tester.view.physicalSize = Size(screen, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  const key = Key('content');
  await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: ReadableWidth(child: SizedBox.expand(key: key))));
  return tester.getSize(find.byKey(key)).width;
}

void main() {
  testWidgets('the open iPhone Duo (669 pt) uses the whole width',
      (tester) async {
    expect(await _widthAt(tester, 669), 669);
  });

  testWidgets('a tablet-wide screen still gets the readable column',
      (tester) async {
    expect(await _widthAt(tester, 834), ReadableWidth.maxWidth);
  });
}
