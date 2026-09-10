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

**Added 2026-09-10 — the study direction has flipped.** The outcome variable is now an
**IYCF indicator**, with EC-FIES as the exposure, rather than the reverse. This is a
different study from the one the synopsis describes and it changes every model. §3.2 is
rewritten around it, §3.8 is new and handles the multiplicity that ten candidate outcomes
create, and §4.7 reports the flipped models. The short version: **EC-FIES does not predict
any IYCF outcome, in any specification, and the estimates are precise enough to call that
an informative null rather than a failure to detect.** What does predict child diet is
household dietary diversity, child age and father's education. The synopsis says
"predictors of food insecurity", so this needs supervisor sign-off before Chapter 4 is
written — see §7, question 2.

**Added earlier, after review:** the analysis in §4.4 and §4.5 had been run
on the **binary** form of every indicator, which was a mistake. WHO's cut-offs exist for
reporting prevalence; dichotomising a scale before testing an association discards
information and costs power. Every association has been re-run on the underlying
ordinal or count scale (new §3.7), and it changed the answers: two barrier items that
looked null are strongly associated, one diet signal that looked real turns out to be
confounded by wealth, and the household-diet finding is the one that survives. §3.2 has
been rewritten to make the **ordinal EC-FIES score, not the binary moderate-or-severe
split, the primary outcome**.

---

## 0. TL;DR — where the project actually stands

| Component | Status |
|---|---|
| Data collection | **Done.** 407 interviews (target 400), 8 divisions, 25 upazilas, GPS captured for 367 |
| EC-FIES scale | **Clean and strong.** α = 0.887, perfect severity gradient, 392/407 complete |
| Wealth index | **Already built** in SPSS (DHS-style PCA: `comscore`, `Ncombsco`, urban/rural splits) |
| IYCF indicators | **All 10 computable ones now computed** against the WHO/UNICEF 2021 definitions (§4.3) |
| Study direction | **Changed 2026-09-10** — an IYCF indicator is the outcome, EC-FIES the exposure (§3.2). Blocking supervisor question |
| Direction B result | **Fitted.** EC-FIES predicts no IYCF outcome; an informative null with tight intervals (§4.7) |
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

### 3.2 Study direction, and which variable is the outcome

**As of 2026-09-10 the outcome is an IYCF indicator and EC-FIES is the exposure.** That is
a change of study, not a change of analysis, and the two directions answer different
questions:

| Direction | Question | Matches the synopsis? |
|---|---|---|
| **A.** EC-FIES as outcome | What predicts early childhood food insecurity? | **Yes** — "prevalence and predictors of food insecurity" |
| **B.** IYCF as outcome | Does food insecurity shape what a child is actually fed? | No |

**Recommendation: keep both, as two objectives.** They share the cleaned dataset, the
covariates and the descriptive tables, so running both costs perhaps a day. Direction A
discharges the approved synopsis and gives Chapter 4 its prevalence and predictor tables.
Direction B is the more interesting question and carries the novel result. Dropping A
leaves the thesis not matching its own title page; dropping B throws away the finding.
Supervisor's call, and it is blocking (§7, question 2).

#### Direction B — the IYCF outcome

**Which indicator is primary?** Ten are computable (§4.3), and testing all ten against
EC-FIES is a multiplicity problem (§3.8). Pre-specify **one**.

> **Recommended primary outcome: minimum dietary diversity**, analysed as the **0–8
> food-group score**, with binary MDD reported alongside for comparability.

Why MDD over the alternatives:

- It is the most widely reported IYCF indicator, so the result is comparable to BDHS and
  to the published literature.
- It has an underlying score with real spread (Appendix B, table 1), so it can be analysed
  without dichotomising (§3.7).
- It is **not a composite**. MAD is MDD ∧ MMF ∧ MMFF, so a result on MAD cannot be
  attributed to any one component. MAD is the more policy-relevant indicator and should be
  reported, but it makes a poor primary outcome for a causal-sounding question.
- The events budget is adequate: binary MDD gives 146 of 392 in the smaller cell, which
  supports about 14 predictor degrees of freedom; the continuous score uses all 392.

Events available if a different indicator is chosen instead:

| Outcome | Yes | No | Limiting cell | Supports |
|---|---|---|---|---|
| ZVF | 166 | 226 | 166 | ~16 df |
| MDD | 146 | 246 | 146 | ~14 df |
| EFF | 254 | 138 | 138 | ~13 df |
| MMF | 255 | 137 | 137 | ~13 df |
| MAD | 112 | 280 | 112 | ~11 df |

**Model form.** Linear regression on the 0–8 score is primary; Poisson gives the same
answer here (§4.7) and either is defensible. Binary logistic on MDD is secondary, for
comparability. Meal frequency, if modelled, is a count and takes Poisson.

**Exposure form.** EC-FIES enters as the raw 0–8 score, per §3.7. Also report it as the
four-level category, because that is what readers will look for and because it does not
assume the effect is linear in the score.

#### Direction A — the EC-FIES outcome

If Direction A is retained as the first objective, the outcome still should not be
dichotomised:

- **Primary: ordinal logistic** across the four severity categories, or proportional-odds
  on the 0–8 score. The effective sample is 392 rather than 80 events, so the
  degrees-of-freedom budget stops being the binding constraint. Test the proportional-odds
  assumption and report the test.
- **Check the shape first.** The raw score is heavily zero-inflated: 46.7% score 0, with a
  long right tail and a second bump at 7–8 (Appendix B, table 8). If proportional odds
  fails, a hurdle model — logistic for any-versus-none, then an ordinal or count model on
  the 209 with a positive score — fits better than forcing one ordinal model or retreating
  to a binary one.
- **Secondary, for comparability only:** binary logistic on moderate-or-severe. Every
  published EC-FIES and FIES paper reports this cut-off, so the thesis has to show it.

#### What does not change

Covariates, clustering (§3.5) and the no-dichotomising rule (§3.7) are the same in both
directions. So is the caution about common-method variance: EC-FIES, the barrier items and
the Module E household diet all come from one respondent in one sitting, and Module F is
the same 24-hour recall. Direction B puts an exposure and an outcome from the same
instrument on opposite sides of a regression, which is exactly where shared-method bias
does its damage. Name it in the limitations.

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

