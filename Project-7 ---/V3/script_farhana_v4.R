# ============================================================
# Metastatic Breast Cancer (V3) - v4 tables, after questionnaire recheck
# Data source: Data/cancer_data_imputed.Farhana.xlsx   (imputed, n = 135)
#              Data/data.sav                           (client's SPSS source,
#                                                       used only for cross-checks)
#              Materials/"Short term outcome of metastatic breast cancer .docx"
#                                                      (coding scheme / questionnaire)
# ------------------------------------------------------------
# Supersedes script_farhana.R.  Every derived column that the recheck
# found to disagree with the questionnaire is now re-derived here from
# the raw coded columns rather than taken from the xlsx.
#
# WHAT CHANGED AND WHY (client's numbered queries):
#
# 1. METASTATIC SITES.  The questionnaire codes site of metastasis as
#    1 = lung, 2 = brain, 3 = liver, 4 = bone, 5 = opposite breast,
#    6 = others, 7 = multiple site.  The site columns carried in the
#    xlsx were built with a different map (V2/script.R line 45 comments
#    it as "2=Liver 3=Brain 5=Multiple 6=Opp.Breast"), so in the xlsx
#      Brain  actually holds code 3 = LIVER
#      Liver  actually holds code 2 = BRAIN
#      opposite_breast actually holds code 6 = OTHERS
#      Others actually holds code 5 = OPPOSITE BREAST
#    i.e. brain and liver are swapped, and others and opposite-breast
#    are swapped.  All seven flags are re-derived here from
#    `sitemetastasis` using the questionnaire codes.  This moves brain
#    metastasis from 55 (40.7%) to 13 (9.6%) and liver from 14 (10.4%)
#    to 55 (40.7%); lung and bone are unaffected.
#
#    Metastatic burden is also re-derived from the site list (1 site /
#    2-3 sites / >3 sites), because the recorded `mburden` field
#    disagrees with the patient's own site list in one row and with the
#    SPSS source in nine.  See the log for the row-by-row comparison.
#
# 2/3. HER2 AND MOLECULAR SUBTYPE.  `clinical_subtype` in the xlsx was
#    imputed as a variable in its own right instead of being derived
#    from the imputed ER/PR/HER2, so it contradicts them in 53 of 135
#    rows and HER2+ (61) does not equal HR+/HER2+ (38) + HR-/HER2+ (39)
#    = 77.  It should: the two are the same patients by definition.
#    Subtype is therefore rebuilt from ER/PR/HER2, after which
#    HR+/HER2+ (43) + HR-/HER2+ (18) = 61 = HER2+ exactly.
#    On the 49-52 rows where the receptors were actually observed the
#    xlsx subtype and the derived subtype agree perfectly - the
#    inconsistency is entirely inside the imputed rows.
#
# 5. RECURRENCE.  Prior stage and causes of recurrent metastasis are new
#    in Table 2b, which is restricted to the 72 recurrent-MBC patients
#    because neither variable is defined for de novo disease.  Causes are
#    re-parsed from `causesrmetast`: the questionnaire defines 1 =
#    treatment incomplete (a = CT not completed, b = RT not completed)
#    and 2 = completed but not within time.  The three flags in the
#    xlsx do not follow that scheme (CT_not_completed matched any "1",
#    so it is really "treatment incomplete"; RT_not_completed matched
#    code 2, which is "not within time"; Tx_not_in_time matched code 3,
#    which the questionnaire does not define at all).
#
# 6. HISTOLOGY.  Duct cell carcinoma (code 1, n = 48) and infiltrating
#    duct cell carcinoma (code 2, n = 74) are merged at the client's
#    instruction into one "Infiltrating duct cell carcinoma" row
#    (n = 122).  The remaining types are no longer lumped into "Others"
#    but kept separate: lobular cell carcinoma (5), infiltrating
#    adenocarcinoma (2), invasive carcinoma (6).
#
# 7. HORMONE THERAPY.  `rxreceived` code 3 gives only 20 patients, which
#    is why the count looked too low.  Code 3 is the right code - no
#    HR-negative patient carries it, which validates the mapping - but
#    `rxreceived` records treatment ever received and misses patients
#    whose endocrine therapy is only recorded in `activetrxname`
#    (code 2 = hormone therapy, 32 patients, 22 of them without code 3).
#    Hormone therapy is now "code 3 in rxreceived OR code 2 in
#    activetrxname" = 42 patients (31.1%), and among patients with an
#    OBSERVED HR status it is 26/38 (68.4%) of HR+ and 0/14 of HR-.
#
# 8. FOLLOW-UP.  Loss to follow-up is NOT recorded in this dataset -
#    `cs` offers only alive-with-disease / disease-free / death, and
#    there is no last-contact date.  The nearest recorded variable is
#    `followup` (regular follow-up yes/no), which is added to Table 2.
#    It cannot yet be used as a proxy for LTFU: it contradicts
#    `causeirregular` (41 of the 74 patients coded as attending
#    REGULARLY have a reason for irregular attendance recorded, while 57
#    of the 61 coded irregular have none), so its direction is unsafe
#    until the client confirms the coding.  See the log.
#
# DELIBERATELY NOT CHANGED (flagged for the client, needs a decision):
#   - os_time for censored patients is `symptomtometastasis`, the
#     interval from first symptom to metastasis.  That is a pre-baseline
#     duration, not follow-up time, so Table 4 and the KM curves are
#     currently modelling the wrong clock.  Fixing it needs a
#     last-contact or last-follow-up date that is not in the data.
#   - Targeted therapy and zoledronic acid: the questionnaire assigns
#     code 6 to targeted therapy and has no code 5 and no zoledronic
#     option at all, while the xlsx columns were built with 5 = targeted
#     and 6 = zoledronic.  The data cannot settle it (every patient on
#     active targeted therapy AND every patient on active zoledronic
#     acid carries code 6).  Kept as delivered, footnoted as unverified.
#
# Output: doc/all_tables_farhana_v4.docx   (previous file left alone)
#         doc/cleaning_log.txt
# ============================================================

