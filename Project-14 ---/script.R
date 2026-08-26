# ============================================================
# Project 14 - NLR / NLPR and in-hospital mortality in sepsis
# ------------------------------------------------------------
# Reference paper being replicated:
#   Shi Y, Yang C, Chen L, Cheng M, Xie W.
#   "Predictive value of neutrophil-to-lymphocyte and platelet
#    ratio in in-hospital mortality in septic patients."
#   Heliyon 2022;8:e11498.   (Materials/PIIS2405844022027864.pdf)
#
# The paper carries four tables, which this project reproduces on
# our own cohort (Data/data.xlsx, "Data Input" sheet):
#   T1  Baseline characteristics, survivors vs non-survivors (+ p)
#   T2  Multivariable logistic regression: NLR(d5)  -> mortality
#   T3  Multivariable logistic regression: NLPR(d5) -> mortality
#   T4  ROC: cut-off / specificity / sensitivity / AUC / 95% CI / p
#       for NLR d1,d3,d5 and NLPR d1,d3,d5 + combined model
#
# PART 1 - DATA CLEANING  (this file)
#   Outputs: Data/sepsis_clean.rds
#            Data/sepsis_clean.csv
#            doc/cleaning_log.txt
#
# Key definitions taken from the paper (section 2.4):
#   NLR  = absolute neutrophil count / absolute lymphocyte count
#   NLPR = NLR * 100 / platelet count   (platelets in 10^9/L)
# Both are RE-DERIVED here from the raw counts rather than trusted
# from the hand-entered NLPR columns (11 of those disagree).
#
# Variables the paper used that our sheet does NOT carry:
#   APACHE II, ICU length of stay, CRRT, mechanical ventilation,
#   smoking, alcohol.  NEWS score (d1/d3/d5) is the severity score
#   available here and is used in place of APACHE II.
# ============================================================

library(readxl)
library(dplyr)
library(stringr)
library(tidyr)
library(forcats)
library(purrr)

RAW_XLSX  <- "Data/data.xlsx"
OUT_RDS   <- "Data/sepsis_clean.rds"
OUT_CSV   <- "Data/sepsis_clean.csv"
OUT_LOG   <- "doc/cleaning_log.txt"
OUT_DOCX  <- "doc/all_tables.docx"

dir.create("doc",   showWarnings = FALSE)
dir.create("Graph", showWarnings = FALSE)

LOG <- character(0)
note <- function(...) {
  msg <- paste0(...)
  LOG <<- c(LOG, msg)
  message(msg)
}

# ----------------------------------------------------------
# 0.  Helpers
# ----------------------------------------------------------

# numeric from free text: keeps digits / . / -, everything else drops.
# "not done", "Vasopressor", "" -> NA
num <- function(x) {
  s <- str_squish(as.character(x))
  s <- str_remove_all(s, "[^0-9.\\-]")
  suppressWarnings(as.numeric(ifelse(s == "" | s == "-" | s == ".", NA, s)))
}

# yes/no from free text ("Yes","yes","YES","no","NO", ...).
# blank_as_no = TRUE is used for the co-morbidity checkboxes, where the
# form was only ticked when the condition was present (see note below).
yn <- function(x, blank_as_no = FALSE) {
  v <- str_to_lower(str_squish(as.character(x)))
  out <- case_when(
    str_starts(v, "y") ~ "Yes",
    str_starts(v, "n") ~ "No",
    .default = NA_character_
  )
  if (blank_as_no) out[is.na(out)] <- "No"
  factor(out, levels = c("No", "Yes"))
}

# Increasing / Decreasing / Stable / Fluctuating
trend <- function(x) {
  v <- str_to_lower(str_squish(as.character(x)))
  case_when(
    str_detect(v, "incr")  ~ "Increasing",
    str_detect(v, "decr")  ~ "Decreasing",
    str_detect(v, "stab")  ~ "Stable",
    str_detect(v, "fluct") ~ "Fluctuating",
    .default = NA_character_
  ) %>% factor(levels = c("Increasing", "Decreasing", "Stable", "Fluctuating"))
}

# culture result from free text
cult <- function(x) {
  v <- str_to_lower(str_squish(as.character(x)))
  case_when(
    str_detect(v, "posi")                        ~ "Positive",
    str_detect(v, "nega|nrgative")               ~ "Negative",
    str_detect(v, "not done|not sent|not study") ~ "Not done",
    .default = NA_character_
  )
}

# dates are hand-typed dd.mm.yy with ".", "," and "/" separators
parse_dmy <- function(x) {
  s <- str_squish(as.character(x))
  s <- str_replace_all(s, "[,/\\-]", ".")
  s <- str_remove_all(s, " ")
  m  <- str_match(s, "^(\\d{1,2})\\.(\\d{1,2})\\.(\\d{2,4})$")
  d  <- suppressWarnings(as.integer(m[, 2]))
  mo <- suppressWarnings(as.integer(m[, 3]))
  y  <- suppressWarnings(as.integer(m[, 4]))
  y  <- ifelse(!is.na(y) & y < 100, 2000 + y, y)
  ok <- !is.na(d) & !is.na(mo) & !is.na(y) & d >= 1 & d <= 31 & mo >= 1 & mo <= 12
  out <- rep(as.Date(NA), length(s))
  out[ok] <- as.Date(sprintf("%04d-%02d-%02d", y[ok], mo[ok], d[ok]))
  out
}

# ----------------------------------------------------------
# 1.  Read the raw sheet
# ------------------------------------------------------------
# Sheet layout:  row 1 = section banner, row 2 = variable labels,
# row 3 = coding scheme, row 4 = blank spacer, row 5+ = patients.
# ----------------------------------------------------------
raw <- read_excel(RAW_XLSX, sheet = "Data Input", skip = 1,
                  col_types = "text", .name_repair = "minimal")
raw <- raw[-(1:2), ]                                    # coding row + spacer

stopifnot(ncol(raw) == 73)
stopifnot(str_squish(names(raw)[1]) == "Study ID No.")

