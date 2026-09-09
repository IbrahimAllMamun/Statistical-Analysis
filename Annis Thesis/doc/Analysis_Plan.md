# Early Childhood Food Insecurity (EC-FIES) — Bangladesh
## Project brainstorm & analysis plan

**Student:** Md. Samsul Arefen Anni (MS 2023-24, INFS, University of Dhaka)
**Supervisor:** Dr. Md. Ruhul Amin
**Data:** `Data/MAIN.sav` — 407 mother–child pairs, 323 variables, KoBo/ODK export
**Prepared:** 2026-09-05 · **Revised:** 2026-09-09

---

## Revision note — what changed on 2026-09-09

`Materials/indicator_methods.pdf` was added: WHO & UNICEF (2021), *Indicators for
assessing infant and young child feeding practices: definitions and measurement
methods*, Geneva. 122 pp. This is the **authoritative source** for every IYCF
indicator in the thesis, and it settles a set of questions the earlier draft of this
plan had to guess at. Five consequences, each worked through below:

1. **Module F of the questionnaire is a Bengali translation of this document's own
   example questionnaire** (Part 2, §B.4). That is a strong methods-chapter claim and
   it fixes the exact variable-to-indicator mapping. See §3.6.
2. **The indicator set grows from 3 to 10.** MDD/MMF/MAD were the only ones computed.
   Seven more are computable today from data already collected: EFF, SwB, UFC, ZVF,
   CBF, ISSSF, MMFF. See §4.3.
3. **MAD was slightly wrong.** The non-breastfed branch needs a minimum-milk-feed
   condition that was not applied. 28.0% → **29.0%**. See §3.6.3.
4. **New data-quality problems in Module F** that only surface once the WHO algorithm
   is applied line by line. See §2.6.
5. **The central null result is now much stronger, and its interpretation has to be
   corrected.** Seven diet indicators, not three, are unrelated to EC-FIES. But the
   earlier claim that diet is "uniformly poor across the socioeconomic range" is
   wrong — wealth does predict diet. See §4.4, which also reports a **new positive
   finding** that gives the thesis its spine.

---

## 0. TL;DR — where the project actually stands

| Component | Status |
|---|---|
| Data collection | **Done.** 407 interviews (target 400), 8 divisions, 25 upazilas, GPS captured for 367 |
| EC-FIES scale | **Clean and strong.** α = 0.887, perfect severity gradient, 392/407 complete |
| Wealth index | **Already built** in SPSS (DHS-style PCA: `comscore`, `Ncombsco`, urban/rural splits) |
| IYCF indicators | **All 10 computable ones now computed** against the WHO/UNICEF 2021 definitions (§4.3) |
| Instrument provenance | **Established.** Module F is WHO's own example questionnaire, translated (§3.6) |
| Thesis draft | **Skeleton only.** Ch. 1–2 written; Ch. 3 half-empty; Ch. 4 has 5 tables; Ch. 5–7 empty |
| Front matter | **Contaminated** — table/figure lists belong to a different thesis (see §2.1) |

The analysis is much closer to done than the draft suggests. The dataset is in good
shape, the headline results are visible (§4), and the arrival of the WHO manual means
every indicator can now be defined by citation rather than by argument. The bottleneck
is writing, not analysis.

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
| E | 5-group **household-level** food consumption (yesterday) | Household diet, and §4.4's key finding |
| F | Milk/liquid rows, 17 child food groups, meal frequency, 7 sweet-beverage probes | **All 10 IYCF indicators** |
| G | **EC-FIES 8 items** (G.A–G.H) + **8 barrier items** (G.I–G.P), split by age block | **Primary outcome + barriers** |

**Reference standard** (`indicator_methods.pdf`) — WHO & UNICEF (2021). Defines 17
IYCF indicators, of which this study can produce 10 (§4.3). Part 1 §B gives the
definitions, Part 2 §C the calculation algorithms, Annex 6 the food-group contents and
Annex 8 the questionnaire-row-to-food-group table. Cite it for every indicator.

**Important design detail:** Module G is routed by age. `G.1.*` (n=83) goes to 6–8-month-olds
with the reference period *"when [NAME] started eating solid or semi-solid foods"*
(যখন [নাম] শক্ত বা আধা-শক্ত খাবার খেতে শুরু করেছিল); `G.2.*` (n=324) goes to
9–23-month-olds with *"in the past 3 months"* (বিগত ৩ মাসে). Verified against the Bengali
instrument on 2026-09-09. The English labels in the SPSS file are copy-pasted and
**wrongly show the G.1 wording on the G.2 items** — the Bengali is the authority. This
must be stated in the methods, because the pooled 8-item scale uses two different recall
windows by age. Routing is clean: no overlaps, no gaps.

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
  items (G.I–G.P) already answer research question 4 with real numbers, and they answer it
  *better* than before now that both age blocks can be pooled (§4.5). *Recommended — it is
  honest, matches the approved synopsis, and costs no fieldwork.*