library(readxl)
library(haven)
library(dplyr)
library(stringr)
library(purrr)
library(forcats)
library(gtsummary)
library(survival)
library(flextable)
library(officer)

RAW_XLSX <- "Data/cancer_data_imputed.Farhana.xlsx"
RAW_SAV  <- "Data/data.sav"
OUT_LOG  <- "doc/cleaning_log.txt"
OUT_DOCX <- "doc/all_tables_farhana_v4.docx"

dir.create("doc", showWarnings = FALSE)

LOG <- character(0)
note <- function(...) { m <- paste0(...); LOG <<- c(LOG, m); message(m) }
note_block <- function(x) walk(capture.output(print(x)), ~ note("  ", .x))

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
# 0.  Read
# ----------------------------------------------------------
raw <- read_excel(RAW_XLSX, .name_repair = "minimal")
sav <- read_sav(RAW_SAV)                       # cross-checks only, never modelled
zc  <- function(v) as.character(haven::zap_labels(v))

note("============================================================")
note("Project 7 / V3 - cleaning & recheck log (script_farhana_v4.R)")
note("Run: ", format(Sys.time(), "%Y-%m-%d %H:%M"))
note("============================================================")
note("Rows read from ", RAW_XLSX, ": ", nrow(raw))
note("Rows read from ", RAW_SAV,  ": ", nrow(sav),
     "  (row-aligned by `mobile`: ", identical(as.numeric(raw$mobile), as.numeric(sav$mobile)), ")")

yn <- function(x) factor(str_to_title(as.character(x)), levels = c("No", "Yes"))

# Multi-response cells are hand-typed with ",", "." or "/" separators and
# stray trailing commas, so split on any of them and keep the distinct codes.
split_codes <- function(x) {
  x <- str_replace_all(as.character(x), "[.;/ ]", ",")
  map(str_split(x, ","), ~ unique(str_subset(.x, "^[0-9a-z]+$")))
}
has_code <- function(lst, code) map_lgl(lst, ~ code %in% .x)

# ----------------------------------------------------------
# 1.  Metastatic sites - re-derived from the questionnaire codes
#     1 lung  2 brain  3 liver  4 bone  5 opposite breast
#     6 others  7 multiple site
# ----------------------------------------------------------
site_l <- split_codes(raw$sitemetastasis)

note("")
note("--- 1. METASTATIC SITES: xlsx columns vs questionnaire codes ---")
site_map <- list(Lung = c("1", "Lung"), Brain = c("2", "Brain"), Liver = c("3", "Liver"),
                 Bone = c("4", "Bone"), opposite_breast = c("5", "Opposite_breast"),
                 Others = c("6", "Others"), Multiple_site = c("7", "Multiple_site"))
for (col in names(site_map)) {
  code <- site_map[[col]][1]
  expected <- has_code(site_l, code)
  recorded <- as.character(raw[[col]]) == "Yes"
  bad <- which(expected != recorded)
  note(sprintf("  %-16s (code %s): xlsx Yes = %3d, questionnaire Yes = %3d, rows disagreeing = %d",
               col, code, sum(recorded, na.rm = TRUE), sum(expected), length(bad)))
}
note("  => Brain/Liver are swapped and Others/Opposite-breast are swapped in the xlsx.")
note("     All seven flags below are taken from `sitemetastasis`, not from those columns.")

# Row 100 carries a site value that is blank in the SPSS source, and its
# xlsx flags were computed before that value was typed in - re-deriving
# from `sitemetastasis` repairs it.
site_src_diff <- which(zc(sav$sitemetastasis) != as.character(raw$sitemetastasis) |
                       xor(is.na(zc(sav$sitemetastasis)), is.na(raw$sitemetastasis)))
if (length(site_src_diff)) {
  note("  `sitemetastasis` differs from the SPSS source in row(s): ",
       paste(site_src_diff, collapse = ", "))
  note_block(data.frame(row  = site_src_diff,
                        sav  = zc(sav$sitemetastasis)[site_src_diff],
                        xlsx = as.character(raw$sitemetastasis)[site_src_diff]))
}

