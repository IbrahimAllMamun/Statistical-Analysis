# =============================================================================
# Project 9 -- Point-wise response to Reviewer 1 (revision round 2)
# -----------------------------------------------------------------------------
# Input  : Data/revision_models.RDS (written by revision_models.R -- run that
#          first); Data/data_with_score.RDS for raw missingness counts.
# Output : Manuscript/Response_to_Reviewer1.docx
#
# Every number quoted in the letter is pulled from the fitted model objects,
# so re-running revision_models.R and then this script keeps the letter in
# step with the tables. Text in [[double brackets]] is information only the
# authors hold; it is printed highlighted in yellow for them to complete.
# The final section ("Notes for the authors") is not for submission.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(flextable)
  library(officer)
})

# -----------------------------------------------------------------------------
# 1. Read model results
# -----------------------------------------------------------------------------
res <- readRDS("Data/revision_models.RDS")
raw <- readRDS("Data/data_with_score.RDS")
st  <- res$stats

n_miss_grad <- sum(is.na(raw$dgraduation))
n_miss_dept <- sum(is.na(raw$dept))
N <- nrow(raw)


# -----------------------------------------------------------------------------
# 2. Formatting helpers
# -----------------------------------------------------------------------------
fmt_p_txt <- function(p) ifelse(p < 0.001, "p < 0.001", sprintf("p = %.3f", p))
f2 <- function(x) sprintf("%.2f", x)

or_txt <- function(o, term) {
  m <- res$mods_rev[[o]]; ci <- res$ci_rev[[o]]
  p <- summary(m)$coefficients[term, 4]
  sprintf("aOR %s, 95%% CI %s–%s, %s", f2(exp(coef(m)[term])), f2(ci[term, 1]),
          f2(ci[term, 2]), fmt_p_txt(p))
}
firth_txt <- function(o, term) {
  f <- res$firth[[o]]
  sprintf("aOR %s, 95%% CI %s–%s, %s", f2(exp(f$coef[term])), f2(exp(f$lower[term])),
          f2(exp(f$upper[term])), fmt_p_txt(f$p[term]))
}
aor <- function(o, term) f2(exp(coef(res$mods_rev[[o]])[term]))

srow <- function(model, design) st[st$Model == model & st$Design == design, ]
epv  <- function(model, design) sprintf("%.1f", srow(model, design)$EPV)

base_font <- fp_text(font.family = "Times New Roman", font.size = 11)
ital_font <- update(base_font, italic = TRUE)
bold_font <- update(base_font, bold = TRUE)
hl_font   <- update(base_font, shading.color = "yellow")

# Paragraph from a string; [[...]] -> yellow highlight, **...** -> bold
para <- function(x, font = base_font) {
  parts <- regmatches(x, gregexpr("\\[\\[.*?\\]\\]|\\*\\*.*?\\*\\*", x), invert = NA)[[1]]
  chunks <- lapply(parts[parts != ""], function(s) {
    if (grepl("^\\[\\[", s)) ftext(gsub("^\\[\\[|\\]\\]$", "", s), update(font, shading.color = "yellow"))
    else if (grepl("^\\*\\*", s)) ftext(gsub("^\\*\\*|\\*\\*$", "", s), update(font, bold = TRUE))
    else ftext(s, font)
  })
  do.call(fpar, c(chunks, list(fp_p = fp_par(padding.bottom = 6, line_spacing = 1.15))))
}
quote_par <- function(x) {
  p <- para(x, ital_font)
  p$fp_p <- fp_par(padding.left = 18, padding.bottom = 6, line_spacing = 1.15)
  p
}
heading <- function(x, size = 12) {
  fpar(ftext(x, update(bold_font, font.size = size)),
       fp_p = fp_par(padding.top = 10, padding.bottom = 4))
}
bullet <- function(x) {
  p <- para(paste0("•  ", x))
  p$fp_p <- fp_par(padding.left = 18, padding.bottom = 3, line_spacing = 1.15)
  p
}
add <- function(doc, ...) { for (p in list(...)) doc <- body_add_fpar(doc, p); doc }


