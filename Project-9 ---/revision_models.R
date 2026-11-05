# =============================================================================
# Project 9 -- Breast & cervical cancer screening KAP among physicians, Rangpur
# Revision round 2: re-fit of the multivariable models (Reviewer 1, point 3)
# -----------------------------------------------------------------------------
# Data   : Data/model_data.RDS (written by analysis.Rmd; N = 414; outcomes
#          already dichotomised at the manuscript cut-offs; missing years since
#          graduation (n = 102) and department (n = 108) were filled in by
#          mice in analysis.Rmd -- completed dataset 5 of 5).
# Output : doc/Revised_Models_Tables5_6.docx  -- model output tables only
#          doc/revision_log.txt               -- running log of checks
#
# Reviewer 1, point 3: "Verify events per estimated parameter for each model,
# reassess the number of predictors if necessary, and confirm adjusted odds
# ratios, 95% confidence intervals, and model-fit reporting."
#
# Analytic decisions
#   1. The published Tables 5-6 are first reproduced exactly (8 covariates,
#      11 coefficients per model) so that EPV and fit can be reported for the
#      models as submitted.
#   2. Events = the smaller outcome category (poor knowledge; good practice).
#      EPV = events / number of estimated coefficients (intercept excluded).
#   3. Merged categories: age had two sparse upper groups (51-60, n = 35;
#      60+, n = 7) and is near-structurally confounded with years since
#      graduation (122 of the 124 physicians 6-10 years from graduation are
#      <=40; none are >50). Age is therefore collapsed to <=40 vs >40.
#      Years since graduation is kept at three levels: no level is sparse
#      (122 / 124 / 168) and collapsing it would be a data-driven choice.
#      The covariate set itself is unchanged (pre-specified, 8 variables),
#      giving 9 coefficients per model.
#   4. Estimation: maximum likelihood logistic regression; 95% CIs are
#      profile-likelihood intervals; p-values are Wald (as in the submission).
#   5. The two practice models still have EPV < 10 after merging, so they
#      are also fitted with Firth's penalized likelihood (Heinze & Schemper
#      2002), with profile penalized-likelihood CIs and penalized
#      likelihood-ratio p-values -- the same definitions as logistf. logistf
#      could not be installed in the build environment, so firth_logit()
#      below implements it; it is checked against a direct numerical
#      maximisation of the penalized likelihood, and against logistf
#      whenever that package is available.
#   6. Model fit, per model: likelihood-ratio chi-square vs the null model,
#      Nagelkerke R^2, AUC (DeLong 95% CI), Hosmer-Lemeshow (10 risk
#      deciles, df = g - 2) and the largest GVIF^(1/(2*df)) (comparable to
#      sqrt(VIF) -- reported alongside the plain VIF for binary terms).
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(flextable)
  library(officer)
  library(pROC)
  library(car)
  library(MASS)
})
select <- dplyr::select

log_file <- "doc/revision_log.txt"
cat("Project 9 -- revision model log --", format(Sys.time()), "\n\n", file = log_file)
logc <- function(...) {
  txt <- paste0(...)
  cat(txt, "\n")
  cat(txt, "\n", file = log_file, append = TRUE)
}
logp <- function(x) {
  out <- capture.output(print(x))
  cat(out, sep = "\n")
  cat(out, sep = "\n", file = log_file, append = TRUE)
}

# Windows locks files open in Word -- warn instead of aborting.
safe_print_docx <- function(doc, path) {
  ok <- tryCatch({ print(doc, target = path); TRUE },
                 error = function(e) { warning("Could not write ", path, ": ",
                                               conditionMessage(e)); FALSE })
  if (ok) logc("Written: ", path)
  invisible(ok)
}


# -----------------------------------------------------------------------------
# 1. Read
# -----------------------------------------------------------------------------
d0 <- readRDS("Data/model_data.RDS")
logc("Rows read: ", nrow(d0), "; missing in model data: ", sum(is.na(d0)))

