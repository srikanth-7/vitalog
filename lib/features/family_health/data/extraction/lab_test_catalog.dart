/// Known lab tests and the spellings labs print for them. The parser uses this
/// to recognise a row as a test and to file it under a category id (the ids
/// match `healthCategories` in domain/health_categories.dart). Add aliases here when a lab's wording is missed.
/// Category for result rows the catalog doesn't know; the user files them.
const otherCategoryId = 'other';

class LabTestDefinition {
  const LabTestDefinition(this.name, this.categoryId, this.aliases);
  final String name;
  final String categoryId;
  final List<String> aliases;
}

const labTestCatalog = <LabTestDefinition>[
  // Blood & CBC
  LabTestDefinition(
      'Hemoglobin', 'blood', ['hemoglobin', 'haemoglobin', 'hb', 'hgb']),
  LabTestDefinition('RBC count', 'blood', [
    'rbc count',
    'red blood cell count',
    'rbc',
    'total rbc count',
    'erythrocyte count'
  ]),
  LabTestDefinition('WBC count', 'blood', [
    'wbc count',
    'white blood cell count',
    'total leucocyte count',
    'total leukocyte count',
    'tlc',
    'wbc',
    'total wbc count'
  ]),
  LabTestDefinition(
      'Platelet count', 'blood', ['platelet count', 'platelets', 'plt']),
  LabTestDefinition('Hematocrit', 'blood',
      ['hematocrit', 'haematocrit', 'pcv', 'packed cell volume', 'hct']),
  LabTestDefinition('MCV', 'blood', ['mcv', 'mean corpuscular volume']),
  LabTestDefinition('MCH', 'blood',
      ['mch', 'mean corpuscular hemoglobin', 'mean corpuscular haemoglobin']),
  LabTestDefinition('MCHC', 'blood', [
    'mchc',
    'mean corpuscular hemoglobin concentration',
    'mean corpuscular haemoglobin concentration'
  ]),
  LabTestDefinition(
      'RDW', 'blood', ['rdw', 'rdw-cv', 'red cell distribution width']),
  LabTestDefinition(
      'Neutrophils', 'blood', ['neutrophils', 'neutrophil', 'polymorphs']),
  LabTestDefinition('Lymphocytes', 'blood', ['lymphocytes', 'lymphocyte']),
  LabTestDefinition('Monocytes', 'blood', ['monocytes', 'monocyte']),
  LabTestDefinition('Eosinophils', 'blood', ['eosinophils', 'eosinophil']),
  LabTestDefinition('Basophils', 'blood', ['basophils', 'basophil']),
  LabTestDefinition('ESR', 'blood', ['esr', 'erythrocyte sedimentation rate']),
  // Glucose
  LabTestDefinition('Fasting glucose', 'glucose', [
    'fasting blood sugar',
    'fasting glucose',
    'glucose fasting',
    'fasting plasma glucose',
    'blood sugar fasting',
    'glucose, fasting',
    'fbs',
    'fpg'
  ]),
  LabTestDefinition('Post-meal glucose', 'glucose', [
    'post prandial blood sugar',
    'postprandial blood sugar',
    'glucose post prandial',
    'glucose pp',
    'pp blood sugar',
    'ppbs',
    'post prandial glucose',
    'blood sugar pp',
    '2 hr post prandial'
  ]),
  LabTestDefinition('Random glucose', 'glucose',
      ['random blood sugar', 'random glucose', 'glucose random', 'rbs']),
  LabTestDefinition('HbA1c', 'glucose', [
    'hba1c',
    'hb a1c',
    'glycated hemoglobin',
    'glycated haemoglobin',
    'glycosylated hemoglobin',
    'glycosylated haemoglobin',
    'hemoglobin a1c',
    'haemoglobin a1c'
  ]),
  LabTestDefinition('Average blood glucose', 'glucose', [
    'estimated average glucose',
    'average blood glucose',
    'mean blood glucose',
    'eag'
  ]),
  // Kidney
  LabTestDefinition('Creatinine', 'kidney', ['serum creatinine', 'creatinine']),
  LabTestDefinition('Urea', 'kidney', ['blood urea', 'serum urea', 'urea']),
  LabTestDefinition(
      'BUN', 'kidney', ['blood urea nitrogen', 'bun', 'urea nitrogen']),
  LabTestDefinition('Uric acid', 'kidney', ['serum uric acid', 'uric acid']),
  LabTestDefinition('eGFR', 'kidney', ['egfr', 'estimated gfr', 'e-gfr']),
  LabTestDefinition('Sodium', 'kidney', ['sodium', 'na+', 'serum sodium']),
  LabTestDefinition(
      'Potassium', 'kidney', ['potassium', 'k+', 'serum potassium']),
  LabTestDefinition(
      'Chloride', 'kidney', ['chloride', 'cl-', 'serum chloride']),
  LabTestDefinition('Calcium', 'kidney', ['serum calcium', 'calcium']),
  // Liver
  LabTestDefinition('SGOT (AST)', 'liver', [
    'sgot',
    'ast',
    'aspartate aminotransferase',
    'sgot/ast',
    'ast (sgot)',
    'sgot (ast)'
  ]),
  LabTestDefinition('SGPT (ALT)', 'liver', [
    'sgpt',
    'alt',
    'alanine aminotransferase',
    'sgpt/alt',
    'alt (sgpt)',
    'sgpt (alt)'
  ]),
  LabTestDefinition(
      'Alkaline phosphatase', 'liver', ['alkaline phosphatase', 'alp']),
  LabTestDefinition('Total bilirubin', 'liver', [
    'total bilirubin',
    'bilirubin total',
    'bilirubin, total',
    'serum bilirubin'
  ]),
  LabTestDefinition('Direct bilirubin', 'liver', [
    'direct bilirubin',
    'bilirubin direct',
    'bilirubin, direct',
    'conjugated bilirubin'
  ]),
  LabTestDefinition('Indirect bilirubin', 'liver', [
    'indirect bilirubin',
    'bilirubin indirect',
    'bilirubin, indirect',
    'unconjugated bilirubin'
  ]),
  LabTestDefinition('Total protein', 'liver',
      ['total protein', 'total proteins', 'serum protein', 'protein total']),
  LabTestDefinition('Albumin', 'liver', ['serum albumin', 'albumin']),
  LabTestDefinition('Globulin', 'liver', ['globulin']),
  LabTestDefinition('A/G ratio', 'liver',
      ['a/g ratio', 'albumin/globulin ratio', 'a:g ratio', 'ag ratio']),
  LabTestDefinition('GGT', 'liver',
      ['ggt', 'gamma gt', 'gamma glutamyl transferase', 'ggtp']),
  // Lipid profile
  LabTestDefinition('Total cholesterol', 'lipid', [
    'total cholesterol',
    'cholesterol total',
    'cholesterol, total',
    'serum cholesterol',
    'cholesterol'
  ]),
  LabTestDefinition('LDL cholesterol', 'lipid', [
    'ldl cholesterol',
    'ldl-c',
    'ldl',
    'ldl direct',
    'low density lipoprotein'
  ]),
  LabTestDefinition('HDL cholesterol', 'lipid', [
    'hdl cholesterol',
    'hdl-c',
    'hdl',
    'hdl direct',
    'high density lipoprotein'
  ]),
  LabTestDefinition('VLDL cholesterol', 'lipid',
      ['vldl cholesterol', 'vldl', 'very low density lipoprotein']),
  LabTestDefinition('Non-HDL cholesterol', 'lipid',
      ['non-hdl cholesterol', 'non hdl cholesterol', 'non-hdl', 'non hdl']),
  LabTestDefinition(
      'Triglycerides', 'lipid', ['triglycerides', 'triglyceride', 'tg']),
  LabTestDefinition('Cholesterol/HDL ratio', 'lipid', [
    'total cholesterol/hdl ratio',
    'chol/hdl ratio',
    'cholesterol/hdl ratio',
    'tc/hdl ratio'
  ]),
  LabTestDefinition(
      'LDL/HDL ratio', 'lipid', ['ldl/hdl ratio', 'ldl:hdl ratio']),
  // Thyroid
  LabTestDefinition('TSH', 'thyroid', [
    'tsh',
    'thyroid stimulating hormone',
    'tsh ultrasensitive',
    'tsh-ultrasensitive'
  ]),
  LabTestDefinition(
      'Free T3', 'thyroid', ['free t3', 'ft3', 'free triiodothyronine']),
  LabTestDefinition('Free T4', 'thyroid', ['free t4', 'ft4', 'free thyroxine']),
  LabTestDefinition('Total T3', 'thyroid',
      ['total t3', 't3 total', 't3', 'triiodothyronine']),
  LabTestDefinition(
      'Total T4', 'thyroid', ['total t4', 't4 total', 't4', 'thyroxine']),
  // Vitamins
  LabTestDefinition('Vitamin D, 25-OH', 'vitamins', [
    'vitamin d, 25-oh',
    'vitamin d 25-oh',
    'vitamin d (25-oh)',
    '25-oh vitamin d',
    '25 oh vitamin d',
    '25-hydroxy vitamin d',
    '25 hydroxy vitamin d',
    'vitamin d total',
    'vitamin d3',
    'vitamin d'
  ]),
  LabTestDefinition('Vitamin B12', 'vitamins',
      ['vitamin b12', 'vitamin b-12', 'cyanocobalamin', 'cobalamin', 'b12']),
  LabTestDefinition(
      'Folate', 'vitamins', ['folic acid', 'folate', 'serum folate']),
  // Iron
  LabTestDefinition('Serum iron', 'iron', ['serum iron', 'iron']),
  LabTestDefinition('Ferritin', 'iron', ['serum ferritin', 'ferritin']),
  LabTestDefinition('TIBC', 'iron', ['tibc', 'total iron binding capacity']),
  LabTestDefinition('Transferrin saturation', 'iron',
      ['transferrin saturation', '% saturation', 'tsat']),
  // Urine
  LabTestDefinition(
      'Urine pH', 'urine', ['urine ph', 'ph', 'reaction (ph)', 'reaction']),
  LabTestDefinition('Specific gravity', 'urine',
      ['specific gravity', 'sp. gravity', 'sp gravity']),
  LabTestDefinition('Urine protein', 'urine',
      ['urine protein', 'urine albumin', 'protein (urine)']),
  LabTestDefinition('Urine glucose', 'urine',
      ['urine glucose', 'urine sugar', 'glucose (urine)', 'sugar (urine)']),
  LabTestDefinition(
      'Ketones', 'urine', ['ketone bodies', 'ketones', 'urine ketones']),
  LabTestDefinition('Pus cells', 'urine',
      ['pus cells', 'pus cell', 'wbc (urine)', 'leucocytes (urine)']),
  LabTestDefinition(
      'Epithelial cells', 'urine', ['epithelial cells', 'epithelial cell']),
  LabTestDefinition('Urine RBC', 'urine',
      ['red blood cells (urine)', 'rbc (urine)', 'urine rbc']),
  // Heart
  LabTestDefinition('hs-CRP', 'heart', [
    'hs-crp',
    'hs crp',
    'hscrp',
    'high sensitivity crp',
    'high sensitivity c-reactive protein'
  ]),
  LabTestDefinition('Homocysteine', 'heart', ['homocysteine']),
  LabTestDefinition(
      'Lipoprotein(a)', 'heart', ['lipoprotein(a)', 'lipoprotein a', 'lp(a)']),
  LabTestDefinition('Troponin I', 'heart', ['troponin i', 'hs troponin i']),
  LabTestDefinition('Troponin T', 'heart', ['troponin t', 'hs troponin t']),
  LabTestDefinition('CK-MB', 'heart', ['ck-mb', 'ckmb', 'ck mb']),
  LabTestDefinition('NT-proBNP', 'heart', ['nt-probnp', 'nt probnp']),
  LabTestDefinition('CPK', 'heart', ['cpk', 'creatine kinase', 'ck total']),
  // Pancreas
  LabTestDefinition('Amylase', 'pancreas', ['amylase', 'serum amylase']),
  LabTestDefinition('Lipase', 'pancreas', ['lipase', 'serum lipase']),
  LabTestDefinition('Fasting insulin', 'pancreas',
      ['fasting insulin', 'insulin fasting', 'insulin']),
  // Immunity & inflammation
  LabTestDefinition(
      'CRP', 'immunity', ['crp', 'c-reactive protein', 'c reactive protein']),
  LabTestDefinition('IgE', 'immunity', ['ige', 'total ige', 'serum ige']),
  LabTestDefinition('ANA', 'immunity', [
    'antinuclear antibodies',
    'antinuclear antibody',
    'anti nuclear antibody',
    'ana (ifa)'
  ]),
  LabTestDefinition(
      'RA factor', 'immunity', ['ra factor', 'rheumatoid factor']),
  LabTestDefinition(
      'ASO', 'immunity', ['aso titre', 'aso titer', 'anti streptolysin o']),
  LabTestDefinition('Procalcitonin', 'immunity', ['procalcitonin']),
  // Cancer markers
  LabTestDefinition(
      'PSA', 'cancer', ['psa', 'total psa', 'prostate specific antigen']),
  LabTestDefinition('Free PSA', 'cancer', ['free psa']),
  LabTestDefinition('CEA', 'cancer', ['cea', 'carcinoembryonic antigen']),
  LabTestDefinition('CA-125', 'cancer', ['ca-125', 'ca 125', 'ca125']),
  LabTestDefinition('CA 19-9', 'cancer', ['ca 19-9', 'ca19-9', 'ca 19.9']),
  LabTestDefinition('CA 15-3', 'cancer', ['ca 15-3', 'ca15-3']),
  LabTestDefinition(
      'AFP', 'cancer', ['afp', 'alpha fetoprotein', 'alpha-fetoprotein']),
  // Hormones
  LabTestDefinition(
      'Testosterone', 'hormones', ['testosterone', 'total testosterone']),
  LabTestDefinition('Estradiol', 'hormones', ['estradiol', 'oestradiol']),
  LabTestDefinition('Progesterone', 'hormones', ['progesterone']),
  LabTestDefinition('Cortisol', 'hormones', ['cortisol']),
  LabTestDefinition('Prolactin', 'hormones', ['prolactin']),
  LabTestDefinition('LH', 'hormones', ['lh', 'luteinizing hormone']),
  LabTestDefinition('FSH', 'hormones', ['fsh', 'follicle stimulating hormone']),
  LabTestDefinition('DHEA-S', 'hormones',
      ['dhea-s', 'dheas', 'dhea sulphate', 'dhea sulfate']),
  // Infections
  LabTestDefinition(
      'HBsAg', 'infections', ['hbsag', 'hepatitis b surface antigen']),
  LabTestDefinition(
      'Anti-HCV', 'infections', ['anti-hcv', 'anti hcv', 'hcv antibody']),
  LabTestDefinition('HIV I & II', 'infections',
      ['hiv i & ii', 'hiv 1 & 2', 'hiv 1 and 2', 'hiv']),
  LabTestDefinition('Dengue NS1', 'infections', ['dengue ns1', 'ns1 antigen']),
  LabTestDefinition(
      'Malaria', 'infections', ['malaria parasite', 'malaria antigen']),
  // Clotting
  LabTestDefinition('Prothrombin time', 'clotting',
      ['prothrombin time', 'pt (prothrombin time)']),
  LabTestDefinition('INR', 'clotting', ['inr']),
  LabTestDefinition(
      'aPTT', 'clotting', ['aptt', 'activated partial thromboplastin time']),
  LabTestDefinition('D-dimer', 'clotting', ['d-dimer', 'd dimer']),
  LabTestDefinition('Fibrinogen', 'clotting', ['fibrinogen']),
];