# ----------------------------------------------------------
# 2.  Metastatic burden - re-derived from the site list
#     Code 7 ("multiple site") is a summary flag, not a site, so it is
#     excluded from the count.
# ----------------------------------------------------------
n_sites <- map_int(site_l, ~ length(setdiff(.x, "7")))
mburden_derived <- cut(n_sites, c(-1, 1, 3, 99),
                       labels = c("1 site", "2-3 sites", ">3 sites"))
mburden_recorded <- case_when(str_detect(raw$mburden, "^>3")  ~ ">3 sites",
                              str_detect(raw$mburden, "^2-3") ~ "2-3 sites",
                              str_detect(raw$mburden, "^1")   ~ "1 site",
                              .default = NA_character_)

note("")
note("--- 2. METASTATIC BURDEN: site list vs recorded `mburden` ---")
note("  derived from site list x recorded in xlsx:")
note_block(table(derived = mburden_derived, recorded = mburden_recorded, useNA = "ifany"))
mb_bad <- which(as.character(mburden_derived) != mburden_recorded)
if (length(mb_bad)) {
  note("  rows where the recorded burden contradicts the patient's own site list:")
  note_block(data.frame(row = mb_bad, sitemetastasis = raw$sitemetastasis[mb_bad],
                        n_sites = n_sites[mb_bad], recorded = raw$mburden[mb_bad],
                        derived = as.character(mburden_derived)[mb_bad]))
}
mb_sav <- zc(sav$mburden)
mb_sav_lab <- c("1" = "1 site", "2" = "2-3 sites", "3" = ">3 sites")[mb_sav]
mb_src_bad <- which(mb_sav_lab != mburden_recorded | xor(is.na(mb_sav_lab), is.na(mburden_recorded)))
note("  rows where the xlsx burden differs from the SPSS source: ", length(mb_src_bad))
if (length(mb_src_bad)) {
  note_block(data.frame(row = mb_src_bad, sav = mb_sav_lab[mb_src_bad],
                        xlsx = mburden_recorded[mb_src_bad],
                        n_sites = n_sites[mb_src_bad]))
  note("  (the site list, not the burden field, is used below - it is the more")
  note("   granular record and reproduces the xlsx in all but the rows above)")
}

# ----------------------------------------------------------
# 3.  Receptors and molecular subtype - subtype derived, not imputed
# ----------------------------------------------------------
note("")
note("--- 3. RECEPTORS: how much of ER/PR/HER2 is imputed rather than observed ---")
for (v in c("ER", "PR", "her2")) {
  obs <- sum(!is.na(zc(sav[[v]])))
  note(sprintf("  %-5s observed in SPSS source: %3d/%d (%.1f%%)  ->  %d imputed",
               v, obs, nrow(sav), 100 * obs / nrow(sav), nrow(sav) - obs))
}
er_obs <- ifelse(zc(sav$ER) == "1", "Positive", ifelse(zc(sav$ER) == "2", "Negative", NA))
er_bad <- which(!is.na(er_obs) & er_obs != str_to_title(raw$ER))
if (length(er_bad)) {
  note("  ER differs from the SPSS source on an OBSERVED row: ", paste(er_bad, collapse = ", "))
  note_block(data.frame(row = er_bad, sav = er_obs[er_bad], xlsx = raw$ER[er_bad]))
}

# ----------------------------------------------------------
# 4.  Causes of recurrent metastasis - re-parsed
#     1 = treatment incomplete (a = CT not completed, b = RT not completed)
#     2 = treatment completed but not within time
#     3, 4 = present in the data, NOT defined in the questionnaire
# ----------------------------------------------------------
cause_l <- split_codes(raw$causesrmetast)
cause_l <- map(cause_l, function(z) {
  # "1a", "1ab", "1b" are typed as one token; expand them into 1 + a / b
  extra <- unlist(map(z[str_detect(z, "^1[ab]+$")], ~ c("1", str_split(str_remove(.x, "^1"), "")[[1]])))
  unique(c(z[!str_detect(z, "^1[ab]+$")], extra))
})

note("")
note("--- 4. CAUSES OF RECURRENT METASTASIS: codes found vs questionnaire ---")
note("  raw strings:")
note_block(table(raw$causesrmetast, useNA = "ifany"))
note("  codes after parsing '1a'/'1ab'/'1b' into 1 + a/b:")
note_block(table(unlist(cause_l), useNA = "ifany"))
note("  questionnaire defines only 1 (with sub-codes a, b) and 2.")
note("  codes 3 (n = ", sum(has_code(cause_l, "3")), ") and 4 (n = ", sum(has_code(cause_l, "4")),
     ") are NOT defined anywhere - client needs to supply their meaning.")
note("  the three flags carried in the xlsx do not follow the questionnaire:")
note(sprintf("    CT_not_completed = %d  (matched any '1' -> really 'treatment incomplete' = %d)",
             sum(raw$CT_not_completed == "Yes"), sum(has_code(cause_l, "1"))))
note(sprintf("    RT_not_completed = %d  (matched code 2 -> really 'not within time' = %d)",
             sum(raw$RT_not_completed == "Yes"), sum(has_code(cause_l, "2"))))
note(sprintf("    Tx_not_in_time   = %d  (matched undefined code 3 = %d)",
             sum(raw$Tx_not_in_time == "Yes"), sum(has_code(cause_l, "3"))))