outcomes <- c(know_breast   = "Good knowledge, breast",
              know_cervical = "Good knowledge, cervical",
              prac_breast   = "Good practice, breast",
              prac_cervical = "Good practice, cervical")


# -----------------------------------------------------------------------------
# 2. Analysis variables (explicit levels -> deterministic rows and references)
# -----------------------------------------------------------------------------
d <- d0 %>%
  mutate(
    age4  = factor(as.character(age), levels = c("<=40", "41-50", "51-60", "60+")),
    age2  = factor(ifelse(age == "<=40", "<=40", ">40"), levels = c("<=40", ">40")),
    Sex   = factor(as.character(Sex), levels = c("Male", "Female")),
    Family = factor(as.character(Family), levels = c("No", "Yes")),
    dgraduation = factor(as.character(dgraduation), levels = c("<6", "6-10", ">10")),
    dx_self_cancer = factor(as.character(dx_self_cancer), levels = c("No", "Yes")),
    know_ca_scrn = factor(as.character(know_ca_scrn), levels = c("No", "Yes")),
    att_ca_scrn  = factor(as.character(att_ca_scrn), levels = c("No", "Yes")),
    dept  = factor(as.character(dept), levels = c("Non Clinical", "Clinical")),
    across(all_of(names(outcomes)), ~ as.integer(.x == "Good"))
  )

logc("\nAge (4 groups) x years since graduation -- why age is collapsed:")
logp(table(Age = d$age4, Graduation = d$dgraduation))
logc("\nAge (merged) x years since graduation:")
logp(table(Age = d$age2, Graduation = d$dgraduation))

covs_orig <- c("age4", "Sex", "Family", "dgraduation", "dx_self_cancer",
               "know_ca_scrn", "att_ca_scrn", "dept")
covs_rev  <- replace(covs_orig, covs_orig == "age4", "age2")

make_fml <- function(y, covs) reformulate(covs, response = y)


# -----------------------------------------------------------------------------
# 3. Helper functions
# -----------------------------------------------------------------------------

## 3a. Hosmer-Lemeshow, g risk deciles (same as ResourceSelection::hoslem.test)
hosmer_lemeshow <- function(y, p, g = 10) {
  br  <- unique(quantile(p, probs = seq(0, 1, 1 / g)))
  grp <- cut(p, breaks = br, include.lowest = TRUE)
  o1 <- tapply(y, grp, sum); n <- tapply(y, grp, length); e1 <- tapply(p, grp, sum)
  chi <- sum((o1 - e1)^2 / e1 + ((n - o1) - (n - e1))^2 / (n - e1))
  df  <- nlevels(grp) - 2
  c(chisq = chi, df = df, p = pchisq(chi, df, lower.tail = FALSE))
}

## 3b. Firth penalized logistic regression with profile penalized-likelihood
##     CIs and penalized LR tests (definitions as in logistf).
firth_pl <- function(X, y, b) {
  eta <- drop(X %*% b)
  w   <- plogis(eta) * plogis(-eta)
  ll  <- sum(y * plogis(eta, log.p = TRUE) + (1 - y) * plogis(-eta, log.p = TRUE))
  ll + 0.5 * as.numeric(determinant(crossprod(X * sqrt(w)), logarithm = TRUE)$modulus)
}

