// Project 16 -- builds Manuscript/Response_to_Reviewer.docx (docx npm package).
// Run from the project folder: node make_response_letter.js Manuscript/Response_to_Reviewer.docx Graph/SLEDAI_histogram.png
// Markup in strings: **bold**, [[placeholder for authors]] (bold, yellow shading).
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType,
  ShadingType, AlignmentType, BorderStyle, LevelFormat, Footer, PageNumber, ImageRun,
} = require("docx");

const OUT = process.argv[2];
const HIST = process.argv[3];
const FONT = "Times New Roman";
const PAGE_W = 11906, MARGIN = 1300, TW = PAGE_W - 2 * MARGIN; // A4

function runs(text, base = {}) {
  const out = [];
  const re = /(\*\*[^*]+\*\*|\[\[[^\]]+\]\])/g;
  let last = 0, m;
  while ((m = re.exec(text))) {
    if (m.index > last) out.push(new TextRun({ text: text.slice(last, m.index), font: FONT, ...base }));
    const t = m[0];
    if (t.startsWith("**")) out.push(new TextRun({ text: t.slice(2, -2), bold: true, font: FONT, ...base }));
    else out.push(new TextRun({ text: "[" + t.slice(2, -2) + "]", bold: true, shading: { type: ShadingType.CLEAR, fill: "FFF200", color: "auto" }, font: FONT, ...base }));
    last = m.index + t.length;
  }
  if (last < text.length) out.push(new TextRun({ text: text.slice(last), font: FONT, ...base }));
  return out;
}
const P = (t, o = {}) => new Paragraph({ children: runs(t, o.run || {}), spacing: { after: 120, line: 276 }, alignment: o.align || AlignmentType.JUSTIFIED, indent: o.indent });
const B = (t) => new Paragraph({ children: runs(t), numbering: { reference: "bul", level: 0 }, spacing: { after: 60, line: 276 } });
const H1 = (t) => new Paragraph({ heading: "Heading1", children: [new TextRun({ text: t, font: FONT })] });
const H2 = (t) => new Paragraph({ heading: "Heading2", children: [new TextRun({ text: t, font: FONT })] });
const LABEL = (t) => new Paragraph({ children: [new TextRun({ text: t, bold: true, font: FONT, size: 22 })], spacing: { before: 120, after: 60 }, keepNext: true });
const QUOTE = (t) => new Paragraph({
  children: runs(t, { italics: true, size: 21 }), spacing: { after: 120, line: 264 },
  indent: { left: 360 }, border: { left: { style: BorderStyle.SINGLE, size: 12, color: "0072B2", space: 8 } },
  alignment: AlignmentType.JUSTIFIED,
});
const CAPTION = (t) => new Paragraph({ children: runs(t, { bold: true, size: 20 }), spacing: { before: 120, after: 60 }, keepNext: true });
const NOTE = (t) => new Paragraph({ children: runs(t, { size: 18 }), spacing: { after: 160 } });

const border = { style: BorderStyle.SINGLE, size: 4, color: "BFBFBF" };
const borders = { top: border, bottom: border, left: border, right: border };
function table(widthsPct, header, rows) {
  const widths = widthsPct.map((p) => Math.round((TW * p) / 100));
  widths[widths.length - 1] = TW - widths.slice(0, -1).reduce((a, b) => a + b, 0);
  const cell = (t, i, head) => new TableCell({
    borders, width: { size: widths[i], type: WidthType.DXA },
    shading: head ? { fill: "DCE9F3", type: ShadingType.CLEAR, color: "auto" } : undefined,
    margins: { top: 50, bottom: 50, left: 90, right: 90 },
    children: [new Paragraph({ children: runs(String(t), { size: 19, bold: !!head }), alignment: i === 0 ? AlignmentType.LEFT : AlignmentType.CENTER })],
  });
  return new Table({
    width: { size: TW, type: WidthType.DXA }, columnWidths: widths,
    rows: [
      new TableRow({ tableHeader: true, children: header.map((h, i) => cell(h, i, true)) }),
      ...rows.map((r) => new TableRow({ cantSplit: true, children: r.map((c, i) => cell(c, i, false)) })),
    ],
  });
}

const body = [];
const add = (...x) => body.push(...x);

