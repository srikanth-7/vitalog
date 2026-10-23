import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/lab_report_parser.dart';
import 'package:vitalog/features/family_health/domain/entities/lab_result.dart';

void main() {
  final parser = LabReportParser(now: DateTime(2026, 10, 22));

  test('reads a typical Indian lab report', () {
    final report = parser.parse([
      'CityCare Diagnostics Pvt Ltd',
      'Patient Name: Maya Sharma   Age/Sex: 34 Y / F',
      'DOB: 02/03/1992',
      'Collected On: 17/09/2026 08:10   Reported On: 18/09/2026 14:22',
      'COMPLETE BLOOD COUNT',
      'Hemoglobin  12.8  g/dL  12.0 - 15.5',
      'Platelet Count  2,50,000  /cumm  1,50,000 - 4,50,000',
      'Total Leucocyte Count  11.8  H  10^3/µL  4.0 - 11.0',
      'BIOCHEMISTRY',
      'Glucose, Fasting (FBS)  96  mg/dL  70 - 99',
      'HbA1c  6.1  %  4.0 - 5.6',
      'Vitamin D, 25-OH  24  ng/mL  30 - 100',
      'LIPID PROFILE',
      'LDL Cholesterol  162  mg/dL  < 100',
      'HDL Cholesterol  48  mg/dL  > 40',
      'TSH  2.1  mIU/L  0.4 - 4.0',
      'URINE ROUTINE',
      'Albumin  Nil',
      'Pus Cells  2-3  /hpf  0 - 5',
      'Note: HbA1c above 6.5 indicates diabetes',
    ]);

    expect(report.lab, 'CityCare Diagnostics Pvt Ltd');
    expect(report.reportDate, DateTime(2026, 9, 18));
    expect(report.collectionDate, DateTime(2026, 9, 17));

    ParsedTest t(String name) => report.tests.firstWhere((t) => t.name == name);
    expect(t('Hemoglobin').value, '12.8');
    expect(t('Hemoglobin').unit, 'g/dL');
    expect(t('Hemoglobin').status, ResultStatus.withinRange);
    expect(t('Hemoglobin').categoryId, 'blood');
    expect(t('Platelet count').value, '250000');
    expect(t('WBC count').status, ResultStatus.high);
    expect(t('Fasting glucose').categoryId, 'glucose');
    expect(t('HbA1c').status, ResultStatus.high);
    expect(t('Vitamin D, 25-OH').value, '24');
    expect(t('Vitamin D, 25-OH').status, ResultStatus.low);
    expect(t('LDL cholesterol').status, ResultStatus.high);
    expect(t('HDL cholesterol').status, ResultStatus.withinRange);
    expect(t('TSH').categoryId, 'thyroid');
    expect(t('Urine protein').value, 'Nil');
    expect(t('Urine protein').categoryId, 'urine');
    expect(report.tests.where((t) => t.name == 'HbA1c'), hasLength(1));
  });

  test('falls back to latest non-birth date and month-name formats', () {
    final report = parser.parse([
      'Northside Lab',
      'Date of birth: 12 Jan 1990',
      'Sample date 2 Mar 2026',
      'Printed: Mar 4, 2026',
      'Creatinine 0.82 mg/dL 0.6-1.1',
    ]);
    expect(report.collectionDate, DateTime(2026, 3, 2));
    expect(report.reportDate, DateTime(2026, 3, 4));
    expect(report.tests.single.categoryId, 'kidney');
  });

  test('grouped ranges and µL units are judged correctly', () {
    final report = parser.parse([
      'COMPLETE BLOOD COUNT',
      'Total Leucocyte Count  7.2  10^3/µL  4.0 - 11.0',
      'Platelet Count  2,40,000  /cumm  1,50,000 - 4,50,000',
    ]);
    // The "L" of µL is part of the unit, not a Low flag.
    expect(report.tests[0].status, ResultStatus.withinRange);
    expect(report.tests[1].referenceRange, '1,50,000 - 4,50,000 /cumm');
    expect(report.tests[1].status, ResultStatus.withinRange);
    final high = parser
        .parse(['Platelet Count  5,10,000  /cumm  1,50,000 - 4,50,000']);
    expect(high.tests.single.status, ResultStatus.high);
  });

  test('cell counts printed as a span are the value, judged by their ends',
      () {
    final report = parser.parse([
      'URINE ROUTINE',
      'Pus Cells  2-3  /hpf  0 - 5',
      'Epithelial Cells  8-10  /hpf  0 - 5',
    ]);
    expect(report.tests[0].value, '2-3');
    expect(report.tests[0].referenceRange, '0 - 5 /hpf');
    expect(report.tests[0].status, ResultStatus.withinRange);
    expect(report.tests[1].status, ResultStatus.high);
    expect(parser.statusFor('6-8', '0 - 5'), ResultStatus.high);
  });

  test('a range printed on the next line belongs to the test above', () {
    final report = parser.parse([
      'Hemoglobin  12.8  g/dL',
      '(12.0 - 15.5)',
      'TSH  6.1  mIU/L',
      'Ref. Range: 0.4 - 4.0',
      'Creatinine  0.9  mg/dL',
      'Urea  30  mg/dL  15 - 40',
    ]);
    ParsedTest t(String name) => report.tests.firstWhere((t) => t.name == name);
    expect(t('Hemoglobin').referenceRange, '12.0 - 15.5 g/dL');
    expect(t('Hemoglobin').status, ResultStatus.withinRange);
    expect(t('TSH').status, ResultStatus.high);
    // Not followed by a range line: stays unjudged, and doesn't steal one.
    expect(t('Creatinine').referenceRange, '');
    expect(t('Urea').referenceRange, '15 - 40 mg/dL');
  });

  test('ranges printed per sex are kept whole and left for review', () {
    final report = parser.parse([
      'Hemoglobin  13.5  g/dL  M: 13.0 - 17.0  F: 12.0 - 15.5',
      'MCV  88  fL  80 - 100',
    ]);
    expect(report.tests[0].referenceRange, 'M: 13.0 - 17.0 F: 12.0 - 15.5');
    expect(report.tests[0].status, ResultStatus.needsReview);
    // "fL" is a unit, not a female band.
    expect(report.tests[1].status, ResultStatus.withinRange);
    expect(parser.statusFor('11', 'Male 13-17 Female 12-15.5'),
        ResultStatus.needsReview);
  });

  test('two tests printed side by side in one row are both read', () {
    final report = parser.parse([
      'Hemoglobin  12.8  g/dL  12.0 - 15.5  Creatinine  1.4  mg/dL  0.6 - 1.1',
    ]);
    expect(report.tests.map((t) => t.name), ['Hemoglobin', 'Creatinine']);
    expect(report.tests[1].status, ResultStatus.high);
  });

  test('a value with no unit, range or flag is not treated as a result', () {
    final report = parser.parse(['TSH was 4 last year']);
    expect(report.tests, isEmpty);
  });

  test('real Apple Vision output, including misread unit cells', () {
    // Captured from VNRecognizeTextRequest on a rendered report.
    final report = parser.parse([
      'Sunrise Pathology Laboratory',
      'Patient: Test Person  Age/Sex: 41 Y / M',
      'Collected On: 10/10/2026 08:05  Reported On: 11/10/2026 13:40',
      'LIPID PROFILE',
      'Test  Result  Unit  Reference Range',
      'Total Cholesterol  212  mg/dL  < 200',
      'Triglycerides  180  mg/dL  < 150',
      'HDL Cholesterol  44  тр/бш  > 40',
      'LDL Cholesterol  132  7р/бш  < 100',
      'THYROID PROFILE',
      'TSH  3.10  HIU/mL  0.40 - 4.50',
      'Free T4  1.2  ng/dL  0.8 - 1.8',
      'Glucose, Fasting  104  mg/dL  70 - 99',
      'HbA1c  5.9  %  4.0 - 5.6',
      'Hemoglobin  14.6  g/dL  13.0 - 17.0',
    ]);
    ParsedTest t(String name) => report.tests.firstWhere((t) => t.name == name);
    expect(report.tests, hasLength(9));
    expect(report.lab, 'Sunrise Pathology Laboratory');
    expect(report.reportDate, DateTime(2026, 10, 11));
    expect(report.collectionDate, DateTime(2026, 10, 10));
    expect(t('HDL cholesterol').unit, 'mg/dL');
    expect(t('HDL cholesterol').status, ResultStatus.withinRange);
    expect(t('LDL cholesterol').status, ResultStatus.high);
    expect(t('TSH').unit, 'µIU/mL');
    expect(t('Fasting glucose').status, ResultStatus.high);
    expect(t('Total cholesterol').status, ResultStatus.high);
    expect(t('Hemoglobin').categoryId, 'blood');
  });

  test(
      'reads heart, pancreas, immunity, cancer, hormone, infection and clotting rows',
      () {
    final report = LabReportParser().parse([
      'CARDIAC RISK MARKERS',
      'hs-CRP  3.8  mg/L  < 1.0',
      'Homocysteine  11.2  µmol/L  5 - 15',
      'Serum Amylase  64  U/L  28 - 100',
      'CRP  4  mg/L  < 6',
      'TUMOR MARKERS',
      'Total PSA  1.9  ng/mL  < 4.0',
      'CA 19-9  12.4  U/mL  < 37',
      'Testosterone  512  ng/dL  264 - 916',
      'SEROLOGY',
      'HBsAg  Non Reactive',
      'HIV I & II  Non-Reactive',
      'COAGULATION',
      'INR  1.1  0.8 - 1.2',
    ]);
    ParsedTest t(String name) => report.tests.firstWhere((t) => t.name == name);
    expect(t('hs-CRP').categoryId, 'heart');
    expect(t('hs-CRP').status, ResultStatus.high);
    expect(t('CRP').categoryId, 'immunity'); // not swallowed by hs-CRP
    expect(t('Amylase').categoryId, 'pancreas');
    expect(t('PSA').categoryId, 'cancer');
    expect(t('CA 19-9').unit, 'U/mL');
    expect(t('CA 19-9').status, ResultStatus.withinRange);
    expect(t('Testosterone').categoryId, 'hormones');
    expect(t('HBsAg').status, ResultStatus.withinRange);
    expect(t('HIV I & II').categoryId, 'infections');
    expect(t('INR').categoryId, 'clotting');
  });
}