note(sprintf("  correct counts: incomplete = %d, of which CT not completed = %d and RT not completed = %d; not within time = %d",
             sum(has_code(cause_l, "1")), sum(has_code(cause_l, "a")),
             sum(has_code(cause_l, "b")), sum(has_code(cause_l, "2"))))

# ----------------------------------------------------------
# 5.  Treatments
# ----------------------------------------------------------
rx_l  <- split_codes(raw$rxreceived)      # ever received: 1 chemo 2 pall.RT 3 hormone 4 immuno 6 targeted
act_l <- split_codes(raw$activetrxname)   # currently on:  1 chemo 2 hormone 3 targeted 4 zoledronic

note("")
note("--- 5. TREATMENT RECEIVED: codes in `rxreceived` vs questionnaire ---")
note_block(table(unlist(rx_l)))
note("  questionnaire: 1 chemo, 2 palliative RT, 3 hormone, 4 immunotherapy, 6 targeted.")
note("  code 4 never used (n = 0); codes 5 (n = ", sum(has_code(rx_l, "5")),
     ") and 7 (n = ", sum(has_code(rx_l, "7")), ") are not defined in the questionnaire.")
note("  the xlsx built Targeted_Therapy from code 5 and Zoledronic_Acid from code 6,")
note("  but the questionnaire assigns code 6 to TARGETED therapy and has no zoledronic option.")
note("  the data cannot settle it: all ", sum(has_code(act_l, "3")), " patients on active targeted")
note("  therapy and all ", sum(has_code(act_l, "4")), " on active zoledronic acid carry code 6.")
note("  => Targeted_Therapy and Zoledronic_Acid are kept as delivered and footnoted as unverified.")

hormone_ever   <- has_code(rx_l, "3")
hormone_active <- has_code(act_l, "2")
note("")
note("--- 6. HORMONE THERAPY (client query: 'must be higher') ---")
note("  rxreceived code 3 (ever received)      : ", sum(hormone_ever))
note("  activetrxname code 2 (currently on)    : ", sum(hormone_active),
     " of which ", sum(hormone_active & !hormone_ever), " have no code 3 in rxreceived")
note("  union used below                       : ", sum(hormone_ever | hormone_active))
pr_obs <- ifelse(zc(sav$PR) == "1", "Positive", ifelse(zc(sav$PR) == "2", "Negative", NA))
hr_obs <- ifelse(er_obs == "Positive" | pr_obs == "Positive", "HR+",
                 ifelse(!is.na(er_obs) & !is.na(pr_obs), "HR-", NA))
note("  validation on rows with OBSERVED receptors (code 3 alone):")
note_block(table(HR = hr_obs, code3 = hormone_ever))
note("  validation on rows with OBSERVED receptors (union):")
note_block(table(HR = hr_obs, union = hormone_ever | hormone_active))
note("  no HR-negative patient receives hormone therapy under either definition,")
note("  which confirms code 3 is the hormone-therapy code; the union simply")
note("  recovers the patients whose endocrine therapy was only recorded as active.")

