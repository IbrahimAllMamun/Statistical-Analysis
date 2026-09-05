# Early Childhood Food Insecurity (EC-FIES) — Bangladesh
## Project brainstorm & analysis plan

**Student:** Md. Samsul Arefen Anni (MS 2023-24, INFS, University of Dhaka)
**Supervisor:** Dr. Md. Ruhul Amin
**Data:** `Data/MAIN.sav` — 407 mother–child pairs, 323 variables, KoBo/ODK export
**Prepared:** 2026-09-05

---

## 0. TL;DR — where the project actually stands

| Component | Status |
|---|---|
| Data collection | **Done.** 407 interviews (target 400), 8 divisions, 25 upazilas, GPS captured for 367 |
| EC-FIES scale | **Clean and strong.** α = 0.887, perfect severity gradient, 392/407 complete |
| Wealth index | **Already built** in SPSS (DHS-style PCA: `comscore`, `Ncombsco`, urban/rural splits) |
| IYCF indicators (MDD/MMF/MAD) | **Not yet built** — all input variables present, computable today |
| Thesis draft | **Skeleton only.** Ch. 1–2 written; Ch. 3 half-empty; Ch. 4 has 5 tables; Ch. 5–7 empty |
| Front matter | **Contaminated** — table/figure lists belong to a different thesis (see §2.1) |

The analysis is much closer to done than the draft suggests. The dataset is in good
shape and the headline results are already visible (§4). The bottleneck is writing,
not analysis.

---

## 1. What the study is, per the source documents

**Synopsis (NST Fellowship 2025-26):** *"Prevalence and predictors of food insecurity
among 6-23 month-old children in Bangladesh."* A **quantitative** cross-sectional rapid
assessment. 400 mothers, stratified multistage sampling of 25 upazilas across 8
divisions, convenience sampling of mothers at health congregation sites. Analysis in
SPSS 26.

**Questionnaire** (`Ben_IYCF_Data Collection Tool_Quant.pdf`, 19 pp., Bengali) — seven modules:

| Mod | Content | Feeds |
|---|---|---|
| A | Interview date, interviewer, GPS, division/district/upazila, congregation site, urban/rural | Sampling description, maps |
| B | Ethnicity, family type, parental age/occupation/education, household size, parity, marriage & first-birth age, religion, delivery place/mode/attendant, ANC, PNC, media access, decision-making, nutrition counselling | Predictors |
| C | Water, sanitation, cooking fuel, land, 14 assets, 7 vehicles, bank account, floor/roof/wall, shared toilet, livestock, kitchen | Wealth index |
| D | Relationship to child, DOB, age, sex, birth order, birth interval, birth weight | Child predictors |
| E | 5-group household-level food consumption (yesterday) | Household diet context |
| F | 18 child food groups + liquids + meal frequency (yesterday) | **MDD / MMF / MAD** |
| G | **EC-FIES 8 items** (G.A–G.H) + **8 barrier items** (G.I–G.P), split by age block | **Primary outcome + barriers** |

**Important design detail:** Module G is routed by age. `G.1.*` (n=83) goes to 6–8-month-olds
with the reference period *"since [NAME] started eating solid or semi-solid foods"*;
`G.2.*` (n=324) goes to 9–23-month-olds with *"in the past 3 months"* (বিগত ৩ মাসে).
The English labels in the SPSS file are copy-pasted and **wrongly show the G.1 wording on
the G.2 items** — the Bengali instrument is the authority. This must be stated in the
methods, because the pooled 8-item scale uses two different recall windows by age.
Routing is clean: no overlaps, no gaps.

---

## 2. Problems that must be fixed

### 2.1 The draft's front matter is from a different thesis — **fix first**

`doc/Thesis Draft.docx` LIST OF TABLES and LIST OF FIGURES describe a study of
**climate shocks in coastal Bangladesh**, not this one:

- Table 4.3 *Duration of the shocks*, 4.4 *Respondent reported critical period of shocks*,
  4.5 *Coping strategies adopted by household during climate shocks*