/// Section headings labs print above groups of tests. While a section is open,
/// ambiguous rows (e.g. "Albumin", "Glucose") and unknown tests take its
/// category.
const labSectionKeywords = <String, List<String>>{
  'blood': [
    'complete blood count',
    'haemogram',
    'hemogram',
    'cbc',
    'blood count'
  ],
  'glucose': ['diabetes', 'blood sugar', 'glucose', 'glycated'],
  'kidney': ['kidney function', 'renal function', 'kft', 'rft', 'electrolytes'],
  'liver': ['liver function', 'lft', 'hepatic function'],
  'lipid': ['lipid profile', 'lipid panel', 'lipid'],
  'thyroid': ['thyroid profile', 'thyroid function', 'thyroid'],
  'vitamins': ['vitamin'],
  'iron': ['iron studies', 'iron profile', 'anaemia profile', 'anemia profile'],
  'urine': [
    'urine routine',
    'urine examination',
    'urinalysis',
    'urine analysis',
    'urine'
  ],
  'heart': ['cardiac markers', 'cardiac risk', 'cardiac profile', 'cardiac'],
  'pancreas': ['pancreatic', 'pancreas'],
  'immunity': [
    'immunology',
    'inflammatory markers',
    'inflammation',
    'autoimmune'
  ],
  'cancer': ['tumor markers', 'tumour markers', 'cancer markers'],
  'hormones': ['hormone', 'fertility', 'reproductive'],
  'infections': ['serology', 'infectious disease', 'infection'],
  'clotting': ['coagulation', 'clotting'],
};

