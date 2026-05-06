library(tidyverse)
library(haven)
library(forcats)
library(broom)
library(gtsummary)
library(kableExtra)
library(viridis)
library(ggthemes)
library(ggsci)
delay <- read_dta("delay_final.dta")
delay <- as_factor(delay)
 

 
formula <- delayedstartrx ~ age_group + Residence + Education + Income + familybreastchistory + firstdoc + agemenarche + staging + metastasis
mod <- delay %>%
  glm(
    formula,
    data = .,
    family = "binomial"
  )


tab <- mod %>% 
  tbl_regression(
    exponentiate = T
  ) 


tab <- tab %>% 
  bold_labels() %>% 
  modify_table_styling(
    columns = c(estimate),
    rows = reference_row == T,
    missing_symbol = "1"
  ) %>%
  as_gt()
tab

gtsave(tab, filename = "tab.docx")
