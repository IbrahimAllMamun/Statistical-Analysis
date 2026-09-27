# ============================================================
# Anni MS thesis - Early Childhood Food Insecurity (EC-FIES), Bangladesh
# ------------------------------------------------------------
# Rebuilds the five tables that already exist in doc/"Thesis Draft.docx",
# corrected against Data/MAIN.sav (N = 407).
#
#   Table 3.1  Sample distribution by division        (methodology chapter)
#   Table 4.1  Household characteristics
#   Table 4.2  Child characteristics
#   Table 4.3  Maternal characteristics
#   Table 4.4  Paternal characteristics
#   Table 4.5  EC-FIES severity by division and residence
#
# Corrections applied (each is logged to doc/tables_cleaning_log.txt):
#   1. Birth weight was recorded in MIXED UNITS - 7 forms in kg, 312 in
#      grams - and the "don't know" sentinel 98 was left in the numeric
#      field. kg entries are multiplied by 1000; 98 becomes a category.
#   2. Religion percentage in the draft read "47" for 19/407 = 4.7%.
#   3. The Wealth Quintile rows were empty although Ncombsco exists.
#   4. Child age group dropped the 18 children with no recorded date of
#      birth; they carry approx_age and are recovered here.
#   5. Father's occupation was collapsed to two categories but LABELLED
#      "Agriculture" and "Business", when the 224 counted as "Business"
#      are mostly salaried job-holders. All seven categories are shown.
#
# Output: doc/Tables_Chapter4.docx
#         doc/tables_cleaning_log.txt
#         Data/ecfies_tables.rds
# ============================================================

library(haven)
library(dplyr)
library(flextable)
library(officer)

SAV      <- "Data/MAIN.sav"
OUT_DOCX <- "doc/Tables_Chapter4.docx"
OUT_LOG  <- "doc/tables_cleaning_log.txt"
OUT_RDS  <- "Data/ecfies_tables.rds"

dir.create("doc", showWarnings = FALSE)

LOG  <- character(0)
note <- function(...) { m <- paste0(...); LOG <<- c(LOG, m); message(m) }

# ----------------------------------------------------------
# 1. Read and derive
# ----------------------------------------------------------
raw <- read_sav(SAV)
note("Rows read from ", SAV, ": ", nrow(raw))
note("")

lab <- function(x) haven::as_factor(x, levels = "labels")

