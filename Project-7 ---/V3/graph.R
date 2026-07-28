# ============================================================
# Metastatic Breast Cancer - Survival graphs (Kaplan-Meier)
# ============================================================
# Data cleaning mirrors script.R (V3) so the survival outcome is
# derived identically:
#   status2 = 1 if Death, else 0
#   os_time = time to death for deaths, symptom-to-metastasis otherwise,
#             capped at 24 months  (timeofdeath/timdea are only recorded
#             for deaths, so this is the defensible follow-up time - see
#             the CAVEAT in script.R).
# ============================================================

library(haven)
library(dplyr)
library(stringr)
library(forcats)
library(survival)
library(survminer)
library(ggplot2)

# ----------------------------------------------------------
# 0.  Load & clean (same derivations as script.R)
# ----------------------------------------------------------
read_sav("Data/Metastatic breast cancer study_new dataset.sav") %>%
  mutate(
    age_grp = case_when(
      age < 35              ~ 1,
      age >= 35 & age < 45  ~ 2,
      age >= 45 & age < 55  ~ 3,
      age >= 55             ~ 4
    ) %>%
      factor(labels = c("<35", "35-45", "45-55", "55+")),

    # ── Metastasis sites (multi-coded) ──
    sitemetastasis  = sitemetastasis %>% labelled::unlabelled(),
    sitemetastasis  = ifelse(sitemetastasis == "", NA, sitemetastasis),
    Lung            = ifelse(str_detect(sitemetastasis, "\\b1\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Liver           = ifelse(str_detect(sitemetastasis, "\\b2\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),

    # ── Receptor status ──
    ER = ER %>% labelled::unlabelled(),
    ER = case_when(ER == "1" ~ 1, ER == "2" ~ 2, .default = NA) %>% factor(labels = c("Positive", "Negative")),
    PR = PR %>% labelled::unlabelled(),
    PR = case_when(PR == "1" ~ 1, PR == "2" ~ 2, .default = NA) %>% factor(labels = c("Positive", "Negative")),
    her2 = her2 %>% labelled::unlabelled(),
    her2 = case_when(her2 == "1" ~ 1, her2 == "2" ~ 2, .default = NA) %>% factor(labels = c("Positive", "Negative")),

    # ── Clinical subtype (HR+/HER2 combinations) ──
    clinical_subtype = case_when(
      ER == "Positive" | PR == "Positive" ~ "HR+",
      ER == "Negative" & PR == "Negative" ~ "HR-",
      .default = NA_character_
    ),
    subtype = case_when(
      clinical_subtype == "HR+" & her2 == "Positive" ~ "HR+/HER2+",
      clinical_subtype == "HR+" & her2 == "Negative" ~ "HR+/HER2-",
      clinical_subtype == "HR-" & her2 == "Positive" ~ "HR-/HER2+",
      clinical_subtype == "HR-" & her2 == "Negative" ~ "HR-/HER2-",
      .default = NA_character_
    ) %>% factor(levels = c("HR+/HER2+", "HR+/HER2-", "HR-/HER2+", "HR-/HER2-")),

    # ── Clinical status & event indicator ──
    cs = cs %>% as.character() %>% as.numeric() %>%
      factor(labels = c("Alive with disease", "Disease free", "Death")),

    # ── Metastatic burden ──
    mburden = mburden %>% labelled::unlabelled(),
    mburden = mburden %>% as.character() %>% as.numeric(),
    mburden = case_when(
      mburden == 1      ~ 1,
      mburden %in% 2:3  ~ 2,
      mburden > 3       ~ 3,
      .default = NA_integer_
    ) %>% factor(labels = c("1 site", "2-3 sites", "4+ sites")),

    status = ifelse(cs == "Death", 1, 0)
  ) -> data

# ----------------------------------------------------------
# 1.  Derived survival outcome (identical to script.R)
# ----------------------------------------------------------
data <- data %>% mutate(
  status2 = ifelse(cs == "Death", 1, 0),
  os_time = ifelse(status == 1, timdea, symptomtometastasis),
  os_time = ifelse(os_time > 24, 24, os_time)
)

# palette (no red)
pal <- c("#2a78d6", "#1baf7a", "#eda100", "#7b52ab")

# ggsurvplot returns a composed grob (curve + risk table), which ggsave cannot
# handle directly - render it through a png device instead.
save_km <- function(g, file, width = 8, height = 7.5) {
  png(file, width = width, height = height, units = "in", res = 300)
  print(g)
  dev.off()
}

# ----------------------------------------------------------
# 2.  Overall Kaplan-Meier curve
# ----------------------------------------------------------
fit_overall <- survfit(Surv(os_time, status2) ~ 1, data = data)

g_overall <- ggsurvplot(
  fit_overall,
  data          = data,
  conf.int      = TRUE,
  risk.table    = TRUE,
  surv.median.line = "hv",
  xlab          = "Time (months)",
  ylab          = "Survival Probability",
  title         = "",
  palette       = "#2a78d6",
  legend.title  = "",
  legend.labs   = "",
  ggtheme       = theme_bw(base_size = 12),
  risk.table.height = 0.25
)

save_km(g_overall, "Graph/km_overall.png", width = 8, height = 7)

# ----------------------------------------------------------
# 3.  Kaplan-Meier by molecular subtype (log-rank test)
# ----------------------------------------------------------
fit_subtype <- survfit(Surv(os_time, status2) ~ subtype, data = data)

g_subtype <- ggsurvplot(
  fit_subtype,
  data          = data,
  conf.int      = FALSE,
  pval          = TRUE,          # log-rank p-value
  risk.table    = TRUE,
  xlab          = "Time since metastasis (months)",
  ylab          = "Overall survival probability",
  title         = "Survival by molecular subtype",
  legend.title  = "Subtype",
  legend.labs   = levels(droplevels(data$subtype)),
  palette       = pal,
  ggtheme       = theme_bw(base_size = 12),
  risk.table.height = 0.28
)

save_km(g_subtype, "Graph/km_subtype.png", width = 8, height = 7.5)

# ----------------------------------------------------------
# 4.  Kaplan-Meier by metastatic burden (log-rank test)
# ----------------------------------------------------------
fit_burden <- survfit(Surv(os_time, status2) ~ mburden, data = data)

g_burden <- ggsurvplot(
  fit_burden,
  data          = data,
  conf.int      = FALSE,
  pval          = TRUE,
  risk.table    = TRUE,
  xlab          = "Time since metastasis (months)",
  ylab          = "Overall survival probability",
  title         = "Survival by metastatic burden",
  legend.title  = "Burden",
  legend.labs   = levels(droplevels(data$mburden)),
  palette       = pal,
  ggtheme       = theme_bw(base_size = 12),
  risk.table.height = 0.28
)

save_km(g_burden, "Graph/km_burden.png", width = 8, height = 7.5)
