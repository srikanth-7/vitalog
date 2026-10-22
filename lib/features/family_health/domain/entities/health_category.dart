import 'lab_result.dart';

class HealthCategory {
  const HealthCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.keyTests = const [],
    this.onAdvice = false,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;

  /// Tests routine check-ups in this group usually include. Used only to show
  /// what hasn't been tested yet, never to judge results.
  final List<KeyTest> keyTests;

  /// Tests done only when a doctor asks for them (cancer markers, hormones…).
  /// Their [keyTests] are examples, never flagged as missing.
  final bool onAdvice;

  /// Key tests with no result among [results].
  List<KeyTest> missingFrom(List<LabResult> results) => onAdvice
      ? const []
      : [
          for (final k in keyTests)
            if (!results.any(k.matches)) k
        ];
}

/// A commonly checked test, with the (lowercased) names labs print it under.
class KeyTest {
  const KeyTest(this.name, this.printedAs);
  final String name;

  /// Hash set: membership is checked for every result.
  final Set<String> printedAs;

  bool matches(LabResult r) => printedAs.contains(r.name.toLowerCase());
}
