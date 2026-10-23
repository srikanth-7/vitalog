# Built-in reference ranges (edition 2026-10)

Status: **in the app** as compiled constants
(`lib/features/family_health/domain/reference/reference_table.dart`).
**Needs clinical review before public release.**

## Tamper protection

- Ranges are `const` Dart data inside the signed app binary — iOS/Android
  refuse modified apps, so a range can only change via a signed app update.
  Not encrypted on purpose: the ranges are public medical facts; the risk is
  *alteration*, which encryption with an on-device key would not prevent.
- The lookup map is read-only at runtime (tested).
- Future API updates: `data/reference/signed_range_table.dart` accepts a
  table only if it carries a valid **Ed25519 signature** from the server's
  private key, matches `rangeSigningPublicKey`, and is a **newer edition**
  (no downgrades). Otherwise the built-in table stays. The shipped public key
  is empty → updates disabled until you generate a key pair:
  `dart run` a one-off script with `Ed25519().newKeyPair()`; keep the private
  key in your server's secret store; paste the 32 public-key bytes into the
  app.
- Users' own results are AES-256-GCM encrypted (any edit to the file is
  rejected on load).

## Behaviour

- Printed lab range always wins. Built-in range used only when none is
  printed; then the status is labelled "… · usual range" and the source is
  shown on the test screen.
- Not applied (left "Needs review"): unknown sex for sex-specific tests,
  children for adult-only tests, missing/unknown units, unfiled tests.
- A notable difference between the printed and usual range shows a hint;
  the lab's range still decides.
- Assay/cycle/time-dependent tests have no built-in range (see table file).

How the app will use these:
1. **The range printed on the lab report always wins.** Labs calibrate ranges
   to their own analyser, method and population.
2. These built-in ranges are used only when a report prints **no** range, and
   as a **cross-check** ("your lab's range differs from the usual one").
3. Ranges are **adult** unless marked. Children (e.g. an 8-year-old) differ for
   haemoglobin, ALP, creatinine and more — pediatric tables are a follow-up.
4. Values are converted to the row's unit before comparing (table at the end).
5. Results are labelled "within / below / above the usual range" — never a
   diagnosis.

Legend for **Basis**: **G** = defined by a clinical guideline (fixed
cut-offs) · **R** = standard adult reference interval (varies a little by lab).

## Blood & CBC (`blood`)

| Test | Unit | Male | Female | Basis | Notes |
|---|---|---|---|---|---|
| Hemoglobin | g/dL | 13.5–17.5 | 12.0–15.5 | R | Child 6–12 y ≈ 11.5–15.5 |
| Hematocrit (PCV) | % | 40–54 | 36–48 | R | NIH StatPearls |
| RBC count | million/µL | 4.5–5.9 | 4.1–5.1 | R | |
| WBC count (TLC) | ×10³/µL | 4.5–11.0 | 4.5–11.0 | R | some labs 4.0–10.0 |
| Platelet count | ×10³/µL | 150–450 | 150–450 | R | Indian reports: 1.5–4.5 lakh/cumm |
| MCV | fL | 80–100 | 80–100 | R | |
| MCH | pg | 27–33 | 27–33 | R | |
| MCHC | g/dL | 32–36 | 32–36 | R | |
| RDW-CV | % | 11.5–14.5 | 11.5–14.5 | R | |
| Neutrophils | % | 40–70 | 40–70 | R | |
| Lymphocytes | % | 20–40 | 20–40 | R | |
| Monocytes | % | 2–8 | 2–8 | R | |
| Eosinophils | % | 1–4 | 1–4 | R | |
| Basophils | % | 0–1 | 0–1 | R | |
| ESR (Westergren) | mm/hr | 0–15 | 0–20 | R | rises with age |

## Glucose (`glucose`) — ADA Standards of Care