var_names <- c(
  # --- A. administrative -------------------------------------------------
  "study_id", "enrol_date", "ward",
  # --- B. demographics ---------------------------------------------------
  "age_years", "sex", "contact_no",
  # --- C. co-morbidities / infection -------------------------------------
  "dm", "htn", "ckd", "cld", "ihd", "copd", "comorbid_other",
  "infection_source", "antimicrobial_started", "antimicrobial_name",
  # --- D. day-0 vitals ---------------------------------------------------
  "rr_day0", "spo2_day0", "oxygen_day0", "sbp_day0", "pulse_day0",
  "temp_day0", "gcs_day0",
  # --- E. NEWS -----------------------------------------------------------
  "news_day1", "news_day3", "news_day5", "news_trend",
  # --- F. SOFA (day 0) ---------------------------------------------------
  "sofa_resp_value",   "sofa_resp_score",
  "sofa_coag_value",   "sofa_coag_score",
  "sofa_liver_value",  "sofa_liver_score",
  "sofa_cardio_value", "sofa_cardio_score",
  "sofa_cns_value",    "sofa_cns_score",
  "sofa_renal_value",  "sofa_renal_score",
  "total_sofa_raw",
  # --- G. haematology ----------------------------------------------------
  "anc_day1", "alc_day1", "plt_day1", "nlpr_day1_raw",
  "anc_day3", "alc_day3", "plt_day3", "nlpr_day3_raw",
  "anc_day5", "alc_day5", "plt_day5", "nlpr_day5_raw",
  "nlpr_trend",
  # --- H. biochemistry ---------------------------------------------------
  "creatinine", "bilirubin", "alt", "ast",
  "sodium", "potassium", "rbg", "lactate",
  # --- I. microbiology ---------------------------------------------------
  "blood_culture", "blood_culture_organism",
  "urine_culture", "sputum_culture", "other_culture",
  # --- J. imaging --------------------------------------------------------
  "cxr_status", "cxr_findings", "usg_status", "usg_findings", "other_imaging",
  # --- K. outcome --------------------------------------------------------
  "outcome", "exit_date"
)
names(raw) <- var_names

# drop rows that are entirely empty
raw <- raw %>% filter(if_any(everything(), ~ !is.na(.x) & str_squish(.x) != ""))
note("Rows read from 'Data Input': ", nrow(raw))

# ----------------------------------------------------------
# 2.  Clean / recode
# ----------------------------------------------------------
dat <- raw %>%
  mutate(
    row_id = row_number(), .before = 1
  ) %>%
  mutate(

    # ---- A. administrative -------------------------------------------
    # NB: the "Study ID No." column was actually filled with the patient's
    #     district, so it is kept as `district`, not as an identifier.
    district   = na_if(str_squish(study_id), ""),
    ward       = na_if(str_squish(ward), ""),
    enrol_date = parse_dmy(enrol_date),
    exit_date  = parse_dmy(exit_date),

    # ---- B. demographics ---------------------------------------------
    age_years = num(age_years),
    age_grp   = cut(age_years,
                    breaks = c(-Inf, 39, 59, 74, Inf),
                    labels = c("<40", "40-59", "60-74", "75+")),
    sex = case_when(
      str_starts(str_to_lower(str_squish(sex)), "m") ~ "Male",
      str_starts(str_to_lower(str_squish(sex)), "f") ~ "Female",
      .default = NA_character_
    ) %>% factor(levels = c("Male", "Female")),

    # ---- C. co-morbidities -------------------------------------------
    # The checkbox columns were only filled in when the condition was
    # present (59/103 rows leave every box empty), so an empty cell is
    # read as "No" rather than as missing.
    dm   = yn(dm,   blank_as_no = TRUE),
    htn  = yn(htn,  blank_as_no = TRUE),
    ckd  = yn(ckd,  blank_as_no = TRUE),
    cld  = yn(cld,  blank_as_no = TRUE),
    ihd  = yn(ihd,  blank_as_no = TRUE),
    copd = yn(copd, blank_as_no = TRUE),

    # ---- infection source (free text, occasionally multi-site) --------
    src_txt          = str_to_lower(str_squish(infection_source)),
    src_respiratory  = str_detect(src_txt, "respi|reswpi"),
    src_urinary      = str_detect(src_txt, "urin"),
    src_gi           = str_detect(src_txt, "gastro"),
    src_skin         = str_detect(src_txt, "skin|soft"),
    src_cns          = str_detect(src_txt, "\\bcns\\b"),
    src_bloodstream  = str_detect(src_txt, "bloodstream"),
    src_other        = str_detect(src_txt, "other|arthritis|puerperal"),

    antimicrobial_started = yn(antimicrobial_started),
    antimicrobial_name    = na_if(str_squish(str_to_title(antimicrobial_name)), ""),

    # ---- D. day-0 vitals ---------------------------------------------
    rr_day0     = num(rr_day0),
    spo2_day0   = num(spo2_day0),
    oxygen_day0 = yn(oxygen_day0),
    sbp_day0    = num(sbp_day0),
    pulse_day0  = num(pulse_day0),
    # column is labelled "Temperature (deg C)" but every value is 84-104,
    # i.e. it was recorded in Fahrenheit. Kept as-is + converted copy.
    temp_f_day0 = num(temp_day0),
    temp_c_day0 = round((temp_f_day0 - 32) * 5 / 9, 1),
    gcs_day0    = num(gcs_day0),

    # ---- E. NEWS -------------------------------------------------------
    news_day1  = num(news_day1),
    news_day3  = num(news_day3),
    news_day5  = num(news_day5),
    news_trend = trend(news_trend),

    # ---- F. SOFA -------------------------------------------------------
    pf_ratio          = num(sofa_resp_value),      # PaO2/FiO2, day 0
    sofa_resp_score   = num(sofa_resp_score),
    plt_sofa          = num(sofa_coag_value),      # absolute count (/uL)
    sofa_coag_score   = num(sofa_coag_score),
    bili_sofa         = num(sofa_liver_value),
    sofa_liver_score  = num(sofa_liver_score),
    map_day0          = num(sofa_cardio_value),    # NA where "Vasopressor"
    sofa_cardio_score = num(sofa_cardio_score),
    gcs_sofa          = num(sofa_cns_value),
    sofa_cns_score    = num(sofa_cns_score),
    creat_sofa        = num(sofa_renal_value),
    sofa_renal_score  = num(sofa_renal_score),
    total_sofa_raw    = num(total_sofa_raw),
    # SOFA cardiovascular >= 2 means a vasopressor was running
    vasopressor = factor(ifelse(sofa_cardio_score >= 2, "Yes", "No"),
                         levels = c("No", "Yes")),

    # ---- G. haematology (10^9/L) ---------------------------------------
    across(c(anc_day1, alc_day1, plt_day1,
             anc_day3, alc_day3, plt_day3,
             anc_day5, alc_day5, plt_day5,
             nlpr_day1_raw, nlpr_day3_raw, nlpr_day5_raw), num),
    nlpr_trend = trend(nlpr_trend),

    # ---- H. biochemistry -----------------------------------------------
    across(c(creatinine, bilirubin, alt, ast,
             sodium, potassium, rbg, lactate), num),

    # ---- I. microbiology -------------------------------------------------
    # "Blood Culture" was filled with "Done" for 21 patients and the actual
    # result written in the organism column, so the two are merged.
    blood_culture = coalesce(
      cult(blood_culture_organism),
      ifelse(!is.na(blood_culture_organism) &
               str_squish(blood_culture_organism) != "", "Positive", NA_character_),
      cult(blood_culture)
    ) %>% factor(levels = c("Negative", "Positive", "Not done")),
    blood_culture_organism = na_if(str_squish(blood_culture_organism), ""),
    urine_culture  = cult(urine_culture)  %>% factor(levels = c("Negative", "Positive", "Not done")),
    sputum_culture = cult(sputum_culture) %>% factor(levels = c("Negative", "Positive", "Not done")),

    # ---- J. imaging ------------------------------------------------------
    cxr_done     = yn(str_replace(str_to_lower(str_squish(cxr_status)), "^done$", "yes")),
    cxr_abnormal = factor(
      ifelse(str_detect(str_to_lower(str_squish(cxr_findings)), "^normal( study)?$"),
             "No", "Yes"), levels = c("No", "Yes")),
    usg_done     = yn(str_replace(str_to_lower(str_squish(usg_status)), "^done$", "yes")),
    usg_abnormal = factor(
      ifelse(str_detect(str_to_lower(str_squish(usg_findings)), "^normal( study)?$"),
             "No", "Yes"), levels = c("No", "Yes")),

    # ---- K. outcome ------------------------------------------------------
    outcome = case_when(
      str_detect(str_to_lower(str_squish(outcome)), "non")    ~ "Non-survivor",
      str_detect(str_to_lower(str_squish(outcome)), "surviv") ~ "Survivor",
      .default = NA_character_
    ) %>% factor(levels = c("Survivor", "Non-survivor")),
    death = as.integer(outcome == "Non-survivor")
  )

