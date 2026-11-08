# Project 16: how to answer the reviewer

Manuscript: *Factors Associated with Disease Activity of SLE: Role of Medication Adherence,
Depression, and Fatigue* (`Manuscript/JOM-[2027]-final.docx`)
Review: `Manuscript/review.txt` (11 major concerns)
Data: `Data/SLE Case Master data.xlsm`
Evidence: `review_audit.py` → `doc/review_audit_log.txt` (every number below comes from it)

---

## 0. Read this first: settle two data problems before any reply

The client's data file **does not support the manuscript as written**. Sort these out with
the client before anyone drafts a response letter. Whatever goes in the letter has to be
something the source data can back up.

| # | Finding | Evidence |
|---|---|---|
| A | **There is no MMAS-8 or PHQ-9 data.** The file has no adherence score, no depression score and no "newly diagnosed" flag. Tables III–V and Figure I rest mainly on these two variables. | No such columns. The file instead has vitamin D, flare category, SLICC/ACR scores, C3/C4, 24-h urine protein, the damage index and MDHAQ RAPID3. |
| B | **Many reported figures do not match the file** (see table below). The ones that *do* match (SLEDAI 17.3 ± 13.3, range 1–47; FSS r = 0.429) show the manuscript was analysed from this file. | Section 3 and 6 of the log |

### Reported vs file

| Item | Manuscript | Data file |
|---|---|---|
| Age, mean ± SD | 27.3 ± 9.8 | 25.3 ± 9.8 |
| Female | 82% | 84% |
| Rural | 44% | 52% |
| BMI <18.5 / 18.5–24.9 / ≥25 | 29 / 61 / 10% | 2 / 76 / 22% |
| Disease duration | New 48, ≤12 m 22, 13–24 m 20, >24 m 10% | <6 m 68, 6–12 m 2, >1 y 30% |
| Haemoglobin | 11.0 ± 2.0 | 10.1 ± 2.3 |
| ESR | 39.1 ± 32.2 | 61.7 ± 30.1 |
| CRP | 8.1 ± 13.0 | 13.0 ± 17.6 (CRP missing in 10%); median 4.9 (IQR 3.1–16.3) |
| Anti-dsDNA positive | **100%** | **92%** |
| HCQ / steroid / CYC / MMF / AZA | 85 / 72 / 25 / 18 / 10% | 98 / 90 / 22 / 8 / 30% |
| SLEDAI low / moderate / high | 50 / 32 / 18% | none of the SLEDAI bandings gives this (see point 1) |
| r (SLEDAI, Hb) | −0.134 | **−0.362** |
| r (SLEDAI, CRP) | 0.088 | 0.105 |
| r (SLEDAI, FSS) | 0.429 | 0.429 ✓ |
| r (SLEDAI, MMAS-8 / PHQ-9) | −0.669 / 0.736 | **not in file** |

The clinical-feature percentages match closely: joint 90 vs 92%, PUO 76 = 76, ulcers 68 = 68,
renal 46 = 46.

The file's other columns (vitamin D, flare, SLICC, damage index, RAPID3) and a pivot table
of *"Average of Vitamin D Level by Flare"* suggest the source is a postgraduate thesis with a
different primary question. The reviewer already suspects this (point 10).

### What to send the client now

1. Item-level MMAS-8 (8 items) and PHQ-9 (9 items) responses for every patient, and the
   original case-record forms they came from.
2. The exact diagnosis date and first-prescription date for each patient, to define
   "newly diagnosed" and time on treatment.
3. Where Table I (BMI, duration), Table II (Hb, ESR, CRP, anti-dsDNA 100%) and the Table III
   treatment percentages came from, since they are not in this file.
4. The thesis title, the degree, whether it has been published, and who collected the data.
5. Answers only the investigators can give: points 4 (who scored), 9 (Bangla versions,
   MMAS-8 licence) and 10 (ethics amendment, assent).