| Test | Unit | Normal | Prediabetes | Diabetes range | Basis |
|---|---|---|---|---|---|
| Fasting glucose | mg/dL | 70–99 | 100–125 | ≥126 | G |
| Post-meal (2-h) glucose | mg/dL | <140 | 140–199 | ≥200 | G (OGTT) |
| Random glucose | mg/dL | <140 | — | ≥200 (+symptoms) | G |
| HbA1c | % | <5.7 | 5.7–6.4 | ≥6.5 | G |
| Estimated average glucose | mg/dL | <117 | 117–137 | ≥140 | derived: 28.7 × A1c − 46.7 |

Below 70 mg/dL fasting is **low** (hypoglycaemia range).

## Kidney & electrolytes (`kidney`)

| Test | Unit | Male | Female | Basis | Notes |
|---|---|---|---|---|---|
| Creatinine | mg/dL | 0.7–1.3 | 0.6–1.1 | R | |
| Urea (blood urea) | mg/dL | 15–40 | 15–40 | R | Urea = BUN × 2.14 |
| BUN | mg/dL | 7–20 | 7–20 | R | |
| Uric acid | mg/dL | 3.4–7.0 | 2.4–6.0 | R | |
| eGFR | mL/min/1.73m² | ≥90 | ≥90 | G (KDIGO) | 60–89 mildly ↓ · 45–59 G3a · 30–44 G3b · 15–29 G4 · <15 G5 |
| Sodium | mmol/L | 135–145 | 135–145 | R | |
| Potassium | mmol/L | 3.5–5.1 | 3.5–5.1 | R | |
| Chloride | mmol/L | 98–107 | 98–107 | R | |
| Calcium (total) | mg/dL | 8.5–10.5 | 8.5–10.5 | R | |

## Liver (`liver`)

| Test | Unit | Adult range | Basis | Notes |
|---|---|---|---|---|
| SGOT (AST) | U/L | 8–48 | R | |
| SGPT (ALT) | U/L | 7–55 | R | |
| Alkaline phosphatase | U/L | 45–115 | R | much higher in growing children |
| GGT | U/L | 9–48 | R | |
| Total bilirubin | mg/dL | 0.1–1.2 | R | |
| Direct bilirubin | mg/dL | 0.0–0.3 | R | |
| Indirect bilirubin | mg/dL | 0.2–0.8 | R | |
| Total protein | g/dL | 6.3–7.9 | R | |
| Albumin | g/dL | 3.5–5.0 | R | |
| Globulin | g/dL | 2.0–3.5 | R | |
| A/G ratio | ratio | 1.0–2.2 | R | |

## Lipid profile (`lipid`) — NCEP ATP III

| Test | Unit | Desirable | Borderline | High | Basis |
|---|---|---|---|---|---|
| Total cholesterol | mg/dL | <200 | 200–239 | ≥240 | G |
| LDL cholesterol | mg/dL | <100 (optimal) | 100–129 near-optimal · 130–159 borderline | 160–189 high · ≥190 very high | G |
| HDL cholesterol | mg/dL | ≥60 protective | 40–59 (M) / 50–59 (F) | **low** <40 (M) / <50 (F) | G |
| Triglycerides | mg/dL | <150 | 150–199 | 200–499 · ≥500 very high | G |
| VLDL | mg/dL | 2–30 | — | >30 | R |
| Non-HDL cholesterol | mg/dL | <130 | 130–159 | ≥160 | G (ATP III secondary target) |
| Total chol / HDL ratio | ratio | <5.0 (ideal <3.5) | — | ≥5.0 | R |
| LDL / HDL ratio | ratio | <3.5 | — | ≥3.5 | R |

## Thyroid (`thyroid`) — assay-dependent; lab range strongly preferred

| Test | Unit | Adult range | Basis |
|---|---|---|---|
| TSH | mIU/L (= µIU/mL) | 0.4–4.0 | R |
| Free T4 | ng/dL | 0.8–1.8 | R |
| Free T3 | pg/mL | 2.3–4.2 | R |
| Total T4 | µg/dL | 5.0–12.0 | R |
| Total T3 | ng/dL | 80–200 | R |

