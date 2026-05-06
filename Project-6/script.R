library(tidyverse)
library(gtsummary)

library(haven)
library(stringr)
library(flextable)
library(officer)

data <- read_sav("GlyStat_Analysis_18.05.24.sav")


data <- data %>%
  mutate(
    Sx = case_when(
      Sx %in% c(
        "Whipple's Procedure",
        "Wipple Procedure",
        "Whipplis Procedure" ,
        "Whipples Procedure"
      ) ~ "Whipples Procedure",
      Sx == "Tripple Bypass" ~ "Tripple Bypass Surgery",
      Sx %in% c(
        "Extended Cholecystectomy",
        "Extended Chalecystectomy",
        "Extended Cholecystectonomy",
        "Extened Chalecystectomy"
      ) ~ "Extended cholecystectomy",
      Sx %in% c("Biliary Reconstruction", "Billiary Reconstruction") ~ "Biliary reconstruction",
      Sx %in% c("Laperotomy", "Laparotomy") ~ "Laparotomy",
      Sx == "Biliary reconstruction" ~ "Biliary reconstruction",
      Sx == "Choledecolithomy & Billary Reconstruction" ~ "Choledocolithotomy & Billary Reconstruction",
      Sx == "Double Duct Anastomosis" ~ "Double Duct Anastomosis",
      Sx == "Drainage of Liver Abscess" ~ "Drainage of Liver Abscess",
      Sx == "Distal Pancreatectomy" ~ "Distal Pancreatectomy",
      Sx == "Extended cholecystectomy" ~ "Extended cholecystectomy",
      Sx == "Extended cholecystectomy & Billary Reconstruction" ~ "Extended cholecystectomy & Billary Reconstruction",
      Sx == "Laparotomy" ~ "Laparotomy",
      Sx == "Liver Abcuss Drainage" ~ "Liver Abcuss Drainage",
      Sx == "Lap. Hysterectomy" ~ "Lap. Hysterectomy",
      Sx == "Lap. Chole" ~ "Laparoscopic cholecystectomy ",
      Sx == "Laparotomy Followed by Colostomy" ~ "Laparotomy Followed by Colostomy",
      Sx == "Laparotomy & Hernioplasty" ~ "Laparotomy & Hernioplasty",
      Sx == "Nephro-lithotomy" ~ "Nephro-lithotomy",
      Sx == "Open Chale" ~ "Open cholecystectomy ",
      Sx == "Open Cholecystectomy & haemangioma & Liver Resection" ~ "Open Cholecystectomy & haemangioma & Liver Resection",
      Sx == "Open Cholecystectomy & hepatic Bi-segmentectomy" ~ "Open Cholecystectomy & hepatic Bi-segmentectomy",
      Sx == "PLPJ" ~ "PLPJ",
      Sx == "Resection of Lf ureteric man & reconstruction" ~ "Resection of Lf ureteric man & reconstruction",
      Sx == "Tripple Bypass Surgery" ~ "Tripple Bypass Surgery",
      Sx == "Whipple's Procedure" ~ "Whipple's Procedure",
      Sx == "Whipples Operation" ~ "Whipples Operation",
      .default = Sx
    ) %>% factor(),
    ECG = case_when(
      ECG %in% c("WML", "WNL") ~ "WNL",
      ECG %in% c("Sinus Tachy", "Sinus Tachycardia") ~ "Sinus Tachycardia",
      ECG %in% c("Normal Study", "Normal") ~ "Normal Study",
      ECG %in% c("Leteral Ischemia(?)") ~ "Leteral Ischemia",
      .default = ECG
    ) %>% factor(),
    CXR = case_when(
      CXR %in% c("Normal Study", "Normal", "Nomal") ~ "Normal Study",
      .default = CXR
    ) %>% factor()
  ) %>% select(-c(Ward, Bed, Hospital_id, Name, SLNo, Group, Date)) %>% 
  rowwise() %>% 
  mutate(
    NO_RWMA = any(stringr::str_detect(Echocardiography, c("No RWMA","NO RWMA"))),
    LVEF = str_extract(Echocardiography, "\\d+") %>% as.integer()
  ) %>% select(-Echocardiography, -BS1, -BS2, -BS3) %>% 
  mutate(
    Group_AA = labelled::to_factor(Group_AA),
    Gender = labelled::to_factor(Gender),
    ASA_Class = labelled::to_factor(ASA_Class),
  ) -> new_data





