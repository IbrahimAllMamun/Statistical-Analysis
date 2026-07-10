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

df_mod <- df 

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














# Graph

# ══════════════════════════════════════════════════════════════════════════
# GRAPH 1 — Bivariate associations with delay in seeking medical care
# Uses: df_mod (delay_trmnt == "No" subset), variables from Table 4
# Requires: df_mod already built by analysis.R (stage_cat, first_doctor3,
#           residence, education_bin, income_bin, occupation_bin, slt_cat,
#           delayed_care)
# ══════════════════════════════════════════════════════════════════════════
library(tidyverse)
library(scales)
library(patchwork)

# ── Panel A: Cancer stage × delay (100% stacked bar) — significant, p < 0.001
plotA <- df_mod %>%
  filter(!is.na(stage_cat), !is.na(delayed_care)) %>%
  count(stage_cat, delayed_care) %>%
  group_by(stage_cat) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup() %>%
  ggplot(aes(x = stage_cat, y = pct, fill = delayed_care)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = paste0(n, "\n(", percent(pct, accuracy = 1), ")")),
            position = position_stack(vjust = 0.5), size = 3, color = "white") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("No" = "#4C72B0", "Yes" = "#55A868"),
                    name = "Delay in seeking care") +
  labs(title = "",
       x = "Cancer stage at diagnosis", y = "Proportion of patients") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

# ── Panel B: First healthcare provider × delay (100% stacked bar) — p < 0.001
plotB <- df_mod %>%
  filter(!is.na(first_doctor3), !is.na(delayed_care)) %>%
  count(first_doctor3, delayed_care) %>%
  group_by(first_doctor3) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup() %>%
  ggplot(aes(x = first_doctor3, y = pct, fill = delayed_care)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = paste0(n, "\n(", percent(pct, accuracy = 1), ")")),
            position = position_stack(vjust = 0.5), size = 3, color = "white") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("No" = "#55A868", "Yes" = "#4C72B0"),
                    name = "Delay in seeking care") +
  labs(title = "",
       x = "First provider consulted", y = "Proportion of patients") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

# ── Panel C: Non-significant factors — % delayed by group (dot/point-range chart)
nonsig_vars <- c("residence", "education_bin", "income_bin", "occupation_bin", "slt_cat")
nonsig_labels <- c(
  residence      = "Residence",
  education_bin  = "Education",
  income_bin     = "Monthly income",
  occupation_bin = "Occupation",
  slt_cat        = "Smokeless tobacco use"
)

pct_delayed <- map_dfr(nonsig_vars, function(v) {
  df_mod %>%
    filter(!is.na(.data[[v]]), !is.na(delayed_care)) %>%
    count(group = .data[[v]], delayed_care) %>%
    group_by(group) %>%
    mutate(pct = n / sum(n), total = sum(n)) %>%
    ungroup() %>%
    filter(delayed_care == "Yes") %>%
    mutate(variable = nonsig_labels[[v]])
})

plotC <- pct_delayed %>%
  mutate(label = paste0(variable, ": ", group)) %>%
  ggplot(aes(x = pct, y = fct_reorder(label, pct))) +
  geom_segment(aes(x = 0, xend = pct, yend = label), color = "grey70") +
  geom_point(size = 3, color = "#55A868") +
  geom_text(aes(label = percent(pct, accuracy = 1)), hjust = -0.4, size = 3) +
  scale_x_continuous(labels = percent_format(), limits = c(0, 1),
                     expand = expansion(mult = c(0, 0.15))) +
  labs(title = "",
       x = "Proportion delayed", y = NULL) +
  theme_minimal(base_size = 11)

# ── Combine and save ─────────────────────────────────────────────────────
# Factors associated with delay in seeking medical care
fig_bivariate <- (plotA | plotB) / plotC +
  plot_layout(heights = c(1, 1)) +
  plot_annotation(
    title = "",
    theme = theme(plot.title = element_text(face = "bold", size = 13))
  )
# Factors associated with delay in seeking medical care
fig_bivariate2 <- (plotA | plotB) +
  plot_layout(heights = c(1, 1)) +
  plot_annotation(
    title = "",
    theme = theme(plot.title = element_text(face = "bold", size = 13))
  )

print(fig_bivariate2)

