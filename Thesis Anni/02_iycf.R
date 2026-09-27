# ============================================================
# Anni MS thesis - Infant and young child feeding (IYCF) practice, Bangladesh
# 02_iycf.R  -  WHO indicators, and the IYCF PRACTICE SCORE that is the outcome
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
#   doc/Tables_IYCF.docx     Tables 4.10 - 4.14 and Table 4.16 (bivariate)
#   Graph/Fig4_5_food_groups.png
#   Graph/Fig4_6_score_profile.png
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
#    407 so that every table shares one denominator, and the script also prints
#    the 6-23 month restriction as a sensitivity check.  Nothing moves by more
#    than 0.2 percentage points.  See Table 4.10 footnote.
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
# 8. THE WHO INDICATORS ARE INDEPENDENTLY REPLICATED.  Every indicator figure
#    was computed from Data/MAIN.sav while the analysis plan was written, and
#    section 12 checks the script against those values and stops if any
#    disagree.  If section 12 reports a mismatch, trust neither number until the
#    difference is understood.  The SCORE in section 10 is new and has no such
#    independent derivation; section 12 checks it only for internal consistency
#    and says so.
#
# ------------------------------------------------------------
# THE OUTCOME VARIABLE - decisions 9 to 12
# ------------------------------------------------------------
# 9. EC-FIES HAS BEEN REMOVED.  Earlier drafts carried early childhood food
#    insecurity as the exposure (plan section 3.2, "Direction B") and the
#    thesis now takes IYCF practice as its outcome with EC-FIES out of scope.
#    Nothing is lost analytically: EC-FIES tested null against every diet
#    measure, adjusted and unadjusted (plan sections 4.4, 4.7 and 4.8).  The
#    eight EC-FIES items are still in MAIN.sav if it is ever wanted back.
#    Table 4.5 in 01_tables_chapter4.R is still an EC-FIES table and has NOT
#    been touched - decide separately whether that table stays in Chapter 4.
#
# 10. THE SCORE IS BUILT FROM GRADED COMPONENTS, NOT FROM THE BINARY FLAGS.
#    Summing the ten WHO yes/no indicators was tried first and does not work:
#    Cronbach's alpha is 0.33 and three items correlate NEGATIVELY with the
#    rest.  It also dichotomises seven times over, which decision 5 forbids.
#    The score instead grades five components on their underlying scales -
#    dietary diversity 0-3, meal frequency 0-2, animal-source foods 0-2, fruit
#    and vegetables 0-2, breastfeeding 0-1 - and sums them to 0-10.  This is
#    the structure of the Infant and Child Feeding Index (Ruel & Menon 2002;
#    Arimond & Ruel 2004), rebuilt on WHO's 2021 definitions because that is
#    the instrument this study actually used.  Alpha is 0.682.  Each WHO
#    indicator stays recoverable from its component, so nothing is lost.
#
# 11. BREASTFEEDING IS IN THE SCORE, BUT IT IS THE WEAK COMPONENT.  Its
#    corrected item-total correlation is NEGATIVE (-0.135), and it stays
#    negative inside every one of the four age groups, so this is a real
#    trade-off in the data and not an age artefact: breastfed children here eat
#    a less varied complementary diet.  Dropping it raises alpha from 0.682 to
#    0.752.  It is KEPT because a score for 6-23 month olds that ignores
#    breastfeeding is not an IYCF score, and because ICFI includes it.  The
#    four-component version is carried as `iycf_score_nobf` so the sensitivity
#    analysis is one line in 05_models.R.  Report both alphas in the methods.
#
# 12. THE TWO "AVOID" INDICATORS ARE REPORTED BUT NOT SCORED, AND REVERSING
#    THEM IS EXACTLY WHAT MAKES THINGS WORSE.  Sweet beverages and unhealthy
#    foods are WHO 2021 indicators, so Table 4.10 keeps them.  Folding them in
#    as reversed 0/1 components was tried.  Set SCORE_INCLUDES_AVOID in
#    section 10 to TRUE to rebuild the whole script on that version; the rest
#    of the script follows the flag, so it is a one-line switch.  The numbers
#    that argue against it, all printed in the log every run:
#
#      5 components, neither item scored          alpha 0.682
#      7 components, REVERSED   (1 = avoided)     alpha 0.538
#      7 components, unreversed (1 = consumed)    alpha 0.650
#
#    Read that middle line against the third.  Reversing is the conceptually
#    correct orientation, and it is the orientation that LOWERS alpha; leaving
#    the items as recorded scores better, but would mean the score rewards
#    feeding a child sweet drinks and biscuits, which is not an option.  The
#    gap between 0.538 and 0.650 is the diagnostic: these two items are not
#    badly-signed measures of feeding adequacy, they are well-behaved measures
#    of something else - discretionary and commercial food exposure, which in
#    this setting tracks relative affluence.  Both get negative item-total
#    correlations when reversed, and the 0-12 version blurs the categories:
#    minimum dietary diversity in the moderate band rises from 2.6% to 23.9%.
#    Zero-vegetable-or-fruit is the one avoidance indicator that IS in the
#    score, as the bottom grade of the fruit-and-vegetable component, and it
#    behaves normally there because it measures absence of a good food rather
#    than presence of a bad one.  The better structure, if the thesis wants
#    these two represented, is a SECOND 0-2 score reported alongside - they
#    correlate with the adequacy score at rho +0.186, so they are a second
#    dimension, not the other end of this one.
#
# 13. CUT-POINTS ARE FIXED, NOT QUANTILES.  0-3 severe, 4-5 moderate, 6-7 mild,
#    8-10 adequate.  They follow the scoring logic rather than the sample, and
#    they happen to land almost exactly on the quartiles, so the groups come
#    out near-equal (111 / 116 / 106 / 74) without being DEFINED that way.
#    A quantile cut would shift with the sample and could not be compared to
#    any other study; this one can.  Table 4.14 validates them against the WHO
#    indicators: MDD runs 0.0%, 2.6%, 73.6%, 100.0% across the four categories
#    and MAD runs 0.0%, 0.0%, 48.1%, 90.5%, which is the gradient a severity
#    scale is supposed to produce.
#
# 14. THREE FORMS OF THE OUTCOME, AND WHICH ONE MODELS WHAT.  The analysis
#    file ships all three so 05_models.R does not have to re-derive any of
#    them, and so the thesis can answer the three different questions a
#    reader will ask.
#
#      iycf_cat    4-level ordinal, PRIMARY.  Ordinal logistic uses all 407
#                  children without splitting them into events and
#                  non-events, so it is the best-powered form and the one the
#                  plan pre-specifies.  Test the proportional-odds assumption
#                  and report the test.
#      iycf_score  0-10 continuous.  Linear regression, for the effect size
#                  in score points.
#      iycf_bin    score >= 8, "appropriate IYCF practice".  This is the top
#                  category AND 80% of the maximum, which is the threshold
#                  Sheikh et al. (2026) use, so it is the form that makes the
#                  thesis comparable.  It agrees with their own rule on 86.5%
#                  of children; the residual is because their denominator
#                  varies per child and this one does not.
#      iycf_bin60  score >= 6.  No external precedent, so it is a sensitivity
#                  analysis, not a headline - but it is the only binary with
#                  the events to carry the full covariate list.
#
#    THE BINARY COMES AT A COST, STATED PLAINLY.  Dichotomising at 8 leaves
#    74 events, about 7 predictor degrees of freedom, and the bivariate
#    screen already selects 12 candidates.  Section 14b also finds an empty
#    outcome cell on place of delivery, so a plain glm will fail to converge:
#    use logistf (Firth), per the house convention.  At 6 there are 180
#    events, about 18 degrees of freedom, and no empty cell anywhere.  Do not
#    present the binary as the primary analysis and the ordinal as a
#    footnote; it is the other way round.
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

# Shared table styling. Defined here rather than beside the first table
# because all five tables in this script use it.
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
# 10. THE IYCF PRACTICE SCORE - the outcome variable of the thesis
#     Construction, psychometrics and cut-points.  Read decisions 9-12 in the
#     header before using this.  Five graded components are summed to 0-10 and
#     then cut into four ordered severity categories.
# ----------------------------------------------------------

# --- component 1.  Dietary diversity, 0-3 ---------------------------------
# Graded from the 0-8 food-group score, NOT from the binary MDD flag, per
# decision 5.  WHO's cut-off of 5 falls between grades 1 and 2, so MDD stays
# recoverable from the component.
c_dd <- cut(fgs, c(-Inf, 2, 4, 6, Inf), labels = FALSE) - 1L

