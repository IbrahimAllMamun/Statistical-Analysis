# ============================================================
# Project 15 - Visual impairment among Garo adults (N = 111)
# ------------------------------------------------------------
# Re-runs the three regression models that appear in Tables 5 and 6
# of doc/"Result_Ocular_ Farhana Bari.docx", keeping exactly the
# variable sets used there, with ONE change requested by the client:
# age enters as a 3-level group (18-30 / 31-49 / >49) instead of as
# a continuous year count.
#
#   Model 1  Refractive error        ~ logistic
#   Model 2  Anterior-segment disease ~ logistic
#   Model 3  Posterior-segment disease ~ Firth penalized logistic
#            (only 10 events, as in the source document)
#
# Output: doc/Tables5_6_rerun.docx      (the source .docx is left alone)
#         Data/ocular_clean.rds / .csv
#         doc/cleaning_log.txt
#
# Coding scheme supplied by the client:
#   Sex                    1 = Male, 2 = Female
#   History of ocular ...  through Family history of ocular disease:
#                          1 = Yes, 2 = No
#   Systemic disease and family history of systemic disease:
#                          "2" = No, any named condition = Yes
#   myopia .. end of sheet 1 = Yes, blank = No
# ============================================================

library(readxl)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)
library(forcats)
library(logistf)
library(flextable)
library(officer)

RAW_XLSX <- "Data/data.xlsx"
OUT_RDS  <- "Data/ocular_clean.rds"
OUT_CSV  <- "Data/ocular_clean.csv"
OUT_LOG  <- "doc/cleaning_log.txt"
OUT_DOCX <- "doc/Tables5_6_rerun.docx"

dir.create("doc",   showWarnings = FALSE)
dir.create("Graph", showWarnings = FALSE)

LOG <- character(0)
note <- function(...) { msg <- paste0(...); LOG <<- c(LOG, msg); message(msg) }

safe_write <- function(expr, path) {
  tryCatch({ force(expr); message("Saved -> ", path); invisible(TRUE) },
           error = function(e) {
             warning("COULD NOT WRITE ", path,
                     " - it is probably open in Excel or Word. Close it and re-run. (",
                     conditionMessage(e), ")", call. = FALSE, immediate. = TRUE)
             invisible(FALSE)
           })
}

# ----------------------------------------------------------
# 0.  Coding helpers
# ----------------------------------------------------------
txt <- function(x) str_squish(as.character(x))

# 1 = Yes, 2 = No, anything else missing
yn12 <- function(x) {
  v <- txt(x)
  factor(case_when(v == "1" ~ "Yes", v == "2" ~ "No", .default = NA_character_),
         levels = c("No", "Yes"))
}

# "2" = No, blank = missing, any named condition (HTN / DM / ...) = Yes
yn_named <- function(x) {
  v <- txt(x)
  factor(case_when(v == "2" ~ "No",
                   is.na(v) | v == "" ~ NA_character_,
                   .default = "Yes"),
         levels = c("No", "Yes"))
}

# tick-box columns: any entry = Yes, blank = No
ticked <- function(x) !is.na(x) & txt(x) != ""

# ----------------------------------------------------------
# 1.  Read and clean
# ----------------------------------------------------------
raw <- read_excel(RAW_XLSX, sheet = "Sheet1", col_types = "text", .name_repair = "minimal")
names(raw) <- str_squish(names(raw))
raw <- raw %>% filter(if_any(everything(), ~ !is.na(.x) & str_squish(.x) != ""))
note("Rows read from Sheet1: ", nrow(raw))