- **(B) Collect the qualitative arm.** 12–15 IDIs with purposively sampled mothers across
  food-security strata. Adds ~6–8 weeks plus a separate IRB amendment.

Everything downstream — title, abstract, methods, chapter structure — depends on this. **Ask now.**

### 2.3 Data errors in `MAIN.sav` — child and household variables

| Variable | Problem | Fix |
|---|---|---|
| `D8_birth_weight_kg` | **Mixed units.** 7 records in kg (2.2, 2.5, 2.8, 3.0×2, 3.2, 3.9); the other 312 in grams. `98` = "don't know" (n=88) is left in the numeric field. One value of 700 g and one of 5000 g. | Multiply the 7 kg values by 1000; set 98 to missing; flag 700 g for verification against the source form |
| `age_months` | Stored as **string**; `age_category` string with blanks | Coerce to numeric |
| Age eligibility | 2 children outside 6–23 months (one 5 mo, one 24 mo) | Keep with a footnote, or exclude — state which. Note that WHO's denominator is strictly ≥183 and <730 days, so a strict reading excludes both (§3.6.5) |
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

These five are already corrected in `01_tables_chapter4.R`, which regenerates Tables
3.1 and 4.1–4.5 into `doc/Tables_Chapter4.docx` with a log at `doc/tables_cleaning_log.txt`.

### 2.5 Housekeeping

`script.R`, `graph.R`, and `.Rhistory` in the project root are leftovers from two unrelated
freelance jobs (a Garo ocular-morbidity study and a breast-cancer survival study). They
should be deleted so nobody runs them by accident.

### 2.6 Data problems in Module F — new, found by applying the WHO algorithms

None of these were visible until the indicator syntax in Part 2 §C was applied row by row.
All counts are out of 407.