// ---------------------------------------------------------------- Opening
add(
  new Paragraph({ children: [new TextRun({ text: "Response to the Reviewer", bold: true, size: 32, font: FONT })], alignment: AlignmentType.CENTER, spacing: { after: 80 } }),
  new Paragraph({ children: runs("Manuscript: “Factors Associated with Disease Activity of Systemic Lupus Erythematosus: Role of Medication Adherence, Depression, and Fatigue”", { italics: true }), alignment: AlignmentType.CENTER, spacing: { after: 40 } }),
  new Paragraph({ children: runs("Manuscript ID: [[manuscript number]]"), alignment: AlignmentType.CENTER, spacing: { after: 280 } }),
  P("Dear Editor and Reviewer,"),
  P("We thank the reviewer for a careful and detailed assessment of our manuscript. The comments identified real errors, and we are grateful for the opportunity to correct them. In responding, we re-checked every reported value against the source data file, rather than only those the reviewer queried. This re-verification found several transcription errors in Tables I–IV, including the SLEDAI-2K activity categories, the anti-dsDNA positivity rate, the treatment frequencies and the laboratory summaries. All of these have been corrected, and the corrections are listed under each comment and in the summary table at the end of this letter."),
  P("The reviewer’s comments are reproduced in italics, followed by our response and the changes made to the manuscript. Changes in the revised manuscript are shown with tracked changes."),
);

// ---------------------------------------------------------------- 1
add(
  H1("Comment 1. SLEDAI-2K categories and the reported mean"),
  QUOTE("The SLEDAI-2K category counts cannot give the reported mean… The authors must state their cut-offs and provide the score distribution (median, IQR, histogram)."),
  LABEL("Response"),
  P("We thank the reviewer and agree entirely. The reviewer’s calculation is correct: the category frequencies printed in Table III (50% low, 32% moderate, 18% high) are incompatible with the mean score. On re-checking the source data, we found that these frequencies had been transcribed in error from a different variable in the data file, the RAPID3 physical-function severity category, and had been mislabelled as SLEDAI-2K activity categories. The continuous SLEDAI-2K summary (mean 17.3 ± 13.3, range 1–47) was correct."),
  P("We have replaced the categories with the commonly used SLEDAI-2K activity bands (no activity 0; mild 1–5; moderate 6–10; high 11–19; very high ≥20), stated these cut-offs in the Methods, and added the median, interquartile range and a histogram of the score distribution."),
  CAPTION("Table R1. Corrected SLEDAI-2K distribution (replaces the categorical rows in Table III)"),
  table([46, 27, 27], ["SLEDAI-2K", "Originally reported, %", "Corrected, %"], [
    ["Mean ± SD", "17.3 ± 13.3", "17.3 ± 13.3"],
    ["Median (IQR)", "Not reported", "17 (5–25)"],
    ["Range", "1–47", "1–47"],
    ["No activity (0)", "—", "0.0"],
    ["Mild (1–5)", "50.0 (“low”)", "28.0"],
    ["Moderate (6–10)", "32.0", "12.0"],
    ["High (11–19)", "18.0", "18.0"],
    ["Very high (≥20)", "—", "42.0"],
  ]),
  NOTE("SLEDAI-2K bands as in Polachek et al., Rheumatology 2017, and Mosca et al., Ann Rheum Dis 2011."),
  new Paragraph({ children: [new ImageRun({ type: "png", data: fs.readFileSync(HIST), transformation: { width: 480, height: 274 } })], alignment: AlignmentType.CENTER }),
  CAPTION("Figure R1 (new Supplementary Figure S1). Distribution of SLEDAI-2K scores. Dashed lines mark the band cut-offs; the solid line marks the median."),
  LABEL("Changes made"),
  B("Methods: SLEDAI-2K activity cut-offs stated, with references."),
  B("Table III: categorical SLEDAI-2K rows replaced (Table R1); median (IQR) added."),
  B("Supplementary Figure S1: histogram of SLEDAI-2K scores added."),
  B("Results and Abstract: wording on disease activity revised to match the corrected bands."),
);

