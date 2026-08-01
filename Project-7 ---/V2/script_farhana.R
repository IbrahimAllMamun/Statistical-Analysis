# ============================================================
# Metastatic Breast Cancer (V2) - Tables & KM graphs
# Data source: Data/cancer_data_imputed.Farhana.xlsx
# ------------------------------------------------------------
# This is Farhana's fully-imputed dataset (no missing biomarker
# data). It already contains the derived analysis columns
# (mbc_type, clinical_subtype, metastasis sites, treatments,
# os_time, status ...), stored as text labels. This script only
# normalises the text into ordered factors and then reproduces
# the same Tables 1-5 and Kaplan-Meier figures as script.R.
#
# Outputs (kept separate from the .sav-based run):
#   Doc/all_table_farhana.docx
#   Graph/Fig*_farhana.pdf
#
# Note: the xlsx `surgery` column is largely empty (only
# "Mastectomy" recorded), so surgery is omitted from Table 1
# (it is not part of the manuscript comparison table either).
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

# ----------------------------------------------------------
# 0.  Load & clean text -> ordered factors
# ----------------------------------------------------------
raw <- read_excel("Data/cancer_data_imputed.Farhana.xlsx")

yn <- function(x) factor(str_to_title(as.character(x)), levels = c("No", "Yes"))

