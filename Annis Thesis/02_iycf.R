# ============================================================
# Anni MS thesis - Early Childhood Food Insecurity (EC-FIES), Bangladesh
# 02_iycf.R  -  Infant and young child feeding indicators
# ------------------------------------------------------------
# Source data : Data/MAIN.sav  (KoBo/ODK export, N = 407 mother-child pairs)
# Reference   : Materials/indicator_methods.pdf
#               WHO & UNICEF (2021). Indicators for assessing infant and young
#               child feeding practices: definitions and measurement methods.
#               Geneva: World Health Organization.
#               Definitions   - Part 1, section B
#               Algorithms    - Part 2, section C  (followed line by line below)
#               Food groups   - Annex 6, and the row mapping in Annex 8
#
# Produces:
#   doc/Tables_IYCF.docx     Tables 4.10 - 4.13
#   Graph/Fig4_5_food_groups.png
#   Graph/Fig4_6_hh_vs_child.png
#   Data/iycf_analysis.rds   analysis-ready data frame for 05_models.R
#   doc/iycf_log.txt         run log, data-quality flags, self-check results
#
# ------------------------------------------------------------
# ANALYTIC DECISIONS AND DEVIATIONS - read before using the output
# ------------------------------------------------------------
# 1. INSTRUMENT PROVENANCE.  Module F of the questionnaire is a Bengali
#    translation of the example questionnaire in Part 2 section B.4 of the WHO
#    document, essentially row for row.  The variable mapping is in section 5
#    below and is NOT guessable from the variable names, because the instrument
#    folded WHO's separate liquids block (Q6) into the F.A rows.
#
# 2. YOGURT IS SPLIT AND MUST STAY SPLIT.  WHO asks about liquid yogurt drink
#    (Q6D) and semi-solid yogurt (Q7A) as two questions because they enter the
#    indicators differently: liquid yogurt counts toward non-breastfed meal
#    frequency, semi-solid yogurt does not (it is already inside Q8), and both
#    count toward the milk-feed minimum.  This instrument asks ONE gate question
#    (F.A.3) with TWO frequency counts (F.A.3Num1 liquid, F.A.3Num2 semi-solid).
#    17 of the 21 yogurt consumers had zero LIQUID yogurt, so collapsing the two
#    counts would misclassify most of that group.
#
# 3. DENOMINATOR.  WHO defines the denominator as age in days >= 183 and < 730.
#    Only completed months are recorded here.  Indicators are reported on all
#    407 for consistency with the EC-FIES tables, and the script also prints the
#    6-23 month restriction as a sensitivity check.  Nothing moves by more than
#    0.2 percentage points.  See Table 4.10 footnote.
#
# 4. MEAL FREQUENCY IS ASKED OUT OF ORDER.  The instrument asks F.A (meal count)
#    BEFORE the food list; WHO asks it after (Q8 follows Q7), so that the
#    respondent has been walked through what counts as a food first.  This is
#    almost certainly why 11 records contradict each other (section 11).  ISSSF
#    is therefore computed from the FOOD LIST, as Part 2 section C.7 requires,
#    not from the meal count.
#
# 5. DO NOT DICHOTOMISE FOR ANALYSIS.  WHO's cut-offs exist to report
#    prevalence.  Collapsing an 8-point score to yes/no at 5, or a meal count to
#    yes/no at 3, discards most of the variance - 33.2% of children sit exactly
#    ON the meal-frequency cut-off.  Section 8 builds the continuous and count
#    forms; Table 4.12 tests on those.  See section 3.7 of doc/Analysis_Plan.md.
#
# 6. SEVEN OF WHO's 17 INDICATORS CANNOT BE COMPUTED.  EvBF, EIBF and EBF2D need
#    birth-recall feeding questions that Module B does not carry; EBF and MixMF
#    have a 0-5 month denominator and this sample is 6-23 months; BoF needs
#    WHO's Q5, not asked; area graphs need both.  Stated in the Table 4.10
#    footnote rather than left for the reader to notice.
#
# 7. "DON'T KNOW" (code 8) on a food row is scored as NOT CONSUMED, per WHO.
#    On the barrier items it is treated as MISSING, because there "don't know"
#    is a substantive answer and 30 respondents gave it on one item.
#
# 8. NOT YET RUN IN R.  Every figure this script produces was computed
#    independently from Data/MAIN.sav while the analysis plan was written, and
#    section 12 checks the script's output against those values and stops if any
#    disagree.  If section 12 reports a mismatch, trust neither number until the
#    difference is understood.
# ============================================================

# ----------------------------------------------------------
# 1. Packages
# ----------------------------------------------------------
library(haven)
library(dplyr)
library(ggplot2)
library(flextable)
library(officer)

SAV       <- "Data/MAIN.sav"
OUT_DOCX  <- "doc/Tables_IYCF.docx"     # generated - NOT a client document
OUT_LOG   <- "doc/iycf_log.txt"
OUT_RDS   <- "Data/iycf_analysis.rds"
GRAPH_DIR <- "Graph"

dir.create("doc",     showWarnings = FALSE)
dir.create("Data",    showWarnings = FALSE)
dir.create(GRAPH_DIR, showWarnings = FALSE)

# ----------------------------------------------------------
# 2. Helpers
# ----------------------------------------------------------
LOG  <- character(0)
note <- function(...) { m <- paste0(...); LOG <<- c(LOG, m); message(m) }
rule <- function(t) note("\n", strrep("-", 66), "\n", t, "\n", strrep("-", 66))

# Windows locks files that are open in Word or Excel.  Warn and carry on rather
# than aborting the run half-way through - same pattern as Project-14/script.R.
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