# -----------------------------------------------------------------------------
# 3. EPV / fit table for the letter
# -----------------------------------------------------------------------------
lt <- st %>%
  mutate(EPV = sprintf("%.1f", EPV), Nagelkerke = sprintf("%.2f", Nagelkerke),
         MaxVIF = sprintf("%.2f", MaxVIF)) %>%
  select(Model, Design, Events, Parameters, EPV, HL, Nagelkerke, AUC, MaxVIF)
lt <- lt[order(match(lt$Model, unique(st$Model)), lt$Design != "Submitted"), ]
letter_tab <- flextable(lt) %>%
  set_header_labels(Model = "Outcome", Design = "Model", Events = "Events",
                    Parameters = "k", EPV = "EPV",
                    HL = "Hosmer–Lemeshow χ² (df), p",
                    Nagelkerke = "R²", AUC = "AUC (95% CI)",
                    MaxVIF = "Max VIF") %>%
  merge_v(j = "Model") %>% valign(j = 1, valign = "top") %>%
  bold(part = "header") %>%
  align(j = 3:9, align = "center", part = "all") %>%
  border_remove() %>%
  hline_top(border = fp_border(width = 1.2), part = "header") %>%
  hline_bottom(border = fp_border(width = 1.2), part = "header") %>%
  hline(i = seq(2, nrow(lt), 2), border = fp_border(width = 0.5), part = "body") %>%
  hline_bottom(border = fp_border(width = 1.2), part = "body") %>%
  add_footer_lines("Events = smaller outcome category; k = estimated parameters; EPV = events per parameter; R² = Nagelkerke R²; Max VIF = largest variance inflation factor. Submitted: age in four groups; Revised: age ≤40 vs >40 years.") %>%
  font(fontname = "Times New Roman", part = "all") %>%
  fontsize(size = 8.5, part = "all") %>% fontsize(size = 8, part = "footer") %>%
  padding(padding.top = 0.5, padding.bottom = 0.5, part = "all") %>%
  width(j = 1, width = 0.95) %>% width(j = 2, width = 0.7) %>%
  width(j = 3, width = 0.72) %>% width(j = 4, width = 0.3) %>% width(j = c(5, 7), width = 0.42) %>%
  width(j = 6, width = 1.1) %>% width(j = 8, width = 1.05) %>% width(j = 9, width = 0.5) %>%
  set_table_properties(layout = "fixed")


# -----------------------------------------------------------------------------
# 4. Letter text
# -----------------------------------------------------------------------------
KB <- "Good knowledge, breast"; KC <- "Good knowledge, cervical"
PB <- "Good practice, breast";  PC <- "Good practice, cervical"

doc <- read_docx() %>%
  add(heading("Response to Reviewer 1", 14),
      para("**Manuscript:** Knowledge, Attitudes, and Practices Regarding Breast and Cervical Cancer Screening Among Physicians in Tertiary Care Hospitals of Rangpur, Bangladesh: A Cross-Sectional Study"),
      para("We thank the reviewer for the careful second reading of our manuscript and for the constructive comments. Each comment is reproduced below in italics, followed by our response and the corresponding change to the manuscript. Changes are shown in the tracked version of the revised manuscript."))