ggsave("graph/fig1.1_bivariate_stage_delay.png", plotA,
       width = 6.5, height = 5.5, dpi = 300)

ggsave("graph/fig1.1_bivariate_providerConsulted_delay.png", plotB,
       width = 6.5, height = 5.5, dpi = 300)

ggsave("graph/fig1.1_bivariate_other_delay.png", plotC,
       width = 6.5, height = 5.5,, dpi = 300)

ggsave("graph/fig1_bivariate_delay.png", fig_bivariate2,
       width = 7, height = 5.5,, dpi = 300)









# Forest Table
# ══════════════════════════════════════════════════════════════════════════
# GRAPH 2 — Forest plot: crude vs adjusted odds ratios for delay in seeking care
# Uses: df_mod, reg_vars, reg_labels, m_delay (multivariable model) from analysis.R
# Requires: broom
# ══════════════════════════════════════════════════════════════════════════
library(tidyverse)
library(broom)
library(scales)

# ── Adjusted (AOR) estimates from the multivariable model ───────────────────
aor_df <- tidy(m_delay, exponentiate = TRUE, conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  transmute(term, estimate, conf.low, conf.high, type = "AOR (adjusted)")

# ── Crude (COR) estimates — one univariable glm per predictor in reg_vars ──
cor_df <- map_dfr(reg_vars, function(v) {
  f <- as.formula(paste("delayed_care_bin ~", v))
  m <- glm(f, data = df_mod, family = binomial(link = "logit"))
  tidy(m, exponentiate = TRUE, conf.int = TRUE) %>%
    filter(term != "(Intercept)") %>%
    transmute(term, estimate, conf.low, conf.high, type = "COR (crude)")
}) %>%
  suppressWarnings() %>%
  suppressMessages()

# ── Combine, attach readable labels, order for display ─────────────────────
# Build a clean label for each regression term (variable name + category)
term_labels <- tribble(
  ~pattern,                     ~clean,
  "stage_catStage II",          "Stage II vs I",
  "stage_catStage III",         "Stage III vs I",
  "stage_catStage IV",          "Stage IV vs I",
  "age_group30\u201339",        "30\u201339 vs \u226429",
  "age_group40\u201349",        "40\u201349 vs \u226429",
  "age_group50\u201359",        "50\u201359 vs \u226429",
  "age_group60\u201369",        "60\u201369 vs \u226429",
  "age_group\u226570",          "\u226570 vs \u226429",
  "residenceRural",             "Residence: Rural vs Urban",
  "education_binLow education", "Education: Low vs High",
  "income_binLow income",       "Income: Low vs High",
  "occupation_binOthers",       "Occupation: Others vs Housewife",
  "slt_catYes",                 "Smokeless tobacco: Yes vs No",
  "first_doctor_binHomeopathy", "First provider: Homeopathy vs Others"
)

# Reference-category rows: only needed for variables with > 2 levels
# (stage_cat has 4, age_group has 6) so the base level still appears in the
# plot as a blank row (label only, no point/CI), matching how Table 5 shows
# "--- (Ref)". Binary variables don't need this since both levels already
# appear as a single comparison row.
ref_labels <- tibble(
  clean = c("Cancer stage: Stage I (Ref)", "Age: \u226429 (Ref)")
)
ref_rows <- ref_labels %>%
  crossing(type = c("COR (crude)", "AOR (adjusted)")) %>%
  mutate(term = NA_character_, estimate = NA_real_,
         conf.low = NA_real_, conf.high = NA_real_)

forest_df <- bind_rows(cor_df, aor_df) %>%
  left_join(term_labels, by = c("term" = "pattern")) %>%
  mutate(clean = coalesce(clean, term)) %>%
  filter(is.finite(conf.low), is.finite(conf.high)) %>%
  bind_rows(ref_rows)

# Order categories top-to-bottom, with each variable's reference row placed
# directly above its comparison rows
term_order <- c(
  "Cancer stage: Stage I (Ref)", "Stage II vs I", "Stage III vs I", "Stage IV vs I",
  "Age: \u226429 (Ref)", "30\u201339 vs \u226429", "40\u201349 vs \u226429",
  "50\u201359 vs \u226429", "60\u201369 vs \u226429", "\u226570 vs \u226429",
  "Residence: Rural vs Urban", "Education: Low vs High", "Income: Low vs High",
  "Occupation: Others vs Housewife", "Smokeless tobacco: Yes vs No",
  "First provider: Homeopathy vs Others"
)

# ── Bold the variable-level rows (reference rows + binary comparisons) ─────
# so they stand out from the indented sub-category rows (e.g. "Stage II vs I",
# "30-39 vs <=29"), which stay unbolded. Uses ggtext::element_markdown() to
# render **bold** markdown in the axis text.
bold_set <- c(
  "Cancer stage: Stage I (Ref)",
  "Age: \u226429 (Ref)",
  "Residence: Rural vs Urban",
  "Education: Low vs High",
  "Income: Low vs High",
  "Occupation: Others vs Housewife",
  "Smokeless tobacco: Yes vs No",
  "First provider: Homeopathy vs Others"
)

forest_df <- forest_df %>%
  mutate(clean = factor(clean, levels = rev(term_order)))

# Build plotmath expressions for the y-axis labels: bold() for the rows in
# bold_set, plain() for everything else. This avoids ggtext::element_markdown()
# (which can silently fail to parse depending on package/graphics-device setup
# and leave literal "**text**") in favor of base-R plotmath, which always renders.
level_order <- rev(term_order)
label_exprs <- do.call(expression, lapply(level_order, function(lbl) {
  if (lbl %in% bold_set) bquote(bold(.(lbl))) else bquote(plain(.(lbl)))
}))


# Crude vs. adjusted odds ratios for delay in seeking medical care
# ── Plot ─────────────────────────────────────────────────────────────────
fig_forest <- ggplot(forest_df, aes(x = estimate, y = clean, color = type)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey40") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high),
                  position = position_dodge(width = 0.5), size = 0.4, na.rm = TRUE) +
  scale_x_log10(breaks = c(0.1, 0.25, 0.5, 1, 2, 4, 8, 16, 32, 64, 128),
                labels = label_number(accuracy = 0.1)) +
  scale_y_discrete(labels = label_exprs) +
  scale_color_manual(values = c("COR (crude)" = "#4C72B0", "AOR (adjusted)" = "#C44E52"),
                     name = NULL) +
  labs(
    title = "",
    subtitle = "Points = OR, bars = 95% CI (log scale)",
    x = "Odds ratio (95% CI)", y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top",
        panel.grid.minor = element_blank())

print(fig_forest)

ggsave("graph/fig2_forest_plot_regression.png", fig_forest,
       width = 9, height = 8, dpi = 300)







# ══════════════════════════════════════════════════════════════════════════
# GRAPH 3 — "Big picture" alluvial/Sankey: care-seeking pathway
#           First provider consulted → Delay in seeking care → Cancer stage
# Uses: df (full cleaned dataset, before the delay_trmnt == "No" filter)
# Requires: ggalluvial  (install.packages("ggalluvial") if not yet installed)
# ══════════════════════════════════════════════════════════════════════════
library(tidyverse)
pacman::p_load(ggalluvial)

# Binarize cancer stage into Early (I-II) / Late (III-IV) so the diagram
# stays readable with 3 flow stages -- change back to stage_cat directly
# if you want all 4 stages shown instead.
alluvial_df <- df %>%
  filter(!is.na(first_doctor3), !is.na(delayed_care), !is.na(stage_cat)) %>%
  mutate(
    stage_group = if_else(stage_cat %in% c("Stage I", "Stage II"),
                          "Early stage (I\u2013II)", "Late stage (III\u2013IV)"),
    stage_group = factor(stage_group, levels = c("Early stage (I\u2013II)", "Late stage (III\u2013IV)")),
    delay_label = if_else(delayed_care == "Yes", "Delayed care", "No delay")
  ) %>%
  count(first_doctor3, delay_label, stage_group, name = "freq")

fig_alluvial <- ggplot(alluvial_df,
                       aes(axis1 = first_doctor3, axis2 = delay_label, axis3 = stage_group, y = freq)) +
  geom_alluvium(aes(fill = first_doctor3), width = 1/4, alpha = 0.8) +
  geom_stratum(width = 1/4, fill = "grey93", color = "grey40") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = 3.2) +
  scale_x_discrete(limits = c("First provider consulted", "Delay in seeking care", "Cancer stage at diagnosis"),
                   expand = c(0.08, 0.08)) +
  scale_fill_manual(values = c("Homeopathy" = "#4C72B0", "Surgeon" = "#55A868", "Others" = "#21e2f2"),
                    name = "First provider") +
  labs(
    title = "Care-seeking pathway: provider \u2192 delay \u2192 stage at diagnosis",
    subtitle = "Flow width = number of patients (n = 206)",
    x = NULL, y = "Number of patients"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom",
        panel.grid = element_blank(),
        axis.text.y = element_blank())