- Table 4.6 *FCS categories in the coastal household of Bangladesh*
- Tables 4.16–4.18 *…effect of climate shock on moderate/severe food insecurity*
- Figure 2.3 *Coastal districts of Bangladesh*, 4.2 *Household affected by any climate shock*,
  4.10–4.11 *…across coastal regions*
- §3.4.2 of the methodology is titled **"Climate shock"**

The ToC also lists **Appendix-C: Similarity Index Certificate**, so this will go through
Turnitin. Imported structure from another thesis is exactly what a similarity check
flags. Purge all of it before another word is written.

### 2.2 "Mixed-methods" is claimed but there is no qualitative component — **decision needed**

The draft title, §3.1, and the research questions all promise a mixed-methods design with
qualitative interviews on lived experience and feeding barriers. There is **no qualitative
tool in `Materials/` and no qualitative data anywhere**. The synopsis never promised one —
it says *"rapid assessment… to collect quantitative data."*

Two ways out, and the supervisor has to pick:

- **(A) Drop "mixed-methods."** Retitle to match the synopsis. The 8 quantitative barrier
  items (G.I–G.P) already answer research question 4 with real numbers (§4.4). *Recommended
  — it is honest, matches the approved synopsis, and costs no fieldwork.*
- **(B) Collect the qualitative arm.** 12–15 IDIs with purposively sampled mothers across
  food-security strata. Adds ~6–8 weeks plus a separate IRB amendment.

Everything downstream — title, abstract, methods, chapter structure — depends on this. **Ask now.**

### 2.3 Data errors in `MAIN.sav`

| Variable | Problem | Fix |
|---|---|---|
| `D8_birth_weight_kg` | **Mixed units.** 7 records in kg (2.2, 2.5, 2.8, 3.0×2, 3.2, 3.9); the other 312 in grams. `98` = "don't know" (n=88) is left in the numeric field. One value of 700 g and one of 5000 g. | Multiply the 7 kg values by 1000; set 98 to missing; flag 700 g for verification against the source form |
| `age_months` | Stored as **string**; `age_category` string with blanks | Coerce to numeric |
| Age eligibility | 2 children outside 6–23 months (one 5 mo, one 24 mo) | Keep with a footnote, or exclude — state which |
| `D7_Birth_interval` | Minimum value of 2 months — biologically implausible | Verify or set missing |
| EC-FIES | 17 "Don't know" responses already recoded to missing; 13 respondents miss 1 item, 2 miss 2 items | Use complete cases (n=392) for the raw score; document |

### 2.4 Errors in the draft's Chapter 4 tables

Cross-checked every reported number against `MAIN.sav`:

- **Table 4.1, Religion:** "Hindu 19 | 47" — should be **4.7%**, decimal dropped.
- **Table 4.1, Wealth Quintile:** rows are **empty** although `Ncombsco` exists and is
  cleanly balanced (Lowest 81, Second 82, Middle 81, Fourth 82, Highest 81).
- **Table 4.2, Age Group:** 82 (20.1%) + 307 (75.4%) = 389 ≠ 407. The 18 children with no
  recorded date of birth are silently dropped. They *do* have `approx_age`; use it.
- **Table 4.2, Birth Weight:** 92 + 219 + 88 = **399 ≠ 407**, and percentages sum to 100.1.
  Downstream of the unit problem in §2.3.
- **Table 4.4, Father's Occupation:** reported as Agriculture 139 / Business 224 /
  Remittance 31 / Not working 13. The raw data is Wage-Labour 106, Job-holder 98,
  Business 98, Agriculture 33, Remittance 31, Others 28, Not working 13. The counts are
  a legitimate collapse (33+106=139; 98+98+28=224) but the **labels are wrong** —
  "Business" is being used for a category that is mostly salaried employment. Relabel to
  *"Agriculture / day labour"* and *"Business / service / other"*.
- Draft Table 4.2.1 (division × residence × ECFI) **does reconcile** with the data. Good.

### 2.5 Housekeeping