dat <- raw %>%
  transmute(
    id  = as.integer(txt(ID)),
    age = as.numeric(txt(Age)),

    # ---- client-specified age bands -------------------------------------
    age_grp = cut(age, breaks = c(-Inf, 30, 49, Inf),
                  labels = c("18-30", "31-49", ">49")),

    sex = factor(case_when(txt(Sex) == "1" ~ "Male",
                           txt(Sex) == "2" ~ "Female",
                           .default = NA_character_),
                 levels = c("Male", "Female")),

    education = factor(txt(`education level`), levels = as.character(1:6),
                       labels = c("Illiterate", "Primary school", "Middle school",
                                  "High school", "Intermediate/diploma", "Graduate")),

    # ---- history (1 = Yes, 2 = No) --------------------------------------
    hx_ocular_disease = yn12(`History of oculardiseases`),
    hx_ocular_surgery = yn12(`History of ocular surgery`),
    hx_ocular_injury  = yn12(`History of ocular injury`),
    smoking           = yn12(Smoking),
    alcohol           = yn12(Alcohole),
    betel             = yn12(`Betel Nut/ leaf`),
    fam_hx_ocular     = yn12(`Family history of ocular disease`),

    # ---- named-condition columns ----------------------------------------
    systemic_disease  = yn_named(`Systemic diseases (DM/ HTN)`),
    fam_hx_systemic   = yn_named(`Family history of systemic disease`),

    # ---- living conditions ----------------------------------------------
    housing  = factor(str_to_title(txt(`status of housing`)),
                      levels = c("Brick", "Bamboo", "Wood")),
    latrine  = yn12(`use of sanitary latrine`),
    nutrition = yn12(`proper nutrition`),

    # ---- visual acuity ---------------------------------------------------
    va_re = as.numeric(txt(`visual acuity RE`)),
    va_le = as.numeric(txt(`Visual acuity LE`)),

    # ---- individual diagnoses (tick-box: any entry = Yes) ----------------
    myopia        = ticked(myopia),
    hypermetropia = ticked(hypermetropia),
    astigmatism   = ticked(astigmatism),
    presbyopia    = ticked(pressbyopia),
    emmetropia    = ticked(Emetropia),
    not_improved  = ticked(`not improved`),

    cataract      = ticked(cataract),
    dry_eye       = ticked(`dry eye`),
    pterygium     = ticked(pterygium),
    growth        = ticked(growth),
    pseudophakia  = ticked(pseudophakia),
    corneal_opacity = ticked(`corneal opacity`),
    conjunctivitis  = ticked(conjunctivitis),
    dacryocystitis  = ticked(`chronic dacrayocystitis`),
    strabismus      = ticked(strabismus),
    pinguecula      = ticked(pinguicula),
    blepharitis     = ticked(Blepharitis),
    chalazion       = ticked(chalazion),

    myopic_fundus = ticked(`myopic Fundus`),
    glaucoma      = ticked(glaucoma),
    diabetic_retinopathy = ticked(`diabetic Retinopathy`),
    amd           = ticked(`age related macular degenaration`)
  ) %>%
  mutate(
    # ---- the three outcomes, per PATIENT --------------------------------
    refractive_error = factor(
      ifelse(myopia | hypermetropia | astigmatism, "Yes", "No"), levels = c("No", "Yes")),
    anterior_disease = factor(
      ifelse(cataract | dry_eye | pterygium | growth | pseudophakia | corneal_opacity |
               conjunctivitis | dacryocystitis | strabismus | pinguecula |
               blepharitis | chalazion, "Yes", "No"), levels = c("No", "Yes")),
    posterior_disease = factor(
      ifelse(myopic_fundus | glaucoma | diabetic_retinopathy | amd, "Yes", "No"),
      levels = c("No", "Yes")),
    across(c(refractive_error, anterior_disease, posterior_disease),
           ~ as.integer(.x == "Yes"), .names = "{.col}_bin")
  )

# ----------------------------------------------------------
# 2.  Cross-checks against the source document
# ----------------------------------------------------------
note("")
note("--- age bands (client's cut-points) ---")
walk2(names(table(dat$age_grp)), as.integer(table(dat$age_grp)),
      ~ note(sprintf("  %-6s %3d (%.1f%%)", .x, .y, 100 * .y / nrow(dat))))
note(sprintf("  mean age %.1f (SD %.1f)  [document: 39.7 +/- 15.4]",
             mean(dat$age), sd(dat$age)))

note("")
note("--- outcome counts: patients vs diagnoses ---")
diag_counts <- c(
  refractive = sum(dat$myopia) + sum(dat$hypermetropia) + sum(dat$astigmatism),
  anterior   = sum(dat$cataract) + sum(dat$dry_eye) + sum(dat$pterygium) + sum(dat$growth) +
    sum(dat$pseudophakia) + sum(dat$corneal_opacity) + sum(dat$conjunctivitis) +
    sum(dat$dacryocystitis) + sum(dat$strabismus) + sum(dat$pinguecula) +
    sum(dat$blepharitis) + sum(dat$chalazion),
  posterior  = sum(dat$myopic_fundus) + sum(dat$glaucoma) +
    sum(dat$diabetic_retinopathy) + sum(dat$amd))
pat_counts <- c(refractive = sum(dat$refractive_error_bin),
                anterior   = sum(dat$anterior_disease_bin),
                posterior  = sum(dat$posterior_disease_bin))