## ---- Point 1 ----------------------------------------------------------------
doc <- doc %>% add(
  heading("Comment 1 — Questionnaire methodology"),
  quote_par("Questionnaire development, expert validation, pilot testing, test–retest reliability, sample size, and the time interval used for reliability assessment requires a little more detail."),
  para("**Response:** Thank you. We have expanded Section 2.3 (Data collection instrument) to describe each step of questionnaire development and validation in more detail. The revised text reads:"),
  quote_par("“The questionnaire was developed by the investigators after a review of published KAP surveys on cancer screening and national screening guidance, and was adapted to the Bangladesh context, where cervical cancer screening is largely delivered through VIA-based services and breast cancer early detection relies on clinical breast examination (CBE) and referral pathways. [[Content validity was assessed by a panel of N experts (e.g., n oncologists, n gynaecologists, n public health specialists), who rated each item for relevance and clarity; items were revised or removed accordingly (item-level CVI / S-CVI = x.xx, if calculated).]] The questionnaire was pilot-tested among 20 physicians [[from <setting>, who were not included in the final sample]] to assess clarity, comprehensibility, and applicability of the items, and [[describe the main refinements, e.g., rewording of n items]] were made before the final survey. Internal consistency was good (Cronbach’s α = 0.78 [[for the knowledge items / whole instrument]]). Test–retest reliability was assessed by re-administering the questionnaire to [[n]] physicians after an interval of [[n days/weeks]]; agreement was summarised using Cohen’s kappa ([[mean item-level]] κ = 0.82), indicating good reliability.”"),
  para("Sample size: the calculation is reported in Section 2.2 (single-proportion formula, p = 0.50, 95% confidence, 5% margin of error, minimum n = 384). A census of all 430 eligible physicians was attempted and 414 participated (response rate 96.3%). We have additionally stated that the sample was not powered for the multivariable models, and refer the reader to the events-per-parameter assessment added in response to Comment 3.")
)

## ---- Point 2 ----------------------------------------------------------------
doc <- doc %>% add(
  heading("Comment 2 — Scoring criteria"),
  quote_par("How knowledge, attitude, and practice scores were calculated, justify the cut-offs used, and specify how inapplicable personal screening questions were handled. This require little more explanation."),
  para("**Response:** Thank you. We have revised Section 2.4 so that each score, its items, its cut-off and its justification are stated once and explicitly. We have also added a supplementary table listing every scored item and its scoring rule."),
  bullet("**Knowledge (0–5 for each cancer).** One point for each of: awareness of screening; correct age to start screening (breast ≥25 years; cervical ≥21 years); correct screening interval; recognition that the cancer can be detected early by screening; and knowledge of the screening modalities (BSE/CBE/mammography; VIA/Pap/HPV-DNA). Incorrect and “don’t know” responses scored 0. Good knowledge was defined as ≥3/5 (≥60%), following the modified Bloom’s cut-off widely used in KAP studies [[add citation]]."),
  bullet("**Attitude.** Attitude was assessed with single items (belief that screening is useful, and that the cancer can be detected early), reported descriptively. The “belief that screening is useful” item was used as an explanatory variable in the regression models. Attitude was not combined into a composite score, and no cut-off was applied."),
  bullet("**Practice (breast 0–8; cervical 0–6).** One point for each of: having undergone the screening test personally and at the recommended interval (breast: BSE/CBE and mammography, 4 items; cervical: VIA/Pap/HPV-DNA, 2 items); having advised family members to be screened, and at the correct interval (2 items); and having advised patients to be screened, and at the correct interval (2 items). An interval item scored 0 when the corresponding behaviour was not reported. Good practice was defined as ≥4/8 (breast) and ≥3/6 (cervical), i.e. at least half of the attainable points. [[State the basis for the 50% threshold, e.g., the source instrument or prior study, with citation.]]"),
  bullet("**Inapplicable personal screening items.** The questionnaire offered no “not applicable” option, and every respondent answered all personal screening items (yes/no). Personal screening items that were not applicable to the respondent (for example, because of sex or age) were therefore scored 0, i.e. treated as “not performed”. Because this lowers the attainable practice score for those respondents, we have added this explicitly to the Methods and to the Limitations, and we interpret the practice score as a composite of personal and professional screening-related behaviour (see Comment 4).")
)