### 3.7 Measurement scale — do not dichotomise for analysis

WHO's indicators are binary **by construction**: MDD is the percentage reaching five of
eight food groups, MMF the percentage reaching an age-specific meal count. That is the
right form for *reporting* prevalence and for comparison against BDHS, and §4.3 keeps it.

It is the wrong form for *testing associations*. Collapsing an eight-point food-group
score to a yes/no at five, or a meal count to a yes/no at three, discards most of the
variance and reduces power, and the loss is not evenly distributed — it is largest
exactly where the underlying variable is concentrated near the cut-off. Re-running §4.4
and §4.5 on the underlying scales changed four conclusions:

| Construct | Binary form | Underlying scale | Effect of dichotomising |
|---|---|---|---|
| Household diet | ≥4 of 5 groups, p = 0.084 | 0–5 count, p = 0.0005 | **Hid a real association** |
| Meal frequency | MMF achieved, p = 0.23 | 0–10 count, p = 0.0023 | **Hid an association** (but see §4.4 — it is confounded) |
| Barrier: food unavailable locally | Sometimes/Always, p = 0.077 | 1–3 ordinal, p < 10⁻⁶ | **Hid a strong association** |
| Barrier: child refused food | Sometimes/Always, p = 0.064 | 1–3 ordinal, p = 0.0006 | **Hid an association** |

**Rule for the whole analysis.** Report the WHO binary indicators in the descriptive
tables, because that is what the indicators are for. Do every association test, and fit
every model, on the underlying scale:

| Variable | Analyse as |
|---|---|
| EC-FIES | 0–8 raw score, or four-level ordinal, or Rasch person measure (§3.2) |
| Child dietary diversity | 0–8 food-group score |
| Meal frequency | 0–10 count from `F_A_freq_food` |
| Fruit and vegetable intake | 0–5 count of the five fruit/veg rows, not the ZVF flag |
| Animal-source foods | 0–9 count of the milk, egg and flesh rows, not the EFF flag |
| Sweet beverages / unhealthy foods | 0–7 and 0–2 item counts |
| Household diet | 0–5 group count from Module E |
| Barrier items | 1–3 ordinal per item; 0–16 total and two 0–6 subscales (§4.5) |

Correlations below are Spearman, because none of these are normally distributed and
several are heavily zero-inflated. Where wealth adjustment is reported it is a partial
Spearman, controlling on ranks. In the final analysis these become terms in the ordinal
model of §3.2 rather than pairwise correlations.

### 3.8 Ten candidate outcomes — the multiplicity problem

Direction B creates a problem the earlier design did not have. There are ten computable
IYCF indicators, several underlying scales and a handful of plausible exposures. Testing
every combination and reporting whichever comes up small is the most common way a null
study turns into a false positive.

Three rules, to be written into the methods chapter **before** the analysis is run:

1. **One pre-specified primary outcome** — MDD as the 0–8 food-group score (§3.2) — with
   one pre-specified primary exposure, the EC-FIES raw score. That is one test. It carries
   the study's conclusion and needs no correction.
2. **Everything else is secondary and labelled as such.** The other nine indicators are
   reported as a descriptive panel with confidence intervals and no significance stars, or
   with an explicit correction. Do not promote a secondary indicator to the headline
   because it happened to reach 0.05.
3. **Report every test that was run.** The panel in §4.7 is complete on purpose. A reader
   who can see all ten nulls will trust the one primary result; a reader shown only the
   interesting one has no way to judge it.

The same discipline applies to the barrier items: eight items plus three summary scores is
eleven tests. §4.5 handles it by leading with the total score, which the α of 0.776
justifies, and treating the item-level table as descriptive.

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

The categorical predictors below are legitimately tested against the binary split, since
they are themselves categorical and the table is descriptive. Everything with an
underlying scale is handled in §4.4 and §4.5 instead, per §3.7.

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

### 4.4 Diet and food insecurity — what actually tracks what

Every test below is on the underlying scale, per §3.7. Spearman ρ against the EC-FIES
raw score (0–8, n = 392), with a partial Spearman adjusting for wealth quintile.

| Measure | Range | ρ vs EC-FIES | p | ρ adj. wealth | p |
|---|---|---|---|---|---|
| **Household food groups (Module E)** | 0–5 | **−0.176** | **0.0005** | **−0.113** | **0.025** |
| Meal frequency count | 0–10 | −0.153 | 0.0023 | −0.044 | 0.38 |
| Animal-source food rows | 0–9 | −0.116 | 0.021 | — | — |
| Fruit and vegetable rows | 0–5 | −0.095 | 0.061 | — | — |
| Child food-group score | 0–8 | −0.086 | 0.090 | −0.042 | 0.41 |
| Unhealthy food items | 0–2 | +0.084 | 0.095 | — | — |
| Sweet beverage items | 0–7 | −0.023 | 0.64 | — | — |
| Food rows endorsed | 0–17 | +0.008 | 0.88 | — | — |

Means by severity category:

| Measure | Secure | Mild | Moderate | Severe | Kruskal-Wallis p |
|---|---|---|---|---|---|
| Household food groups (0–5) | 3.39 | 3.14 | 3.11 | 2.74 | 0.0014 |
| Meal frequency (0–10) | 3.04 | 2.64 | 2.54 | 2.24 | 0.013 |
| Child food-group score (0–8) | 4.18 | 3.81 | 3.87 | 3.97 | 0.33 |
| Fruit and vegetable rows (0–5) | 1.01 | 0.73 | 0.74 | 0.79 | 0.28 |
| Animal-source rows (0–9) | 1.51 | 1.28 | 1.22 | 1.21 | 0.13 |
| Food rows endorsed (0–17) | 3.92 | 3.60 | 4.00 | 4.21 | 0.75 |

Three things follow, and they are not the same thing.

**1. Child dietary diversity genuinely does not track food insecurity.** This survives the
move off the binary cut-off. The 0–8 score gives ρ = −0.086, p = 0.09 crude, and p = 0.41
once wealth is controlled. The count of all 17 food rows is flat to three decimal places.
This is a real null, not an artefact of dichotomising, and it can be reported as one.