# --- component 2.  Meal frequency, 0-2 ------------------------------------
# Graded against EACH CHILD'S OWN WHO minimum (Part 2 C.9), because the minimum
# differs by age and by breastfeeding status.  A child who only just reaches the
# minimum scores 1, one who exceeds it scores 2.  This is where dichotomising
# costs most: a third of the sample sits exactly ON the cut-off (decision 5).
mf_min <- ifelse(bf & age_m <= 8, 2L, 3L)      # breastfed: solid/semi-solid feeds
nb_tot <- milk_mmf + Q8                        # non-breastfed: milk + solid feeds
c_mf <- ifelse(bf,
               ifelse(Q8 <  mf_min, 0L, ifelse(Q8 == mf_min, 1L, 2L)),
               ifelse(!MMF,         0L, ifelse(nb_tot == 4L,  1L, 2L)))

# --- component 3.  Animal-source foods, 0-2 -------------------------------
# 0 is exactly the complement of the EFF indicator, which stays recoverable.
c_asf <- pmin(asf_rows, 2L)

# --- component 4.  Fruit and vegetables, 0-2 ------------------------------
# 0 is exactly the ZVF indicator, which stays recoverable.
c_fv <- pmin(fv_rows, 2L)

# --- component 5.  Breastfeeding, 0-1 -------------------------------------
c_bf <- as.integer(bf)

# --- OPTIONAL components 6 and 7.  The two WHO "avoid" indicators, reversed --
# Set SCORE_INCLUDES_AVOID to TRUE to fold sweet beverages and unhealthy foods
# into the score as reversed 0/1 components, making it 0-12 instead of 0-10.
# Default FALSE.  Reversing is the conceptually correct orientation and it is
# what was tested; it is ALSO what makes the scale worse, because these two
# items genuinely run against the grain of feeding adequacy in this sample.
# Both alphas are printed below every run so the choice stays visible, and
# decision 12 in the header carries the argument.
SCORE_INCLUDES_AVOID <- FALSE
c_noswb <- as.integer(!SwB)      # 1 = did NOT drink a sweet beverage
c_noufc <- as.integer(!UFC)      # 1 = did NOT eat unhealthy food

IYCF_C <- cbind(`Dietary diversity`    = c_dd,
                `Meal frequency`       = c_mf,
                `Animal-source foods`  = c_asf,
                `Fruit and vegetables` = c_fv,
                `Breastfeeding`        = c_bf)
IYCF_C_AVOID <- cbind(IYCF_C, `No sweet beverage` = c_noswb,
                              `No unhealthy food` = c_noufc)
if (SCORE_INCLUDES_AVOID) IYCF_C <- IYCF_C_AVOID
SCORE_MAX  <- if (SCORE_INCLUDES_AVOID) 12L else 10L
iycf_score <- as.integer(rowSums(IYCF_C))                       # 0-SCORE_MAX

# Cut-points.  Chosen on the scoring logic - 8+ means the child meets or beats
# the WHO minimum on essentially every component, 0-3 means failing most of
# them - and they land on the sample quartiles, so the four groups are close to
# equal in size without being DEFINED as quantiles.  Quantile cut-points would
# move with the sample and could not be compared to another study; these cannot.
IYCF_BREAKS <- if (SCORE_INCLUDES_AVOID) c(-Inf, 5, 7, 9, Inf) else c(-Inf, 3, 5, 7, Inf)
IYCF_LABELS <- c("Severe inadequacy", "Moderate inadequacy",
                 "Mild inadequacy", "Adequate")
iycf_cat <- factor(cut(iycf_score, breaks = IYCF_BREAKS, labels = IYCF_LABELS),
                   levels = IYCF_LABELS, ordered = TRUE)

# Sensitivity version with breastfeeding removed (decision 11).  Carried as a
# column so 05_models.R can re-fit on it without re-deriving anything.
iycf_score_nobf <- as.integer(rowSums(IYCF_C[, colnames(IYCF_C) != "Breastfeeding"]))

# --- psychometrics --------------------------------------------------------
cronbach <- function(M)
  ncol(M) / (ncol(M) - 1) * (1 - sum(apply(M, 2, var)) / var(rowSums(M)))
item_total <- function(M) {
  s <- rowSums(M)
  setNames(vapply(seq_len(ncol(M)), function(j) cor(M[, j], s - M[, j]),
                  numeric(1)), colnames(M))
}
alpha_5 <- cronbach(IYCF_C)
alpha_4 <- cronbach(IYCF_C[, colnames(IYCF_C) != "Breastfeeding"])
itot_5  <- item_total(IYCF_C)
# The two orientations of the avoid items, always computed so the comparison is
# in the log whichever way SCORE_INCLUDES_AVOID is set.
alpha_rev <- cronbach(IYCF_C_AVOID)
alpha_raw <- cronbach(cbind(IYCF_C_AVOID[, 1:5],
                            SwB = as.integer(SwB), UFC = as.integer(UFC)))

rule("IYCF PRACTICE SCORE - the outcome")
note("Range ", min(iycf_score), "-", max(iycf_score),
     "   mean ", sprintf("%.2f", mean(iycf_score)),
     "   SD ",   sprintf("%.2f", sd(iycf_score)),
     "   median ", median(iycf_score))
note("Cronbach's alpha, all 5 components : ", sprintf("%.3f", alpha_5))
note("Cronbach's alpha, breastfeeding out: ", sprintf("%.3f", alpha_4))
note("Corrected item-total correlations:")
for (nm in names(itot_5))
  note(sprintf("   %-22s %+.3f%s", nm, itot_5[[nm]],
               if (itot_5[[nm]] < 0) "   <- NEGATIVE, see decision 11" else ""))
note("Category distribution:")
for (l in IYCF_LABELS)
  note(sprintf("   %-22s %3d  (%4.1f%%)", l, sum(iycf_cat == l),
               100 * mean(iycf_cat == l)))

# The three WHO "avoid" indicators are deliberately NOT in the score.
# Decision 12: they correlate POSITIVELY with it, so reverse-scoring them into
# an adequacy scale would penalise the better-fed children.  Quantified here so
# the claim is checkable rather than asserted.
# Denominator sensitivity.  Materials/IYCF_Methodology.docx reports N = 405, which
# is 407 minus the two children outside WHO's 6-23 month window.  Every table in
# this script is built on 407 (decision 3).  The difference is quantified here so
# the student and supervisor can settle which denominator the thesis reports, and
# so nobody has to take on trust that it does not matter.
note("Denominator sensitivity - the methodology document reports N = 405:")
note(sprintf("   all %d children : mean %.3f, SD %.3f, adequate %d (%.1f%%)",
             nrow(raw), mean(iycf_score), sd(iycf_score),
             sum(iycf_cat == "Adequate"), 100 * mean(iycf_cat == "Adequate")))
note(sprintf("   6-23 mo (n=%d): mean %.3f, SD %.3f, adequate %d (%.1f%%)",
             sum(elig), mean(iycf_score[elig]), sd(iycf_score[elig]),
             sum(iycf_cat[elig] == "Adequate"), 100 * mean(iycf_cat[elig] == "Adequate")))
note("   The two excluded children are aged 5 and 24 months.")

note("Sweet beverages and unhealthy foods - both orientations (decision 12):")
note(sprintf("   reversed, 1 = avoided (correct orientation) : alpha %.3f", alpha_rev))
note(sprintf("   as recorded, 1 = consumed                   : alpha %.3f", alpha_raw))
note(sprintf("   neither in the score, 5 components          : alpha %.3f", cronbach(IYCF_C_AVOID[, 1:5])))
note("   Reversing is the right orientation and is what lowers alpha. Leaving")
note("   them unreversed scores higher, but would reward feeding a child junk")
note("   food, so it is not an option. That gap is the diagnostic: these two")
note("   items measure discretionary-food exposure, not feeding adequacy.")
note("Correlation of each with the score, as recorded:")
for (v in list(list("Sweet beverage (SwB)", SwB), list("Unhealthy food (UFC)", UFC)))
  note(sprintf("   %-22s r = %+.3f", v[[1]], cor(as.numeric(v[[2]]), iycf_score)))