# The KoBo export mangles long question text into long variable names
# (e.g. Fswt1_Was_the_milk_or_were_avoured_type_of_milk).  Matching on a stable
# prefix rather than the full name means a re-export with slightly different
# truncation still runs.  Erroring on 0 or 2+ matches is deliberate: a silent
# wrong-column match would be far worse than a stop().
one_col <- function(df, pattern) {
  hit <- grep(pattern, names(df), value = TRUE)
  if (length(hit) != 1L)
    stop("Expected exactly 1 column matching '", pattern, "', found ",
         length(hit), if (length(hit)) paste0(": ", paste(hit, collapse = ", ")),
         call. = FALSE)
  hit
}
# yes() is TRUE only for an explicit "1 = Yes".  Code 8 ("Don't know") and NA
# both fall through to FALSE, which is exactly WHO's rule for the food rows.
yes  <- function(df, pattern) as.numeric(df[[one_col(df, pattern)]]) %in% 1
# WHO Part 2 section C.9 and C.10: a frequency question skipped because the
# child did not consume the item, or left missing, scores 0.
z0   <- function(df, pattern) { x <- as.numeric(df[[one_col(df, pattern)]]); ifelse(is.na(x), 0, x) }
num  <- function(df, pattern) as.numeric(df[[one_col(df, pattern)]])

# Wilson score interval, no continuity correction.  Written out rather than
# calling prop.test() so the method is visible in the script and identical for
# every row of Table 4.10, including the 0% and 100% edge cases.
wilson <- function(k, n) {
  if (is.na(n) || n == 0) return(c(NA_real_, NA_real_))
  p <- k / n; z <- qnorm(0.975)
  den <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / den
  hw  <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  100 * c(ctr - hw, ctr + hw)
}
pct_ci <- function(k, n) {
  ci <- wilson(k, n)
  sprintf("%d/%d (%.1f)   %.1f-%.1f", k, n, 100 * k / n, ci[1], ci[2])
}
fmt_p <- function(p) ifelse(is.na(p), "-", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))

# Spearman correlation.  exact = FALSE because every one of these variables is
# heavily tied, so the exact permutation p-value is unavailable anyway and R
# would only warn about it.
sp <- function(x, y) {
  ok <- stats::complete.cases(x, y)
  ct <- suppressWarnings(cor.test(x[ok], y[ok], method = "spearman", exact = FALSE))
  c(rho = unname(ct$estimate), p = ct$p.value, n = sum(ok))
}
# Partial Spearman: rank-transform outcome, exposure and control, then correlate
# the residuals of the first two regressed on the third.  Used to strip the
# wealth gradient out of a diet-vs-EC-FIES association without assuming
# linearity on the original scales.
sp_partial <- function(x, y, ctrl) {
  ok <- stats::complete.cases(x, y, ctrl)
  rx <- rank(x[ok]); ry <- rank(y[ok]); rc <- rank(ctrl[ok])
  ex <- residuals(lm(rx ~ rc)); ey <- residuals(lm(ry ~ rc))
  ct <- cor.test(ex, ey)
  c(rho = unname(ct$estimate), p = ct$p.value, n = sum(ok))
}

# Okabe-Ito, colour-blind safe.  The client has asked for NO RED anywhere.
OK_BLUE  <- "#0072B2"
OK_AMBER <- "#E69F00"
OK_GREEN <- "#009E73"
OK_GREY  <- "#4D4D4D"

theme_thesis <- theme_minimal(base_size = 11, base_family = "sans") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.title = element_text(size = 10),
        plot.caption = element_text(size = 8, hjust = 0, colour = OK_GREY),
        legend.position = "top", legend.title = element_blank())

# ----------------------------------------------------------
# 3. Read
# ----------------------------------------------------------
raw <- read_sav(SAV)
rule("02_iycf.R")
note("Run: ", format(Sys.time(), "%Y-%m-%d %H:%M"))
note("Source: ", SAV)
note("Rows read: ", nrow(raw), " | columns: ", ncol(raw))

# ----------------------------------------------------------
# 4. Age, breastfeeding status, denominator
# ----------------------------------------------------------
# age_months is stored as a STRING and is blank for 18 children; approx_age
# carries their age and recovers all 18.  See section 2.3 of the analysis plan.
age_dob  <- suppressWarnings(as.numeric(as.character(raw$age_months)))
age_appr <- suppressWarnings(as.numeric(raw$approx_age))
age_m    <- ifelse(is.na(age_dob), age_appr, age_dob)

bf <- yes(raw, "^F_A_0_Breastmilk")               # WHO Q4: breastfed yesterday
Q8 <- z0(raw, "^F_A_freq_food")                   # WHO Q8: solid/semi-solid feeds

# The !is.na() guards are not decoration: age_m would be NA if a child had
# neither a date of birth nor an approximate age, and a single NA here would
# silently poison every denominator downstream instead of erroring.
elig  <- !is.na(age_m) & age_m >= 6  & age_m <= 23   # WHO: >=183 and <730 days
w_cbf <- !is.na(age_m) & age_m >= 12 & age_m <= 23   # CBF denominator
w_iss <- !is.na(age_m) & age_m >= 6  & age_m <= 8    # ISSSF denominator
note("Age recovered from approx_age for ", sum(is.na(age_dob)), " children.")
note("Outside the 6-23 month window: ", sum(!elig, na.rm = TRUE),
     " (ages ", paste(sort(age_m[!elig]), collapse = ", "), " months)")
note("Breastfed yesterday: ", sum(bf), "/", nrow(raw),
     sprintf(" (%.1f%%)", 100 * mean(bf)))