firth_newton <- function(X, y, start, fixed = integer(0), maxit = 200, tol = 1e-9) {
  b <- start
  free <- setdiff(seq_len(ncol(X)), fixed)
  pl_old <- firth_pl(X, y, b)
  for (it in seq_len(maxit)) {
    eta <- drop(X %*% b); pr <- plogis(eta); w <- pr * (1 - pr)
    I   <- crossprod(X * sqrt(w))
    h   <- w * rowSums((X %*% solve(I)) * X)          # hat diagonal
    U   <- drop(crossprod(X, y - pr + h * (0.5 - pr)))  # Firth-modified score
    delta <- solve(I[free, free, drop = FALSE], U[free])
    if (max(abs(delta)) > 5) delta <- delta * 5 / max(abs(delta))
    step <- 1
    repeat {                                          # step halving
      b_new <- b; b_new[free] <- b[free] + step * delta
      pl_new <- firth_pl(X, y, b_new)
      if (pl_new >= pl_old - 1e-12 || step < 1e-6) break
      step <- step / 2
    }
    b <- b_new
    conv <- max(abs(step * delta)) < tol && max(abs(U[free])) < 1e-6
    pl_old <- pl_new
    if (conv) break
  }
  list(coef = b, pl = pl_old, converged = conv, iter = it)
}

firth_logit <- function(formula, data, level = 0.95) {
  mf <- model.frame(formula, data)
  X  <- model.matrix(formula, mf); y <- model.response(mf)
  fit <- firth_newton(X, y, start = rep(0, ncol(X)))
  b <- fit$coef; names(b) <- colnames(X)
  eta <- drop(X %*% b); w <- plogis(eta) * plogis(-eta)
  se  <- sqrt(diag(solve(crossprod(X * sqrt(w)))))
  crit <- qchisq(level, 1) / 2
  prof <- function(j, val) {
    st <- b; st[j] <- val
    firth_newton(X, y, start = st, fixed = j)$pl
  }
  res <- lapply(seq_along(b), function(j) {
    f <- function(v) prof(j, v) - (fit$pl - crit)
    lo_b <- b[j] - 2 * se[j]; while (f(lo_b) > 0) lo_b <- lo_b - 2 * se[j]
    hi_b <- b[j] + 2 * se[j]; while (f(hi_b) > 0) hi_b <- hi_b + 2 * se[j]
    lo <- uniroot(f, c(lo_b, b[j]), tol = 1e-8)$root
    hi <- uniroot(f, c(b[j], hi_b), tol = 1e-8)$root
    chi <- 2 * (fit$pl - prof(j, 0))
    c(lower = lo, upper = hi, p = pchisq(max(chi, 0), 1, lower.tail = FALSE))
  })
  res <- do.call(rbind, res)
  rownames(res) <- colnames(X)
  list(coef = b, se = se, lower = res[, "lower"], upper = res[, "upper"],
       p = res[, "p"], pl = fit$pl, converged = fit$converged, X = X, y = y)
}

## 3c. Fit statistics for one glm
fit_stats <- function(m, label, design) {
  y <- m$y; p <- fitted(m); n <- length(y)
  events <- min(sum(y), n - sum(y))
  k  <- length(coef(m)) - 1
  lr <- m$null.deviance - m$deviance
  r2 <- (1 - exp((m$deviance - m$null.deviance) / n)) / (1 - exp(-m$null.deviance / n))
  hl <- hosmer_lemeshow(y, p)
  rc <- suppressMessages(pROC::roc(y, p, ci = TRUE, direction = "<", quiet = TRUE))
  gv <- car::vif(m)
  gv_adj <- if (is.matrix(gv)) gv[, "GVIF^(1/(2*Df))"]^2 else gv  # back on VIF scale
  data.frame(
    Model = label, Design = design, N = n,
    Events = sprintf("%d (%s)", events, ifelse(sum(y) <= n - sum(y), "good", "poor")),
    Parameters = k, EPV = events / k,
    LR = sprintf("%.2f (%d), %s", lr, k, fmt_p(pchisq(lr, k, lower.tail = FALSE))),
    Nagelkerke = r2,
    AUC = sprintf("%.2f (%.2f\u2013%.2f)", rc$ci[2], rc$ci[1], rc$ci[3]),
    HL = sprintf("%.2f (%d), %s", hl["chisq"], hl["df"], fmt_p(hl["p"])),
    MaxVIF = max(gv_adj),
    check.names = FALSE
  )
}

fmt_p  <- function(p) ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
fmt_or <- function(x) ifelse(x > 1000, ">1000", ifelse(x < 0.001, "<0.001", sprintf("%.2f", x)))