# ----------------------------------------------------------
# 3.  Derived variables + targeted fixes
# ----------------------------------------------------------

# 3a. length of follow-up.  A single enrolment date carries a year typo
#     ("3.9.26"), which puts discharge before admission; roll it back a year.
dat <- dat %>%
  mutate(
    enrol_date = if_else(!is.na(exit_date) & !is.na(enrol_date) & exit_date < enrol_date,
                         enrol_date - 365, enrol_date),
    los_days   = as.numeric(exit_date - enrol_date)
  )
note("Enrolment dates repaired for an out-of-range year: ",
     sum(!is.na(dat$los_days) & dat$los_days >= 0 &
           parse_dmy(raw$enrol_date) != dat$enrol_date, na.rm = TRUE))
note("Follow-up (days) range: ", min(dat$los_days, na.rm = TRUE), " - ",
     max(dat$los_days, na.rm = TRUE),
     "  [fixed 5-7 day study window, NOT true hospital LOS]")

# 3b. implausible platelet counts.  Every genuine value is >= 36 x10^9/L;
#     two day-3 cells hold 7.45 and 6.03, which are NLPR-sized, not platelet
#     counts.  They are voided rather than guessed at.
PLT_MIN <- 20
plt_bad <- dat %>%
  select(row_id, plt_day1, plt_day3, plt_day5) %>%
  pivot_longer(-row_id, names_to = "var", values_to = "value") %>%
  filter(!is.na(value), value < PLT_MIN)
if (nrow(plt_bad)) {
  note("Implausible platelet counts (< ", PLT_MIN, " x10^9/L) set to NA:")
  walk2(plt_bad$var, plt_bad$value, ~ note("   row ", plt_bad$row_id[plt_bad$var == .x & plt_bad$value == .y][1],
                                           "  ", .x, " = ", .y))
}
dat <- dat %>%
  mutate(across(c(plt_day1, plt_day3, plt_day5),
                ~ ifelse(!is.na(.x) & .x < PLT_MIN, NA_real_, .x)))

# 3c. NLR and NLPR, re-derived from the raw counts (paper, section 2.4)
dat <- dat %>%
  mutate(
    nlr_day1  = anc_day1 / alc_day1,
    nlr_day3  = anc_day3 / alc_day3,
    nlr_day5  = anc_day5 / alc_day5,
    nlpr_day1 = nlr_day1 * 100 / plt_day1,
    nlpr_day3 = nlr_day3 * 100 / plt_day3,
    nlpr_day5 = nlr_day5 * 100 / plt_day5
  )

nlpr_diff <- dat %>%
  select(row_id, ends_with("_raw") & starts_with("nlpr"),
         nlpr_day1, nlpr_day3, nlpr_day5) %>%
  pivot_longer(-row_id) %>%
  mutate(day = str_extract(name, "day\\d"),
         kind = ifelse(str_detect(name, "_raw$"), "entered", "derived")) %>%
  select(-name) %>%
  pivot_wider(names_from = kind, values_from = value) %>%
  filter(!is.na(entered), !is.na(derived), abs(entered - derived) > 0.5)