# ----------------------------------------------------------
# 5. The eight MDD food groups
#    WHO Part 2 section C.8, and the row mapping in Annex 8.
#    WHO question number -> variable in MAIN.sav:
#      Q4   breast milk           F_A_0_Breastmilk
#      Q6B  infant formula        F_A_1_Infant_formula   (+ F_A_1Num...)
#      Q6C  animal milk           F_A_2_ANIMAL_MILK      (+ F_A_2Num...)
#      Q6D  liquid yogurt drink   F_A_3_YOGURT gate      (+ F_A_3Num1...)
#      Q7A  semi-solid yogurt     F_A_3_YOGURT gate      (+ F_A_3Num2...)
#      Q7B..Q7R  the 17 food rows F_B_... .. F_R_0_other_food, in order
# ----------------------------------------------------------
fg1 <- bf                                                            # breast milk
fg2 <- yes(raw, "^F_B_FOODS_MADE_FROM_GRAINS") | yes(raw, "^F_D_ROOTS")
fg3 <- yes(raw, "^F_N_PEAS_NUTS")                                    # pulses, nuts, seeds
fg4 <- yes(raw, "^F_A_1_Infant_formula") | yes(raw, "^F_A_2_ANIMAL_MILK") |
       yes(raw, "^F_A_3_YOGURT")        | yes(raw, "^F_O_CHEESE")    # dairy
fg5 <- yes(raw, "^F_I_ORGAN_MEAT") | yes(raw, "^F_J_PROCESSED_MEATS") |
       yes(raw, "^F_K_OTHER_MEATS") | yes(raw, "^F_M_FRESH_OR_DRIED_FISH")
fg6 <- yes(raw, "^F_L_EGGS")                                         # eggs
fg7 <- yes(raw, "^F_C_CARROTS_SQUASH_ETC") | yes(raw, "^F_E_LEAFY_VEGETABLES") |
       yes(raw, "^F_G_MANGO_RIPE_PAPAYA")                            # vitamin-A rich
fg8 <- yes(raw, "^F_F_OTHER_VEGETABLES") | yes(raw, "^F_H_OTHER_FRUITS")

FG <- cbind(fg1, fg2, fg3, fg4, fg5, fg6, fg7, fg8)
colnames(FG) <- c("Breast milk", "Grains, roots, tubers", "Pulses, nuts, seeds",
                  "Dairy", "Flesh foods", "Eggs",
                  "Vitamin-A rich fruit & veg", "Other fruit & veg")
fgs <- rowSums(FG)                                                   # 0-8

# ----------------------------------------------------------
# 6. Milk feed counts
#    Two different sums, and they are NOT interchangeable:
#      milk_mmf  - for MMF  (Part 2 C.9)  EXCLUDES semi-solid yogurt, because
#                  semi-solid yogurt is already counted inside Q8.
#      milk_mmff - for MMFF (Part 2 C.10) INCLUDES it.
# ----------------------------------------------------------
n_formula <- z0(raw, "^F_A_1Num")
n_animal  <- z0(raw, "^F_A_2Num")
n_yog_liq <- z0(raw, "^F_A_3Num1")
n_yog_sem <- z0(raw, "^F_A_3Num2")

milk_mmf  <- n_formula + n_animal + n_yog_liq
milk_mmff <- milk_mmf + n_yog_sem

# ----------------------------------------------------------
# 7. The ten computable indicators  (WHO Part 2 section C)
# ----------------------------------------------------------
MDD <- fgs >= 5                                                       # C.8

# C.9  breastfed 6-8 mo need >=2; breastfed 9-23 mo need >=3;
#      non-breastfed need >=4 counting milk feeds, with >=1 solid feed.
MMF <- (age_m >= 6 & age_m <= 8  & bf & Q8 >= 2) |
       (age_m >= 9 & age_m <= 23 & bf & Q8 >= 3) |
       (!bf & (milk_mmf + Q8) >= 4 & Q8 >= 1)

MMFF <- !bf & milk_mmff >= 2                                          # C.10, non-BF only
MAD  <- MDD & MMF & (bf | MMFF)                                       # C.11
EFF  <- fg5 | fg6                                                     # C.12, eggs and/or flesh

# C.13  Chocolate drinks, juice and sodas are assumed sweet; milk, yogurt
#       drinks, tea/coffee and "other" have their own "was it sweetened?" probe.
SwB <- yes(raw, "^Fswt1") | yes(raw, "^Fswt2") | yes(raw, "^Fswt3") |
       yes(raw, "^Fswt4") | yes(raw, "^Fswt5") |
       yes(raw, "^Fswt6_1") | yes(raw, "^Fswt7_1")

UFC <- yes(raw, "^F_P_SWEET_FOODS") | yes(raw, "^F_Q_SALTY_FOODS")    # C.14, sentinel foods

# C.15  Zero vegetable or fruit.  Starchy roots and tubers are in food group 2
#       and deliberately do NOT count here.
fv_rows_m <- cbind(yes(raw, "^F_C_CARROTS_SQUASH_ETC"), yes(raw, "^F_E_LEAFY_VEGETABLES"),
                   yes(raw, "^F_F_OTHER_VEGETABLES"),   yes(raw, "^F_G_MANGO_RIPE_PAPAYA"),
                   yes(raw, "^F_H_OTHER_FRUITS"))
ZVF <- rowSums(fv_rows_m) == 0

CBF <- bf                                                             # C.6, denom 12-23 mo

# C.7  ISSSF is calculated from the FOOD LIST, not from the meal-count question.
FOOD_ROWS <- c("^F_B_FOODS_MADE_FROM_GRAINS", "^F_C_CARROTS_SQUASH_ETC", "^F_D_ROOTS",
               "^F_E_LEAFY_VEGETABLES", "^F_F_OTHER_VEGETABLES", "^F_G_MANGO_RIPE_PAPAYA",
               "^F_H_OTHER_FRUITS", "^F_I_ORGAN_MEAT", "^F_J_PROCESSED_MEATS",
               "^F_K_OTHER_MEATS", "^F_L_EGGS", "^F_M_FRESH_OR_DRIED_FISH",
               "^F_N_PEAS_NUTS", "^F_O_CHEESE", "^F_P_SWEET_FOODS", "^F_Q_SALTY_FOODS",
               "^F_R_0_other_food")
