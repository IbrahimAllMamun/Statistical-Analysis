# ============================================================
# Anni MS thesis - Infant and young child feeding (IYCF) practice, Bangladesh
# 03_analysis.R  -  the full Chapter 4 table set, descriptive to regression
# ------------------------------------------------------------
# Source data : Data/iycf_analysis.rds, written by 02_iycf.R from Data/MAIN.sav
#               (N = 407 mother-child pairs, 6-23 months)
# Reference   : WHO & UNICEF (2021), Materials/indicator_methods.pdf
#               Sheikh Z, Hossain MS, Ali M, Hassan R, Alam MM, Amin MR (2026),
#               J Nutr Sci 15: e50 - the supervisor's own paper, whose method
#               for scoring and for variable selection is followed here.
#
# Produces:
#   doc/Tables_Analysis.docx   Tables 1 - 16
#   doc/analysis_log.txt       run log, model diagnostics, selection trace
#
# ------------------------------------------------------------
# ANALYTIC DECISIONS - read before using the output
# ------------------------------------------------------------
# 1. THE OUTCOME IS THE FOUR-COMPONENT SCORE, 0-9, NOT THE FIVE-COMPONENT
#    0-10 ONE.  This was a deliberate change from 02_iycf.R, made because the
#    four-component version has the HIGHER internal consistency: alpha 0.752
#    against 0.682.  The component dropped is breastfeeding, whose corrected
#    item-total correlation is negative in the five-component score and stays
#    negative inside every age group.
#
#    WHAT THIS COSTS, and it should be stated in the methods chapter rather
#    than left for an examiner to raise: a feeding score for 6-23 month olds
#    that contains no breastfeeding term is a COMPLEMENTARY FEEDING adequacy
#    score, not a complete IYCF score.  Breastfeeding is still reported as a
#    WHO indicator in Table 8, and continued breastfeeding at 12-23 months is
#    93.4% in this sample, so little information is lost in practice - but the
#    construct being modelled is narrower than the thesis title implies.
#    Name it accurately in the text.
#
# 2. SCORING FOLLOWS THE SUPERVISOR'S PAPER WHERE IT CAN.  Sheikh et al. score
#    one point per correct practice and cut at 80% of the attainable maximum.
#    Table 10 reports their index alongside this one.  Their exact method is
#    NOT used as primary for the reasons set out in 02_iycf.R decision 12 and
#    in the Table 10 footnote, chiefly that minimum acceptable diet is an
#    arithmetic function of other indicators in the same list and inflates the
#    alpha of that index.
#
# 3. VARIABLE SELECTION IS THEIRS, EXACTLY.  Bivariate screen at p <= 0.25,
#    then multicollinearity by variance inflation factor with a cut-off of 2,
#    then binary logistic regression reporting adjusted odds ratios.  This is
#    the procedure in their Statistical analysis section and following it makes
#    the two studies comparable.  Table 14 shows every step.
#
# 4. THE BINARY IS THE TOP CATEGORY.  Score >= 7 of 9 is "appropriate
#    complementary feeding practice".  That is 78% of the attainable maximum,
#    the closest this scale comes to the 80% convention, and it is exactly the
#    top of the four-level variable, so the binary and the ordinal agree by
#    construction.  80 events, which supports about 8 predictor degrees of
#    freedom at ten events per variable.
#
# 5. SEPARATION IS CHECKED, NOT ASSUMED AWAY.  Place of delivery has an empty
#    outcome cell at its "Other" level, n = 2.  It does not survive the p <=
#    0.25 screen so it never reaches the model, but the check runs anyway and
#    the script refits with Firth penalisation if any selected variable turns
#    out to separate.  Note that glm does NOT warn about this: it reports
#    convergence and returns an odds ratio in the hundreds of thousands.
#
# 6. THE PUBLISHED SELECTION PROCEDURE OVERFITS THIS SAMPLE, AND BOTH MODELS
#    ARE REPORTED.  The p <= 0.25 screen admits 16 variables costing 38
#    degrees of freedom, against 79 events - 2.08 events per degree of
#    freedom, where ten is the conventional minimum.  This is not a flaw in
#    the source paper: their sample carried roughly 264 events and could
#    afford the screen.  It is what happens when the same screen meets a
#    sample a fifth of the size.  Table 15 reports the method-faithful model
#    so the departure is visible; Table 16 reports a backward-eliminated
#    model at 5.27 events per degree of freedom, which is still short of ten
#    but defensible.  READ THEM TOGETHER: a variable significant in both is a
#    robust finding, one significant only in Table 15 is unstable.
#
# 7. NOTHING HERE IS ADJUSTED FOR CLUSTERING within the 25 upazila recruitment
#    sites.  Confidence intervals are therefore narrower than a design-adjusted
#    analysis would give.  Stated in every relevant footnote.
# ============================================================

# ----------------------------------------------------------
# 1. Packages and paths
# ----------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(flextable)
  library(officer)
})

IN_RDS   <- "Data/iycf_analysis.rds"
OUT_DOCX <- "doc/Tables_Analysis.docx"     # generated - NOT a client document
OUT_LOG  <- "doc/analysis_log.txt"

stopifnot(file.exists(IN_RDS))
dir.create("doc", showWarnings = FALSE)

# ----------------------------------------------------------
# 2. Helpers
# ----------------------------------------------------------
LOG  <- character(0)
note <- function(...) { m <- paste0(...); LOG <<- c(LOG, m); message(m) }
rule <- function(t) note("\n", strrep("-", 66), "\n", t, "\n", strrep("-", 66))

safe_write <- function(expr, path) {
  tryCatch({ force(expr); message("Saved -> ", path); invisible(TRUE) },
           error = function(e) {
             warning("COULD NOT WRITE ", path,
                     " - it is probably open in Word. Close it and re-run. (",
                     conditionMessage(e), ")", call. = FALSE, immediate. = TRUE)
             invisible(FALSE) })
}

