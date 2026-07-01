library(tidyverse)
library(gtsummary)
library(flextable)
library(officer)
library(openxlsx)
library(labelled)

select <- dplyr::select

# ── 1. Load & clean data ──────────────────────────────────────────────────────
df_raw <- read.xlsx("Data/data.xlsx", sheet = 1)

df <- df_raw %>%
  rename(
    age                = age,
    marital            = marital_status,
    education          = education,
    household_income   = monthly_income_bdt,
    residence          = residence,
    duration_living    = duration_living_dhaka_years,
    duration_working   = employment_duration,
    primary_job        = primary_job_task,
    working_hr_day     = working_hours_day,
    workplace_toilet   = toilet_availability,
    workplace_water    = drinking_water_access,
    absorbent_type     = absorbent_type,
    afford_pads        = afford_pads,
    drying_cloth       = drying_reusable_cloth,
    uti_any            = uti_any,
    lower_abdominal    = lower_abdominal_pain_discomfort,
    lower_back         = lower_back_flank_pain,
    burning_urination  = burning_pain_urination,
    frequent_urination = frequent_urgent_urination,
    cloudy_urine       = cloudy_dark_bloody_urine,
    rti_any            = rti_any,
    vaginal_discharge  = abnormal_vaginal_discharge,
    vaginal_odor       = foul_smelling_vaginal_odor,
    genital_itching    = genital_itching_irritation,
    menstrual_cycle    = menstrual_cycle_regularity,
    menstrual_irreg    = menstrual_irregularity,
    dysmenorrhea       = dysmenorrhea,
    heavy_bleeding     = heavy_menstrual_bleeding,
    missed_cycle       = missed_menstrual_cycle_past_12m,
    sought_treatment   = sought_treatment,
    healthcare_provider = healthcare_provider,
    barrier_finance    = barrier_financial_constraints,
    barrier_time       = barrier_lack_time_due_work,
    barrier_embarrass  = barrier_embarrassment_shyness,
    barrier_distance   = barrier_distance_facility,
    barrier_female_prov = barrier_lack_female_provider,
    barrier_employer   = barrier_employer_restrictions
  ) %>%
  mutate(
    # Age group
    age_group = case_when(
      age %in% 18:25 ~ "18–25",
      age %in% 26:35 ~ "26–35",
      age > 35       ~ ">35",
      TRUE           ~ NA_character_
    ),
    age_group = factor(age_group, levels = c("18–25", "26–35", ">35")),
    
    # Ordered factors matching document
    marital = factor(marital, levels = c("Single", "Married", "Divorced/Widowed/Separated")),
    education = factor(education, levels = c("No formal education", "Primary", "Secondary", "Higher secondary or above")),
    household_income = factor(household_income, levels = c("<10000", "10000-20000", ">20000", "Don't know")),
    residence = factor(residence, levels = c("Dhaka city", "Outside Dhaka but working in Dhaka", "Other")),
    duration_working = factor(duration_working, levels = c("<3 months", "3-12 months", ">1 year")),
    primary_job = factor(primary_job, levels = c("Brick breaking", "Cleaning", "General laborer", "Material carrying", "Other")),
    working_hr_day = factor(working_hr_day, levels = c("<6 hours", "6-8 hours", ">8 hours")),
    workplace_toilet = factor(workplace_toilet, levels = c("Clean/private", "Unclean/shared", "No toilet facility")),
    workplace_water = factor(workplace_water, levels = c("Adequate access", "Limited access", "No access")),
    absorbent_type = factor(absorbent_type, levels = c("Sanitary pads", "Reusable cloth", "Others")),
    afford_pads = factor(afford_pads, levels = c("Yes, easily", "Sometimes difficult", "No")),
    drying_cloth = factor(drying_cloth, levels = c("Direct sunlight/open space", "Indoors/hidden place", "Not applicable")),
    
    # Recode working hours for bivariate (≤8 vs >8)
    working_hr_bin = factor(
      if_else(working_hr_day == ">8 hours", ">8 hours", "≤8 hours"),
      levels = c("≤8 hours", ">8 hours")
    ),
    
    # Recode water access for bivariate (Adequate vs Limited/No)
    water_bin = factor(
      if_else(workplace_water == "Adequate access", "Adequate access", "Limited/No access"),
      levels = c("Adequate access", "Limited/No access")
    ),
    
    # Healthcare provider – only among those who sought treatment
    healthcare_provider = factor(healthcare_provider,
                                 levels = c("Government health facility", "Private clinic/hospital",
                                            "Pharmacy/drug seller", "Traditional healer/other", "Not sought"))
  ) %>%
  set_variable_labels(
    age_group        = "Age group (years)",
    marital          = "Marital status",
    education        = "Educational status",
    household_income = "Monthly household income (BDT)",
    residence        = "Place of residence",
    duration_living  = "Duration of living in Dhaka (years)",
    duration_working = "Duration of employment in construction work",
    primary_job      = "Primary job task",
    working_hr_day   = "Working hours per day",
    workplace_toilet = "Workplace toilet availability",
    workplace_water  = "Workplace drinking water access",
    absorbent_type   = "Type of absorbent used",
    afford_pads      = "Ability to afford sanitary pads",
    drying_cloth     = "Drying reusable cloth",
    uti_any          = "Any UTI symptom",
    lower_abdominal  = "Lower abdominal pain/discomfort",
    lower_back       = "Lower back/flank pain",
    burning_urination = "Burning/pain during urination",
    frequent_urination = "Frequent/urgent urination",
    cloudy_urine     = "Cloudy/dark/bloody urine",
    rti_any          = "Any RTI symptom",
    vaginal_discharge = "Abnormal vaginal discharge",
    vaginal_odor     = "Foul-smelling vaginal odor",
    genital_itching  = "Genital itching/irritation",
    menstrual_irreg  = "Menstrual irregularity",
    dysmenorrhea     = "Dysmenorrhea",
    heavy_bleeding   = "Heavy menstrual bleeding",
    missed_cycle     = "Missed menstrual cycle",
    working_hr_bin   = "Working hours/day",
    water_bin        = "Drinking water access",
    age              = "Age (years)"
  )