**2. Meal frequency looked like a real signal and is not an independent one.** The binary
MMF indicator gave p = 0.23; the 0–10 count gives p = 0.0023, with a clean monotone fall
from 3.04 meals in food-secure children to 2.24 in the severe group. It is robust to age
adjustment (p = 0.0011), to restricting to the 9–23-month block with its single recall
window (p = 0.0021), to excluding the 11 contradictory records of §2.6a (p = 0.0030), and
to excluding all 22 zero-meal records (p = 0.0045). **But it disappears entirely on
adjustment for wealth** (ρ = −0.044, p = 0.38). Wealth drives both. Report the crude
gradient, report the adjusted null, and do not claim an independent effect of food
insecurity on meal frequency. Whether wealth is a confounder or a mediator here is not
identifiable in a cross-sectional design; say so rather than picking one.

**3. Household diet is the finding.** The Module E five-group count falls monotonically
across severity, ρ = −0.176, p = 0.0005, and it is **the only diet measure that survives
wealth adjustment** (ρ = −0.113, p = 0.025). It is also unaffected by age adjustment
(p = 0.0004).

Put together: **as food insecurity deepens the household's diet narrows, and the child's
does not.** That is dietary buffering, and this dataset captures it unusually well because
household and child diet were measured in the same interview with parallel food groups.

The earlier claim in this plan that complementary feeding is "uniformly poor across the
whole socioeconomic range" was wrong and is withdrawn. Wealth predicts child diet clearly:

| Wealth quintile | Moderate/severe ECFI | Child food-group score | MDD achieved |
|---|---|---|---|
| Lowest | 44.0% | 3.85 | 34.6% |
| Second | 20.3% | 3.73 | 26.8% |
| Middle | 15.6% | 4.15 | 45.7% |
| Fourth | 12.3% | 3.88 | 31.7% |
| Highest | 11.2% | 4.53 | 51.9% |

Wealth versus child food-group score: r = +0.15, p = 0.003. So wealth moves diet and wealth
moves food insecurity, but food insecurity and diet do not move together once wealth is
held constant. That is the sharp version of the claim and the one the discussion should
be built on.

**Two counts to treat carefully.** The unhealthy-food count (0.52, 0.76, 0.65, 0.50) and
the sweet-beverage count (0.25, 0.09, 0.28, 0.47) both return significant Kruskal-Wallis
tests, p = 0.023 and 0.0012, but neither is monotone — the mild group is the outlier in
both, high on unhealthy food and low on sweet drinks. Neither has a trend (ρ p = 0.10 and
0.64). Do not build an argument on either. Report the four means and say the pattern is
non-monotone.

**Pass-through.** Among households that ate a given group yesterday, the proportion whose
child also ate it:

| Food group | Households eating it | Pass-through to child | Secure | Mod/severe | p |
|---|---|---|---|---|---|
| Grains/roots | 395 | 88.6% | 88.1% | 88.6% | 1.00 |
| Vitamin-A fruit/veg | 227 | 47.6% | 45.3% | 54.8% | 0.35 |
| Other fruit/veg | 159 | 49.1% | 51.5% | 41.7% | 0.51 |
| Eggs/flesh foods | 313 | 73.5% | 71.4% | 78.7% | 0.39 |
| Pulses/nuts/seeds | 211 | 37.0% | 31.2% | 52.3% | **0.017** |

Pass-through does not fall as food insecurity worsens for any group, which is what
buffering predicts. The pulses result is one significant test out of five and would not
survive a Bonferroni correction; report it as suggestive and say so. Two structural facts
stand regardless of significance: **vitamin-A rich fruit and vegetables reach the child in
fewer than half of the households that eat them, and pulses in barely a third.** The gap
between what a household eats and what a 6–23-month-old is given is a programmatic target
in itself, and it is invisible to any indicator computed on the child alone.

**How to frame it.** An experience-based scale and a 24-hour dietary recall measure
different constructs. EC-FIES captures worry, coping and perceived adequacy at household
level; the food-group score captures what entered the child's mouth yesterday. Both have
an economic root, which is why both correlate with wealth, but they are not substitutes
and this study shows it directly. The policy reading is that income transfers alone will
not fix diet quality here: 41.8% of children ate no fruit or vegetable yesterday, and that
number barely moves between food-secure and severely food-insecure households. That
contradicts hypotheses 3, 4 and 5 as the draft frames them, and needs to be reported as a
finding rather than buried.

### 4.5 Barriers to feeding (module G.I–G.P) — the strongest signal in the dataset

The barrier items were **not** pooled across the two age blocks in the SPSS file, unlike
the EC-FIES items. Pooling `G_1_*` and `G_2_*` recovers the full sample. The items are
**three-level** — Never / Sometimes / Always — and collapsing them to a binary was the
worst of the dichotomisations in the earlier draft, because it hid two associations
entirely.

Prevalence uses "Sometimes or Always", which is the reportable form; the association tests
use the 1–3 ordinal scale. "Do not know" is treated as missing throughout.

| Barrier | Sometimes/Always | Secure | Mild | Mod | Sev | ρ vs raw | ordinal p | binary p |
|---|---|---|---|---|---|---|---|---|
| Struggled to find time to prepare | 36.0% | 1.21 | 1.42 | 1.85 | 1.94 | **+0.402** | <10⁻¹⁵ | <0.001 |
| Household member discouraged feeding | 16.0% | 1.05 | 1.18 | 1.44 | 1.59 | +0.332 | <10⁻¹⁰ | <0.001 |
| Did not know what to give | 32.4% | 1.24 | 1.29 | 1.62 | 2.10 | +0.317 | <10⁻⁹ | <0.001 |
| Nutritious food unavailable locally | 39.6% | 1.25 | 1.56 | 1.46 | 1.72 | +0.282 | <10⁻⁷ | **0.077** |
| Could not travel to market | 32.1% | 1.21 | 1.41 | 1.62 | 1.55 | +0.269 | <10⁻⁶ | <0.001 |
| Not permitted to go to market | 20.8% | 1.16 | 1.23 | 1.38 | 1.67 | +0.247 | <10⁻⁵ | <0.001 |
| Not permitted to decide purchases | 21.2% | 1.18 | 1.23 | 1.47 | 1.68 | +0.221 | <10⁻⁴ | <0.001 |
| Child refused food | 81.1% | 1.92 | 2.06 | 2.22 | 2.21 | +0.172 | 0.0006 | **0.064** |

