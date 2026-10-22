import 'entities/health_category.dart';

/// Every health category the app knows, in display order. Fixed: each family
/// member sees all of them, split into tested and yet to test. Ids match
/// `labTestCatalog`, which files each parsed test under one of these; key test
/// names match the catalog's (lowercased).
const healthCategories = <HealthCategory>[
  HealthCategory(
      id: 'blood',
      name: 'Blood & CBC',
      iconKey: 'bloodtype_outlined',
      colorValue: 0xFFB85E58,
      keyTests: [
        KeyTest('Hemoglobin', {'hemoglobin'}),
        KeyTest('WBC count', {'wbc count'}),
        KeyTest('Platelet count', {'platelet count'}),
      ]),
  HealthCategory(
      id: 'glucose',
      name: 'Glucose',
      iconKey: 'water_drop_outlined',
      colorValue: 0xFFC18A37,
      keyTests: [
        KeyTest('Fasting glucose', {'fasting glucose'}),
        KeyTest('HbA1c', {'hba1c'}),
      ]),
  HealthCategory(
      id: 'kidney',
      name: 'Kidney',
      iconKey: 'filter_alt_outlined',
      colorValue: 0xFF4C8D82,
      keyTests: [
        KeyTest('Creatinine', {'creatinine'}),
        KeyTest('eGFR', {'egfr'}),
      ]),
  HealthCategory(
      id: 'liver',
      name: 'Liver',
      iconKey: 'spa_outlined',
      colorValue: 0xFF94734B,
      keyTests: [
        KeyTest('ALT', {'sgpt (alt)', 'alt'}),
        KeyTest('AST', {'sgot (ast)', 'ast'}),
      ]),
  HealthCategory(
      id: 'lipid',
      name: 'Lipid profile',
      iconKey: 'monitor_heart_outlined',
      colorValue: 0xFF6E7FA9,
      keyTests: [
        KeyTest('Total cholesterol', {'total cholesterol'}),
        KeyTest('LDL', {'ldl cholesterol'}),
        KeyTest('HDL', {'hdl cholesterol'}),
        KeyTest('Triglycerides', {'triglycerides'}),
      ]),
  HealthCategory(
      id: 'thyroid',
      name: 'Thyroid',
      iconKey: 'bubble_chart_outlined',
      colorValue: 0xFF8A6D9F,
      keyTests: [
        KeyTest('TSH', {'tsh'})
      ]),
  HealthCategory(
      id: 'vitamins',
      name: 'Vitamins',
      iconKey: 'wb_sunny_outlined',
      colorValue: 0xFFB38A43,
      keyTests: [
        KeyTest('Vitamin D', {'vitamin d, 25-oh'}),
        KeyTest('Vitamin B12', {'vitamin b12'}),
      ]),
  HealthCategory(
      id: 'iron',
      name: 'Iron',
      iconKey: 'grain',
      colorValue: 0xFFB46B50,
      keyTests: [
        KeyTest('Ferritin', {'ferritin'})
      ]),
  HealthCategory(
      id: 'urine',
      name: 'Urine',
      iconKey: 'opacity_outlined',
      colorValue: 0xFF5588A2,
      keyTests: [
        KeyTest('Urine protein', {'urine protein'})
      ]),
  HealthCategory(
      id: 'heart',
      name: 'Heart',
      iconKey: 'favorite_border',
      colorValue: 0xFFB5525F,
      keyTests: [
        KeyTest('hs-CRP', {'hs-crp'}),
        KeyTest('Homocysteine', {'homocysteine'}),
      ]),
  HealthCategory(
      id: 'pancreas',
      name: 'Pancreas',
      iconKey: 'science_outlined',
      colorValue: 0xFFA0794A,
      onAdvice: true,
      keyTests: [
        KeyTest('Amylase', {'amylase'}),
        KeyTest('Lipase', {'lipase'}),
        KeyTest('Fasting insulin', {'fasting insulin'}),
      ]),
  HealthCategory(
      id: 'immunity',
      name: 'Immunity & inflammation',
      iconKey: 'shield_outlined',
      colorValue: 0xFF4E8A6A,
      keyTests: [
        KeyTest('CRP', {'crp'})
      ]),
  HealthCategory(
      id: 'cancer',
      name: 'Cancer markers',
      iconKey: 'biotech_outlined',
      colorValue: 0xFF7C6A9C,
      onAdvice: true,
      keyTests: [
        KeyTest('PSA', {'psa'}),
        KeyTest('CEA', {'cea'}),
        KeyTest('CA-125', {'ca-125'}),
        KeyTest('AFP', {'afp'}),
      ]),
  HealthCategory(
      id: 'hormones',
      name: 'Hormones',
      iconKey: 'balance',
      colorValue: 0xFFA0607E,
      onAdvice: true,
      keyTests: [
        KeyTest('Testosterone', {'testosterone'}),
        KeyTest('Cortisol', {'cortisol'}),
        KeyTest('Prolactin', {'prolactin'}),
      ]),
  HealthCategory(
      id: 'infections',
      name: 'Infections',
      iconKey: 'coronavirus_outlined',
      colorValue: 0xFF5C7F96,
      onAdvice: true,
      keyTests: [
        KeyTest('HBsAg', {'hbsag'}),
        KeyTest('Anti-HCV', {'anti-hcv'}),
        KeyTest('HIV', {'hiv i & ii'}),
      ]),
  HealthCategory(
      id: 'clotting',
      name: 'Clotting',
      iconKey: 'healing_outlined',
      colorValue: 0xFF9A5A4E,
      onAdvice: true,
      keyTests: [
        KeyTest('PT / INR', {'prothrombin time', 'inr'}),
        KeyTest('aPTT', {'aptt'}),
      ]),
  // Results the app couldn't file; the user picks a category for each.
  // Shown only when it has results (it has no key tests to suggest).
  HealthCategory(
      id: 'other',
      name: 'Other tests',
      iconKey: 'category_outlined',
      colorValue: 0xFF6F7C76),
];