food_any <- Reduce(`|`, lapply(FOOD_ROWS, function(p) yes(raw, p)))
ISSSF    <- food_any

# ----------------------------------------------------------
# 8. Continuous and count forms - the ANALYSIS variables
#    Section 3.7 of the analysis plan.  The binary indicators above are for
#    reporting prevalence; everything below is what the models and the
#    association tests actually use.
# ----------------------------------------------------------
meals      <- Q8                                     # 0-10 count
fv_rows    <- rowSums(fv_rows_m)                     # 0-5
asf_rows   <- rowSums(cbind(
                yes(raw, "^F_I_ORGAN_MEAT"), yes(raw, "^F_J_PROCESSED_MEATS"),
                yes(raw, "^F_K_OTHER_MEATS"), yes(raw, "^F_M_FRESH_OR_DRIED_FISH"),
                yes(raw, "^F_L_EGGS"), yes(raw, "^F_A_1_Infant_formula"),
                yes(raw, "^F_A_2_ANIMAL_MILK"), yes(raw, "^F_A_3_YOGURT"),
                yes(raw, "^F_O_CHEESE")))            # 0-9
all_rows   <- rowSums(sapply(FOOD_ROWS, function(p) yes(raw, p)))    # 0-17
sweet_n    <- rowSums(cbind(
                yes(raw, "^Fswt1"), yes(raw, "^Fswt2"), yes(raw, "^Fswt3"),
                yes(raw, "^Fswt4"), yes(raw, "^Fswt5"),
                yes(raw, "^Fswt6_1"), yes(raw, "^Fswt7_1")))         # 0-7
ufc_n      <- rowSums(cbind(yes(raw, "^F_P_SWEET_FOODS"),
                            yes(raw, "^F_Q_SALTY_FOODS")))           # 0-2

# ----------------------------------------------------------
# 9. Module E - household diet, and the household-to-child pass-through
#    Five household-level food groups, asked of the same respondent about the
#    same 24 hours.  Section 4.4 of the analysis plan: this is the one diet
#    measure that tracks EC-FIES.
# ----------------------------------------------------------
E_COLS <- c("^E1_Grains_Or_Roots", "^E2_Vitamin_A_Ruits_And_Vegetables",
            "^E3_Other_Fruits_And_Vegetables", "^E4_Eggs_And_Flesh_Foods",
            "^E5_Pulses_Nuts_And_Seeds")
E_mat  <- sapply(E_COLS, function(p) yes(raw, p))
colnames(E_mat) <- c("Grains/roots", "Vitamin-A fruit/veg", "Other fruit/veg",
                     "Eggs/flesh foods", "Pulses/nuts/seeds")
hhdiv  <- rowSums(E_mat)                              # 0-5

# The child-side counterpart of each household group.  Note eggs and flesh are
# ONE household row (E4) but two MDD groups, so the child side is fg5 | fg6.
child_match <- cbind(`Grains/roots`         = fg2,
                     `Vitamin-A fruit/veg`  = fg7,
                     `Other fruit/veg`      = fg8,
                     `Eggs/flesh foods`     = fg5 | fg6,
                     `Pulses/nuts/seeds`    = fg3)

# ----------------------------------------------------------
# 10. EC-FIES - the exposure (Direction B) / outcome (Direction A)
#     The 8 items were already pooled across the two age blocks in the SPSS
#     file.  17 "don't know" responses were recoded to missing before export.
#     Complete cases only for the raw score, per section 2.3 of the plan.
# ----------------------------------------------------------
EC_ITEMS <- c("G_Worried", "G_Unable_healthy", "G_fewer", "G_unable_enough_food",
              "G_less_food", "G_run_out_food", "G_hungry", "G_did_not_eat")
EC <- sapply(EC_ITEMS, function(v) as.numeric(raw[[v]]))
ec_valid <- rowSums(!is.na(EC))
ec_raw   <- ifelse(ec_valid == 8, rowSums(EC), NA_real_)
ec_cat   <- cut(ec_raw, breaks = c(-Inf, 0, 3, 6, 8),
                labels = c("Food secure", "Mild", "Moderate", "Severe"))
ec_cat   <- factor(ec_cat, levels = c("Food secure", "Mild", "Moderate", "Severe"))
modsev   <- ec_raw >= 4

note("EC-FIES complete on all 8 items: ", sum(!is.na(ec_raw)), "/", nrow(raw))

# ----------------------------------------------------------
# 11. Data-quality checks
#     Section 2.6 of the analysis plan.  These are FLAGGED, not silently fixed.
# ----------------------------------------------------------
rule("DATA-QUALITY FLAGS (Module F)")

bad_hi <- Q8 == 0 & food_any
bad_lo <- Q8 >= 1 & !food_any
note("(a) Meal count contradicts the food list:")
note("      says 0 meals but a food was reported : ", sum(bad_hi))
note("      says >=1 meal but no food reported   : ", sum(bad_lo))
note("      -> ", sum(bad_hi | bad_lo), " records total. ISSSF uses the food list (WHO C.7).")
note("      Cause is almost certainly decision 4 in the header: F.A is asked")
note("      before the food list, where WHO asks it after.")

note("(c) F_A_1Num == 8, ambiguous with the 'Don't know' code: ",
     sum(num(raw, "^F_A_1Num") == 8, na.rm = TRUE))
note("(d) Formula = Yes but count = 0: ",
     sum(yes(raw, "^F_A_1_Infant_formula") & num(raw, "^F_A_1Num") == 0, na.rm = TRUE))

