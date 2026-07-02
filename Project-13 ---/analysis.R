library(tidyverse)
library(gtsummary)
library(flextable)
library(officer)
library(openxlsx)
library(labelled)

select <- dplyr::select

# ── 1. Load & clean data ──────────────────────────────────────────────────────
df_raw <- read.xlsx("Data/Ca breast final dataset.xlsx", sheet = 1)

df <- df_raw %>%
  mutate(
    age = as.numeric(age),
    
    age_group = case_when(
      age <= 29           ~ "\u226429",
      age %in% 30:39       ~ "30\u201339",
      age %in% 40:49       ~ "40\u201349",
      age %in% 50:59       ~ "50\u201359",
      age %in% 60:69       ~ "60\u201369",
      age >= 70            ~ "\u226570",
      TRUE                 ~ NA_character_
    ),
    age_group = factor(age_group, levels = c("\u226429","30\u201339","40\u201349","50\u201359","60\u201369","\u226570")),
    
    gender = str_to_title(gender),
    gender = factor(gender, levels = c("Male", "Female")),
    
    education = case_when(
      education == "no_education"        ~ "Illiterate",
      education == "primary"              ~ "\u22645 years schooling",
      education == "secondery"            ~ "5\u201310 years schooling",
      education == "higher_secondery"     ~ "10\u201312 years schooling",
      education == "graduate_and_more"    ~ "Graduate and above",
      TRUE ~ NA_character_
    ),
    education = factor(education, levels = c("Illiterate", "\u22645 years schooling",
                                             "5\u201310 years schooling", "10\u201312 years schooling",
                                             "Graduate and above")),
    
    # NOTE: "Low/High education" split for bivariate/regression tables (Table 4 & 5)
    # is not defined in the raw data. Assumed cut: Illiterate + <=5 yrs = Low;
    # 5-10 yrs + 10-12 yrs + Graduate = High. Adjust the cutoff below if the
    # original study used a different split (e.g., primary vs secondary+).
    education_bin = factor(
      if_else(education %in% c("Illiterate", "\u22645 years schooling"), "Low education", "High education"),
      levels = c("High education", "Low education")
    ),
    
    occupation = case_when(
      occupation == "housewife" ~ "Housewife",
      occupation == "service"   ~ "Service",
      occupation == "agri"      ~ "Agriculture",
      TRUE ~ NA_character_
    ),
    occupation = factor(occupation, levels = c("Housewife", "Service", "Agriculture")),
    occupation_bin = factor(
      if_else(occupation == "Housewife", "Housewife", "Others"),
      levels = c("Housewife", "Others")
    ),
    
    marriage = case_when(
      marriage == "married"   ~ "Married",
      marriage == "unmarried" ~ "Unmarried",
      TRUE ~ NA_character_   # drops the single invalid code "3"
    ),
    marriage = factor(marriage, levels = c("Married", "Unmarried")),
    
    # NOTE: income category labels in the raw data ("poor","middle","high","rich")
    # are mapped to BDT bands based on Table 1 frequencies matching exactly.
    income = case_when(
      income == "poor"   ~ "<5000",
      income == "middle" ~ "5001\u201310000",
      income == "high"   ~ "10001\u201315000",
      income == "rich"   ~ ">15000",
      TRUE ~ NA_character_
    ),
    income = factor(income, levels = c("<5000", "5001\u201310000", "10001\u201315000", ">15000")),
    
    # NOTE: "Low/High income" split for Table 4 & 5 assumed at BDT 10,000
    # (<=10000 = Low, >10000 = High). Adjust if a different cutoff was used.
    income_bin = factor(
      if_else(income %in% c("<5000", "5001\u201310000"), "Low income", "High income"),
      levels = c("High income", "Low income")
    ),
    
    slt_cat = str_to_title(slt_cat),
    slt_cat = factor(slt_cat, levels = c("No", "Yes")),
    
    residence = str_to_title(residence),
    residence = na_if(residence, ""),
    residence = factor(residence, levels = c("Urban", "Rural")),
    
    stage_cat = case_when(
      stage_cat == "first"  ~ "Stage I",
      stage_cat == "second" ~ "Stage II",
      stage_cat == "third"  ~ "Stage III",
      stage_cat == "fourth" ~ "Stage IV",
      TRUE ~ NA_character_
    ),
    stage_cat = factor(stage_cat, levels = c("Stage I", "Stage II", "Stage III", "Stage IV")),
    
    delayed_care = str_to_title(delayed_care),
    delayed_care = factor(delayed_care, levels = c("No", "Yes")),
    delayed_care_bin = if_else(delayed_care == "Yes", 1L, 0L),
    
    delay_trmnt = str_to_title(delay_trmnt),
    delay_trmnt = factor(delay_trmnt, levels = c("No", "Yes")),
    
    first_symp = case_when(
      first_symp == "br_lump" ~ "Breast lump",
      first_symp == "br_pain" ~ "Breast pain",
      first_symp == "lump_ax" ~ "Axillary lump",
      TRUE ~ NA_character_
    ),
    first_symp = factor(first_symp, levels = c("Breast lump", "Breast pain", "Axillary lump")),
    
    first_doctor = case_when(
      first_doctor == "homio"    ~ "Homeopathy practitioner",
      first_doctor == "surg"     ~ "Surgeon",
      first_doctor == "gynac"    ~ "Gynecologist",
      first_doctor == "med"      ~ "Medicine specialist",
      first_doctor == "gp"       ~ "General practitioner (GP)",
      first_doctor == "quak"     ~ "Quack",
      first_doctor == "shop"     ~ "Medicine shop/pharmacy",
      first_doctor == "gov_hosp" ~ "Government hospital OPD",
      first_doctor == "others"   ~ "Others",
      TRUE ~ NA_character_
    ),
    first_doctor = factor(first_doctor, levels = c(
      "Homeopathy practitioner", "Surgeon", "Gynecologist", "Medicine specialist",
      "General practitioner (GP)", "Quack", "Medicine shop/pharmacy",
      "Government hospital OPD", "Others"
    )),
    
    # 3-level recode used for Table 4 (Homeopathy / Surgeon / Others)
    first_doctor3 = case_when(
      first_doctor == "Homeopathy practitioner" ~ "Homeopathy",
      first_doctor == "Surgeon"                 ~ "Surgeon",
      !is.na(first_doctor)                      ~ "Others",
      TRUE ~ NA_character_
    ),
    first_doctor3 = factor(first_doctor3, levels = c("Homeopathy", "Surgeon", "Others")),
    
    # Binary recode used for Table 5 (Homeopathy vs Others)
    first_doctor_bin = factor(
      if_else(first_doctor == "Homeopathy practitioner", "Homeopathy", "Others"),
      levels = c("Others", "Homeopathy")
    ),
    
    sympseek = as.numeric(sympseek),
    time_to_seek = case_when(
      sympseek <= 1  ~ "0\u20131 months",
      sympseek <= 3  ~ "1\u20133 months",
      sympseek <= 6  ~ "3\u20136 months",
      sympseek <= 12 ~ "6\u201312 months",
      sympseek > 12  ~ ">12 months",
      TRUE ~ NA_character_
    ),
    time_to_seek = factor(time_to_seek, levels = c("0\u20131 months", "1\u20133 months",
                                                   "3\u20136 months", "6\u201312 months", ">12 months")),
    
    # Misinterpretation of symptoms as non-serious (from free-text cause_delay)
    misinterp = if_else(str_detect(coalesce(cause_delay, ""), "nothing serious"), "Yes", "No"),
    misinterp = factor(misinterp, levels = c("No", "Yes"))
    
    # NOTE: The dataset has no standalone "awareness of breast cancer" variable.
    # The closest field, know_bse (knowledge of breast self-exam), is almost
    # constant (205/206 = "No") and cannot be used as a meaningful predictor.
    # Table 5 in the template includes this row; confirm with the original
    # codebook whether a separate awareness variable exists before adding it
    # back into the regression model below.
  ) %>%
  set_variable_labels(
    age_group         = "Age group (years)",
    gender            = "Gender",
    education         = "Education level",
    occupation        = "Occupation",
    marriage          = "Marital status",
    income            = "Monthly income (BDT)",
    slt_cat           = "Smokeless tobacco (SLT) use",
    stage_cat         = "Cancer stage",
    residence         = "Place of residence",
    education_bin     = "Education level",
    income_bin        = "Monthly income (BDT)",
    occupation_bin    = "Occupation",
    first_doctor      = "First healthcare provider consulted",
    first_doctor3     = "First healthcare provider",
    first_doctor_bin  = "First healthcare provider",
    first_symp        = "First symptom noticed",
    time_to_seek      = "Time to seek medical care",
    delayed_care      = "Delay in seeking medical care",
    misinterp         = "Misinterpretation of symptoms as non-serious"
  )