data <- raw %>%
  mutate(
    # ── grouping & subtype (already derived) ──
    mbc_type = factor(mbc_type, levels = c("De novo MBC", "Recurrent MBC")),
    clinical_subtype = factor(clinical_subtype,
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

    # ── metastatic burden (clean ">3*" variants) ──
    mburden = case_when(
      str_detect(mburden, "^>3")     ~ ">3 sites",
      str_detect(mburden, "^2-3")    ~ "2-3 sites",
      str_detect(mburden, "^1")      ~ "1 site",
      .default = NA_character_
    ) %>% factor(levels = c("1 site", "2-3 sites", ">3 sites")),

    # ── metastasis sites (already No/Yes) ──
    Lung = yn(Lung), Liver = yn(Liver), Brain = yn(Brain),
    Bone = yn(Bone), opposite_breast = yn(opposite_breast), Others = yn(Others),

    # ── treatments (already No/Yes) ──
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

    # ── survival outcome (already computed & capped at 24 mo) ──
    status  = as.numeric(status),
    os_time = as.numeric(os_time),
    
    surgery = factor(surgery)
  )
# ============================================================
# TABLE 1 - Patient & tumour characteristics by MBC type
# ============================================================
tab1 <- data %>%
  filter(!is.na(mbc_type)) %>%
  select(mbc_type, age_grp, Residence, Education, Income, Smoking,
         ER, PR, her2, clinical_subtype, grading, surgery) %>%
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
      clinical_subtype ~ "Clinical subtype",
      grading          ~ "Tumour grade",
      surgery          ~ "Surgery"
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
  select(mbc_type, mburden, Lung, Liver, Brain, Bone, opposite_breast, Others) %>%
  tbl_summary(
    by = mbc_type,
    label = list(
      mburden         ~ "Metastatic burden (no. of sites)",
      Lung            ~ "Lung metastasis",
      Liver           ~ "Liver metastasis",
      Brain           ~ "Brain (CNS) metastasis",
      Bone            ~ "Bone metastasis",
      opposite_breast ~ "Opposite breast metastasis",
      Others          ~ "Other/multiple sites"
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
  df <- df %>% filter(!is.na(os_time), !is.na(status), !is.na(mbc_type))
  if (nrow(df) < 5 | length(unique(df$mbc_type)) < 2) return(NULL)

  km  <- survfit(Surv(os_time, status) ~ mbc_type, data = df)
  med <- summary(km)$table[, "median"]
  ns  <- as.integer(summary(km)$table[, "records"])

  cox_u <- coxph(Surv(os_time, status) ~ mbc_type, data = df)
  hr_u  <- exp(coef(cox_u)); ci_u <- exp(confint(cox_u))
  p_u   <- summary(cox_u)$coefficients[, "Pr(>|z|)"]

  df_adj <- df %>% filter(!is.na(age_grp), !is.na(mburden), !is.na(Any_Systemic_Tx))
  cox_a <- tryCatch(
    coxph(Surv(os_time, status) ~ mbc_type + age_grp + mburden + Residence + Education + grading + Any_Systemic_Tx,
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
  get_survival_stats(data %>% filter(clinical_subtype == "HR+/HER2+"), "HR+/HER2+"),
  get_survival_stats(data %>% filter(clinical_subtype == "HR+/HER2-"), "HR+/HER2-"),
  get_survival_stats(data %>% filter(clinical_subtype == "HR-/HER2+"), "HR-/HER2+"),
  get_survival_stats(data %>% filter(clinical_subtype == "HR-/HER2-"), "HR-/HER2-")
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
  filter(!is.na(os_time), !is.na(status)) %>%
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
  Surv(os_time, status) ~ prior_tx_group + age_grp + mburden + Residence + Education + grading,
  data = data_sub)

tab5 <- tbl_regression(cox_sub, exponentiate = TRUE, include = "prior_tx_group",
                       label = list(prior_tx_group ~ "MBC group / prior stage")) %>%
  bold_p(t = 0.05) %>% bold_labels() %>%
  modify_header(label ~ "**Group**") %>%
  modify_caption("Table 5. Hazard ratios by MBC type and prior disease stage")

# ============================================================
# EXPORT - all tables to one Word document
# ============================================================
doc <- read_docx() %>%
  body_add("Table 1", style = "heading 1") %>%
  body_add_flextable(tab1 %>% as_flex_table() %>% autofit()) %>% body_add("") %>%
  body_add("Table 2", style = "heading 1") %>%
  body_add_flextable(tab2 %>% as_flex_table() %>% autofit()) %>% body_add("") %>%
  body_add("Table 3", style = "heading 1") %>%
  body_add_flextable(tab3 %>% as_flex_table() %>% autofit()) %>% body_add("") %>%
  body_add("Table 4", style = "heading 1") %>%
  body_add_flextable(tab4_ft %>% autofit()) %>% body_add("") %>%
  body_add("Table 5", style = "heading 1") %>%
  body_add_flextable(tab5 %>% as_flex_table() %>% autofit())

print(doc, target = file.path("Doc", "all_table_farhana.docx"))
message("Saved -> Doc/all_table_farhana.docx")

# ============================================================
# KM PLOTS - overall survival by MBC type (± by subtype)
# ============================================================
km_plot <- function(df, title = "") {
  df <- df %>% filter(!is.na(os_time), !is.na(status), !is.na(mbc_type))
  if (nrow(df) < 5 | length(unique(df$mbc_type)) < 2) {
    message("Skipping '", title, "': insufficient data"); return(invisible(NULL))
  }
  fit <- survfit(Surv(os_time, status) ~ mbc_type, data = df)
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
km_hrp_her2p <- km_plot(data %>% filter(clinical_subtype == "HR+/HER2+"), "HR+/HER2+")
km_hrp_her2n <- km_plot(data %>% filter(clinical_subtype == "HR+/HER2-"), "HR+/HER2-")
km_hrn_her2p <- km_plot(data %>% filter(clinical_subtype == "HR-/HER2+"), "HR-/HER2+")
km_hrn_her2n <- km_plot(data %>% filter(clinical_subtype == "HR-/HER2-"), "HR-/HER2-")

save_km_pdf <- function(km_obj, filepath, width = 8, height = 6) {
  if (is.null(km_obj)) return(invisible(NULL))
  combined <- cowplot::plot_grid(ggplotGrob(km_obj$plot), ggplotGrob(km_obj$table),
                                 ncol = 1, rel_heights = c(0.72, 0.28))
  cairo_pdf(filepath, width = width, height = height, onefile = TRUE)
  print(combined); dev.off()
  message("Saved -> ", filepath)
}

save_km_pdf(km_overall,   "Graph/Fig1_KM_Overall_v2.pdf")
save_km_pdf(km_hrp_her2p, "Graph/Fig2_KM_HR+_HER2+_farhana.pdf")
save_km_pdf(km_hrp_her2n, "Graph/Fig3_KM_HR+_HER2-_farhana.pdf")
save_km_pdf(km_hrn_her2n, "Graph/Fig4_KM_HR-_HER2-_farhana.pdf")

# subtype panels combined
km_panels <- Filter(Negate(is.null), list(km_hrp_her2p, km_hrp_her2n, km_hrn_her2p, km_hrn_her2n))
if (length(km_panels) > 0) {
  panel_grobs <- lapply(km_panels, function(p)
    cowplot::plot_grid(ggplotGrob(p$plot), ggplotGrob(p$table), ncol = 1, rel_heights = c(0.72, 0.28)))
  combined_panels <- cowplot::plot_grid(plotlist = panel_grobs, ncol = 2)
  cairo_pdf("Graph/Fig5_KM_by_Subtype_farhana.pdf", width = 14, height = 10, onefile = TRUE)
  print(combined_panels); dev.off()
  message("Saved -> Graph/Fig5_KM_by_Subtype_farhana.pdf")
}

message("\n=== All Farhana-imputed outputs saved ===")