// ---------------------------------------------------------------- 2
add(
  H1("Comment 2. Anti-dsDNA positivity and the minimum SLEDAI-2K score"),
  QUOTE("“100% anti-dsDNA positive” contradicts a minimum SLEDAI-2K of 1… either the antibody results are historical, or the SLEDAI scoring left out the immunological items."),
  LABEL("Response"),
  P("We agree. First, the 100% figure was a transcription error. The source data show anti-dsDNA positivity in **92.0%** of patients, and this has been corrected throughout (see also Comment 3)."),
  P("Second, the reviewer correctly identifies a timing issue. The serology in our case-record form records antibody status [[AUTHORS TO CONFIRM: at the time of diagnosis / at the study visit]]. [[AUTHORS TO CONFIRM which applies: (a) SLEDAI-2K was scored using only serological results obtained within 10 days of the study visit, so patients whose most recent anti-dsDNA or complement result fell outside this window received no points for these items; or (b) the immunological items were not scored, and SLEDAI-2K has been re-scored from the case-record forms with these items included.]] We have stated the timing of the serological tests explicitly in the Methods, and have added it to the limitations."),
  LABEL("Changes made"),
  B("Abstract, Results, Table II, Discussion: anti-dsDNA positivity corrected from 100% to 92.0%."),
  B("Methods: the timing of serological testing relative to the SLEDAI-2K assessment is stated."),
  B("Discussion (limitations): the timing of serology is acknowledged."),
);

// ---------------------------------------------------------------- 3
add(
  H1("Comment 3. Serology, ELISA paragraph and source data"),
  QUOTE("The serology itself is implausible… The Methods paragraph listing three commercial ELISA thresholds is irrelevant… The editor needs to know who holds the source data."),
  LABEL("Response"),
  P("We thank the reviewer. After correction, the serological profile is as shown in Table R2. Anti-dsDNA positivity was not an entry criterion: 8.0% of enrolled patients were anti-dsDNA negative. The corrected positivity of 92.0% remains above the 60–70% typically reported. We attribute this to the study setting, a tertiary referral centre where most patients had recently diagnosed, active disease (68.0% were diagnosed within the preceding six months), and to antibody status being recorded at diagnosis. We now discuss this explicitly as a potential source of selection bias."),
  CAPTION("Table R2. Corrected serological profile"),
  table([46, 27, 27], ["Serology", "Originally reported, %", "Corrected, %"], [
    ["ANA positive", "96.0", "96.0"],
    ["Anti-dsDNA positive", "100.0", "92.0"],
    ["ANA and anti-dsDNA positive", "—", "88.0"],
    ["ANA positive, anti-dsDNA negative", "—", "8.0"],
    ["ANA negative, anti-dsDNA positive", "4.0", "4.0"],
  ]),
  P("The small ANA-negative, anti-dsDNA-positive group (4.0%) is now discussed in the context of assay sensitivity, and we note that this discordance may reflect a false-positive ELISA result."),
  P("As requested, we have deleted the paragraph listing the commercial ELISA thresholds and the sentence stating that the assay could not be verified. The Methods now state: “ANA was tested by indirect immunofluorescence on HEp-2 cells [[titre cut-off, e.g. ≥1:80]] and anti-dsDNA by ELISA ([[manufacturer and kit name]]; positive ≥[[cut-off with units]]) at [[laboratory name]].”"),
  P("Source data: the original case-record forms and the study data file are held by [[name, position and institution of the data custodian]], and can be made available to the editor on request."),
  LABEL("Changes made"),
  B("Methods: ELISA-threshold paragraph and unverifiability sentence deleted; actual assay details added."),
  B("Table II and Results: serology corrected (Table R2)."),
  B("Discussion: selection bias and ANA/anti-dsDNA discordance discussed."),
);