# ----------------------------------------------------------
# 10b. THE SHEIKH-STYLE INDEX - the supervisor's own published method
#      Sheikh Z, Hossain MS, Ali M, Hassan R, Alam MM, Amin MR (2026).
#      "Infant and young child feeding in rural Bangladesh: insights into
#      knowledge, practices, and associated factors."  J Nutr Sci 15: e50.
#      Materials/Infant and young child feeding in rural Bangladesh ... .pdf,
#      section "Assessment of IYCF knowledge and practices".
#
#      Method, as published: one point per CORRECT practice across the
#      WHO/UNICEF indicators, cumulative score, expressed as a percentage,
#      then cut at >80% = "appropriate practice".  The three negative
#      indicators count as correct when the child did NOT do them, which is
#      the reversal the score in section 10 declines to make.
#
#      Built here for two reasons.  It is the supervisor's own method, so the
#      thesis needs to be able to report it and be compared against the BIHS
#      paper.  And the one genuinely good idea in it - a per-child denominator
#      of APPLICABLE indicators - is the clean solution to the problem that
#      kept ISSSF and MMFF out of the section 10 score.
#
#      THREE DEFECTS, all checkable in the log below.  Read them before
#      making this the primary outcome.
#      (a) MAD is in the indicator list AND is MDD & MMF & (BF | MMFF), which
#          are also in the list.  It is an arithmetic function of its own
#          scale-mates, so it inflates alpha by double-counting: 0.569 with
#          MAD in, 0.372 with it out.  The published paper reports no alpha.
#      (b) The paper says the score is "out of 15" and reports a mean of
#          6.3 +/- 2.2, yet classifies 30.3% as scoring >80%.  Eighty percent
#          of 15 is >12, which is 2.6 SD above their own mean; those three
#          numbers cannot all be right on a fixed denominator of 15.  They are
#          consistent if the denominator is per-child applicable indicators,
#          which is how it is implemented here.  WORTH ASKING THE SUPERVISOR
#          DIRECTLY - it changes the headline prevalence.
#      (c) The reversed negative indicators still carry negative corrected
#          item-total correlations here, exactly as in decision 12.  The
#          supervisor's method does not make that problem go away; it just
#          does not look for it.
# ----------------------------------------------------------
SH_OK <- cbind(
  MDD = as.integer(MDD), MMF = as.integer(MMF), MAD = as.integer(MAD),
  EFF = as.integer(EFF),
  `No sweet beverage` = as.integer(!SwB),
  `No unhealthy food` = as.integer(!UFC),
  `Any fruit or veg`  = as.integer(!ZVF),
  CBF = as.integer(CBF), ISSSF = as.integer(ISSSF), MMFF = as.integer(MMFF))

# Which indicators APPLY to each child.  This is the part worth borrowing:
# CBF, ISSSF and MMFF have restricted denominators, so they enter the
# numerator and the denominator together, and a child is never penalised for
# an indicator that could not apply to them.
SH_APP <- cbind(
  MDD = 1L, MMF = 1L, MAD = 1L, EFF = 1L,
  `No sweet beverage` = 1L, `No unhealthy food` = 1L, `Any fruit or veg` = 1L,
  CBF   = as.integer(w_cbf),
  ISSSF = as.integer(w_iss),
  MMFF  = as.integer(!bf))
SH_APP <- SH_APP[rep(1, nrow(raw)), ]          # recycle the constant columns
SH_APP[, "CBF"]   <- as.integer(w_cbf)
SH_APP[, "ISSSF"] <- as.integer(w_iss)
SH_APP[, "MMFF"]  <- as.integer(!bf)
SH_OK[SH_APP == 0] <- 0L

sh_raw <- as.integer(rowSums(SH_OK))           # correct practices
sh_den <- as.integer(rowSums(SH_APP))          # applicable indicators
sh_pct <- 100 * sh_raw / sh_den

# The paper's own binary cut.
sh_appropriate <- as.integer(sh_pct > 80)
# The paper's three-level scheme, which it applies to KNOWLEDGE not practice.
sh_cat3 <- factor(cut(sh_pct, c(-Inf, 50, 80, Inf),
                      labels = c("Poor", "Fair", "Good")),
                  levels = c("Poor", "Fair", "Good"), ordered = TRUE)
# A four-level version on the same percentage scale, for comparability with
# iycf_cat.  Cut at 40/60/80 because that keeps the four groups usable and
# keeps the paper's own 80% boundary as the top cut.
sh_cat4 <- factor(cut(sh_pct, c(-Inf, 40, 60, 80, Inf),
                      labels = IYCF_LABELS), levels = IYCF_LABELS, ordered = TRUE)

rule("SHEIKH-STYLE INDEX (the supervisor's published method)")
note("Applicable indicators per child: ",
     paste(sprintf("%d -> %d children", as.integer(names(table(sh_den))),
                   as.integer(table(sh_den))), collapse = ";  "))
note(sprintf("Correct practices: mean %.2f  SD %.2f", mean(sh_raw), sd(sh_raw)))
note(sprintf("Percentage of applicable: mean %.1f%%  SD %.1f  median %.1f",
             mean(sh_pct), sd(sh_pct), median(sh_pct)))
note(sprintf("Paper's cut, >80%% = appropriate practice: %d of %d (%.1f%%)",
             sum(sh_appropriate), nrow(raw), 100 * mean(sh_appropriate)))
note("   The BIHS paper reports 30.3% appropriate on its own 0-23 month sample.")
note("Three-level scheme: ",
     paste(sprintf("%s %d", levels(sh_cat3), as.integer(table(sh_cat3))), collapse = ";  "))

# Defect (a), quantified rather than asserted.
sh_core <- SH_OK[, c("MDD", "MMF", "MAD", "EFF", "No sweet beverage",
                     "No unhealthy food", "Any fruit or veg")]
note(sprintf("Alpha on the 7 universally-applicable items : %.3f", cronbach(sh_core)))
note(sprintf("   same, with MAD removed                   : %.3f  <- defect (a)",
             cronbach(sh_core[, colnames(sh_core) != "MAD"])))
note("   MAD = MDD & MMF & (BF | MMFF), so it is an arithmetic function of its")
note("   own scale-mates. Its item-total correlation is the highest in the set")
note("   for that reason alone. Do not read 0.569 as evidence the scale coheres.")
sh_it <- item_total(sh_core)
note("Corrected item-total correlations:")
for (nm in names(sh_it))
  note(sprintf("   %-20s %+.3f%s", nm, sh_it[[nm]],
               if (sh_it[[nm]] < 0) "   <- NEGATIVE, defect (c)" else ""))
note(sprintf("Agreement with the section 10 graded score: Spearman rho = %.3f",
             cor(sh_pct, iycf_score, method = "spearman")))
note(sprintf("   but only %.1f%% of children land in the same one of four categories",
             100 * mean(sh_cat4 == iycf_cat)))

# --- binary forms of the outcome, for model building ----------------------
# Decision 14 in the header.  Two cuts, because no single one is right for
# both jobs the thesis needs a binary to do.
#
# iycf_bin   - "appropriate IYCF practice", score >= 8 of 10.  This is the TOP
#              CATEGORY of iycf_cat and it is also 80% of the maximum, which
#              is the threshold Sheikh et al. (2026) use.  So it is the cut
#              that makes the thesis comparable, and it is the one to report.
#              It is thin: 74 events, which supports about 7 predictor degrees
#              of freedom at the usual 10-events-per-variable rule, and the
#              bivariate screen already finds 12 candidates.  EXPECT
#              SEPARATION - the check in section 14b finds a zero cell on
#              place of delivery - and fit it with logistf (Firth), not glm.
#
# iycf_bin60 - score >= 6 of 10, the mild-or-better split.  180 events, about
#              18 predictor degrees of freedom, and no zero cell anywhere in
#              the candidate set.  This is the cut to use when the adjusted
#              model needs to carry the full covariate list.  It has no
#              external precedent, so report it as a sensitivity analysis
#              rather than as the headline prevalence.
#
# Neither replaces the ordinal model.  iycf_cat uses all 407 children without
# splitting them into events and non-events, so it is still the primary form
# (plan section 3.2) and the binaries are for comparability and for readers
# who expect an odds ratio.
IYCF_BIN_CUT <- 8L
iycf_bin     <- as.integer(iycf_score >= IYCF_BIN_CUT)
iycf_bin60   <- as.integer(iycf_score >= 6L)

note("Binary forms for model building (decision 14):")
for (k in c(8L, 7L, 6L, 5L)) {
  y <- as.integer(iycf_score >= k); lim <- min(sum(y), sum(1 - y))
  note(sprintf("   score >= %2d (%3.0f%% of max) : %3d yes / %3d no   limiting cell %3d -> ~%2d predictor df%s",
               k, 100 * k / SCORE_MAX, sum(y), sum(1 - y), lim, lim %/% 10,
               if (k == IYCF_BIN_CUT) "   <- iycf_bin, PRIMARY"
               else if (k == 6L)      "   <- iycf_bin60, well-powered"
               else ""))
}
note(sprintf("   Sheikh's own >80%% of applicable rule : %3d yes / %3d no  (agrees with",
             sum(sh_appropriate), nrow(raw) - sum(sh_appropriate)))
note(sprintf("   iycf_bin on %.1f%% of children - the denominators differ per child)",
             100 * mean(iycf_bin == sh_appropriate)))

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

