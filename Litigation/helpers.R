library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(purrr)

library(readxl)

active_litigation <- read_excel("legal_new_data.xlsx")

active_litigation <- active_litigation %>% select(
  all_of(c("AccountNumber",
           "ClientName",
           "CaseID",
           "Branch",
           "LitigationStatus",
           "Nature of Suit",
           "CIF",
           "Suit Value",
           "Suit Filing Date",
           "Law Firm",
           "Court No",
           "Next Hearing Date",
           "Cheque Number",
           "RMName",
           "Litigation_Receivable",
           "HearingDetails",
           "URPA",
           "Overdue_Amount",
           "LPI",
           "NetExciseDutyTillLastYear",
           "NetExciseDutyTillCurrentYear"))
)

split_hearings <- function(x) {
  parts <- str_split(x, "(?=\\d+\\)\\s*Hearing Date:)", simplify = FALSE)[[1]]
  parts <- str_trim(parts)
  parts <- parts[parts != ""]
  parts <- str_remove(parts, ";\\s*$")
  
  tibble(raw = parts) %>%
    mutate(
      hearing_date = str_extract(raw, "(?<=Hearing Date:)[^;]+") %>% str_trim() %>% mdy(),
      case_status  = str_extract(raw, "(?<=Case Status:).+") %>% str_trim()
    ) %>%
    select(hearing_date, case_status) %>% 
    na.omit() %>% 
    arrange(desc(hearing_date)) %>% 
    distinct()
}



history <- active_litigation %>%
  mutate(case_data = map(HearingDetails, split_hearings)) %>%
  select(CaseID, case_data) %>%
  unnest(case_data)



active_litigation <- active_litigation %>% 
  select(-HearingDetails)


saveRDS(list(history=history, all_litigation=active_litigation), "data.RDS")