// ---------------------------------------------------------------- 4
add(
  H1("Comment 4. Complement, urine data and the SLEDAI-2K assessor"),
  QUOTE("How was SLEDAI-2K scored without complement or urine data?… The authors should state how each of the 24 descriptors was determined… Who scored, and were they blinded to the questionnaires?"),
  LABEL("Response"),
  P("We thank the reviewer. Complement and 24-hour urine protein were measured but had been omitted from the manuscript. C3 was low in 54.0% of patients, normal in 22.0%, high in 2.0% and not done in 22.0%. C4 was low in 54.0%, normal in 18.0%, high in 2.0% and not done in 26.0%. The median 24-hour urine protein was 0.59 g (IQR 0.25–1.73), and it exceeded 0.5 g in 52.0% of patients. These values have been added to Table II."),
  P("Urine microscopy (casts, haematuria and pyuria) was not available. We have added a supplementary table (Table R3, new Supplementary Table S1) giving the source of each of the 24 SLEDAI-2K descriptors and its frequency at assessment. We acknowledge that the descriptors that could not be assessed, particularly the three urinary-sediment items, may have led to under-scoring of renal activity. This is now stated as a limitation."),
  CAPTION("Table R3 (new Supplementary Table S1). Source and frequency of SLEDAI-2K descriptors at assessment"),
  table([34, 10, 42, 14], ["Descriptor", "Weight", "Source", "Present, %"], [
    ["Seizure", "8", "Clinical examination", "10.0"],
    ["Psychosis", "8", "Clinical examination", "2.0"],
    ["Organic brain syndrome", "8", "Not assessed", "—"],
    ["Visual disturbance", "8", "Not assessed", "—"],
    ["Cranial nerve disorder", "8", "Not assessed", "—"],
    ["Lupus headache", "8", "Not assessed", "—"],
    ["Cerebrovascular accident", "8", "Clinical examination", "4.0"],
    ["Vasculitis", "8", "Not assessed", "—"],
    ["Arthritis", "4", "Clinical examination", "80.0"],
    ["Myositis", "4", "Not assessed", "—"],
    ["Urinary casts", "4", "Not available (no urine microscopy)", "—"],
    ["Haematuria", "4", "Not available (no urine microscopy)", "—"],
    ["Proteinuria >0.5 g/24 h", "4", "24-hour urine protein", "52.0"],
    ["Pyuria", "4", "Not available (no urine microscopy)", "—"],
    ["Rash", "2", "Clinical examination", "40.0"],
    ["Alopecia", "2", "Clinical examination", "20.0"],
    ["Mucosal ulcers", "2", "Clinical examination", "46.0"],
    ["Pleurisy", "2", "Clinical examination", "26.0"],
    ["Pericarditis", "2", "Not assessed", "—"],
    ["Low complement (C3 or C4)", "2", "Serum C3, C4", "64.0"],
    ["Increased DNA binding", "2", "Anti-dsDNA", "92.0"],
    ["Fever", "1", "Clinical examination", "58.0"],
    ["Thrombocytopenia (<100,000/mm³)", "1", "Platelet count", "16.0"],
    ["Leukopenia (<3,000/mm³)", "1", "White cell count", "0.0"],
  ]),
  NOTE("[[AUTHORS TO CONFIRM that “Not assessed” items were recorded as absent, and that the descriptor sources above match the case-record form.]]"),
  P("Assessor: the phrase “treating rheumatologist” was inaccurate and has been corrected. SLEDAI-2K was scored by [[name/role, e.g. “the first author, a postgraduate trainee in Internal Medicine, under the supervision of …”]] for patients from all three departments. The assessor [[was / was not]] blinded to the questionnaire scores. [[If not blinded:]] We acknowledge this as a potential source of information bias in the limitations."),
  LABEL("Changes made"),
  B("Table II: C3, C4 and 24-hour urine protein added."),
  B("Supplementary Table S1: SLEDAI-2K descriptor sources and frequencies."),
  B("Methods: identity of the assessor and blinding status stated."),
  B("Discussion (limitations): missing urinary-sediment items and assessor blinding discussed."),
);

