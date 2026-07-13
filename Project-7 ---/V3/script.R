library(tidyverse)
library(gtsummary)

library(haven)
library(stringr)
library(flextable)
library(officer)




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
library(broom)
library(pacman)
p_load(broom.helpers)
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
    Opposite_breast = ifelse(str_detect(sitemetastasis, "\\b6\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Others          = ifelse(str_detect(sitemetastasis, "\\b5\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Multiple_site   = ifelse(str_detect(sitemetastasis, "\\b7\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    
    # ── Receptor status ────────────────────────────────────
    ER = ER %>% labelled::unlabelled(),
    ER = case_when(
      ER == "1" ~ 1,
      ER == "2" ~ 2,
      .default  = NA
    ) %>% factor(labels = c("Positive", "Negative")),
    
    PR = PR %>% labelled::unlabelled(),
    PR = case_when(
      PR == "1" ~ 1,
      PR == "2" ~ 2,
      .default  = NA
    ) %>% factor(labels = c("Positive", "Negative")),
    
    her2 = her2 %>% labelled::unlabelled(),
    her2 = case_when(
      her2 == "1" ~ 1,
      her2 == "2" ~ 2,
      .default    = NA
    ) %>% factor(labels = c("Positive", "Negative")),
    
    parity = case_when(
      totalpg == 0 ~ "Nulliparous",
      totalpg >= 1 ~ "Parous"
    ) %>% factor(),
    
    family_hist = familybreastchistory %>% as_factor(),
    
    # ── De novo / Recurrent flags ───────────────────────
    denovometastasis = denovometastasis %>% labelled::unlabelled(),
    denovometastasis = denovometastasis %>% as.character() %>% as.numeric(),
    denovo           = case_when(
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
    subtype = case_when(
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
      .default = NA
    ) %>% factor(labels = c("Yes", "No")),
    
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
      .default = NA
    ) %>% factor(labels = c("Stable", "Progressive disease",
                            "Partial response", "Complete response")),
    
    # ── Tumour grade ───────────────────────────────────────
    grading = grading %>% labelled::unlabelled(),
    grading = case_when(
      grading == "1" ~ 1,
      grading == "2" ~ 2,
      grading == "3" ~ 3,
      .default = NA
    ) %>% factor(labels = c("Grade 1", "Grade 2", "Grade 3")),
    
    # ── Surgery ────────────────────────────────────────────
    surgery = surgery %>% labelled::unlabelled(),
    surgery = case_when(
      surgery == "1" ~ 1,
      surgery == "3" ~ 2,
      .default = NA
    ) %>% factor(labels = c("Mastectomy", "BCS")),
    
    # ── Treatments received (multi-coded) ──────────────────
    rxreceived          = rxreceived %>% labelled::unlabelled(),
    rxreceived          = ifelse(rxreceived == "", NA, rxreceived),
    Chemotherapy        = ifelse(str_detect(rxreceived, "\\b1\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    # Palliative_RT       = ifelse(str_detect(rxreceived, "\\b2\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Hormone_Therapy     = ifelse(str_detect(rxreceived, "\\b3\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    # Immunotherapy       = ifelse(str_detect(rxreceived, "\\b4\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Targeted_Therapy    = ifelse(str_detect(rxreceived, "\\b5\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Zoledronic_Acid     = ifelse(str_detect(rxreceived, "\\b6\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
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
    
    stage       = staging %>% as_factor(),
    
    # ── Causes of recurrent metastasis ────────────────────
    causesrmetast = causesrmetast %>% labelled::unlabelled(),
    CT_not_completed  = ifelse(str_detect(causesrmetast, "1"), 1, 0) %>% factor(labels = c("No", "Yes")),
    RT_not_completed  = ifelse(causesrmetast == "2",           1, 0) %>% factor(labels = c("No", "Yes")),
    Tx_not_in_time    = ifelse(causesrmetast == "3",           1, 0) %>% factor(labels = c("No", "Yes")),
    
    histology   = histologycal %>% as_factor(),
    # ── Survival outcome ───────────────────────────────────
    # status: 1 = Death (event), 0 = censored
    status = ifelse(cs == "Death", 1, 0) %>% factor(labels = c("Alive", "Death"))
    
  ) -> data

# ---------------------------------------------------------------------------
# Table 1. Patient and disease characteristics  (mirrors paper's Table 1)
# ---------------------------------------------------------------------------

data %>%
  select(age_grp, parity, family_hist, stage, subtype,
         histology, grading, Lung, Liver, Brain, Bone, Opposite_breast) %>%
  tbl_summary(
    statistic = list(
      all_continuous()  ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    missing = "no",
    label = list(
      age_grp        ~ "Age (years)",
      parity         ~ "Parity",
      family_hist    ~ "Family history of breast cancer",
      stage          ~ "Stage",
      subtype        ~ "Molecular subtype",
      histology      ~ "Histology",
      grading        ~ "Grade",
      Lung           ~ "Lung metastasis",
      Liver          ~ "Liver metastasis",
      Brain          ~ "Brain metastasis",
      Bone           ~ "Bone metastasis",
      Opposite_breast ~ "Opposite-breast metastasis"
    )
  ) %>%
  bold_labels() -> table1

table1

doc <- table1 %>% as_flex_table() %>% body_add_flextable(read_docx(), .)
print(doc, target = "doc/table1_patient_characteristics.docx")




# ---------------------------------------------------------------------------
# Table 2. Treatment and disease-course details  (mirrors paper's Table 2 intro)
# ---------------------------------------------------------------------------

data %>%
  select(surgery, Chemotherapy, Hormone_Therapy,
         Targeted_Therapy, Zoledronic_Acid,
         recume, denovo, mburden, cs) %>%
  tbl_summary(
    statistic = list(
      all_continuous()  ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    missing = "no",
    label = list(
      surgery           ~ "Surgery",
      Chemotherapy      ~ "Chemotherapy received",
      Hormone_Therapy   ~ "Hormone therapy received",
      Targeted_Therapy  ~ "Targeted therapy received",
      Zoledronic_Acid   ~ "Zoledronic acid received",
      recume            ~ "Recurrent metastasis",
      denovo            ~ "De novo metastatic disease",
      mburden           ~ "Metastatic burden",
      cs                ~ "Current disease status"
    )
  ) %>%
  bold_labels() -> table2

table2

# Uptake among biomarker-positive subgroups (paper reports this as narrative text)
hr_pos_uptake <- data %>%
  filter(ER == "Positive" | PR == "Positive") %>%
  summarise(n = n(), received = sum(Hormone_Therapy == "Yes", na.rm = TRUE)) %>%
  mutate(pct = round(100 * received / n, 1))

her2_pos_uptake <- data %>%
  filter(her2 == "Positive") %>%
  summarise(n = n(), received = sum(Targeted_Therapy == "Yes", na.rm = TRUE)) %>%
  mutate(pct = round(100 * received / n, 1))

hr_pos_uptake
her2_pos_uptake

doc <- table2 %>% as_flex_table() %>% 
  body_add_flextable(read_docx(), .) %>% 
  body_add(paste0(hr_pos_uptake$received, "(", hr_pos_uptake$pct, "%)", "Uptake among ", hr_pos_uptake$n," HR+ Cases")) %>% 
  body_add(paste0(her2_pos_uptake$received, "(", her2_pos_uptake$pct, "%)", "Uptake among ", her2_pos_uptake$n," HER2+ Cases"))
print(doc, target = "doc/table2_treatment_details.docx")











# ---------------------------------------------------------------------------
# Table 3. Association with mortality  (SUBSTITUTE for paper's Cox HR table)
# ---------------------------------------------------------------------------
# IMPORTANT CAVEAT
# ----------------
# The paper's Table 2 is a univariate + multivariate Cox proportional-hazards
# model for overall survival (HR, 95% CI). `timeofdeath` / `timdea` in this
# dataset are populated ONLY for patients whose current status (`cs`) is
# "Death" (39 of 135 rows) -- there is no recorded follow-up/censoring time
# for the 96 patients who are alive. A coxph() call on Surv(timeofdeath, status)
# will silently drop every row with NA duration via na.omit, which means it
# effectively fits on a subset with no censored observations left -- the
# resulting "HRs" are not a valid survival analysis and should not be reported
# as such. See below for that model kept only as a documented non-example.
#
# As a defensible alternative, this table tests association between each
# clinicopathological/treatment factor and CURRENT VITAL STATUS
# (Death vs Alive/disease-free) with chi-square / Fisher's exact test --
# conceptually closest to the paper's univariate screen, without requiring a
# time-to-event that the dataset doesn't actually contain.

data %>%
  select(status, grading, subtype, mburden, Lung, Liver, delayrx, skip) %>%
  tbl_summary(
    by = status,
    statistic = list(
      all_continuous()  ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    missing = "no",
    label = list(
      grading    ~ "Tumor grade",
      subtype  ~ "Molecular subtype",
      mburden  ~ "Metastatic burden",
      Lung     ~ "Lung metastasis",
      Liver    ~ "Liver metastasis",
      delayrx  ~ "Delayed treatment",
      skip     ~ "Skipped treatment"
    )
  ) %>%
  add_p(
    test = list(all_categorical() ~ "fisher.test")  # safer than chisq.test for small cells
  ) %>%
  bold_labels() -> table3

table3

doc <- table3 %>% as_flex_table() %>% body_add_flextable(read_docx(), .)
print(doc, target = "doc/table3_mortality_association.docx")







data <- data %>% mutate(
  status2 = ifelse(cs == "Death", 1, 0),
  os_time =   ifelse(status == 1, timdea, symptomtometastasis),
  os_time = ifelse(os_time >24, 24, os_time)
)

vars <- c("age_grp", "grading", "subtype", "mburden", "Lung", "Liver", "delayrx", "skip")

var_label <- list(
  age_grp ~ "Age Group",
  grading   ~ "Tumor grade",
  subtype ~ "Molecular subtype",
  mburden ~ "Metastatic burden",
  Lung    ~ "Lung metastasis",
  Liver   ~ "Liver metastasis",
  delayrx ~ "Delayed treatment",
  skip    ~ "Skipped treatment"
)
names(var_label) <- vars

# --- Univariate models: one variable at a time, stacked into one table ------
tbl_list <- list()
for (var in vars) {
  fml <- as.formula(paste0("Surv(os_time, status2) ~ ", var))
  cox_uni <- coxph(fml, data = data)
  
  tbl_list[[var]] <- tbl_regression(
    cox_uni,
    exponentiate = TRUE,
    label = var_label[[var]]     # single-element list, keeps names() intact
  ) %>%
    bold_labels() %>%
    bold_p(t = 0.05)
}

tbl_uni <- tbl_stack(tbl_list)

# --- Multivariate model: all variables together -----------------------------
cox_multi <- coxph(
  Surv(os_time, status2) ~ age_grp + grading + subtype + mburden + Lung + Liver + delayrx + skip,
  data = data
)

tbl_multi <- tbl_regression(
  cox_multi,
  exponentiate = TRUE,
  label = list(
    age_grp ~ "Age Group",
    grading   ~ "Tumor grade",
    subtype ~ "Molecular subtype",
    mburden ~ "Metastatic burden",
    Lung    ~ "Lung metastasis",
    Liver   ~ "Liver metastasis",
    delayrx ~ "Delayed treatment",
    skip    ~ "Skipped treatment"
  )
) %>%
  bold_labels() %>%
  bold_p(t = 0.05)

# --- Concatenate univariate + multivariate side by side (paper's Table 2 layout) ---
table4 <- tbl_merge(
  tbls = list(tbl_uni, tbl_multi),
  tab_spanner = c("**Univariate analysis**", "**Multivariate analysis**")
) 

table4

doc <- table4 %>% as_flex_table() %>% body_add_flextable(read_docx(), .)
print(doc, target = "doc/table4_cox_regression.docx")