# -----------------------------------------------------------------------------
# 4. Reproduce the submitted models (Tables 5-6 as published)
# -----------------------------------------------------------------------------
mods_orig <- lapply(names(outcomes), function(o)
  glm(make_fml(o, covs_orig), data = d, family = binomial))
names(mods_orig) <- names(outcomes)

logc("\nSubmitted models -- aORs reproduced (compare with manuscript Tables 5-6):")
logp(round(sapply(mods_orig, function(m) exp(coef(m))[-1]), 2))
logc("\nTable 6, cervical: the two aORs printed as 4.81 at 4 d.p. -> ",
     sprintf("%.4f", exp(coef(mods_orig$prac_cervical)["dgraduation6-10"])), " (6-10 y) and ",
     sprintf("%.4f", exp(coef(mods_orig$prac_cervical)["deptClinical"])), " (clinical): ",
     "a genuine coincidence of rounding, not a copy error.")


# -----------------------------------------------------------------------------
# 5. Revised models: merged age, same pre-specified covariates
# -----------------------------------------------------------------------------
mods_rev <- lapply(names(outcomes), function(o)
  glm(make_fml(o, covs_rev), data = d, family = binomial))
names(mods_rev) <- names(outcomes)
stopifnot(all(sapply(mods_rev, `[[`, "converged")))

ci_rev <- lapply(mods_rev, function(m) exp(suppressMessages(confint(m))))

stats_tab <- bind_rows(
  lapply(names(outcomes), function(o) fit_stats(mods_orig[[o]], outcomes[[o]], "Submitted")),
  lapply(names(outcomes), function(o) fit_stats(mods_rev[[o]],  outcomes[[o]], "Revised"))
)
logc("\nEvents per parameter and model fit:")
logp(stats_tab)

# Univariable p-values -- the manuscript Methods describe a p < 0.25 screen,
# but all eight covariates were entered in every model. Logged so the
# authors can see which variables that rule would have retained.
logc("\nUnivariable (LR test) p-values by outcome -- the p<0.25 screen described in Methods:")
uni_p <- sapply(names(outcomes), function(o) sapply(covs_rev, function(v) {
  m1 <- glm(make_fml(o, v), data = d, family = binomial)
  anova(m1, test = "LRT")[2, "Pr(>Chi)"]
}))
logp(round(uni_p, 3))


# -----------------------------------------------------------------------------
# 6. Firth penalized models for the practice outcomes (EPV < 10)
# -----------------------------------------------------------------------------
firth <- lapply(c("prac_breast", "prac_cervical"), function(o)
  firth_logit(make_fml(o, covs_rev), d))
names(firth) <- c("prac_breast", "prac_cervical")
stopifnot(all(sapply(firth, `[[`, "converged")))

# Check 1: estimates equal a direct numerical maximum of the penalized likelihood
for (o in names(firth)) {
  f <- firth[[o]]
  opt <- optim(rep(0, ncol(f$X)), function(b) -firth_pl(f$X, f$y, b),
               method = "BFGS", control = list(reltol = 1e-14, maxit = 1000))
  logc("Firth check (", o, "): max |Newton - optim| coefficient difference = ",
       signif(max(abs(opt$par - f$coef)), 3))
}
# Check 2: logistf, where installed (e.g. the analyst's Windows library)
if (requireNamespace("logistf", quietly = TRUE)) {
  for (o in names(firth)) {
    lf <- logistf::logistf(make_fml(o, covs_rev), data = d)
    logc("logistf check (", o, "): max |coef diff| = ",
         signif(max(abs(coef(lf) - firth[[o]]$coef)), 3),
         "; max |lower CI diff| = ", signif(max(abs(lf$ci.lower - firth[[o]]$lower)), 3))
  }
} else logc("logistf not installed -- check 2 skipped.")