# --- construction invariants for the score --------------------------------
# These are NOT an independent replication - the score is new to this script
# and there is no hand-computed comparator (decision 8).  They check that the
# score is internally consistent and that the categories behave like a severity
# scale, which is what would break first if a component were mis-specified.
note("")
note("Score construction invariants (not an independent replication):")
inv <- list(
  list("score = sum of parts",  all(iycf_score == rowSums(IYCF_C)),            TRUE),
  list("score in range",        all(iycf_score >= 0 & iycf_score <= SCORE_MAX), TRUE),
  list("no missing score",      !anyNA(iycf_score),                            TRUE),
  list("no missing category",   !anyNA(iycf_cat),                              TRUE),
  list("categories sum to N",   sum(table(iycf_cat)) == nrow(raw),             TRUE),
  list("all 4 categories used", all(table(iycf_cat) > 0),                      TRUE),
  # MDD, MAD and EFF must rise monotonically across the categories, and ZVF
  # must fall.  If any of these breaks, a component is scored backwards.
  list("MDD rises",  !is.unsorted(tapply(as.numeric(MDD), iycf_cat, mean)),    TRUE),
  list("MAD rises",  !is.unsorted(tapply(as.numeric(MAD), iycf_cat, mean)),    TRUE),
  list("EFF rises",  !is.unsorted(tapply(as.numeric(EFF), iycf_cat, mean)),    TRUE),
  list("ZVF falls",  !is.unsorted(rev(tapply(as.numeric(ZVF), iycf_cat, mean))), TRUE),
  list("top cat is best",       unname(which.max(tapply(iycf_score, iycf_cat, mean))) == 4L, TRUE)
)
for (e in inv) {
  ok <- isTRUE(all.equal(e[[2]], e[[3]]))
  if (!ok) bad <- bad + 1
  note(sprintf("  %-22s %-5s   %s", e[[1]], e[[2]],
               if (ok) "ok" else "*** FAILED ***"))
}
if (bad > 0)
  warning("Score construction invariant failed - a component is mis-specified.",
          call. = FALSE, immediate. = TRUE)
# Separation quality, reported not asserted.  How cleanly does the bottom
# category exclude children who reached the WHO thresholds?  This is the number
# that degrades if the avoid indicators are folded in, so it is printed either
# way rather than hidden behind a pass/fail.
note(sprintf("  %-22s %d child(ren) reaching MDD sit in the bottom category",
             "separation quality", sum(MDD[iycf_cat == "Severe inadequacy"])))
note(sprintf("  %-22s %d child(ren) reaching MAD sit in the bottom category",
             "", sum(MAD[iycf_cat == "Severe inadequacy"])))

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
  # ---- THE OUTCOME (section 10) ----
  # iycf_score is the primary outcome, 0-10, and iycf_cat is the ordered
  # four-level form for the ordinal model.  The five components ship with them
  # so 05_models.R can re-fit on any single one without re-deriving it.
  iycf_score = iycf_score,
  iycf_cat   = iycf_cat,
  iycf_nobf  = iycf_score_nobf,          # sensitivity, decision 11
  # binary forms for model building, decision 14
  iycf_bin   = iycf_bin,                 # score >= 8, "appropriate practice"
  iycf_bin60 = iycf_bin60,               # score >= 6, well-powered alternative
  # Sheikh et al. 2026 index (section 10b) - the supervisor's published method,
  # carried so 05_models.R can report both and so the thesis is comparable to
  # the BIHS paper.  Read the three defects in 10b before making it primary.
  sh_raw = sh_raw, sh_den = sh_den, sh_pct = sh_pct,
  sh_appropriate = sh_appropriate, sh_cat3 = sh_cat3, sh_cat4 = sh_cat4,
  c_dd = c_dd, c_mf = c_mf, c_asf = c_asf, c_fv = c_fv, c_bf = c_bf,
  # data-quality flag, so 05_models.R can run a sensitivity analysis
  flag_meal_contradiction = as.integer(bad_hi | bad_lo)
)

# ----------------------------------------------------------
# 14. Candidate independent variables
#      Built here rather than in 05_models.R so that Table 4.16 and the models
#      use one definition of every covariate.  Collapsing decisions are stated
#      inline and repeated in the Table 4.16 footnote, because several are
#      judgement calls the supervisor may want to change.
# ----------------------------------------------------------
lv <- function(x, levels, labels = levels)
  factor(as.character(haven::as_factor(x)), levels = levels, labels = labels)

EDU5 <- c("No formal education", "Primary", "Secondary", "Higher Secondary",
          "Higher Study (tertiary education)")
EDU5L <- c("No formal education", "Primary", "Secondary", "Higher secondary",
           "Higher education")

# Birth weight carries two problems at once: 7 forms were filled in kilograms
# and the rest in grams, and 98 = "don't know" was left in the numeric field.
# Same repair as 01_tables_chapter4.R.  "Don't know" is kept as its own level
# rather than dropped, because 21.6% of the sample would otherwise vanish.
bw_raw <- as.numeric(raw$D8_birth_weight_kg)
bw_g   <- ifelse(bw_raw == 98, NA_real_, ifelse(bw_raw < 10, bw_raw * 1000, bw_raw))
anc_n  <- ifelse(as.numeric(raw$B15_ANC) == 98, NA_real_, as.numeric(raw$B15_ANC))