Columns 3–6 are mean level on the 1–3 scale. Per-item denominators are 377–407; the
knowledge item carries 30 "don't know" responses, by far the most of any item, which is
itself worth reporting (§2.6h).

**All eight barriers are associated with EC-FIES severity.** The binary analysis reported
six, missing local food availability and child refusal — the two bolded p-values above.
Both are strongly significant once the Always/Sometimes distinction is kept.

**The items form a usable scale.** Cronbach's α = 0.776 across the eight items (n = 366).
That justifies summing them, which is more informative than eight separate tests and
avoids the multiplicity problem:

| Score | Range | Secure | Mild | Mod | Sev | ρ vs raw | p | ρ adj. wealth | p |
|---|---|---|---|---|---|---|---|---|---|
| **Total barrier score** | 0–16 | 2.12 | 3.05 | 4.54 | 6.26 | **+0.395** | 1×10⁻¹⁴ | +0.307 | 4×10⁻⁹ |
| Structural subscale (I, J, M) | 0–6 | 0.67 | 1.36 | 1.91 | 2.13 | **+0.421** | 7×10⁻¹⁸ | +0.327 | 5×10⁻¹¹ |
| Agency subscale (K, L, N) | 0–6 | 0.39 | 0.62 | 1.26 | 1.97 | +0.317 | 2×10⁻¹⁰ | +0.230 | 5×10⁻⁶ |
| Knowledge item (O) | 0–2 | 0.24 | 0.29 | 0.62 | 1.10 | +0.317 | 6×10⁻¹⁰ | +0.226 | 1×10⁻⁵ |
| Child refusal (P) | 0–2 | 0.92 | 1.06 | 1.22 | 1.21 | +0.172 | 6×10⁻⁴ | +0.145 | 0.004 |

Subscale α: structural 0.630, agency 0.689. Modest, and they should be reported as such,
but both are adequate for a three-item scale and the two subscales behave differently
enough to be worth keeping apart.

**The structural subscale at ρ = +0.421 is the strongest association anywhere in this
dataset** — stronger than wealth quintile, stronger than either parent's education. Every
score survives adjustment for wealth, which none of the diet measures except household
diversity does.

**This is the other half of §4.4.** Caregivers in food-insecure households report markedly
more difficulty feeding their children — time, knowledge, mobility, permission, family
opposition — and yet the measured diet of those children is no worse. The two strongest
individual barriers are not about money at all: time to prepare food and knowing what to
feed. The agency cluster is the most publishable angle and the one a nutrition-education
or women's-empowerment intervention could act on.

**Two cautions to state in the limitations.** Direction of causality is not identifiable
in a cross-sectional design. And the barrier items sit in the same module as the EC-FIES
items, share a respondent, a recall window and a framing about lack of money, so some of
this association is common-method variance. That is a real threat to the interpretation
and it should be named, not buried — it is the most likely reviewer objection.

### 4.6 Unused asset: GPS coordinates

`@_A1_3__latitude` / `@_A1_3__longitude` are populated for **367 of 407** interviews. The
draft's §3.5.2 already promises "spatial analysis" and currently delivers nothing. Even a
simple point map of the 25 upazilas over a division boundary layer would fill the study-area
figure and justify that heading.

---

### 4.7 IYCF practice as the outcome — the flipped models

Direction B fitted (§3.2). Outcome is the child's diet; exposure is the EC-FIES raw score;
covariates are wealth quintile, mother's education, child age, child sex, urban/rural
residence and current breastfeeding. n = 392 complete cases.

**Primary model — food-group score (0–8), linear regression:**

| Model | β per +1 EC-FIES point | 95% CI | p |
|---|---|---|---|
| Unadjusted | −0.045 | −0.113, +0.023 | 0.19 |
| **Adjusted** | **−0.007** | **−0.080, +0.066** | **0.85** |
| Poisson, adjusted (rate ratio) | 0.998 | 0.975, 1.022 | 0.87 |

EC-FIES as a four-level category instead, adjusted, reference = food secure:

| Category | β | 95% CI | p |
|---|---|---|---|
| Mild | −0.200 | −0.578, +0.179 | 0.30 |
| Moderate | −0.142 | −0.676, +0.391 | 0.60 |
| Severe | +0.069 | −0.567, +0.705 | 0.83 |

**Secondary outcomes, adjusted logistic, odds ratio per +1 EC-FIES point:**

| Outcome | OR | 95% CI | p |
|---|---|---|---|
| MDD | 0.988 | 0.890, 1.096 | 0.82 |
| MAD | 0.986 | 0.880, 1.104 | 0.80 |
| MMF | 0.989 | 0.893, 1.094 | 0.82 |
| EFF | 0.966 | 0.870, 1.071 | 0.51 |
| ZVF | 1.024 | 0.930, 1.128 | 0.63 |
| Meal frequency (Poisson, rate ratio) | 0.986 | 0.958, 1.015 | 0.34 |

**This is an informative null, not an underpowered one.** Write it in exactly these terms:

- Across the full 0–8 EC-FIES range the adjusted effect on the food-group score is bounded
  between **−0.64 and +0.53 food groups**. A difference larger than two-thirds of one food
  group between a food-secure child and a maximally food-insecure one is ruled out.
- For MDD, the adjusted odds ratio across a four-point EC-FIES shift — roughly secure
  versus moderate — is **0.95 (0.63, 1.44)**.

A null with intervals this tight is publishable. "No significant association was found",
without them, is not.

**Meal frequency is where confounding becomes visible.** The Poisson rate ratio is 0.963,
p = 0.005, with age, sex, residence and breastfeeding in the model but **not** wealth or
education. Adding those moves it to 0.986, p = 0.34. Socioeconomic position explains the
whole of it. Report both models side by side; it is the clearest illustration in the
dataset of why the adjusted model is the one to believe.

