employed <- c(
  "farmer",
  "Rickshaw Pullar",
  "Small business",
  "samll business",
  "Businessman",
  "Health woker",
  "Service holder",
  "Farmer",
  "Service holder (office job)",
  "Service Holder(MLSS)",
  "Private job",
  "Contruction worker",
  "Service",
  "tailor",
  "Teacher",
  "Manual worker",
  "Job",
  "service",
  "Driver",
  "School teacher",
  "Labourer",
  "Construction worker",
  "Tailor"
)


unemployed <- c(
  "ex farmer",
  "Ex Businessman",
  "Ex Shopkeeper",
  "Ex Farmer",
  "Ex day labourer",
  "Ex farmer",
  "Unemployed",
  "Retaired person",
  "Ex service man, retaired ",
  "Ex polititian",
  "Housewife",
  "House wife",
  "Widowed"
)






all_labels <- list(
  smoking = c("Yes", "No", "Former"),
  physical = c("Sedentary", "Moderate", "Active", "Limited Activities"),
  education = c(
    "No education",
    "Primary school",
    "Secondary school",
    "College",
    "University"
  ),
  income = c("<10,000", "<20,000", "<50,000", ">50,000"),
  residence = c("Rural", "Urban"),
  DM = c(
    "Oral antidiabetic agent(s)",
    "Insulin",
    "Both",
    "Diet and discipline",
    "None (Newly diagnosed)",
    "Alternative medicine"
  ),
  yes_no = c("Yes", "No"),
  no_yes = c("No", "Yes"),
  antihyper_pres = c(
    "Registered physician",
    # "Nurse",
    # "Health assistant(HA)",
    "Village practitioner/Quack"
    # "Not prescribed yet"
  ),
  blood_freq = c(
    "Monthly",
    "3 monthly",
    "6 monthly",
    "Yearly",
    "Not measured at all/ more than 1 yearly"
  ),
  comor = c("Hypothyroidism", "IHD", "Hypothyroidism + IHD", "Stroke", "FLD", "Others", "None")
)




# Hypertension was defined as:
#    systolic blood pressure > 130 mmHg,
# or diastolic blood pressure >80 mmHg, 
# or if the patient was already taking anti-hypertensive medication.








# Dyslipidemia was defined according to 
# the adult treatment panel III (ATPIII) as the presence of one or more of the
# following lipid abnormalities: 
#   Total cholesterol level ≥ 200mg/dl, 
#   Triglyceride level ≥ 150 mg/dl, 
#   LDL-c levels ≥ 100mg/dl, 
#   or HDL-c levels < 40 mg/dl or < 50 mg/dl in males and females, respectively, 
#   or if the patient was already on anti-dyslipidemic agents (17). 






hypo <- c(
  "Hypothyroidism",
  "Hypothyoidism",
  "Hypothyeroidism",
  "Hypothyroidism, Fatty liver disease, osteoarthritis",
  "Hypothyroidism, Fatty liver disease, GERD"
)
ihd_hypo <- c("STOKE, IHD, Hypthyoidism",
              "IHD, hypothyroidism, FLD",
              "IHD, CKD, Hypothyoidism")
ihd <- c(
  "IHD, cervical spondylosis",
  "IHD, compensated heart failure",
  "IHD, Kidney disease",
  "IHD, CABG",
  "IHD, FLD",
  "IHD, COPD",
  "IHD, FLD, Gall stone, chronic cholecystitis",
  "Old stroke, IHD, pituitary adenoma?",
  "Stroke, IHD",
  "IHD",
  "IHD, obesity, Knee OA, Asthma, HTN"
)
stroke <- c(
  "Stroke",
  "stoke",
  "Stroke, Fatty liver disease (FLD)",
  "stoke, heat disease",
  "stroke",
  "Stroke, heart failure, Fatty liver disease"
)

fld <- c("Fatty Liver Disease",
         "FLD",
         "Knee Osteoarthritis, FLD",
         "FLD, Knee OA")
none <- c("NOne", "None", "none")


comor <- list(
  hypo = hypo,
  ihd_hypo = ihd_hypo,
  ihd = ihd,
  stroke = stroke,
  fld = fld,
  none = none,
  all = c(hypo, ihd_hypo, ihd, stroke, none, fld)
)


# fml <- list(
#   High_cholesterol = High_cholesterol ~ Age + Gender + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension,
#   High_LDL_C = High_LDL_C ~ Age + Gender + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension,
#   High_TG = High_TG ~ Age + Gender + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension,
#   Low_HDL_C = Low_HDL_C ~ Age + Gender + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension
# )
fml <- list(
  High_cholesterol = High_cholesterol ~ Age + Gender + Smoking + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension + Other_medications,
  High_LDL_C = High_LDL_C ~ Age + Gender + Smoking + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension + Other_medications,
  High_TG = High_TG ~ Age + Gender + Smoking + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension + Other_medications,
  Low_HDL_C = Low_HDL_C ~ Age + Gender + Smoking + Occupation + Income + Physical + Waist + BMI + Residence + HBA1C + Duration_Diabetes + HO_Hypertension + Other_medications
)




# Duration_Lipid_medication,


rm(hypo, ihd_hypo, ihd, stroke, none, fld)


















# Age,
# Gender,
# BMI,
# Waist,
# Residence,
# Education,
# Occupation,
# Income,
# Smoking,
# Physical,
# Duration_Diabetes,
# Diabetic_medication,
# Lipid_medication,
# Duration_Lipid_medication,
# Comorbidities
# 
# HBA1C
# RBS
# FBS
# HABF_2
# Diabetic_Neuropathy
# SBP
# DBP
# HO_Hypertension
# Duration_HTN
# Antihyper_medication
# Antihyper_regularly
# Antihyper_prescriber
# BP_frequency
# 
# 
# High_cholesterol
# 
# 
# 
# High_TG,
# High_LDL_C,
# Low_HDL_C,
# 
# TG_LDL,
# TG_HDL,
# LDL_HDL,
# LDL_HDL_TG,
# No_dys
# 
# 
# 
# 
# 
# 
# 
# 
# 
# # Table 1
# Age,
# Gender,
# BMI,
# Waist,
# Residence,
# Education,
# Occupation,
# Income,
# Smoking,
# Physical,
# Duration_Diabetes,
# Diabetic_medication,
# Lipid_medication,
# Duration_Lipid_medication,
# Comorbidities
# 
# 
# 
# # Table 2
# Gender
# High_TG,
# High_LDL_C,
# Low_HDL_C,
# TG_LDL,
# TG_HDL,
# LDL_HDL,
# LDL_HDL_TG,
# No_dys
# 
# 
# 
# 
# 
# # Table 3
# High_cholesterol
# High_TG
# High_LDL_C
# Low_HDL_C
# 
# Age
# Gender
# BMI
# Smoking
# HBA1C
# Duration_Diabetes
# Lipid_medication
# HO_Hypertension
# 
# 
# 
# 
# 
# 
# # Table 4
# High_cholesterol
# 
# Duration_Diabetes
# Lipid_medication
# HBA1C
# 
# 
# High_LDL_C
# 
# Age
# Lipid_medication
# Gender
# Smoking
# 
# 
# High_TG
# 
# Duration_Diabetes
# Occupation
# HO_Hypertension
# Waist
# HBA1C
# 
# 
# Low_HDL_C
# 
# HO_Hypertension
# HBA1C