### Decision after the client replies

* **If complete source data with MMAS-8/PHQ-9 exist:** re-run everything
  from that data (cleaning log, new Tables I–V) and answer point by point as below.
* **If MMAS-8/PHQ-9 data cannot be produced:** this paper cannot be revised. The honest
  route is to withdraw it. A different paper on what was actually measured (fatigue, vitamin
  D, flare and disease activity) could go in as a new submission, with the
  thesis disclosed.

Do not write a response that defends the adherence or depression results until the source data are in hand. The reviewer has explicitly raised fabrication or
transcription error with the editor.

---

## 1. Point-by-point guide

Each point gives the **verdict** (is the reviewer right?), **what the data show**, and
**what the reply should say or do**.

### 1. SLEDAI-2K categories cannot give the reported mean

**Verdict: the reviewer is right, and the error is worse than they think.**

* Mean 17.3 ± 13.3 (range 1–47) is correct. Median **17 (IQR 5–25)**. The score is skewed
  and not normally distributed (Shapiro-Wilk).
* With conventional bands, the file gives: mild 1–5 **28%**, moderate 6–10 **12%**,
  high 11–19 **18%**, very high ≥20 **42%**. Nothing near 50 / 32 / 18.
* 50 / 32 / 18 is exactly the **MDHAQ RAPID3 physical-function severity** column
  (High 50%, Moderate 32%, Low 18%), with the labels reversed. Table III printed the wrong
  variable.

**Reply:** Thank the reviewer and admit the error. Replace the category rows with
SLEDAI-2K bands: 0 / 1–5 / 6–10 / 11–19 / ≥20 (cite Polachek 2017 or Mosca 2011), with the
cut-offs stated in Methods. Add median (IQR) and a histogram as a supplementary figure.

### 2. 100% anti-dsDNA positive contradicts a minimum SLEDAI of 1

**Verdict: right.**

* The file shows **92%** anti-dsDNA positive, not 100%.
* Every patient with SLEDAI = 1 is recorded as anti-dsDNA positive. In **34%** of
  patients, the recorded SLEDAI is lower than the points implied by their own recorded
  descriptors (current arthritis, dsDNA, low complement, proteinuria >0.5 g). Example: SL 10
  has SLEDAI = 1 but current joint disease, dsDNA+, low C3/C4 and proteinuria >0.5 g/day
  (implied ≥12).
* The antibody column has no date, and the ACR/SLICC columns are explicitly "at diagnosis".
  Most likely the serology is historical (from diagnosis), and the SLEDAI either left out
  the immunological items or was scored at a different time point.

**Reply:** Correct the figure to 92%. State plainly when the serology was measured. If it
was at diagnosis, say so, and explain that SLEDAI-2K at the study visit used the serology
available within the 10-day window, or left it out. The client must confirm which. If the
17 inconsistent scores cannot be reconciled from the case-record forms, SLEDAI has to be
re-scored from source records. Do not defend the current scores.

### 3. Serology is implausible

**Verdict: partly answered by correcting the data.**

* The true figures are ANA+ 96%, anti-dsDNA+ 92%, **ANA−/dsDNA+ 4%** and
  ANA+/dsDNA− 8%.
* dsDNA-negative patients (8%) were enrolled, so anti-dsDNA was **not** an entry
  requirement. That answers the selection-bias option.
* 92% is still high. It plausibly reflects a tertiary, mostly inpatient, recently diagnosed
  cohort (68% diagnosed <6 months ago) and "ever-positive" recording. Say so as a
  limitation.

**Reply:** Delete the paragraph listing three commercial ELISA thresholds and the sentence
that the assay "could not be independently verified". Replace them with the actual
laboratory, method and cut-off, which the client must obtain. If they truly cannot obtain
them, state that as a limitation in one honest sentence. The editor's question "who holds
the source data" needs a direct answer: name the custodian and offer to provide the data.