# ----------------------------------------------------------
# 6.  Build the analysis frame
# ----------------------------------------------------------
data <- raw %>%
  mutate(
    # ── demographics ──
    age_grp = factor(age_grp, levels = c("<35", "35-45", "45-55", "55+")),
    parity  = case_when(totalpg == 0 ~ "Nulliparous", totalpg >= 1 ~ "Parous") %>% factor(),
    family_hist = case_when(familybreastchistory == 1 ~ "Yes",
                            familybreastchistory == 2 ~ "No",
                            .default = NA_character_) %>% factor(levels = c("Yes", "No")),
    menopause = ifelse(is.na(ageofmenopause), 0, 1) %>%
      factor(levels = c(0, 1), labels = c("No", "Yes")),

    # ── disease characteristics ──
    stage = case_when(staging == 1 ~ "Stage 1", staging == 2 ~ "Stage 2",
                      staging == 3 ~ "Stage 3", staging == 4 ~ "Stage 4",
                      .default = NA_character_) %>%
      factor(levels = c("Stage 1", "Stage 2", "Stage 3", "Stage 4")),

    # QUERY 6: duct cell + infiltrating duct cell merged; the rest kept
    # separate instead of being lumped into "Others".
    histology = case_when(
      histologycal %in% c("1", "2") ~ "Infiltrating duct cell carcinoma",
      histologycal == "3"           ~ "Lobular cell carcinoma",
      histologycal == "4"           ~ "Infiltrating adenocarcinoma",
      histologycal == "5"           ~ "Invasive carcinoma",
      .default = NA_character_) %>%
      factor(levels = c("Infiltrating duct cell carcinoma", "Lobular cell carcinoma",
                        "Infiltrating adenocarcinoma", "Invasive carcinoma")),
    grading = factor(grading, levels = c("Grade 1", "Grade 2", "Grade 3")),

    # ── receptors ──
    ER   = factor(str_to_title(ER),   levels = c("Positive", "Negative")),
    PR   = factor(str_to_title(PR),   levels = c("Positive", "Negative")),
    her2 = factor(str_to_title(her2), levels = c("Positive", "Negative")),

    # QUERIES 2 & 3: subtype DERIVED from the receptors, so that
    # HER2+ == HR+/HER2+ plus HR-/HER2+ by construction.
    hr_status = ifelse(ER == "Positive" | PR == "Positive", "HR+", "HR-"),
    subtype = paste0(hr_status, "/HER2", ifelse(her2 == "Positive", "+", "-")) %>%
      factor(levels = c("HR+/HER2+", "HR+/HER2-", "HR-/HER2+", "HR-/HER2-")),

    # QUERY 1: sites straight off the questionnaire codes.
    Lung            = factor(ifelse(has_code(site_l, "1"), "Yes", "No"), levels = c("No", "Yes")),
    Brain           = factor(ifelse(has_code(site_l, "2"), "Yes", "No"), levels = c("No", "Yes")),
    Liver           = factor(ifelse(has_code(site_l, "3"), "Yes", "No"), levels = c("No", "Yes")),
    Bone            = factor(ifelse(has_code(site_l, "4"), "Yes", "No"), levels = c("No", "Yes")),
    Opposite_breast = factor(ifelse(has_code(site_l, "5"), "Yes", "No"), levels = c("No", "Yes")),
    Other_site      = factor(ifelse(has_code(site_l, "6"), "Yes", "No"), levels = c("No", "Yes")),
    mburden         = mburden_derived,

    # ── treatments ──
    Chemotherapy     = yn(Chemotherapy),
    Targeted_Therapy = yn(Targeted_Therapy),   # unverified code, see log
    Zoledronic_Acid  = yn(Zoledronic_Acid),    # unverified code, see log
    # QUERY 7
    Hormone_Therapy  = factor(ifelse(hormone_ever | hormone_active, "Yes", "No"),
                              levels = c("No", "Yes")),

    # ── disease course ──
    surgery = factor(surgery, levels = c("Mastectomy", "Lumpectomy", "Biopsy", "No Surgery")),
    cs      = factor(cs, levels = c("Alive with disease", "Disease free", "Death")),
    delayrx = factor(str_to_title(delayrx), levels = c("No", "Yes")),
    skip    = factor(skip, levels = c("Non Adherent", "Adherent")),

    # QUERY 8: follow-up regularity (the only follow-up variable recorded).
    followup_reg = case_when(followup == "1" ~ "Regular",
                             followup == "2" ~ "Irregular",
                             .default = NA_character_) %>%
      factor(levels = c("Regular", "Irregular")),

    # QUERY 5: recurrence detail (defined for recurrent MBC only).
    prestage = factor(prestage, levels = c("Stage 1", "Stage 2", "Stage 3")),
    rec_incomplete = factor(ifelse(has_code(cause_l, "1"), "Yes", "No"), levels = c("No", "Yes")),
    rec_ct_incomplete = factor(ifelse(has_code(cause_l, "a"), "Yes", "No"), levels = c("No", "Yes")),
    rec_rt_incomplete = factor(ifelse(has_code(cause_l, "b"), "Yes", "No"), levels = c("No", "Yes")),
    rec_not_in_time = factor(ifelse(has_code(cause_l, "2"), "Yes", "No"), levels = c("No", "Yes")),
    rec_undefined  = factor(ifelse(has_code(cause_l, "3") | has_code(cause_l, "4"), "Yes", "No"),
                            levels = c("No", "Yes")),

    # ── survival ──
    # status2 comes from `cs`, the documented definition. The xlsx `status`
    # column disagrees on one row (see log) and is not used.
    status2 = as.numeric(cs == "Death"),
    status  = factor(ifelse(cs == "Death", 1, 0), labels = c("Alive", "Death")),
    os_time = as.numeric(os_time)
  )

# ----------------------------------------------------------
# 7.  Post-build consistency checks
# ----------------------------------------------------------
note("")
note("--- 7. SUBTYPE: xlsx `clinical_subtype` vs subtype derived from ER/PR/HER2 ---")
note_block(table(xlsx = raw$clinical_subtype, derived = data$subtype, useNA = "ifany"))
sub_bad <- which(as.character(data$subtype) != raw$clinical_subtype)
note("  rows disagreeing: ", length(sub_bad), " of ", nrow(data))
sub_bad_obs <- which(!is.na(hr_obs) & !is.na(zc(sav$her2)) &
                     as.character(data$subtype) != raw$clinical_subtype)
note("  of those, ", length(sub_bad) - length(sub_bad_obs),
     " sit in rows where the receptors were imputed and ", length(sub_bad_obs),
     " in rows where they were observed",
     if (length(sub_bad_obs)) paste0(" (row ", paste(sub_bad_obs, collapse = ", "),
       " - the same row whose ER value differs from the SPSS source, see section 3)") else "")
note("")
note("  QUERY 2 - HER2 frequency:")
note("    HER2 positive (imputed dataset): ", sum(data$her2 == "Positive"), "/", nrow(data),
     sprintf(" (%.1f%%)", 100 * mean(data$her2 == "Positive")))
note("    HER2 positive (observed only)  : ", sum(zc(sav$her2) == "1", na.rm = TRUE), "/",
     sum(!is.na(zc(sav$her2))),
     sprintf(" (%.1f%%)", 100 * mean(zc(sav$her2)[!is.na(zc(sav$her2))] == "1")))