#### What does predict child dietary diversity

The same model, reading the other coefficients. Outcome is the 0–8 score, n = 392,
R² = 0.227.

| Predictor | Block p | Direction |
|---|---|---|
| **Household dietary diversity (Module E)** | **<0.0001** | +0.447 per household group |
| **Child age** | **<0.0001** | +0.070 per month |
| **Father's education** | **0.049** | +1.02 for higher secondary vs none |
| Wealth quintile | 0.081 | +0.53 highest vs lowest |
| Mother's education | 0.39 | — |
| Child sex | 0.16 | — |
| Urban residence | 0.21 | — |
| Currently breastfed | 0.15 | — |
| Household size | 0.47 | — |
| **EC-FIES** | **0.36** | — |

For binary MDD the same two dominate: household diversity OR 1.75 per group (p < 0.0001),
age OR 1.09 per month (p = 0.0002).

Three things to handle carefully in the write-up.

**1. The household-diet coefficient is partly mechanical.** Module E and Module F share a
respondent, a 24-hour window and overlapping food groups — if the household ate eggs, the
child plausibly ate the same eggs. Cramér's V between matched household and child groups
runs 0.20 to 0.39. The coefficient is real but it is not a clean causal estimate and must
not be presented as one. Report the model with and without it: wealth becomes significant
(p = 0.034) and father's education strengthens (p = 0.0012) when it is dropped, which is
what you would expect if household diet sits on the path between income and what the child
is fed.

**2. Mother's education is null and father's is not.** That inverts the usual finding in
the IYCF literature, where maternal education dominates. The two correlate at ρ = 0.56, so
collinearity is real but not extreme enough to explain it away. Worth a paragraph rather
than a footnote, and worth checking against mother's occupation (94% housewife) before
concluding anything — in a sample where almost no mother is in paid work, the father's
education may be carrying the household's entire socioeconomic signal.

**3. EC-FIES stays null with household diversity out of the model** (β = +0.025, p = 0.50
for the score; MDD OR 1.024, p = 0.67). The null is not an artefact of over-adjustment.

### 4.8 Bivariate screen — what is associated with child dietary diversity

Table 4.16. All 34 candidate independent variables against the outcome, tested on the 0–8
food-group score (Kruskal-Wallis, or Spearman for the three continuous variables) with the
binary MDD chi-squared printed alongside as a secondary column.

**Eight variables reach p < 0.05 on the score:**

| Variable | p (score) | Pattern, mean food-group score |
|---|---|---|
| Household food groups (0–5) | <0.001 | ρ = +0.313 |
| Child age group | <0.001 | 3.34 at 6–8 mo rising to 4.45 at 18–23 mo |
| Father's education | <0.001 | 3.30 none, 4.71 higher secondary |
| Division | <0.001 | 3.48 Chittagong to 4.92 Rangpur |
| Birth weight | <0.001 | 3.33 if <2.5 kg, 4.22 if ≥2.5 kg |
| Any media access | 0.005 | 3.63 no access, 4.16 with access |
| Wealth quintile | 0.009 | 3.85 poorest, 4.53 richest, **non-monotone** |
| Mother's education | 0.049 | 3.95 none, 4.69 tertiary, **non-monotone** |

**EC-FIES severity is null here too** (p = 0.33), consistent with §4.4 and §4.7. The
bivariate screen finds it on no reading.

Three things worth attention before this becomes Chapter 4 text.

**Birth weight is a new finding and needs care.** Low-birth-weight children score nearly
one food group lower. The plausible readings run in both directions — a smaller or sicker
child may be fed differently, or the same deprivation may cause both — and a cross-sectional
design cannot separate them. It is also downstream of the mixed-units repair in §2.3, so the
result should be re-checked after the 700 g value is verified.

**Two gradients are not gradients.** Wealth runs 3.85, 3.73, 4.15, 3.88, 4.53 across
quintiles, and mother's education runs 3.95, 3.93, 3.89, 4.25, 4.69. Both reach
significance while zigzagging, and in both the lowest category is not the lowest score.
Report the level means rather than describing either as a dose-response, and expect the
question at the viva.

**Rangpur is an outlier.** 64.6% reach MDD against 22.9% in Chittagong, and the division
effect is stronger than wealth. Worth checking whether one or two upazilas are driving it
before it is interpreted, which is also the clearest argument for the cluster-robust
standard errors of §3.5.

Nothing here is adjusted for multiple comparisons or for clustering. A variable reaching
0.05 in this table is a candidate for the multivariable model, not a finding.

Two variables were excluded as candidates rather than tested: 405 of 407 households use an
improved drinking-water source and 405 of 407 respondents are Bengali. Neither has the
variance to support a test, and saying so is better than reporting a meaningless p-value.

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
| 4.12 | **Diet measures on their underlying scales vs EC-FIES, crude and wealth-adjusted** *(new, §4.4)* |
| 4.13 | **Household (Module E) vs child (Module F) food groups and pass-through** *(new, §4.4)* |
| 4.14 | **Barrier items: prevalence, mean ordinal level by severity, ρ** *(new, §4.5)* |
| 4.15 | **Barrier scale: total and subscales, α, and wealth-adjusted associations** *(new, §4.5)* |
| 4.16 | **Bivariate: child dietary diversity vs all 34 candidate independent variables** *(§4.8)* |
| 4.17 | Bivariate associations with EC-FIES severity — Direction A |
| 4.18 | **Food-group score on EC-FIES and covariates — Direction B primary model** *(§4.7)* |
| 4.19 | **All ten IYCF outcomes on EC-FIES, adjusted — the complete panel** *(§3.8, §4.7)* |
| 4.20 | **Predictors of child dietary diversity, with and without household diet** *(§4.7)* |
| 4.21 | Ordinal logistic on EC-FIES severity — Direction A primary model *(§3.2)* |
| 4.22 | Binary logistic on moderate-or-severe — secondary, for comparability only |
| 4.23 | WHO indicators by EC-FIES severity, binary form — for completeness |

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
| 4.7 | **Barrier score against EC-FIES raw score, with a loess fit** *(new)* |
| 4.8 | **Forest plot: all ten IYCF outcomes on EC-FIES, adjusted, with CIs** — the informative null in one image *(§4.7)* |
| 4.9 | Forest plot of adjusted odds ratios from the Direction A ordinal model |
| 4.10 | Barriers, diverging stacked bar on the three-level scale by ECFI severity |