milk_any <- yes(raw, "^F_A_1_Infant_formula") | yes(raw, "^F_A_2_ANIMAL_MILK")
ungated  <- sum(yes(raw, "^Fswt1") & !milk_any) + sum(yes(raw, "^Fswt2") & !yes(raw, "^F_A_3_YOGURT"))
note("(e) Sweet-drink probe answered with no matching drink reported: ", ungated)
SwB_gated <- (yes(raw, "^Fswt1") & milk_any) | (yes(raw, "^Fswt2") & yes(raw, "^F_A_3_YOGURT")) |
             yes(raw, "^Fswt3") | yes(raw, "^Fswt4") | yes(raw, "^Fswt5") |
             yes(raw, "^Fswt6_1") | yes(raw, "^Fswt7_1")
note("      SwB as specified ", sprintf("%.1f%%", 100 * mean(SwB)),
     " vs gated ", sprintf("%.1f%%", 100 * mean(SwB_gated)), " - see Table 4.10 footnote.")

note("(f) Sodas/malt/energy row: ", sum(yes(raw, "^Fswt5")), " of ", nrow(raw), " reported Yes.")
if (sum(yes(raw, "^Fswt5")) == 0)
  note("      ZERO VARIANCE. Plausible for this age group, but the Bengali form")
note("      numbers two consecutive rows 'Fswt5'. Confirm the row was administered.")

note("(g) Food-group score of 1 (breast milk only): ", sum(fgs == 1),
     ", of whom ", sum(fgs == 1 & Q8 == 0), " recorded zero meals.")
if (any(fgs == 1 & age_m >= 12, na.rm = TRUE))
  note("      Includes children aged >= 12 months (max ", max(age_m[fgs == 1], na.rm = TRUE),
       " mo) - implausible, verify against the paper forms.")

dk_rows <- sapply(c("^F_A_0_Breastmilk", FOOD_ROWS), function(p) num(raw, p) == 8)
note("(h) 'Don't know' on food rows: ", sum(dk_rows, na.rm = TRUE), " responses across ",
     sum(rowSums(dk_rows, na.rm = TRUE) > 0), " children. Scored as not consumed, per WHO.")

# ----------------------------------------------------------
# 12. Self-check against doc/Analysis_Plan.md
#     Every value below was computed independently from MAIN.sav when the plan
#     was written.  If R disagrees, something is wrong in one of the two and
#     nothing downstream should be trusted until it is resolved.
# ----------------------------------------------------------
rule("SELF-CHECK against the analysis plan")
expect <- list(
  list("MDD",              sum(MDD),                     155),
  list("MMF",              sum(MMF),                     261),
  list("MAD",              sum(MAD),                     118),
  list("EFF",              sum(EFF),                     266),
  list("SwB",              sum(SwB),                      71),
  list("UFC",              sum(UFC),                     185),
  list("ZVF",              sum(ZVF),                     170),
  list("CBF (12-23 mo)",   sum(CBF[w_cbf]),              206),
  list("ISSSF (6-8 mo)",   sum(ISSSF[w_iss]),             76),
  list("MMFF (non-BF)",    sum(MMFF[!bf]),                16),
  list("Breastfed",        sum(bf),                      380),
  list("EC-FIES complete", sum(!is.na(ec_raw)),          392),
  list("Moderate/severe",  sum(modsev, na.rm = TRUE),     80),
  list("Food-group score sum", sum(fgs),                1639),
  list("Household groups sum", sum(hhdiv),              1305)
)
bad <- 0
for (e in expect) {
  ok <- isTRUE(all.equal(e[[2]], e[[3]]))
  if (!ok) bad <- bad + 1
  note(sprintf("  %-22s computed %5s   expected %5s   %s",
               e[[1]], e[[2]], e[[3]], if (ok) "ok" else "*** MISMATCH ***"))
}
if (bad > 0)
  warning(bad, " self-check mismatch(es). Do NOT use the tables until resolved.",
          call. = FALSE, immediate. = TRUE) else note("  All ", length(expect), " checks passed.")

# ----------------------------------------------------------
# 13. Analysis data frame
# ----------------------------------------------------------
dat <- tibble(
  id         = as.integer(raw$ID),
  age_m      = age_m,
  age_grp    = cut(age_m, c(-Inf, 8, 11, 17, Inf),
                   labels = c("6-8 months", "9-11 months", "12-17 months", "18-23 months")),
  sex        = factor(as.numeric(raw$D5_sex_of_the_child), levels = c(1, 2),
                      labels = c("Male", "Female")),
  urban      = as.integer(as.numeric(raw$A2_3_Residence) == 1),
  division   = as_factor(raw$DIVISION),
  wealth     = factor(as.numeric(raw$Ncombsco), levels = 1:5,
                      labels = c("Poorest", "Poorer", "Middle", "Richer", "Richest")),
  medu       = factor(as.numeric(raw$B11_edu_mother), levels = 1:5,
                      labels = c("No formal education", "Primary", "Secondary",
                                 "Higher secondary", "Higher education")),
  fedu       = factor(as.numeric(raw$B5_education_child_father), levels = 1:5,
                      labels = c("No formal education", "Primary", "Secondary",
                                 "Higher secondary", "Higher education")),
  hhsize     = as.numeric(raw$B6_members_household),
  bf         = as.integer(bf),
  # WHO binary indicators - for REPORTING prevalence
  mdd = as.integer(MDD), mmf = as.integer(MMF), mad = as.integer(MAD),
  eff = as.integer(EFF), swb = as.integer(SwB), ufc = as.integer(UFC),
  zvf = as.integer(ZVF), mmff = as.integer(MMFF), isssf = as.integer(ISSSF),
  # underlying scales - for ANALYSIS (section 3.7 of the plan)
  fgs = fgs, meals = meals, fv_rows = fv_rows, asf_rows = asf_rows,
  all_rows = all_rows, sweet_n = sweet_n, ufc_n = ufc_n, hhdiv = hhdiv,
  # EC-FIES
  ec_raw = ec_raw, ec_cat = ec_cat,
  modsev = ifelse(is.na(ec_raw), NA_integer_, as.integer(ec_raw >= 4)),
  # data-quality flag, so 05_models.R can run a sensitivity analysis
  flag_meal_contradiction = as.integer(bad_hi | bad_lo)
)

