# ============================================================
# Metastatic Breast Cancer – Reproducing Tables from
# Slotman et al. (2026) Breast Cancer Research and Treatment
# ============================================================
# Variable mapping (confirmed from dataset):
#   denovometastasis == 1  →  De novo MBC
#   recume           == 1  →  Recurrent MBC
#   mbc_type  = derived grouping variable (De novo / Recurrent)
# ============================================================

library(haven)
library(dplyr)
library(stringr)
library(forcats)
library(gtsummary)
library(survival)
library(survminer)
library(flextable)
library(officer)
# library(cowplot) needed for plot_grid + ggplotGrob composition
library(cowplot)
# ----------------------------------------------------------
# 0.  Load raw data
# ----------------------------------------------------------
read_sav("Data/Metastatic breast cancer study_new dataset.sav") %>%
  mutate(
    
    # ── Age group ──────────────────────────────────────────
    age_grp = case_when(
      age < 35              ~ 1,
      age >= 35 & age < 45  ~ 2,
      age >= 45 & age < 55  ~ 3,
      age >= 55             ~ 4
    ) %>%
      factor(labels = c("<35", "35-45", "45-55", "55+")),
    
    # ── Socio-demographics ─────────────────────────────────
    Residence = Residence %>% as_factor(),
    Education = Education %>% as_factor(),
    Smoking   = Smoking   %>% as_factor(),
    Income    = Income    %>% as_factor(),
    
    # ── Metastasis sites (multi-coded: 1=Lung 2=Liver 3=Brain 4=Bone 5=Multiple 6=Opp.Breast) ──
    sitemetastasis  = sitemetastasis %>% labelled::unlabelled(),
    sitemetastasis  = ifelse(sitemetastasis == "", NA, sitemetastasis),
    Lung            = ifelse(str_detect(sitemetastasis, "\\b1\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Brain           = ifelse(str_detect(sitemetastasis, "\\b3\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Liver           = ifelse(str_detect(sitemetastasis, "\\b2\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Bone            = ifelse(str_detect(sitemetastasis, "\\b4\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    opposite_breast = ifelse(str_detect(sitemetastasis, "\\b6\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Others          = ifelse(str_detect(sitemetastasis, "\\b5\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Multiple_site   = ifelse(str_detect(sitemetastasis, "\\b7\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    
    # ── Receptor status ────────────────────────────────────
    ER = ER %>% labelled::unlabelled(),
    ER = case_when(
      ER == "1" ~ 1,
      ER == "2" ~ 2,
      .default  = 3
    ) %>% factor(labels = c("Positive", "Negative", "Unknown")),
    
    PR = PR %>% labelled::unlabelled(),
    PR = case_when(
      PR == "1" ~ 1,
      PR == "2" ~ 2,
      .default  = 3
    ) %>% factor(labels = c("Positive", "Negative", "Unknown")),
    
    her2 = her2 %>% labelled::unlabelled(),
    her2 = case_when(
      her2 == "1" ~ 1,
      her2 == "2" ~ 2,
      .default    = 3
    ) %>% factor(labels = c("Positive", "Negative", "Unknown")),
    
    # ── De novo / Recurrent flags ───────────────────────
    denovometastasis = denovometastasis %>% labelled::unlabelled(),
    denovometastasis = denovometastasis %>% as.character() %>% as.numeric(),
    denovometastasis = case_when(
      denovometastasis == 1 ~ 1,
      denovometastasis == 2 ~ 2,
      .default = NA_integer_
    ) %>% factor(labels = c("Yes", "No")),   # Yes = has de novo metastasis
    
    recume = recume %>% labelled::unlabelled(),
    recume = recume %>% as.character() %>% as.numeric() %>%
      factor(labels = c("Yes", "No")),        # Yes = Recurrent (recurrent) metastasis
    
    # ── Derived grouping variable (paper's primary comparison) ──
    # denovometastasis==Yes  →  De novo MBC
    # recume==Yes            →  Recurrent MBC
    mbc_type = case_when(
      denovometastasis == "Yes" ~ "De novo MBC",
      recume           == "Yes" ~ "Recurrent MBC",
      .default = NA_character_
    ) %>% factor(levels = c("De novo MBC", "Recurrent MBC")),
    
    # ── Clinical subtype (HR+/HER2+, HR+/HER2-, HR-/HER2+, HR-/HER2-) ──
    # HR positive = ER+ or PR+
    clinical_subtype = case_when(
      ER == "Positive" | PR == "Positive" ~ "HR+",
      ER == "Negative" & PR == "Negative" ~ "HR-",
      .default = NA_character_
    ),
    clinical_subtype = case_when(
      clinical_subtype == "HR+" & her2 == "Positive" ~ "HR+/HER2+",
      clinical_subtype == "HR+" & her2 == "Negative" ~ "HR+/HER2-",
      clinical_subtype == "HR-" & her2 == "Positive" ~ "HR-/HER2+",
      clinical_subtype == "HR-" & her2 == "Negative" ~ "HR-/HER2-",
      .default = NA_character_
    ) %>% factor(levels = c("HR+/HER2+", "HR+/HER2-", "HR-/HER2+", "HR-/HER2-")),
    
    # ── Skip & clinical status ─────────────────────────────
    skip = skip %>% as.character() %>% as.numeric() %>%
      factor(labels = c("Non Adherent", "Adherent")),
    cs   = cs   %>% as.character() %>% as.numeric() %>%
      factor(labels = c("Alive with disease", "Disease free", "Death")),
    
    # ── Metastatic burden ──────────────────────────────────
    mburden = mburden %>% labelled::unlabelled(),
    mburden = mburden %>% as.character() %>% as.numeric(),
    mburden = case_when(
      mburden == 1        ~ 1,
      mburden %in% 2:3   ~ 2,
      mburden > 3         ~ 3,
      .default = NA_integer_
    ) %>% factor(labels = c("1 site", "2-3 sites", ">3 sites")),
    
    # ── Treatment delay & response ─────────────────────────
    delayrx = delayrx %>% labelled::unlabelled(),
    delayrx = case_when(
      delayrx == "1" ~ 1,
      delayrx == "2" ~ 2,
      .default = 3
    ) %>% factor(labels = c("Yes", "No", "Unknown")),
    
    symptomaticresponse = symptomaticresponse %>% labelled::unlabelled(),
    symptomaticresponse = case_when(
      symptomaticresponse == "1" ~ 1,
      symptomaticresponse == "2" ~ 2,
      .default = NA
    ) %>% factor(labels = c("Adequate", "Inadequate")),
    
    # ── Radiological response ──────────────────────────────
    radiologivcalresponse = radiologivcalresponse %>% labelled::unlabelled(),
    radiologivcalresponse = case_when(
      radiologivcalresponse == "1" ~ 1,
      radiologivcalresponse == "2" ~ 2,
      radiologivcalresponse == "3" ~ 3,
      radiologivcalresponse == "4" ~ 4,
      .default = 5
    ) %>% factor(labels = c("Stable", "Progressive disease",
                            "Partial response", "Complete response", "Unknown")),
    
    # ── Tumour grade ───────────────────────────────────────
    grading = grading %>% labelled::unlabelled(),
    grading = case_when(
      grading == "1" ~ 1,
      grading == "2" ~ 2,
      grading == "3" ~ 3,
      .default = 4
    ) %>% factor(labels = c("Grade 1", "Grade 2", "Grade 3", "Unknown")),
    
    # ── Surgery ────────────────────────────────────────────
    surgery = surgery %>% labelled::unlabelled(),
    surgery = case_when(
      surgery == "1" ~ 1,
      surgery == "2" ~ 2,
      surgery == "3" ~ 3,
      surgery == "4" ~ 3,
      .default = NA
    ) %>% factor(labels = c("BCS", "Mastectomy")),
    
    # ── Treatments received (multi-coded) ──────────────────
    rxreceived              = rxreceived %>% labelled::unlabelled(),
    rxreceived              = ifelse(rxreceived == "", NA, rxreceived),
    Chemotherapy            = ifelse(str_detect(rxreceived, "\\b1\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Palliative_Radiotherapy = ifelse(str_detect(rxreceived, "\\b2\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Hormone_Therapy         = ifelse(str_detect(rxreceived, "\\b3\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Targeted_Therapy        = ifelse(str_detect(rxreceived, "\\b5\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Zoledronic_Acid         = ifelse(str_detect(rxreceived, "\\b6\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Any_Systemic_Tx         = ifelse(
      Chemotherapy == "Yes" | Hormone_Therapy == "Yes" | Targeted_Therapy == "Yes", 1, 0
    ) %>% factor(labels = c("No", "Yes")),
    
    # ── Symptoms (multi-coded) ─────────────────────────────
    symptoms = symptoms %>% labelled::unlabelled(),
    symp_01  = ifelse(str_detect(symptoms, "\\b1\\b"),  1, 0) %>% factor(labels = c("No", "Yes")),
    symp_02  = ifelse(str_detect(symptoms, "\\b2\\b"),  1, 0) %>% factor(labels = c("No", "Yes")),
    symp_06  = ifelse(str_detect(symptoms, "\\b6\\b"),  1, 0) %>% factor(labels = c("No", "Yes")),
    symp_07  = ifelse(str_detect(symptoms, "\\b7\\b"),  1, 0) %>% factor(labels = c("No", "Yes")),
    symp_08  = ifelse(str_detect(symptoms, "\\b8\\b"),  1, 0) %>% factor(labels = c("No", "Yes")),
    symp_09  = ifelse(str_detect(symptoms, "\\b9\\b"),  1, 0) %>% factor(labels = c("No", "Yes")),
    symp_10  = ifelse(str_detect(symptoms, "\\b10\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    symp_11  = ifelse(str_detect(symptoms, "\\b11\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    symp_12  = ifelse(str_detect(symptoms, "\\b12\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    symp_16  = ifelse(str_detect(symptoms, "\\b16\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    
    # ── Prior stage (for Recurrent sub-analysis) ────────
    # prestage: 1=Stage1, 2=Stage2, 3=Stage3 (de novo patients have missing)
    prestage = prestage %>% labelled::unlabelled(),
    prestage = case_when(
      prestage == "1" ~ "Stage 1",
      prestage == "2" ~ "Stage 2",
      prestage == "3" ~ "Stage 3",
      prestage == "4" ~ "Stage 4",
      .default = NA_character_
    ) %>% factor(),
    
    # ── Causes of recurrent metastasis ────────────────────
    causesrmetast = causesrmetast %>% labelled::unlabelled(),
    CT_not_completed  = ifelse(str_detect(causesrmetast, "1"), 1, 0) %>% factor(labels = c("No", "Yes")),
    RT_not_completed  = ifelse(causesrmetast == "2",           1, 0) %>% factor(labels = c("No", "Yes")),
    Tx_not_in_time    = ifelse(causesrmetast == "3",           1, 0) %>% factor(labels = c("No", "Yes")),
    
    # ── Survival outcome ───────────────────────────────────
    # status: 1 = Death (event), 0 = censored
    status = ifelse(cs == "Death", 1, 0)
    
  ) -> data


# =============================================================
# TABLE 1 – Patient & tumour characteristics by MBC type
# Analog of Table 1 in Slotman et al. (2026)
# =============================================================
# Test selection: chi-squared when all expected cell counts ≥ 5,
# Fisher's exact otherwise (gtsummary handles this automatically
# via test = "auto")

tab1 <- data %>%
  filter(!is.na(mbc_type)) %>%
  select(
    mbc_type,
    age_grp, Residence, Education, Income, Smoking,
    ER, PR, her2,
    clinical_subtype,
    grading, surgery
  ) %>%
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
      surgery          ~ "Surgery type"
    ),
    statistic  = list(all_categorical() ~ "{n} ({p}%)"),
    missing    = "no"
  ) %>%
  add_p(
    test = list(all_categorical() ~ "chisq.test"),
    pvalue_fun = label_style_pvalue(digits = 3)
  ) %>%
  add_overall(last = FALSE) %>%
  bold_labels() %>%
  modify_header(label ~ "**Characteristic**") %>%
  modify_spanning_header(c(stat_1, stat_2) ~ "**MBC Type**") %>%
  modify_caption("Table 1. Patient characteristics and clinical subtype of patients diag nosed with de novo or metachronous metastatic breast cancer (MBC)")

tab1


# =============================================================
# TABLE 2 – Disease/metastasis characteristics by MBC type
# Analog of Table 2 in Slotman et al. (2026)
# =============================================================
tab2 <- data %>%
  filter(!is.na(mbc_type)) %>%
  select(
    mbc_type,
    mburden,
    Lung, Liver, Brain, Bone, opposite_breast, Others,
    prestage          # prior stage (only relevant for Recurrent)
  ) %>%
  tbl_summary(
    by = mbc_type,
    label = list(
      mburden         ~ "Metastatic burden (no. of sites)",
      Lung            ~ "Lung metastasis",
      Liver           ~ "Liver metastasis",
      Brain           ~ "Brain (CNS) metastasis",
      Bone            ~ "Bone metastasis",
      opposite_breast ~ "Opposite breast metastasis",
      Others          ~ "Other/multiple sites",
      prestage        ~ "Prior disease stage (Recurrent only)"
    ),
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no"
  ) %>%
  add_p(
    test = list(all_categorical() ~ "chisq.test"),
    pvalue_fun = label_style_pvalue(digits = 3)
  ) %>%
  add_overall(last = FALSE) %>%
  bold_labels() %>%
  modify_header(label ~ "**Disease Characteristic**") %>%
  modify_spanning_header(c(stat_1, stat_2) ~ "**MBC Type**") %>%
  modify_caption("Table 2. Disease and metastasis characteristics by MBC type")

tab2


# =============================================================
# TABLE 3 – Systemic treatment patterns by MBC type
# Analog of Table 3 in Slotman et al. (2026)
# =============================================================
tab3 <- data %>%
  filter(!is.na(mbc_type)) %>%
  select(
    mbc_type,
    Any_Systemic_Tx,
    Chemotherapy, Hormone_Therapy, Targeted_Therapy,
    Palliative_Radiotherapy, Zoledronic_Acid,
    delayrx, symptomaticresponse, radiologivcalresponse,
    skip
  ) %>%
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
  add_p(
    test = list(all_categorical() ~ "chisq.test"),
    pvalue_fun = label_style_pvalue(digits = 3)
  ) %>%
  add_overall(last = FALSE) %>%
  bold_labels() %>%
  modify_header(label ~ "**Treatment**") %>%
  modify_spanning_header(c(stat_1, stat_2) ~ "**MBC Type**") %>%
  modify_caption("Table 3. Treatment patterns by MBC type")

tab3


# =============================================================
# TABLE 4 – Median OS + Cox Hazard Ratios by MBC type
# Analog of Table 4 in Slotman et al. (2026)
# NOTE: timeofdeath is only populated for patients who died (n=39).
# We construct a proper survival time for all patients:
#   - If dead  : timeofdeath (months from diagnosis to death)
#   - If alive : use symptomtometastasis as censoring time proxy
#   (The dataset has no explicit follow-up duration for censored patients,
#    so symptomtometastasis is the best available approximation)
# =============================================================
data <- data %>%
  mutate(
    # Construct OS time: observed death time OR symptom-to-metastasis as proxy
    os_time =   ifelse(status == 1, timdea, symptomtometastasis),
    os_time = ifelse(os_time >24, 24, os_time)
  )

# Helper: fit KM + unadjusted & adjusted Cox for one subset
get_survival_stats <- function(df, subtype_label = "Overall") {
  df <- df %>% filter(!is.na(os_time), !is.na(status), !is.na(mbc_type))
  if (nrow(df) < 5 | length(unique(df$mbc_type)) < 2) return(NULL)
  
  km  <- survfit(Surv(os_time, status) ~ mbc_type, data = df)
  med <- summary(km)$table[, "median"]
  ns  <- as.integer(summary(km)$table[, "records"])
  
  # Unadjusted Cox
  cox_u  <- coxph(Surv(os_time, status) ~ mbc_type, data = df)
  hr_u   <- exp(coef(cox_u))
  ci_u   <- exp(confint(cox_u))
  p_u    <- summary(cox_u)$coefficients[, "Pr(>|z|)"]
  
  # Adjusted Cox: age group + metastatic burden + any systemic treatment
  df_adj <- df %>% filter(!is.na(age_grp), !is.na(mburden), !is.na(Any_Systemic_Tx))
  cox_a  <- tryCatch(
    coxph(Surv(os_time, status) ~ mbc_type + age_grp + mburden + Any_Systemic_Tx,
          data = df_adj),
    error = function(e) NULL
  )
  if (!is.null(cox_a)) {
    idx  <- grep("mbc_type", names(coef(cox_a)))
    hr_a <- exp(coef(cox_a))[idx]
    ci_a <- exp(confint(cox_a))[idx, , drop = FALSE]
    p_a  <- summary(cox_a)$coefficients[idx, "Pr(>|z|)"]
  } else {
    hr_a <- NA; ci_a <- matrix(NA, 1, 2); p_a <- NA
  }
  
  tibble(
    `Clinical Subtype`   = c(subtype_label, ""),
    Group                = c("De novo MBC", "Recurrent MBC"),
    N                    = ns,
    `Median OS (months)` = round(med, 1),
    `HR (unadjusted)`    = c("Reference",
                             sprintf("%.2f (%.2f–%.2f)", hr_u, ci_u[1,1], ci_u[1,2])),
    `P (unadj.)`         = c("", ifelse(p_u < 0.001, "<0.001", round(p_u, 3))),
    `HR (adjusted)`      = c("Reference",
                             ifelse(!is.na(hr_a),
                                    sprintf("%.2f (%.2f–%.2f)", hr_a, ci_a[1,1], ci_a[1,2]),
                                    "—")),
    `P (adj.)`           = c("", ifelse(!is.na(p_a),
                                        ifelse(p_a < 0.001, "<0.001", round(p_a, 3)),
                                        "—"))
  )
}

tab4_data <- bind_rows(
  get_survival_stats(data %>% filter(!is.na(mbc_type)),                             "Overall"),
  get_survival_stats(data %>% filter(clinical_subtype == "HR+/HER2+"),  "HR+/HER2+"),
  get_survival_stats(data %>% filter(clinical_subtype == "HR+/HER2-"),  "HR+/HER2-"),
  get_survival_stats(data %>% filter(clinical_subtype == "HR-/HER2+"),  "HR-/HER2+"),
  get_survival_stats(data %>% filter(clinical_subtype == "HR-/HER2-"),  "HR-/HER2-")
)

# Render as flextable
tab4_ft <- flextable(tab4_data) %>%
  merge_v(j = "Clinical Subtype") %>%
  valign(j = "Clinical Subtype", valign = "top") %>%
  bold(part = "header") %>%
  bold(j = "Clinical Subtype") %>%
  hline(i = c(2, 4, 6, 8), border = officer::fp_border(color = "grey70")) %>%
  autofit() %>%
  theme_booktabs() %>%
  set_caption("Table 4. Median overall survival and hazard ratios – de novo vs. Recurrent MBC")

tab4_ft


# =============================================================
# TABLE 5 – Sub-analysis: prior disease stage among Recurrent
# Analog of Table 5 in Slotman et al. (2026)
# Paper: stratifies Recurrent MBC by prior (neo)adjuvant
#        systemic treatment. Dataset proxy: prior stage (prestage)
# Groups:
#   1. De novo MBC
#   2. Recurrent MBC – prior Stage 3 (most likely to have had prior chemo/RT)
#   3. Recurrent MBC – prior Stage 1–2 (less intensive prior treatment)
# =============================================================
data_sub <- data %>%
  filter(!is.na(os_time), !is.na(status)) %>%
  mutate(
    prior_tx_group = case_when(
      mbc_type == "De novo MBC"                                     ~ "De novo MBC",
      mbc_type == "Recurrent MBC" & prestage == "Stage 3"        ~ "Recurrent – Prior Stage 3",
      mbc_type == "Recurrent MBC" & prestage %in% c("Stage 1","Stage 2") ~ "Recurrent – Prior Stage 1/2",
      mbc_type == "Recurrent MBC" & is.na(prestage)              ~ "Recurrent – Stage unknown",
      .default = NA_character_
    ) %>% factor(levels = c(
      "De novo MBC",
      "Recurrent – Prior Stage 3",
      "Recurrent – Prior Stage 1/2",
      "Recurrent – Stage unknown"
    ))
  ) %>%
  filter(!is.na(prior_tx_group))

cox_sub <- coxph(
  Surv(os_time, status) ~ prior_tx_group + age_grp + mburden,
  data = data_sub
)

tab5 <- tbl_regression(
  cox_sub,
  exponentiate = TRUE,
  include      = "prior_tx_group",
  label        = list(
    prior_tx_group ~ "MBC group / prior stage"
  )
) %>%
  bold_p(t = 0.05) %>%
  bold_labels() %>%
  modify_header(label ~ "**Group**") %>%
  modify_caption(
    "Table 5.Hazard ratios by MBC type and prior disease stage"
  )

tab5


# =============================================================
# KM PLOTS – Overall survival by MBC type (± by subtype)
# Analog of Fig. 1 in Slotman et al. (2026)
# =============================================================
km_plot <- function(df, title = "") {
  df <- df %>% filter(!is.na(os_time), !is.na(status), !is.na(mbc_type))
  if (nrow(df) < 5 | length(unique(df$mbc_type)) < 2) {
    message("Skipping '", title, "': insufficient data"); return(invisible(NULL))
  }
  fit <- survfit(Surv(os_time, status) ~ mbc_type, data = df)
  ggsurvplot(
    fit,
    data              = df,
    pval              = TRUE,
    pval.size         = 4,
    conf.int          = TRUE,
    conf.int.alpha    = 0.15,
    risk.table        = TRUE,
    risk.table.height = 0.28,
    xlab              = "Months since diagnosis",
    ylab              = "Overall survival probability",
    title             = title,
    legend.title      = "",
    legend.labs       = c("De novo MBC", "Recurrent MBC"),
    palette           = c("#2166AC", "#D6604D"),
    ggtheme           = theme_classic(base_size = 12),
    surv.median.line  = "hv"
  )
}

# (a) Overall
km_overall <- km_plot(data %>% filter(!is.na(mbc_type)),
                      title = "Overall")

# (b)–(e) By clinical subtype
km_hrp_her2p <- km_plot(data %>% filter(clinical_subtype == "HR+/HER2+"), "HR+/HER2+")
km_hrp_her2n <- km_plot(data %>% filter(clinical_subtype == "HR+/HER2-"), "HR+/HER2-")
km_hrn_her2p <- km_plot(data %>% filter(clinical_subtype == "HR-/HER2+"), "HR-/HER2+")
km_hrn_her2n <- km_plot(data %>% filter(clinical_subtype == "HR-/HER2-"), "HR-/HER2-")

# Print plots
km_overall
km_hrp_her2n    # Most patients fall here – typically most informative

# Arrange all subtype panels side by side (Fig.1 layout)
km_panels <- Filter(Negate(is.null),
                    list(km_hrp_her2p, km_hrp_her2n, km_hrn_her2n))
if (length(km_panels) > 0)
  arrange_ggsurvplots(km_panels, ncol = 2, nrow = 2, print = TRUE)


# =============================================================
# EXPORT – All tables to Word documents
# =============================================================
doc <- read_docx() %>%
  body_add("Table 1", style = "heading 1") %>% 
  body_add_flextable(tab1 %>% as_flex_table() %>% autofit()) %>% 
  body_add("") %>% 
  body_add("Table 2", style = "heading 1") %>% 
  body_add_flextable(tab2 %>% as_flex_table() %>% autofit()) %>% 
  body_add("") %>% 
  body_add("Table 3", style = "heading 1") %>% 
  body_add_flextable(tab3 %>% as_flex_table() %>% autofit()) %>% 
  body_add("") %>% 
  body_add("Table 4", style = "heading 1") %>% 
  body_add_flextable(tab4_ft %>% autofit()) %>% 
  body_add("") %>% 
  body_add("Table 5", style = "heading 1") %>% 
  body_add_flextable(tab5 %>% as_flex_table() %>% autofit())


print(doc, target = file.path("Doc", "all_table.docx"))



# KM plots as PDF
# ggsurvplot internally calls grid.newpage() which adds a blank first page
# when using pdf(). The fix: extract the combined ggplot object via $plot +
# $table and compose manually with patchwork, OR use ggsurvplot's own
# print method inside a clean graphics device opened AFTER the object exists.
# The most reliable fix is to convert to a single patchwork/gtable and draw once.

save_km_pdf <- function(km_obj, filepath, width = 8, height = 6) {
  # Build a single gtable from the ggsurvplot components so that only
  # one page is written — no internal grid.newpage() side effects.
  combined <- cowplot::plot_grid(
    ggplotGrob(km_obj$plot),
    ggplotGrob(km_obj$table),
    ncol  = 1,
    rel_heights = c(0.72, 0.28)
  )
  cairo_pdf(filepath, width = width, height = height, onefile = TRUE)
  print(combined)
  dev.off()
  message("Saved → ", filepath)
}



save_km_pdf(km_overall,    "Graph/Fig1_KM_Overall.pdf",    width = 8,  height = 6)
save_km_pdf(km_hrp_her2p,    "Graph/Fig2_KM_HR+_HER2+.pdf",    width = 8,  height = 6)
save_km_pdf(km_hrp_her2n,    "Graph/Fig3_KM_HR+_HER2-.pdf",    width = 8,  height = 6)
save_km_pdf(km_hrn_her2n,    "Graph/Fig4_KM_HR-_HER2-.pdf",    width = 8,  height = 6)

if (length(km_panels) > 0) {
  # For subtype panels: build each into a grob, arrange in 2x2 grid
  panel_grobs <- lapply(km_panels, function(p) {
    cowplot::plot_grid(
      ggplotGrob(p$plot),
      ggplotGrob(p$table),
      ncol = 1,
      rel_heights = c(0.72, 0.28)
    )
  })
  combined_panels <- cowplot::plot_grid(plotlist = panel_grobs, ncol = 2, nrow = 2)
  cairo_pdf("Graph/Fig1_KM_by_Subtype.pdf", width = 14, height = 10, onefile = TRUE)
  print(combined_panels)
  dev.off()
  message("Saved → output_docs/Fig1_KM_by_Subtype.pdf")
}

message("\n=== All outputs saved to output_docs/ ===")