# ── Comorbidities (Table 1) ──────────────────────────────────────────────────
# NOTE: raw "comor" is a multiple-response code field (e.g. "2,11") with no
# codebook supplied. Mapping below is INFERRED by matching code frequencies
# to the Table 1 counts (None=161, Hypertension=16, Diabetes=11, Asthma=11,
# Other malignancy=2) and is NOT guaranteed to be exactly correct — please
# verify against the original survey codebook before using in publication.
comor_map <- c(
  "8"  = "None",
  "11" = "Hypertension",
  "1"  = "Diabetes mellitus",
  "2"  = "Asthma",
  "10" = "Other malignancy",
  "7"  = "Other malignancy"   # only appears once, combined with code 11
)
df <- df %>%
  mutate(
    comor_first = str_trim(str_split_fixed(as.character(comor), ",", 2)[, 1]),
    comorbidity = recode(comor_first, !!!comor_map, .default = NA_character_),
    comorbidity = factor(comorbidity, levels = c("None", "Hypertension", "Diabetes mellitus",
                                                 "Asthma", "Other malignancy"))
  ) %>%
  set_variable_labels(comorbidity = "Comorbidities")


# ── 2. Helper: bivariate tbl_summary (matches template style) ────────────────
make_bivariate_tbl <- function(data, dep_var, ind_vars) {
  data %>%
    select(all_of(ind_vars), all_of(dep_var)) %>%
    tbl_summary(
      by      = all_of(dep_var),
      statistic = list(all_categorical() ~ "{n} ({p}%)"),
      missing = "no"
    ) %>%
    add_p(
      test = list(all_categorical() ~ "chisq.test"),
      pvalue_fun = ~ style_pvalue(.x, digits = 3)
    ) %>%
    bold_p(t = 0.05) %>%
    modify_header(label ~ "**Variable**") %>%
    bold_labels() %>%
    suppressMessages()
}