# ----------------------------------------------------------
# 14. Table 4.10 - the ten indicators
# ----------------------------------------------------------
ind_rows <- list(
  list("Minimum dietary diversity (MDD)",            MDD,   rep(TRUE, nrow(raw))),
  list("Minimum meal frequency (MMF)",               MMF,   rep(TRUE, nrow(raw))),
  list("Minimum acceptable diet (MAD)",              MAD,   rep(TRUE, nrow(raw))),
  list("Egg and/or flesh food consumption (EFF)",    EFF,   rep(TRUE, nrow(raw))),
  list("Sweet beverage consumption (SwB)",           SwB,   rep(TRUE, nrow(raw))),
  list("Unhealthy food consumption (UFC)",           UFC,   rep(TRUE, nrow(raw))),
  list("Zero vegetable or fruit consumption (ZVF)",  ZVF,   rep(TRUE, nrow(raw))),
  list("Continued breastfeeding 12-23 mo (CBF)",     CBF,   w_cbf),
  list("Introduction of solid foods 6-8 mo (ISSSF)", ISSSF, w_iss),
  list("Minimum milk feeding frequency (MMFF)",      MMFF,  !bf),
  list("Breastfed yesterday (context)",              bf,    rep(TRUE, nrow(raw)))
)
BDHS <- c("~34", "~65", "~28", "-", "-", "-", "-", "~94", "-", "-", "-")
t410 <- data.frame(
  Indicator = sapply(ind_rows, `[[`, 1),
  Estimate  = sapply(ind_rows, function(r) pct_ci(sum(r[[2]] & r[[3]]), sum(r[[3]]))),
  Restricted = sapply(ind_rows, function(r) {
    d <- r[[3]] & elig
    sprintf("%.1f", 100 * sum(r[[2]] & d) / sum(d))
  }),
  `BDHS 2022` = BDHS, check.names = FALSE, stringsAsFactors = FALSE
)

mk_ft <- function(df, widths = NULL) {
  ft <- flextable(df) %>%
    bold(part = "header") %>%
    align(j = 2:ncol(df), align = "center", part = "all") %>%
    fontsize(size = 9, part = "all") %>%
    font(fontname = "Times New Roman", part = "all") %>%
    padding(padding.top = 2, padding.bottom = 2, part = "all") %>%
    border_remove() %>%
    hline_top(part = "header", border = fp_border(width = 1.2)) %>%
    hline_bottom(part = "header", border = fp_border(width = 1)) %>%
    hline_bottom(part = "body", border = fp_border(width = 1.2))
  set_table_properties(ft, layout = "autofit", width = 1)
}
ft410 <- mk_ft(t410) %>%
  set_header_labels(Estimate = "n/N (%)   95% CI", Restricted = "6-23 mo only (%)")

foot410 <- paste0(
  "Indicators follow WHO & UNICEF (2021), Indicators for assessing infant and young child feeding ",
  "practices: definitions and measurement methods, Part 2 section C. Percentages are of the ",
  "denominator each indicator defines, shown in the n/N column; 95% confidence intervals are Wilson ",
  "score intervals without continuity correction and do NOT account for clustering within the 25 ",
  "upazila recruitment sites, so they are narrower than a design-adjusted interval would be. ",
  "The '6-23 mo only' column restricts to the ", sum(elig), " children inside WHO's age window, ",
  "excluding one aged 5 months and one aged 24 months; no indicator moves by more than 0.2 ",
  "percentage points. Seven of WHO's 17 indicators cannot be computed from these data: ever ",
  "breastfed, early initiation of breastfeeding and exclusive breastfeeding for the first two days ",
  "require birth-recall questions that were not asked; exclusive and mixed milk feeding have a 0-5 ",
  "month denominator and this sample is 6-23 months; bottle feeding was not asked; and the infant ",
  "feeding area graphs require both. Sweet beverage consumption is ",
  sprintf("%.1f%%", 100 * mean(SwB)), " as specified and ", sprintf("%.1f%%", 100 * mean(SwB_gated)),
  " if the sweetness probe is required to match a drink actually reported, which ",
  ungated, " records do not. BDHS 2022 comparators are approximate and must be verified against ",
  "the BDHS final report before publication; dashes mark indicators new in the 2021 revision for ",
  "which the comparator has not yet been looked up."
)

# ----------------------------------------------------------
# 15. Table 4.11 - the eight food groups
# ----------------------------------------------------------
t411 <- data.frame(
  `Food group` = c(colnames(FG), "Mean food-group score (of 8)"),
  n            = c(sprintf("%d", colSums(FG)), sprintf("%.2f", mean(fgs))),
  `%`          = c(sprintf("%.1f", 100 * colMeans(FG)), ""),
  `95% CI`     = c(apply(FG, 2, function(g) {
                     ci <- wilson(sum(g), length(g)); sprintf("%.1f-%.1f", ci[1], ci[2]) }),
                   sprintf("SD %.2f", sd(fgs))),
  check.names = FALSE, stringsAsFactors = FALSE
)
ft411 <- mk_ft(t411)
foot411 <- paste0(
  "The eight food groups of the minimum dietary diversity indicator, WHO & UNICEF (2021) Part 2 ",
  "section C.8 and Annex 8. Denominator ", nrow(raw), " for every row. Group 2 combines the grains ",
  "row and the roots-and-tubers row; group 4 combines infant formula, animal milk, yogurt and ",
  "cheese; group 5 combines organ meat, processed meat, other meat and fish; group 7 combines ",
  "pumpkin/carrot/squash, dark green leafy vegetables and ripe mango/papaya; group 8 combines other ",
  "vegetables and other fruits. Starchy roots and tubers count in group 2 and are deliberately ",
  "excluded from the zero-vegetable-or-fruit indicator. 'Don't know' responses are scored as not ",
  "consumed, per WHO. Minimum dietary diversity is a score of five or more; ",
  sprintf("%.1f%%", 100 * mean(MDD)), " of children reached it."
)