cov <- tibble(
  `Child age group`      = cut(age_m, c(-Inf, 8, 11, 17, Inf),
                               labels = c("6-8 months", "9-11 months",
                                          "12-17 months", "18-23 months")),
  `Child sex`            = lv(raw$D5_sex_of_the_child, c("Male", "Female")),
  `Birth order`          = lv(raw$D6_birth_order, c("First", "Second", "Third", "Above"),
                              c("First", "Second", "Third", "Fourth or higher")),
  `Birth weight`         = factor(ifelse(is.na(bw_g), "Don't know",
                                  ifelse(bw_g < 2500, "<2.5 kg", "2.5 kg or more")),
                                  levels = c("<2.5 kg", "2.5 kg or more", "Don't know")),
  `Currently breastfed`  = factor(ifelse(bf, "Yes", "No"), levels = c("No", "Yes")),
  # Child illness is the single strongest known confounder of a 24-hour
  # dietary recall and the score is built entirely on that recall, so it has
  # to be screened here.  Recruitment happened at health congregation sites,
  # so sick children are over-sampled BY DESIGN - this is a sampling feature,
  # not a finding about illness.  5 children have no answer and are excluded
  # from this row only.
  `Child sick at interview` = lv(raw$Is_Child_Sick, c("Yes", "No")),
  `Mother's age (years)`  = as.numeric(raw$B8_age_mother),
  `Mother's education`   = lv(raw$B11_edu_mother, EDU5, EDU5L),
  # 385 of 407 mothers are housewives, so the seven recorded categories collapse
  # to a single employed/not contrast; anything finer is empty cells.
  `Mother's occupation`  = factor(ifelse(as.character(haven::as_factor(raw$B12_occupation_mother)) ==
                                         "Housewife", "Housewife", "Employed / other"),
                                  levels = c("Housewife", "Employed / other")),
  `Age at marriage`      = factor(ifelse(as.numeric(raw$B9_age_at_marriage) < 18,
                                         "<18 years", "18 years or more"),
                                  levels = c("<18 years", "18 years or more")),
  `Number of children`   = cut(as.numeric(raw$B7_How_many_children), c(-Inf, 1, 2, Inf),
                               labels = c("1", "2", "3 or more")),
  `Father's age (years)`  = as.numeric(raw$B3_age_father),
  `Father's education`   = lv(raw$B5_education_child_father, EDU5, EDU5L),
  # Labels matter here: the draft called the 224 salaried/business/other group
  # "Business", which it mostly is not. See section 2.4 of the analysis plan.
  `Father's occupation`  = factor(dplyr::case_when(
      as.character(haven::as_factor(raw$B4_occupation_father)) %in%
        c("Agriculture", "Wage-Labor")                        ~ "Agriculture / day labour",
      as.character(haven::as_factor(raw$B4_occupation_father)) %in%
        c("Business", "Job-holder", "Others")                 ~ "Business / service / other",
      as.character(haven::as_factor(raw$B4_occupation_father)) == "Remittance erner" ~ "Remittance",
      TRUE                                                    ~ "Not working"),
      levels = c("Agriculture / day labour", "Business / service / other",
                 "Remittance", "Not working")),
  `Family type`          = lv(raw$B2_type_of_your_family, c("Nuclear", "Joint")),
  `Household size`       = cut(as.numeric(raw$B6_members_household), c(-Inf, 4, 6, Inf),
                               labels = c("4 or fewer", "5-6", "7 or more")),
  `Religion`             = lv(raw$B13_religion, c("Muslim", "Hindu")),
  `Wealth quintile`      = lv(raw$Ncombsco, c("Lowest", "Second", "Middle", "Fourth", "Highest"),
                              c("Poorest", "Poorer", "Middle", "Richer", "Richest")),
  `Residence`            = lv(raw$A2_3_Residence, c("Urban", "Rural")),
  `Division`             = haven::as_factor(raw$DIVISION),
  # WHO's own threshold for adequate antenatal care is four or more visits.
  `ANC visits`           = factor(ifelse(is.na(anc_n), NA_character_,
                                  ifelse(anc_n == 0, "None",
                                  ifelse(anc_n < 4, "1-3", "4 or more"))),
                                  levels = c("None", "1-3", "4 or more")),
  `Place of delivery`    = factor(dplyr::case_when(
      as.character(haven::as_factor(raw$B14_child_was_delivered)) %in%
        c("Your Home", "Natal House")                                  ~ "Home",
      as.character(haven::as_factor(raw$B14_child_was_delivered)) %in%
        c("Government hospital", "Upazilla Health Complex")            ~ "Government facility",
      as.character(haven::as_factor(raw$B14_child_was_delivered)) %in%
        c("Private hospital", "Clinic")                                ~ "Private facility",
      TRUE                                                             ~ "Other"),
      levels = c("Home", "Government facility", "Private facility", "Other")),
  `Mode of delivery`     = lv(raw$B16_How_child_delivered, c("Normal", "Cesarean")),
  `Birth attendant`      = lv(raw$B17_helped_during_delivery,
                              c("Health professionals/Trained birth attendant", "Midwife", "Others"),
                              c("Health professional / trained attendant", "Midwife", "Other")),
  `Postnatal care visit` = lv(raw$B18_PNC, c("No", "Yes")),
  `Nutrition counselling` = lv(raw$B21_nutrition_counselling, c("No", "Yes")),
  # Collapsed from six categories; father-in-law, mother-in-law and "someone
  # else" total 21 and cannot stand alone.
  `Child health decisions` = factor(dplyr::case_when(
      as.character(haven::as_factor(raw$B20_decision_making)) == "Wife" ~ "Mother alone",
      as.character(haven::as_factor(raw$B20_decision_making)) == "Both" ~ "Mother and husband jointly",
      TRUE                                                             ~ "Husband or other relative"),
      levels = c("Mother alone", "Mother and husband jointly", "Husband or other relative")),
  # B19_Media_access5 is the "No access" tick-box, so it inverts.
  `Any media access`     = factor(ifelse(as.numeric(raw$B19_Media_access5) == 1, "No", "Yes"),
                                  levels = c("No", "Yes")),
  # JMP classification. Code 113 is a "Skip" sentinel, not a facility type.
  `Improved sanitation`  = factor(ifelse(as.numeric(raw$C2_toilet_facility) == 113, NA_character_,
                                  ifelse(as.numeric(raw$C2_toilet_facility) %in% c(11, 12, 13, 21, 22),
                                         "Improved", "Unimproved")),
                                  levels = c("Unimproved", "Improved")),
  `Clean cooking fuel`   = factor(ifelse(as.numeric(raw$C3_fuel_for_cooking) %in% 1:4,
                                         "Clean", "Solid / polluting"),
                                  levels = c("Solid / polluting", "Clean")),
  `Shared toilet`        = lv(raw$C11_share_toilet, c("Yes", "No")),
  `Separate kitchen`     = lv(raw$C13_kitchen, c("No", "Yes")),
  `Household bank account` = lv(raw$C7_bank_account, c("No", "Yes")),
  `Household food groups (0-5)` = as.numeric(hhdiv)
)
# Drinking water and ethnicity are deliberately NOT candidates: 405 of 407
# households use an improved source and 405 of 407 respondents are Bengali.
# Neither has the variance to support a test; both are noted in the footnote.

# ----------------------------------------------------------
# 14b. Separation screen for the binary outcomes
#      Run here, not in 05_models.R, because the answer determines which
#      modelling function that script has to use.  A categorical predictor
#      with an empty outcome cell pushes its coefficient towards infinity.
#      NOTE THE TRAP: on this data glm reports converged = TRUE and prints a
#      coefficient of 13.1, an odds ratio near 500,000, with no warning at
#      all.  It is quasi-separation, and it is silent.  Checking convergence
#      is NOT enough; the screen below is what catches it.  Fit the flagged
#      variables with logistf (Firth), per the house convention.
# ----------------------------------------------------------
rule("SEPARATION SCREEN for the binary outcomes")
sep_screen <- function(y, lab) {
  note("Outcome: ", lab, "  (", sum(y), " events / ", sum(1 - y), " non-events)")
  hits <- character(0)
  for (nm in names(cov)) {
    x <- cov[[nm]]
    if (!is.factor(x)) next
    k <- !is.na(x); f <- droplevels(x[k]); tb <- table(f, y[k])
    if (ncol(tb) < 2 || nrow(tb) < 2) next
    z <- rownames(tb)[tb[, 1] == 0 | tb[, 2] == 0]
    if (length(z)) {
      hits <- c(hits, nm)
      note(sprintf("   %-28s empty outcome cell at: %s  (n = %s)",
                   nm, paste(z, collapse = "; "),
                   paste(rowSums(tb)[z], collapse = "; ")))
    }
  }
  if (!length(hits)) note("   No empty outcome cell in any categorical candidate.")
  else {
    note("   -> fit these with logistf (Firth), or collapse the sparse level first.")
    note("   -> glm will NOT warn you: it reports converged = TRUE and returns a")
    note("      coefficient near 13 (odds ratio ~500,000). Do not trust it.")
  }
  invisible(hits)
}
sep_bin   <- sep_screen(iycf_bin,   "iycf_bin, score >= 8")
sep_bin60 <- sep_screen(iycf_bin60, "iycf_bin60, score >= 6")

# The events-per-variable budget against what the bivariate screen actually
# selects.  This is the number that decides whether the primary binary can
# carry a full adjusted model or needs a reduced one.
note("Budget check:")
note(sprintf("   iycf_bin   supports ~%d predictor df; iycf_bin60 supports ~%d.",
             sum(iycf_bin) %/% 10, min(sum(iycf_bin60), sum(1 - iycf_bin60)) %/% 10))
note("   The bivariate screen selects more candidates than iycf_bin can carry,")
note("   so the adjusted binary model on iycf_bin must either drop predictors,")
note("   use iycf_bin60, or defer to the ordinal model on iycf_cat, which uses")
note("   all ", nrow(raw), " children without splitting them into events.")

# ----------------------------------------------------------
# 15. Table 4.16 - bivariate: the IYCF practice score vs every candidate
#     independent variable.
#     The outcome is shown BOTH ways, per section 3.7 of the analysis plan:
#     the 0-10 score, because that is what the test is run on, and the
#     percentage in the top category, because that is what a reader looks for.
#     The score column carries the primary p-value; the category p-value is
#     secondary and is printed so the cost of collapsing is visible.
# ----------------------------------------------------------
# Fisher's exact rather than chi-squared whenever a 2x2 has an expected count
# below 5 - religion (19 Hindu), improved sanitation (21 unimproved) and mode
# of delivery all sail close to that line.
p_binary <- function(f, y) {
  tb <- table(f, y)
  if (any(dim(tb) < 2)) return(NA_real_)
  ex <- suppressWarnings(chisq.test(tb)$expected)
  if (any(ex < 5) && all(dim(tb) == c(2, 2))) fisher.test(tb)$p.value
  else suppressWarnings(chisq.test(tb)$p.value)
}

biv_rows <- function(label, x, score, mdd) {
  if (is.numeric(x)) {
    ok <- !is.na(x)
    ct <- suppressWarnings(cor.test(x[ok], score[ok], method = "spearman", exact = FALSE))
    wt <- suppressWarnings(wilcox.test(x[ok & mdd], x[ok & !mdd]))
    return(data.frame(
      Variable = label, n = sum(ok),
      `Adequate n (%)` = sprintf("median %.0f vs %.0f", median(x[ok & mdd]), median(x[ok & !mdd])),
      `IYCF score, mean (SD)` = sprintf("rho = %+.3f", unname(ct$estimate)),
      `p (score)` = fmt_p(ct$p.value), `p (category)` = fmt_p(wt$p.value),
      check.names = FALSE, stringsAsFactors = FALSE))
  }
  f  <- droplevels(x)
  ok <- !is.na(f)
  pk <- kruskal.test(score[ok], f[ok])$p.value
  pb <- p_binary(f[ok], mdd[ok])
  head <- data.frame(Variable = label, n = sum(ok), `Adequate n (%)` = "",
                     `IYCF score, mean (SD)` = "", `p (score)` = fmt_p(pk),
                     `p (category)` = fmt_p(pb), check.names = FALSE, stringsAsFactors = FALSE)
  body <- do.call(rbind, lapply(levels(f), function(l) {
    m <- ok & f == l
    data.frame(Variable = paste0("    ", l), n = sum(m),
               `Adequate n (%)` = sprintf("%d (%.1f)", sum(mdd[m]), 100 * mean(mdd[m])),
               `IYCF score, mean (SD)` = sprintf("%.2f (%.2f)", mean(score[m]), sd(score[m])),
               `p (score)` = "", `p (category)` = "",
               check.names = FALSE, stringsAsFactors = FALSE)
  }))
  rbind(head, body)
}