## ---- Point 3 ----------------------------------------------------------------
doc <- doc %>% add(
  heading("Comment 3 — Regression analysis"),
  quote_par("Verify events per estimated parameter for each model, reassess the number of predictors if necessary, and confirm adjusted odds ratios, 95% confidence intervals, and model-fit reporting."),
  para("**Response:** We thank the reviewer for this important point. We re-examined all four multivariable models (good knowledge and good practice, for breast and cervical cancer) as follows."),
  para(sprintf(paste0(
    "**(a) Events per estimated parameter.** Events were defined as the smaller outcome category (poor knowledge in the knowledge models; good practice in the practice models). In the submitted models, age was entered in four categories, giving 11 estimated parameters per model. ",
    "EPV was therefore %s (breast knowledge, %s events) and %s (cervical knowledge, %s events) for the knowledge models, but only %s (breast practice, %s events) and %s (cervical practice, %s events) for the practice models, below the conventional minimum of 10."),
    epv(KB, "Submitted"), sub(" .*", "", srow(KB, "Submitted")$Events),
    epv(KC, "Submitted"), sub(" .*", "", srow(KC, "Submitted")$Events),
    epv(PB, "Submitted"), sub(" .*", "", srow(PB, "Submitted")$Events),
    epv(PC, "Submitted"), sub(" .*", "", srow(PC, "Submitted")$Events)))
)

doc <- doc %>% add(
  para(sprintf(paste0(
    "**(b) Reassessment of predictors.** The two oldest age groups were sparse (51–60 years, n = %d; >60 years, n = %d), and age overlapped almost completely with years since graduation (%d of the %d physicians 6–10 years after graduation were aged ≤40 years, and none were older than 50). We therefore merged age into two categories (≤40 vs >40 years), which reduced each model to 9 estimated parameters. ",
    "Years since graduation was kept in three categories because none of its categories was sparse. The covariate set was otherwise unchanged. EPV in the revised models is %s and %s for the knowledge models and %s and %s for the practice models. Because EPV remained below 10 for the practice models, we refitted both practice models using Firth’s penalized-likelihood logistic regression, which reduces the small-sample bias of maximum-likelihood odds ratios (Heinze & Schemper, 2002). The penalized estimates led to the same conclusions as the maximum-likelihood estimates (new Supplementary Table S2)."),
    as.integer(table(res$mods_orig$know_breast$model$age4)["51-60"]),
    as.integer(table(res$mods_orig$know_breast$model$age4)["60+"]),
    sum(res$mods_orig$know_breast$model$age4 == "<=40" & res$mods_orig$know_breast$model$dgraduation == "6-10"),
    sum(res$mods_orig$know_breast$model$dgraduation == "6-10"),
    epv(KB, "Revised"), epv(KC, "Revised"), epv(PB, "Revised"), epv(PC, "Revised"))),
  para(sprintf(paste0(
    "**(c) Confirmation of aORs, 95%% CIs and model fit.** All estimates were re-computed from the analysis dataset. Tables 5 and 6 now report adjusted odds ratios (aOR) with profile-likelihood 95%% CIs, and the term “aOR” is used consistently in the Abstract, Results and tables. ",
    "The submitted Methods reported a single Hosmer–Lemeshow p-value (p = 0.42); this value referred to the breast-knowledge model only (p = %s). Model fit is now reported separately for each of the four models (Hosmer–Lemeshow test, Nagelkerke R² and AUC) in the footnotes of Tables 5 and 6 and in new Supplementary Table S1, reproduced below. ",
    "None of the Hosmer–Lemeshow tests indicated lack of fit (all p ≥ %s). The largest variance inflation factor was %s, indicating no problematic multicollinearity."),
    sub(".*, ", "", srow(KB, "Submitted")$HL),
    sprintf("%.3f", min(as.numeric(sub(".*, ", "", st$HL[st$Design == "Revised"])))),
    sprintf("%.2f", max(st$MaxVIF[st$Design == "Revised"]))))
)
doc <- doc %>% body_add_flextable(letter_tab) %>% body_add_par("")

