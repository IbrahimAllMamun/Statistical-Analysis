# ============================================================
# Metastatic Breast Cancer (V2) - Tables & KM graphs
# Data source: Data/cancer_data_fixed_v4.xlsx  (sheet "data", n = 135)
# ------------------------------------------------------------
# That file is NOT the client's imputed spreadsheet. It is written by
# ../V3/script_farhana_v4.R, which re-derives every analysis column
# from the raw questionnaire codes after the coding recheck, and copies
# the result here so both versions report the same numbers from one
# source. Re-run that script, not this one, when the data change; the
# file's second sheet ("changes") lists every variable it corrected.
#
# What that means for the tables below, against the previous run off
# Data/cancer_data_imputed.Farhana.xlsx:
#
#   * Brain and liver metastasis were transposed in the old columns.
#     Brain falls from 55 (40.7%) to 13 (9.6%) and liver rises from 14
#     to 55, so Table 2 and every subtype comparison that touches them
#     changes.
#   * Clinical subtype is now derived from ER/PR/HER2 instead of being
#     imputed as a variable of its own, so HER2-positive (61) equals
#     HR+/HER2+ (43) plus HR-/HER2+ (18). The old column disagreed with
#     the receptors in 53 of 135 rows, which is why the subtype strata
#     in Tables 4-5 and the KM panels move.
#   * Hormone therapy counts endocrine treatment recorded as currently
#     active as well as ever received: 42 patients (31.1%), not 20.
#   * Metastatic burden is counted from the patient's own site list.
#   * `prestage` and `causesrmetast` are the client's re-coded values,
#     so Table 5's prior-stage strata differ from the delivered run.
#
# Column names follow the corrected file: `subtype` (not
# clinical_subtype), `Opposite_breast` / `Other_site` (not
# opposite_breast / Others) and `event` (0/1) with `vital_status` as its
# text label. The superseded columns are absent from the file on
# purpose, so a stale reference fails here instead of quietly tabulating
# the values the recheck corrected.
#
# `surgery` is unchanged by the correction and is fully recorded in the
# current data (mastectomy 77, biopsy 47, no surgery 11). The note this
# header used to carry, that surgery held only "Mastectomy" and was not
# worth tabulating, described an earlier version of the spreadsheet and
# no longer applies.
#
# Outputs (kept separate from the .sav-based run):
#   doc/all_table_farhana.docx
#   Graph/Fig*_farhana.pdf
# ============================================================

library(readxl)
library(dplyr)
library(stringr)
library(forcats)
library(gtsummary)
library(survival)
library(survminer)
library(flextable)
library(officer)
library(cowplot)
library(broom)
library(pacman)
p_load(broom.helpers)

# Windows locks files that are open in Word; warn instead of dying half-way.
safe_write <- function(expr, path) {
  tryCatch({ force(expr); message("Saved -> ", path); invisible(TRUE) },
           error = function(e) {
             warning("COULD NOT WRITE ", path,
                     " - it is probably open in Word. Close it and re-run. (",
                     conditionMessage(e), ")", call. = FALSE, immediate. = TRUE)
             invisible(FALSE)
           })
}

# ----------------------------------------------------------
# 0.  Load & clean text -> ordered factors
#     The corrected file stores factors as their labels, so the work here
#     is only to fix level order (table row order and Cox reference
#     categories); no value is recoded.
# ----------------------------------------------------------
raw <- read_excel("Data/cancer_data_fixed_v4.xlsx", sheet = "data")

stopifnot(nrow(raw) == 135)
if (!"subtype" %in% names(raw))
  stop("Data/cancer_data_fixed_v4.xlsx is missing `subtype` - it looks like the old ",
       "imputed spreadsheet. Re-run ../V3/script_farhana_v4.R to regenerate it.")

yn <- function(x) factor(str_to_title(as.character(x)), levels = c("No", "Yes"))