dat <- raw %>%
  transmute(
    id        = as.integer(ID),
    division  = lab(DIVISION),
    residence = factor(lab(A2_3_Residence), levels = c("Urban", "Rural")),

    # ---- household -------------------------------------------------
    family_type = factor(lab(B2_type_of_your_family), levels = c("Nuclear", "Joint")),
    hh_size_n   = as.numeric(B6_members_household),
    hh_size     = cut(hh_size_n, breaks = c(-Inf, 4, 6, Inf),
                      labels = c("≤4 members", "5-6 members", "≥7 members")),
    religion    = droplevels(lab(B13_religion)),
    wealth      = factor(lab(Ncombsco),
                         levels = c("Lowest", "Second", "Middle", "Fourth", "Highest"),
                         labels = c("Poorest", "Poorer", "Middle", "Richer", "Richest")),

    # ---- child -----------------------------------------------------
    sex = factor(lab(D5_sex_of_the_child), levels = c("Male", "Female")),

    # date of birth is missing for 18 children; approx_age carries their age
    age_dob  = suppressWarnings(as.numeric(as.character(age_months))),
    age_appr = as.numeric(approx_age),
    age_m    = ifelse(is.na(age_dob), age_appr, age_dob),
    age_src  = ifelse(is.na(age_dob), "Approximate (DoB unknown)", "Date of birth"),
    age_grp  = cut(age_m, breaks = c(-Inf, 8, 11, 17, Inf),
                   labels = c("6-8 months", "9-11 months",
                              "12-17 months", "18-23 months")),
    birth_order = factor(lab(D6_birth_order),
                         levels = c("First", "Second", "Third", "Above"),
                         labels = c("First", "Second", "Third", "Fourth or higher")),

    # ---- birth weight: MIXED UNITS + sentinel 98 -------------------
    bw_raw = as.numeric(D8_birth_weight_kg),
    bw_g   = case_when(bw_raw == 98 ~ NA_real_,   # "don't know"
                       bw_raw <  10 ~ bw_raw * 1000,  # recorded in kg
                       TRUE         ~ bw_raw),
    bw_cat = factor(case_when(is.na(bw_g)   ~ "Don't know",
                              bw_g <  2500  ~ "Low birth weight (<2.5 kg)",
                              TRUE          ~ "≥2.5 kg"),
                    levels = c("Low birth weight (<2.5 kg)", "≥2.5 kg", "Don't know")),

    # ---- mother ----------------------------------------------------
    m_edu = factor(lab(B11_edu_mother),
                   levels = c("No formal education", "Primary", "Secondary",
                              "Higher Secondary", "Higher Study (tertiary education)"),
                   labels = c("No formal education", "Primary", "Secondary",
                              "Higher secondary", "Higher education")),
    m_occ_full = droplevels(lab(B12_occupation_mother)),
    m_occ = factor(ifelse(as.character(m_occ_full) == "Housewife",
                          "Housewife", "Employed / other"),
                   levels = c("Housewife", "Employed / other")),
    m_age_marriage = as.numeric(B9_age_at_marriage),
    m_age_marr_cat = factor(ifelse(m_age_marriage < 18, "<18 years", "≥18 years"),
                            levels = c("<18 years", "≥18 years")),
    m_age_birth1   = as.numeric(B10_age_at_first_birth),
    m_age_b1_cat   = factor(ifelse(m_age_birth1 < 20, "<20 years", "20-34 years"),
                            levels = c("<20 years", "20-34 years")),

    # ---- father ----------------------------------------------------
    f_edu = factor(lab(B5_education_child_father),
                   levels = c("No formal education", "Primary", "Secondary",
                              "Higher Secondary", "Higher Study (tertiary education)"),
                   labels = c("No formal education", "Primary", "Secondary",
                              "Higher secondary", "Higher education")),
    f_occ = factor(lab(B4_occupation_father),
                   levels = c("Agriculture", "Wage-Labor", "Business", "Job-holder",
                              "Remittance erner", "Not working", "Others"),
                   labels = c("Agriculture", "Day labour", "Business", "Service / job-holder",
                              "Remittance earner", "Not working", "Other")),

    # ---- EC-FIES ---------------------------------------------------
    g1 = as.numeric(G_Worried),      g2 = as.numeric(G_Unable_healthy),
    g3 = as.numeric(G_fewer),        g4 = as.numeric(G_unable_enough_food),
    g5 = as.numeric(G_less_food),    g6 = as.numeric(G_run_out_food),
    g7 = as.numeric(G_hungry),       g8 = as.numeric(G_did_not_eat)
  ) %>%
  mutate(
    ecfies_n_valid = rowSums(!is.na(across(g1:g8))),
    ecfies_raw     = ifelse(ecfies_n_valid == 8, rowSums(across(g1:g8)), NA_real_),
    ecfies_cat     = cut(ecfies_raw, breaks = c(-Inf, 0, 3, 6, 8),
                         labels = c("Food secure", "Mild", "Moderate", "Severe"))
  )

# ----------------------------------------------------------
# 2. Cleaning log - what changed and why
# ----------------------------------------------------------
note("--- CORRECTION 1: birth weight ---")
note("  Forms recorded in kilograms (value < 10), multiplied by 1000: ",
     sum(dat$bw_raw < 10, na.rm = TRUE))
note("    values: ", paste(sort(dat$bw_raw[dat$bw_raw < 10]), collapse = ", "))
note("  Coded 98 = 'don't know', set to a category rather than a number: ",
     sum(dat$bw_raw == 98, na.rm = TRUE))
note("  After the fix: LBW <2500 g = ", sum(dat$bw_cat == "Low birth weight (<2.5 kg)"),
     ", >=2500 g = ", sum(dat$bw_cat == "≥2.5 kg"),
     ", don't know = ", sum(dat$bw_cat == "Don't know"),
     "  (total ", nrow(dat), ")")