doc <- doc %>% add(
  para(sprintf(paste0(
    "Merging the age categories did not change any substantive finding. For good knowledge, the belief that screening is useful remained the strongest factor for both breast (%s) and cervical cancer (%s), and awareness of screening remained associated with breast cancer knowledge (%s). ",
    "Female sex, previously borderline for cervical knowledge (p = 0.052), now reaches conventional significance (%s); we describe this as a weak association. ",
    "For good practice, family history (%s) and personal history of cancer (%s) remained associated with breast screening practice (Firth: %s and %s). For cervical screening practice, 6–10 years since graduation (%s) and working in a clinical department (%s) remained associated (Firth: %s and %s). The wide interval for the department estimate reflects the small number of non-clinical physicians with good cervical practice; we now note this in the Results."),
    or_txt("know_breast", "att_ca_scrnYes"), or_txt("know_cervical", "att_ca_scrnYes"),
    or_txt("know_breast", "know_ca_scrnYes"), or_txt("know_cervical", "SexFemale"),
    or_txt("prac_breast", "FamilyYes"), or_txt("prac_breast", "dx_self_cancerYes"),
    firth_txt("prac_breast", "FamilyYes"), firth_txt("prac_breast", "dx_self_cancerYes"),
    or_txt("prac_cervical", "dgraduation6-10"), or_txt("prac_cervical", "deptClinical"),
    firth_txt("prac_cervical", "dgraduation6-10"), firth_txt("prac_cervical", "deptClinical"))),
  para(sprintf(
    "We also note, in the interest of transparency, that the breast-practice model as a whole had limited explanatory power (likelihood-ratio test against the null model %s; Nagelkerke R² = %.2f; AUC = %s). We now present the associations in this model as exploratory, both in the Results and in the Limitations.",
    sub(".*\\), ", "p = ", srow(PB, "Revised")$LR) %>% sub("p = <", "p < ", .),
    srow(PB, "Revised")$Nagelkerke, srow(PB, "Revised")$AUC)),
  para("**Revised Section 2.5 (Statistical analysis)** — the regression part now reads:"),
  quote_par(sprintf(paste0(
    "“Data were analysed in [[R version 4.x (R Foundation for Statistical Computing, Vienna, Austria)]]. Missing values for years since graduation (n = %d, %.1f%%) and department (n = %d, %.1f%%) were imputed by multiple imputation by chained equations (mice package; logistic and polytomous regression models). ",
    "Associations with good knowledge and good practice were examined using multivariable logistic regression. Eight explanatory variables were specified a priori (age, sex, family history of cancer, years since graduation, personal history of cancer, awareness of cancer screening, belief that screening is useful, and department) and were entered simultaneously into each of the four models. ",
    "Age was categorised as ≤40 vs >40 years because the older age groups were sparse. Each model therefore estimated 9 parameters; events per parameter (EPV) were %s and %s for the breast and cervical knowledge models and %s and %s for the breast and cervical practice models. ",
    "Because EPV was below 10 in the practice models, these models were also fitted using Firth’s penalized-likelihood logistic regression as a sensitivity analysis. Results are presented as adjusted odds ratios (aOR) with profile-likelihood 95%% confidence intervals. ",
    "Multicollinearity was assessed with the variance inflation factor (VIF; values <5 were considered acceptable). Model fit was assessed for each model with the Hosmer–Lemeshow goodness-of-fit test, Nagelkerke R² and the area under the ROC curve (AUC). A two-sided p < 0.05 was considered statistically significant.”"),
    n_miss_grad, 100 * n_miss_grad / N, n_miss_dept, 100 * n_miss_dept / N,
    epv(KB, "Revised"), epv(KC, "Revised"), epv(PB, "Revised"), epv(PC, "Revised"))),
  para(sprintf("The Results paragraphs for Tables 5 and 6 and the Abstract have been updated with the revised estimates. The Abstract now reports adjusted odds ratios: “Belief in screening usefulness predicted good knowledge (aOR %s and %s). Breast screening practice was more common among those with a family or personal history of cancer (aOR %s and %s). Cervical screening practice was associated with 6–10 years since graduation (aOR %s) and clinical work (aOR %s).”",
    aor("know_breast", "att_ca_scrnYes"), aor("know_cervical", "att_ca_scrnYes"),
    aor("prac_breast", "FamilyYes"), aor("prac_breast", "dx_self_cancerYes"),
    aor("prac_cervical", "dgraduation6-10"), aor("prac_cervical", "deptClinical")))
)