bivariate <- new_data %>%
  select(-LVEF, -NO_RWMA, -Duration_Anaes) %>% 
  tbl_summary(
    by = Group_AA,
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
  bold_labels()


univariate_flex <- as_flex_table(bivariate)

# Create Word document and add table
doc <- read_docx() %>%
  body_add_flextable(univariate_flex)

# Save to file
print(doc, target = "bivariate_summary2.docx")









lvef_tab <- new_data %>%
  filter(NO_RWMA) %>% 
  select(Group_AA, LVEF) %>% 
  tbl_summary(
    by = c(Group_AA),
    statistic = list(all_continuous() ~ "{mean} ({sd})", all_categorical() ~ "{n} ({p}%)"),
    digits = all_continuous() ~ 2,
    missing = "no"
  ) %>%
  add_p( # Add p-values
    test = list(
      all_continuous() ~ "t.test",         # Use ANOVA for continuous
      all_categorical() ~ "chisq.test"  # Use Chi-square for categorical
    )
  ) %>%
  bold_labels()

lvef_flex <- as_flex_table(lvef_tab)

# Create Word document and add table
doc <- read_docx() %>%
  body_add_flextable(lvef_flex)

# Save to file
print(doc, target = "lvef_tab.docx")








new_data %>%
  filter(!NO_RWMA) %>%
  filter(!is.na(LVEF)) %>% 
  select(Group_AA, LVEF) %>%
  group_by(Group_AA) %>% 
  summarise(
    m = mean(LVEF),
    s = sd(LVEF),
    n = n()
  )


new_data %>%
  select(Group_AA, Duration_Anaes) %>%
  group_by(Group_AA) %>% 
  summarise(
    m = mean(Duration_Anaes),
    s = sd(Duration_Anaes),
  )



t.test(Duration_Anaes~Group_AA, data=new_data)




theme_pub <- theme_classic(base_size = 12) +
  theme(
    text = element_text(family = "serif"),
    axis.title = element_text(face = "bold"),
    axis.text  = element_text(color = "black"),
    legend.title = element_text(face = "bold"),
    legend.position = "right",
    plot.title = element_text(face = "bold", hjust = 0.5)
  )



data %>%
  ggplot(aes(x = Group_AA, y = Age, fill = Group_AA)) +
  geom_boxplot(
    width = 0.6,
    alpha = 0.85,
    outlier.shape = 21,
    outlier.size = 1.5
  ) +
  scale_fill_grey(start = 0.4, end = 0.8) +
  # scale_fill_brewer(palette = "Set2") +
  labs(
    x = "Group",
    y = "Age (years)",
    title = "Distribution of Age by Group"
  ) +
  theme_pub +
  theme(legend.position = "none") -> age_plot



data %>%
  ggplot(aes(x = Group_AA, y = Body_wt, fill = Group_AA)) +
  geom_boxplot(
    width = 0.6,
    alpha = 0.85,
    outlier.shape = 21,
    outlier.size = 1.5
  ) +
  scale_fill_grey(start = 0.4, end = 0.8) +
  # scale_fill_brewer(palette = "Set2") +
  labs(
    x = "Group",
    y = "Body Weight (kg)",
    title = "Distribution of Body Weight by Group"
  ) +
  theme_pub +
  theme(legend.position = "none") -> wt_plot





data %>%
  ggplot(aes(x = Group_AA, fill = Gender)) +
  geom_bar(
    position = position_dodge(width = 0.7),
    width = 0.6,
    color = "black"
  ) + 
  scale_fill_grey(start = 0.4, end = 0.8) +
  # scale_fill_brewer(palette = "Set2") +
  labs(
    x = "Group",
    y = "Number of Participants",
    fill = "Gender",
    title = "Gender Distribution by Group"
  ) +
  theme_classic(base_size = 12) +
  theme(
    text = element_text(family = "serif"),
    axis.title = element_text(face = "bold"),
    legend.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) -> gender_plot









lab_vars <- c("Hb", "Creatinine", "Sodium",
              "Potassium", "ChlorideC", "HCO3")

data_long <- data %>%
  select(Group_AA, all_of(lab_vars)) %>%
  pivot_longer(-Group_AA,
               names_to = "Variable",
               values_to = "Value")
data_long <- data_long %>%
  group_by(Variable) %>%
  mutate(Z = as.numeric(scale(Value))) %>%
  ungroup()

heat_data <- data_long %>%
  group_by(Group_AA, Variable) %>%
  summarise(Zmean = mean(Z, na.rm = TRUE), .groups = "drop")


ggplot(heat_data,
       aes(x = Variable, y = Group_AA, fill = Zmean)) +
  
  geom_tile(color = "white", linewidth = 0.6) +
  
  scale_fill_gradient2(
    low = "#2166AC",
    mid = "white",
    high = "#B2182B",
    midpoint = 0,
    name = "Standardized\nMean (Z)"
  ) +
  
  labs(
    x = "",
    y = "",
    title = "Standardized Laboratory Profiles by Group"
  ) +
  
  theme_pub +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.title = element_text(face = "bold")
  ) -> lab_plot1