// ---------------------------------------------------------------- 5
add(
  H1("Comment 5. Newly diagnosed patients and medication adherence"),
  QUOTE("The adherence finding is confounded by newly diagnosed patients… I request a cross-tabulation of adherence category by diagnosis status; the main analysis repeated in established-disease patients only, or with new-diagnosis status as a covariate (an interaction term would be better)… Did MMAS-8 cover [cyclophosphamide]?"),
  LABEL("Response"),
  P("We agree that this is an important concern. Disease activity was higher among patients diagnosed within the previous six months (median SLEDAI-2K 20, IQR 6.3–26.8) than among those with longer disease duration (median 9, IQR 3.5–20.5), although this difference was not statistically significant (Mann–Whitney p = 0.11). This pattern supports the reviewer’s point that untreated disease at presentation may drive the association with adherence."),
  P("We have performed the requested analyses: [[INSERT once the item-level MMAS-8 data and diagnosis/first-prescription dates are available: (i) cross-tabulation of MMAS-8 category by new versus established diagnosis; (ii) the adherence–SLEDAI-2K association restricted to patients with established disease; (iii) the full model with new-diagnosis status and an adherence × new-diagnosis interaction term. State the results, and whether the adherence association persists in established disease.]]"),
  P("[[If MMAS-8 was administered within days of a first prescription:]] We accept that MMAS-8 cannot meaningfully describe adherence in patients assessed shortly after their first prescription. We have therefore [[excluded newly diagnosed patients from the adherence analysis / restricted the adherence conclusions to patients with established disease]]."),
  P("Cyclophosphamide: MMAS-8 [[AUTHORS TO CONFIRM: referred only to self-administered oral SLE medications; intravenous cyclophosphamide, administered by hospital staff, was not included in the adherence assessment]]. This is now stated in the Methods."),
  LABEL("Changes made"),
  B("Results: new table cross-tabulating adherence by diagnosis status; sensitivity analysis in established disease. [[to be completed]]"),
  B("Methods: definition of “newly diagnosed” and the scope of MMAS-8 (oral medication only) stated."),
  B("Discussion: the reverse-causation and confounding issue is discussed."),
);

// ---------------------------------------------------------------- 6
add(
  H1("Comment 6. Confounding, overlapping measures and model diagnostics"),
  QUOTE("The model leaves out age, sex, disease duration, new-diagnosis status, prednisolone dose… Required additions: VIFs… R² and adjusted R²; residual diagnostics; Spearman correlations or a robust or transformed model."),
  LABEL("Response"),
  P("We thank the reviewer and have made all the requested additions. Because SLEDAI-2K and CRP are skewed, we now report Spearman correlations alongside Pearson coefficients (Table R4). CRP is summarised as a median (IQR) and log-transformed in the models. On re-analysis, we also found that the haemoglobin and CRP correlations in Table IV had been transcribed incorrectly. Haemoglobin is in fact moderately and inversely correlated with disease activity, consistent with anaemia of active disease. Table IV has been corrected."),
  CAPTION("Table R4. Correlations with SLEDAI-2K score (corrected Table IV, laboratory and fatigue rows)"),
  table([28, 18, 18, 18, 18], ["Variable", "Originally reported r", "Pearson r", "Spearman ρ", "p (Spearman)"], [
    ["Fatigue (FSS)", "0.429", "0.429", "0.412", "0.003"],
    ["Haemoglobin", "−0.134", "−0.362", "−0.378", "0.007"],
    ["CRP", "0.088", "0.105", "0.187", "0.220"],
    ["ESR", "—", "0.283", "0.366", "0.009"],
    ["MMAS-8", "−0.669", "[[to insert]]", "[[to insert]]", "[[to insert]]"],
    ["PHQ-9", "0.736", "[[to insert]]", "[[to insert]]", "[[to insert]]"],
  ]),
  NOTE("CRP: median 4.9 mg/L (IQR 3.1–16.3); missing in 10% of patients (test not done)."),
  P("We have refitted the regression with the confounders the reviewer listed: age, sex, recent diagnosis (<6 months) and high-dose prednisolone. Robust (HC3) standard errors are used because the Breusch–Pagan test indicated heteroscedasticity (p = 0.022). Table R5 shows the adjusted association for fatigue. Collinearity was negligible (all VIF ≤1.21), and the residuals were approximately normal (Shapiro–Wilk p = 0.21; residual and Q–Q plots in new Supplementary Figure S2). The model explained 25.0% of the variance in SLEDAI-2K (adjusted R² = 0.165)."),
  CAPTION("Table R5. Adjusted association of fatigue with SLEDAI-2K score"),
  table([34, 14, 24, 14, 14], ["Variable", "B", "95% CI (robust)", "p", "VIF"], [
    ["FSS score (per point)", "5.40", "2.24 to 8.56", "<0.001", "1.01"],
    ["Age, years", "0.01", "−0.33 to 0.36", "0.945", "1.11"],
    ["Female sex", "−1.63", "−10.43 to 7.17", "0.717", "1.04"],
    ["Diagnosed <6 months", "7.17", "−0.92 to 15.25", "0.082", "1.21"],
    ["High-dose prednisolone", "3.36", "−3.41 to 10.12", "0.331", "1.08"],
  ]),
  NOTE("Linear regression of SLEDAI-2K score; HC3 heteroscedasticity-consistent standard errors. R² = 0.250; adjusted R² = 0.165."),
  P("The full multivariable model (Table V) has been refitted with MMAS-8 and PHQ-9 added to these covariates, and its VIFs, R² and adjusted R² are reported. [[INSERT once MMAS-8 and PHQ-9 data are available: the refitted Table V with VIFs, R² and adjusted R². To limit over-fitting, keep about 10–15 observations per predictor; if needed, fit one model per exposure, each adjusted for the same confounder set.]] Haemoglobin and CRP were not pre-specified confounders with a clear causal rationale, and have been removed from the adjusted model. Their unadjusted correlations remain in Table IV."),
  P("Overlap between PHQ-9 and FSS: we agree that PHQ-9 items 3 (sleep), 4 (fatigue) and 5 (appetite) overlap with fatigue. [[INSERT: the correlation between PHQ-9 and FSS, and the model re-run using PHQ-9 without items 3–5 (somatic items removed), stating whether the depression association persists.]]"),
  LABEL("Changes made"),
  B("Table IV: Spearman coefficients added; haemoglobin and CRP rows corrected."),
  B("Table II: CRP reported as median (IQR)."),
  B("Table V: refitted with age, sex, recent diagnosis and steroid dose; VIF, R², adjusted R² and robust CIs reported. [[to be completed]]"),
  B("Supplementary Figure S2: residual diagnostics."),
  B("Supplementary analysis: PHQ-9 without somatic items. [[to be completed]]"),
);