data <- raw %>%
  mutate(
    # ── grouping & subtype (derived from the receptors in V3) ──
    mbc_type = factor(mbc_type, levels = c("De novo MBC", "Recurrent MBC")),
    subtype  = factor(subtype,
                      levels = c("HR+/HER2+", "HR+/HER2-", "HR-/HER2+", "HR-/HER2-")),

    # ── demographics ──
    age_grp   = factor(age_grp, levels = c("<35", "35-45", "45-55", "55+")),
    Residence = factor(str_to_title(Residence), levels = c("Urban", "Rural")),
    Education = factor(Education,
                       levels = c("Illiterate", "5 or less", ">5-10 years",
                                  ">10-12 years", "Graduate and above")),
    Income    = factor(Income,
                       levels = c("<5000", "5001-10000", "10001-15000", ">15000")),
    Smoking   = factor(Smoking),

    # ── receptors (normalise case) ──
    ER   = factor(str_to_title(ER),   levels = c("Positive", "Negative")),
    PR   = factor(str_to_title(PR),   levels = c("Positive", "Negative")),
    her2 = factor(str_to_title(her2), levels = c("Positive", "Negative")),

    # ── tumour grade ──
    grading = factor(grading, levels = c("Grade 1", "Grade 2", "Grade 3")),

    # ── metastatic burden (counted from the site list in V3) ──
    mburden = factor(mburden, levels = c("1 site", "2-3 sites", ">3 sites")),

    # ── metastasis sites (questionnaire codes 1-6) ──
    Lung = yn(Lung), Liver = yn(Liver), Brain = yn(Brain),
    Bone = yn(Bone), Opposite_breast = yn(Opposite_breast), Other_site = yn(Other_site),

    # ── treatments ──
    Any_Systemic_Tx         = yn(Any_Systemic_Tx),
    Chemotherapy            = yn(Chemotherapy),
    Hormone_Therapy         = yn(Hormone_Therapy),
    Targeted_Therapy        = yn(Targeted_Therapy),
    Palliative_Radiotherapy = yn(Palliative_Radiotherapy),
    Zoledronic_Acid         = yn(Zoledronic_Acid),

    # ── delay / response / adherence ──
    delayrx = factor(str_to_title(delayrx), levels = c("Yes", "No")),
    symptomaticresponse = factor(symptomaticresponse, levels = c("Adequate", "Inadequate")),
    radiologivcalresponse = factor(radiologivcalresponse,
                                   levels = c("Stable", "Progressive disease",
                                              "Partial response", "Complete response")),
    skip = factor(skip, levels = c("Non Adherent", "Adherent")),

    # ── prior stage (Recurrent only) ──
    prestage = factor(prestage, levels = c("Stage 1", "Stage 2", "Stage 3")),

    surgery = factor(surgery, levels = c("Mastectomy", "Lumpectomy", "Biopsy", "No Surgery")),

    # ── survival outcome ──
    # `event` is the 0/1 death indicator taken from `cs`; os_time is capped
    # at 24 months and, for censored patients, is still the symptom-to-
    # metastasis interval - see the caution footnoted under Table 4.
    event   = as.numeric(event),
    event2   = factor(event, labels = c("Alive", "Death")),
    os_time = as.numeric(os_time)
  )

# ============================================================
# TABLE 1 - Patient & tumour characteristics by MBC type
# ============================================================
tab1 <- data %>%
  filter(!is.na(mbc_type)) %>%
  select(mbc_type, age_grp, Residence, Education, Income, Smoking,
         ER, PR, her2, subtype, grading, surgery, cs) %>%
  tbl_summary(
    by = mbc_type,
    label = list(
      age_grp          ~ "Age group",
      Residence        ~ "Residence",
      Education        ~ "Education level",
      Income           ~ "Monthly income",
      Smoking          ~ "Smoking status",
      ER               ~ "ER status",
      PR               ~ "PR status",
      her2             ~ "HER2 status",
      subtype          ~ "Clinical subtype",
      grading          ~ "Tumour grade",
      surgery          ~ "Surgery",
      cs               ~ "Status"
    ),
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no"
  ) %>%
  add_p(test = list(all_categorical() ~ "chisq.test"),
        pvalue_fun = label_style_pvalue(digits = 3)) %>%
  add_overall(last = FALSE) %>%
  bold_labels() %>%
  modify_header(label ~ "**Characteristic**") %>%
  modify_spanning_header(c(stat_1, stat_2) ~ "**MBC Type**") %>%
  modify_caption("Table 1. Patient characteristics and clinical subtype by MBC type")

