# ============================================================
# Forest plot - prognostic factors for 2-year overall survival
# Data source: Data/cancer_data_imputed.Farhana.xlsx
# ------------------------------------------------------------
# Visualises the multivariable Cox model from Table 4
# (script_farhana.R): hazard ratios (95% CI) for overall
# survival within the 24-month (2-year) window.
#   Output: Graph/Fig_forest_prognostic_farhana.png
# ============================================================

library(readxl)
library(dplyr)
library(stringr)
library(forcats)
library(survival)
library(broom)
library(ggplot2)

raw <- read_excel("Data/cancer_data_imputed.Farhana.xlsx")
yn <- function(x) factor(str_to_title(as.character(x)), levels = c("No", "Yes"))

# ---- clean & derive (same as script_farhana.R) ----
dat <- raw %>%
  transmute(
    os_time = as.numeric(os_time),
    status2 = as.numeric(cs == "Death"),                       # event = death
    age_grp = factor(age_grp, levels = c("<35", "35-45", "45-55", "55+")),
    grade   = factor(grading, levels = c("Grade 1", "Grade 2", "Grade 3")),
    subtype = factor(clinical_subtype,
                     levels = c("HR+/HER2+", "HR+/HER2-", "HR-/HER2+", "HR-/HER2-")),
    burden  = case_when(
      str_detect(mburden, "^>3")  ~ ">3 sites",
      str_detect(mburden, "^2-3") ~ "2-3 sites",
      str_detect(mburden, "^1")   ~ "1 site",
      .default = NA_character_) %>% factor(levels = c("1 site", "2-3 sites", ">3 sites")),
    lung  = yn(Lung),
    liver = yn(Liver),
    delay = factor(str_to_title(delayrx), levels = c("No", "Yes")),   # No = reference
    skip  = factor(skip, levels = c("Non Adherent", "Adherent"))
  )

# ---- multivariable Cox model ----
cox_multi <- coxph(
  Surv(os_time, status2) ~ age_grp + grade + subtype + burden + lung + liver + delay + skip,
  data = dat)

# ---- tidy -> hazard ratios ----
term_labels <- c(
  "age_grp35-45"        = "Age 35-45 (vs <35)",
  "age_grp45-55"        = "Age 45-55 (vs <35)",
  "age_grp55+"          = "Age 55+ (vs <35)",
  "gradeGrade 2"        = "Grade 2 (vs Grade 1)",
  "gradeGrade 3"        = "Grade 3 (vs Grade 1)",
  "subtypeHR+/HER2-"    = "HR+/HER2- (vs HR+/HER2+)",
  "subtypeHR-/HER2+"    = "HR-/HER2+ (vs HR+/HER2+)",
  "subtypeHR-/HER2-"    = "HR-/HER2- (vs HR+/HER2+)",
  "burden2-3 sites"     = "2-3 sites (vs 1 site)",
  "burden>3 sites"      = ">3 sites (vs 1 site)",
  "lungYes"             = "Lung metastasis",
  "liverYes"            = "Liver metastasis",
  "delayYes"            = "Delayed treatment",
  "skipAdherent"        = "Treatment adherent (vs non-adherent)"
)

hr <- tidy(cox_multi, exponentiate = TRUE, conf.int = TRUE) %>%
  filter(is.finite(estimate), is.finite(conf.low), is.finite(conf.high)) %>%
  mutate(
    label = factor(term_labels[term], levels = rev(unname(term_labels))),
    sig   = ifelse(p.value < 0.05, "p < 0.05", "NS")
  )

# ---- forest plot ----
fp <- ggplot(hr, aes(x = estimate, y = label, colour = sig)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey60") +
  geom_linerange(aes(xmin = conf.low, xmax = conf.high), linewidth = 0.8) +
  geom_point(size = 2.8) +
  geom_text(aes(label = sprintf("%.2f (%.2f-%.2f)", estimate, conf.low, conf.high)),
            vjust = -1, size = 3, colour = "grey25") +
  scale_x_log10() +
  scale_colour_manual(values = c("p < 0.05" = "#0f766e", "NS" = "#9aa5b1")) +
  labs(x = "Adjusted hazard ratio (95% CI, log scale)", y = NULL, colour = NULL,
       title = "Prognostic factors for 2-year overall survival",
       subtitle = "Multivariable Cox proportional-hazards model (metastatic breast cancer, n = 134)") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank())

ggsave("Graph/Fig_forest_prognostic_farhana.png", fp, width = 10, height = 7.5, dpi = 300)
message("Saved -> Graph/Fig_forest_prognostic_farhana.png")