// ---------------------------------------------------------------- 7
add(
  H1("Comment 7. Effect sizes relative to the literature"),
  QUOTE("The effect sizes are out of line with the literature… The Discussion has to address why these results are so much stronger."),
  LABEL("Response"),
  P("We thank the reviewer for these references, which are now discussed. Our fatigue finding (Pearson r = 0.429; Spearman ρ = 0.412) was unchanged after adjustment for age, sex, recent diagnosis and steroid dose (B = 5.40 per FSS point, 95% CI 2.24 to 8.56). It was also unchanged when adolescents were excluded (ρ = 0.404). We have added the following to the Discussion:"),
  P("“Unlike Mertz et al., who found that fatigue was associated with the Physician Global Assessment but not with the SELENA-SLEDAI [20], we observed a moderate association between fatigue and SLEDAI-2K. Our cohort was recruited from a tertiary hospital, most patients had recently diagnosed and highly active disease (42.0% with SLEDAI-2K ≥20), and the range of disease activity was wide (1–47). In such a population, inflammatory features that contribute both to fatigue and to SLEDAI-2K, such as fever and arthritis, are more prevalent, which may strengthen the association compared with predominantly outpatient cohorts with low disease activity.”", { indent: { left: 360, right: 360 } }),
  P("[[INSERT once PHQ-9 and MMAS-8 are verified: a comparable paragraph comparing the PHQ-9 association with Liao et al. 2022 (AUC 0.660, cut-off 8.5) and the adherence association with the Saudi outpatient study (Lupus 2018;27:327–332). If the re-analysis gives smaller coefficients, report and discuss those.]] We also note in the limitations that an unblinded SLEDAI-2K assessor could have inflated the associations with patient-reported measures."),
  LABEL("Changes made"),
  B("Discussion: comparison with Liao 2022, Mertz 2022 and the Saudi adherence study added; possible reasons for stronger associations discussed."),
);

// ---------------------------------------------------------------- 8
add(
  H1("Comment 8. Descriptive data and depression labelling"),
  QUOTE("Means and SDs of MMAS-8, PHQ-9 and FSS are not reported… severe (PHQ-9 ≥20) was 21%. The 43% is moderately severe plus severe."),
  LABEL("Response"),
  P("We agree with both points. The scale descriptives have been added to Table III (Table R6). The misstatement has been corrected in the Abstract, Results and Discussion to read: “43.0% had moderately severe or severe depressive symptoms (PHQ-9 ≥15), including 21.0% with severe symptoms (PHQ-9 ≥20).”"),
  CAPTION("Table R6. Scale scores (added to Table III)"),
  table([28, 24, 24, 24], ["Scale (range)", "Mean ± SD", "Median (IQR)", "Observed range"], [
    ["FSS (1–7)", "5.50 ± 1.02", "5.8 (5.0–6.1)", "2.9–7.0"],
    ["MMAS-8 (0–8)", "[[to insert]]", "[[to insert]]", "[[to insert]]"],
    ["PHQ-9 (0–27)", "[[to insert]]", "[[to insert]]", "[[to insert]]"],
  ]),
  LABEL("Changes made"),
  B("Table III: mean ± SD and median (IQR) of FSS, MMAS-8 and PHQ-9 added."),
  B("Abstract, Results, Discussion: “43% severe” corrected."),
);