note("NLPR cells where the entered value disagrees with ANC/ALC/PLT by > 0.5: ",
     nrow(nlpr_diff), " (derived values are used throughout)")

# 3d. total SOFA re-summed from its six components
dat <- dat %>%
  mutate(
    total_sofa = sofa_resp_score + sofa_coag_score + sofa_liver_score +
                 sofa_cardio_score + sofa_cns_score + sofa_renal_score,
    sofa_mismatch = !is.na(total_sofa_raw) & total_sofa_raw != total_sofa
  )
note("Total SOFA recomputed from components; entered total disagreed in ",
     sum(dat$sofa_mismatch, na.rm = TRUE), " rows and was missing in ",
     sum(is.na(dat$total_sofa_raw)), " row(s).")

# 3e. single primary infection site (for a one-row-per-patient summary)
dat <- dat %>%
  mutate(
    n_sites = src_respiratory + src_urinary + src_gi + src_skin +
              src_cns + src_bloodstream + src_other,
    infection_site = case_when(
      n_sites > 1      ~ "Multiple",
      src_respiratory  ~ "Respiratory",
      src_urinary      ~ "Urinary",
      src_gi           ~ "Gastrointestinal",
      src_cns          ~ "CNS",
      src_skin         ~ "Skin/Soft tissue",
      src_bloodstream  ~ "Bloodstream",
      src_other        ~ "Others",
      .default = NA_character_
    ) %>% factor(levels = c("Respiratory", "Urinary", "Gastrointestinal",
                            "CNS", "Skin/Soft tissue", "Bloodstream",
                            "Others", "Multiple")),
    across(starts_with("src_") & where(is.logical),
           ~ factor(ifelse(.x, "Yes", "No"), levels = c("No", "Yes"))),
    comorbid_n = (dm == "Yes") + (htn == "Yes") + (ckd == "Yes") +
                 (cld == "Yes") + (ihd == "Yes") + (copd == "Yes"),
    comorbid_any = factor(ifelse(comorbid_n > 0, "Yes", "No"),
                          levels = c("No", "Yes"))
  )

# 3f. implausible biochemistry.  One ALT cell holds 0.6 U/L, which is a
#     bilirubin-sized number in a transaminase column; voided.
#     (ALT 128-228 in three patients is kept - those rows also carry a
#      raised AST and bilirubin, so they are genuine hepatic involvement.)
n_alt_bad <- sum(!is.na(dat$alt) & dat$alt < 5)
dat <- dat %>% mutate(alt = ifelse(!is.na(alt) & alt < 5, NA_real_, alt))
note("Implausible ALT values (< 5 U/L) set to NA: ", n_alt_bad)

# 3g. analysis set = everyone with a recorded outcome
dat <- dat %>% mutate(analysis_set = !is.na(outcome))

# ----------------------------------------------------------
# 4.  Final column selection
# ----------------------------------------------------------
clean <- dat %>%
  select(
    row_id, district, ward, enrol_date, exit_date, los_days,
    age_years, age_grp, sex,
    dm, htn, ckd, cld, ihd, copd, comorbid_n, comorbid_any,
    infection_site, src_respiratory, src_urinary, src_gi, src_skin,
    src_cns, src_bloodstream, src_other,
    antimicrobial_started, antimicrobial_name,
    rr_day0, spo2_day0, oxygen_day0, sbp_day0, pulse_day0,
    temp_f_day0, temp_c_day0, gcs_day0,
    news_day1, news_day3, news_day5, news_trend,
    pf_ratio, map_day0, vasopressor,
    sofa_resp_score, sofa_coag_score, sofa_liver_score,
    sofa_cardio_score, sofa_cns_score, sofa_renal_score,
    total_sofa, total_sofa_raw, sofa_mismatch,
    anc_day1, alc_day1, plt_day1, nlr_day1, nlpr_day1, nlpr_day1_raw,
    anc_day3, alc_day3, plt_day3, nlr_day3, nlpr_day3, nlpr_day3_raw,
    anc_day5, alc_day5, plt_day5, nlr_day5, nlpr_day5, nlpr_day5_raw,
    nlpr_trend,
    creatinine, bilirubin, alt, ast, sodium, potassium, rbg, lactate,
    blood_culture, blood_culture_organism, urine_culture, sputum_culture,
    cxr_done, cxr_abnormal, usg_done, usg_abnormal,
    outcome, death, analysis_set
  )

# ----------------------------------------------------------
# 5.  Cleaning / quality log
# ----------------------------------------------------------
note("")
note("--- cohort ---")
note("N cleaned            : ", nrow(clean))
note("Outcome recorded     : ", sum(clean$analysis_set),
     "  (", sum(!clean$analysis_set), " missing -> excluded from Tables 1-4)")
note("Survivors            : ", sum(clean$outcome == "Survivor", na.rm = TRUE))
note("Non-survivors        : ", sum(clean$outcome == "Non-survivor", na.rm = TRUE),
     "  (", round(100 * mean(clean$death, na.rm = TRUE), 1), "% mortality)")
note("Sex missing          : ", sum(is.na(clean$sex)))

note("")
note("--- missingness in the variables the four tables need ---")
key <- c("age_years", "sex", "total_sofa", "gcs_day0", "news_day1", "news_day3",
         "news_day5", "pf_ratio", "creatinine", "bilirubin", "lactate",
         "anc_day1", "alc_day1", "plt_day1", "nlr_day1", "nlpr_day1",
         "anc_day3", "alc_day3", "plt_day3", "nlr_day3", "nlpr_day3",
         "anc_day5", "alc_day5", "plt_day5", "nlr_day5", "nlpr_day5",
         "outcome")
miss <- tibble(variable = key,
               n_missing = map_int(key, ~ sum(is.na(clean[[.x]]))),
               pct = round(100 * map_int(key, ~ sum(is.na(clean[[.x]]))) / nrow(clean), 1))