Figure 4.6 is the one to get right. Two series on one panel across the four severity
categories: household 5-group mean (falling, 3.39 → 2.74) and child 8-group mean (flat,
4.18 → 3.97). It states the thesis's central finding in a single image.

Figure 4.10 must show all three response levels. A diverging stacked bar with Never,
Sometimes and Always is the whole point — the Sometimes/Always collapse is what hid two
of the eight associations (§4.5).

Figures use the Okabe-Ito colour-blind-safe palette; **no red anywhere** — `#0072B2` blue,
`#E69F00` amber, `#009E73` green.

---

## 6. Suggested sequence

1. **Get the §2.2 decision** (mixed-methods or not) — everything else hangs on it.
2. Purge the borrowed front matter and §3.4.2 (§2.1). Rebuild the table/figure lists empty.
3. Write `01_clean.R` — fix birth weight, coerce age, build the EC-FIES raw score and
   categories, pool the barrier items across both age blocks, label everything, save
   `Data/ecfies_clean.rds`. Ship a cleaning log covering §2.3 and §2.6.
4. **`02_iycf.R` — written.** All ten indicators coded straight from the WHO algorithms in
   Part 2 §C with the mapping in §3.6.2, plus the continuous and count forms of Appendix A,
   Module E household groups and pass-through. Produces Tables 4.10–4.13 into
   `doc/Tables_IYCF.docx`, Figures 4.5–4.6 into `Graph/`, a run log at `doc/iycf_log.txt`,
   and the analysis-ready frame `Data/iycf_analysis.rds` that steps 6–8 read. Table 4.19
   moved to step 7, with the other model tables. Table 4.16, the bivariate screen of all 34
   candidate independent variables against child dietary diversity, is also produced here —
   it needs the same covariate construction, which the script exports so `05_models.R` does
   not re-derive it. The script carries a **self-check** that
   compares its output against fifteen headline counts from this plan and warns if any
   disagree — treat a mismatch as blocking. It has **not yet been run in R**, so the first
   run is a verification step, not a formality. **Cross-check the four new indicators
   against the BDHS 2022 report before writing a word about them.**
5. Write `03_descriptives.R` — Tables 4.1–4.6. Much of this already exists in
   `01_tables_chapter4.R` and can be lifted.
6. Write `04_ecfies_rasch.R` — Tables 4.7–4.8, Figures 4.1–4.2. Install `RM.weights` first.
7. Write `05_models.R` — Tables 4.17–4.23, Figures 4.8–4.9, with upazila-clustered SEs.
   **Fix the primary outcome and primary exposure in writing first** (§3.2, §3.8).
   Direction B, the IYCF outcome, is the main model set; Direction A's ordinal model
   follows the same covariate structure.
8. Write `06_barriers_spatial.R` — Tables 4.14–4.15, Figures 3.1, 4.4, 4.7, 4.10. Keep the
   barrier items on their three-level scale throughout (§3.7).
9. Fill Chapter 3 (currently ~10 empty subsections) from the questionnaire, the WHO manual
   and this plan. §3.6 is close to publishable text for the IYCF measurement subsection.
10. Write Chapters 4–7 against the finished tables.
11. Abstract last.

Steps 3–8 are perhaps two to three days of work; the data is cooperative. The
thesis-writing is the long pole.

---

## 7. Open questions for the student / supervisor

Questions 1 and 2 are blocking — nothing in Chapters 3 to 5 can be written until they are
settled, and they interact. Ask them together.

1. **Mixed-methods — in or out?** (§2.2) Blocking.
2. **Does the supervisor accept the flipped outcome, and does the synopsis need amending?**
   (§3.2) Blocking. The approved synopsis is titled *"Prevalence and predictors of food
   insecurity"*, which is Direction A. Making an IYCF indicator the outcome is Direction B
   and a different study. The recommendation is to keep both as two objectives, which
   preserves the synopsis and keeps the finding. Note that the answer changes what
   Chapter 5 argues, because Direction B's headline is a null (§4.7).
3. **Which IYCF indicator is the pre-specified primary outcome?** (§3.2) The recommendation
   is MDD as the 0–8 food-group score. Fix it in writing before the models are run, or the
   ten-outcome panel in §4.7 becomes a fishing expedition (§3.8).
4. **Is a null result acceptable as the headline?** (§4.7) EC-FIES predicts no IYCF
   outcome, and the intervals are tight enough to state that positively rather than plead
   low power. Defensible and publishable, but a committee expecting a positive association
   should hear it now, not at the viva.
5. **Rasch validation chapter — in or out?** (§3.1) It is the study's best novelty claim,
   and the data supports it, but it adds a psychometrics section to a nutrition thesis.
6. **Direction A outcome form.** Largely superseded by §3.2, which recommends ordinal on
   the four severity levels rather than a choice between two binary cut-offs. Still worth
   confirming the committee expects moderate-or-severe to appear somewhere, since it is
   the comparator every published EC-FIES paper reports.
7. **The 88 "don't know" birth weights** (21.6%) — is a paper record available for any of
   them, or does birth weight enter the analysis as a 3-level variable with "unknown" kept
   as its own category?
8. **The 700 g birth weight** — real, or a data-entry slip for 1700/2700?
9. **Are the 2 out-of-range children** (5 and 24 months) to be kept or dropped? (§3.6.5)
10. **Must the final analysis be reproducible in SPSS**, or is R output acceptable to the
   examination committee? (§3.3)
11. **Was the sodas/malt/energy-drink row actually administered?** (§2.6f) It is "No" for all
   407, and the Bengali form numbers two consecutive rows `Fswt5`. A field-team confirmation
   settles it.
12. **Can the 11 meal-frequency contradictions be checked against paper forms?** (§2.6a) If
   the forms are gone, say so and treat the food list as authoritative for ISSSF.