# ============================================================
# TABLE 2 - Disease/metastasis characteristics by MBC type
# ============================================================
tab2 <- data %>%
  filter(!is.na(mbc_type)) %>%
  select(mbc_type, mburden, Lung, Liver, Brain, Bone, Opposite_breast, Other_site) %>%
  tbl_summary(
    by = mbc_type,
    label = list(
      mburden         ~ "Metastatic burden (no. of sites)",
      Lung            ~ "Lung metastasis",
      Liver           ~ "Liver metastasis",
      Brain           ~ "Brain (CNS) metastasis",
      Bone            ~ "Bone metastasis",
      Opposite_breast ~ "Opposite breast metastasis",
      Other_site      ~ "Other site"
    ),
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no"
  ) %>%
  add_p(test = list(all_categorical() ~ "chisq.test"),
        pvalue_fun = label_style_pvalue(digits = 3)) %>%
  add_overall(last = FALSE) %>%
  bold_labels() %>%
  modify_header(label ~ "**Disease Characteristic**") %>%
  modify_spanning_header(c(stat_1, stat_2) ~ "**MBC Type**") %>%
  modify_caption("Table 2. Disease and metastasis characteristics by MBC type")

# ============================================================
# TABLE 3 - Treatment patterns by MBC type
# ============================================================
tab3 <- data %>%
  filter(!is.na(mbc_type)) %>%
  select(mbc_type, Any_Systemic_Tx, Chemotherapy, Hormone_Therapy, Targeted_Therapy,
         Palliative_Radiotherapy, Zoledronic_Acid,
         delayrx, symptomaticresponse, radiologivcalresponse, skip) %>%
  tbl_summary(
    by = mbc_type,
    label = list(
      Any_Systemic_Tx         ~ "Any systemic treatment",
      Chemotherapy            ~ "Chemotherapy",
      Hormone_Therapy         ~ "Hormonal therapy",
      Targeted_Therapy        ~ "Targeted therapy",
      Palliative_Radiotherapy ~ "Palliative radiotherapy",
      Zoledronic_Acid         ~ "Zoledronic acid",
      delayrx                 ~ "Delay in treatment initiation",
      symptomaticresponse     ~ "Symptomatic response",
      radiologivcalresponse   ~ "Radiological response",
      skip                    ~ "Treatment adherence"
    ),
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no"
  ) %>%
  add_p(test = list(all_categorical() ~ "chisq.test"),
        pvalue_fun = label_style_pvalue(digits = 3)) %>%
  add_overall(last = FALSE) %>%
  bold_labels() %>%
  modify_header(label ~ "**Treatment**") %>%
  modify_spanning_header(c(stat_1, stat_2) ~ "**MBC Type**") %>%
  modify_caption("Table 3. Treatment patterns by MBC type")