## ---- Point 4 ----------------------------------------------------------------
doc <- doc %>% add(
  heading("Comment 4 — Interpretation of results"),
  quote_par("Improve interpretation of results: Clarify that practice scores combine personal screening behaviour and professional counselling activities."),
  para("**Response:** We agree. Throughout the Results and Discussion, “practice” is now described as “screening-related practice”. We state explicitly that the score combines the physician’s own screening behaviour (personal items) with screening advice given to family members and patients (professional counselling items). We added the following to the first paragraph of the Discussion:"),
  quote_par("“The practice score used in this study is a composite of physicians’ personal screening behaviour and their screening-related counselling of family members and patients. A low practice score may therefore reflect limited personal screening uptake, limited counselling activity, or both. It should not be interpreted as a measure of professional counselling performance alone.”"),
  para("The factors associated with good practice in Table 6 are interpreted in the same light. For example, the association with a personal or family history of cancer may operate mainly through the personal screening items.")
)

## ---- Point 5 ----------------------------------------------------------------
doc <- doc %>% add(
  heading("Comment 5 — Duplication, language, abbreviations and tables"),
  quote_par("Remove the duplicated practice-score description, correct grammatical and punctuation errors, standardise abbreviations, verify table denominators and percentages. A grammar software may be used."),
  para("**Response:** Thank you. We have made the following changes:"),
  bullet("The duplicated paragraph in Section 2.4.2 (“Breast cancer screening practice was assessed using eight components…”, which appeared twice) has been removed."),
  bullet("Abbreviations are now defined at first use and used consistently: aOR (replacing “OR” for adjusted estimates), CI, KAP, BSE, CBE, VIA, HPV (“human papillomavirus (HPV)”), and “family history” in place of “H/O” in the tables."),
  bullet(sprintf("Table denominators and percentages were re-checked against the dataset. The column totals in Tables 3 and 4 are correct (good/poor knowledge 300/114 and 294/120; good/poor practice 61/353 and 67/347). In Table 1, the denominator for age at diagnosis of cancer in a family member is now stated (n = 64 of the 68 physicians with a family history; 4 missing). We have also added a footnote to Tables 1, 3 and 4 stating that years since graduation and department include imputed values (n = %d and n = %d originally missing).", n_miss_grad, n_miss_dept)),
  bullet("The manuscript was proofread in full, with the help of grammar-checking software [[name, e.g. Grammarly]], to correct grammatical and punctuation errors.")
)

doc <- doc %>% add(para("We hope that these revisions address the reviewer’s concerns, and we thank the reviewer again for helping to improve the manuscript."))


# -----------------------------------------------------------------------------
# 5. Notes for the authors -- not for submission
# -----------------------------------------------------------------------------
uni <- res$uni_p
nice <- c(age2 = "age", Sex = "sex", Family = "family history", dgraduation = "years since graduation",
          dx_self_cancer = "personal history of cancer", know_ca_scrn = "awareness of screening",
          att_ca_scrn = "belief screening is useful", dept = "department")
keep_txt <- sapply(colnames(uni), function(o) paste(nice[rownames(uni)[uni[, o] < 0.25]], collapse = ", "))