adequate <- iycf_cat == "Adequate"
t416 <- do.call(rbind, lapply(names(cov), function(nm)
  biv_rows(nm, cov[[nm]], iycf_score, adequate)))

# Ship the covariates alongside the model frame.  The snake_case columns built
# in section 13 are what the models use; these display-named columns are what
# Table 4.16 uses, and carrying both means 05_models.R can reproduce any row of
# the bivariate table without re-deriving a collapse.
dat <- dplyr::bind_cols(dat, cov)

ft416 <- mk_ft(t416) %>%
  bold(i = which(!startsWith(t416$Variable, "    ")), j = 1) %>%
  align(j = 1, align = "left", part = "all")
# Bold the variables that reach 0.05 on the primary (score) test, so the table
# can be read at a glance without hunting through 127 rows.
sig <- which(t416$`p (score)` != "" &
             (t416$`p (score)` == "<0.001" |
              suppressWarnings(as.numeric(t416$`p (score)`)) < 0.05))
if (length(sig)) ft416 <- bold(ft416, i = sig, j = 5)

n_sig <- length(sig)

# Second self-check block. These three cannot go in section 12 because the
# bivariate table does not exist yet at that point in the script.
# Structural checks only.  The count of significant variables is NOT checked
# against a pre-computed value: the outcome changed when the score replaced the
# food-group score (decision 9), so there is no comparator.  It is printed.
for (e in list(list("Candidate variables", length(cov), 34L),
               list("Table 4.16 rows",     nrow(t416),  125L))) {
  ok2 <- isTRUE(all.equal(e[[2]], e[[3]]))
  note(sprintf("  %-22s computed %5s   expected %5s   %s",
               e[[1]], e[[2]], e[[3]], if (ok2) "ok" else "*** MISMATCH ***"))
  if (!ok2) warning("Table 4.16 self-check mismatch on ", e[[1]], call. = FALSE,
                    immediate. = TRUE)
}
note(sprintf("  %-22s computed %5s   (no comparator - new outcome)",
             "Sig. on score p<0.05", n_sig))
foot416 <- paste0(
  "Outcome is the IYCF practice score (section 10 of the script; 0-10, five graded components), ",
  "shown two ways. 'IYCF score, mean (SD)' is the score itself; 'Adequate n (%)' is the count and ",
  "percentage in the top category of the four-level severity variable, a score of 8 or more. The ",
  "PRIMARY test is 'p (score)': a Kruskal-Wallis test of the score across the levels of each ",
  "variable, or a Spearman correlation for the three continuous variables, where the estimate ",
  "column shows rho and the Adequate column shows medians. 'p (category)' is a secondary ",
  "chi-squared test on adequate-versus-not, or Fisher's exact test where a two-by-two table has an ",
  "expected count below five; it is printed so the cost of collapsing a four-level outcome to a ",
  "binary one is visible, and it is not the basis for any conclusion. Bold marks p < 0.05 on the ",
  "primary test (", n_sig, " variables). Denominators vary: antenatal care visits exclude one ",
  "'don't know', sanitation excludes four skip codes, and child illness excludes five children with ",
  "no answer. Children sick at interview are over-sampled BY DESIGN, because recruitment happened at ",
  "health congregation sites, so the illness row describes the sampling frame and is not evidence that ",
  "illness causes poor feeding. Birth weight was recorded in mixed units ",
  "and is repaired here (7 forms in kilograms multiplied by 1000); the 88 'don't know' responses ",
  "are kept as their own level rather than dropped. Father's occupation collapses seven recorded ",
  "categories into four, and the 224 counted as 'business / service / other' are mostly salaried ",
  "employees, not traders. Child health decisions collapses six categories into three. Drinking ",
  "water source and ethnicity are excluded as candidates: 405 of 407 households use an improved ",
  "water source and 405 of 407 respondents are Bengali, so neither has the variance to support a ",
  "test. No adjustment is made for multiple comparisons and none of these tests is adjusted for ",
  "clustering within the 25 upazila recruitment sites, so a variable reaching 0.05 here is a ",
  "candidate for the multivariable model, not a finding."
)

# ----------------------------------------------------------
# 16. Table 4.10 - the ten indicators
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
# 17. Table 4.11 - the eight food groups
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
# 18. Table 4.12 - how the IYCF practice score is built
#     Every component, what each grade means, how the sample distributes across
#     the grades, and the corrected item-total correlation.  A reader has to be
#     able to rebuild the score from this table alone.
# ----------------------------------------------------------
comp_max  <- c(3L, 2L, 2L, 2L, 1L, 1L, 1L)[seq_len(ncol(IYCF_C))]
comp_rule <- c(
  "0-2 food groups / 3-4 / 5-6 / 7-8, so the WHO cut-off of 5 sits between grades 1 and 2",
  "below the child's own WHO minimum / exactly at it / above it",
  "no rows / 1 row / 2 or more of the 9 animal-source rows",
  "no rows, which is exactly ZVF / 1 row / 2 or more of the 5 fruit-and-vegetable rows",
  "not breastfed yesterday / breastfed yesterday")

t412 <- do.call(rbind, lapply(seq_len(ncol(IYCF_C)), function(j) {
  x <- IYCF_C[, j]
  g <- vapply(0:3, function(k)
         if (k > comp_max[j]) "-" else
           sprintf("%d (%.1f)", sum(x == k), 100 * mean(x == k)), character(1))
  data.frame(Component = colnames(IYCF_C)[j],
             Scored    = sprintf("0-%d", comp_max[j]),
             `Grade 0` = g[1], `Grade 1` = g[2], `Grade 2` = g[3], `Grade 3` = g[4],
             `Mean (SD)`    = sprintf("%.2f (%.2f)", mean(x), sd(x)),
             `Item-total r` = sprintf("%+.3f", itot_5[[j]]),
             check.names = FALSE, stringsAsFactors = FALSE)
}))
t412 <- rbind(t412, data.frame(
  Component = "IYCF PRACTICE SCORE", Scored = sprintf("0-%d", SCORE_MAX),
  `Grade 0` = "", `Grade 1` = "", `Grade 2` = "", `Grade 3` = "",
  `Mean (SD)`    = sprintf("%.2f (%.2f)", mean(iycf_score), sd(iycf_score)),
  `Item-total r` = sprintf("alpha %.3f", alpha_5),
  check.names = FALSE, stringsAsFactors = FALSE))

ft412 <- mk_ft(t412) %>%
  bold(i = nrow(t412)) %>%
  align(j = 1, align = "left", part = "all")

foot412 <- paste0(
  "The five components of the IYCF practice score, n = ", nrow(raw), " for every row. Cells are ",
  "n (%) of children at each grade; a dash marks a grade the component does not have. Grades are ",
  "assigned as follows. Dietary diversity: ", comp_rule[1], ". Meal frequency: ", comp_rule[2],
  ", where that minimum is two solid feeds for a breastfed child aged 6-8 months, three for a ",
  "breastfed child aged 9-23 months, and four feeds including milk with at least one solid feed ",
  "for a non-breastfed child (WHO Part 2 section C.9). Animal-source foods: ", comp_rule[3],
  ". Fruit and vegetables: ", comp_rule[4], ". Breastfeeding: ", comp_rule[5], ". ",
  if (SCORE_INCLUDES_AVOID)
    paste0("Sweet beverages: ", comp_rule[6], ". Unhealthy foods: ", comp_rule[7], ". ") else "",
  "Components are ",
  "graded on their underlying scales rather than on the WHO yes/no cut-offs, because a third of the ",
  "sample sits exactly on the meal-frequency cut-off and dichotomising there discards most of the ",
  "variance; every WHO indicator remains recoverable from its component. The item-total column is ",
  "the corrected item-total correlation, between the component and the sum of the other four. ",
  "Cronbach's alpha is ", sprintf("%.3f", alpha_5), " for all five components and ",
  sprintf("%.3f", alpha_4), " with breastfeeding removed. Breastfeeding is the one component with ",
  "a negative item-total correlation, and it stays negative within all four age groups, so ",
  "breastfed children in this sample genuinely eat a less varied complementary diet. It is retained ",
  "because a feeding score for 6-23 month olds that omits breastfeeding is not an IYCF score, and ",
  "a four-component version is carried in the analysis file so the sensitivity analysis is one ",
  "line. The structure follows the Infant and Child Feeding Index (Ruel & Menon 2002; Arimond & ",
  "Ruel 2004), rebuilt on the WHO & UNICEF (2021) definitions because that is the instrument this ",
  "study used. Sweet beverages and unhealthy foods are deliberately not scored - see Table 4.13."
)