# ============================================================
# TABLE 4 - Median OS + Cox HR by MBC type (overall & by subtype)
# ============================================================
get_survival_stats <- function(df, subtype_label = "Overall") {
  df <- df %>% filter(!is.na(os_time), !is.na(event), !is.na(mbc_type))
  if (nrow(df) < 5 | length(unique(df$mbc_type)) < 2) return(NULL)

  km  <- survfit(Surv(os_time, event) ~ mbc_type, data = df)
  med <- summary(km)$table[, "median"]
  ns  <- as.integer(summary(km)$table[, "records"])

  cox_u <- coxph(Surv(os_time, event) ~ mbc_type, data = df)
  hr_u  <- exp(coef(cox_u)); ci_u <- exp(confint(cox_u))
  p_u   <- summary(cox_u)$coefficients[, "Pr(>|z|)"]

  df_adj <- df %>% filter(!is.na(age_grp), !is.na(mburden), !is.na(Any_Systemic_Tx))
  cox_a <- tryCatch(
    coxph(Surv(os_time, event) ~ mbc_type + age_grp + mburden + Residence + Education + grading + Any_Systemic_Tx,
          data = df_adj),
    error = function(e) NULL)
  if (!is.null(cox_a)) {
    idx  <- grep("mbc_type", names(coef(cox_a)))
    hr_a <- exp(coef(cox_a))[idx]
    ci_a <- exp(confint(cox_a))[idx, , drop = FALSE]
    p_a  <- summary(cox_a)$coefficients[idx, "Pr(>|z|)"]
  } else { hr_a <- NA; ci_a <- matrix(NA, 1, 2); p_a <- NA }

  tibble(
    `Clinical Subtype`   = c(subtype_label, ""),
    Group                = c("De novo MBC", "Recurrent MBC"),
    N                    = ns,
    `Median OS (months)` = round(med, 1),
    `HR (unadjusted)`    = c("Reference", sprintf("%.2f (%.2f-%.2f)", hr_u, ci_u[1,1], ci_u[1,2])),
    `P (unadj.)`         = c("", ifelse(p_u < 0.001, "<0.001", round(p_u, 3))),
    `HR (adjusted)`      = c("Reference", ifelse(!is.na(hr_a),
                             sprintf("%.2f (%.2f-%.2f)", hr_a, ci_a[1,1], ci_a[1,2]), "-")),
    `P (adj.)`           = c("", ifelse(!is.na(p_a),
                             ifelse(p_a < 0.001, "<0.001", round(p_a, 3)), "-"))
  )
}

tab4_data <- bind_rows(
  get_survival_stats(data %>% filter(!is.na(mbc_type)),               "Overall"),
  get_survival_stats(data %>% filter(subtype == "HR+/HER2+"), "HR+/HER2+"),
  get_survival_stats(data %>% filter(subtype == "HR+/HER2-"), "HR+/HER2-"),
  get_survival_stats(data %>% filter(subtype == "HR-/HER2+"), "HR-/HER2+"),
  get_survival_stats(data %>% filter(subtype == "HR-/HER2-"), "HR-/HER2-")
)

tab4_ft <- flextable(tab4_data) %>%
  merge_v(j = "Clinical Subtype") %>%
  valign(j = "Clinical Subtype", valign = "top") %>%
  bold(part = "header") %>% bold(j = "Clinical Subtype") %>%
  hline(i = c(2, 4, 6, 8), border = officer::fp_border(color = "grey70")) %>%
  autofit() %>% theme_booktabs() %>%
  set_caption("Table 4. Median overall survival and hazard ratios - de novo vs. Recurrent MBC")

# ============================================================
# TABLE 5 - Prior disease stage sub-analysis (Cox)
# ============================================================
data_sub <- data %>%
  filter(!is.na(os_time), !is.na(event)) %>%
  mutate(
    prior_tx_group = case_when(
      mbc_type == "De novo MBC"                                             ~ "De novo MBC",
      mbc_type == "Recurrent MBC" & prestage == "Stage 3"                   ~ "Recurrent - Prior Stage 3",
      mbc_type == "Recurrent MBC" & prestage %in% c("Stage 1", "Stage 2")   ~ "Recurrent - Prior Stage 1/2",
      mbc_type == "Recurrent MBC" & is.na(prestage)                         ~ "Recurrent - Stage unknown",
      .default = NA_character_
    ) %>% factor(levels = c("De novo MBC", "Recurrent - Prior Stage 3",
                            "Recurrent - Prior Stage 1/2", "Recurrent - Stage unknown"))
  ) %>%
  filter(!is.na(prior_tx_group))