walk(seq_len(nrow(miss)), ~ note(sprintf("  %-14s %3d (%.1f%%)",
                                         miss$variable[.x], miss$n_missing[.x], miss$pct[.x])))

note("")
note("--- data-quality flags to keep in mind when reading the tables ---")
note("  Age below the paper's 18-year inclusion floor : ",
     sum(clean$age_years < 18, na.rm = TRUE), " patient(s) (youngest ",
     min(clean$age_years, na.rm = TRUE), " y) - kept, flag for the client.")
note("  Serum lactate is exactly 0.5 in ",
     sum(clean$lactate == 0.5, na.rm = TRUE), "/", sum(!is.na(clean$lactate)),
     " rows - looks like an assay floor / placeholder, not a measurement.")
note("  Temperature column is labelled deg C but every value is 98-104,")
note("     i.e. Fahrenheit -> kept as temp_f_day0, converted as temp_c_day0.")
note("  Random blood glucose is labelled mg/dL but the values are mmol/L;")
note("     one patient reads ", max(clean$rbg, na.rm = TRUE),
     " mmol/L - extreme but left in place.")
note("  Follow-up is a fixed 5-7 day study window, so `los_days` is NOT")
note("     comparable with the paper's 'hospital stay' row.")

note("")
note("--- variables in the reference paper that this dataset does not carry ---")
note("  APACHE II score, ICU length of stay, CRRT, mechanical ventilation,")
note("  smoking history, alcohol history.")
note("  NEWS score (day 1/3/5) is used in place of APACHE II as the")
note("  severity covariate in the Table 2 / Table 3 regressions.")

# ----------------------------------------------------------
# 6.  Save
# ----------------------------------------------------------
# A file left open in Excel / Word is locked on Windows.  That should not
# abort the analysis half-way, so writes warn instead of erroring out.
safe_write <- function(expr, path) {
  tryCatch({
    force(expr)
    message("Saved -> ", path)
    invisible(TRUE)
  }, error = function(e) {
    warning("COULD NOT WRITE ", path,
            " - it is probably open in Excel or Word. Close it and re-run. (",
            conditionMessage(e), ")", call. = FALSE, immediate. = TRUE)
    invisible(FALSE)
  })
}

safe_write(saveRDS(clean, OUT_RDS), OUT_RDS)
safe_write(write.csv(clean, OUT_CSV, row.names = FALSE, na = ""), OUT_CSV)
safe_write(writeLines(LOG, OUT_LOG), OUT_LOG)


# ============================================================
# PART 2 - THE FOUR TABLES
# ------------------------------------------------------------
# Mirrors Tables 1-4 of Shi et al. (Heliyon 2022;8:e11498) on this
# cohort.  Substitutions / omissions:
#   * APACHE II was not collected. NEWS was the intended stand-in, but
#     NEWS separates the two outcome groups almost perfectly (see below)
#     and makes every coefficient in the model unidentifiable, so the
#     Table 2 / Table 3 models adjust for SOFA, sex and age only - the
#     paper's model minus the APACHE II term.
#   * ICU stay, CRRT, mechanical ventilation, smoking and alcohol are
#     not in this dataset and are dropped from Table 1.
#   * Hospital stay is dropped: follow-up here is a fixed 5-7 day
#     study window, not a length of stay.
#   * CKD and chronic liver disease were absent in all 103 patients,
#     so they carry no information and are dropped from Table 1.
#
# ** SEPARATION **
# NLPR (d5), NEWS (d3) and NEWS (d5) split survivors from non-survivors
# with NO overlap at all, and NEWS (d1) overlaps at a single value.
# Ordinary maximum-likelihood logistic regression is undefined under
# that kind of separation (glm reports "did not converge" and pushes
# coefficients toward infinity), so Tables 2 and 3 are fitted by
# Firth's penalized likelihood (logistf), which returns finite
# estimates and profile-likelihood confidence intervals.  Even under
# Firth, the covariates sitting alongside a perfect separator can have
# a one-sided unbounded profile interval; those bounds are printed as
# ">1000" / "<0.001" rather than as spurious precision.  The separation
# itself is a property of the data, not of the model, and is reported
# in the log.
#
# Output: doc/all_tables.docx
# ============================================================

library(gtsummary)
library(pROC)
library(logistf)
library(flextable)
library(officer)

theme_gtsummary_compact()
set_flextable_defaults(font.size = 9, padding = 3)

# Shared figure palette (Okabe-Ito, colour-blind safe). No red anywhere -
# graph.R uses the same two-colour version for the outcome bar charts.
PALETTE3   <- c("#0072B2", "#E69F00", "#009E73")   # blue / amber / green
PALETTE_OS <- c(Survivor = "#0072B2", `Non-survivor` = "#E69F00")

analysis <- clean %>% filter(analysis_set)
note("")
note("=== PART 2: tables built on ", nrow(analysis), " patients with a recorded outcome ===")

# ----------------------------------------------------------
# 7.  Separation check (drives the Table 2 / 3 model choice)
# ----------------------------------------------------------
sep_check <- function(v) {
  a <- analysis[[v]][analysis$death == 0]
  b <- analysis[[v]][analysis$death == 1]
  a <- a[!is.na(a)]; b <- b[!is.na(b)]
  tibble(variable = v,
         survivor = sprintf("%.2f - %.2f", min(a), max(a)),
         death    = sprintf("%.2f - %.2f", min(b), max(b)),
         separated = max(a) < min(b) | max(b) < min(a))
}
sep <- map_dfr(c("nlr_day1", "nlr_day3", "nlr_day5",
                 "nlpr_day1", "nlpr_day3", "nlpr_day5",
                 "news_day1", "news_day3", "news_day5",
                 "total_sofa", "age_years"), sep_check)
note("")
note("--- range overlap between survivors and non-survivors ---")
walk(seq_len(nrow(sep)), ~ note(sprintf("  %-11s survivors %-16s deaths %-16s %s",
                                        sep$variable[.x], sep$survivor[.x], sep$death[.x],
                                        ifelse(sep$separated[.x], "<-- COMPLETE SEPARATION", ""))))