`script.R`, `graph.R`, and `.Rhistory` in the project root are leftovers from two unrelated
freelance jobs (a Garo ocular-morbidity study and a breast-cancer survival study). They
should be deleted so nobody runs them by accident.

---

## 3. Methodological decisions to settle

### 3.1 How to score the EC-FIES — the central choice

The scale performs beautifully:

- **Cronbach's α = 0.887** (n = 392)
- Item endorsement falls monotonically in exactly the expected severity order:
  worried 46.8% → unable to eat healthy 39.9% → fewer foods 31.4% → not enough
  food 15.1% → less food 20.7% → ran out 15.5% → hungry 9.9% → did not eat all
  day 6.1%
- The inter-item correlation matrix is a clean simplex (adjacent items correlate
  most, distant items least) — the signature of a unidimensional Rasch scale

Two scoring routes:

- **Raw-score cut-points** (what the draft already uses): 0 = food secure, 1–3 = mild,
  4–6 = moderate, 7–8 = severe. Simple, transparent, reproducible in SPSS.
- **Rasch / one-parameter logistic model** — the official FAO "Voices of the Hungry"
  approach used for FIES and adopted for EC-FIES. Produces item severity parameters,
  infit statistics, respondent measures, and *probabilistic* prevalence estimates with
  standard errors.