print(fig_alluvial)

ggsave("graph/fig3_alluvial_pathway.png", fig_alluvial,
       width = 10, height = 7, dpi = 300)



















































# ══════════════════════════════════════════════════════════════════════════
# TABLE 4 (updated) — adds test statistic, df, and effect size alongside p
# per reviewer comment: "Alongside p-values, report the test statistic
# (t/chi2/F as applicable) and name the statistical test in legends/text.
# For chi2/ANOVA and similar tests, include degrees of freedom and an
# appropriate effect size measure."
#
# All variables in Table 4 are categorical vs. delayed_care (categorical),
# so the applicable test is Pearson's chi-squared test; the paired effect
# size measure is Cramer's V. Requires: df_mod as built earlier in analysis.R
# ══════════════════════════════════════════════════════════════════════════
library(tidyverse)
library(gtsummary)
library(flextable)

# ── Helper: chi-square statistic, df, and Cramer's V for one variable ──────
# Uses the uncorrected Pearson chi-square (correct = FALSE) so the reported
# statistic and the derived effect size are internally consistent; this is
# noted explicitly in the table footnote below.
chisq_effect_size <- function(data, variable, by) {
  tab <- table(data[[variable]], data[[by]])
  test <- suppressWarnings(chisq.test(tab, correct = FALSE))
  n <- sum(tab)
  k <- min(dim(tab))
  cramers_v <- sqrt(unname(test$statistic) / (n * (k - 1)))
  tibble(
    variable      = variable,
    stat_fmt      = sprintf("\u03c7\u00b2(%d) = %.2f", unname(test$parameter), unname(test$statistic)),
    cramers_v_fmt = sprintf("%.2f", cramers_v)
  )
}

