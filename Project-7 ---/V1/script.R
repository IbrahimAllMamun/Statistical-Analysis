library(tidyverse)
library(gtsummary)

library(haven)
library(stringr)
library(flextable)
library(officer)

data <- read_sav("Metastatic breast cancer study.sav")



# Table 1
data %>%
  mutate(
    age_grp = case_when(
      age < 40 ~ 1, 
      age >= 40 & age < 50 ~ 2, 
      age >= 50 &
      age < 60 ~ 3, 
      age >= 60 ~ 4
      ) %>% 
      factor(labels = c("<40", "40-50", "50-60", "60+")),
    marital = marital %>% as_factor()
  ) -> data 


data %>%
  select(age_grp, marital) %>%
  tbl_summary(
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    missing = "no"
  ) %>%
  bold_labels() -> demo_tab


# Create Word document and add table
doc <- demo_tab %>% 
  as_flex_table() %>% 
  body_add_flextable(read_docx(), .)
  
  

# Table 2


data %>% 
  mutate(
    metastasis = metastasis %>% labelled::unlabelled(),
    Lung = ifelse(str_detect(metastasis, "\\b1\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Brain = ifelse(str_detect(metastasis, "\\b2\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    liver = ifelse(str_detect(metastasis, "\\b3\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Bone = ifelse(str_detect(metastasis, "\\b4\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    opposite_breast = ifelse(str_detect(metastasis, "\\b5\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Others = ifelse(str_detect(metastasis, "\\b6\\b"), 1, 0) %>% factor(labels = c("No", "Yes")),
    Multiple_site = ifelse(str_detect(metastasis, "\\b7\\b"), 1, 0) %>% factor(labels = c("No", "Yes"))
  ) -> data 




data %>%
  select(Lung, Brain, liver, Bone, opposite_breast, Others, Multiple_site) %>%
  tbl_summary(
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    missing = "no"
  ) %>%
  bold_labels() -> meta_tab



doc <- meta_tab %>% 
  as_flex_table() %>% 
  body_add_flextable(read_docx(), .)

# Save to file
print(doc, target = "metastatic_table.docx")



# Table 3
# TODO: add recurent
data %>% 
  mutate(
    her2 = her2 %>% labelled::unlabelled(),
    her2 = case_when(
      her2 == "1" ~ 1,
      her2 == "2" ~ 2,
      .default = 3
    ) %>% factor(labels = c("Positive", "Negative", "Unknown"))
  ) -> data 




data %>%
  select(age_grp, her2, Lung, Brain, liver, Bone, opposite_breast, Others, Multiple_site) %>%
  tbl_summary(
    by = age_grp,
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    missing = "no"
  ) %>%
  add_p( # Add p-values
    test = list(
      all_continuous() ~ "t.test",         # Use ANOVA for continuous
      all_categorical() ~ "chisq.test"  # Use Chi-square for categorical
    )
  ) %>%
  bold_labels() -> bivar_tab









# Table 5
data %>% 
  mutate(
    her2 = her2 %>% labelled::unlabelled(),
    her2 = case_when(
      her2 == "1" ~ 1,
      her2 == "2" ~ 2,
      .default = 3
    ) %>% factor(labels = c("Positive", "Negative", "Unknown"))
  ) -> data 




data %>%
  select(age_grp, her2, Lung, Brain, liver, Bone, opposite_breast, Others, Multiple_site) %>%
  tbl_summary(
    by = age_grp,
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 2,
    missing = "no"
  ) %>%
  add_p( # Add p-values
    test = list(
      all_continuous() ~ "t.test",         # Use ANOVA for continuous
      all_categorical() ~ "chisq.test"  # Use Chi-square for categorical
    )
  ) %>%
  bold_labels() -> bivar_tab