# ----------------------------------------------------------
# 16. Table 4.12 - diet on the underlying scales vs EC-FIES
#     Section 3.7 of the plan: test on the scale, not the cut-off.
# ----------------------------------------------------------
scale_vars <- list(
  list("Household food groups (Module E)", hhdiv,    "0-5"),
  list("Meal frequency count",             meals,    "0-10"),
  list("Animal-source food rows",          asf_rows, "0-9"),
  list("Fruit and vegetable rows",         fv_rows,  "0-5"),
  list("Child food-group score",           fgs,      "0-8"),
  list("Unhealthy food items",             ufc_n,    "0-2"),
  list("Sweet beverage items",             sweet_n,  "0-7"),
  list("Food rows endorsed",               all_rows, "0-17")
)
wealth_n <- as.numeric(raw$Ncombsco)
t412 <- do.call(rbind, lapply(scale_vars, function(v) {
  s  <- sp(v[[2]], ec_raw)
  sa <- sp_partial(v[[2]], ec_raw, wealth_n)
  # kruskal.test(x, g), not the formula interface: the formula method resolves
  # its terms in the formula's environment, and inside this lapply the
  # left-hand side is an expression rather than a name.
  keep  <- !is.na(ec_cat)
  grp   <- droplevels(ec_cat[keep])
  kw    <- kruskal.test(v[[2]][keep], grp)
  means <- tapply(v[[2]][keep], grp, mean)
  data.frame(
    Measure = v[[1]], Range = v[[3]],
    Secure = sprintf("%.2f", means[["Food secure"]]),
    Mild   = sprintf("%.2f", means[["Mild"]]),
    Moderate = sprintf("%.2f", means[["Moderate"]]),
    Severe = sprintf("%.2f", means[["Severe"]]),
    rho = sprintf("%+.3f", s[["rho"]]), p = fmt_p(s[["p"]]),
    `rho adj.` = sprintf("%+.3f", sa[["rho"]]), `p adj.` = fmt_p(sa[["p"]]),
    `KW p` = fmt_p(kw$p.value),
    check.names = FALSE, stringsAsFactors = FALSE)
}))
ft412 <- mk_ft(t412)
foot412 <- paste0(
  "Spearman rank correlation against the EC-FIES raw score (0-8), n = ", sum(!is.na(ec_raw)),
  " complete cases. Columns 3-6 are group means by EC-FIES severity category. 'rho adj.' is a ",
  "partial Spearman correlation controlling for wealth quintile, computed by rank-transforming ",
  "both variables and the control and correlating the residuals. 'KW p' is a Kruskal-Wallis test ",
  "across the four severity categories. Variables are analysed on their underlying scale rather ",
  "than at the WHO cut-off, because dichotomising discards most of the variance: 33.2% of children ",
  "sit exactly on the minimum-meal-frequency threshold and 41.3% score either side of the minimum ",
  "dietary diversity threshold. Household food groups is the only measure that survives adjustment ",
  "for wealth. Meal frequency is significant crude and null adjusted, so no independent association ",
  "with food insecurity should be claimed for it. The unhealthy-food and sweet-beverage counts ",
  "return significant Kruskal-Wallis tests but are non-monotone, with the mild group as the outlier ",
  "in both, and support no trend. These are unadjusted for clustering within upazila."
)

# ----------------------------------------------------------
# 17. Table 4.13 - household to child pass-through
# ----------------------------------------------------------
# NA-safe: modsev is NA for the 15 children without a complete EC-FIES score,
# so it is re-derived here as a plain logical over the complete cases only.
ms <- !is.na(ec_raw) & ec_raw >= 4

t413 <- do.call(rbind, lapply(seq_len(ncol(E_mat)), function(j) {
  hh <- E_mat[, j]; ch <- child_match[, j]
  ok <- hh & !is.na(ec_raw)
  tb <- table(factor(ch[ok], c(FALSE, TRUE)), factor(ms[ok], c(FALSE, TRUE)))
  # chisq.test errors on an all-zero margin, which happens when a food group is
  # universal among the households that reported it.
  pv <- suppressWarnings(
          if (all(rowSums(tb) > 0) && all(colSums(tb) > 0)) chisq.test(tb)$p.value
          else NA_real_)
  data.frame(
    `Food group` = colnames(E_mat)[j],
    `Households` = sum(hh),
    `Child ate`  = sum(ch),
    `Pass-through` = sprintf("%.1f", 100 * mean(ch[hh])),
    `Secure`     = sprintf("%.1f", 100 * mean(ch[ok & !ms])),
    `Mod/severe` = sprintf("%.1f", 100 * mean(ch[ok &  ms])),
    `p`          = fmt_p(pv),
    check.names = FALSE, stringsAsFactors = FALSE)
}))
ft413 <- mk_ft(t413)
foot413 <- paste0(
  "Pass-through is the percentage of children who consumed a food group among households that ",
  "consumed it, from the household 5-group recall (Module E) and the child 24-hour recall ",
  "(Module F), both asked of the same respondent about the same day. Eggs and flesh foods are one ",
  "household row but two child food groups, so the child side is 'eggs OR flesh foods'. ",
  "Chi-squared test of the child's consumption against moderate-or-severe food insecurity, within ",
  "households consuming the group. Pass-through does not fall as food insecurity worsens for any ",
  "group, which is what dietary buffering predicts. The pulses result is one significant test of ",
  "five and would not survive correction for multiple comparisons; treat it as suggestive. Because ",
  "both recalls come from one respondent in one sitting and the food groups overlap, the ",
  "association between household and child diet is partly method-driven and is not a clean causal ",
  "estimate."
)