13. **Is the dietary-buffering framing (§4.4) acceptable to the supervisor?** It reframes
    hypotheses 3–5 from "confirmed/rejected" into a more interesting question, but it is a
    genuine change of story and the supervisor should sign off before Chapter 5 is written.
14. **Is an ordinal primary model acceptable to the committee?** (§3.2) It is the better
    analysis and it removes the events-per-variable constraint, but every comparable
    published EC-FIES paper dichotomises, and a committee expecting a binary logistic
    table will need the reasoning spelled out. The binary model is retained as a secondary
    analysis either way.
15. **Should mother's occupation replace or join mother's education in the models?** (§4.7)
    Maternal education is null where paternal education is not, which inverts the usual
    IYCF finding. With 94% of mothers recorded as housewives, paternal education may be
    carrying the whole socioeconomic signal. Worth one model run before it is written up
    as a substantive result.
16. **Wealth as confounder or mediator?** (§4.4) Meal frequency tracks food insecurity
    crudely and not after wealth adjustment. Whether wealth confounds that relationship or
    sits on the causal path is not identifiable here, and the two readings support
    different policy conclusions. Worth a supervisor conversation before Chapter 5.

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

**Continuous and ordinal forms used for every association test (§3.7).** These are the
analysis variables; the binary indicators above are for reporting prevalence only.

```r
FGS                                          # 0-8, as constructed above
meals    <- z(F_A_freq_food)                 # 0-10 count
fv_rows  <- (F_C == 1) + (F_E == 1) + (F_F == 1) + (F_G == 1) + (F_H == 1)      # 0-5
asf_rows <- (F_I == 1) + (F_J == 1) + (F_K == 1) + (F_M == 1) + (F_L == 1) +
            (F_A_1 == 1) + (F_A_2 == 1) + (F_A_3 == 1) + (F_O == 1)             # 0-9
all_rows <- sum of the 17 food rows == 1                                        # 0-17
sweet_n  <- sum of the 7 Fswt indicators == 1                                   # 0-7
ufc_n    <- (F_P_SWEET_FOODS == 1) + (F_Q_SALTY_FOODS == 1)                     # 0-2
HHS      <- as above                                                            # 0-5

# barrier items keep all three levels; 8 = "Do not know" -> NA
bar_K    <- na_if(coalesce(G_1_K_..., G_2_K_...), 8)        # 1 Never 2 Sometimes 3 Always
bar_tot    <- sum(bar_I .. bar_P) - 8                       # 0-16, alpha = 0.776
bar_struct <- (bar_I + bar_J + bar_M) - 3                   # 0-6,  alpha = 0.630
bar_agency <- (bar_K + bar_L + bar_N) - 3                   # 0-6,  alpha = 0.689

# EC-FIES stays on its raw 0-8 scale for all association testing (§3.2)
```

Associations are Spearman ρ against `raw`. Wealth adjustment is a partial Spearman:
rank-transform both variables and the control, regress each rank on the control, correlate
the residuals. In the final analysis these become terms in the ordinal model, not pairwise
correlations.

All §4.3, §4.4 and §4.5 figures were recomputed from `MAIN.sav` on 2026-09-09 and
2026-09-10 using exactly these expressions. They have **not** yet been reproduced in R against the client's
environment — that is step 4 of §6, and the R output should be checked against the
tables here before anything is written into the thesis.

---

## Appendix B. Frequency distributions of the analysis variables

Every variable §3.7 puts on an underlying scale, tabulated. Computed from `MAIN.sav`,
2026-09-10. These justify the non-dichotomised treatment variable by variable, and they
show where it does **not** matter.

**1. Child dietary diversity — food-group score (n = 407).** Mean 4.03, median 4, IQR 3–5.

| Score | n | % | Cum % |
|---|---|---|---|
| 1 | 21 | 5.2 | 5.2 |
| 2 | 57 | 14.0 | 19.2 |
| 3 | 81 | 19.9 | 39.1 |
| 4 | 93 | 22.9 | 61.9 |
| **5** | **75** | **18.4** | **80.3** |
| 6 | 53 | 13.0 | 93.4 |
| 7 | 20 | 4.9 | 98.3 |
| 8 | 7 | 1.7 | 100.0 |

MDD is score ≥5. The cut-off sits one step above the mode, and **41.3% of the sample
scores 4 or 5** — immediately either side of it. Those children differ by one food group
and are placed in opposite categories.

**2. Meal frequency — feeds yesterday (n = 407).** Mean 2.75, median 3, IQR 2–3.

| Count | n | % | Cum % |
|---|---|---|---|
| 0 | 22 | 5.4 | 5.4 |
| 1 | 51 | 12.5 | 17.9 |
| 2 | 102 | 25.1 | 43.0 |
| **3** | **135** | **33.2** | **76.2** |
| 4 | 57 | 14.0 | 90.2 |
| 5 | 23 | 5.7 | 95.8 |
| 6 | 10 | 2.5 | 98.3 |
| 7–10 | 7 | 1.7 | 100.0 |

**This is the worst dichotomisation in the set.** MMF for a breastfed 9–23-month-old is
≥3 feeds, and **135 children (33.2%) sit exactly on that value** — the modal response. A
one-feed recall error moves a third of the sample across the threshold. It is why binary
MMF returned p = 0.23 while the count returned p = 0.0023.

**3. Household food groups, Module E (n = 407).** Mean 3.21, median 3, IQR 3–4.

| Score | n | % | Cum % |
|---|---|---|---|
| 0 | 8 | 2.0 | 2.0 |
| 1 | 13 | 3.2 | 5.2 |
| 2 | 72 | 17.7 | 22.9 |
| 3 | 157 | 38.6 | 61.4 |
| 4 | 108 | 26.5 | 88.0 |
| 5 | 49 | 12.0 | 100.0 |

No WHO cut-off applies. Well spread, which is why the continuous form recovers a
significant association (p = 0.0005) that an arbitrary ≥4 split did not (p = 0.084).

**4. Fruit and vegetable rows (n = 407).** Mean 0.87, median 1, IQR 0–1.

