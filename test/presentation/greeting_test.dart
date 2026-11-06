import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/presentation/health_presentation.dart';

void main() {
  test('greetingName uses the first name, never an email', () {
    expect(greetingName('Srikanth V'), 'Srikanth');
    expect(greetingName('  '), isNull);
    expect(greetingName(null), isNull);
    expect(greetingName('srikanth.v@akrivia.in'), isNull);
  });
}