// ---------------------------------------------------------------- 9
add(
  H1("Comment 9. Questionnaire language, validation and licensing"),
  QUOTE("PHQ-9: a validated Bangla version exists (Naher et al., DUJBS 2021)… FSS and MMAS-8: the authors must say which Bangla versions were used… MMAS-8 licence: the authors should state whether they held a licence."),
  LABEL("Response"),
  P("We thank the reviewer. The Methods now state the language version and validation source of each instrument."),
  B("PHQ-9: [[AUTHORS TO CONFIRM: the validated Bangla PHQ-9 (Naher et al., DUJBS 2021) was used, and is now cited / a different version was used: give its source]]."),
  B("FSS: [[source of the Bangla version and its validation; if translated by the study team, describe the forward–backward translation and pilot testing]]."),
  B("MMAS-8: [[source of the Bangla version and its validation, as above]]."),
  P("MMAS-8 licence: [[AUTHORS TO STATE TRUTHFULLY: “A licence for the MMAS-8 was obtained from … (licence no. …)” or “The authors did not hold a licence for the MMAS-8 at the time of the study.”]] We leave any decision on the journal’s policy to the editor."),
  LABEL("Changes made"),
  B("Methods: language version, validation reference and licensing status for each instrument."),
  B("References: Bangla PHQ-9 validation study added."),
);

// ---------------------------------------------------------------- 10
add(
  H1("Comment 10. Ethics, consent and provenance"),
  QUOTE("Ethical approval is dated February 2020, but data were collected in 2022… The memo number suggests a postgraduate thesis… Patients aged 13–17 need guardian consent plus assent… An ICMJE contributorship statement is needed."),
  LABEL("Response"),
  B("**Approval date:** [[AUTHORS TO CONFIRM: the protocol was approved in February 2020; data collection was delayed by the COVID-19 pandemic and took place in January–June 2022 under an extension or amendment dated … (memo no. …).]] The approval letter and extension are available to the editor."),
  B("**Thesis:** this study was conducted as part of the [[degree, e.g. FCPS/MD]] thesis of [[name]] at Chittagong Medical College ([[year]]), titled “[[thesis title]]”. This is now disclosed in the Methods and the cover letter. [[AUTHORS TO CONFIRM: no part of the thesis has been published elsewhere / list any related publication.]]"),
  B("**Adolescent participants:** 20.0% of participants were aged 13–17 years. [[AUTHORS TO CONFIRM: written informed consent was obtained from a parent or legal guardian, and assent from the participant.]] This is now stated in the Methods. We agree that PHQ-9 is not the adolescent-specific instrument (PHQ-A), and have added this as a limitation. In a sensitivity analysis restricted to adults, the fatigue association was unchanged (Spearman ρ = 0.404). [[INSERT the adult-only result for PHQ-9 once available.]]"),
  B("**Authorship and data collection:** an ICMJE/CRediT contributorship statement has been added. The data were collected at Chattogram Medical College Hospital by [[name(s)]], who [[was/were then a postgraduate trainee(s) at the hospital and is/are now at …]]. The phrase “according to the original study records” has been removed."),
  LABEL("Changes made"),
  B("Methods: ethics extension, thesis disclosure, guardian consent and assent."),
  B("Contributorship statement added."),
  B("Discussion (limitations): PHQ-9 use in adolescents."),
);