## Vitamins (`vitamins`)

**Vitamin D, 25-OH (ng/mL)** — two conventions exist; pick one (see question):

| Category | NIH / IOM | Endocrine Society (used by most Indian labs) |
|---|---|---|
| Deficient | <12 | <20 |
| Inadequate / insufficient | 12–19 | 20–29 |
| Adequate / sufficient | 20–50 | 30–100 |
| Possibly too high | >50 | >100 |

Example: **Vitamin D = 7 ng/mL → "below range — deficient" under both.**

| Test | Unit | Range | Basis | Notes |
|---|---|---|---|---|
| Vitamin B12 | pg/mL | 200–900 | R | <200 deficient · 200–300 borderline |
| Folate (serum) | ng/mL | 4–20 | R | <3 deficient |

## Iron (`iron`)

| Test | Unit | Male | Female | Basis | Notes |
|---|---|---|---|---|---|
| Serum iron | µg/dL | 65–175 | 50–170 | R | |
| Ferritin | ng/mL | 30–300 | 15–150 | R | rises with inflammation; <30 suggests low iron stores |
| TIBC | µg/dL | 240–450 | 240–450 | R | |
| Transferrin saturation | % | 20–50 | 20–50 | R | iron ÷ TIBC × 100 |

## Urine routine (`urine`)

| Test | Expected | Basis |
|---|---|---|
| Urine pH | 4.5–8.0 | R |
| Specific gravity | 1.005–1.030 | R |
| Urine protein / albumin | Nil / Negative | R |
| Urine glucose | Nil / Negative | R |
| Ketones | Negative | R |
| Pus cells (WBC) | 0–5 /hpf | R |
| Urine RBC | 0–2 /hpf | R |
| Epithelial cells | 0–5 /hpf | R |

## Source comparison — WHO vs India vs US/international

Where sources disagree, the **Default** column is what the app would use when
a report prints no range (pending your approval).