# ── TABLE 1: Socio-demographic and clinical characteristics (n = 206) ────────
tbl1_age <- df %>%
  select(age) %>%
  tbl_summary(statistic = all_continuous() ~ "{mean} \u00b1 {sd}",
              label = age ~ "Age (years), Mean \u00b1 SD") %>%
  modify_header(label ~ "**Variable**", stat_0 ~ "**Frequency (%)**") %>%
  suppressMessages()

tbl1_ageband <- df %>%
  select(age_group) %>%
  tbl_summary(statistic = all_categorical() ~ "{n} ({p}%)", missing = "no",
              label = age_group ~ "Age group (years)") %>%
  modify_header(label ~ "**Variable**", stat_0 ~ "**Frequency (%)**") %>%
  suppressMessages()

tbl1_rest <- df %>%
  select(gender, education, occupation, marriage, income, slt_cat,
         comorbidity, stage_cat) %>%
  tbl_summary(statistic = all_categorical() ~ "{n} ({p}%)", missing = "no") %>%
  modify_header(label ~ "**Variable**", stat_0 ~ "**Frequency (%)**") %>%
  suppressMessages()

tbl1 <- tbl_stack(list(tbl1_age, tbl1_ageband, tbl1_rest), quiet = TRUE) %>%
  bold_labels() %>%
  suppressMessages()


# ── TABLE 2: Symptom profile and healthcare-seeking behavior (n = 206) ───────
# Part A: presenting symptoms (multiple response) — built manually since the
# raw "symptoms" field allows more than one selection per patient.
symptoms_tbl <- tibble(
  Category = c("Breast lump", "Axillary lump",
               "Metastatic symptoms (bone pain/SOB/headache/jaundice)",
               "Nipple discharge", "Other symptoms"),
  n = c(
    sum(str_detect(df$symptoms, "breast lump"), na.rm = TRUE),
    sum(str_detect(df$symptoms, "axilary lump"), na.rm = TRUE),
    sum(str_detect(df$symptoms, "metastatic"), na.rm = TRUE),
    sum(str_detect(df$symptoms, "nipple"), na.rm = TRUE),
    sum(str_detect(df$symptoms, "others"), na.rm = TRUE)
  )
) %>%
  mutate(`Frequency (%)` = paste0(n, " (", round(100 * n / nrow(df), 2), ")")) %>%
  select(Category, `Frequency (%)`)

tbl2_symp <- flextable(symptoms_tbl) %>%
  add_header_lines("Presenting symptoms") %>%
  bold(part = "header") %>%
  autofit()

tbl2_firstsymp <- df %>%
  select(first_symp) %>%
  tbl_summary(statistic = all_categorical() ~ "{n} ({p}%)", missing = "no") %>%
  modify_header(label ~ "**Variable**", stat_0 ~ "**Frequency (%)**") %>%
  suppressMessages()