note("    -> the published HER2 frequency is ", nrow(sav) - sum(!is.na(zc(sav$her2))),
     "/", nrow(sav), " imputed; worth a limitation sentence.")
note("")
note("  QUERY 3 - does HER2+ equal HR+/HER2+ plus HR-/HER2+ ?")
note("    xlsx subtype   : HR+/HER2+ ", sum(raw$clinical_subtype == "HR+/HER2+"),
     " + HR-/HER2+ ", sum(raw$clinical_subtype == "HR-/HER2+"),
     " = ", sum(raw$clinical_subtype %in% c("HR+/HER2+", "HR-/HER2+")),
     "  vs HER2+ ", sum(data$her2 == "Positive"), "   MISMATCH")
note("    derived subtype: HR+/HER2+ ", sum(data$subtype == "HR+/HER2+"),
     " + HR-/HER2+ ", sum(data$subtype == "HR-/HER2+"),
     " = ", sum(data$subtype %in% c("HR+/HER2+", "HR-/HER2+")),
     "  vs HER2+ ", sum(data$her2 == "Positive"), "   OK")

note("")
note("--- 8. DE NOVO vs RECURRENT consistency ---")
note_block(table(denovometastasis = raw$denovometastasis, recume = raw$recume, useNA = "ifany"))
dn_bad <- which((raw$denovometastasis == "Yes") != (raw$mbc_type == "De novo MBC"))
note("  rows where `denovometastasis` contradicts `mbc_type`: ", paste(dn_bad, collapse = ", "))
cause_on_denovo <- which(raw$mbc_type == "De novo MBC" & !is.na(raw$causesrmetast))
note("  de novo patients carrying a CAUSE OF RECURRENCE (impossible by definition): ",
     length(cause_on_denovo))
note("    rows: ", paste(cause_on_denovo, collapse = ", "))
note("    these causes are ignored below - Table 2b is restricted to recurrent MBC.")
note("  prior stage recorded for ", sum(!is.na(data$prestage) & raw$mbc_type == "Recurrent MBC"),
     " of ", sum(raw$mbc_type == "Recurrent MBC"), " recurrent patients")

note("")
note("--- 9. FOLLOW-UP (client query 8: can loss to follow-up be incorporated?) ---")
note("  `cs` categories available:")
note_block(table(data$cs))
note("  There is NO lost-to-follow-up category and no last-contact date, so LTFU")
note("  cannot be derived. The only follow-up variable is `followup`:")
note_block(table(followup_reg = data$followup_reg))
note("  but it contradicts `causeirregular`:")
note_block(table(followup = data$followup_reg, causeirregular = raw$causeirregular, useNA = "ifany"))
note("  ", sum(data$followup_reg == "Regular" & !is.na(raw$causeirregular)),
     " patients coded REGULAR have a reason for irregular attendance recorded, while ",
     sum(data$followup_reg == "Irregular" & is.na(raw$causeirregular)),
     " coded IRREGULAR have none.")
note("  => the direction of `followup` is unsafe. It is tabulated in Table 2 but")
note("     deliberately NOT modelled until the client confirms the coding.")
note("")
note("  CENSORING WARNING: os_time for the ", sum(data$status2 == 0),
     " censored patients equals `symptomtometastasis`")
note("  (interval from first symptom to metastasis) capped at 24 months, in ",
     sum(data$os_time[data$status2 == 0] ==
         pmin(as.numeric(raw$symptomtometastasis)[data$status2 == 0], 24), na.rm = TRUE),
     " of them.")
note("  That is a PRE-BASELINE duration, not follow-up time, so Table 4 and the KM")
note("  curves are modelling the wrong clock. Fixing it needs a last-contact date.")
st_bad <- which((raw$status == 1) != (data$cs == "Death"))
if (length(st_bad)) {
  note("  xlsx `status` column disagrees with `cs` on row(s) ", paste(st_bad, collapse = ", "),
       " (cs = ", paste(as.character(data$cs)[st_bad], collapse = ", "),
       " but status = 1); events taken from `cs`, so ", sum(data$status2), " events not ",
       sum(raw$status == 1), ".")
}

# ----------------------------------------------------------
# 8.  TABLE 1 - Patient and disease characteristics
# ----------------------------------------------------------
table1 <- data %>%
  select(age_grp, Education, family_hist, stage, subtype, ER, PR, her2, mbc_type,
         menopause, histology, grading, Lung, Liver, Brain, Bone, Opposite_breast,
         Other_site) %>%
  tbl_summary(
    statistic = list(all_continuous() ~ "{mean} ({sd})", all_categorical() ~ "{n} ({p}%)"),
    digits = all_continuous() ~ 2, missing = "no",
    label = list(
      age_grp ~ "Age (years)", Education ~ "Education",
      family_hist ~ "Family history of breast cancer", stage ~ "Stage",
      subtype ~ "Molecular subtype", ER ~ "ER status", PR ~ "PR status",
      her2 ~ "HER2 status", mbc_type ~ "MBC type", menopause ~ "Menopause",
      histology ~ "Histology", grading ~ "Grade",
      Lung ~ "Lung metastasis", Liver ~ "Liver metastasis",
      Brain ~ "Brain metastasis", Bone ~ "Bone metastasis",
      Opposite_breast ~ "Opposite-breast metastasis", Other_site ~ "Other site")) %>%
  bold_labels()