# ----------------------------------------------------------
# 18. Figure 4.5 - food group consumption
# ----------------------------------------------------------
fig45_df <- data.frame(group = factor(colnames(FG), levels = colnames(FG)[order(colMeans(FG))]),
                       pct   = 100 * colMeans(FG))
fig45 <- ggplot(fig45_df, aes(group, pct)) +
  geom_col(fill = OK_BLUE, width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), hjust = -0.15, size = 3, colour = OK_GREY) +
  coord_flip(clip = "off") +
  scale_y_continuous(limits = c(0, 105), expand = c(0, 0)) +
  labs(x = NULL, y = "Children consuming the group in the previous day (%)",
       caption = paste0("n = ", nrow(raw), ". The eight food groups of the WHO/UNICEF (2021) ",
                        "minimum dietary diversity indicator.")) +
  theme_thesis

# ----------------------------------------------------------
# 19. Figure 4.6 - household diet falls, child diet does not
#     Both series are plotted as a percentage of the maximum attainable score,
#     because the household scale runs 0-5 and the child scale 0-8.  Plotting
#     the raw means on one axis would make the LEVELS look comparable when they
#     are not; the point of the figure is the two SLOPES.
# ----------------------------------------------------------
ok <- !is.na(ec_cat)
mean_ci <- function(x, g, denom, label) {
  s <- split(x[ok], droplevels(g[ok]))
  do.call(rbind, lapply(names(s), function(k) {
    v <- s[[k]]; m <- mean(v); se <- sd(v) / sqrt(length(v))
    data.frame(cat = k, series = label, raw = m,
               pct = 100 * m / denom,
               lo = 100 * (m - 1.96 * se) / denom,
               hi = 100 * (m + 1.96 * se) / denom,
               stringsAsFactors = FALSE)
  }))
}
fig46_df <- rbind(mean_ci(hhdiv, ec_cat, 5, "Household diet (of 5 groups)"),
                  mean_ci(fgs,   ec_cat, 8, "Child diet (of 8 groups)"))
fig46_df$cat <- factor(fig46_df$cat, levels = levels(ec_cat))

fig46 <- ggplot(fig46_df, aes(cat, pct, colour = series, group = series)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.10, linewidth = 0.4) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.6) +
  geom_text(aes(label = sprintf("%.2f", raw)), vjust = -1.4, size = 3, show.legend = FALSE) +
  scale_colour_manual(values = c("Household diet (of 5 groups)" = OK_AMBER,
                                 "Child diet (of 8 groups)"     = OK_BLUE)) +
  scale_y_continuous(limits = c(30, 80)) +
  labs(x = "EC-FIES severity", y = "Mean score, % of maximum attainable",
       caption = paste0("n = ", sum(ok), ". Point labels are the raw mean scores. Both series are ",
                        "shown as a percentage of the\nmaximum attainable score because the ",
                        "household scale runs 0-5 and the child scale 0-8; this makes the two\n",
                        "slopes comparable, not the two levels. Bars are 95% confidence ",
                        "intervals of the mean, unadjusted for\nclustering. Household diet falls ",
                        "across severity (Spearman p = 0.0005); child diet does not (p = 0.09).")) +
  theme_thesis

# ----------------------------------------------------------
# 20. Export
# ----------------------------------------------------------
small    <- fp_text(font.size = 8, italic = TRUE)
add_foot <- function(d, txt) body_add_fpar(d, fpar(ftext(txt, small)))

doc <- read_docx() %>%
  body_add_par("Table 4.10  Infant and young child feeding indicators, WHO/UNICEF 2021", style = "heading 2") %>%
  body_add_flextable(ft410) %>% add_foot(foot410) %>% body_add_par("") %>%
  body_add_par("Table 4.11  Consumption of the eight minimum-dietary-diversity food groups", style = "heading 2") %>%
  body_add_flextable(ft411) %>% add_foot(foot411) %>% body_add_par("") %>%
  body_add_par("Table 4.12  Diet measures on their underlying scales, by EC-FIES severity", style = "heading 2") %>%
  body_add_flextable(ft412) %>% add_foot(foot412) %>% body_add_par("") %>%
  body_add_par("Table 4.13  Household to child food-group pass-through", style = "heading 2") %>%
  body_add_flextable(ft413) %>% add_foot(foot413)

safe_write(print(doc, target = OUT_DOCX), OUT_DOCX)
safe_write(ggsave(file.path(GRAPH_DIR, "Fig4_5_food_groups.png"), fig45,
                  width = 7.2, height = 4.2, dpi = 300),
           file.path(GRAPH_DIR, "Fig4_5_food_groups.png"))
safe_write(ggsave(file.path(GRAPH_DIR, "Fig4_6_hh_vs_child.png"), fig46,
                  width = 7.2, height = 5.0, dpi = 300),
           file.path(GRAPH_DIR, "Fig4_6_hh_vs_child.png"))
safe_write(saveRDS(dat, OUT_RDS), OUT_RDS)

rule("DONE")
note("Tables  -> ", OUT_DOCX)
note("Figures -> ", GRAPH_DIR, "/Fig4_5_food_groups.png, Fig4_6_hh_vs_child.png")
note("Data    -> ", OUT_RDS, "  (", nrow(dat), " rows, ", ncol(dat), " columns)")
note("Next    -> 05_models.R reads ", OUT_RDS, " for Tables 4.17-4.22.")
safe_write(writeLines(LOG, OUT_LOG), OUT_LOG)