tbl2_provider <- df %>%
  select(first_doctor) %>%
  tbl_summary(statistic = all_categorical() ~ "{n} ({p}%)", missing = "no") %>%
  modify_header(label ~ "**Variable**", stat_0 ~ "**Frequency (%)**") %>%
  suppressMessages()

tbl2_time <- df %>%
  select(time_to_seek) %>%
  tbl_summary(statistic = all_categorical() ~ "{n} ({p}%)", missing = "no") %>%
  modify_header(label ~ "**Variable**", stat_0 ~ "**Frequency (%)**") %>%
  suppressMessages()

tbl2_gt <- tbl_stack(list(tbl2_firstsymp, tbl2_provider, tbl2_time), quiet = TRUE) %>%
  bold_labels() %>%
  suppressMessages()

tbl2_gt_ft <- as_flex_table(tbl2_gt)


# ── TABLE 3: Causes of delay in seeking care & treatment initiation ──────────
# Part A: delay in seeking medical care (n = 123, i.e. delayed_care == "Yes")
delay_seek <- df %>% filter(delayed_care == "Yes")
n_seek <- nrow(delay_seek)

causesA <- tibble(
  `Cause of delay` = c(
    "Use of traditional treatment (homeopathy)",
    "Misinterpretation of symptoms as non-serious",
    "Belief symptoms would resolve spontaneously",
    "Financial constraints",
    "Social stigma",
    "Fear of cancer diagnosis/treatment outcome",
    "Others"
  ),
  n = c(
    sum(str_detect(delay_seek$cause_delay, "traditional treatment"), na.rm = TRUE),
    sum(str_detect(delay_seek$cause_delay, "nothing serious"), na.rm = TRUE),
    sum(str_detect(delay_seek$cause_delay, "relief by itself"), na.rm = TRUE),
    sum(str_detect(delay_seek$cause_delay, "financial problem"), na.rm = TRUE),
    sum(str_detect(delay_seek$cause_delay, "social stigma"), na.rm = TRUE),
    sum(str_detect(delay_seek$cause_delay, "fear of treatment"), na.rm = TRUE),
    sum(str_detect(delay_seek$cause_delay, "^others$"), na.rm = TRUE)
  )
) %>%
  mutate(`Frequency (%)` = paste0(n, " (", round(100 * n / n_seek, 2), ")")) %>%
  select(`Cause of delay`, `Frequency (%)`)

# Part B: delay in treatment initiation (n = 28, i.e. delay_trmnt == "Yes")
# NOTE: "Continued use of homeopathy" (2 cases in the template) has no clear
# match in causesdelayedrx — verify this category against the raw codebook.
delay_rx <- df %>% filter(delay_trmnt == "Yes")
n_rx <- nrow(delay_rx)

causesB <- tibble(
  `Cause of delay` = c(
    "Financial constraints",
    "Fear of chemotherapy/radiotherapy/surgery",
    "Doctor did not advise timely treatment",
    "Continued use of homeopathy",
    "Others"
  ),
  n = c(
    sum(str_detect(delay_rx$causesdelayedrx, "financial problem"), na.rm = TRUE),
    sum(str_detect(delay_rx$causesdelayedrx, "fear of chemotherapy"), na.rm = TRUE),
    sum(str_detect(delay_rx$causesdelayedrx, "doctor didnt"), na.rm = TRUE),
    sum(str_detect(delay_rx$causesdelayedrx, "homeo"), na.rm = TRUE),
    sum(str_detect(delay_rx$causesdelayedrx, "^others$"), na.rm = TRUE)
  )
) %>%
  mutate(`Frequency (%)` = paste0(n, " (", round(100 * n / n_rx, 2), ")")) %>%
  select(`Cause of delay`, `Frequency (%)`)

tbl3A_ft <- flextable(causesA) %>%
  add_header_lines(paste0("A. Delay in seeking medical care (n = ", n_seek, ")")) %>%
  bold(part = "header") %>%
  autofit()

tbl3B_ft <- flextable(causesB) %>%
  add_header_lines(paste0("B. Delay in treatment initiation (n = ", n_rx, ")")) %>%
  bold(part = "header") %>%
  autofit()



# ── TABLE 4: Association between factors and delay in seeking care (n=206) ───

df_mod <- df %>% 
  filter(delay_trmnt=="No")