| # | Problem | n | What to do |
|---|---|---|---|
| a | **Meal-frequency question contradicts the food list.** `F_A_freq_food` (WHO's Q8) says 0 meals for 7 children who *did* report eating a listed food; and says ≥1 meal for 4 children who reported eating nothing. | 11 | Report both, reconcile against the paper forms if they exist. Compute ISSSF from the **food list**, as WHO Part 2 §C.7 requires — not from Q8. |
| b | **Question order deviates from WHO.** The instrument asks meal frequency (F.A) *before* the food list (F.B–F.R). WHO's example questionnaire asks it *after* (Q8 follows Q7), so that the respondent has been walked through what counts as a food before being asked to count meals. | all | Almost certainly the cause of (a). State it as a limitation in the methods chapter. Nothing to fix in the data. |
| c | **`F_A_1Num` = 8 for one record.** `8` is the "Don't know" code on every adjacent yes/no row, so 8 formula feeds and "don't know" are indistinguishable. | 1 | Verify; otherwise treat as missing, which per WHO Part 2 §C.9 scores 0. |
| d | **Gate says yes, count says zero.** One child with formula = Yes has `F_A_1Num` = 0. | 1 | Same treatment as (c). |
| e | **Sweet-drink probes asked out of gate.** `Fswt1` (was the milk sweet/flavoured?) is "Yes" for 12 children whose records report no milk at all; `Fswt2` (sweet yogurt drink) is "Yes" for 5 with no yogurt. | 17 | Moves SwB from 17.4% to 15.0% if the gate is enforced. Report the WHO-literal 17.4% and the gated 15.0% as a sensitivity check. |
| f | **Duplicate item numbers in the Bengali form.** Two consecutive rows are both printed `Fswt5` (sodas/malt/sports/energy; and tea/coffee/herbal), and the follow-ups run `Fswt5.1`, `Fswt6`, `Fswt6.1`. The SPSS export silently renumbered them to `Fswt5`, `Fswt6`, `Fswt6_1`, `Fswt7`, `Fswt7_1`. The mapping is recoverable and consistent, but it is a live data-collection risk. | — | Confirm with the field team that both rows were administered. Note that `Fswt5` (sodas) is **"No" for all 407** — plausible for this age group, but it is exactly the pattern a skipped row would produce. |
| g | **21 children have a food-group score of 1** (breast milk only); 13 of them recorded zero meals. Their ages run to 20 months. | 21 | A 20-month-old who ate nothing in 24 hours is implausible. Flag for verification; do not silently drop. |
| h | **"Don't know" on food rows.** 9 responses across 6 rows, affecting 7 children. On barrier items there are 48, of which 30 are on the single item G.*.O (knowledge of what to feed). | 7 / 30 | WHO scores DK as "not consumed" for food rows. For the barrier items, 30 DKs on one item is itself a finding — report it rather than absorbing it into "Never". |

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
Wilson intervals for every headline estimate are tabulated in §4.1 and §4.3.

### 3.5 Clustering

Mothers were recruited at 25 upazila-level congregation sites. Standard errors that ignore
this clustering are too narrow. Either fit the models with cluster-robust SEs (upazila as
the cluster), or state plainly that clustering was not accounted for and list it as a
limitation. Cluster-robust is cheap — do it. WHO's Annex 3 covers sampling and design
issues specific to food-group recall surveys and is worth citing here.

### 3.6 Constructing the IYCF indicators — settled by `indicator_methods.pdf`

#### 3.6.1 The instrument is WHO's own

Module F is a Bengali translation of the example questionnaire in Part 2 §B.4 of the WHO
manual, essentially row for row. `F.P` ("চকোলেট, ক্যান্ডি, পেস্ট্রি, কেক, বিস্কুট বা হিমায়িত খাবার
যেমন: আইসক্রিম এবং পপসিকলস") is a faithful rendering of WHO's row 7P, and `F.Q` ("চিপস,
ক্রিস্পস, পাফস, ফ্রেঞ্চ ফ্রাই, ভাজা ময়দা, ইনস্ট্যান্ট নুডলস") of row 7Q. This matters twice
over: it means the sentinel unhealthy-food indicator is **valid as collected**, and it gives
the methods chapter a citable provenance for the whole module instead of a description.
Say so explicitly — it is the best answer available to "why should we trust this instrument?"

#### 3.6.2 Variable mapping — WHO question number → `MAIN.sav`

The instrument merged WHO's separate liquids block (Q6) into the F.A rows and split the
yogurt question in an unusual way, so the mapping is not guessable and must be written down.

| WHO | Content | `MAIN.sav` |
|---|---|---|
| Q4 | Breastfed yesterday | `F_A_0_Breastmilk` |
| Q6B / Q6Bnum | Infant formula / frequency | `F_A_1_Infant_formula` / `F_A_1Num_Biomil_Prima` |
| Q6C / Q6Cnum | Animal milk / frequency | `F_A_2_ANIMAL_MILK` / `F_A_2Num_freq_animal_milk` |
| Q6D / Q6Dnum | **Liquid** yogurt drink / frequency | `F_A_3_YOGURT` (shared gate) / `F_A_3Num1_freq_Liquid_yogurt` |
| Q7A / Q7Anum | **Semi-solid** yogurt / frequency | `F_A_3_YOGURT` (shared gate) / `F_A_3Num2_freq_semi_solid_yogurt` |
| Q6Cswt, Q6Dswt | Milk / yogurt drink sweetened | `Fswt1…`, `Fswt2…` |
| Q6E, Q6F, Q6G | Chocolate drinks, juice, sodas | `Fswt3…`, `Fswt4…`, `Fswt5…` |
| Q6H + Q6Hswt | Tea/coffee/herbal + sweetened | `Fswt6_Tea_coffee…` + `Fswt6_1…` |
| Q6J + Q6Jswt | Other liquids + sweetened | `Fswt7_Any_other_liquids` + `Fswt7_1…` |
| Q7B … Q7R | The 17 food rows | `F_B_…` … `F_R_0_other_food`, in order |
| Q8 | Times ate solid/semi-solid/soft food | `F_A_freq_food` |
| — | Plain water (Q6A), bottle feeding (Q5) | **Not collected** |

The one trap: **WHO treats liquid yogurt and semi-solid yogurt as two different questions**
(Q6D and Q7A) because they enter the indicators differently — liquid yogurt counts toward
non-breastfed meal frequency, semi-solid yogurt does not (it is already inside Q8), and both
count toward the milk-feed minimum. This instrument asks one gate question and two separate
frequency counts, which preserves the distinction but only if `F_A_3Num1` and `F_A_3Num2`
are kept apart. 17 of the 21 yogurt consumers had zero *liquid* yogurt, so collapsing the
two would misclassify most of them.

#### 3.6.3 MAD was wrong and is now fixed

The earlier figure of 28.0% treated MAD as simply MDD ∧ MMF. WHO Part 2 §C.11 requires,
for **non-breastfed** children, that the minimum milk feeding frequency (MMFF, ≥2 milk
feeds) also be met — and for MMF itself, non-breastfed children need ≥4 feeds counting
milk, with at least one solid. Applying the correct branch:

> **MAD = MDD ∧ MMF ∧ (breastfed ∨ MMFF)** → **29.0%** (118/407), not 28.0%.

Only 27 children are not breastfed, so the correction is small in this sample. It is still
the difference between an indicator that matches the published definition and one that does
not, and a reviewer who recomputes it will notice. MMF moves 64.4% → **64.1%** for the same
reason.

#### 3.6.4 What cannot be computed, and why

Seven of WHO's 17 indicators are out of reach, and the methods chapter should say so
rather than leave the reader to wonder:

- **EvBF, EIBF, EBF2D** (ever breastfed, early initiation, exclusive for first two days) —
  Module B has no birth-recall feeding questions at all.
- **EBF, MixMF** (exclusive and mixed milk feeding under 6 months) — denominator is 0–5
  months; this sample is 6–23 months by design.
- **BoF** (bottle feeding) — WHO's Q5 was not asked.
- **Area graphs** — need the under-6-month sample plus a plain-water question (Q6A), neither
  of which exists here.

The first three are the real loss: early initiation is the single most commonly reported
IYCF indicator in Bangladesh and its absence will be noticed. It is a one-question fix for
any future round, and worth a sentence in the recommendations.

#### 3.6.5 Denominator

WHO defines the denominator as age in days ≥183 and <730. Only completed months are
available here. Using 6 ≤ age ≤ 23 months, two children fall outside (one 5-month-old, one
24-month-old, §2.3). Dropping them moves no indicator by more than 0.2 percentage points
(e.g. MDD 38.1% → 38.0%). **Recommendation:** report on all 407 for consistency with the
EC-FIES tables, and footnote the two out-of-range children plus the sensitivity result.
Whatever is chosen, apply it identically to every table.

---

## 4. What the data already shows

All figures below computed directly from `MAIN.sav`. Intervals are Wilson 95% CIs and do
**not** yet account for upazila clustering (§3.5).

### 4.1 Prevalence — the headline result

| EC-FIES severity | n | % | 95% CI |
|---|---|---|---|
| Food secure (raw 0) | 183 | 46.7 | 41.8–51.6 |
| Mild (1–3) | 129 | 32.9 | 28.4–37.7 |
| Moderate (4–6) | 46 | 11.7 | 8.9–15.3 |
| Severe (7–8) | 34 | 8.7 | 6.3–11.9 |
| **Moderate or severe (≥4)** | **80** | **20.4** | **16.7–24.7** |
| Any (≥1) | 209 | 53.3 | 48.4–58.2 |

Denominator 392 — the complete-case EC-FIES sample.

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

### 4.3 IYCF indicators — all ten, per WHO/UNICEF 2021

| Indicator | n / N | % | 95% CI | BDHS 2022 (6–23 mo) |
|---|---|---|---|---|
| **MDD** Minimum dietary diversity | 155/407 | **38.1** | 33.5–42.9 | ~34% |
| **MMF** Minimum meal frequency | 261/407 | **64.1** | 59.4–68.6 | ~65% |
| **MAD** Minimum acceptable diet | 118/407 | **29.0** | 24.8–33.6 | ~28% |
| **EFF** Egg and/or flesh food | 266/407 | **65.4** | 60.6–69.8 | *look up* |
| **SwB** Sweet beverage | 71/407 | **17.4** | 14.1–21.4 | *look up* |
| **UFC** Unhealthy food (sentinel) | 185/407 | **45.5** | 40.7–50.3 | *look up* |
| **ZVF** Zero vegetable or fruit | 170/407 | **41.8** | 37.1–46.6 | *look up* |
| **CBF** Continued breastfeeding 12–23 mo | 206/227 | **90.7** | 86.3–93.9 | ~94% |
| **ISSSF** Intro. of solids 6–8 mo | 76/82 | **92.7** | 84.9–96.6 | *look up* |
| **MMFF** Min. milk feeds, non-breastfed | 16/27 | **59.3** | 40.7–75.5 | *look up* |
| *(context)* Breastfed yesterday, all ages | 380/407 | 93.4 | 90.5–95.4 | — |

The four indicators marked *look up* are new in the 2021 revision; national comparators
must be pulled from the BDHS 2022 final report rather than assumed. **Do not fill these
from memory** — they are the numbers most likely to be checked.

MDD/MMF/MAD/CBF agree closely with BDHS 2022. That close agreement is a strong
external-validity argument for a convenience sample — **make this point explicitly in the
discussion**; it is the best defence against the sampling criticism this design will attract.

**The four new indicators are the most quotable results in the thesis:**

- **41.8% of children ate no vegetable or fruit at all** in the previous 24 hours.
- **45.5% consumed a sentinel unhealthy food** — sweets, chips, biscuits, instant noodles.
  More children ate an unhealthy snack food than reached minimum dietary diversity (38.1%).
- **17.4% had a sweet beverage** (15.0% under the stricter gated definition, §2.6e).
- Only **65.4%** ate an egg or any flesh food.

Food group consumption, the eight MDD groups: breast milk 93.4%, grains/roots/tubers 86.2%,
eggs 45.0%, flesh foods 44.2%, vitamin-A rich fruit & veg 38.3%, other fruit & veg 36.9%,
dairy 34.4%, pulses/nuts/seeds 24.3%. Mean food-group score 4.03 of 8; the modal score is 4
(93 children), and 21 children scored 1 (breast milk only — see §2.6g).

### 4.4 The null result, corrected and strengthened

**None of the seven child-diet indicators is associated with EC-FIES severity.**

Percent achieving each indicator, by EC-FIES category, with χ² against moderate-or-severe:

| Indicator | Secure | Mild | Moderate | Severe | p |
|---|---|---|---|---|---|
| MDD achieved | 41.0 | 34.1 | 32.6 | 35.3 | 0.55 |
| MMF achieved | 69.4 | 62.8 | 60.9 | 55.9 | 0.23 |
| MAD achieved | 31.7 | 27.9 | 23.9 | 20.6 | 0.23 |
| EFF egg/flesh consumed | 66.7 | 62.8 | 65.2 | 61.8 | 0.93 |
| SwB sweet beverage | 20.8 | 7.0 | 21.7 | 29.4 | 0.05 |
| UFC unhealthy food | 39.3 | 56.6 | 45.7 | 35.3 | 0.48 |
| ZVF zero veg or fruit | 42.1 | 41.9 | 43.5 | 44.1 | 0.87 |

Mean food-group score: 4.18 secure, 3.81 mild, 3.87 moderate, 3.97 severe (Mann-Whitney
p = 0.50 secure vs moderate/severe). MAD and MMF are the only two that fall monotonically,
and neither reaches significance on a trend test (p = 0.12 and 0.07). The SwB p-value of
0.05 is not a gradient — the mild group sits at 7.0% between two ~21% groups, and the
trend test returns p = 0.59. Treat it as noise, not a finding.

**The earlier interpretation was wrong and must be corrected.** This plan previously said
complementary feeding quality is "uniformly poor across the whole socioeconomic range."
It is not. Wealth predicts child diet perfectly clearly:

| Wealth quintile | Moderate/severe ECFI | Child food-group score | MDD achieved |
|---|---|---|---|
| Lowest | 44.0% | 3.85 | 34.6% |
| Second | 20.3% | 3.73 | 26.8% |
| Middle | 15.6% | 4.15 | 45.7% |
| Fourth | 12.3% | 3.88 | 31.7% |
| Highest | 11.2% | 4.53 | 51.9% |

Wealth versus child food-group score: r = +0.15, p = 0.003. So wealth moves diet, and
wealth moves EC-FIES, but **EC-FIES and diet do not move together.** That is a sharper and
more defensible claim than the old one, and it is the finding the discussion should be
built around.

**And there is a positive result that makes sense of it.** The household-level 5-group
score from Module E *does* track EC-FIES severity, cleanly and significantly:

| EC-FIES category | Mean household food groups (of 5) |
|---|---|
| Food secure | 3.39 |
| Mild | 3.14 |
| Moderate | 3.11 |
| Severe | 2.74 |

Trend across the four levels p = 0.0006; Mann-Whitney secure vs moderate/severe p = 0.009.

So: **as food insecurity deepens, the household's diet narrows — and the child's does not.**
That is dietary buffering, and it is a well-documented phenomenon that this dataset happens
to capture unusually well, because it measured household and child diet in the same
interview with parallel food groups.

A pass-through analysis supports it. Among households that ate a given food group
yesterday, the proportion whose child also ate it:

| Food group | Households eating it | Pass-through to child | Secure | Mod/severe | p |
|---|---|---|---|---|---|
| Grains/roots | 395 | 88.6% | 88.1% | 88.6% | 1.00 |
| Vitamin-A fruit/veg | 227 | 47.6% | 45.3% | 54.8% | 0.35 |
| Other fruit/veg | 159 | 49.1% | 51.5% | 41.7% | 0.51 |
| Eggs/flesh foods | 313 | 73.5% | 71.4% | 78.7% | 0.39 |
| Pulses/nuts/seeds | 211 | 37.0% | 31.2% | 52.3% | **0.017** |

Pass-through does not fall as food insecurity worsens for any group, and for pulses it
rises sharply — food-insecure households that have pulses in the house are markedly more
likely to feed them to the child, plausibly as a cheap protein substituting for eggs and
flesh foods. **Caveat:** that is one significant result out of five tests, and it would not
survive a Bonferroni correction. Report it as suggestive and say so.

Two structural facts worth noting in the discussion regardless of significance:
**vitamin-A rich fruit and vegetables reach the child in fewer than half of the households
that eat them (47.6%), and pulses in barely a third (37.0%)**. The gap between what a
household eats and what a 6–23-month-old is given is a programmatic target in itself, and
it is invisible to any indicator computed on the child alone.

**How to frame all of this.** An experience-based scale and a 24-hour dietary recall are
measuring different constructs. EC-FIES captures worry, coping and perceived adequacy at
the household level; MDD captures what actually entered the child's mouth yesterday. Both
have an economic root, which is why both correlate with wealth, but they are not
substitutes for one another and this study shows it directly. The policy reading is that
income transfers alone will not fix diet quality here: **41.8% of children ate no fruit or
vegetable yesterday, and that number barely moves between food-secure and severely
food-insecure households.** That is a stronger message than a positive association would
have been, and it directly contradicts hypotheses 3, 4 and 5 as the draft frames them —
which needs to be reported as a finding, not buried.

### 4.5 Barriers to feeding (module G.I–G.P) — answers RQ4 without qualitative work

The barrier items were **not** pooled across the two age blocks in the SPSS file (unlike the
EC-FIES items, which were). Pooling `G_1_*` and `G_2_*` recovers the full sample and is
straightforward — the two blocks differ only in the recall window, exactly as the EC-FIES
items do. Percent reporting "sometimes" or "always", "don't know" treated as missing:

| Barrier | All (n=407) | Secure | Mod/severe | p |
|---|---|---|---|---|
| Child refused food / spat it out | **81.1** | 78.8 | 88.8 | 0.064 |
| Nutritious food unavailable in local shops | 39.6 | 37.0 | 48.7 | 0.077 |
| Struggled to find time to prepare food | 36.0 | 24.4 | **73.4** | <0.001 |
| Did not know what to give or how to prepare | 32.4 | 22.4 | **67.1** | <0.001 |
| Could not travel to shops/markets | 32.1 | 27.1 | 48.7 | <0.001 |
| Not permitted to decide what to buy | 21.2 | 16.1 | 39.2 | <0.001 |
| Not permitted to go to the shop/market | 20.8 | 15.8 | 37.2 | <0.001 |
| Household member discouraged feeding | 16.0 | 9.3 | 36.7 | <0.001 |

Per-item denominators are 377–407; the knowledge item carries 30 "don't know" responses,
by far the most of any item, which is itself worth reporting (§2.6h).

Three distinct clusters: **child-level** (refusal, 81.1%), **structural** (market
availability, transport, time, 32–40%), and **maternal agency** (permission, decision
authority, discouragement, 16–21%).

**This is the other half of the story in §4.4.** Six of the eight barriers are very strongly
associated with EC-FIES severity, while none of the seven diet indicators is. Caregivers in
food-insecure households report markedly more difficulty feeding their children — time,
knowledge, mobility, permission, family opposition — and yet the measured diet of those
children is no worse. The two most strongly associated barriers are not about money at all:
**time to prepare food (24.4% → 73.4%) and knowing what to feed (22.4% → 67.1%)**. The
agency cluster is the most publishable angle and the one a nutrition-education or
women's-empowerment intervention could actually act on.

Note the direction of causality is not identifiable here, and the barrier items and the
EC-FIES items sit in the same module and share a respondent, a recall window and a framing
about lack of money. Some of this association is common-method variance. Say so.

### 4.6 Unused asset: GPS coordinates

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
| 4.8 | **Raw score distribution and prevalence by severity category, with CIs** |
| 4.9 | Prevalence by division and residence *(already drafted — keep)* |
| 4.10 | **All ten IYCF indicators with 95% CIs, against BDHS 2022** *(expanded)* |
| 4.11 | **Eight MDD food groups, and the 17 questionnaire rows behind them** *(new)* |
| 4.12 | **IYCF indicators by EC-FIES severity — the null result** *(new, §4.4)* |
| 4.13 | **Household (Module E) vs child (Module F) food groups and pass-through** *(new, §4.4)* |
| 4.14 | Bivariate associations with moderate-or-severe ECFI |
| 4.15 | **Multivariable logistic regression — adjusted ORs** |
| 4.16 | Ordinal logistic across four severity levels (sensitivity) |
| 4.17 | Barriers to feeding by ECFI severity, pooled across both age blocks |

**Figures**

| # | Content |
|---|---|
| 3.1 | Study area — 25 upazilas from GPS, over division boundaries |
| 3.2 | UNICEF conceptual framework adapted to EC-FIES |
| 4.1 | EC-FIES item severity ladder (Rasch) |
| 4.2 | Raw score distribution |
| 4.3 | Severity composition by wealth quintile (stacked bar) — the strongest single graphic |
| 4.4 | Division choropleth, moderate-or-severe prevalence |
| 4.5 | Food group consumption, all eight groups |
| 4.6 | **Household vs child diet across EC-FIES severity — the two lines that diverge** *(new)* |
| 4.7 | Forest plot of adjusted odds ratios |
| 4.8 | Barriers, diverging stacked bar by ECFI severity |

Figure 4.6 is the one to get right. Two series on one panel across the four severity
categories: household 5-group mean (falling, 3.39 → 2.74) and child 8-group mean (flat,
4.18 → 3.97). It states the thesis's central finding in a single image.

Figures use the Okabe-Ito colour-blind-safe palette; **no red anywhere** — `#0072B2` blue,
`#E69F00` amber, `#009E73` green.

---

## 6. Suggested sequence

1. **Get the §2.2 decision** (mixed-methods or not) — everything else hangs on it.
2. Purge the borrowed front matter and §3.4.2 (§2.1). Rebuild the table/figure lists empty.
3. Write `01_clean.R` — fix birth weight, coerce age, build the EC-FIES raw score and
   categories, pool the barrier items across both age blocks, label everything, save
   `Data/ecfies_clean.rds`. Ship a cleaning log covering §2.3 and §2.6.
4. Write `02_iycf.R` — all ten indicators, coded straight from the WHO algorithms in
   Part 2 §C with the mapping in §3.6.2, plus Module E household groups and pass-through.
   Tables 4.10–4.13, Figures 4.5–4.6. **Cross-check the four new indicators against the
   BDHS 2022 report before writing a word about them.**
5. Write `03_descriptives.R` — Tables 4.1–4.6. Much of this already exists in
   `01_tables_chapter4.R` and can be lifted.
6. Write `04_ecfies_rasch.R` — Tables 4.7–4.8, Figures 4.1–4.2. Install `RM.weights` first.
7. Write `05_models.R` — Tables 4.14–4.16, Figure 4.7, with upazila-clustered SEs.
8. Write `06_barriers_spatial.R` — Table 4.17, Figures 3.1, 4.4, 4.8.
9. Fill Chapter 3 (currently ~10 empty subsections) from the questionnaire, the WHO manual
   and this plan. §3.6 is close to publishable text for the IYCF measurement subsection.
10. Write Chapters 4–7 against the finished tables.
11. Abstract last.

Steps 3–8 are perhaps two to three days of work; the data is cooperative. The
thesis-writing is the long pole.

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
6. **Are the 2 out-of-range children** (5 and 24 months) to be kept or dropped? (§3.6.5)
7. **Must the final analysis be reproducible in SPSS**, or is R output acceptable to the
   examination committee? (§3.3)
8. **Was the sodas/malt/energy-drink row actually administered?** (§2.6f) It is "No" for all
   407, and the Bengali form numbers two consecutive rows `Fswt5`. A field-team confirmation
   settles it.
9. **Can the 11 meal-frequency contradictions be checked against paper forms?** (§2.6a) If
   the forms are gone, say so and treat the food list as authoritative for ISSSF.
10. **Is the dietary-buffering framing (§4.4) acceptable to the supervisor?** It reframes
    hypotheses 3–5 from "confirmed/rejected" into a more interesting question, but it is a
    genuine change of story and the supervisor should sign off before Chapter 5 is written.

---

## Appendix A. Indicator syntax against `MAIN.sav`

Every percentage in §4.3 is reproducible from these expressions. They are the algorithms
in Part 2 §C of `indicator_methods.pdf`, rewritten in terms of the variable names in
`MAIN.sav` using the mapping in §3.6.2. Written R-style; the SPSS translation is direct.

Codes throughout: `1 = Yes`, `2 = No`, `8 = Don't know`. WHO scores "don't know" and
missing as **not consumed** on food rows, and as **0** on the frequency counts.

```r
age    <- coalesce(as.numeric(age_months), as.numeric(approx_age))   # completed months
elig   <- age >= 6 & age <= 23          # WHO: age in days >=183 & <730
bf     <- F_A_0_Breastmilk == 1         # Q4  breastfed yesterday
Q8     <- coalesce(F_A_freq_food, 0)    # Q8  solid/semi-solid/soft feeds yesterday

# --- the eight MDD food groups (WHO Part 2 §C.8, Annex 8) --------------------
fg1 <- bf                                                    # breast milk
fg2 <- F_B_FOODS_MADE_FROM_GRAINS == 1 | F_D_ROOTS == 1      # grains, roots, tubers
fg3 <- F_N_PEAS_NUTS == 1                                    # pulses, nuts, seeds
fg4 <- F_A_1_Infant_formula == 1 | F_A_2_ANIMAL_MILK == 1 |
       F_A_3_YOGURT == 1 | F_O_CHEESE == 1                   # dairy
fg5 <- F_I_ORGAN_MEAT == 1 | F_J_PROCESSED_MEATS == 1 |
       F_K_OTHER_MEATS == 1 | F_M_FRESH_OR_DRIED_FISH == 1   # flesh foods
fg6 <- F_L_EGGS == 1                                         # eggs
fg7 <- F_C_CARROTS_SQUASH_ETC == 1 | F_E_LEAFY_VEGETABLES == 1 |
       F_G_MANGO_RIPE_PAPAYA == 1                            # vitamin-A rich fruit & veg
fg8 <- F_F_OTHER_VEGETABLES == 1 | F_H_OTHER_FRUITS == 1     # other fruit & veg
FGS <- fg1 + fg2 + fg3 + fg4 + fg5 + fg6 + fg7 + fg8         # 0-8

# --- milk-feed counts -------------------------------------------------------
# NOTE: F_A_3Num1 is the LIQUID yogurt drink (WHO Q6Dnum);
#       F_A_3Num2 is SEMI-SOLID yogurt (WHO Q7Anum). They are not interchangeable.
milk_mmf  <- z(F_A_1Num_Biomil_Prima) + z(F_A_2Num_freq_animal_milk) +
             z(F_A_3Num1_freq_Liquid_yogurt)                   # excludes semi-solid yogurt
milk_mmff <- milk_mmf + z(F_A_3Num2_freq_semi_solid_yogurt)     # includes it
# z() = replace NA with 0

# --- the indicators ---------------------------------------------------------
MDD   <- FGS >= 5
MMF   <- (age %in% 6:8   & bf & Q8 >= 2) |
         (age %in% 9:23  & bf & Q8 >= 3) |
         (!bf & (milk_mmf + Q8) >= 4 & Q8 >= 1)
MMFF  <- !bf & milk_mmff >= 2                        # denominator: non-breastfed only
MAD   <- MDD & MMF & (bf | MMFF)
EFF   <- fg5 | fg6
ZVF   <- !(F_C_CARROTS_SQUASH_ETC == 1 | F_E_LEAFY_VEGETABLES == 1 |
           F_F_OTHER_VEGETABLES  == 1 | F_G_MANGO_RIPE_PAPAYA  == 1 |
           F_H_OTHER_FRUITS == 1)                    # roots/tubers do NOT count here
UFC   <- F_P_SWEET_FOODS == 1 | F_Q_SALTY_FOODS == 1
SwB   <- Fswt1 == 1 | Fswt2 == 1 | Fswt3 == 1 | Fswt4 == 1 |
         Fswt5 == 1 | Fswt6_1 == 1 | Fswt7_1 == 1
         # Fswt3/4/5 are assumed sweet; 1/2/6_1/7_1 are the "was it sweetened?" probes.
         # Gated sensitivity (§2.6e): require milk reported for Fswt1,
         # yogurt reported for Fswt2  ->  15.0% instead of 17.4%.
CBF   <- bf                                          # denominator: age 12-23 months
ISSSF <- any(F_B..F_R_0 == 1)                        # denominator: age 6-8 months
         # WHO Part 2 §C.7 uses the FOOD LIST, not Q8. Using Q8 >= 1 gives 91.5%
         # instead of 92.7% -- the 11 contradictions of §2.6a.
```

**Household diet, Module E** (5 groups, household-level, previous day). Used for §4.4:

```r
HHS <- (E1_Grains_Or_Roots == 1) + (E2_Vitamin_A_Ruits_And_Vegetables == 1) +
       (E3_Other_Fruits_And_Vegetables == 1) + (E4_Eggs_And_Flesh_Foods == 1) +
       (E5_Pulses_Nuts_And_Seeds == 1)                                      # 0-5
```

Pass-through for a group is the proportion of children consuming the matching Module F
rows among households where the Module E row is 1. The pairings are E1↔fg2, E2↔fg7,
E3↔fg8, E4↔(fg5 | fg6), E5↔fg3.

**Barrier items**, pooled across the two age blocks (§4.5):

```r
barrier_K <- coalesce(G_1_K_..., G_2_K_...)          # for K in I..P
endorsed  <- barrier_K %in% c(2, 3)                  # "Sometimes" or "Always"
                                                     # 8 = "Do not know" -> missing
```

**EC-FIES** (already pooled in the SPSS file as `G_Worried` … `G_did_not_eat`):

```r
raw <- if (n_valid == 8) sum(the 8 items) else NA    # complete cases, n = 392
cat <- cut(raw, c(-Inf, 0, 3, 6, 8),
           labels = c("Food secure", "Mild", "Moderate", "Severe"))
```

All §4.3 and §4.4 figures were recomputed from `MAIN.sav` on 2026-09-09 using exactly
these expressions. They have **not** yet been reproduced in R against the client's
environment — that is step 4 of §6, and the R output should be checked against the
tables here before anything is written into the thesis.