**Recommendation: do both.** Report raw-score prevalence as the headline (it is what the
tables and figures rest on), and run the Rasch model as a **validation** chapter. The
synopsis explicitly claims this study *"will be among the first to validate and apply the
newly developed EC-FIES tool in the Bangladeshi context."* A psychometric validation
section is the single strongest claim to novelty this thesis has, and the data clearly
supports it. Needs `RM.weights` (FAO's own package) — not currently installed.

### 3.2 Which outcome for the regression models

`n = 80` moderate-or-severe cases (20.4%). At the conventional 10 events per variable
that allows roughly **8 predictor degrees of freedom** — not 8 variables, 8 *df*, so a
5-level wealth quintile eats 4 of them. Budget accordingly; do not throw all 20 candidate
predictors into one model.

- **Primary model:** binary logistic on moderate-or-severe (raw ≥ 4).
- **Sensitivity:** ordinal logistic across all four severity levels (test the proportional
  odds assumption; `ordinal` package is installed). Uses more information and buys back power.
- **Also worth reporting:** binary logistic on *any* ECFI (raw ≥ 1), n = 209 — the larger
  event count supports a fuller model.

### 3.3 Software

R 4.6.1 is installed and already has `haven`, `dplyr`, `gtsummary`, `flextable`, `officer`,
`ggplot2`, `nnet`, `MASS`, `ordinal`, `car`, `broom`, `labelled`, `janitor`. Missing and
needed: **`RM.weights`** (Rasch), **`psych`** (α, tetrachoric correlations), and `sf` +
`rnaturalearth` if the division choropleth is wanted.

The synopsis promises SPSS 26. Suggested compromise: **build everything in R** (scripted,
reproducible, auto-generates Word tables via `flextable`/`officer`), and describe it in the
methods as *"SPSS 26 and R 4.6.1"* — the wealth index genuinely was built in SPSS, so this
is accurate. Cross-check two or three key tables in SPSS before submission.

### 3.4 Sample size

The synopsis's §3.2 is titled "Sample size calculation" but contains **no calculation** —
only a description of sampling. This will be asked about in the viva. Add a post-hoc
precision statement instead: n = 407 estimates a 20% prevalence with a 95% CI half-width
of ±3.9%; a design effect of 1.5 for clustering within 25 upazilas widens that to ±4.8%.

### 3.5 Clustering

Mothers were recruited at 25 upazila-level congregation sites. Standard errors that ignore
this clustering are too narrow. Either fit the models with cluster-robust SEs (upazila as
the cluster), or state plainly that clustering was not accounted for and list it as a
limitation. Cluster-robust is cheap — do it.

---

## 4. What the data already shows

All figures below computed directly from `MAIN.sav`.

### 4.1 Prevalence — the headline result

| EC-FIES severity | n | % |
|---|---|---|
| Food secure (raw 0) | 183 | 46.7 |
| Mild (1–3) | 129 | 32.9 |
| Moderate (4–6) | 46 | 11.7 |
| Severe (7–8) | 34 | 8.7 |
| **Moderate or severe (≥4)** | **80** | **20.4** |

### 4.2 Predictors — bivariate, χ² on moderate-or-severe

**Strongly associated:**

| Predictor | Gradient | p |
|---|---|---|
| Wealth quintile | 44.0% lowest → 11.2% highest | <0.001 |
| Father's education | 56.1% none → 5.1% tertiary | <0.001 |
| Mother's education | 52.9% none → 9.7% tertiary | 0.001 |
| Household bank account | 29.4% no → 9.9% yes | <0.001 |
| Division | 10.6% Rangpur → 34.1% Sylhet | 0.042 |

**Not associated:** urban/rural residence (p=0.78), child sex (0.88), birth order (0.71),
family type (0.39), religion (1.00), PNC attendance (0.73), nutrition counselling (0.27),
father's occupation (0.12).

The pattern is coherent: **economic position, not geography or child characteristics,
drives early childhood food insecurity in this sample.** The flat urban/rural result is
itself interesting and worth a paragraph in the discussion — urban poverty is doing as
much work as rural poverty.

### 4.3 IYCF indicators — computed, and they validate against national data

| Indicator | This study | BDHS 2022 (6–23 mo) |
|---|---|---|
| Minimum Dietary Diversity (≥5 of 8 groups) | **38.1%** | ~34% |
| Minimum Meal Frequency | **64.4%** | ~65% |
| Minimum Acceptable Diet | **28.0%** | ~28% |
| Currently breastfed | 93.4% | ~94% |

The close agreement with BDHS is a strong external-validity argument for a convenience
sample — **make this point explicitly in the discussion**; it is the best defence against
the sampling criticism this design will attract.

Food group consumption: breastmilk 93.4%, grains/roots 86.2%, eggs 45.0%, flesh foods
44.2%, vitamin-A fruit & veg 38.3%, other fruit & veg 36.9%, dairy 34.4%, legumes/nuts 24.3%.

**A null result that matters:** MDD, MMF, and MAD are **not** significantly associated with
EC-FIES status (p = 0.55, 0.13, 0.12). Mean dietary diversity score is 4.03 in food-secure
children vs 3.91 in the moderate/severe group — a difference of one-tenth of a food group.

This directly contradicts hypotheses 3, 4, and 5 as the draft frames them, and it needs to
be reported as a finding rather than buried. The interpretation is defensible and
interesting: **complementary feeding quality here is uniformly poor across the whole
socioeconomic range**, so an experience-based food insecurity scale and a 24-hour dietary
recall are measuring genuinely different constructs. Food-secure households are not
feeding their children meaningfully better diets — they are simply not *worried* about it.
That is a stronger policy message than a positive association would have been: income
transfers alone will not fix diet quality here.

### 4.4 Barriers to feeding (module G.I–G.P) — answers RQ4 without qualitative work

Percent reporting "sometimes" or "always", 9–23-month block (n = 324):

| Barrier | % |
|---|---|
| Child refused food / spat it out | **81.5** |
| Could not find nutritious food in local shops/markets | 40.2 |
| Struggled to find time to prepare food | 38.8 |
| Did not know what nutritious food to give or how to prepare it | 34.3 |
| Could not travel to shops/markets | 33.2 |
| Not permitted to decide what to buy | 21.4 |
| Not permitted to go to the shop/market | 21.2 |
| Another household member discouraged feeding | 15.5 |

Three distinct clusters here — **child-level** (refusal, 81.5%), **structural** (market
availability, transport, time, ~33–40%), and **maternal agency** (permission, decision
authority, discouragement, 15–21%). Cross-tabulating each against ECFI severity is the
whole of research question 4, and the agency cluster is the most publishable angle.

### 4.5 Unused asset: GPS coordinates

`@_A1_3__latitude` / `@_A1_3__longitude` are populated for **367 of 407** interviews. The
draft's §3.5.2 already promises "spatial analysis" and currently delivers nothing. Even a
simple point map of the 25 upazilas over a division boundary layer would fill the study-area
figure and justify that heading.

---

## 5. Proposed table and figure plan

**Tables**

| # | Content |
|---|---|
| 4.1 | Household and socioeconomic characteristics (incl. the missing wealth quintile rows) |
| 4.2 | Child characteristics (age, sex, birth order, birth weight — after the unit fix) |
| 4.3 | Maternal characteristics |
| 4.4 | Paternal characteristics (with corrected occupation labels) |
| 4.5 | Maternal & newborn health service use (ANC, delivery, PNC, counselling) |
| 4.6 | WASH and housing |
| 4.7 | **EC-FIES item endorsement, Rasch severity parameters, infit/outfit** |
| 4.8 | **Raw score distribution and prevalence by severity category** |
| 4.9 | Prevalence by division and residence *(already drafted — keep)* |
| 4.10 | IYCF indicators: food groups, MDD, MMF, MAD, breastfeeding |
| 4.11 | Bivariate associations with moderate-or-severe ECFI |
| 4.12 | **Multivariable logistic regression — adjusted ORs** |
| 4.13 | Ordinal logistic across four severity levels (sensitivity) |
| 4.14 | Barriers to feeding by ECFI severity |

**Figures**

| # | Content |
|---|---|
| 3.1 | Study area — 25 upazilas from GPS, over division boundaries |
| 3.2 | UNICEF conceptual framework adapted to EC-FIES |
| 4.1 | EC-FIES item severity ladder (Rasch) |
| 4.2 | Raw score distribution |
| 4.3 | Severity composition by wealth quintile (stacked bar) — the strongest single graphic |
| 4.4 | Division choropleth, moderate-or-severe prevalence |
| 4.5 | Food group consumption |
| 4.6 | Forest plot of adjusted odds ratios |
| 4.7 | Barriers, diverging stacked bar by ECFI severity |

---

## 6. Suggested sequence

1. **Get the §2.2 decision** (mixed-methods or not) — everything else hangs on it.
2. Purge the borrowed front matter and §3.4.2 (§2.1). Rebuild the table/figure lists empty.
3. Write `01_clean.R` — fix birth weight, coerce age, build MDD/MMF/MAD, EC-FIES raw score
   and categories, label everything, save `Data/ecfies_clean.rds`. Ship a cleaning log.
4. Write `02_descriptives.R` — Tables 4.1–4.6, 4.10.
5. Write `03_ecfies_rasch.R` — Tables 4.7–4.8, Figures 4.1–4.2. Install `RM.weights` first.
6. Write `04_models.R` — Tables 4.11–4.13, Figure 4.6, with upazila-clustered SEs.
7. Write `05_barriers_spatial.R` — Table 4.14, Figures 3.1, 4.4, 4.7.
8. Fill Chapter 3 (currently ~10 empty subsections) from the questionnaire and this plan.
9. Write Chapters 4–7 against the finished tables.
10. Abstract last.

Steps 3–7 are perhaps two days of work; the data is cooperative. The thesis-writing is
the long pole.

---

## 7. Open questions for the student / supervisor

1. **Mixed-methods — in or out?** (§2.2) Blocking.
2. **Rasch validation chapter — in or out?** (§3.1) It is the study's best novelty claim,
   and the data supports it, but it adds a psychometrics section to a nutrition thesis.
3. **Primary outcome:** moderate-or-severe (n=80) or any-ECFI (n=209)? Affects model size.
4. **The 88 "don't know" birth weights** (21.6%) — is a paper record available for any of
   them, or does birth weight enter the analysis as a 3-level variable with "unknown" kept
   as its own category?
5. **The 700 g birth weight** — real, or a data-entry slip for 1700/2700?
6. **Are the 2 out-of-range children** (5 and 24 months) to be kept or dropped?
7. **Must the final analysis be reproducible in SPSS**, or is R output acceptable to the
   examination committee? (§3.3)