note("  Firth penalized likelihood is therefore used for Tables 2 and 3, and")
note("  NEWS is left out of the adjustment set (it separates the groups too).")

# ----------------------------------------------------------
# TABLE 1 (a-e) - Characteristics of patients enrolled
# ----------------------------------------------------------
# The reference paper runs one long baseline table.  Here it is split into
# five, one per variable domain, so each fits a page and can be placed next
# to the text that discusses it.  Every panel keeps the same columns
# (Overall / Survivor / Non-survivor / p) and the same denominators.
#
# CKD and chronic liver disease are absent in all patients and carry no
# information, so they do not appear in 1a.

# the paper reports creatinine / bilirubin / oxygenation index as mean (SD)
# and everything else continuous as median (IQR)
mean_sd_vars <- c("creatinine", "bilirubin", "pf_ratio")
# scores with few distinct values that gtsummary would otherwise call
# categorical, but which the paper reports as scores
force_cont   <- c("gcs_day0", "total_sofa", "news_day1", "news_day3", "news_day5")

t1_groups <- list(
  "1a" = list(
    title  = "Table 1a. Demographic characteristics and co-morbidities",
    note   = "",
    labels = list(
      age_grp = "Age group (years)",
      sex     = "Sex",
      dm      = "Diabetes mellitus",
      htn     = "Hypertension",
      ihd     = "Ischaemic heart disease",
      copd    = "COPD"
    )
  ),
  "1b" = list(
    title  = "Table 1b. Source of infection and clinical management",
    note   = paste0("Source of infection is not mutually exclusive - two patients had two ",
                    "sites recorded, so the site rows do not sum to N. Vasopressor use is ",
                    "taken from a SOFA cardiovascular sub-score of 2 or more. "),
    labels = list(
      src_respiratory = "Respiratory",
      src_urinary     = "Urinary",
      src_gi          = "Gastrointestinal",
      src_cns         = "CNS",
      src_skin        = "Skin / soft tissue",
      src_other       = "Other",
      antimicrobial_started = "Antimicrobial therapy started",
      oxygen_day0     = "Supplemental oxygen",
      vasopressor     = "Vasopressor"
    )
  ),
  "1c" = list(
    title  = "Table 1c. Severity of illness scores",
    note   = paste0("NEWS, national early warning score; SOFA, sequential organ failure ",
                    "assessment; GCS, Glasgow coma scale. SOFA and GCS are day-0 values. "),
    labels = list(
      news_day1  = "NEWS, day 1",
      news_day3  = "NEWS, day 3",
      news_day5  = "NEWS, day 5",
      total_sofa = "SOFA",
      gcs_day0   = "GCS"
    )
  ),
  "1d" = list(
    title  = "Table 1d. Biochemical parameters",
    note   = paste0("Creatinine, total bilirubin and PaO2/FiO2 are mean (SD) and compared by ",
                    "t test, as in the reference paper; the rest are median (IQR). "),
    labels = list(
      creatinine = "Creatinine (mg/dL)",
      bilirubin  = "Total bilirubin (mg/dL)",
      pf_ratio   = "PaO2/FiO2 (mmHg)",
      alt        = "ALT (U/L)",
      ast        = "AST (U/L)",
      sodium     = "Sodium (mmol/L)",
      potassium  = "Potassium (mmol/L)",
      rbg        = "Random blood glucose (mmol/L)",
      lactate    = "Lactate (mmol/L)"
    )
  ),
  "1e" = list(
    title  = "Table 1e. Haematological parameters and derived ratios",
    note   = paste0("Neutrophil, lymphocyte and platelet counts are 10^9/L. ",
                    "NLR = neutrophil / lymphocyte; NLPR = NLR x 100 / platelet count. ",
                    "Day-3 platelet count and NLPR are missing for two patients whose ",
                    "recorded platelet value was implausible and was voided in cleaning. "),
    labels = list(
      anc_day1 = "Neutrophil, day 1", anc_day3 = "Neutrophil, day 3", anc_day5 = "Neutrophil, day 5",
      alc_day1 = "Lymphocyte, day 1", alc_day3 = "Lymphocyte, day 3", alc_day5 = "Lymphocyte, day 5",
      plt_day1 = "Platelet, day 1",   plt_day3 = "Platelet, day 3",   plt_day5 = "Platelet, day 5",
      nlr_day1 = "NLR, day 1",   nlr_day3 = "NLR, day 3",   nlr_day5 = "NLR, day 5",
      nlpr_day1 = "NLPR, day 1", nlpr_day3 = "NLPR, day 3", nlpr_day5 = "NLPR, day 5"
    )
  )
)

# any_of() rather than all_of(): each panel holds only some of these variables
make_t1 <- function(labels) {
  analysis %>%
    select(outcome, all_of(names(labels))) %>%
    tbl_summary(
      by = outcome,
      statistic = list(
        all_continuous()     ~ "{median} ({p25}-{p75})",
        any_of(mean_sd_vars) ~ "{mean} ({sd})",
        all_categorical()    ~ "{n} ({p}%)"
      ),
      type    = list(any_of(force_cont) ~ "continuous"),
      digits  = list(all_continuous() ~ 2, all_categorical() ~ c(0, 1)),
      missing = "no",
      label   = labels
    ) %>%
    add_overall(last = FALSE) %>%
    add_p(
      test = list(
        all_continuous()     ~ "wilcox.test",
        any_of(mean_sd_vars) ~ "t.test"
      ),
      pvalue_fun = label_style_pvalue(digits = 3)
    ) %>%
    bold_labels() %>%
    bold_p(t = 0.05) %>%
    modify_header(label = "**Characteristic**")
}

table1_list <- lapply(t1_groups, function(g) make_t1(g$labels))

# ----------------------------------------------------------
# TABLES 2 & 3 - Multivariable logistic regression (Firth)
# ----------------------------------------------------------
# Sex is releveled so that, as in the paper, the odds ratio reported is
# the one for male gender.
mdat <- analysis %>%
  filter(!is.na(sex)) %>%
  mutate(sex = fct_relevel(sex, "Female"))

