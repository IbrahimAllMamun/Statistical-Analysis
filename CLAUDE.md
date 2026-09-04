# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A collection of independent freelance biostatistics engagements, mostly medical and
epidemiological studies destined for journal publication. Each top-level directory is a
**self-contained consulting job with no shared code** — there is no package, no build, no
test suite, and no dependency lockfile. `Project-N` folders are the analysis engagements
(numbered in rough chronological order); `Litigation/` and `Fastapi Test/` are R
flexdashboard + ODBC/SQL work and follow different conventions; `Binning/` is credit
scorecard work; `template/` holds scratch variable-naming notes, not runnable code.

Work happens inside one project folder at a time. Do not refactor across projects or
extract shared helpers — duplication between projects is deliberate, because each was
delivered separately and must stay reproducible on its own.

## Running R

**R 4.4.1 is broken** — `C:\Program Files\R\R-4.4.1\bin` contains only DLLs, no
`Rscript.exe`. Use R 4.6.1, and set `R_LIBS_USER` explicitly because the 4.6 user library
is not on the default `.libPaths()`:

```bash
cd "Project-15 ---" && R_LIBS_USER="$LOCALAPPDATA/R/win-library/4.6" "/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" script.R
```

Scripts use paths relative to the project folder (`Data/...`, `doc/...`), so always run
from inside the project directory, not the repo root.

Packages compiled for R 4.4 (`win-library/4.4`, `4.5`) **cannot** be reused — they fail
with a `LoadLibrary` error on `rlang.dll`. There is no Rtools installed, so anything that
needs compiling fails with `gcc: command not found`; install with
`install.packages(pkg, type = "binary")` to pull the CRAN Windows binary instead.

## Project layout

Most `Project-N` folders follow this convention:

| Folder | Contents |
|---|---|
| `Data/` | Client's raw data — SPSS `.sav`, Excel `.xlsx`, Stata `.dta`. Plus cleaned `.rds`/`.csv` written by the scripts. |
| `Materials/` | The reference paper being replicated (PDF), or the client's questionnaire/protocol. |
| `doc/` | **Client-authored** draft manuscripts and results documents, *and* the Word tables the scripts generate. |
| `Graph/` | Generated figures (PNG). |

Scripts are typically `script.R` or `analysis.R` (cleaning + tables) and `graph.R`
(figures), sometimes an `analysis.Rmd`. Where a project has `V1/`, `V2/`, `V3/`
subfolders (Project-7), those are successive re-analyses after client review — the highest
version is current.

**`doc/` mixes inputs and outputs.** Before writing anything there, check whether the
filename is a client document. Never overwrite a client's manuscript; write generated
tables to a clearly distinct name (e.g. `doc/Tables5_6_rerun.docx`).

## The typical engagement

The client supplies raw data plus either a reference paper (`Materials/*.pdf`) whose
tables are to be reproduced on their own cohort, or their own draft results document
(`doc/*.docx`) whose analysis is to be re-run or corrected. The deliverable is a Word file
of publication-ready tables, sometimes with figures.

Read the reference paper or results document **first** — it defines the outcome
definitions, the variable sets for each model, and the statistical tests. Match its choices
(median (IQR) vs mean (SD), which rows get a t-test vs Mann-Whitney) unless the data make
that impossible.

## Analysis stack

`dplyr`/`tidyverse` + `stringr`/`forcats` for cleaning; `haven` (SPSS/Stata), `readxl` or
`openxlsx` (Excel), `labelled`.

Tables: **`gtsummary`** (`tbl_summary`, `tbl_regression`, `add_p`, `add_overall`,
`tbl_merge`, `tbl_stack`) piped through `as_flex_table()` into **`flextable` + `officer`**,
which assembles the `.docx`. When a model type has no gtsummary tidier (e.g. `logistf`),
build the rows manually into a `flextable` instead — see `Project-15 ---/script.R`.

Modelling: `survival`/`survminer` (Cox, Kaplan-Meier), `logistf` (Firth penalized logistic,
for rare outcomes and separation), `pROC` (ROC/AUC/Youden cut-offs), `broom`, `mice`
(imputation).

## Working with the raw data

These are hand-entered clinical spreadsheets, not clean exports. Expect, and check for:

- **Per-project coding schemes that only the client knows.** `1 = Yes, 2 = No` in one block
  of columns, `1 = Yes, blank = No` tick-boxes in another, free text elsewhere. Ask if the
  scheme is not written down; it is rarely inferable.
- **Free-text yes/no with mixed case and typos** (`Yes`/`yes`/`YES`, `Reswpiratory`).
  Normalise with `str_to_lower(str_squish(x))` and match on a prefix or `str_detect`,
  not on equality.
- **Header rows that are not row 1.** Excel sheets often carry a section banner, a label
  row, a coding-scheme row and a spacer before the data starts.
- **Hand-typed dates** in `dd.mm.yy` with `.`, `,` and `/` separators, and year typos that
  put discharge before admission.
- **Values that contradict their column label** — temperatures labelled °C but recorded in
  °F, glucose labelled mg/dL but recorded in mmol/L.
- **Derived columns the client computed by hand** that disagree with the raw inputs.
  Re-derive from the raw values and log the disagreements rather than trusting the entry.

Always cross-check derived counts against the source document's own tables before
modelling, and report mismatches. Two real examples worth knowing about: a document
reported outcome prevalences that were counts of *diagnoses* rather than of *patients*
(patients with two conditions were double counted); and two variables that looked distinct
were perfectly collinear, which is why the published table printed an identical odds ratio
on both rows.

Windows locks files open in Word or Excel. Wrap file writes so a locked output warns
instead of aborting the run half-way — see `safe_write()` in `Project-14 ---/script.R`.

## Script conventions

Scripts are written to be read by the client's statistician, not just executed:

- A block comment header naming the data source, what the script produces, and every
  analytic decision or deviation from the reference paper.
- Numbered sections (`# 1. Read`, `# 2. Clean`, ...) with `# ---` rules.
- Inline comments explaining *why* a non-obvious choice was made, especially where a
  statistical assumption was forced by the data.
- Explicit `factor(levels = ...)` on every categorical so table row order is deterministic
  and reference levels in models are intentional.
- A running log written to `doc/cleaning_log.txt` recording row counts, missingness,
  repaired values and data-quality flags.

Table footnotes are part of the deliverable. State the test used, the reference category,
what an unestimable confidence bound means, and any variable that had to be dropped.

Figures use an Okabe-Ito colour-blind-safe palette; the current client has asked for **no
red anywhere** (`#0072B2` blue, `#E69F00` amber, `#009E73` green).

## Statistical judgement calls that recur

- **Separation / rare outcomes.** Several datasets contain predictors that perfectly split
  the outcome, so `glm` reports "did not converge" and pushes coefficients to infinity. Use
  `logistf` (Firth) and say so in the footnote. Note that a perfect separator as a
  *covariate* makes every other coefficient unidentifiable — it can only be the exposure.
- Report profile-likelihood confidence bounds that run to infinity as `">1000"` /
  `"<0.001"` rather than printing spurious precision.
- Flag rather than silently fix: implausible lab values, ages outside the stated inclusion
  criteria, placeholder values repeated across most rows.

## Commits

Present-tense summaries scoped to the engagement: `Project 14/ Analysis Delivered`,
`Project 7/V3 Done Review`, `Initated Project 15`. Data files are committed alongside code.