fmt_p <- function(p) ifelse(is.na(p), "-",
                     ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
np    <- function(k, n) sprintf("%d (%.1f)", k, 100 * k / n)

wilson <- function(k, n) {
  if (n == 0) return(c(NA, NA))
  p <- k / n; z <- 1.959964; d <- 1 + z^2 / n
  c(100 * ((p + z^2/(2*n) - z*sqrt(p*(1-p)/n + z^2/(4*n^2))) / d),
    100 * ((p + z^2/(2*n) + z*sqrt(p*(1-p)/n + z^2/(4*n^2))) / d))
}

mk_ft <- function(df) {
  flextable(df) |>
    theme_booktabs() |>
    fontsize(size = 9, part = "all") |>
    font(fontname = "Calibri", part = "all") |>
    bold(part = "header") |>
    align(align = "center", part = "all") |>
    align(j = 1, align = "left", part = "all") |>
    padding(padding.top = 1, padding.bottom = 1, part = "all") |>
    autofit()
}

# Chi-squared, or Fisher's exact where any expected count is below 5.  Applied
# to every categorical bivariate test in this script.
p_cat <- function(f, y) {
  tb <- table(f, y)
  if (any(dim(tb) < 2)) return(NA_real_)
  ex <- suppressWarnings(chisq.test(tb)$expected)
  if (any(ex < 5)) {
    pv <- tryCatch(fisher.test(tb, simulate.p.value = TRUE, B = 20000)$p.value,
                   error = function(e) NA_real_)
    return(pv)
  }
  suppressWarnings(chisq.test(tb)$p.value)
}

rule("03_analysis.R")
note("Run: ", format(Sys.time(), "%Y-%m-%d %H:%M"))
note("Source: ", IN_RDS)

# ----------------------------------------------------------
# 3. Read, and rebuild the outcome at the highest alpha
# ----------------------------------------------------------
d <- readRDS(IN_RDS)
N <- nrow(d)
note("Rows: ", N, " | columns: ", ncol(d))

cronbach <- function(M)
  ncol(M) / (ncol(M) - 1) * (1 - sum(apply(M, 2, var)) / var(rowSums(M)))
item_total <- function(M) {
  s <- rowSums(M)
  setNames(vapply(seq_len(ncol(M)), function(j) cor(M[, j], s - M[, j]),
                  numeric(1)), colnames(M))
}

# The four graded components, decision 1.  Breastfeeding is deliberately out.
CMP <- as.matrix(d[, c("c_dd", "c_mf", "c_asf", "c_fv")])
colnames(CMP) <- c("Dietary diversity", "Meal frequency",
                   "Animal-source foods", "Fruit and vegetables")
CMP5 <- cbind(CMP, Breastfeeding = d$c_bf)

score  <- as.integer(rowSums(CMP))           # 0-9
alpha4 <- cronbach(CMP)
alpha5 <- cronbach(CMP5)
itot4  <- item_total(CMP)

# Four categories.  Cut on the scoring logic - the top band means meeting or
# beating the WHO minimum on essentially every component - and they land on
# the sample quartiles (2, 4, 6), so the groups come out near-equal without
# being DEFINED as quantiles, which keeps them comparable to another study.
BREAKS <- c(-Inf, 2, 4, 6, Inf)
LABELS <- c("Severe inadequacy", "Moderate inadequacy",
            "Mild inadequacy", "Adequate")
BANDS  <- c("0-2", "3-4", "5-6", "7-9")
scat   <- factor(cut(score, BREAKS, labels = LABELS), levels = LABELS,
                 ordered = TRUE)

# The binary, decision 4: the top category.
BIN_CUT <- 7L
ybin    <- as.integer(score >= BIN_CUT)

d$score <- score; d$scat <- scat; d$ybin <- ybin

rule("OUTCOME")
note(sprintf("Score 0-9: mean %.2f  SD %.2f  median %d", mean(score), sd(score),
             median(score)))
note(sprintf("Cronbach's alpha, 4 components : %.3f   <- used", alpha4))
note(sprintf("Cronbach's alpha, 5 components : %.3f   (02_iycf.R default)", alpha5))
for (l in LABELS)
  note(sprintf("   %-22s %3d (%4.1f%%)", l, sum(scat == l), 100 * mean(scat == l)))
note(sprintf("Binary, score >= %d: %d events / %d non-events (%.1f%%)",
             BIN_CUT, sum(ybin), N - sum(ybin), 100 * mean(ybin)))

# ----------------------------------------------------------
# 4. The independent variables, grouped as the thesis draft groups them
# ----------------------------------------------------------
CAND <- names(d)[which(names(d) == "Child age group"):ncol(d)]
CAND <- CAND[!grepl("^sh_|^score$|^scat$|^ybin$", CAND)]

GROUPS <- list(
  `Household and socioeconomic characteristics` = c(
    "Division", "Residence", "Wealth quintile", "Religion", "Family type",
    "Household size", "Any media access", "Improved sanitation",
    "Clean cooking fuel", "Shared toilet", "Separate kitchen",
    "Household bank account", "Household food groups (0-5)"),
  `Characteristics of the children` = c(
    "Child age group", "Child sex", "Birth order", "Birth weight",
    "Currently breastfed", "Child sick at interview"),
  `Maternal characteristics` = c(
    "Mother's age (years)", "Mother's education", "Mother's occupation",
    "Age at marriage", "Number of children"),
  `Paternal characteristics` = c(
    "Father's age (years)", "Father's education", "Father's occupation"),
  `Maternal and child health service use` = c(
    "ANC visits", "Place of delivery", "Mode of delivery", "Birth attendant",
    "Postnatal care visit", "Nutrition counselling", "Child health decisions"))

miss <- setdiff(CAND, unlist(GROUPS))
if (length(miss)) note("NOT GROUPED (check): ", paste(miss, collapse = ", "))
note("Independent variables: ", length(CAND), " in ", length(GROUPS), " groups")

# One frequency block for one variable.  Numerics get mean (SD) and median
# (IQR) rather than levels, because three of the candidates are counts.
freq_rows <- function(label, x) {
  ok <- !is.na(x); n <- sum(ok)
  if (is.numeric(x)) {
    return(data.frame(
      Variable = label,
      `n (%)`  = sprintf("%.2f (%.2f)", mean(x[ok]), sd(x[ok])),
      `Summary` = sprintf("%.0f (%.0f-%.0f)", median(x[ok]),
                          quantile(x[ok], .25), quantile(x[ok], .75)),
      Missing  = as.character(N - n),
      check.names = FALSE, stringsAsFactors = FALSE))
  }
  f <- droplevels(x[ok])
  rbind(
    data.frame(Variable = label, `n (%)` = "", Summary = "",
               Missing = as.character(N - n),
               check.names = FALSE, stringsAsFactors = FALSE),
    do.call(rbind, lapply(levels(f), function(l)
      data.frame(Variable = paste0("    ", l),
                 `n (%)`  = np(sum(f == l), n),
                 Summary  = sprintf("%.1f", 100 * sum(f == l) / n),
                 Missing  = "",
                 check.names = FALSE, stringsAsFactors = FALSE))))
}

group_table <- function(vars) {
  do.call(rbind, lapply(vars, function(v) freq_rows(v, d[[v]])))
}

FOOT_COMMON <- paste0(
  "n = ", N, " mother-child pairs, children aged 6-23 months. Categorical variables are n (%) of ",
  "non-missing responses, with the percentage repeated in the third column; continuous variables ",
  "are mean (SD) in the second column and median (IQR) in the third. The Missing column counts ",
  "children with no valid response, and percentages are of the non-missing denominator. ")

# ----------------------------------------------------------
# 5. Tables 1-6 - the descriptive tables the thesis draft already carries
# ----------------------------------------------------------
t1 <- local({
  div <- droplevels(d$Division); res <- droplevels(d$Residence)
  tb  <- table(div, res)
  do.call(rbind, lapply(levels(div), function(l) {
    r <- tb[l, ]
    data.frame(Division = l,
               Urban = np(r[["Urban"]], sum(r)),
               Rural = np(r[["Rural"]], sum(r)),
               Total = sprintf("%d (%.1f)", sum(r), 100 * sum(r) / N),
               check.names = FALSE, stringsAsFactors = FALSE)
  })) |>
    rbind(data.frame(Division = "Total",
                     Urban = np(sum(res == "Urban"), N),
                     Rural = np(sum(res == "Rural"), N),
                     Total = sprintf("%d (100.0)", N),
                     check.names = FALSE, stringsAsFactors = FALSE))
})
ft1 <- mk_ft(t1) |> bold(i = nrow(t1))
foot1 <- paste0(
  "Distribution of the ", N, " study children across administrative divisions and place of ",
  "residence. Percentages in the Urban and Rural columns are of the division row total; the Total ",
  "column is the percentage of the whole sample. Recruitment took place at 25 upazila health ",
  "congregation sites, so this is not a population-representative geographic distribution and no ",
  "analysis in this document is weighted or adjusted for that clustering.")

t2 <- group_table(GROUPS[[1]]); ft2 <- mk_ft(t2)
t3 <- group_table(GROUPS[[2]]); ft3 <- mk_ft(t3)
t4 <- group_table(GROUPS[[3]]); ft4 <- mk_ft(t4)
t5 <- group_table(GROUPS[[4]]); ft5 <- mk_ft(t5)
t6 <- group_table(GROUPS[[5]]); ft6 <- mk_ft(t6)
for (nm in c("ft2","ft3","ft4","ft5","ft6")) {
  tb <- get(sub("^ft", "t", nm))
  assign(nm, bold(get(nm), i = which(!startsWith(tb$Variable, "    ")), j = 1))
}

foot2 <- paste0(FOOT_COMMON,
  "Household food groups is the 0-5 count from the Module E household recall. Wealth quintile was ",
  "constructed by principal components analysis on the household asset list. Clean cooking fuel ",
  "groups electricity, LPG, natural gas and biogas against solid and polluting fuels. Drinking ",
  "water source and ethnicity are not shown: 405 of 407 households use an improved source and 405 ",
  "of 407 respondents are Bengali, so neither varies enough to analyse.")
foot3 <- paste0(FOOT_COMMON,
  "Birth weight was recorded in mixed units and is repaired here, with 7 forms entered in kilograms ",
  "multiplied by 1000; the 88 'don't know' responses are kept as their own level rather than ",
  "dropped, because dropping them would remove a fifth of the sample. Child sick at interview is ",
  "the mother's report on the day of interview. Recruitment happened at health congregation sites, ",
  "so sick children are OVER-SAMPLED BY DESIGN and this row describes the sampling frame; it is ",
  "not evidence that illness is unusually common in this population.")
foot4 <- paste0(FOOT_COMMON,
  "Age at marriage is the mother's age at first marriage in completed years. Number of children is ",
  "total living children, not only those in the eligible age band.")
foot5 <- paste0(FOOT_COMMON,
  "Father's occupation collapses seven recorded categories into four; the group counted as ",
  "'business / service / other' is mostly salaried employees rather than traders.")
foot6 <- paste0(FOOT_COMMON,
  "Antenatal care visits exclude one 'don't know' response. Place of delivery, mode of delivery and ",
  "birth attendant refer to the index child. Child health decisions collapses six recorded response ",
  "categories into three. Nutrition counselling is any counselling reported during pregnancy or ",
  "after delivery.")

# ----------------------------------------------------------
# 6. Table 7 - every independent variable in one univariate table
# ----------------------------------------------------------
t7 <- do.call(rbind, lapply(names(GROUPS), function(g) {
  rbind(data.frame(Variable = toupper(g), `n (%)` = "", Summary = "", Missing = "",
                   check.names = FALSE, stringsAsFactors = FALSE),
        group_table(GROUPS[[g]]))
}))
ft7 <- mk_ft(t7) |>
  bold(i = which(!startsWith(t7$Variable, "    ")), j = 1) |>
  bg(i = which(t7$Variable == toupper(names(GROUPS))[match(t7$Variable, toupper(names(GROUPS)))] &
               !is.na(match(t7$Variable, toupper(names(GROUPS))))),
     bg = "#EFEFEF", part = "body")
foot7 <- paste0(FOOT_COMMON,
  "This is the complete set of ", length(CAND), " candidate independent variables carried into the ",
  "bivariate screen in Table 13, gathered into one table so the modelling variable list can be ",
  "checked at a glance. It repeats the content of Tables 2 to 6 in consolidated form. Denominators ",
  "vary where a variable has missing responses, and the Missing column gives the count.")

# ----------------------------------------------------------
# 7. Table 8 - the WHO IYCF indicators
# ----------------------------------------------------------
IND <- list(
  list("Minimum dietary diversity (MDD)",            d$mdd,   rep(TRUE, N)),
  list("Minimum meal frequency (MMF)",               d$mmf,   rep(TRUE, N)),
  list("Minimum acceptable diet (MAD)",              d$mad,   rep(TRUE, N)),
  list("Egg and/or flesh food consumption (EFF)",    d$eff,   rep(TRUE, N)),
  list("Sweet beverage consumption (SwB)",           d$swb,   rep(TRUE, N)),
  list("Unhealthy food consumption (UFC)",           d$ufc,   rep(TRUE, N)),
  list("Zero vegetable or fruit consumption (ZVF)",  d$zvf,   rep(TRUE, N)),
  list("Continued breastfeeding at 12-23 months (CBF)", d$bf,  d$age_m >= 12),
  list("Introduction of solid foods at 6-8 months (ISSSF)", d$isssf,
       d$age_m >= 6 & d$age_m <= 8),
  list("Minimum milk feeding frequency, non-breastfed (MMFF)", d$mmff, d$bf == 0),
  list("Breastfed yesterday (context)",              d$bf,    rep(TRUE, N)))

t8 <- do.call(rbind, lapply(IND, function(r) {
  k <- r[[3]]; num <- sum(r[[2]][k]); den <- sum(k); ci <- wilson(num, den)
  data.frame(Indicator = r[[1]],
             `n / N`   = sprintf("%d / %d", num, den),
             `%`       = sprintf("%.1f", 100 * num / den),
             `95% CI`  = sprintf("%.1f - %.1f", ci[1], ci[2]),
             check.names = FALSE, stringsAsFactors = FALSE)
}))
ft8 <- mk_ft(t8)
foot8 <- paste0(
  "Indicators follow WHO & UNICEF (2021), Indicators for assessing infant and young child feeding ",
  "practices, Part 2 section C. Each percentage is of the denominator that indicator defines, shown ",
  "in the n / N column: continued breastfeeding applies only at 12-23 months, introduction of solid ",
  "foods only at 6-8 months, and minimum milk feeding frequency only to non-breastfed children. ",
  "Confidence intervals are Wilson score intervals without continuity correction and are NOT ",
  "adjusted for clustering within the 25 upazila recruitment sites, so they are narrower than a ",
  "design-adjusted interval would be. Seven of WHO's 17 indicators cannot be computed from these ",
  "data: ever breastfed, early initiation of breastfeeding and exclusive breastfeeding for the ",
  "first two days need birth-recall questions that were not asked; exclusive and mixed milk feeding ",
  "have a 0-5 month denominator and this sample is 6-23 months; bottle feeding was not asked; and ",
  "the infant feeding area graphs require both. Note that sweet beverage, unhealthy food and zero ",
  "vegetable or fruit consumption are indicators where a HIGHER percentage is worse.")

# ----------------------------------------------------------
# 8. Table 9 - how the score is built
# ----------------------------------------------------------
CMAX  <- c(3L, 2L, 2L, 2L)
CRULE <- c("0-2 food groups / 3-4 / 5-6 / 7-8 of the eight WHO groups",
           "below the child's own WHO minimum / exactly at it / above it",
           "none / 1 / 2 or more of the nine animal-source rows",
           "none, which is exactly ZVF / 1 / 2 or more of the five rows")

t9 <- do.call(rbind, lapply(seq_len(ncol(CMP)), function(j) {
  x <- CMP[, j]
  g <- vapply(0:3, function(k)
         if (k > CMAX[j]) "-" else np(sum(x == k), N), character(1))
  data.frame(Component = colnames(CMP)[j], Range = sprintf("0-%d", CMAX[j]),
             `Grade 0` = g[1], `Grade 1` = g[2], `Grade 2` = g[3], `Grade 3` = g[4],
             `Mean (SD)`    = sprintf("%.2f (%.2f)", mean(x), sd(x)),
             `Item-total r` = sprintf("%+.3f", itot4[[j]]),
             check.names = FALSE, stringsAsFactors = FALSE)
}))
t9 <- rbind(t9, data.frame(
  Component = "IYCF PRACTICE SCORE", Range = "0-9",
  `Grade 0` = "", `Grade 1` = "", `Grade 2` = "", `Grade 3` = "",
  `Mean (SD)`    = sprintf("%.2f (%.2f)", mean(score), sd(score)),
  `Item-total r` = sprintf("alpha %.3f", alpha4),
  check.names = FALSE, stringsAsFactors = FALSE))
ft9 <- mk_ft(t9) |> bold(i = nrow(t9))
foot9 <- paste0(
  "The four components of the IYCF practice score, n = ", N, " for every row. Cells are n (%) of ",
  "children at each grade; a dash marks a grade the component does not have. Grades are assigned ",
  "as follows. Dietary diversity: ", CRULE[1], ". Meal frequency: ", CRULE[2], ", where that ",
  "minimum is two solid feeds for a breastfed child aged 6-8 months, three for a breastfed child ",
  "aged 9-23 months, and four feeds including milk with at least one solid feed for a non-breastfed ",
  "child. Animal-source foods: ", CRULE[3], ". Fruit and vegetables: ", CRULE[4], ". Components are ",
  "graded on their underlying scales rather than on the WHO yes/no cut-offs, because a third of the ",
  "sample sits exactly on the meal-frequency cut-off and dichotomising there discards most of the ",
  "variance; each WHO indicator remains recoverable from its component. 'Item-total r' is the ",
  "corrected item-total correlation, between the component and the sum of the other three. ",
  "Cronbach's alpha is ", sprintf("%.3f", alpha4), ". Adding breastfeeding as a fifth component ",
  "LOWERS alpha to ", sprintf("%.3f", alpha5), ", because its item-total correlation is negative ",
  "and stays negative within every age group, so it is excluded; the consequence is that this is a ",
  "complementary feeding adequacy score rather than a complete IYCF score, and it should be named ",
  "that way in the text. The structure follows the Infant and Child Feeding Index (Ruel & Menon ",
  "2002; Arimond & Ruel 2004) applied to the WHO & UNICEF (2021) definitions.")

# ----------------------------------------------------------
# 9. Table 10 - the candidate index constructions compared
# ----------------------------------------------------------
CMP7 <- cbind(CMP5, `No sweet beverage` = 1L - d$swb, `No unhealthy food` = 1L - d$ufc)
SH_C <- cbind(MDD = d$mdd, MMF = d$mmf, MAD = d$mad, EFF = d$eff,
              noSwB = 1L - d$swb, noUFC = 1L - d$ufc, noZVF = 1L - d$zvf)

t10 <- data.frame(
  Construction = c(
    "Four graded components (USED)",
    "Five graded components, breastfeeding added",
    "Seven graded components, sweet drinks and junk food added, reversed",
    "Sheikh et al. (2026), one point per correct practice",
    "Sheikh et al., with minimum acceptable diet removed"),
  Items = c("4 graded", "5 graded", "7 graded", "10 binary", "9 binary"),
  Scale = c("0-9", "0-10", "0-12", "0-100%", "0-100%"),
  `Cronbach alpha` = sprintf("%.3f", c(alpha4, alpha5, cronbach(CMP7),
                                       cronbach(SH_C),
                                       cronbach(SH_C[, colnames(SH_C) != "MAD"]))),
  `Negative item-total` = c(
    sprintf("%d of 4", sum(itot4 < 0)),
    sprintf("%d of 5", sum(item_total(CMP5) < 0)),
    sprintf("%d of 7", sum(item_total(CMP7) < 0)),
    sprintf("%d of 7 core", sum(item_total(SH_C) < 0)),
    sprintf("%d of 6 core", sum(item_total(SH_C[, colnames(SH_C) != "MAD"]) < 0))),
  check.names = FALSE, stringsAsFactors = FALSE)
ft10 <- mk_ft(t10) |> bold(i = 1)
foot10 <- paste0(
  "Every candidate construction of the outcome, computed on the same ", N, " children and the same ",
  "indicator definitions, so the alphas are directly comparable. The first row is the score used ",
  "throughout this document. Rows two and three show why components were left out: breastfeeding ",
  "and the two avoidance indicators each LOWER internal consistency when added, and each arrives ",
  "with a negative corrected item-total correlation. For the avoidance indicators this is not a ",
  "coding error and reversing them is what produces it - in these data a child given sweet drinks ",
  "and biscuits is typically a child being given more of everything, so those items measure ",
  "discretionary food exposure rather than feeding adequacy. Rows four and five are the method of ",
  "Sheikh et al. (2026, Journal of Nutritional Science 15: e50), the supervisor's own paper: one ",
  "point per correct practice across the WHO indicators, scored over the indicators applicable to ",
  "each child and expressed as a percentage. Its alpha falls from ", sprintf("%.3f", cronbach(SH_C)),
  " to ", sprintf("%.3f", cronbach(SH_C[, colnames(SH_C) != "MAD"])), " when minimum acceptable ",
  "diet is removed, because minimum acceptable diet is by definition minimum dietary diversity AND ",
  "minimum meal frequency AND a milk-feed condition, all separately present in the same list, so it ",
  "counts one behaviour twice. That published index and this one rank children similarly, at ",
  "Spearman ", sprintf("%.3f", cor(d$sh_pct, score, method = "spearman")),
  ", so the choice between them changes the measurement properties more than it changes the ranking.")

# ----------------------------------------------------------
# 10. Table 11 - the score distribution and its four categories
# ----------------------------------------------------------
t11a <- do.call(rbind, lapply(0:9, function(k) {
  m <- score == k
  data.frame(Score = as.character(k), `n (%)` = np(sum(m), N),
             Cumulative = sprintf("%.1f", 100 * mean(score <= k)),
             Category = as.character(LABELS[findInterval(k, c(0, 3, 5, 7)) ]),
             check.names = FALSE, stringsAsFactors = FALSE)
}))
ft11a <- mk_ft(t11a)

t11b <- do.call(rbind, lapply(seq_along(LABELS), function(i) {
  m <- scat == LABELS[i]
  row <- data.frame(Category = LABELS[i], Score = BANDS[i],
                    `n (%)` = np(sum(m), N),
                    `Mean score` = sprintf("%.2f", mean(score[m])),
                    check.names = FALSE, stringsAsFactors = FALSE)
  for (v in list(c("MDD","mdd"), c("MMF","mmf"), c("MAD","mad"),
                 c("EFF","eff"), c("ZVF","zvf")))
    row[[v[1]]] <- sprintf("%.1f", 100 * mean(d[[v[2]]][m]))
  row
}))
ft11b <- mk_ft(t11b)

kw <- function(v) fmt_p(kruskal.test(as.numeric(d[[v]]), scat)$p.value)
foot11 <- paste0(
  "Distribution of the 0-9 IYCF practice score and of the four severity categories built from it, ",
  "n = ", N, ". Cut-points are fixed on the scoring logic rather than taken from the sample: the ",
  "top band means the child meets or beats the WHO minimum on essentially every component, and the ",
  "bottom band means failing most of them. They happen to fall on the sample quartiles of 2, 4 and ",
  "6, so the four groups come out near-equal in size, but they are NOT defined as quartiles, which ",
  "matters because a quantile cut-point shifts with the sample and cannot be compared against ",
  "another study. The second panel validates them against the WHO indicators, which is the check ",
  "that would fail first if a component were scored backwards: minimum dietary diversity rises ",
  paste(sprintf("%.1f%%", 100 * tapply(d$mdd, scat, mean)), collapse = ", "), " across the four ",
  "categories (Kruskal-Wallis p ", kw("mdd"), "), minimum acceptable diet rises ",
  paste(sprintf("%.1f%%", 100 * tapply(d$mad, scat, mean)), collapse = ", "), " (p ", kw("mad"),
  "), and zero vegetable or fruit consumption falls ",
  paste(sprintf("%.1f%%", 100 * tapply(d$zvf, scat, mean)), collapse = ", "), " (p ", kw("zvf"),
  "). No child in the bottom category reaches minimum dietary diversity and none reaches minimum ",
  "acceptable diet, and every child in the top category reaches minimum dietary diversity.")

# ----------------------------------------------------------
# 11. Table 12 - the binary outcome
# ----------------------------------------------------------
t12 <- do.call(rbind, lapply(c(8L, 7L, 6L, 5L), function(k) {
  y <- as.integer(score >= k); lim <- min(sum(y), N - sum(y))
  data.frame(`Cut-point` = sprintf("Score >= %d", k),
             `% of maximum` = sprintf("%.0f", 100 * k / 9),
             `Appropriate n (%)`   = np(sum(y), N),
             `Inappropriate n (%)` = np(N - sum(y), N),
             `Limiting cell` = as.character(lim),
             `Supports ~df`  = as.character(lim %/% 10),
             Use = if (k == BIN_CUT) "USED - the top category"
                   else if (k == 5L) "Best powered, no precedent"
                   else "",
             check.names = FALSE, stringsAsFactors = FALSE)
}))
ft12 <- mk_ft(t12) |> bold(i = which(t12$`Cut-point` == sprintf("Score >= %d", BIN_CUT)))
foot12 <- paste0(
  "Candidate dichotomisations of the 0-9 score, n = ", N, ". The cut used throughout the rest of ",
  "this document is a score of ", BIN_CUT, " or more, called 'appropriate complementary feeding ",
  "practice'. It is chosen for three reasons: it is exactly the top category of the four-level ",
  "variable, so the binary and the ordinal forms agree by construction; it is 78% of the attainable ",
  "maximum, the closest this scale comes to the 80% threshold Sheikh et al. (2026) use, which keeps ",
  "the thesis comparable to that paper; and it leaves ", sum(ybin), " events, enough to support ",
  "about ", sum(ybin) %/% 10, " predictor degrees of freedom at the conventional ten events per ",
  "variable. The 'limiting cell' is the smaller of the two outcome groups, which is what governs ",
  "the degrees-of-freedom budget. A lower cut would be better powered but has no external ",
  "precedent, so it belongs in a sensitivity analysis rather than as the reported prevalence. ",
  "DICHOTOMISING COSTS INFORMATION: the four-level ordinal form in Table 11 uses all ", N,
  " children without splitting them into events and non-events, and should carry the main analysis ",
  "wherever a reviewer will accept an ordinal model.")

# ----------------------------------------------------------
# 12. Table 13 - bivariate screen against the binary outcome
# ----------------------------------------------------------
biv_rows <- function(label, x, y) {
  ok <- !is.na(x); n <- sum(ok)
  if (is.numeric(x)) {
    pv <- suppressWarnings(wilcox.test(x[ok] ~ y[ok])$p.value)
    return(data.frame(
      Variable = label, n = n,
      `Appropriate` = sprintf("%.2f (%.2f)", mean(x[ok & y == 1]), sd(x[ok & y == 1])),
      `Inappropriate` = sprintf("%.2f (%.2f)", mean(x[ok & y == 0]), sd(x[ok & y == 0])),
      `Crude OR (95% CI)` = local({
        m <- glm(y[ok] ~ x[ok], family = binomial)
        ci <- suppressMessages(confint(m))
        sprintf("%.2f (%.2f-%.2f)", exp(coef(m)[2]), exp(ci[2,1]), exp(ci[2,2])) }),
      p = fmt_p(pv), check.names = FALSE, stringsAsFactors = FALSE))
  }
  f  <- droplevels(x[ok]); yy <- y[ok]
  pv <- p_cat(f, yy)
  head <- data.frame(Variable = label, n = n, Appropriate = "", Inappropriate = "",
                     `Crude OR (95% CI)` = "", p = fmt_p(pv),
                     check.names = FALSE, stringsAsFactors = FALSE)
  ref <- levels(f)[1]
  body <- do.call(rbind, lapply(levels(f), function(l) {
    m <- f == l
    or <- if (l == ref) "1.00 (reference)" else {
      tb <- table(factor(f %in% c(ref, l), c(FALSE, TRUE)), yy)
      sub <- f %in% c(ref, l)
      fit <- suppressWarnings(glm(yy[sub] ~ factor(f[sub], levels = c(ref, l)),
                                  family = binomial))
      ci <- suppressWarnings(suppressMessages(confint(fit)))
      if (any(!is.finite(ci[2, ])) || abs(coef(fit)[2]) > 10) "not estimable"
      else sprintf("%.2f (%.2f-%.2f)", exp(coef(fit)[2]), exp(ci[2,1]), exp(ci[2,2]))
    }
    data.frame(Variable = paste0("    ", l), n = sum(m),
               Appropriate   = np(sum(yy[m] == 1), sum(m)),
               Inappropriate = np(sum(yy[m] == 0), sum(m)),
               `Crude OR (95% CI)` = or, p = "",
               check.names = FALSE, stringsAsFactors = FALSE)
  }))
  rbind(head, body)
}

t13 <- do.call(rbind, lapply(CAND, function(v) biv_rows(v, d[[v]], ybin)))
ft13 <- mk_ft(t13) |> bold(i = which(!startsWith(t13$Variable, "    ")), j = 1)
sig13 <- which(t13$p != "" & (t13$p == "<0.001" |
                suppressWarnings(as.numeric(t13$p)) <= 0.25))
if (length(sig13)) ft13 <- bold(ft13, i = sig13, j = 6)

foot13 <- paste0(
  "Bivariate association between each candidate independent variable and appropriate complementary ",
  "feeding practice, defined as an IYCF practice score of ", BIN_CUT, " or more of 9. n = ", N,
  " with denominators varying where a variable has missing responses. For categorical variables the ",
  "Appropriate and Inappropriate columns are n (%) within each level of the variable, and the test ",
  "is Pearson's chi-squared, or Fisher's exact test with 20,000 Monte Carlo replicates where any ",
  "expected count falls below five. For continuous variables the two columns are mean (SD) within ",
  "each outcome group and the test is the Mann-Whitney U test. Crude odds ratios are unadjusted and ",
  "come from a logistic regression of the outcome on that variable alone, against the first listed ",
  "level as reference; 'not estimable' marks a level where an empty outcome cell drives the ",
  "estimate to infinity. Bold marks p <= 0.25, which is the threshold carried into the variable ",
  "selection in Table 14, following Sheikh et al. (2026). That threshold is deliberately loose: it ",
  "is a screen for the multivariable model, not a finding, and a variable reaching it here has not ",
  "been shown to be associated with anything. No adjustment is made for multiple comparisons and ",
  "none of these tests accounts for clustering within the 25 upazila recruitment sites.")

# ----------------------------------------------------------
# 13. Table 14 - variable selection
# ----------------------------------------------------------
rule("VARIABLE SELECTION")
pvals <- sapply(CAND, function(v) {
  x <- d[[v]]; ok <- !is.na(x)
  if (is.numeric(x)) suppressWarnings(wilcox.test(x[ok] ~ ybin[ok])$p.value)
  else p_cat(droplevels(x[ok]), ybin[ok])
})
passed <- names(pvals)[pvals <= 0.25 & !is.na(pvals)]
note("Step 1, bivariate p <= 0.25: ", length(passed), " of ", length(CAND), " pass")

# Step 2, multicollinearity.  car::vif returns a generalised VIF for factors;
# GVIF^(1/(2*df)) is the scale-comparable form, and squaring it puts it back on
# the ordinary VIF scale so the cut-off of 2 means the same thing for a factor
# as for a continuous variable.
sel_df <- d[, passed, drop = FALSE]
names(sel_df) <- make.names(names(sel_df))
sel_df$.y <- ybin
full_fm  <- as.formula(paste(".y ~", paste(names(sel_df)[names(sel_df) != ".y"],
                                           collapse = " + ")))
cc  <- complete.cases(sel_df)
note("Step 2, complete cases across the ", length(passed), " screened variables: ",
     sum(cc), " of ", N)
m_full <- suppressWarnings(glm(full_fm, data = sel_df[cc, ], family = binomial))
vif_raw <- car::vif(m_full)
if (is.matrix(vif_raw)) {
  vif_adj <- vif_raw[, 3]^2
  vif_g   <- vif_raw[, 1]
} else { vif_adj <- vif_raw; vif_g <- vif_raw }
names(vif_adj) <- passed; names(vif_g) <- passed
dropped_vif <- names(vif_adj)[vif_adj >= 2]
kept <- setdiff(passed, dropped_vif)
note("Step 3, VIF >= 2 removed: ",
     if (length(dropped_vif)) paste(dropped_vif, collapse = ", ") else "none")
note("Final model variables: ", length(kept))

t14 <- do.call(rbind, lapply(CAND, function(v) {
  p1 <- pvals[[v]]
  s1 <- if (!is.na(p1) && p1 <= 0.25) "Pass" else "Excluded"
  data.frame(
    Variable = v,
    `Bivariate p` = fmt_p(p1),
    `Step 1: p <= 0.25` = s1,
    `GVIF` = if (v %in% passed) sprintf("%.2f", vif_g[[v]]) else "-",
    `VIF (comparable)` = if (v %in% passed) sprintf("%.2f", vif_adj[[v]]) else "-",
    `Step 2: VIF < 2` = if (!v %in% passed) "-"
                        else if (v %in% dropped_vif) "Excluded" else "Pass",
    `In final model` = if (v %in% kept) "YES" else "no",
    check.names = FALSE, stringsAsFactors = FALSE)
}))
t14 <- t14[order(pvals[t14$Variable]), ]
ft14 <- mk_ft(t14) |> bold(i = which(t14$`In final model` == "YES"))
foot14 <- paste0(
  "Variable selection, following the procedure in Sheikh et al. (2026, Journal of Nutritional ",
  "Science 15: e50), which is the supervisor's own published analysis of the same indicators. Step ",
  "1 screens every candidate on its bivariate association with the outcome and retains those with ",
  "p <= 0.25; ", length(passed), " of ", length(CAND), " pass. Step 2 tests the retained set for ",
  "multicollinearity using the variance inflation factor with a cut-off of 2. Because most ",
  "candidates are categorical, car::vif returns a generalised VIF; the column 'VIF (comparable)' is ",
  "the square of GVIF^(1/(2 x df)), which puts a factor on the same scale as a continuous variable ",
  "so that one cut-off means the same thing for both, and it is the column the rule is applied to. ",
  if (length(dropped_vif))
    paste0("Removed at this step: ", paste(dropped_vif, collapse = ", "), ". ")
  else "No variable exceeded the cut-off. ",
  length(kept), " variables enter the final model in Table 15, fitted on the ", sum(cc),
  " children with complete data on all of them. Two cautions. The p <= 0.25 screen is applied to ",
  length(CAND), " tests with no correction, so it will admit some variables by chance; it is a ",
  "screen, not evidence. And selecting variables on the same data used to estimate the final model ",
  "makes the reported confidence intervals narrower and the p-values smaller than they should be, ",
  "which is a known cost of this procedure and applies equally to the published analysis it follows.")

# ----------------------------------------------------------
# 14. Table 15 - multivariable logistic regression
# ----------------------------------------------------------
rule("FINAL MODEL")
fit_fm <- as.formula(paste(".y ~", paste(make.names(kept), collapse = " + ")))
mdl_df <- d[, kept, drop = FALSE]; names(mdl_df) <- make.names(kept)
mdl_df$.y <- ybin
cc2 <- complete.cases(mdl_df)
m   <- suppressWarnings(glm(fit_fm, data = mdl_df[cc2, ], family = binomial))

# Separation check.  glm does NOT warn: it reports convergence and returns an
# odds ratio in the hundreds of thousands.  Detect it and refit with Firth.
co <- coef(m); se <- summary(m)$coefficients[, 2]
separated <- any(abs(co[-1]) > 10, na.rm = TRUE) || any(se > 10, na.rm = TRUE)
MDF <- length(coef(m)) - 1L
EPV <- sum(ybin[cc2]) / MDF
note("Fitted on ", sum(cc2), " complete cases, ", sum(ybin[cc2]), " events.")
note(sprintf("Model degrees of freedom: %d  ->  %.2f events per df", MDF, EPV))
if (EPV < 10)
  warning(sprintf(paste0("OVERFITTING: %.2f events per degree of freedom, against a ",
                         "conventional minimum of 10. The p <= 0.25 screen admits %d ",
                         "variables costing %d df, and there are only %d events. Table 16 ",
                         "gives the parsimonious alternative; report both."),
                  EPV, length(kept), MDF, sum(ybin[cc2])),
          call. = FALSE, immediate. = TRUE)
note("Max |coefficient| ", sprintf("%.2f", max(abs(co[-1]), na.rm = TRUE)),
     "  max SE ", sprintf("%.2f", max(se, na.rm = TRUE)))
if (separated) {
  note("SEPARATION DETECTED -> refitting with logistf (Firth penalisation).")
  mf  <- logistf::logistf(fit_fm, data = mdl_df[cc2, ])
  est <- exp(mf$coefficients); lo <- exp(mf$ci.lower); hi <- exp(mf$ci.upper)
  pv  <- mf$prob; nms <- names(mf$coefficients)
  METHOD <- "Firth penalised logistic regression (logistf)"
} else {
  note("No separation. Ordinary maximum-likelihood logistic regression used.")
  ci  <- suppressMessages(confint(m))
  est <- exp(co); lo <- exp(ci[, 1]); hi <- exp(ci[, 2])
  pv  <- summary(m)$coefficients[, 4]; nms <- names(co)
  METHOD <- "maximum-likelihood logistic regression (glm)"
}

# Map the model's term names back to readable labels, and insert the reference
# level of every factor so the table reads as a thesis table rather than as R
# output.
t15 <- do.call(rbind, lapply(kept, function(v) {
  x <- d[[v]]; safe <- make.names(v)
  if (is.numeric(x)) {
    i <- match(safe, nms)
    return(data.frame(Variable = paste0(v, " (per unit)"),
                      `Adjusted OR (95% CI)` = sprintf("%.2f (%.2f-%.2f)", est[i], lo[i], hi[i]),
                      p = fmt_p(pv[i]), check.names = FALSE, stringsAsFactors = FALSE))
  }
  lv <- levels(droplevels(x[cc2]))
  rbind(
    data.frame(Variable = v, `Adjusted OR (95% CI)` = "", p = "",
               check.names = FALSE, stringsAsFactors = FALSE),
    do.call(rbind, lapply(lv, function(l) {
      if (l == lv[1])
        return(data.frame(Variable = paste0("    ", l),
                          `Adjusted OR (95% CI)` = "1.00 (reference)", p = "",
                          check.names = FALSE, stringsAsFactors = FALSE))
      i <- match(paste0(safe, l), nms)
      data.frame(Variable = paste0("    ", l),
                 `Adjusted OR (95% CI)` =
                   if (is.na(i)) "-" else sprintf("%.2f (%.2f-%.2f)", est[i], lo[i], hi[i]),
                 p = if (is.na(i)) "-" else fmt_p(pv[i]),
                 check.names = FALSE, stringsAsFactors = FALSE)
    })))
}))
ft15 <- mk_ft(t15) |> bold(i = which(!startsWith(t15$Variable, "    ")), j = 1)
sig15 <- which(t15$p != "" & t15$p != "-" &
               (t15$p == "<0.001" | suppressWarnings(as.numeric(t15$p)) < 0.05))
if (length(sig15)) ft15 <- bold(ft15, i = sig15, j = 2:3)

mfit <- if (!separated)
  sprintf("Model chi-squared %.1f on %d df, p %s; Nagelkerke pseudo R-squared %.3f. ",
          m$null.deviance - m$deviance, m$df.null - m$df.residual,
          fmt_p(pchisq(m$null.deviance - m$deviance,
                       m$df.null - m$df.residual, lower.tail = FALSE)),
          (1 - exp((m$deviance - m$null.deviance) / sum(cc2))) /
            (1 - exp(-m$null.deviance / sum(cc2)))) else ""

foot15 <- paste0(
  "Multivariable ", METHOD, " for appropriate complementary feeding practice, an IYCF practice ",
  "score of ", BIN_CUT, " or more of 9. Fitted on ", sum(cc2), " children with complete data on ",
  "every model variable, of whom ", sum(ybin[cc2]), " had the outcome. Variables are those ",
  "surviving both selection steps in Table 14. Odds ratios are adjusted for every other variable ",
  "in the table, with the first listed level of each categorical variable as the reference. ",
  mfit,
  if (separated)
    paste0("Firth penalisation was used because at least one predictor separated the outcome; ",
           "ordinary logistic regression gives infinite or near-infinite estimates there, and ",
           "does so WITHOUT reporting a convergence failure. ")
  else
    paste0("No predictor separated the outcome, so ordinary maximum likelihood was used; this ",
           "was checked rather than assumed, because glm reports convergence even when a ",
           "coefficient has been driven to the hundreds of thousands. "),
  "Bold marks p < 0.05. Three limitations belong with this table. The model variables were chosen ",
  "using the same data that fitted it, so the intervals are narrower and the p-values smaller than ",
  "they should be. Nothing is adjusted for clustering within the 25 upazila recruitment sites, ",
  "which narrows the intervals further. And the design is cross-sectional, so nothing here ",
  "establishes direction: household dietary diversity and child feeding are measured from one ",
  "respondent in one sitting about the same 24 hours, which is exactly the situation in which ",
  "shared-method variance inflates an association.")

# ----------------------------------------------------------
# 14b. Table 16 - the parsimonious model
#      Table 15 follows the published procedure exactly and is overfitted on
#      this sample: the screen was designed for n = 873 with roughly 264
#      events, and here there are 79.  Backward elimination on Akaike's
#      information criterion, starting from the Table 15 model, gives a model
#      the data can actually support.  Both are reported, because dropping
#      Table 15 would hide the departure from the supervisor's method and
#      dropping Table 16 would present estimates nobody should trust.
# ----------------------------------------------------------
rule("PARSIMONIOUS MODEL")
m_red <- suppressWarnings(step(m, direction = "backward", trace = 0))
red_terms <- attr(terms(m_red), "term.labels")
kept_red  <- kept[make.names(kept) %in% red_terms]
MDF_R <- length(coef(m_red)) - 1L
EPV_R <- sum(ybin[cc2]) / MDF_R
note("Retained: ", paste(kept_red, collapse = ", "))
note(sprintf("Degrees of freedom %d -> %d;  events per df %.2f -> %.2f",
             MDF, MDF_R, EPV, EPV_R))

ci_r  <- suppressMessages(confint(m_red))
est_r <- exp(coef(m_red)); lo_r <- exp(ci_r[, 1]); hi_r <- exp(ci_r[, 2])
pv_r  <- summary(m_red)$coefficients[, 4]; nms_r <- names(coef(m_red))

t16 <- do.call(rbind, lapply(kept_red, function(v) {
  x <- d[[v]]; safe <- make.names(v)
  if (is.numeric(x)) {
    i <- match(safe, nms_r)
    return(data.frame(Variable = paste0(v, " (per unit)"),
                      `Adjusted OR (95% CI)` = sprintf("%.2f (%.2f-%.2f)",
                                                       est_r[i], lo_r[i], hi_r[i]),
                      p = fmt_p(pv_r[i]), check.names = FALSE, stringsAsFactors = FALSE))
  }
  lv <- levels(droplevels(x[cc2]))
  rbind(
    data.frame(Variable = v, `Adjusted OR (95% CI)` = "", p = "",
               check.names = FALSE, stringsAsFactors = FALSE),
    do.call(rbind, lapply(lv, function(l) {
      if (l == lv[1])
        return(data.frame(Variable = paste0("    ", l),
                          `Adjusted OR (95% CI)` = "1.00 (reference)", p = "",
                          check.names = FALSE, stringsAsFactors = FALSE))
      i <- match(paste0(safe, l), nms_r)
      data.frame(Variable = paste0("    ", l),
                 `Adjusted OR (95% CI)` =
                   if (is.na(i)) "-" else sprintf("%.2f (%.2f-%.2f)", est_r[i], lo_r[i], hi_r[i]),
                 p = if (is.na(i)) "-" else fmt_p(pv_r[i]),
                 check.names = FALSE, stringsAsFactors = FALSE)
    })))
}))
ft16 <- mk_ft(t16) |> bold(i = which(!startsWith(t16$Variable, "    ")), j = 1)
sig16 <- which(t16$p != "" & t16$p != "-" &
               (t16$p == "<0.001" | suppressWarnings(as.numeric(t16$p)) < 0.05))
if (length(sig16)) ft16 <- bold(ft16, i = sig16, j = 2:3)

foot16 <- paste0(
  "Parsimonious multivariable logistic regression for appropriate complementary feeding practice, ",
  "obtained by backward elimination on Akaike's information criterion starting from the Table 15 ",
  "model. Fitted on the same ", sum(cc2), " children and ", sum(ybin[cc2]), " events. ",
  "WHY THIS TABLE EXISTS: Table 15 follows the published selection procedure exactly, and on this ",
  "sample that procedure is overfitted. It admits ", length(kept), " variables costing ", MDF,
  " degrees of freedom against ", sum(ybin[cc2]), " events, which is ", sprintf("%.2f", EPV),
  " events per degree of freedom where the conventional minimum is ten. That is not a criticism of ",
  "the source paper, whose sample had roughly 264 events and could carry the screen comfortably; it ",
  "is a consequence of applying the same screen to a sample a fifth of the size. This model uses ",
  MDF_R, " degrees of freedom, or ", sprintf("%.2f", EPV_R), " events per degree of freedom. ",
  "Read the two tables together: a variable that is significant in both is a robust finding, and ",
  "one significant only in Table 15 should be treated as unstable. Backward elimination carries its ",
  "own costs, which apply here as much as anywhere: the standard errors and p-values do not account ",
  "for the selection, so they are optimistic, and the retained set can change with small changes to ",
  "the data. Nothing is adjusted for clustering within the 25 upazila recruitment sites, and the ",
  "design is cross-sectional so no estimate here establishes direction.")

# ----------------------------------------------------------
# 15. Export
# ----------------------------------------------------------
small    <- fp_text(font.size = 8, italic = TRUE)
add_foot <- function(dd, txt) body_add_fpar(dd, fpar(ftext(txt, small)))
add_tbl  <- function(dd, title, ft, foot)
  dd |>
    body_add_par(title, style = "heading 2") |>
    body_add_flextable(ft) |>
    add_foot(foot) |>
    body_add_par("")

doc <- read_docx() |>
  body_add_par("Chapter 4  Results", style = "heading 1") |>
  add_tbl("Table 1  Distribution of the study sample by administrative division and place of residence", ft1, foot1) |>
  add_tbl("Table 2  Household and socioeconomic characteristics of the study participants", ft2, foot2) |>
  add_tbl("Table 3  Characteristics of the children", ft3, foot3) |>
  add_tbl("Table 4  Maternal characteristics of the study participants", ft4, foot4) |>
  add_tbl("Table 5  Paternal characteristics of the study participants", ft5, foot5) |>
  add_tbl("Table 6  Maternal and child health service use", ft6, foot6) |>
  add_tbl("Table 7  Univariate distribution of all candidate independent variables", ft7, foot7) |>
  add_tbl("Table 8  Prevalence of the WHO/UNICEF infant and young child feeding indicators", ft8, foot8) |>
  add_tbl("Table 9  Construction of the IYCF practice score: components, grading and internal consistency", ft9, foot9) |>
  add_tbl("Table 10  Candidate index constructions compared, including the published method", ft10, foot10) |>
  body_add_par("Table 11  Distribution of the IYCF practice score and its four severity categories", style = "heading 2") |>
  body_add_flextable(ft11a) |> body_add_par("") |>
  body_add_flextable(ft11b) |> add_foot(foot11) |> body_add_par("") |>
  add_tbl("Table 12  Construction of the binary outcome", ft12, foot12) |>
  add_tbl("Table 13  Bivariate association between appropriate complementary feeding practice and each independent variable", ft13, foot13) |>
  add_tbl("Table 14  Variable selection procedure", ft14, foot14) |>
  add_tbl("Table 15  Multivariable logistic regression for appropriate complementary feeding practice", ft15, foot15) |>
  add_tbl("Table 16  Parsimonious multivariable logistic regression after backward elimination", ft16, foot16)

safe_write(print(doc, target = OUT_DOCX), OUT_DOCX)

rule("DONE")
note("Outcome -> 0-9 score (alpha ", sprintf("%.3f", alpha4), "), 4 categories, binary at >= ",
     BIN_CUT, ".")
note("Tables  -> ", OUT_DOCX, "  (1-16)")
note("Selected  -> ", paste(kept, collapse = ", "))
note("Parsimonious -> ", paste(kept_red, collapse = ", "))
safe_write(writeLines(LOG, OUT_LOG), OUT_LOG)