summary_data <- data_long %>%
  group_by(Group_AA, Variable) %>%
  summarise(Zmean = mean(Z), .groups = "drop")

ggplot(summary_data,
       aes(x = Variable, y = Zmean,
           group = Group_AA, color = Group_AA)) +
  
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  
  scale_color_brewer(palette = "Dark2") +
  
  labs(
    x = "",
    y = "Standardized Mean (Z-score)",
    color = "Group",
    title = "Laboratory Profile Comparison Between Groups"
  ) +
  
  theme_pub +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) -> lab_plot2





bs_long <- data %>%
  select(Group_AA,
         Blood_Sugar_Preinduction,
         Blood_Sugar_after_incision,
         Blood_Sugar_recovery) %>%
  pivot_longer(
    -Group_AA,
    names_to = "Time",
    values_to = "Blood_Sugar"
  ) %>%
  mutate(
    Time = factor(
      Time,
      levels = c(
        "Blood_Sugar_Preinduction",
        "Blood_Sugar_after_incision",
        "Blood_Sugar_recovery"
      ),
      labels = c("Pre-induction", "After incision", "Recovery")
    )
  )


ggplot(bs_long,
       aes(x = Time, y = Blood_Sugar,
           color = Group_AA, group = Group_AA)) +
  
  stat_summary(fun = mean, geom = "line", linewidth = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  
  stat_summary(
    fun.data = mean_se,
    geom = "errorbar",
    width = 0.15,
    linewidth = 0.8
  ) +
  
  scale_color_brewer(palette = "Dark2") +
  
  labs(
    x = "Perioperative Time",
    y = "Blood Sugar (mg/dL)",
    color = "Group",
    title = "Perioperative Blood Sugar Changes by Group"
  ) +
  
  theme_classic(base_size = 12) +
  theme(
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    legend.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) -> suger_plot







ggsave("graph/age_boxplot.png", plot=age_plot, width = 4, height = 4, dpi = 300)
ggsave("graph/bodywt_boxplot.png", plot=wt_plot, width = 4, height = 4, dpi = 300)
ggsave("graph/gender_by_group.png", plot=gender_plot, width = 4.5, height = 4, dpi = 300)
ggsave("graph/lab_by_group_heatmap.png", plot=lab_plot1, width = 6, height = 4, dpi = 300)
ggsave("graph/lab_by_group_line.png", plot=lab_plot2, width = 6, height = 4, dpi = 300)
ggsave("graph/blood_suger_by_group_line.png", plot=suger_plot, width = 6, height = 4, dpi = 300)




names(data)