| Test | WHO | India | US / international | Default |
|---|---|---|---|---|
| Hemoglobin — low (anaemia) | Men <13.0 · non-pregnant women <12.0 · children 5–11 y <11.5 · 12–14 y <12.0 · 6–59 mo <11.0 · pregnancy <11.0 g/dL (2024 guideline kept adult cut-offs) | Indian labs mostly print 13–17 (M) / 12–15 (F) g/dL; Chennai reference study found sex differences close to these | 13.5–17.5 (M) / 12.0–15.5 (F) g/dL | Low = **WHO** cut-offs by age/sex; high = US upper limit |
| Platelets | — | North-India donor study: healthy Indians run **lower** than 150–450; labs still print 1.5–4.5 lakh/cumm | 150–450 ×10³/µL | 150–450 (flag 100–150 gently as "slightly low") |
| Fasting glucose | Normal <110 (6.1 mmol/L) · IFG 110–125 · diabetes ≥126 (7.0) | **RSSDI-ESI 2020 = ADA**: <100 · 100–125 · ≥126 | ADA <100 · 100–125 · ≥126 | **RSSDI/ADA** (WHO's 110 noted) |
| HbA1c | Diabetes ≥6.5% (accepted 2011) | RSSDI: <5.7 · 5.7–6.4 · ≥6.5. Indian studies suggest 6.1–6.4% may suit Asian Indians; anaemia can distort A1c | ADA same | RSSDI/ADA |
| Ferritin — low | <15 µg/L adults (non-pregnant women) · <12 children (2020 guideline, unchanged) | Labs print ~13–150 (F) / 30–400 (M) | <30 commonly used clinically; ASH 2026 raised cut-offs | Low <15 (**WHO**) with "<30 may mean low stores" note |
| TSH | — | **2025 multicentre India study (5,812 adults): upper limit ≈4.3–4.6 (young) rising to ≈6.1–6.4 mIU/L at ≥60**; Delhi mean 2.2; older study 0.3–4.6 | 0.4–4.0 | **Age-adjusted Indian** upper limit (≤4.5 under 60, ≤6.2 at 60+) |
| Vitamin D | — | Indian labs/studies: <20 deficient · 20–29 insufficient · ≥30 sufficient; 2025 Indian expert consensus suggests keeping **40–60** | NIH/IOM <12 · 12–19 · 20–50 · >50 | **Indian lab convention** (<20 / 20–29 / 30–100) |
| LDL cholesterol | — | Lipid Association of India: **risk-based targets** — <100 low risk, <70 moderate/metabolic syndrome, <50 very high risk, ≤30 extreme (LAI 2016, 2024 update) | ATP III <100 optimal | ATP III bands for "usual range"; LAI targets need the user's risk level (future) |
| Non-HDL | — | LAI: co-primary target (= LDL target + 30) | ATP III <130 | <130 |

Takeaways: India mostly follows ADA for diabetes and the Endocrine Society
for vitamin D; WHO is the authority for anaemia and iron cut-offs; thyroid
upper limits are clearly **age-dependent** in Indians; lipid "normal" depends
on personal heart risk (LAI), which the app doesn't know yet.

## Unit conversions the app will apply before comparing

| Test | From → To | Multiply by |
|---|---|---|
| Glucose | mmol/L → mg/dL | 18.0 |
| Cholesterol (total/LDL/HDL) | mmol/L → mg/dL | 38.67 |
| Triglycerides | mmol/L → mg/dL | 88.57 |
| Creatinine | µmol/L → mg/dL | 0.0113 |
| Urea | mmol/L → mg/dL | 6.01 |
| Uric acid | µmol/L → mg/dL | 0.0168 |
| Vitamin D | nmol/L → ng/mL | 0.4 |
| Vitamin B12 | pmol/L → pg/mL | 1.355 |
| Hemoglobin | g/L → g/dL | 0.1 |
| Platelets | lakh/cumm → ×10³/µL | 100 |
| Bilirubin | µmol/L → mg/dL | 0.0585 |
| Calcium | mmol/L → mg/dL | 4.008 |

## Sources

- ADA diagnosis criteria (A1C, fasting, OGTT) — reproduced in
  [Johns Hopkins Diabetes Guide](https://www.hopkinsguides.com/hopkins/pview/Johns%20Hopkins%20Diabetes%20Guide/547125/all/Prediabetes%20or%20Categories%20of%20Increased%20Risk%20for%20Diabetes%C2%A0),
  [LabCE ADA criteria](https://labce.com/spg3921332_ada_guidelines_criteria_for_prediabetes_and_diabet.aspx)
- NCEP ATP III lipid classification —
  [Univ. of Iowa lipid page](https://www.healthcare.uiowa.edu/familymedicine/fpinfo/lipid_page.htm),
  [Medigraphic ATP III table](https://www.medigraphic.com/files/cardiovascuar/cms-2021/S3/cmss213i-T1.html)
- Vitamin D categories (IOM/NIH vs Endocrine Society) —
  [PMC4801816](https://pmc.ncbi.nlm.nih.gov/articles/PMC4801816/table/Tab2),
  [PMC8074587](https://pmc.ncbi.nlm.nih.gov/articles/PMC8074587/table/metabolites-11-00255-t004)
- KDIGO eGFR categories —
  [KDIGO summary (Health PEI)](https://src.healthpei.ca:443/sites/src.healthpei.ca/files/pdf/Summary_KDIGO_Guidelines_for_the_Management_and_Evaluation_of_CKD.pdf),
  [ebm.one](https://ebm.one/en/chapter-table/egfr-categories-ckd)
- CBC intervals — [NIH StatPearls NBK604207](https://ncbi.nlm.nih.gov/books/NBK604207),
  [AAMDS](https://www.aamds.org/node/2174),
  [CLL Society](https://cllsociety.org/toolbox/normal-lab-values/)
- Liver panel — [WikEM LFTs](https://wikem.org/wiki/Liver_function_tests)
- B12 / iron / ferritin — [PMC6054240 (Adv Nutr)](https://pmc.ncbi.nlm.nih.gov/articles/PMC6054240/table/tbl1),
  [Labcorp iron/TIBC](https://www.labcorp.com/tests/001321/iron-and-total-iron-binding-capacity-tibc),
  [Apollo Diagnostics B12](https://admin-drupal.apollohospitals.com/diagnostics-investigations/serum-vit-b12)
- Thyroid intervals are assay-dependent —
  [PMC7514062](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7514062/)
- WHO anaemia thresholds (2024 guideline) — [The Blood Project](https://www.thebloodproject.com/definition-of-anemia-hb-thresholds/),
  [Braat et al. 2024, PubMed 38432242](https://pubmed.ncbi.nlm.nih.gov/38432242/),
  [Indian Pediatrics 2024](https://indianpediatrics.net/july2024/671.pdf)
- WHO diabetes criteria — [MSD Manual table](https://msdmanuals.com/professional/multimedia/table/diagnostic-criteria-for-diabetes-mellitus-and-impaired-glucose-regulation),
  [PMC7468655](https://pmc.ncbi.nlm.nih.gov/articles/PMC7468655/table/tab1)
- WHO ferritin (2020) — [NCBI Bookshelf NBK569877](https://www.ncbi.nlm.nih.gov/books/NBK569877/),
  [The Blood Project](https://www.thebloodproject.com/cases-archive/the-abcs-of-ferritin/serum-ferritin-thresholds/)
- Indian TSH reference ranges — [PMC12744483 (2025, 5,812 adults)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12744483/),
  [Delhi study (IAS)](https://repository.ias.ac.in/106967),
  [Kerala study (DOAJ)](https://doaj.org/article/380e2a751aa94ad08ae7d7191e941a6a),
  [IJEM 2013](https://doaj.org/article/c3ed22d46ed645a08637064259728204)
- Indian haematology reference studies — [JCDR Chennai](https://jcdr.net/articles/PDF/2630/15- 4882_E(C)_PF1(M)_F(P)_PF1(PM)_PFA(PM)_OLF(P)_PF1(RP)_u.pdf),
  [Asian J Transfusion Sci 2022 (North India platelets)](https://doaj.org/article/87a59e6a664f46c981682e295726a3a0)
- Indian vitamin D — [CMC Vellore 2025 expert consensus](https://www.cmcendovellore.org/pub/2025/prevention-and-treatment-of-vitamin-d-deficiency-in-india-an-expert-group-consensus.pdf),
  [Metabolism Open 2024](https://doaj.org/article/2afa890961144730929247b05333c932),
  [Medanta study PMC4992490](https://pmc.ncbi.nlm.nih.gov/articles/PMC4992490)
- RSSDI-ESI diabetes recommendations & Indian HbA1c studies — [PMC7328526](https://pmc.ncbi.nlm.nih.gov/articles/PMC7328526),
  [PMC8948497](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8948497/)
- Lipid Association of India — [Medical Dialogues summary](https://speciality.medicaldialogues.in/lipid-association-of-india-issues-guidelines-on-management-of-dyslipidemia-in-indians),
  [LAI 2023 update](https://ohsu.elsevierpure.com/en/publications/lipid-association-of-india-2023-update-on-cardiovascular-risk-ass)
- Electrolytes, calcium, urea, uric acid, RBC, MCH/MCHC/RDW, differential,
  ESR, protein/globulin, folate, urine routine: standard adult reference
  intervals (Merck Manual / clinical chemistry texts). Merck, MedlinePlus,
  NIH ODS and Wikipedia block automated fetching from this environment, so
  these rows were not re-fetched live — **verify during clinical review.**