doc_counts <- c(refractive = 56, anterior = 61, posterior = 10)
for (k in names(pat_counts)) {
  note(sprintf("  %-11s patients %3d (%.1f%%) | diagnoses %3d | document reports %3d%s",
               k, pat_counts[[k]], 100 * pat_counts[[k]] / nrow(dat),
               diag_counts[[k]], doc_counts[[k]],
               ifelse(pat_counts[[k]] == doc_counts[[k]], "", "   <-- MISMATCH")))
}
note("  Where these differ, the document counted DIAGNOSES; a regression outcome")
note("  has to be one row per patient, so the patient count is what is modelled.")

# ----------------------------------------------------------
# 3.  Model specifications - the variable sets of Tables 5 and 6
# ----------------------------------------------------------
spec_main <- list(
  age_grp           = "Age group (years)",
  sex               = "Sex",
  hx_ocular_disease = "History of ocular disease",
  hx_ocular_injury  = "History of ocular injury",
  smoking           = "Smoking",
  alcohol           = "Alcohol consumption",
  betel             = "Betel nut/leaf consumption",
  fam_hx_ocular     = "Family history of ocular disease",
  fam_hx_systemic   = "Family history of systemic disease",
  housing           = "Housing status",
  latrine           = "Use of sanitary latrine",
  nutrition         = "Proper nutrition"
)

spec_post <- list(
  age_grp           = "Age group (years)",
  sex               = "Sex",
  hx_ocular_disease = "History of ocular disease",
  fam_hx_ocular     = "Family history of ocular disease"
)