# ----------------------------------------------------------
# 9.  TABLE 2 - Treatment and disease-course details
# ----------------------------------------------------------
table2 <- data %>%
  select(surgery, Chemotherapy, Hormone_Therapy, Targeted_Therapy, Zoledronic_Acid,
         mburden, delayrx, skip, followup_reg, cs) %>%
  tbl_summary(
    statistic = list(all_continuous() ~ "{mean} ({sd})", all_categorical() ~ "{n} ({p}%)"),
    digits = all_continuous() ~ 2, missing = "no",
    label = list(
      surgery ~ "Surgery", Chemotherapy ~ "Chemotherapy received",
      Hormone_Therapy ~ "Hormone therapy received",
      Targeted_Therapy ~ "Targeted therapy received",
      Zoledronic_Acid ~ "Zoledronic acid received",
      mburden ~ "Metastatic burden", delayrx ~ "Delayed treatment",
      skip ~ "Treatment adherence", followup_reg ~ "Follow-up attendance",
      cs ~ "Current disease status")) %>%
  bold_labels()

# Biomarker-directed uptake (reported as narrative text in the paper)
hr_pos_uptake <- data %>% filter(ER == "Positive" | PR == "Positive") %>%
  summarise(n = n(), received = sum(Hormone_Therapy == "Yes")) %>%
  mutate(pct = round(100 * received / n, 1))
her2_pos_uptake <- data %>% filter(her2 == "Positive") %>%
  summarise(n = n(), received = sum(Targeted_Therapy == "Yes")) %>%
  mutate(pct = round(100 * received / n, 1))

# ----------------------------------------------------------
# 10. TABLE 2b - Recurrence detail (recurrent MBC only)  [QUERY 5]
# ----------------------------------------------------------
rec <- data %>% filter(mbc_type == "Recurrent MBC")
table2b <- rec %>%
  select(prestage, rec_incomplete, rec_ct_incomplete, rec_rt_incomplete,
         rec_not_in_time, rec_undefined) %>%
  tbl_summary(
    statistic = all_categorical() ~ "{n} ({p}%)", missing = "ifany",
    missing_text = "Not recorded",
    label = list(
      prestage ~ "Stage prior to recurrence",
      rec_incomplete ~ "Treatment incomplete",
      rec_ct_incomplete ~ "  Chemotherapy not completed",
      rec_rt_incomplete ~ "  Radiotherapy not completed",
      rec_not_in_time ~ "Treatment completed but not within time",
      rec_undefined ~ "Uncoded reason (codes 3/4)")) %>%
  bold_labels()

# ----------------------------------------------------------
# 11. TABLE 3 - Association with current vital status
# ----------------------------------------------------------
table3 <- data %>%
  select(status, grading, subtype, mburden, Lung, Liver, Brain, Bone,
         delayrx, skip, followup_reg) %>%
  tbl_summary(
    by = status, statistic = all_categorical() ~ "{n} ({p}%)", missing = "no",
    label = list(
      grading ~ "Tumor grade", subtype ~ "Molecular subtype",
      mburden ~ "Metastatic burden", Lung ~ "Lung metastasis",
      Liver ~ "Liver metastasis", Brain ~ "Brain metastasis",
      Bone ~ "Bone metastasis", delayrx ~ "Delayed treatment",
      skip ~ "Treatment adherence", followup_reg ~ "Follow-up attendance")) %>%
  add_p(test = all_categorical() ~ "fisher.test") %>%
  bold_labels() %>%
  modify_spanning_header(all_stat_cols() ~ "**Current vital status**")

# ----------------------------------------------------------
# 12. TABLE 4 - Univariate + multivariate Cox regression (OS)
#     `followup_reg` is left out on purpose - see the log.
# ----------------------------------------------------------
vars <- c("age_grp", "Education", "grading", "subtype", "menopause", "mburden",
          "Lung", "Liver", "Brain", "Bone", "delayrx", "skip")
var_label <- list(
  age_grp ~ "Age Group", Education ~ "Education", grading ~ "Tumor grade",
  subtype ~ "Molecular subtype", menopause ~ "Menopause",
  mburden ~ "Metastatic burden", Lung ~ "Lung metastasis",
  Liver ~ "Liver metastasis", Brain ~ "Brain metastasis",
  Bone ~ "Bone metastasis", delayrx ~ "Delayed treatment",
  skip ~ "Treatment adherence")
# The univariate loop indexes this by variable name; tbl_regression() needs the
# plain unnamed list of formulas, so keep both forms.
var_label_by_name <- setNames(var_label, vars)

tbl_uni <- lapply(vars, function(v) {
  coxph(as.formula(paste0("Surv(os_time, status2) ~ ", v)), data = data) %>%
    tbl_regression(exponentiate = TRUE, label = var_label_by_name[[v]]) %>%
    bold_labels() %>% bold_p(t = 0.05)
}) %>% tbl_stack()