/// The unit most labs print for a test. Used only when OCR clearly saw a unit
/// but returned garbage for it (e.g. "mg/dL" read as Cyrillic "тр/бш").
const typicalUnits = <String, String>{
  'Hemoglobin': 'g/dL',
  'Hematocrit': '%',
  'MCV': 'fL',
  'MCH': 'pg',
  'MCHC': 'g/dL',
  'RDW': '%',
  'Neutrophils': '%',
  'Lymphocytes': '%',
  'Monocytes': '%',
  'Eosinophils': '%',
  'Basophils': '%',
  'ESR': 'mm/hr',
  'Fasting glucose': 'mg/dL',
  'Post-meal glucose': 'mg/dL',
  'Random glucose': 'mg/dL',
  'HbA1c': '%',
  'Average blood glucose': 'mg/dL',
  'Creatinine': 'mg/dL',
  'Urea': 'mg/dL',
  'BUN': 'mg/dL',
  'Uric acid': 'mg/dL',
  'eGFR': 'mL/min/1.73m2',
  'Sodium': 'mmol/L',
  'Potassium': 'mmol/L',
  'Chloride': 'mmol/L',
  'Calcium': 'mg/dL',
  'SGOT (AST)': 'U/L',
  'SGPT (ALT)': 'U/L',
  'Alkaline phosphatase': 'U/L',
  'GGT': 'U/L',
  'Total bilirubin': 'mg/dL',
  'Direct bilirubin': 'mg/dL',
  'Indirect bilirubin': 'mg/dL',
  'Total protein': 'g/dL',
  'Albumin': 'g/dL',
  'Globulin': 'g/dL',
  'Total cholesterol': 'mg/dL',
  'LDL cholesterol': 'mg/dL',
  'HDL cholesterol': 'mg/dL',
  'VLDL cholesterol': 'mg/dL',
  'Non-HDL cholesterol': 'mg/dL',
  'Triglycerides': 'mg/dL',
  'TSH': 'µIU/mL',
  'Free T3': 'pg/mL',
  'Free T4': 'ng/dL',
  'Total T3': 'ng/dL',
  'Total T4': 'µg/dL',
  'Vitamin D, 25-OH': 'ng/mL',
  'Vitamin B12': 'pg/mL',
  'Folate': 'ng/mL',
  'Serum iron': 'µg/dL',
  'Ferritin': 'ng/mL',
  'TIBC': 'µg/dL',
  'Transferrin saturation': '%',
};