cox_sub <- coxph(
  Surv(os_time, event) ~ prior_tx_group + age_grp + mburden + Residence + Education + grading,
  data = data_sub)

tab5 <- tbl_regression(cox_sub, exponentiate = TRUE, include = "prior_tx_group",
                       label = list(prior_tx_group ~ "MBC group / prior stage")) %>%
  bold_p(t = 0.05) %>% bold_labels() %>%
  modify_header(label ~ "**Group**") %>%
  modify_caption("Table 5. Hazard ratios by MBC type and prior disease stage")

# ============================================================
# EXPORT - all tables to one Word document
# ============================================================
# Footnotes are part of the deliverable: every table below moved when the
# corrected dataset replaced the imputed spreadsheet, and the reader has to
# be able to see why without opening the scripts.
fn <- function(x) fpar(ftext(x, prop = fp_text(font.size = 9, italic = TRUE)))

# Several of these cross-tabulations have a cell whose expected count is under
# 5 - `Any_Systemic_Tx` has only 4 untreated patients, `mburden` only 5 with >3
# sites - and R warns that the chi-square approximation may be incorrect.  The
# test is left as the manuscript specifies it, but the rows it affects are
# named in the footnote rather than left for the reader to discover.
sparse_note <- function(vars, labels) {
  bad <- vars[vapply(vars, function(v) {
    tab <- table(data[[v]], data$mbc_type)
    tab <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]
    nrow(tab) > 1 && ncol(tab) > 1 &&
      min(suppressWarnings(chisq.test(tab)$expected)) < 5
  }, logical(1))]
  if (!length(bad)) return("")
  paste0(" The chi-square approximation is unreliable for ",
         knitr::combine_words(unlist(labels[bad])),
         ", where an expected cell count falls below 5; those p-values are approximate ",
         "and an exact test would be preferable.")
}
sparse_labels <- list(
  age_grp = "age group", Residence = "residence", Education = "education",
  Income = "income", Smoking = "smoking", ER = "ER status", PR = "PR status",
  her2 = "HER2 status", subtype = "clinical subtype", grading = "tumour grade",
  surgery = "surgery", mburden = "metastatic burden", Lung = "lung metastasis",
  Liver = "liver metastasis", Brain = "brain metastasis", Bone = "bone metastasis",
  Opposite_breast = "opposite-breast metastasis", Other_site = "other site",
  Any_Systemic_Tx = "any systemic treatment", Chemotherapy = "chemotherapy",
  Hormone_Therapy = "hormonal therapy", Targeted_Therapy = "targeted therapy",
  Palliative_Radiotherapy = "palliative radiotherapy",
  Zoledronic_Acid = "zoledronic acid", delayrx = "delay in treatment",
  symptomaticresponse = "symptomatic response",
  radiologivcalresponse = "radiological response", skip = "treatment adherence")

n_her2 <- sum(data$her2 == "Positive")