// ---------------------------------------------------------------- 11
add(
  H1("Comment 11. Classification criteria"),
  QUOTE("Using ACR 1997 in 2022 needs justification, since SLICC-2012 and EULAR/ACR-2019 were available."),
  LABEL("Response"),
  P("We thank the reviewer. ACR-1997 was specified in the protocol approved in 2020. However, SLICC-2012 scores were also recorded at diagnosis for every patient, and **all patients fulfilled the SLICC-2012 classification criteria** (recorded score 6–13; ≥4 required). We have added this to the Methods. EULAR/ACR-2019 criteria were not applied. We note that 4.0% of patients were ANA-negative and would not meet its ANA entry criterion, and we have added this as a limitation."),
  P("Revised Methods text: “Patients fulfilling the revised 1997 ACR classification criteria were eligible [12]. All enrolled patients also fulfilled the 2012 SLICC classification criteria (recorded score range 6–13) [new ref.].”", { indent: { left: 360, right: 360 } }),
  LABEL("Changes made"),
  B("Methods: SLICC-2012 fulfilment stated, with reference (Petri et al., Arthritis Rheum 2012)."),
  B("Discussion (limitations): EULAR/ACR-2019 not applied."),
);

// ---------------------------------------------------------------- Summary of corrections
add(
  H1("Summary of additional corrections to Tables I–III"),
  P("Re-verifying the manuscript against the source data identified the following transcription errors in addition to those raised by the reviewer. All have been corrected."),
  table([46, 27, 27], ["Item", "Originally reported", "Corrected"], [
    ["Age, years, mean ± SD", "27.3 ± 9.8", "25.3 ± 9.8"],
    ["Female, %", "82.0", "84.0"],
    ["Rural / urban residence, %", "44.0 / 56.0", "52.0 / 48.0"],
    ["BMI <18.5 / 18.5–24.9 / 25–29.9 / ≥30, %", "29.0 / 61.0 / 10.0 (≥25)", "2.0 / 76.0 / 18.0 / 4.0"],
    ["Disease duration <6 m / 6–12 m / >12 m, %", "48.0 new / 22.0 / 30.0", "68.0 / 2.0 / 30.0"],
    ["Joint disease / anaemia / skin rash (ever), %", "92.0 / 64.0 / 52.0", "90.0 / 62.0 / 54.0"],
    ["Haemoglobin, g/dL", "11.0 ± 2.0", "10.1 ± 2.3"],
    ["ESR, mm/h", "39.1 ± 32.2", "61.7 ± 30.1"],
    ["CRP, mg/L", "8.1 ± 13.0", "median 4.9 (IQR 3.1–16.3)"],
    ["Anti-dsDNA positive, %", "100.0", "92.0"],
    ["Hydroxychloroquine, %", "85.0", "98.0"],
    ["Any glucocorticoid, %", "72.0", "90.0 (high-dose 70.0; IV methylprednisolone 18.0)"],
    ["Cyclophosphamide / MMF / azathioprine, %", "25.0 / 18.0 / 10.0", "22.0 / 8.0 / 30.0"],
    ["SLEDAI-2K categories", "50.0 / 32.0 / 18.0", "See Table R1"],
    ["r (SLEDAI-2K, haemoglobin)", "−0.134", "−0.362"],
    ["r (SLEDAI-2K, CRP)", "0.088", "0.105"],
  ]),
  P(""),
  P("We hope that the revised manuscript addresses the reviewer’s concerns. We thank the reviewer again for comments that have substantially improved its accuracy."),
  P("Yours sincerely,", { align: AlignmentType.LEFT }),
  P("[[Corresponding author name]], on behalf of all authors", { align: AlignmentType.LEFT }),
);

const doc = new Document({
  creator: "Project 16",
  title: "Response to Reviewer",
  styles: {
    default: { document: { run: { font: FONT, size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { font: FONT, size: 25, bold: true, color: "1F3864" },
        paragraph: { spacing: { before: 300, after: 100 }, keepNext: true, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { font: FONT, size: 23, bold: true },
        paragraph: { spacing: { before: 200, after: 80 }, keepNext: true, outlineLevel: 1 } },
    ],
  },
  numbering: { config: [{ reference: "bul", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] }] },
  sections: [{
    properties: { page: { size: { width: PAGE_W, height: 16838 }, margin: { top: 1300, bottom: 1300, left: MARGIN, right: MARGIN } } },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 18 })] })] }) },
    children: body,
  }],
});
Packer.toBuffer(doc).then((buf) => { fs.writeFileSync(OUT, buf); console.log("wrote", OUT); });