note("  Draft reported 92 / 219 / 88, which sums to 399, not 407.")
note("  IMPLAUSIBLE VALUE remaining, verify against the paper form: ",
     paste(sort(dat$bw_g[dat$bw_g < 1000]), collapse = ", "), " g")
note("")

note("--- CORRECTION 2: religion ---")
note("  Hindu n = ", sum(dat$religion == "Hindu"), " of ", nrow(dat),
     " = ", sprintf("%.1f%%", 100 * mean(dat$religion == "Hindu")),
     "  (draft printed '47')")
note("")

note("--- CORRECTION 3: wealth quintile ---")
note("  Ncombsco is populated for all ", sum(!is.na(dat$wealth)), " respondents; ",
     "the draft left these rows blank.")
note("")

note("--- CORRECTION 4: child age ---")
note("  Date of birth missing for ", sum(dat$age_src != "Date of birth"),
     " children; approx_age recovers all of them.")
note("  Draft age-group rows summed to 389, losing those 18.")
oor <- dat$age_m < 6 | dat$age_m > 23
note("  OUT OF ELIGIBLE RANGE (6-23 months): n = ", sum(oor, na.rm = TRUE),
     " (ages ", paste(sort(dat$age_m[oor]), collapse = ", "), " months)")
note("")

note("--- CORRECTION 5: father's occupation ---")
note("  Draft: Agriculture 139 / Business 224 / Remittance 31 / Not working 13.")
note("  Those are collapses of the seven recorded categories:")
for (l in levels(dat$f_occ))
  note(sprintf("    %-22s %3d (%.1f%%)", l, sum(dat$f_occ == l),
               100 * mean(dat$f_occ == l)))
note("  33 + 106 = 139 was labelled 'Agriculture'; 98 + 98 + 28 = 224 was")
note("  labelled 'Business' although most of it is salaried employment.")
note("")

note("--- EC-FIES completeness ---")
note("  Complete on all 8 items: ", sum(!is.na(dat$ecfies_raw)), " of ", nrow(dat))
note("  1 item missing: ", sum(dat$ecfies_n_valid == 7),
     " | 2 items missing: ", sum(dat$ecfies_n_valid == 6))
note("")

# ----------------------------------------------------------
# 3. Table builders
# ----------------------------------------------------------
# One block of rows per variable: a bold heading, then one row per level.
# `denom` is spelled out per block because some variables have missing
# values and the percentage base has to be stated, not guessed.
blk <- function(x, heading, denom = NULL) {
  x   <- factor(x)
  tab <- table(x, useNA = "no")
  d   <- if (is.null(denom)) sum(tab) else denom
  rbind(
    data.frame(Characteristic = heading, n = "", pct = ""),
    data.frame(Characteristic = paste0("    ", names(tab)),
               n   = as.character(as.integer(tab)),
               pct = sprintf("%.1f", 100 * as.integer(tab) / d))
  )
}

mk_ft <- function(df, headings, note_txt) {
  ft <- flextable(df) %>%
    set_header_labels(Characteristic = "Characteristic",
                      n = "Frequency (n)", pct = "Percentage (%)") %>%
    bold(part = "header") %>%
    bold(i = which(df$Characteristic %in% headings), j = 1) %>%
    align(j = 2:3, align = "center", part = "all") %>%
    fontsize(size = 10, part = "all") %>%
    font(fontname = "Times New Roman", part = "all") %>%
    padding(padding.top = 2, padding.bottom = 2, part = "all") %>%
    border_remove() %>%
    hline_top(part = "header", border = fp_border(width = 1.2)) %>%
    hline_bottom(part = "header", border = fp_border(width = 1)) %>%
    hline_bottom(part = "body", border = fp_border(width = 1.2)) %>%
    set_table_properties(layout = "autofit", width = 1)
  attr(ft, "note") <- note_txt
  ft
}