| Count | n | % | Cum % |
|---|---|---|---|
| **0** | **170** | **41.8** | **41.8** |
| 1 | 160 | 39.3 | 81.1 |
| 2 | 48 | 11.8 | 92.9 |
| 3 | 22 | 5.4 | 98.3 |
| 4–5 | 7 | 1.7 | 100.0 |

ZVF is score = 0. **Here dichotomising costs almost nothing** — 81% of the sample is 0 or
1, so the variable is close to binary already. Report ZVF as the headline and do not
expect the count to add power.

**5. Animal-source food rows (n = 407).** Mean 1.39, median 1, IQR 1–2.

| Count | n | % | Cum % |
|---|---|---|---|
| 0 | 99 | 24.3 | 24.3 |
| 1 | 134 | 32.9 | 57.2 |
| 2 | 120 | 29.5 | 86.7 |
| 3 | 32 | 7.9 | 94.6 |
| 4 | 14 | 3.4 | 98.0 |
| 5 | 8 | 2.0 | 100.0 |

The theoretical range is 0–9 but nothing above 5 was observed. The binary EFF flag
(65.4% yes) collapses scores 1–5 into one bin, which is why it showed nothing (p = 0.93)
where the count showed ρ = −0.116, p = 0.021.

**6. Sweet beverage items (n = 407).** Mean 0.22, median 0.

| Count | n | % |
|---|---|---|
| 0 | 336 | 82.6 |
| 1 | 54 | 13.3 |
| 2 | 16 | 3.9 |
| 3 | 1 | 0.2 |

Heavily zero-inflated and effectively capped at 3, not 7. Like ZVF, the binary form loses
little. Both scales agree that nothing is there.

**7. Unhealthy (sentinel) food items (n = 407).** Mean 0.61, median 0.

| Count | n | % |
|---|---|---|
| 0 | 222 | 54.5 |
| 1 | 121 | 29.7 |
| 2 | 64 | 15.7 |

15.7% ate from **both** sentinel categories, sweet and salty, on the same day. The UFC
flag hides that group inside its 45.5%.

**8. EC-FIES raw score — the outcome (n = 392).** Mean 1.85, median 1, IQR 0–3.

| Score | n | % | Cum % |
|---|---|---|---|
| 0 | 183 | 46.7 | 46.7 |
| 1 | 45 | 11.5 | 58.2 |
| 2 | 45 | 11.5 | 69.6 |
| 3 | 39 | 9.9 | 79.6 |
| **4** | **21** | **5.4** | **84.9** |
| 5 | 16 | 4.1 | 89.0 |
| 6 | 9 | 2.3 | 91.3 |
| 7 | 15 | 3.8 | 95.2 |
| 8 | 19 | 4.8 | 100.0 |

Nearly half the sample scores zero, and the tail turns back up at 7–8. See §3.2 — this
shape is the reason to test proportional odds before committing to a single ordinal model.
Only 14.7% score 3 or 4, so the moderate/severe cut-off itself is comparatively
well-placed; the problem with the binary outcome is lost information, not an unstable
threshold.

**9. Barrier items, all three levels.** "Do not know" excluded, counts shown separately.

| Barrier | Never | Sometimes | Always | DK | n |
|---|---|---|---|---|---|
| Child refused food | 77 (18.9%) | 239 (58.7%) | **91 (22.4%)** | 0 | 407 |
| Nutritious food unavailable locally | 244 (60.4%) | 151 (37.4%) | 9 (2.2%) | 3 | 404 |
| Struggled to find time to prepare | 259 (64.0%) | 112 (27.7%) | 34 (8.4%) | 2 | 405 |
| Could not travel to market | 273 (67.9%) | 114 (28.4%) | 15 (3.7%) | 5 | 402 |
| Did not know what to give | 255 (67.6%) | 97 (25.7%) | 25 (6.6%) | **30** | 377 |
| Not permitted to go to market | 319 (79.2%) | 62 (15.4%) | 22 (5.5%) | 4 | 403 |
| Not permitted to decide purchases | 319 (78.8%) | 59 (14.6%) | 27 (6.7%) | 2 | 405 |
| HH member discouraged feeding | 340 (84.0%) | 49 (12.1%) | 16 (4.0%) | 2 | 405 |

The binary collapse merges Sometimes with Always. For child refusal that buries a
**22.4% Always group** inside an 81.1% "endorsed" figure, which is exactly why the item
lost its association (binary p = 0.064, ordinal p = 0.0006). Figure 4.10 must show all
three levels.

**10. Barrier scores.**

| Score | Range | n | Mean | Median | IQR |
|---|---|---|---|---|---|
| Total (8 items, α = 0.776) | 0–13 observed of 0–16 | 366 | 3.08 | 2 | 1–5 |
| Structural (I, J, M; α = 0.630) | 0–5 observed of 0–6 | 398 | 1.19 | 1 | 0–2 |
| Agency (K, L, N; α = 0.689) | 0–5 observed of 0–6 | 399 | 0.72 | 0 | 0–1 |

Total score distribution: 13.4% score 0, 24.6% score 1, and the tail runs to 13. The
agency subscale is the most zero-heavy at 67.4%, which is worth noting before it goes into
a model — it may need a hurdle treatment of its own, or to be used as an ordinal
three-level collapse rather than a 0–6 count.

**Summary — where dichotomising actually hurt.**

| Variable | Cost of the binary form |
|---|---|
| Meal frequency | **Severe.** 33.2% sit exactly on the cut-off |
| Child food-group score | **Severe.** 41.3% sit either side of the cut-off |
| Barrier items | **Severe.** Merges a large Always group into Sometimes |
| Household diet | **Severe.** Any split discards a well-spread 0–5 scale |
| Animal-source foods | **Moderate.** EFF collapses scores 1–5 into one bin |
| Unhealthy foods | **Moderate.** Hides the 15.7% who ate both categories |
| Fruit and vegetables | **Low.** 81% already sit at 0 or 1 |
| Sweet beverages | **Low.** 82.6% zero |
| EC-FIES outcome | **Moderate.** Threshold is well-placed; the loss is information, not stability |
