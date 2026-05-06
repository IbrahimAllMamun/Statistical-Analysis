library(tidyverse)
library(gt)
library(gtsummary)

library(haven)
library(stringr)
library(flextable)
library(officer)
library(summarytools)
library(openxlsx)

library(forcats)

library(dplyr)
library(survival)
library(survminer)

library(labelled)

library(mice)
library(jomo)

select <- dplyr::select


non_clinical <- c("Anatomy", "Physiology","Biochemistry","Community medicine","Forensic medicine","Pharmacology","Pathology","Microbiology")

read_dta("Data/Knownledge_data2.dta") %>%
  mutate(across(where(haven::is.labelled), haven::as_factor)) %>%
  mutate(
    age = case_when(
      age <= 40 ~ 1,
      age > 40 & age <= 50 ~ 2,
      age > 50 & age <= 60 ~ 3,
      age > 60  ~ 4
      # Age > 60 & Age <= 70 ~ 4,
      # Age > 70 ~ 5
    ) %>%
      factor(labels = c("<=40", "41-50", "51-60", "60+")),
    post = fct_recode(post, "MO" = "9"),
    dgraduation = case_when(
      dgraduation <= 5 ~ 1,
      dgraduation > 5 & dgraduation <= 10 ~ 2,
      dgraduation > 10  ~ 3
    ) %>%
      factor(, labels = c("<6", "6-10", ">10")),
    agecancer = case_when(
      agecancer <  45 ~ 1,
      agecancer >= 45 & agecancer <= 55 ~ 2,
      agecancer >  55  ~ 3
    ) %>%
      factor(, labels = c("<45", "45-55", ">55")),
    durationscan = case_when(
      durationscan <  5 ~ 1,
      durationscan >= 5 & durationscan <= 10 ~ 2,
      durationscan >  10  ~ 3
    ) %>%
      factor(, labels = c("<5", "5-10", ">10")),
    dept = case_when(
      is.na(dept) ~ NA_real_,
      dept %in% non_clinical ~ 0,!dept %in% non_clinical ~ 1,
    ) %>% factor(labels = c("Non Clinical", "Clinical"))
  ) -> data




data$nameofcancer[data$nameofcancer %in% c("coion","colon")] <- "Colon"
data$nameofcancer[data$nameofcancer %in% c("carvix","ceavix","cervix")] <- "Cervix"
data$nameofcancer[data$nameofcancer %in% c("head&nek")] <- "Head and Neck"
data$nameofcancer[data$nameofcancer %in% c("leukamia","leukemia")] <- "Leukemia"
data$nameofcancer[data$nameofcancer %in% c("lang","lung","Lung","Nung")] <- "Lung"
data$nameofcancer[data$nameofcancer %in% c("ovareon","ovario","ovarion")] <- "Ovarian"
data$nameofcancer[data$nameofcancer %in% c("")] <- NA





data$nameselfcan[data$nameselfcan %in% c("Breast","breast")] <- "Breast"
data$nameselfcan[data$nameselfcan %in% c("cervix","carvix")] <- "Cervix"
data$nameselfcan[data$nameselfcan %in% c("long","lung","Lung")] <- "Lung"
data$nameselfcan[data$nameselfcan %in% c("laryngea","larynx")] <- "Larynx"
data$nameselfcan[data$nameselfcan %in% c("ovareon","Ovariaya","ovarion","overion")] <- "Ovarian"
data$nameselfcan[data$nameselfcan %in% c("")] <- NA



data$namecancers[data$namecancers %in% c("bone", "none")] <- "Bone"
data$namecancers[data$namecancers %in% c("brest", "breast")] <- "Breast"
data$namecancers[data$namecancers %in% c("cervical","carvical","carvix","cervix")] <- "Cervix"
data$namecancers[data$namecancers %in% c("prostet","prostate")] <- "Prostate"
data$namecancers[data$namecancers %in% c("")] <- NA




# Breast

data <- data %>% 
  mutate(
    know_breast = case_when(
      as.numeric(know_ca_br_scrn)==1~1,
      as.numeric(know_ca_br_scrn)==2~0
    ) +
      case_when(
        agebrcans>=25~1,
        agebrcans<25~0,
        is.na(agebrcans)~0
      ) + 
      case_when(
        interval_br_scrn %in% c(1)~1,
        !interval_br_scrn %in% c(1)~0,
      ) +
      case_when(
        as.numeric(prac_brca_scrn)==1~1,
        as.numeric(prac_brca_scrn)==2~0
      ) +
      case_when(
        as.numeric(att_br_ca_scrn)==1~1,
        as.numeric(att_br_ca_scrn)==2~0
      ),
    
    prac_breast = case_when(
      as.numeric(prac_bse)==1~1,
      as.numeric(prac_bse)==2~0
    ) +
      case_when(
        bse_interval %in% c(1)~1,
        !bse_interval %in% c(1)~0,
      ) +
      case_when(
        as.numeric(prac_mamography)==1~1,
        as.numeric(prac_mamography)==2~0
      ) +
      case_when(
        interval_mamo %in% c(1,2)~1,
        !interval_mamo %in% c(1,2)~0
      ) +
      case_when(
        as.numeric(brcan_scrn_family)==1~1,
        as.numeric(brcan_scrn_family)==2~0
      ) +
      case_when(
        famlibrcansc %in% c(1)~1,
        !famlibrcansc %in% c(1)~0,
      ) +
      case_when(
        as.numeric(brca_scrn_pt)==1~1,
        as.numeric(brca_scrn_pt)==2~0
      ) +
      case_when(
        interval_brca_pt %in% c(1)~1,
        !interval_brca_pt %in% c(1)~0,
      ) 
  ) 