# Age enters as the grouped variable, so each level gets its own row against
# the <40 reference.  The 75+ cell holds only 3 patients, so that row is
# estimable but wide - read it with the n in Table 1 alongside.
term_labels <- c(
  "nlr_day5"     = "NLR (d5)",
  "nlpr_day5"    = "NLPR (d5)",
  "sexMale"      = "Sex (male gender)",
  "age_grp40-59" = "Age 40-59 y (vs <40)",
  "age_grp60-74" = "Age 60-74 y (vs <40)",
  "age_grp75+"   = "Age 75+ y (vs <40)",
  "total_sofa"   = "SOFA"
)

# A profile-likelihood bound that ran off to infinity is shown as a bound,
# not as a number: printing "4.6e18" would imply a precision that is not there.
ci_num <- function(x) ifelse(x > 1000, ">1000", ifelse(x < 0.001, "<0.001", sprintf("%.3f", x)))

firth_table <- function(fit) {
  keep  <- names(coef(fit)) != "(Intercept)"
  terms <- names(coef(fit))[keep]
  tibble(
    Factor       = ifelse(is.na(term_labels[terms]), terms, unname(term_labels[terms])),
    `Odds ratio` = sprintf("%.3f", exp(coef(fit))[keep]),
    `95% CI`     = paste0(ci_num(exp(fit$ci.lower)[keep]), "-", ci_num(exp(fit$ci.upper)[keep])),
    P            = ifelse(fit$prob[keep] < 0.001, "<0.001", sprintf("%.3f", fit$prob[keep]))
  )
}

FIT_CTL <- logistf.control(maxit = 1000)
PL_CTL  <- logistpl.control(maxit = 1000)

fit_nlr  <- logistf(death ~ nlr_day5  + sex + age_grp + total_sofa,
                    data = mdat, control = FIT_CTL, plcontrol = PL_CTL)
fit_nlpr <- logistf(death ~ nlpr_day5 + sex + age_grp + total_sofa,
                    data = mdat, control = FIT_CTL, plcontrol = PL_CTL)

table2_df <- firth_table(fit_nlr)
table3_df <- firth_table(fit_nlpr)

mk_reg_ft <- function(df) {
  flextable(df) %>%
    bold(part = "header") %>%
    align(j = 2:4, align = "center", part = "all") %>%
    bold(i = ~ P == "<0.001" | suppressWarnings(as.numeric(P)) < 0.05, j = 4) %>%
    autofit()
}
table2 <- mk_reg_ft(table2_df)
table3 <- mk_reg_ft(table3_df)