# ----------------------------------------------------------
# 19. Table 4.13 - the four severity categories, and what validates them
#     This is the table that has to convince a reader the cut-points mean
#     something.  If the WHO indicators did not line up monotonically across
#     the four categories, the score would not be measuring feeding adequacy.
# ----------------------------------------------------------
val_ind  <- list(list("MDD", MDD), list("MMF", MMF), list("MAD", MAD),
                 list("EFF", EFF), list("ZVF", ZVF), list("SwB", SwB), list("UFC", UFC))
br <- IYCF_BREAKS
cat_band <- c(sprintf("0-%d", br[2]), sprintf("%d-%d", br[2] + 1, br[3]),
              sprintf("%d-%d", br[3] + 1, br[4]), sprintf("%d-%d", br[4] + 1, SCORE_MAX))

t413 <- do.call(rbind, lapply(seq_along(levels(iycf_cat)), function(i) {
  l <- levels(iycf_cat)[i]; m <- iycf_cat == l
  row <- data.frame(Category = l, Score = cat_band[i],
                    `n (%)`      = sprintf("%d (%.1f)", sum(m), 100 * mean(m)),
                    `Mean score` = sprintf("%.2f", mean(iycf_score[m])),
                    check.names = FALSE, stringsAsFactors = FALSE)
  for (v in val_ind) row[[v[[1]]]] <- sprintf("%.1f", 100 * mean(v[[2]][m]))
  row
}))
ft413 <- mk_ft(t413) %>% align(j = 1, align = "left", part = "all")

pc  <- function(v) paste(sprintf("%.1f%%", 100 * tapply(as.numeric(v), iycf_cat, mean)),
                         collapse = ", ")
kwp <- function(v) fmt_p(kruskal.test(as.numeric(v), iycf_cat)$p.value)

foot413 <- paste0(
  "The four severity categories of the IYCF practice score, with the WHO & UNICEF (2021) indicators ",
  "as the percentage of each category reaching them. n = ", nrow(raw), ". Cut-points are fixed on ",
  "the scoring logic rather than taken from the sample: a score of 8 or more means the child meets ",
  "or beats the WHO minimum on essentially every component, and the bottom band means failing most ",
  "of them. They ",
  "happen to fall close to the sample quartiles, so the four groups come out near-equal in size, ",
  "but they are not defined as quartiles and so can be compared against another study; a quantile ",
  "cut-point could not be. The four positive indicators rise monotonically across the categories ",
  "and zero vegetable or fruit falls monotonically, which is the gradient a severity scale has to ",
  "produce: minimum dietary diversity runs ", pc(MDD), " (Kruskal-Wallis p ", kwp(MDD),
  ") and minimum acceptable diet runs ", pc(MAD), " (p ", kwp(MAD), "). Sweet beverage and ",
  "unhealthy food consumption are the exception and rise with feeding adequacy - sweet beverages ",
  pc(SwB), " (p ", kwp(SwB), "), unhealthy foods ", pc(UFC), " (p ", kwp(UFC), "). That is why ",
  "neither is reverse-scored into the score: in these data a child given biscuits and sweet drinks ",
  "is typically a child being given more of everything, so subtracting for them would penalise the ",
  "better-fed children. Both are reported in Table 4.10 as the WHO indicators they are and are ",
  "interpreted separately. Zero vegetable or fruit is the one avoidance indicator inside the score, ",
  "where it is the bottom grade of the fruit-and-vegetable component. Percentages are unadjusted ",
  "for clustering within the 25 upazila recruitment sites."
)

# ----------------------------------------------------------
# 19b. Table 4.14 - household to child pass-through
#      The EC-FIES split this table used to carry went with the rest of EC-FIES
#      (decision 9).  What replaces it is the contrast the table was really
#      about: does the child eat a food group more often when the household
#      ate it?
# ----------------------------------------------------------
t414 <- do.call(rbind, lapply(seq_len(ncol(E_mat)), function(j) {
  hh <- E_mat[, j] == 1; ch <- child_match[, j] == 1
  tb <- table(factor(hh, c(FALSE, TRUE)), factor(ch, c(FALSE, TRUE)))
  pv <- suppressWarnings(
          if (all(rowSums(tb) > 0) && all(colSums(tb) > 0)) chisq.test(tb)$p.value
          else NA_real_)
  data.frame(`Food group`       = colnames(E_mat)[j],
             `Households n (%)` = sprintf("%d (%.1f)", sum(hh), 100 * mean(hh)),
             `Children n (%)`   = sprintf("%d (%.1f)", sum(ch), 100 * mean(ch)),
             `Child ate it, household did`     = sprintf("%.1f", 100 * mean(ch[hh])),
             `Child ate it, household did not` = if (sum(!hh) > 0)
                                                   sprintf("%.1f", 100 * mean(ch[!hh])) else "-",
             p = fmt_p(pv), check.names = FALSE, stringsAsFactors = FALSE)
}))
ft414 <- mk_ft(t414) %>% align(j = 1, align = "left", part = "all")
foot414 <- paste0(
  "Pass-through from the household five-group recall (Module E) to the child 24-hour recall ",
  "(Module F), both asked of the same respondent about the same day, n = ", nrow(raw), ". Eggs and ",
  "flesh foods are one household row but two child food groups, so the child side is eggs or flesh ",
  "foods. The last two columns are the percentage of children who ate the group among households ",
  "that did and did not eat it, and the test is chi-squared on that two-by-two table. Because both ",
  "recalls come from one respondent in one sitting and the food groups overlap by construction, ",
  "this association is partly method-driven and is not a clean causal estimate. Household dietary ",
  "diversity is also the strongest correlate of the IYCF practice score in Table 4.16, which is ",
  "the same caution in another form."
)

# ----------------------------------------------------------
# 19c. Table 4.15 - the two candidate indices, side by side
#      The thesis has to pick one and defend the choice in the methods
#      chapter.  This is the table that supports that paragraph.
# ----------------------------------------------------------
sh_core_noMAD <- sh_core[, colnames(sh_core) != "MAD"]
t415 <- data.frame(
  Property = c("Construction",
               "Items",
               "Item form",
               "Denominator",
               "Scale",
               "Mean (SD)",
               "Cronbach's alpha",
               "Alpha with arithmetic composites removed",
               "Items with negative item-total r",
               "Reaching the top category",
               "MDD across the four categories",
               "MAD across the four categories"),
  `Graded score (section 10)` = c(
    "Graded components, ICFI structure",
    sprintf("%d components", ncol(IYCF_C)),
    "0-3, 0-2 and 0-1 grades",
    sprintf("Fixed, 0-%d for every child", SCORE_MAX),
    sprintf("0-%d", SCORE_MAX),
    sprintf("%.2f (%.2f)", mean(iycf_score), sd(iycf_score)),
    sprintf("%.3f", alpha_5),
    sprintf("%.3f  (none to remove)", alpha_5),
    sprintf("%d of %d", sum(itot_5 < 0), length(itot_5)),
    sprintf("%d (%.1f%%)", sum(iycf_cat == "Adequate"), 100 * mean(iycf_cat == "Adequate")),
    paste(sprintf("%.1f", 100 * tapply(as.numeric(MDD), iycf_cat, mean)), collapse = ", "),
    paste(sprintf("%.1f", 100 * tapply(as.numeric(MAD), iycf_cat, mean)), collapse = ", ")),
  `Sheikh et al. index (section 10b)` = c(
    "One point per correct practice",
    sprintf("%d WHO indicators", ncol(SH_OK)),
    "Binary, 0 or 1",
    sprintf("Per child, %d to %d applicable", min(sh_den), max(sh_den)),
    "0-100%",
    sprintf("%.1f%% (%.1f)", mean(sh_pct), sd(sh_pct)),
    sprintf("%.3f", cronbach(sh_core)),
    sprintf("%.3f  (MAD removed)", cronbach(sh_core_noMAD)),
    sprintf("%d of %d", sum(sh_it < 0), length(sh_it)),
    sprintf("%d (%.1f%%)", sum(sh_cat4 == "Adequate"), 100 * mean(sh_cat4 == "Adequate")),
    paste(sprintf("%.1f", 100 * tapply(as.numeric(MDD), sh_cat4, mean)), collapse = ", "),
    paste(sprintf("%.1f", 100 * tapply(as.numeric(MAD), sh_cat4, mean)), collapse = ", ")),
  check.names = FALSE, stringsAsFactors = FALSE)