doc <- read_docx() %>%
  body_add("Table 1", style = "heading 1") %>%
  body_add_flextable(tab1 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Chi-square test. Clinical subtype is derived from ER, PR and HER2, so HER2-positive (",
    n_her2, ") equals HR+/HER2+ (", sum(data$subtype == "HR+/HER2+"), ") plus HR-/HER2+ (",
    sum(data$subtype == "HR-/HER2+"), "); the subtype column used previously was imputed as a ",
    "separate variable and contradicted the receptors in 53 of 135 patients. ER, PR and HER2 ",
    "were missing for 83, 83 and 86 patients respectively and are multiply imputed, so receptor ",
    "and subtype frequencies should be read with that in mind. Every cross-check behind this ",
    "table is logged in ../V3/doc/cleaning_log.txt.",
    sparse_note(c("age_grp", "Residence", "Education", "Income", "Smoking", "ER", "PR",
                  "her2", "subtype", "grading", "surgery"), sparse_labels)))) %>%
  body_add("") %>%
  body_add("Table 2", style = "heading 1") %>%
  body_add_flextable(tab2 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Chi-square test. Metastatic sites are taken from each patient's recorded site list using ",
    "the questionnaire codes (1 lung, 2 brain, 3 liver, 4 bone, 5 opposite breast, 6 other). ",
    "Brain and liver were transposed in the previous version of this table: brain metastasis is ",
    sum(data$Brain == "Yes"), " (", sprintf("%.1f", 100 * mean(data$Brain == "Yes")),
    "%), not 55, and liver is ", sum(data$Liver == "Yes"), " (",
    sprintf("%.1f", 100 * mean(data$Liver == "Yes")), "%), not 14. Metastatic burden is counted ",
    "from the same site list.",
    sparse_note(c("mburden", "Lung", "Liver", "Brain", "Bone", "Opposite_breast",
                  "Other_site"), sparse_labels)))) %>%
  body_add("") %>%
  body_add("Table 3", style = "heading 1") %>%
  body_add_flextable(tab3 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Chi-square test. Hormone therapy counts a patient as treated if endocrine therapy appears ",
    "either in treatment ever received or in current active treatment: ",
    sum(data$Hormone_Therapy == "Yes"), " patients (",
    sprintf("%.1f", 100 * mean(data$Hormone_Therapy == "Yes")),
    "%), where the previous version counted the former only and reported 20. No ",
    "hormone-receptor-negative patient is counted as treated. Targeted therapy and zoledronic ",
    "acid are carried over unchanged and remain unverified: the questionnaire assigns code 6 to ",
    "targeted therapy and defines no code for zoledronic acid, while these columns were built ",
    "from codes 5 and 6 respectively.",
    sparse_note(c("Any_Systemic_Tx", "Chemotherapy", "Hormone_Therapy", "Targeted_Therapy",
                  "Palliative_Radiotherapy", "Zoledronic_Acid", "delayrx",
                  "symptomaticresponse", "radiologivcalresponse", "skip"), sparse_labels)))) %>%
  body_add("") %>%
  body_add("Table 4", style = "heading 1") %>%
  body_add_flextable(tab4_ft %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Cox proportional-hazards regression, de novo MBC as reference; adjusted for age group, ",
    "metastatic burden, residence, education, tumour grade and any systemic treatment. Deaths ",
    "(n = ", sum(data$event), ") are taken from the recorded current disease status."))) %>%
  body_add_fpar(fn(paste0(
    "CAUTION: for the ", sum(data$event == 0), " patients who had not died, the survival time ",
    "used here is the interval from first symptom to metastasis, not time under observation ",
    "after metastasis, and loss to follow-up is not recorded anywhere in the dataset. This is ",
    "inherited from the delivered data and needs a last-contact date to correct. The hazard ",
    "ratios and the Kaplan-Meier figures should not be published until it is fixed."))) %>%
  body_add("") %>%
  body_add("Table 5", style = "heading 1") %>%
  body_add_flextable(tab5 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Prior stage is recorded for all ",
    sum(!is.na(data$prestage) & data$mbc_type == "Recurrent MBC"),
    " patients with recurrent MBC and is undefined for de novo disease, except for ",
    sum(!is.na(data$prestage) & data$mbc_type == "De novo MBC"),
    " patient classified as de novo who also carries a prior stage. Stage values are the ",
    "investigators' re-coded ones and differ from the previously delivered run in nine ",
    "patients. The same survival-time caution as Table 4 applies.")))

safe_write(print(doc, target = file.path("doc", "all_table_farhana.docx")),
           "doc/all_table_farhana.docx")



# ============================================================
# KM PLOTS - overall survival by MBC type (± by subtype)
# ============================================================
km_plot <- function(df, title = "") {
  df <- df %>% filter(!is.na(os_time), !is.na(event), !is.na(mbc_type))
  if (nrow(df) < 5 | length(unique(df$mbc_type)) < 2) {
    message("Skipping '", title, "': insufficient data"); return(invisible(NULL))
  }
  fit <- survfit(Surv(os_time, event) ~ mbc_type, data = df)
  ggsurvplot(fit, data = df, pval = TRUE, pval.size = 4,
             conf.int = TRUE, conf.int.alpha = 0.15,
             risk.table = TRUE, risk.table.height = 0.28,
             xlab = "Months since diagnosis", ylab = "Overall survival probability",
             title = title, legend.title = "",
             legend.labs = c("De novo MBC", "Recurrent MBC"),
             palette = c("#2166AC", "#1baf7a"),
             ggtheme = theme_classic(base_size = 12), surv.median.line = "hv")
}