### 4. SLEDAI scored without complement or urine data; who scored?

**Verdict: partly wrong, because the file does contain these.**

* C3 and C4 were recorded (C3 low in 54%, normal 22%, not done 22%), as was 24-h urine
  protein (available in 92%, >0.5 g in 52%). WBC and platelets are also present.
* **Not** in the file: urine microscopy (casts, haematuria, pyuria), vasculitis, visual and
  cranial-nerve items, headache, myositis, pericarditis.

**Reply:** Add a supplementary table listing all 24 SLEDAI-2K descriptors, the source of
each (examination, labs, or not available) and how many patients scored each one. Report
C3/C4 and proteinuria in Table II. State that urinary sediment was unavailable, so the renal
items may be under-scored. Name who scored (the client must answer), and say whether the
scorer was blinded to the questionnaires. If not, list it as a limitation.

### 5. Adherence confounded by newly diagnosed patients

**Verdict: right. Cannot be addressed from the current file.**

* There is no MMAS-8 data and no new-diagnosis flag. The duration column (<6 m 68%,
  6–12 m 2%, >1 y 30%) contradicts Table I (48% "newly diagnosed").
* Patients diagnosed <6 months ago have higher SLEDAI than those >1 year (mean 19.5 vs
  12.6). That is exactly the confounding the reviewer describes.

**Reply, once the MMAS-8 data are supplied:**
* A cross-tab of adherence category by new or established diagnosis.
* The model restricted to established disease.
* The full model with new-diagnosis status plus an adherence × new-diagnosis interaction.
* On cyclophosphamide: state that MMAS-8 refers to self-administered oral medication, and
  that IV cyclophosphamide was excluded from the adherence assessment, if that is what was
  done. The client must confirm.
* If the newly diagnosed patients completed MMAS-8 within days of a first prescription,
  concede the point. Then either exclude them from the adherence analysis or drop the
  adherence claim for that group.

### 6. Unadjusted confounding, overlapping measures, diagnostics

**Verdict: right. Doable once the data are complete, but mind the sample size.**

* Keep the model parsimonious (roughly 10–15 observations per predictor). Adding every
  confounder on top of the current five predictors will over-fit.
* Covariates available in the file: age, sex, disease duration, steroid dose (none, low,
  high, high + IV methylprednisolone), renal involvement and NPSLE ever (seizure, psychosis,
  stroke: 12%).
* Hb is **not** null in the file. Pearson r = −0.36 and Spearman ρ = −0.38, against −0.134 in the manuscript. CRP is heavily skewed (skew 2.4), with
  median 4.9 (IQR 3.1–16.3) and 10% missing.

**Reply:**
* Justify or drop Hb and CRP. Pre-specify a small confounder set: age, sex, new diagnosis,
  steroid dose. Fit one model per exposure rather than putting everything in together.
* Report VIFs, R² and adjusted R², and residual-vs-fitted and Q–Q plots as a supplement.
* Use HC3 robust SEs or bootstrap CIs, and give Spearman correlations alongside Pearson.
* Summarise CRP as median (IQR) and log-transform it in models.
* For PHQ-9/FSS overlap: report the PHQ-9 vs FSS correlation, and re-run with PHQ-9 minus
  items 3, 4 and 5 (sleep, fatigue, appetite). This needs item-level PHQ-9 data.

### 7. Effect sizes are out of line with the literature

**Verdict: a fair challenge.**

* FSS r = 0.429 reproduces exactly. The MMAS-8 (−0.669) and PHQ-9 (0.736) values cannot be
  checked at all.

**Reply:** Rebut nothing until the PHQ-9 and MMAS-8 data are verified. If they are verified,
the Discussion should engage directly with:
* Liao 2022: AUC 0.66 at cut-off 8.5.
* Mertz 2022: fatigue tracks PGA, not SLEDAI.
* The Saudi adherence study (Lupus 2018;27:327–332).