cox_multi <- coxph(
  as.formula(paste0("Surv(os_time, status2) ~ ", paste(vars, collapse = " + "))),
  data = data)
tbl_multi <- tbl_regression(cox_multi, exponentiate = TRUE, label = var_label) %>%
  bold_labels() %>% bold_p(t = 0.05)

table4 <- tbl_merge(tbls = list(tbl_uni, tbl_multi),
                    tab_spanner = c("**Univariate analysis**", "**Multivariate analysis**"))

# ----------------------------------------------------------
# 13. Export
# ----------------------------------------------------------
fn <- function(x) fpar(ftext(x, prop = fp_text(font.size = 9, italic = TRUE)))

doc <- read_docx() %>%
  body_add("Table 1. Patient and disease characteristics", style = "heading 1") %>%
  body_add_flextable(table1 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Metastatic sites are derived from the recorded site list using the questionnaire codes ",
    "(1 lung, 2 brain, 3 liver, 4 bone, 5 opposite breast, 6 others). Brain and liver, and ",
    "other-site and opposite-breast, were transposed in the previous version of this table."))) %>%
  body_add_fpar(fn(paste0(
    "Molecular subtype is derived from ER, PR and HER2, so HER2-positive equals HR+/HER2+ plus ",
    "HR-/HER2+ (", sum(data$subtype %in% c("HR+/HER2+", "HR-/HER2+")), "). ",
    "ER, PR and HER2 were missing for 83, 83 and 86 of 135 patients respectively and are ",
    "multiply imputed; receptor and subtype frequencies should be read with that in mind."))) %>%
  body_add_fpar(fn(paste0(
    "Histology: duct cell carcinoma and infiltrating duct cell carcinoma are reported as one ",
    "category at the investigators' instruction; lobular, infiltrating adenocarcinoma and ",
    "invasive carcinoma are reported separately."))) %>%
  body_add("") %>%

  body_add("Table 2. Treatment and disease-course details", style = "heading 1") %>%
  body_add_flextable(table2 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(sprintf(
    "Hormone-therapy uptake among HR+ cases: %d/%d (%.1f%%).",
    hr_pos_uptake$received, hr_pos_uptake$n, hr_pos_uptake$pct))) %>%
  body_add_fpar(fn(sprintf(
    "Targeted-therapy uptake among HER2+ cases: %d/%d (%.1f%%).",
    her2_pos_uptake$received, her2_pos_uptake$n, her2_pos_uptake$pct))) %>%
  body_add_fpar(fn(paste0(
    "Hormone therapy counts a patient as treated if endocrine therapy appears either in ",
    "treatment ever received or in current active treatment; the previous version used the ",
    "former only and reported ", sum(hormone_ever), " instead of ",
    sum(hormone_ever | hormone_active), ". No hormone-receptor-negative patient is counted ",
    "as treated under either definition."))) %>%
  body_add_fpar(fn(paste0(
    "Targeted therapy and zoledronic acid are carried over unchanged and remain UNVERIFIED: ",
    "the questionnaire assigns code 6 to targeted therapy and defines no code for zoledronic ",
    "acid, while these columns were built from code 5 and code 6 respectively."))) %>%
  body_add_fpar(fn(paste0(
    "Follow-up attendance is shown for completeness only. Loss to follow-up is not recorded ",
    "in this dataset, and the attendance variable conflicts with the recorded reasons for ",
    "irregular attendance, so it is not used in any model."))) %>%
  body_add("") %>%

  body_add("Table 2b. Recurrence detail (recurrent MBC only)", style = "heading 1") %>%
  body_add_flextable(table2b %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Restricted to the ", nrow(rec), " patients with recurrent MBC; prior stage and cause of ",
    "recurrence are undefined for de novo disease. Reasons are not mutually exclusive. ",
    "Codes 3 and 4 appear in the data but are not defined in the questionnaire and are ",
    "reported together as uncoded. ", length(cause_on_denovo), " patients classified as de ",
    "novo MBC also carried a cause of recurrence; those entries are excluded here and ",
    "listed in the cleaning log."))) %>%
  body_add("") %>%

  body_add("Table 3. Association with current vital status", style = "heading 1") %>%
  body_add_flextable(table3 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "Fisher exact test throughout. Deaths (n = ", sum(data$status2),
    ") are taken from the recorded current status."))) %>%
  body_add("") %>%

  body_add("Table 4. Univariate and multivariate Cox regression (overall survival)",
           style = "heading 1") %>%
  body_add_flextable(table4 %>% as_flex_table() %>% autofit()) %>%
  body_add_fpar(fn(paste0(
    "CAUTION: for the ", sum(data$status2 == 0), " patients who had not died, the survival ",
    "time used here is the interval from first symptom to metastasis, not time under ",
    "observation after metastasis. This is inherited from the existing dataset and needs a ",
    "last-contact date to correct. Hazard ratios should not be published until it is fixed.")))

safe_write(print(doc, target = OUT_DOCX), OUT_DOCX)

note("")
note("--- OUTPUT ---")
note("  ", OUT_DOCX)
safe_write(writeLines(LOG, OUT_LOG), OUT_LOG)