km_overall   <- km_plot(data %>% filter(!is.na(mbc_type)), "")
km_hrp_her2p <- km_plot(data %>% filter(subtype == "HR+/HER2+"), "HR+/HER2+")
km_hrp_her2n <- km_plot(data %>% filter(subtype == "HR+/HER2-"), "HR+/HER2-")
km_hrn_her2p <- km_plot(data %>% filter(subtype == "HR-/HER2+"), "HR-/HER2+")
km_hrn_her2n <- km_plot(data %>% filter(subtype == "HR-/HER2-"), "HR-/HER2-")

save_km_pdf <- function(km_obj, filepath, width = 8, height = 6) {
  if (is.null(km_obj)) return(invisible(NULL))
  combined <- cowplot::plot_grid(ggplotGrob(km_obj$plot), ggplotGrob(km_obj$table),
                                 ncol = 1, rel_heights = c(0.72, 0.28))
  safe_write({
    cairo_pdf(filepath, width = width, height = height, onefile = TRUE)
    on.exit(dev.off(), add = TRUE)
    print(combined)
  }, filepath)
}

save_km_pdf(km_overall,   "Graph/Fig1_KM_Overall_v2.pdf")
save_km_pdf(km_hrp_her2p, "Graph/Fig2_KM_HR+_HER2+_farhana.pdf")
save_km_pdf(km_hrn_her2p, "Graph/Fig2_KM_HR-_HER2+_farhana.pdf")
save_km_pdf(km_hrp_her2n, "Graph/Fig3_KM_HR+_HER2-_farhana.pdf")
save_km_pdf(km_hrn_her2n, "Graph/Fig4_KM_HR-_HER2-_farhana.pdf")

# subtype panels combined
km_panels <- Filter(Negate(is.null), list(km_hrp_her2p, km_hrp_her2n, km_hrn_her2p, km_hrn_her2n))
if (length(km_panels) > 0) {
  panel_grobs <- lapply(km_panels, function(p)
    cowplot::plot_grid(ggplotGrob(p$plot), ggplotGrob(p$table), ncol = 1, rel_heights = c(0.72, 0.28)))
  combined_panels <- cowplot::plot_grid(plotlist = panel_grobs, ncol = 2)
  safe_write({
    cairo_pdf("Graph/Fig5_KM_by_Subtype_farhana.pdf", width = 14, height = 10, onefile = TRUE)
    on.exit(dev.off(), add = TRUE)
    print(combined_panels)
  }, "Graph/Fig5_KM_by_Subtype_farhana.pdf")
}

status_graph <- data %>%
  mutate(
    cs = factor(
      cs,
      levels = c(
        "Disease free",
        "Alive with disease",
        "Death"
      )
    )
  ) %>% 
  ggplot(aes(x = cs, fill = mbc_type)) +
  geom_bar(
    position = "dodge",
    colour = "black"
  ) +
  geom_text(
    aes(label = after_stat(count)),
    stat = "count",
    position = position_dodge(width = 0.9),
    vjust = -0.3,
    size = 4
  ) +
  scale_fill_manual(
    values = c("#2166AC", "#1baf7a")
  ) +
  labs(
    x = "Status",
    y = "Frequency",
    fill = "MBC Type"
  ) +
  theme_minimal()


ggsave("Graph/Fig4_status.pdf", plot = status_graph, height = 6,width = 8,dpi = 300)

message("\n=== All outputs rebuilt from Data/cancer_data_fixed_v4.xlsx ===")