# Colon


data <- data %>% 
  mutate(
    know_colon = case_when(
      as.numeric(know_colon_ca)==1~1,
      as.numeric(know_colon_ca)==2~0
    ) +
      case_when(
        age_colon_ca>=45~1,
        age_colon_ca<45~0,
        is.na(age_colon_ca)~0
      ) + 
      case_when(
        intecolocas %in% c(3)~1,
        !intecolocas %in% c(3)~0,
      ) +
      case_when(
        as.numeric(do_colonoscopy)==1~1,
        as.numeric(do_colonoscopy)==2~0
      ) + 
      case_when(
        intercolonos %in% c(3)~1,
        !intercolonos %in% c(3)~0
      ) +
      case_when(
        as.numeric(att_colon_ca)==1~1,
        as.numeric(att_colon_ca)==2~0
      ),
    
    prac_colon = case_when(
      as.numeric(colon_scrn_family)==1~1,
      as.numeric(colon_scrn_family)==2~0
    ) +
      case_when(
        intercolonfamil %in% c(3)~1,
        !intercolonfamil %in% c(3)~0,
      ) +
      case_when(
        as.numeric(colon_scrn_patient)==1~1,
        as.numeric(colon_scrn_patient)==2~0
      ) +
      case_when(
        intercolonspt %in% c(3)~1,
        !intercolonspt %in% c(3)~0
      ) 
  )













# Prostate

data <- data %>% 
  mutate(
    know_prostate = case_when(
      as.numeric(know_prost_scrn)==1~1,
      as.numeric(know_prost_scrn)==2~0
    ) +
      case_when(
        ageproscs>=50~1,
        ageproscs<50~0,
        is.na(ageproscs)~0,
      ) + 
      case_when(
        interproscs %in% c(1)~1,
        !interproscs %in% c(1)~0,
      ) +
      case_when(
        as.numeric(att_prost_scrn)==1~1,
        as.numeric(att_prost_scrn)==2~0
      ),
    
    prac_prostate = case_when(
      as.numeric(do_dre_psa)==1~1,
      as.numeric(do_dre_psa)==2~0
    ) +
      case_when(
        interpsadre %in% c(1,2)~1,
        !interpsadre %in% c(1,2)~0,
      ) +
      case_when(
        as.numeric(pros_scrn_family)==1~1,
        as.numeric(pros_scrn_family)==2~0
      ) +
      case_when(
        iprosf %in% c(1,2)~1,
        !iprosf %in% c(1,2)~0
      ) +
      case_when(
        as.numeric(pros_scrn_patient)==1~1,
        as.numeric(pros_scrn_patient)==2~0
      ) +
      case_when(
        interprospt %in% c(1,2)~1,
        !interprospt %in% c(1,2)~0,
      )
  )







# Cervical

data <- data %>% 
  mutate(
    know_cervical  = case_when(
      as.numeric(know_cerv_scrn)==1~1,
      as.numeric(know_cerv_scrn)==2~0
    ) +
      case_when(
        age_cerv_start>=21~1,
        age_cerv_start<21~0,
        is.na(age_cerv_start)~0
      ) + 
      case_when(
        intercer %in% c(3,5)~1,
        !intercer %in% c(3,5)~0,
      ) +
      case_when(
        as.numeric(prac_via)==1~1,
        as.numeric(prac_via)==2~0
      ) +
      case_when(
        as.numeric(att_cerv_scrn)==1~1,
        as.numeric(att_cerv_scrn)==2~0
      ),
    
    prac_cervical  = case_when(
      as.numeric(do_via)==1~1,
      as.numeric(do_via)==2~0
    ) +
      case_when(
        intervia %in% c(1)~1,
        !intervia %in% c(1)~0,
      ) +
      case_when(
        as.numeric(cerv_scrn_family)==1~1,
        as.numeric(cerv_scrn_family)==2~0
      ) +
      case_when(
        interfamcer %in% c(1,2)~1,
        !interfamcer %in% c(1,2)~0
      ) +
      case_when(
        as.numeric(cerv_scrn_patient)==1~1,
        as.numeric(cerv_scrn_patient)==2~0
      ) +
      case_when(
        intercerpt %in% c(1)~1,
        !intercerpt %in% c(1)~0,
      )
  ) 