ft415 <- mk_ft(t415) %>% align(j = 1, align = "left", part = "all") %>% bold(j = 1)

foot415 <- paste0(
  "The two candidate constructions of the IYCF outcome, n = ", nrow(raw), ". The left column is ",
  "the graded score built in section 10 of the analysis script, following the Infant and Child ",
  "Feeding Index structure of Ruel & Menon (2002) on WHO & UNICEF (2021) definitions. The right ",
  "column is the method published by Sheikh and colleagues (2026, Journal of Nutritional Science ",
  "15: e50), which is the supervisor's own paper on the BIHS data: one point per correct practice ",
  "across the WHO indicators, expressed as a percentage, with the three negative indicators ",
  "counted as correct when the child did not do them. Both are computed on the same children and ",
  "the same indicator definitions, so the rows are directly comparable. They rank children ",
  "similarly, at Spearman ", sprintf("%.3f", cor(sh_pct, iycf_score, method = "spearman")),
  ", but place only ", sprintf("%.1f%%", 100 * mean(sh_cat4 == iycf_cat)), " of children in the ",
  "same one of four categories, so the choice is not cosmetic. Three things to weigh. First, the ",
  "alpha rows: minimum acceptable diet is by definition minimum dietary diversity AND minimum meal ",
  "frequency AND a milk-feed condition, all of which are separately in the Sheikh indicator list, ",
  "so it inflates that index's alpha by counting the same behaviour twice; removing it drops alpha ",
  "from ", sprintf("%.3f", cronbach(sh_core)), " to ", sprintf("%.3f", cronbach(sh_core_noMAD)),
  ". The graded score contains no such composite. Second, the negative item-total counts: both ",
  "constructions are dragged by the same two sweet-beverage and unhealthy-food items, so ",
  "reverse-scoring them does not repair them. Third, the validation rows: the graded score ",
  "separates the WHO indicators more cleanly across its categories. Against that, the Sheikh index ",
  "is the published method, it handles the restricted denominators of continued breastfeeding, ",
  "introduction of solid foods and milk feeding frequency by scoring each child only on the ",
  "indicators that apply to them, and reporting it makes this thesis directly comparable to the ",
  "BIHS analysis. Both are carried in the analysis file so either can be the primary outcome."
)

# ----------------------------------------------------------
# 20. Figure 4.5 - food group consumption
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
# 21. Figure 4.6 - the outcome variable: distribution and cut-points
#     Replaces the old household-diet-versus-EC-FIES figure (decision 9).
#     One figure has to do two jobs here: show how the 0-10 score is
#     distributed, and show where the four category boundaries fall on it, so
#     a reader can see that the cut-points are not slicing through a spike.
#     Okabe-Ito palette, no red anywhere - the client has asked for none.
# ----------------------------------------------------------
CAT_COL <- c("Severe inadequacy"   = "#4D4D4D",
             "Moderate inadequacy" = "#E69F00",
             "Mild inadequacy"     = "#56B4E9",
             "Adequate"            = "#009E73")

fig46_df <- as.data.frame(table(score = iycf_score), stringsAsFactors = FALSE)
fig46_df$score <- as.integer(fig46_df$score)
fig46_df$cat   <- factor(cut(fig46_df$score, IYCF_BREAKS, labels = IYCF_LABELS),
                         levels = IYCF_LABELS)
fig46_df$pct   <- 100 * fig46_df$Freq / nrow(raw)

fig46 <- ggplot(fig46_df, aes(factor(score), pct, fill = cat)) +
  geom_col(width = 0.82) +
  geom_text(aes(label = Freq), vjust = -0.6, size = 3, colour = OK_GREY) +
  # Boundaries sit BETWEEN bars, at 3|4, 5|6 and 7|8.
  geom_vline(xintercept = match(br[2:4], sort(unique(fig46_df$score))) + 0.5,
             linetype = "dashed",
             colour = OK_GREY, linewidth = 0.4) +
  scale_fill_manual(values = CAT_COL, name = NULL) +
  scale_y_continuous(limits = c(0, max(fig46_df$pct) * 1.18), expand = c(0, 0)) +
  labs(x = sprintf("IYCF practice score (0-%d)", SCORE_MAX), y = "Children (%)",
       caption = paste0(
         "n = ", nrow(raw), ". Bar labels are counts. Mean ",
         sprintf("%.2f", mean(iycf_score)), ", SD ", sprintf("%.2f", sd(iycf_score)),
         ", median ", median(iycf_score),
         ". Dashed lines are the category boundaries; colours are the four\n",
         "severity categories: severe 0-3 (n = ", sum(iycf_cat == "Severe inadequacy"),
         "), moderate 4-5 (n = ", sum(iycf_cat == "Moderate inadequacy"),
         "), mild 6-7 (n = ", sum(iycf_cat == "Mild inadequacy"),
         "), adequate 8-10 (n = ", sum(iycf_cat == "Adequate"), ").\n",
         "Cut-points follow the scoring logic rather than the sample distribution, and no boundary ",
         "falls on a spike in the distribution.")) +
  theme_thesis +
  theme(legend.position = "top")

# ----------------------------------------------------------
# 22. Export
# ----------------------------------------------------------
small    <- fp_text(font.size = 8, italic = TRUE)
add_foot <- function(d, txt) body_add_fpar(d, fpar(ftext(txt, small)))

doc <- read_docx() %>%
  body_add_par("Table 4.10  Infant and young child feeding indicators, WHO/UNICEF 2021", style = "heading 2") %>%
  body_add_flextable(ft410) %>% add_foot(foot410) %>% body_add_par("") %>%
  body_add_par("Table 4.11  Consumption of the eight minimum-dietary-diversity food groups", style = "heading 2") %>%
  body_add_flextable(ft411) %>% add_foot(foot411) %>% body_add_par("") %>%
  body_add_par("Table 4.12  Construction of the IYCF practice score: components, grades and internal consistency", style = "heading 2") %>%
  body_add_flextable(ft412) %>% add_foot(foot412) %>% body_add_par("") %>%
  body_add_par("Table 4.13  The four IYCF practice categories, validated against the WHO indicators", style = "heading 2") %>%
  body_add_flextable(ft413) %>% add_foot(foot413) %>% body_add_par("") %>%
  body_add_par("Table 4.14  Household to child food-group pass-through", style = "heading 2") %>%
  body_add_flextable(ft414) %>% add_foot(foot414) %>% body_add_par("") %>%
  body_add_par("Table 4.15  The two candidate IYCF indices compared", style = "heading 2") %>%
  body_add_flextable(ft415) %>% add_foot(foot415) %>% body_add_par("") %>%
  body_add_par("Table 4.16  Bivariate association between the IYCF practice score and each candidate independent variable", style = "heading 2") %>%
  body_add_flextable(ft416) %>% add_foot(foot416)

safe_write(print(doc, target = OUT_DOCX), OUT_DOCX)
safe_write(ggsave(file.path(GRAPH_DIR, "Fig4_5_food_groups.png"), fig45,
                  width = 7.2, height = 4.2, dpi = 300),
           file.path(GRAPH_DIR, "Fig4_5_food_groups.png"))
safe_write(ggsave(file.path(GRAPH_DIR, "Fig4_6_score_profile.png"), fig46,
                  width = 7.2, height = 4.6, dpi = 300),
           file.path(GRAPH_DIR, "Fig4_6_score_profile.png"))
safe_write(saveRDS(dat, OUT_RDS), OUT_RDS)

rule("DONE")
note("Outcome -> iycf_score (0-10) and iycf_cat (4 ordered levels), section 10.")
note("Tables  -> ", OUT_DOCX, "  (4.10-4.16)")
note("Figures -> ", GRAPH_DIR, "/Fig4_5_food_groups.png, Fig4_6_score_profile.png")
note("Data    -> ", OUT_RDS, "  (", nrow(dat), " rows, ", ncol(dat), " columns)")
note("Next    -> 05_models.R: ordinal logistic on iycf_cat, linear on iycf_score.")
note("NOTE    -> EC-FIES is gone from this script (decision 9). Table 4.5 in")
note("           01_tables_chapter4.R is still an EC-FIES table and was NOT")
note("           touched - decide separately whether it stays in Chapter 4.")
safe_write(writeLines(LOG, OUT_LOG), OUT_LOG)