doc <- doc %>% body_add_break() %>% add(
  heading("Notes for the authors — delete before submission", 13),
  para("Items highlighted in yellow need information only you hold. The points below are decisions or corrections to confirm before sending the reply."),
  bullet("**Software.** Section 2.5 says IBM SPSS 26, but the regression models, multiple imputation and tables were produced in R. The revised Methods text says R; please confirm and fill in the version."),
  bullet(sprintf("**Imputation must be disclosed.** Years since graduation (%d missing) and department (%d missing) were imputed with mice before modelling, and Tables 1, 3 and 4 show the completed values for all %d physicians. The current manuscript does not mention this. The reply and revised Methods now state it. Note that a single completed dataset was analysed (the 5th of 5 imputations), not pooled estimates. If a reviewer asks, pooling across imputations or a complete-case sensitivity analysis can be added.", n_miss_grad, n_miss_dept, N)),
  bullet(sprintf("**p < 0.25 screening sentence removed.** The submitted Methods say variables with univariable p < 0.25 were selected, but all eight covariates were entered in every model. The revised text describes what was actually done (a priori covariate set). Applying the p < 0.25 rule would have retained: breast knowledge — %s; cervical knowledge — %s; breast practice — %s; cervical practice — %s.",
                keep_txt["know_breast"], keep_txt["know_cervical"], keep_txt["prac_breast"], keep_txt["prac_cervical"])),
  bullet(sprintf("**VIF threshold.** The submitted Methods say VIF < 2.0. After merging age, the largest VIF is %s (age, cervical-practice model), because age and years since graduation overlap. The revised text uses the conventional threshold of 5. If you prefer to keep < 2.0, the alternative is to drop age and keep years since graduation.", sprintf("%.2f", max(st$MaxVIF[st$Design == "Revised"])))),
  bullet("**Results wording changes.** Female sex for cervical knowledge is now p = 0.045 (was 0.052, “borderline”). Update the sentence in the Results. All other significant / non-significant classifications are unchanged."),
  bullet("**Breast-practice model.** Its overall likelihood-ratio test is not significant (p = 0.144). The reply says so openly. The two associations (family and personal history) should be worded cautiously in the Results and Discussion."),
  bullet(sprintf("**Personal screening items answered “yes” by men.** Of the %d male physicians, %d reported having performed BSE/CBE/mammography, %d mammography and %d VIA/Pap/HPV-DNA. This suggests some respondents read these as performing or ordering the test (e.g. for patients), not as their own screening. Please check the wording of these questions in the questionnaire. The reply to Comment 2 describes them as personal items and states that inapplicable items were scored 0; adjust the wording if the questionnaire says otherwise.",
                sum(raw$Sex == "Male"), sum(raw$Sex == "Male" & as.numeric(raw$prac_bse) == 1),
                sum(raw$Sex == "Male" & as.numeric(raw$prac_mamography) == 1),
                sum(raw$Sex == "Male" & as.numeric(raw$do_via) == 1))),
  bullet("**Tables.** Replace manuscript Tables 5 and 6 with the revised versions in doc/Revised_Models_Tables5_6.docx, and add Supplementary Tables S1 (EPV and model fit) and S2 (Firth sensitivity analysis) from the same file."),
  bullet("**Reference to add:** Heinze G, Schemper M. A solution to the problem of separation in logistic regression. Stat Med. 2002;21(16):2409–2419. Optionally also: Peduzzi P, et al. A simulation study of the number of events per variable in logistic regression analysis. J Clin Epidemiol. 1996;49(12):1373–1379.")
)


# -----------------------------------------------------------------------------
# 6. Write
# -----------------------------------------------------------------------------
out <- "Manuscript/Response_to_Reviewer1.docx"
tryCatch({ print(doc, target = out); cat("Written:", out, "\n") },
         error = function(e) warning("Could not write ", out, ": ", conditionMessage(e)))