data_mod <- data %>% 
  mutate(
    know_breast = ifelse(know_breast>=3, 1,0) %>% factor(labels = c("Poor", "Good")),
    prac_breast = ifelse(prac_breast>=4, 1,0) %>% factor(labels = c("Poor", "Good")),
    know_colon = ifelse(know_colon>=3, 1,0) %>% factor(labels = c("Poor", "Good")),
    prac_colon = ifelse(prac_colon>=2, 1,0) %>% factor(labels = c("Poor", "Good")),
    know_prostate = ifelse(know_prostate>=2, 1,0) %>% factor(labels = c("Poor", "Good")),
    prac_prostate = ifelse(prac_prostate>=3, 1,0) %>% factor(labels = c("Poor", "Good")),
    know_cervical = ifelse(know_cervical>=3, 1,0) %>% factor(labels = c("Poor", "Good")),
    prac_cervical = ifelse(prac_cervical>=3, 1,0) %>% factor(labels = c("Poor", "Good"))
  ) %>% 
  select(
    age,Sex,Family,dgraduation,dx_self_cancer,know_ca_scrn,att_ca_scrn,dept,
    know_breast,prac_breast,know_colon,prac_colon,know_prostate,prac_prostate,know_cervical,prac_cervical
  )




meth <- rep("logreg", 16)
meth[1] <- "polyreg"
meth[4] <- "polyreg"

# Number of imputations
m <- 5

# Run JM (jomo) imputation in mice
imp <- mice(data_mod, method = meth, m = m, seed = 123)

# Get completed dataset
data_mod <- complete(imp, action = m)



lab <- c("<30", "30-40", ">40")

data <- data %>% 
  mutate(
    agebrcans = case_when(
      agebrcans <  30~1,
      agebrcans >= 30 & agebrcans <= 40 ~ 2, 
      agebrcans >  40  ~ 3
    ) %>% 
      factor(, labels = lab),
    age_cerv_start = case_when(
      age_cerv_start <  30~1,
      age_cerv_start >= 30 & age_cerv_start <= 40 ~ 2, 
      age_cerv_start >  40  ~ 3
    ) %>% 
      factor(, labels = lab),
    age_colon_ca = case_when(
      age_colon_ca <  30~1,
      age_colon_ca >= 30 & age_colon_ca <= 40 ~ 2, 
      age_colon_ca >  40  ~ 3
    ) %>% 
      factor(, labels = lab),
    ageproscs = case_when(
      ageproscs <  30~1,
      ageproscs >= 30 & ageproscs <= 40 ~ 2, 
      ageproscs >  40  ~ 3
    ) %>% 
      factor(, labels = lab),
  )

data_mod %>% 
  mutate(
    Family = relevel(Family, ref = "No"),
    dx_self_cancer = relevel(dx_self_cancer, ref = "No"),
    know_ca_scrn = relevel(know_ca_scrn, ref = "No"),
    att_ca_scrn = relevel(att_ca_scrn, ref = "No")
  ) -> data_mod

data_mod %>%
  set_variable_labels(
    age = "Age of the patient",
    Sex = "Sex of the patient",
    Family = "Family H/O cancer",
    dgraduation = "Duration of graduation (years)",
    dx_self_cancer = "Ever been diagnosed any cancer",
    know_ca_scrn = "Know about cancer screening",
    att_ca_scrn = "Think cancer screening will usefull",
    dept = "Department",
    know_breast = "Knowledge",
    prac_breast = "Practice",
    know_colon = "Knowledge",
    prac_colon = "Practice",
    know_prostate = "Knowledge",
    prac_prostate = "Practice",
    know_cervical = "Knowledge",
    prac_cervical = "Practice",
  ) -> data_mod


data %>%
  set_variable_labels(
    age = "Age of the patient",
    Sex = "Sex of the patient",
    Family = "Family H/O cancer",
    nameofcancer = "Name of cancer",
    agecancer = "Age of diagnosis of cancer",
    dept = "Department",
    post = "Post",
    dgraduation = "Duration of graduation (years)",
    dx_self_cancer = "Ever been diagnosed any cancer",
    nameselfcan = "Name of self cancer",
    durationscan = "Duration of diagnosis of self cancer",
    know_ca_scrn = "Know about cancer screening",
    namecancers = "Name of cancer that can be screened",
    att_ca_scrn = "Think cancer screening will usefull",
    agebrcans = "Age of start of breast cancer screening",
    age_cerv_start = "Age of start of cervical cancer screening",
    age_colon_ca = "Age of start of colon cancer screening",
    ageproscs = "Age of start of prostate cancer screening"
  ) -> data








saveRDS(data_mod, "Data/model_data.RDS")
saveRDS(data, "Data/data_with_score.RDS")