tbl4 <- df_mod %>%
  select(residence, education_bin, income_bin, occupation_bin, slt_cat,
         stage_cat, first_doctor3, delayed_care) %>%
  tbl_summary(
    by = delayed_care,
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing = "no",
    label = list(
      residence        ~ "Residence",
      education_bin    ~ "Education level",
      income_bin       ~ "Monthly income (BDT)",
      occupation_bin   ~ "Occupation",
      slt_cat          ~ "Smokeless tobacco use (SLT)",
      stage_cat        ~ "Cancer stage",
      first_doctor3    ~ "First healthcare provider"
    )
  ) %>%
  add_p(test = list(all_categorical() ~ "chisq.test"),
        pvalue_fun = ~ style_pvalue(.x, digits = 3)) %>%
  bold_p(t = 0.05) %>%
  modify_header(
    label  ~ "**Variable**",
    stat_2 ~ "**Delay**",
    stat_1 ~ "**No delay**"
  ) %>%
  bold_labels() %>%
  suppressMessages()


# ── TABLE 5: Binary logistic regression — factors for delay in seeking care ──
# NOTE: "Awareness of breast cancer" from the template is excluded — the
# dataset's closest field (know_bse) is ~constant (205/206 "No") and unusable
# as a predictor. Confirm with the original codebook if a proper awareness
# variable exists and add it back into the formulas below if so.

# Age: template shows a single "Grouped" row -> median-split binary variable
df_mod <- df_mod %>%
  mutate(
    age_bin = factor(if_else(age >= median(age, na.rm = TRUE), "\u2265 median age", "< median age"),
                     levels = c("< median age", "\u2265 median age"))
  )



reg_vars <- c("stage_cat", "age_group", "residence", "education_bin", "income_bin",
              "occupation_bin", "slt_cat", "first_doctor_bin") #, "misinterp")

reg_labels <- list(
  stage_cat        ~ "Cancer stage",
  age_group        ~ "Age",
  residence        ~ "Residence",
  education_bin    ~ "Education",
  income_bin       ~ "Monthly income",
  occupation_bin   ~ "Occupation",
  slt_cat          ~ "Smokeless tobacco use",
  first_doctor_bin ~ "First healthcare provider"
  # misinterp        ~ "Misinterpretation of symptoms"
)

# Univariable (crude) odds ratios
tbl5_cor <- df_mod %>%
  select(all_of(reg_vars), delayed_care_bin) %>%
  tbl_uvregression(
    method = glm,
    y = delayed_care_bin,
    method.args = list(family = binomial(link = "logit")),
    exponentiate = TRUE,
    label = reg_labels,
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  suppressWarnings() %>%
  suppressMessages()

# Multivariable (adjusted) model
m_delay <- glm(
  delayed_care_bin ~ stage_cat + age_group + residence + education_bin +
    income_bin + occupation_bin + slt_cat + first_doctor_bin, # + misinterp,
  data   = df_mod,
  family = binomial(link = "logit")
)

tbl5_aor <- m_delay %>%
  tbl_regression(
    exponentiate = TRUE,
    label = reg_labels,
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  bold_p(t = 0.05) %>%
  suppressMessages()

tbl5 <- tbl_merge(
  list(tbl5_cor, tbl5_aor),
  tab_spanner = c("**COR (95% CI)**", "**AOR (95% CI)**")
) %>%
  modify_header(label ~ "**Variable**") %>%
  bold_labels() %>%
  suppressMessages()


# ── 3. Export all tables to a Word document ───────────────────────────────────
to_ft <- function(tbl) tbl %>% as_flex_table()

doc <- read_docx()

add_section <- function(doc, title, tbl_ft) {
  doc %>%
    body_add_par(value = title, style = "centered") %>%
    body_add_flextable(value = tbl_ft) %>%
    body_add_par(value = "") %>%
    body_add_par(value = "")
}

doc <- doc %>%
  add_section("Table 1: Socio-demographic and clinical characteristics of breast cancer patients (n = 206)", to_ft(tbl1)) %>%
  add_section("Table 2: Symptom profile and healthcare-seeking behavior among breast cancer patients (n = 206) \u2013 Presenting symptoms", tbl2_symp) %>%
  add_section("Table 2 (cont.): First symptom noticed, first provider consulted, time to seek care", tbl2_gt_ft) %>%
  add_section("Table 3: Causes of delay in seeking medical care and treatment initiation \u2013 A. Delay in seeking medical care", tbl3A_ft) %>%
  add_section("Table 3 (cont.): B. Delay in treatment initiation", tbl3B_ft) %>%
  add_section("Table 4: Association between socio-demographic/clinical factors and delay in seeking medical care (n = 178)", to_ft(tbl4)) %>%
  add_section("Table 5: Binary logistic regression analysis of factors associated with delay in seeking medical care", to_ft(tbl5))

out_path <- "doc/replicated_tables_breast_cancer.docx"
doc %>% print(target = out_path)
message("\u2705 Saved: ", out_path)