# ----------------------------------------------------------
# 4.  Table helpers
# ----------------------------------------------------------
# A profile bound that ran off to infinity is shown as a bound, not a number.
ci_num <- function(x) {
  ifelse(!is.finite(x), "Inf",
         ifelse(x > 1000, ">1000", ifelse(x < 0.001, "<0.001", sprintf("%.3f", x))))
}
fmt_or <- function(e, l, h) sprintf("%.3f (%s-%s)", e, ci_num(l), ci_num(h))
fmt_p  <- function(p) ifelse(is.na(p), "-", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
NOT_EST <- "Not estimable (collinear)"

# Coefficient table from either a glm or a logistf fit, on the OR scale.
# glm drops perfectly collinear terms, leaving an NA coefficient that summary()
# omits entirely, so rows are matched by name rather than by position and an
# aliased term is carried through as NA for model_rows() to label.
coef_tbl <- function(fit) {
  if (inherits(fit, "logistf")) {
    return(data.frame(term = names(coef(fit)),
                      est  = exp(unname(coef(fit))),
                      lo   = exp(unname(fit$ci.lower)),
                      hi   = exp(unname(fit$ci.upper)),
                      p    = unname(fit$prob), stringsAsFactors = FALSE))
  }
  cf <- stats::coef(fit)
  sm <- summary(fit)$coefficients
  ci <- tryCatch(suppressMessages(stats::confint(fit)),       # profile likelihood
                 error = function(e) stats::confint.default(fit))
  if (is.null(dim(ci))) ci <- matrix(ci, nrow = 1, dimnames = list(rownames(sm), NULL))
  i_sm <- match(names(cf), rownames(sm))
  i_ci <- match(names(cf), rownames(ci))
  data.frame(term = names(cf),
             est  = exp(unname(cf)),
             lo   = exp(unname(ci[i_ci, 1])),
             hi   = exp(unname(ci[i_ci, 2])),
             p    = unname(sm[i_sm, 4]), stringsAsFactors = FALSE)
}

# one block of rows per variable, with an explicit reference level
model_rows <- function(fit, spec, d) {
  co <- coef_tbl(fit)
  out <- list()
  add <- function(v, or, p) out[[length(out) + 1]] <<-
    data.frame(Variable = v, OR = or, P = p, stringsAsFactors = FALSE)

  for (v in names(spec)) {
    x <- d[[v]]
    if (is.factor(x)) {
      add(spec[[v]], "", "")
      lv <- levels(x)
      for (i in seq_along(lv)) {
        if (i == 1) {
          add(paste0("    ", lv[i]), "Reference", "-")
        } else {
          r <- co[co$term == paste0(v, lv[i]), ]
          if (nrow(r) == 1 && is.finite(r$est))
            add(paste0("    ", lv[i]), fmt_or(r$est, r$lo, r$hi), fmt_p(r$p))
          else
            add(paste0("    ", lv[i]), NOT_EST, "-")
        }
      }
    } else {
      r <- co[co$term == v, ]
      if (nrow(r) == 1 && is.finite(r$est))
        add(spec[[v]], fmt_or(r$est, r$lo, r$hi), fmt_p(r$p))
      else
        add(spec[[v]], NOT_EST, "-")
    }
  }
  do.call(rbind, out)
}

# unadjusted (crude) odds ratios, one model per variable
univariable_rows <- function(outcome, spec, d, firth = FALSE) {
  blocks <- lapply(names(spec), function(v) {
    f <- stats::as.formula(paste(outcome, "~", v))
    fit <- if (firth) logistf(f, data = d, control = FIT_CTL, plcontrol = PL_CTL)
           else glm(f, data = d, family = binomial)
    model_rows(fit, spec[v], d)
  })
  do.call(rbind, blocks)
}

FIT_CTL <- logistf.control(maxit = 1000)
PL_CTL  <- logistpl.control(maxit = 1000)

# ----------------------------------------------------------
# 5.  The three models
# ----------------------------------------------------------
# `nutrition` is perfectly collinear with `latrine` (see the cross-tabulation in
# the log): the same 15 people lack both, the same 94 have both. Only one of the
# two can enter a model, so nutrition is left out of the formula - it keeps its
# row in the table, marked not estimable, and the latrine coefficient stands for
# both. Dropping it also recovers the 2 rows whose nutrition entry was blank.
COLLINEAR_DROP <- "nutrition"
model_vars <- setdiff(names(spec_main), COLLINEAR_DROP)

rhs_main <- paste(model_vars, collapse = " + ")
rhs_post <- paste(names(spec_post), collapse = " + ")

m_refractive <- glm(as.formula(paste("refractive_error_bin ~", rhs_main)),
                    data = dat, family = binomial)
m_anterior   <- glm(as.formula(paste("anterior_disease_bin ~", rhs_main)),
                    data = dat, family = binomial)
m_posterior  <- logistf(as.formula(paste("posterior_disease_bin ~", rhs_post)),
                        data = dat, control = FIT_CTL, plcontrol = PL_CTL)

note("")
note("--- model fit sizes (complete cases) ---")
note("  Model 1 refractive error      : n = ", nobs(m_refractive),
     ", events = ", sum(m_refractive$y))
note("  Model 2 anterior-segment      : n = ", nobs(m_anterior),
     ", events = ", sum(m_anterior$y))
note("  Model 3 posterior-segment     : n = ", nrow(m_posterior$data %||% dat),
     ", events = ", sum(dat$posterior_disease_bin))
note("  Rows drop out of Models 1-2 where betel nut or family history of")
note("  systemic disease was left blank on the form.")

# glm silently sets perfectly collinear terms to NA. Fit the full variable set
# once, purely to name which terms those are, then report what they collide with.
m_full  <- glm(as.formula(paste("refractive_error_bin ~",
                                paste(names(spec_main), collapse = " + "))),
               data = dat, family = binomial)
aliased <- names(coef(m_full))[is.na(coef(m_full))]
if (length(aliased)) {
  note("")
  note("--- COLLINEARITY: terms glm could not estimate ---")
  walk(aliased, ~ note("  ", .x))
  note("  Cross-tabulation of the two living-condition variables:")
  ct <- table(latrine = dat$latrine, nutrition = dat$nutrition, useNA = "ifany")
  walk(capture.output(print(ct)), ~ note("  ", .x))
  note("  Every participant without a sanitary latrine also lacks proper")
  note("  nutrition, and every participant with one has it - the two columns")
  note("  are the same variable. Only one can enter the model, which is why")
  note("  Table 5 of the source document prints an identical odds ratio on")
  note("  both rows.")
}

# ----------------------------------------------------------
# 6.  Assemble the tables
# ----------------------------------------------------------
t5_ref <- model_rows(m_refractive, spec_main, dat)
t5_ant <- model_rows(m_anterior,   spec_main, dat)
stopifnot(identical(t5_ref$Variable, t5_ant$Variable))

table5_df <- data.frame(
  Variable                              = t5_ref$Variable,
  `Refractive error aOR (95% CI)`       = t5_ref$OR,
  `p-value`                             = t5_ref$P,
  `Anterior-segment disease aOR (95% CI)` = t5_ant$OR,
  `p-value `                            = t5_ant$P,
  check.names = FALSE, stringsAsFactors = FALSE
)

t6_cor   <- univariable_rows("posterior_disease_bin", spec_post, dat, firth = FALSE)
t6_firth <- model_rows(m_posterior, spec_post, dat)
stopifnot(identical(t6_cor$Variable, t6_firth$Variable))

table6_df <- data.frame(
  Variable              = t6_cor$Variable,
  `COR (95% CI)`        = t6_cor$OR,
  `p-value`             = t6_cor$P,
  `Firth aOR (95% CI)`  = t6_firth$OR,
  `p-value `            = t6_firth$P,
  check.names = FALSE, stringsAsFactors = FALSE
)

mk_ft <- function(df, p_cols) {
  ft <- flextable(df) %>%
    bold(part = "header") %>%
    align(j = 2:ncol(df), align = "center", part = "all") %>%
    padding(padding.top = 2, padding.bottom = 2, part = "all") %>%
    fontsize(size = 9, part = "all")
  # row indices are resolved here rather than in a flextable formula, which
  # cannot see the loop variable
  for (j in p_cols) {
    pv  <- df[[j]]
    hit <- which(pv == "<0.001" | suppressWarnings(as.numeric(pv)) < 0.05)
    if (length(hit)) ft <- bold(ft, i = hit, j = j)
  }
  set_table_properties(ft, layout = "autofit", width = 1)
}

table5 <- mk_ft(table5_df, c(3, 5))
table6 <- mk_ft(table6_df, c(3, 5))

# ----------------------------------------------------------
# 7.  Export
# ----------------------------------------------------------
small <- fp_text(font.size = 8, italic = TRUE)
add_foot <- function(d, txt) body_add_fpar(d, fpar(ftext(txt, small)))

foot5 <- paste0(
  "aOR = adjusted odds ratio; CI = confidence interval. Multivariable logistic regression fitted ",
  "separately for each outcome, using the same variable set as Table 5 of the source document. ",
  "Age enters as a three-level group (18-30 / 31-49 / >49) rather than as a continuous year count, ",
  "with 18-30 years as the reference. Profile-likelihood confidence intervals. ",
  sprintf("Model n = %d (refractive error) and %d (anterior-segment disease) complete cases of %d; ",
          nobs(m_refractive), nobs(m_anterior), nrow(dat)),
  "rows with a blank betel-nut or family-history-of-systemic-disease entry drop out. ",
  "Proper nutrition is perfectly collinear with use of a sanitary latrine - the same 15 participants ",
  "lack both and the same 94 have both - so it cannot be estimated separately and the sanitary-latrine ",
  "odds ratio stands for both. The source document reports an identical odds ratio on those two rows ",
  "for the same reason. ",
  "p < 0.05 in bold."
)
foot6 <- paste0(
  "COR = crude odds ratio; aOR = adjusted odds ratio; CI = confidence interval. ",
  "Crude odds ratios come from one univariable logistic model per variable; the adjusted column is ",
  "Firth penalized logistic regression, used because only ",
  sum(dat$posterior_disease_bin), " participants had posterior-segment disease. ",
  "Age enters as a three-level group with 18-30 years as the reference. p < 0.05 in bold."
)
foot_outcome <- paste0(
  "NOTE ON OUTCOME COUNTS. Table 3 of the source document reports 56 refractive errors and 61 ",
  "anterior-segment diseases. Those are counts of DIAGNOSES, not of participants: 7 people carry ",
  "both myopia and astigmatism, and 11 carry two or three anterior-segment conditions. A regression ",
  "outcome is one row per participant, so the models below use ",
  sum(dat$refractive_error_bin), " refractive-error and ", sum(dat$anterior_disease_bin),
  " anterior-segment cases out of ", nrow(dat), ". Posterior-segment disease is unaffected at ",
  sum(dat$posterior_disease_bin), ". Estimates therefore differ from the published tables for this ",
  "reason as well as the change in how age is modelled."
)

doc <- read_docx() %>%
  body_add("Table 5. Multivariable logistic regression of factors associated with refractive error and anterior-segment disease among Garo adults",
           style = "heading 1") %>%
  body_add_flextable(table5) %>%
  add_foot(foot5) %>%
  add_foot(foot_outcome) %>%
  body_add_break() %>%
  body_add("Table 6. Logistic regression of factors associated with posterior-segment disease",
           style = "heading 1") %>%
  body_add_flextable(table6) %>%
  add_foot(foot6)

safe_write(print(doc, target = OUT_DOCX), OUT_DOCX)
safe_write(saveRDS(dat, OUT_RDS), OUT_RDS)
safe_write(write.csv(dat, OUT_CSV, row.names = FALSE, na = ""), OUT_CSV)

note("")
note("--- Table 5 ---")
walk(capture.output(print(table5_df, row.names = FALSE)), note)
note("")
note("--- Table 6 ---")
walk(capture.output(print(table6_df, row.names = FALSE)), note)

safe_write(writeLines(LOG, OUT_LOG), OUT_LOG)