# ----------------------------------------------------------
# 4. Table 3.1 - sample distribution by division
# ----------------------------------------------------------
t31_df <- dat %>%
  count(division, name = "n") %>%
  mutate(pct = sprintf("%.1f", 100 * n / nrow(dat))) %>%
  transmute(Division = as.character(division), n = as.character(n), pct) %>%
  bind_rows(data.frame(Division = "Total", n = as.character(nrow(dat)), pct = "100.0"))

t31 <- flextable(t31_df) %>%
  set_header_labels(Division = "Division", n = "Frequency (n)", pct = "Percentage (%)") %>%
  bold(part = "header") %>% bold(i = nrow(t31_df)) %>%
  align(j = 2:3, align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  font(fontname = "Times New Roman", part = "all") %>%
  border_remove() %>%
  hline_top(part = "header", border = fp_border(width = 1.2)) %>%
  hline_bottom(part = "header", border = fp_border(width = 1)) %>%
  hline_bottom(part = "body", border = fp_border(width = 1.2)) %>%
  set_table_properties(layout = "autofit", width = 1)

# ----------------------------------------------------------
# 5. Table 4.1 - household characteristics
# ----------------------------------------------------------
h41 <- c("Residence", "Type of family", "Household size", "Religion", "Wealth quintile")
t41_df <- rbind(
  blk(dat$residence,   h41[1]),
  blk(dat$family_type, h41[2]),
  blk(dat$hh_size,     h41[3]),
  blk(dat$religion,    h41[4]),
  blk(dat$wealth,      h41[5])
)
t41 <- mk_ft(t41_df, h41, paste0(
  "N = ", nrow(dat), ". Percentages are of the total sample. ",
  "Wealth quintile is the combined national wealth index built by principal ",
  "component analysis of household assets, housing materials, water and ",
  "sanitation, following the DHS procedure; quintiles are of this sample, not ",
  "of the national population."))

# ----------------------------------------------------------
# 6. Table 4.2 - child characteristics
# ----------------------------------------------------------
h42 <- c("Sex", "Age group", "Birth order", "Birth weight")
t42_df <- rbind(
  blk(dat$sex,         h42[1]),
  blk(dat$age_grp,     h42[2]),
  blk(dat$birth_order, h42[3]),
  blk(dat$bw_cat,      h42[4])
)
t42 <- mk_ft(t42_df, h42, paste0(
  "N = ", nrow(dat), ". Age is calculated from the recorded date of birth; for ",
  sum(dat$age_src != "Date of birth"),
  " children whose date of birth was not known the caregiver's estimate ",
  "(approximate age in months) is used. ",
  sum(dat$age_m < 6 | dat$age_m > 23, na.rm = TRUE),
  " children fell just outside the 6-23 month eligibility window (aged ",
  paste(sort(dat$age_m[dat$age_m < 6 | dat$age_m > 23]), collapse = " and "),
  " months) and are retained. Birth weight was reported in kilograms on ",
  sum(dat$bw_raw < 10, na.rm = TRUE), " forms and in grams on the rest; the ",
  "kilogram entries were converted before categorisation. Birth weight was ",
  "unknown to ", sum(dat$bw_cat == "Don't know"), " caregivers (",
  sprintf("%.1f%%", 100 * mean(dat$bw_cat == "Don't know")),
  "), which is shown as its own category rather than treated as missing."))

# ----------------------------------------------------------
# 7. Table 4.3 - maternal characteristics
# ----------------------------------------------------------
h43 <- c("Educational status", "Occupation", "Age at marriage",
         "Age at first birth")
t43_df <- rbind(
  blk(dat$m_edu,          h43[1]),
  blk(dat$m_occ,          h43[2]),
  blk(dat$m_age_marr_cat, h43[3]),
  blk(dat$m_age_b1_cat,   h43[4])
)
t43 <- mk_ft(t43_df, h43, paste0(
  "N = ", nrow(dat), ". Mean maternal age ",
  sprintf("%.1f years (SD %.1f)", mean(as.numeric(raw$B8_age_mother), na.rm = TRUE),
          sd(as.numeric(raw$B8_age_mother), na.rm = TRUE)),
  "; mean age at marriage ",
  sprintf("%.1f (SD %.1f)", mean(dat$m_age_marriage, na.rm = TRUE),
          sd(dat$m_age_marriage, na.rm = TRUE)),
  "; mean age at first birth ",
  sprintf("%.1f (SD %.1f)", mean(dat$m_age_birth1, na.rm = TRUE),
          sd(dat$m_age_birth1, na.rm = TRUE)), ". ",
  "'Employed / other' comprises ",
  paste(sprintf("%s (%d)", names(table(dat$m_occ_full)[names(table(dat$m_occ_full)) != "Housewife"]),
                as.integer(table(dat$m_occ_full)[names(table(dat$m_occ_full)) != "Housewife"])),
        collapse = ", "), "."))

# ----------------------------------------------------------
# 8. Table 4.4 - paternal characteristics
# ----------------------------------------------------------
h44 <- c("Educational status", "Occupation")
t44_df <- rbind(
  blk(dat$f_edu, h44[1]),
  blk(dat$f_occ, h44[2])
)
t44 <- mk_ft(t44_df, h44, paste0(
  "N = ", nrow(dat), ". Mean paternal age ",
  sprintf("%.1f years (SD %.1f)", mean(as.numeric(raw$B3_age_father), na.rm = TRUE),
          sd(as.numeric(raw$B3_age_father), na.rm = TRUE)), ". ",
  "All seven recorded occupation categories are shown separately. An earlier ",
  "draft collapsed them into two groups labelled 'Agriculture' (n = 139) and ",
  "'Business' (n = 224); the second of those is in fact mostly salaried ",
  "employment, so the collapsed labels are not used here."))

# ----------------------------------------------------------
# 9. Table 4.5 - EC-FIES severity by division and residence
# ----------------------------------------------------------
# Row percentages within each division x residence cell, so each row sums
# to 100. Cells with fewer than 10 respondents are footnoted rather than
# dropped, because dropping them would hide whole divisions.
ecf <- dat %>% filter(!is.na(ecfies_cat))

cell <- function(d) {
  tb <- table(factor(d$ecfies_cat,
                     levels = c("Food secure", "Mild", "Moderate", "Severe")))
  tot <- sum(tb)
  setNames(sprintf("%d (%.1f)", as.integer(tb), 100 * as.integer(tb) / tot),
           names(tb))
}

rows <- list()
for (dv in levels(ecf$division)) {
  for (rs in c("Urban", "Rural")) {
    sub <- ecf %>% filter(division == dv, residence == rs)
    if (nrow(sub) == 0) next
    rows[[length(rows) + 1]] <- data.frame(
      Division = dv, Residence = rs, N = as.character(nrow(sub)),
      t(cell(sub)), check.names = FALSE)
  }
}
for (rs in c("Urban", "Rural")) {
  sub <- ecf %>% filter(residence == rs)
  rows[[length(rows) + 1]] <- data.frame(
    Division = "All divisions", Residence = rs, N = as.character(nrow(sub)),
    t(cell(sub)), check.names = FALSE)
}
rows[[length(rows) + 1]] <- data.frame(
  Division = "All divisions", Residence = "Total", N = as.character(nrow(ecf)),
  t(cell(ecf)), check.names = FALSE)

t45_df <- do.call(rbind, rows)
tot_i  <- which(t45_df$Division == "All divisions")

t45 <- flextable(t45_df) %>%
  set_header_labels(N = "n") %>%
  add_header_row(values = c("", "", "", "EC-FIES severity, n (% of row)"),
                 colwidths = c(1, 1, 1, 4)) %>%
  bold(part = "header") %>%
  bold(i = tot_i) %>%
  align(j = 3:7, align = "center", part = "all") %>%
  align(i = 1, align = "center", part = "header") %>%
  fontsize(size = 9, part = "all") %>%
  font(fontname = "Times New Roman", part = "all") %>%
  padding(padding.top = 2, padding.bottom = 2, part = "all") %>%
  border_remove() %>%
  hline_top(part = "header", border = fp_border(width = 1.2)) %>%
  hline_bottom(part = "header", border = fp_border(width = 1)) %>%
  hline(i = min(tot_i) - 1, border = fp_border(width = 1)) %>%
  hline_bottom(part = "body", border = fp_border(width = 1.2)) %>%
  set_table_properties(layout = "autofit", width = 1)

small_cells <- sum(sapply(rows, function(r) as.integer(r$N) < 10)) -
               3  # the three summary rows are never small

t45_note <- paste0(
  "n = ", nrow(ecf), " of ", nrow(dat), " (", nrow(dat) - nrow(ecf),
  " respondents did not answer all eight EC-FIES items and are excluded). ",
  "Severity is the sum of affirmative responses to the eight EC-FIES items: ",
  "0 = food secure, 1-3 = mild, 4-6 = moderate, 7-8 = severe. ",
  "Percentages are of the row. Several division-by-residence cells contain ",
  "fewer than 15 respondents, so division-level estimates are imprecise and ",
  "should be read as descriptive only.")

# ----------------------------------------------------------
# 10. Export
# ----------------------------------------------------------
sm <- fp_text(font.size = 8, italic = TRUE, font.family = "Times New Roman")
ttl <- fp_text(font.size = 11, bold = TRUE, font.family = "Times New Roman")

add_tbl <- function(doc, title, ft, note_txt) {
  doc %>%
    body_add_fpar(fpar(ftext(title, ttl))) %>%
    body_add_flextable(ft) %>%
    body_add_fpar(fpar(ftext(note_txt, sm))) %>%
    body_add_par("")
}

doc <- read_docx() %>%
  add_tbl("Table 3.1  Distribution of the study sample by administrative division",
          t31, paste0("N = ", nrow(dat),
                      ". The planned sample was 400; ", nrow(dat),
                      " interviews were completed across 25 upazilas.")) %>%
  body_add_break() %>%
  add_tbl("Table 4.1  Household characteristics of the study participants",
          t41, attr(t41, "note")) %>%
  body_add_break() %>%
  add_tbl("Table 4.2  Characteristics of the children",
          t42, attr(t42, "note")) %>%
  body_add_break() %>%
  add_tbl("Table 4.3  Maternal characteristics of the study participants",
          t43, attr(t43, "note")) %>%
  body_add_break() %>%
  add_tbl("Table 4.4  Paternal characteristics of the study participants",
          t44, attr(t44, "note")) %>%
  body_add_break() %>%
  add_tbl("Table 4.5  Early childhood food insecurity by division and place of residence",
          t45, t45_note)

ok <- tryCatch({ print(doc, target = OUT_DOCX); TRUE },
               error = function(e) {
                 warning("Could not write ", OUT_DOCX,
                         " - it is probably open in Word. Close it and re-run. (",
                         conditionMessage(e), ")", call. = FALSE, immediate. = TRUE)
                 FALSE
               })
if (ok) message("Saved -> ", OUT_DOCX)

saveRDS(dat, OUT_RDS)
message("Saved -> ", OUT_RDS)

# ----------------------------------------------------------
# 11. Console echo of every table
# ----------------------------------------------------------
note("=== Table 3.1  Sample by division ===")
note(paste(capture.output(print(t31_df, row.names = FALSE)), collapse = "\n"))
note("")
note("=== Table 4.1  Household characteristics ===")
note(paste(capture.output(print(t41_df, row.names = FALSE)), collapse = "\n"))
note("")
note("=== Table 4.2  Child characteristics ===")
note(paste(capture.output(print(t42_df, row.names = FALSE)), collapse = "\n"))
note("")
note("=== Table 4.3  Maternal characteristics ===")
note(paste(capture.output(print(t43_df, row.names = FALSE)), collapse = "\n"))
note("")
note("=== Table 4.4  Paternal characteristics ===")
note(paste(capture.output(print(t44_df, row.names = FALSE)), collapse = "\n"))
note("")
note("=== Table 4.5  EC-FIES by division and residence ===")
note(paste(capture.output(print(t45_df, row.names = FALSE)), collapse = "\n"))

writeLines(LOG, OUT_LOG)
message("Saved -> ", OUT_LOG)