# -----------------------------------------------------------------------------
# 7. Tables
# -----------------------------------------------------------------------------
var_labels <- c(
  age2 = "Age (years)", Sex = "Sex", Family = "Family history of cancer",
  dgraduation = "Years since graduation", dx_self_cancer = "Personal history of cancer",
  know_ca_scrn = "Aware of cancer screening", att_ca_scrn = "Believes cancer screening is useful",
  dept = "Department"
)
level_labels <- c("Non Clinical" = "Non-clinical", "<=40" = "≤40")

# Long data frame of rows for one model: variable header + one row per level
model_rows <- function(est, lo, hi, p) {
  rows <- list()
  for (v in covs_rev) {
    lv <- levels(d[[v]])
    rows[[length(rows) + 1]] <- data.frame(Variable = var_labels[[v]], type = "header",
                                           aOR = "", CI = "", P = "")
    for (i in seq_along(lv)) {
      nm <- paste0(v, lv[i]); lab <- ifelse(lv[i] %in% names(level_labels), level_labels[[lv[i]]], lv[i])
      if (i == 1) {
        rows[[length(rows) + 1]] <- data.frame(Variable = lab, type = "ref",
                                               aOR = "1 (Ref.)", CI = "", P = "")
      } else {
        rows[[length(rows) + 1]] <- data.frame(
          Variable = lab, type = "level", aOR = fmt_or(exp(est[nm])),
          CI = paste0(fmt_or(exp(lo[nm])), "–", fmt_or(exp(hi[nm]))),
          P = fmt_p(p[nm]))
      }
    }
  }
  do.call(rbind, rows)
}

glm_rows <- function(m, ci) {
  s <- summary(m)$coefficients
  model_rows(coef(m), log(ci[, 1]), log(ci[, 2]), s[, 4])
}
firth_rows <- function(f) model_rows(f$coef, f$lower, f$upper, f$p)

two_model_table <- function(r1, r2, caption, footnote, n1, n2) {
  tab <- data.frame(Variable = r1$Variable,
                    a1 = r1$aOR, c1 = r1$CI, p1 = r1$P,
                    a2 = r2$aOR, c2 = r2$CI, p2 = r2$P)
  hdr <- which(r1$type == "header")
  lvl <- which(r1$type != "header")
  ft <- flextable(tab) %>%
    set_header_labels(Variable = "Variables", a1 = "aOR", c1 = "95% CI", p1 = "p-value",
                      a2 = "aOR", c2 = "95% CI", p2 = "p-value") %>%
    add_header_row(values = c("", n1, n2), colwidths = c(1, 3, 3)) %>%
    set_caption(caption) %>%
    bold(i = hdr, j = 1, part = "body") %>%
    padding(i = lvl, j = 1, padding.left = 14, part = "body") %>%
    bold(part = "header") %>%
    align(j = 2:7, align = "center", part = "all") %>%
    border_remove() %>%
    hline_top(border = fp_border(width = 1.2), part = "header") %>%
    hline(i = 1, j = 2:7, border = fp_border(width = 0.6), part = "header") %>%
    hline_bottom(border = fp_border(width = 1.2), part = "header") %>%
    hline_bottom(border = fp_border(width = 1.2), part = "body") %>%
    add_footer_lines(footnote) %>%
    font(fontname = "Times New Roman", part = "all") %>%
    fontsize(size = 10, part = "header") %>%
    fontsize(size = 9.5, part = "body") %>%
    fontsize(size = 8, part = "footer") %>%
    padding(padding.top = 0.5, padding.bottom = 0.5, part = "all") %>%
    line_spacing(space = 1, part = "all") %>%
    width(j = 1, width = 2.2) %>% width(j = c(2, 4, 5, 7), width = 0.6) %>%
    width(j = c(3, 6), width = 0.95)
  ft
}

