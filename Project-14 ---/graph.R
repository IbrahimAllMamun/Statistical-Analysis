# ============================================================
# Overall Kaplan-Meier survival curve (whole MBC cohort)
# Data source: Data/cancer_data_imputed.Farhana.xlsx
#   os_time = time to death / censoring, capped at 24 months
#   status2 = 1 if death, else 0
#   Output: Graph/Fig_KM_overall_farhana.png
# ============================================================

library(readxl)
library(dplyr)
library(survival)
library(survminer)

raw <- read_excel("Data/cancer_data_imputed.Farhana.xlsx")

dat <- raw %>%
  transmute(
    os_time = as.numeric(os_time),
    status2 = as.numeric(cs == "Death")
  ) %>%
  filter(!is.na(os_time), !is.na(status2))

fit <- survfit(Surv(os_time, status2) ~ 1, data = dat)

g <- ggsurvplot(
  fit, data = dat,
  conf.int         = TRUE,
  risk.table       = TRUE,
  surv.median.line = "hv",
  xlab   = "Time (Months)",
  ylab   = "Survival Probability",
  title  = "",
  legend = "none",
  palette = "#2166AC",
  ggtheme = theme_bw(base_size = 12),
  legend.title  = "",
  legend.labs   = "",
  risk.table.height = 0.22,
  break.time.by = 3,
  xlim = c(0, 24)
)

# ggsurvplot is a composed grob -> render through a device
png("Graph/Fig_KM_overall_farhana.png", width = 8, height = 7, units = "in", res = 300)
print(g)
dev.off()
message("Saved -> Graph/Fig_KM_overall_farhana.png")