Possible honest reasons for a stronger association: a hospitalised, recently diagnosed
cohort with a wide SLEDAI range (1–47), and an unblinded scorer. If, after correction, the
associations shrink, report the smaller values.

### 8. Missing descriptives; "43% severe" mislabel

**Verdict: right on both counts.**

* FSS: **5.50 ± 1.02; median 5.8 (IQR 5.0–6.1)**. MMAS-8 and PHQ-9 need the data.
* The text fix is mechanical: "43% had moderately severe or severe depressive symptoms
  (PHQ-9 ≥15), including 21% with severe symptoms (≥20)." Change it in the Abstract,
  Results and Discussion. Note this only fixes the wording; the PHQ-9 counts still need
  verifying.

**Reply:** Add mean ± SD and median (IQR) of all three scales to Table III, and make the
wording correction.

### 9. Questionnaire language, validation, MMAS-8 licence

**Verdict: administrative. Only the client can answer.**

**Reply:**
* Name the Bangla PHQ-9 version used and cite its validation. Check that the reviewer's
  citation (Naher et al., DUJBS 2021) is the version actually used.
* Name and cite the Bangla FSS and MMAS-8 versions. If they were translated in-house,
  describe the forward and back translation.
* MMAS-8 licence: state truthfully whether a licence was held, and leave the policy question
  to the editor. Don't argue the legal position in the response.

### 10. Ethics, consent, provenance

**Verdict: right on every sub-point. The client must supply documents.**

* Approval is dated Feb 2020 but data were collected in 2022: provide the amendment or
  extension letter, or explain.
* The memo "CMC/PG/…" and the file structure both point to a thesis. **Disclose it**, cite
  it, and state whether any part has been published.
* **20% of patients were aged 13–17.** State guardian consent plus assent, if they were
  obtained. Either add a sensitivity analysis excluding under-18s, or acknowledge that PHQ-9
  is not validated for adolescents (PHQ-A).
* Add an ICMJE CRediT contributorship statement, and name who collected the data at
  Chattogram. Explain the authors' link to the site.

### 11. ACR-1997 classification criteria

**Verdict: answerable in your favour.**

* The file records a SLICC-2012 score at diagnosis for every patient: **range 6–13, so every
  patient meets SLICC-2012 (≥4)**. ACR-1997 scores range 4–9.
* For EULAR/ACR-2019, the 4% who are ANA-negative would fail its entry criterion.

**Reply:** "All patients also fulfilled the SLICC-2012 classification criteria (recorded
score 6–13). ACR-1997 was the inclusion standard specified in the approved protocol." Add
SLICC-2012 to Methods. Acknowledge EULAR/ACR-2019 was not applied, and that ANA-negative
patients (4%) would not meet its entry criterion.

---

## 2. Summary

| Point | Reviewer right? | Answerable from current file? |
|---|---|---|
| 1 SLEDAI categories | Yes (wrong variable printed) | **Yes**: corrected bands, median, histogram |
| 2 dsDNA vs SLEDAI | Yes | Partly: corrected to 92%; scoring needs client |
| 3 Serology | Partly | Partly: 92%, not an entry criterion; assay needs client |
| 4 Complement and urine | Partly | **Yes** for C3/C4/UTP; scorer and blinding need client |
| 5 New diagnosis vs adherence | Yes | **No**: needs MMAS-8 and diagnosis dates |
| 6 Confounding and diagnostics | Yes | Partly: covariates exist; needs MMAS-8/PHQ-9 |
| 7 Effect sizes | Fair challenge | FSS yes; MMAS-8/PHQ-9 no |
| 8 Descriptives and "43% severe" | Yes | FSS yes; wording fix yes; MMAS-8/PHQ-9 no |
| 9 Questionnaires and licence | n/a | Client only |
| 10 Ethics and thesis | Yes | Client only (20% aged 13–17) |
| 11 Criteria | Answerable | **Yes**: all meet SLICC-2012 |