events_txt <- function(o) {
  s <- stats_tab[stats_tab$Model == outcomes[[o]] & grepl("Revised", stats_tab$Design), ]
  sprintf("%s, EPV %.1f", s$Events, s$EPV)
}
fit_txt <- function(o) {
  m  <- mods_rev[[o]]
  s  <- stats_tab[stats_tab$Model == outcomes[[o]] & grepl("Revised", stats_tab$Design), ]
  hl <- hosmer_lemeshow(m$y, fitted(m))
  sprintf("Hosmer\u2013Lemeshow \u03c7\u00b2 = %.2f, df = %d, p = %s; Nagelkerke R\u00b2 = %.2f; AUC = %s",
          hl["chisq"], hl["df"], fmt_p(hl["p"]), s$Nagelkerke, s$AUC)
}

common_foot <- c(
  "aOR = adjusted odds ratio; CI = confidence interval; Ref. = reference category; EPV = events per estimated parameter.",
  "All variables shown were entered simultaneously (9 estimated coefficients per model). Age was collapsed to ≤40 vs >40 years because the 51–60 (n = 35) and >60 (n = 7) groups were sparse and almost entirely overlapped with years since graduation."
)

t5 <- two_model_table(
  glm_rows(mods_rev$know_breast, ci_rev$know_breast),
  glm_rows(mods_rev$know_cervical, ci_rev$know_cervical),
  caption = "Table 5: Factors associated with good knowledge regarding breast and cervical cancer screening among physicians: multivariable logistic regression (N = 414)",
  footnote = c(common_foot,
    "Multivariable logistic regression (maximum likelihood); 95% CIs are profile-likelihood intervals; p-values are Wald tests.",
    paste0("Breast cancer model: ", events_txt("know_breast"), "; ", fit_txt("know_breast"), "."),
    paste0("Cervical cancer model: ", events_txt("know_cervical"), "; ", fit_txt("know_cervical"), ".")),
  n1 = "Breast Cancer", n2 = "Cervical Cancer")

t6 <- two_model_table(
  glm_rows(mods_rev$prac_breast, ci_rev$prac_breast),
  glm_rows(mods_rev$prac_cervical, ci_rev$prac_cervical),
  caption = "Table 6: Factors associated with good practice regarding breast and cervical cancer screening among physicians: multivariable logistic regression (N = 414)",
  footnote = c(common_foot,
    "Multivariable logistic regression (maximum likelihood); 95% CIs are profile-likelihood intervals; p-values are Wald tests.",
    paste0("Breast cancer model: ", events_txt("prac_breast"), "; ", fit_txt("prac_breast"), "."),
    paste0("Cervical cancer model: ", events_txt("prac_cervical"), "; ", fit_txt("prac_cervical"), "."),
    "Because EPV was below 10 in both practice models, estimates were confirmed with Firth penalized logistic regression (Supplementary Table S2)."),
  n1 = "Breast Cancer", n2 = "Cervical Cancer")

ts2 <- two_model_table(
  firth_rows(firth$prac_breast), firth_rows(firth$prac_cervical),
  caption = "Supplementary Table S2: Sensitivity analysis — factors associated with good screening practice estimated by Firth penalized logistic regression (N = 414)",
  footnote = c(common_foot,
    "Firth's penalized-likelihood logistic regression, which reduces the small-sample bias of maximum-likelihood odds ratios when events per parameter are few. 95% CIs are profile penalized-likelihood intervals; p-values are penalized likelihood-ratio tests."),
  n1 = "Breast Cancer", n2 = "Cervical Cancer")

# Table S1: EPV and model fit, submitted vs revised
s1 <- stats_tab %>%
  mutate(EPV = sprintf("%.1f", EPV), Nagelkerke = sprintf("%.2f", Nagelkerke),
         MaxVIF = sprintf("%.2f", MaxVIF)) %>%
  select(Model, Design, N, Events, Parameters, EPV, LR, Nagelkerke, AUC, HL, MaxVIF)