# ── 2. Helper: bivariate tbl_summary ─────────────────────────────────────────
make_bivariate_tbl <- function(data, dep_var, ind_vars) {
  data %>%
    select(all_of(ind_vars), all_of(dep_var)) %>%
    tbl_summary(
      by      = all_of(dep_var),
      statistic = list(
        all_continuous()  ~ "{mean} ± {sd}",
        all_categorical() ~ "{n} ({p}%)"
      ),
      digits  = all_continuous() ~ 1,
      missing = "no"
    ) %>%
    add_p(
      test = list(
        all_continuous()  ~ "t.test",
        all_categorical() ~ "chisq.test"
      ),
      pvalue_fun = ~ style_pvalue(.x, digits = 3)
    ) %>%
    bold_p(t = 0.05) %>%
    modify_header(label ~ "**Variable**") %>%
    bold_labels() %>% 
    suppressMessages()
}


# ── TABLE 1: Socio-demographic characteristics ────────────────────────────────
tbl1 <- df %>%
  select(age_group, marital, education, household_income,
         residence, duration_working, duration_living) %>%
  tbl_summary(
    statistic = list(
      all_continuous()  ~ "{mean} ± {sd}",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits  = all_continuous() ~ 2,
    missing = "no",
    label   = list(
      age_group        ~ "Age group (years)",
      marital          ~ "Marital status",
      education        ~ "Educational status",
      household_income ~ "Monthly household income (BDT)",
      residence        ~ "Place of residence",
      duration_working ~ "Duration of employment in construction work",
      duration_living  ~ "Duration of living in Dhaka (years)"
    )
  ) %>%
  modify_header(label ~ "**Variable**",
                stat_0 ~ "**n (%)**") %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 2: Workplace and menstrual hygiene characteristics ─────────────────
tbl2 <- df %>%
  select(primary_job, working_hr_day, workplace_toilet,
         workplace_water, absorbent_type, afford_pads, drying_cloth) %>%
  tbl_summary(
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no",
    label = list(
      primary_job      ~ "Primary job task",
      working_hr_day   ~ "Working hours per day",
      workplace_toilet ~ "Workplace toilet availability",
      workplace_water  ~ "Workplace drinking water access",
      absorbent_type   ~ "Type of absorbent used",
      afford_pads      ~ "Ability to afford sanitary pads",
      drying_cloth     ~ "Drying reusable cloth"
    )
  ) %>%
  modify_header(label ~ "**Variable**",
                stat_0 ~ "**n (%)**") %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 3: UTI and RTI prevalence ──────────────────────────────────────────
tbl3 <- df %>%
  select(uti_any, lower_abdominal, lower_back, burning_urination,
         frequent_urination, cloudy_urine,
         rti_any, vaginal_discharge, vaginal_odor, genital_itching) %>%
  tbl_summary(
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no"
  ) %>%
  modify_header(label ~ "**Variable**",
                stat_0 ~ "**n (%)**") %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 4: Menstrual health outcomes ───────────────────────────────────────
tbl4 <- df %>%
  select(menstrual_irreg, dysmenorrhea, heavy_bleeding, missed_cycle) %>%
  tbl_summary(
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no"
  ) %>%
  modify_header(label ~ "**Variable**",
                stat_0 ~ "**n (%)**") %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 5: Factors associated with UTI ─────────────────────────────────────
# Dep var: uti_any; ind vars: age_group, working_hr_bin, workplace_toilet, water_bin, absorbent_type
tbl5 <- df %>%
  select(age_group, working_hr_bin, workplace_toilet,
         water_bin, absorbent_type, uti_any) %>%
  tbl_summary(
    by      = uti_any,
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing = "no",
    label = list(
      age_group        ~ "Age (years)",
      working_hr_bin   ~ "Working hours/day",
      workplace_toilet ~ "Workplace toilet availability",
      water_bin        ~ "Drinking water access",
      absorbent_type   ~ "Absorbent type"
    )
  ) %>%
  add_p(
    test  = list(all_categorical() ~ "chisq.test"),
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  bold_p(t = 0.05) %>%
  modify_spanning_header(all_stat_cols() ~ "**UTI Symptom**") %>%
  modify_header(
    label    ~ "**Variable**",
    stat_1   ~ "**Absent**<br>N = {n}",
    stat_2   ~ "**Present**<br>N = {n}"
  ) %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 6: Factors associated with RTI ─────────────────────────────────────
# Filter drying_cloth to exclude "Not applicable"
df_drying <- df %>% filter(drying_cloth != "Not applicable") %>%
  mutate(drying_cloth = droplevels(drying_cloth))

tbl6_base <- df %>%
  select(workplace_toilet, absorbent_type, afford_pads, rti_any) %>%
  tbl_summary(
    by      = rti_any,
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing = "no",
    label = list(
      workplace_toilet ~ "Workplace toilet availability",
      absorbent_type   ~ "Absorbent type",
      afford_pads      ~ "Ability to afford sanitary pads"
    )
  ) %>%
  add_p(test = list(all_categorical() ~ "chisq.test"),
        pvalue_fun = ~ style_pvalue(.x, digits = 3)) %>%
  bold_p(t = 0.05) %>%
  bold_labels() %>% 
  suppressMessages()

tbl6_drying <- df_drying %>%
  select(drying_cloth, rti_any) %>%
  tbl_summary(
    by      = rti_any,
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing = "no",
    label = list(drying_cloth ~ "Drying reusable cloth")
  ) %>%
  add_p(test = list(all_categorical() ~ "chisq.test"),
        pvalue_fun = ~ style_pvalue(.x, digits = 3)) %>%
  bold_p(t = 0.05) %>%
  bold_labels() %>% 
  suppressMessages()

tbl6 <- tbl_stack(list(tbl6_base, tbl6_drying), quiet = TRUE) %>%
  modify_spanning_header(all_stat_cols() ~ "**RTI Symptom**") %>%
  modify_header(
    label  ~ "**Variable**",
    stat_1 ~ "**Absent**<br>N = {n}",
    stat_2 ~ "**Present**<br>N = {n}"
  ) %>%
  suppressMessages()


# ── TABLE 7: Factors associated with menstrual irregularity ──────────────────
tbl7 <- df %>%
  select(age_group, workplace_toilet, water_bin,
         absorbent_type, afford_pads, dysmenorrhea, menstrual_irreg) %>%
  tbl_summary(
    by      = menstrual_irreg,
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing = "no",
    label = list(
      age_group        ~ "Age (years)",
      workplace_toilet ~ "Workplace toilet availability",
      water_bin        ~ "Drinking water access",
      absorbent_type   ~ "Absorbent type",
      afford_pads      ~ "Ability to afford sanitary pads",
      dysmenorrhea     ~ "Dysmenorrhea"
    )
  ) %>%
  add_p(test = list(all_categorical() ~ "chisq.test"),
        pvalue_fun = ~ style_pvalue(.x, digits = 3)) %>%
  bold_p(t = 0.05) %>%
  modify_spanning_header(all_stat_cols() ~ "**Menstrual Cycle**") %>%
  modify_header(
    label  ~ "**Variable**",
    stat_1 ~ "**Regular**<br>N = {n}",
    stat_2 ~ "**Irregular**<br>N = {n}"
  ) %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 8: Healthcare-seeking behaviour ────────────────────────────────────
tbl8 <- df %>%
  select(healthcare_provider) %>%
  tbl_summary(
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing = "no",
    label = list(
      healthcare_provider        ~ "Sought treatment for reproductive health problems"
    )
  ) %>%
  bold_labels() %>% 
  suppressMessages()



# ── TABLE 9: Barriers ────────────────────────────────────────────────────────
barriers <- c("barrier_finance", "barrier_time", "barrier_embarrass",
              "barrier_distance", "barrier_female_prov", "barrier_employer")

tbl9 <- df %>%
  select(all_of(barriers)) %>%
  tbl_summary(
    statistic = list(all_categorical() ~ "{n} ({p}%)"),
    missing   = "no",
    label = list(
      barrier_finance     ~ "Financial constraints",
      barrier_time        ~ "Lack of time due to work",
      barrier_embarrass   ~ "Embarrassment/shyness",
      barrier_distance    ~ "Distance to healthcare facility",
      barrier_female_prov ~ "Lack of female healthcare provider",
      barrier_employer    ~ "Employer restrictions"
    )
  ) %>%
  modify_header(label ~ "**Variable**",
                stat_0 ~ "**n (%)**") %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 10: Multivariable logistic regression – UTI ────────────────────────
df_model <- df %>%
  mutate(
    uti_bin   = if_else(uti_any == "Yes", 1L, 0L),
    rti_bin   = if_else(rti_any == "Yes", 1L, 0L),
    irreg_bin = if_else(menstrual_irreg == "Yes", 1L, 0L),
    afford_bin = factor(
      if_else(afford_pads == "Yes, easily", "Yes, easily", "Sometimes difficult/No"),
      levels = c("Yes, easily", "Sometimes difficult/No")
    ),
    drying_cloth_bin = factor(
      if_else(drying_cloth == "Indoors/hidden place", "Indoors/hidden place", "Direct sunlight/open space"),
      levels = c("Indoors/hidden place", "Direct sunlight/open space")
    )
  )

m_uti <- glm(
  uti_bin ~ age_group + working_hr_bin + workplace_toilet +
    water_bin + absorbent_type + afford_bin,
  data   = df_model,
  family = binomial(link = "logit")
)

tbl10 <- m_uti %>%
  tbl_regression(
    exponentiate = TRUE,
    label = list(
      age_group        ~ "Age group (years)",
      working_hr_bin   ~ "Working hours per day",
      workplace_toilet ~ "Workplace toilet availability",
      afford_bin        ~ "Workplace drinking water access",
      absorbent_type   ~ "Type of absorbent used",
      afford_bin       ~ "Ability to afford sanitary pads"
    ),
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  bold_p(t = 0.05) %>%
  modify_header(
    label    ~ "**Variable**",
    estimate ~ "**AOR**",
    p.value  ~ "**p-value**"
  ) %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 11: Multivariable logistic regression – RTI ────────────────────────
m_rti <- glm(
  rti_bin ~ workplace_toilet + absorbent_type + afford_bin + drying_cloth_bin,
  data   = df_model,
  family = binomial(link = "logit")
)

tbl11 <- m_rti %>%
  tbl_regression(
    exponentiate = TRUE,
    label = list(
      workplace_toilet ~ "Workplace toilet availability",
      absorbent_type   ~ "Absorbent type",
      afford_bin      ~ "Ability to afford sanitary pads",
      drying_cloth_bin     ~ "Drying of reusable cloth"
    ),
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  bold_p(t = 0.05) %>%
  modify_header(
    label    ~ "**Variable**",
    estimate ~ "**AOR**",
    p.value  ~ "**p-value**"
  ) %>%
  bold_labels() %>% 
  suppressMessages()


# ── TABLE 12: Multivariable logistic regression – Menstrual irregularity ──────
m_irreg <- glm(
  irreg_bin ~ age_group + workplace_toilet + workplace_water +
    absorbent_type + afford_bin + dysmenorrhea,
  data   = df_model,
  family = binomial(link = "logit")
)

tbl12 <- m_irreg %>%
  tbl_regression(
    exponentiate = TRUE,
    label = list(
      age_group        ~ "Age group (years)",
      workplace_toilet ~ "Toilet availability",
      workplace_water  ~ "Drinking water access",
      absorbent_type   ~ "Absorbent type",
      afford_bin      ~ "Ability to afford pads",
      dysmenorrhea     ~ "Dysmenorrhea"
    ),
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  bold_p(t = 0.05) %>%
  modify_header(
    label    ~ "**Variable**",
    estimate ~ "**AOR**",
    p.value  ~ "**p-value**"
  ) %>%
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
  add_section("Table 1: Socio-demographic characteristics (N=270)", to_ft(tbl1)) %>%
  add_section("Table 2: Workplace and menstrual hygiene characteristics (N=270)", to_ft(tbl2)) %>%
  add_section("Table 3: Prevalence of UTI, RTI and menstrual health outcomes (N=270)", to_ft(tbl3)) %>%
  add_section("Table 4: Prevalence of menstrual health outcomes (N=270)", to_ft(tbl4)) %>%
  add_section("Table 5: Factors associated with UTI symptoms (N=270)", to_ft(tbl5)) %>%
  add_section("Table 6: Factors associated with RTI symptoms (N=270)", to_ft(tbl6)) %>%
  add_section("Table 7: Factors associated with menstrual irregularity (N=270)", to_ft(tbl7)) %>%
  add_section("Table 8: Healthcare-seeking behaviour (N=270)", to_ft(tbl8)) %>%
  add_section("Table 9: Barriers to reproductive healthcare access (N=270)", to_ft(tbl9)) %>%
  add_section("Table 10: Multivariable logistic regression – UTI (N=270)", to_ft(tbl10)) %>%
  add_section("Table 11: Multivariable logistic regression – RTI (N=270)", to_ft(tbl11)) %>%
  add_section("Table 12: Multivariable logistic regression – Menstrual irregularity (N=270)", to_ft(tbl12))

out_path <- "doc/replicated_tables_v2.docx"
doc %>% print(target = out_path)
message("✅ Saved: ", out_path)