# ----------------------------------------------------------
# TABLE 4 - Predictive value (ROC) of NLR and NLPR
# ----------------------------------------------------------
# Cut-off is the Youden-optimal point.  The AUC confidence interval and the
# test of AUC = 0.5 use DeLong variance; where an AUC of exactly 1 makes that
# variance zero, the equivalent exact Mann-Whitney test is reported instead.
roc_row <- function(score, outcome_bin, label) {
  ok <- !is.na(score) & !is.na(outcome_bin)
  s  <- score[ok]; y <- outcome_bin[ok]
  r  <- pROC::roc(y, s, quiet = TRUE, direction = "<")
  co <- pROC::coords(r, "best", best.method = "youden",
                     ret = c("threshold", "specificity", "sensitivity"),
                     transpose = FALSE)[1, ]
  a  <- as.numeric(pROC::auc(r))
  se <- suppressWarnings(sqrt(pROC::var(r, method = "delong")))
  if (is.finite(se) && se > 0) {
    ci <- as.numeric(pROC::ci.auc(r, method = "delong"))
    p  <- 2 * stats::pnorm(-abs((a - 0.5) / se))
    ci_txt <- sprintf("%.3f-%.3f", max(0, ci[1]), min(1, ci[3]))
  } else {
    p      <- suppressWarnings(stats::wilcox.test(s ~ y)$p.value)
    ci_txt <- "1.000-1.000"
  }
  tibble(
    Parameter       = label,
    `Cut-off value` = sprintf("%.3f", co$threshold),
    Specificity     = sprintf("%.3f", co$specificity),
    Sensitivity     = sprintf("%.3f", co$sensitivity),
    AUC             = sprintf("%.3f", a),
    `95% CI`        = ci_txt,
    P               = ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

# combined predictor: NLPR(d5) + age + SOFA, on the predicted-probability
# scale.  Fitted by Firth for the same separation reason as Tables 2-3.
fit_comb <- logistf(death ~ nlpr_day5 + age_grp + total_sofa, data = analysis,
                    control = FIT_CTL, plcontrol = PL_CTL)
X_comb   <- model.matrix(~ nlpr_day5 + age_grp + total_sofa, data = analysis)
analysis$pred_comb <- as.numeric(plogis(X_comb %*% coef(fit_comb)))

table4_df <- bind_rows(
  roc_row(analysis$nlr_day1,  analysis$death, "NLR (d1)"),
  roc_row(analysis$nlr_day3,  analysis$death, "NLR (d3)"),
  roc_row(analysis$nlr_day5,  analysis$death, "NLR (d5)"),
  roc_row(analysis$nlpr_day1, analysis$death, "NLPR (d1)"),
  roc_row(analysis$nlpr_day3, analysis$death, "NLPR (d3)"),
  roc_row(analysis$nlpr_day5, analysis$death, "NLPR (d5)"),
  roc_row(analysis$pred_comb, analysis$death, "NLPR (d5) & age & SOFA")
)

# the paper also quotes the NLPR value implied by the combined cut-off;
# solve the fitted logit for NLPR holding age and SOFA at their medians
# age now enters as a group, so the reference level (<40) contributes nothing
# to the linear predictor and only SOFA needs holding at its median.
p_star   <- as.numeric(table4_df$`Cut-off value`[table4_df$Parameter == "NLPR (d5) & age & SOFA"])
b        <- coef(fit_comb)
age_ref  <- levels(analysis$age_grp)[1]
sofa_med <- median(analysis$total_sofa, na.rm = TRUE)
nlpr_at_cut <- (qlogis(p_star) - b[["(Intercept)"]] -
                  b[["total_sofa"]] * sofa_med) / b[["nlpr_day5"]]

table4 <- flextable(table4_df) %>%
  bold(part = "header") %>%
  align(j = 2:7, align = "center", part = "all") %>%
  autofit()

# ----------------------------------------------------------
# ROC curves (the paper's Figures 1 and 2)
# ----------------------------------------------------------
# Titles are left off every figure - the caption in the manuscript carries them.
roc_png <- function(vars, labels, file) {
  png(file, width = 6.5, height = 6, units = "in", res = 300)
  on.exit(dev.off(), add = TRUE)
  cols <- PALETTE3
  for (i in seq_along(vars)) {
    r <- pROC::roc(analysis$death, analysis[[vars[i]]], quiet = TRUE, direction = "<")
    pROC::plot.roc(r, add = i > 1, col = cols[i], lwd = 2,
                   legacy.axes = TRUE, main = "",
                   xlab = "1 - Specificity", ylab = "Sensitivity")
  }
  aucs <- map_dbl(vars, ~ as.numeric(pROC::auc(pROC::roc(
    analysis$death, analysis[[.x]], quiet = TRUE, direction = "<"))))
  legend("bottomright", bty = "n", lwd = 2, col = cols[seq_along(vars)],
         legend = sprintf("%s (AUC %.3f)", labels, aucs))
}
roc_png(c("nlr_day1", "nlr_day3", "nlr_day5"),
        c("NLR day 1", "NLR day 3", "NLR day 5"),
        "Graph/Fig1_ROC_NLR.png")
roc_png(c("nlpr_day1", "nlpr_day3", "nlpr_day5"),
        c("NLPR day 1", "NLPR day 3", "NLPR day 5"),
        "Graph/Fig2_ROC_NLPR.png")

# ----------------------------------------------------------
# EXPORT - all four tables in ONE Word document
# ----------------------------------------------------------
fx <- function(tbl) tbl %>% as_flex_table() %>% fontsize(size = 8, part = "all") %>% autofit()

# shared across the five Table 1 panels; each panel appends its own `note`
foot1_common <- paste0(
  "Values are median (IQR) or n (%). P values: Mann-Whitney U test for median (IQR) rows, ",
  "chi-square or Fisher exact test for categorical rows. ",
  "One patient with an unrecorded outcome is excluded from every panel, and one with ",
  "unrecorded sex from the sex row. IQR, interquartile range."
)
foot23 <- paste0(
  "Firth penalized-likelihood logistic regression with profile-likelihood confidence intervals, ",
  "used because NLPR (d5) separates the two outcome groups completely and ordinary maximum ",
  "likelihood does not converge. Adjusted for sex, age group and SOFA, with age <40 years as the ",
  "reference group. The APACHE II term of the ",
  "reference paper has no counterpart here: APACHE II was not recorded, and the NEWS score - the ",
  "available stand-in - also separates the outcome groups, which leaves every coefficient in the ",
  "model unidentifiable. A confidence bound shown as \">1000\" or \"<0.001\" is not estimable: the ",
  "profile likelihood is flat in that direction once a perfect separator is in the model. ",
  "Female sex is the reference category. CI, confidence interval."
)
foot4 <- paste0(
  "Cut-off is the Youden-optimal point. The AUC confidence interval and the test of AUC = 0.5 use ",
  "the DeLong method; where the AUC is exactly 1 that variance is zero and the equivalent exact ",
  "Mann-Whitney test is reported instead. The combined row is on the predicted-probability scale of a ",
  "Firth logistic model containing NLPR (d5), age group and SOFA; ",
  sprintf("at that cut-off, for the %s year age group and SOFA at its median (%g), the corresponding NLPR (d5) is %.2f. ",
          age_ref, sofa_med, nlpr_at_cut),
  "AUC, area under the ROC curve; CI, confidence interval."
)

small <- fp_text(font.size = 8, italic = TRUE)
add_foot <- function(d, txt) body_add_fpar(d, fpar(ftext(txt, small)))

doc <- read_docx()

# Tables 1a-1e, each on its own page
for (k in names(t1_groups)) {
  g <- t1_groups[[k]]
  doc <- doc %>%
    body_add(paste0(g$title, " (N = ", nrow(analysis), ")"), style = "heading 1") %>%
    body_add_flextable(fx(table1_list[[k]])) %>%
    add_foot(paste0(g$note, foot1_common)) %>%
    body_add_break()
}

doc <- doc %>%
  body_add("Table 2. Multivariable logistic regression exploring the association of NLR (d5) with in-hospital mortality",
           style = "heading 1") %>%
  body_add_flextable(table2) %>%
  add_foot(foot23) %>%
  body_add("") %>%

  body_add("Table 3. Multivariable logistic regression exploring the association of NLPR (d5) with in-hospital mortality",
           style = "heading 1") %>%
  body_add_flextable(table3) %>%
  add_foot(foot23) %>%
  body_add_break() %>%

  body_add("Table 4. Predictive value of NLR and NLPR at different time points for in-hospital mortality of sepsis patients",
           style = "heading 1") %>%
  body_add_flextable(table4) %>%
  add_foot(foot4)

safe_write(print(doc, target = OUT_DOCX), OUT_DOCX)

# ----------------------------------------------------------
# console summary
# ----------------------------------------------------------
note("")
note("--- Table 2: NLR(d5) model (Firth) ---")
walk(capture.output(print(as.data.frame(table2_df), row.names = FALSE)), note)
note("--- Table 3: NLPR(d5) model (Firth) ---")
walk(capture.output(print(as.data.frame(table3_df), row.names = FALSE)), note)
note("--- Table 4: ROC ---")
walk(capture.output(print(as.data.frame(table4_df), row.names = FALSE)), note)

safe_write(writeLines(LOG, OUT_LOG), OUT_LOG)
message("Saved -> Graph/Fig1_ROC_NLR.png")
message("Saved -> Graph/Fig2_ROC_NLPR.png")