s1 <- s1[order(match(s1$Model, outcomes), s1$Design != "Submitted"), ]
ts1 <- flextable(s1) %>%
  set_header_labels(Model = "Outcome", Design = "Model", N = "N", Events = "Events",
                    Parameters = "Parameters", EPV = "EPV",
                    LR = "LR χ² (df), p", Nagelkerke = "Nagelkerke R²",
                    AUC = "AUC (95% CI)", HL = "Hosmer–Lemeshow χ² (df), p",
                    MaxVIF = "Largest VIF") %>%
  merge_v(j = "Model") %>% valign(j = 1, valign = "top") %>%
  set_caption("Supplementary Table S1: Events per estimated parameter and model-fit statistics for the submitted and revised multivariable models") %>%
  bold(part = "header") %>%
  align(j = 3:11, align = "center", part = "all") %>%
  font(fontname = "Times New Roman", part = "all") %>%
  fontsize(size = 9, part = "all") %>%
  padding(padding.top = 1, padding.bottom = 1, part = "all") %>%
  border_remove() %>%
  hline_top(border = fp_border(width = 1.2), part = "header") %>%
  hline_bottom(border = fp_border(width = 1.2), part = "header") %>%
  hline(i = seq(2, nrow(s1), 2), border = fp_border(width = 0.5), part = "body") %>%
  hline_bottom(border = fp_border(width = 1.2), part = "body") %>%
  add_footer_lines(c(
    "Events = the smaller outcome category (poor knowledge for the knowledge models, good practice for the practice models). EPV = events per estimated parameter (intercept excluded); ≥10 is the conventional minimum.",
    "Submitted: age in four groups (11 parameters). Revised: age ≤40 vs >40 years (9 parameters); all other covariates unchanged.",
    "LR χ² = likelihood-ratio test of the model against the intercept-only model. AUC = area under the ROC curve (DeLong 95% CI). Hosmer–Lemeshow test on deciles of predicted risk; p > 0.05 indicates no evidence of lack of fit.",
    "Largest VIF = largest variance inflation factor across covariates (generalised VIF, GVIF^(1/(2·df)) squared, for the multi-level term)."
  )) %>%
  font(fontname = "Times New Roman", part = "all") %>%
  fontsize(size = 8, part = "footer") %>%
  width(j = 1, width = 1.2) %>% width(j = 2, width = 0.8) %>%
  width(j = c(3, 6), width = 0.45) %>% width(j = c(4, 5, 8), width = 0.8) %>%
  width(j = c(7, 10), width = 1.15) %>% width(j = 9, width = 1.05) %>% width(j = 11, width = 0.6)


# -----------------------------------------------------------------------------
# 8. Write model-output document
# -----------------------------------------------------------------------------
portrait  <- prop_section(page_size = page_size(orient = "portrait"), type = "nextPage")
landscape <- prop_section(page_size = page_size(orient = "landscape"), type = "nextPage")

doc <- read_docx() %>%
  body_add_fpar(fpar(ftext("Revised multivariable models — response to Reviewer 1, point 3",
                           fp_text(bold = TRUE, font.size = 13, font.family = "Times New Roman")))) %>%
  body_add_flextable(t5) %>%
  body_add_par("") %>%
  body_add_break() %>%
  body_add_flextable(t6) %>%
  body_add_par("") %>%
  body_end_block_section(block_section(portrait)) %>%
  body_add_flextable(ts1) %>%
  body_add_par("") %>%
  body_end_block_section(block_section(landscape)) %>%
  body_add_flextable(ts2)

safe_print_docx(doc, "doc/Revised_Models_Tables5_6.docx")


# -----------------------------------------------------------------------------
# 9. Objects for the response letter
# -----------------------------------------------------------------------------
saveRDS(list(stats = stats_tab, mods_orig = mods_orig, mods_rev = mods_rev,
             ci_rev = ci_rev, firth = lapply(firth, function(f) f[c("coef", "lower", "upper", "p")]),
             uni_p = uni_p),
        "Data/revision_models.RDS")
logc("\nDone.")