table4_vars <- c("residence", "education_bin", "income_bin", "occupation_bin",
                 "slt_cat", "stage_cat", "first_doctor3")

test_stats_tbl4 <- map_dfr(table4_vars, chisq_effect_size,
                           data = df_mod, by = "delayed_care")

# ── Build Table 4 (categorical summary + p-value, as before) ───────────────
tbl4 <- df_mod %>%
  select(all_of(table4_vars), delayed_care) %>%
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
        test.args = all_categorical() ~ list(correct = FALSE),
        pvalue_fun = ~ style_pvalue(.x, digits = 3)) %>%
  bold_p(t = 0.05) %>%
  modify_header(
    label  ~ "**Variable**",
    stat_2 ~ "**Delay**",
    stat_1 ~ "**No delay**"
  ) %>%
  bold_labels()

# ── Inject test statistic + effect size onto each variable's label row ─────
tbl4 <- tbl4 %>%
  modify_table_body(
    ~ .x %>%
      left_join(test_stats_tbl4, by = "variable")
  ) %>%
  modify_header(
    stat_fmt      ~ "**Test statistic**",
    cramers_v_fmt ~ "**Effect size (Cram\u00e9r's V)**"
  ) %>%
  modify_table_styling(
    columns = c(stat_fmt, cramers_v_fmt),
    rows = row_type == "label",
    missing_symbol = ""
  ) %>%
  modify_footnote(
    update = c(stat_fmt, p.value) ~ "Pearson's chi-squared test (without continuity correction)",
    abbreviation = FALSE
  ) %>%
  suppressMessages()

# tbl4 now displays, per variable: Delay n(%) | No delay n(%) | Test statistic
# (chi2, df) | Cramer's V | p-value — ready for as_flex_table() / export as before.




df %>% select(all_of(table4_vars), delayed_care) %>% is.na() %>% colSums() %>% View


df %>% nrow()
