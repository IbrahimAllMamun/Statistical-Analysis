library(flexdashboard)
library(dplyr)
library(DT)
library(reactable)
library(htmltools)
library(jsonlite)

require(tidyverse)
require(readxl)
require(lubridate)
require(openxlsx)
require(glue)

library(DBI)
library(odbc)

library(crosstalk)
library(bizdays)

# Load the config configuration object
cfg <- config::get()

# ?????? DB Connection ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = cfg$DB_DRIVER,
                      Server   = cfg$DB_SERVER,
                      Database = cfg$DB_DATABASE,
                      UID      = cfg$DB_UID,
                      PWD      = cfg$DB_PWD,
                      Port     = cfg$DB_PORT)


con <- DBI::dbConnect(odbc::odbc(), 
                        Driver   = "SQL Server",     # the driver actually installed on your host
                        Server   = "localhost,1433", # host,port together for this driver
                        Database = "IDLC",
                        UID      = "sa",
                        PWD      = "IDLC@Str0ngPass"
                      )
         

query <- paste0("SELECT * FROM [dbo].[data]")


# End of the current work week: the upcoming Thursday (or today if today IS Thursday).
# wday(): Sunday=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7
Validation <- tbl(con, DBI::Id(schema = "SME", table = "Holiday")) %>% collect()
BD_Calender <- create.calendar(name = "BD", holidays = Validation$Date, weekdays = c("friday", "saturday"))
report_date <- dbGetQuery(con,"SELECT MAX([ReportPreparationDate]) dt FROM [dbo].[AnalyticsLitigationAccount]") %>% pull(dt)
report_date <- as.Date(bizdays::add.bizdays(report_date, -1, "BD"))



today_date <- Sys.Date()

# end of the next-5-working-day window
next5_end <- as.Date(bizdays::add.bizdays(today_date, 5, "BD"))

month_end      <- lubridate::ceiling_date(today_date, "month") - lubridate::days(1)
next_month_end <- lubridate::ceiling_date(today_date %m+% months(1), "month") - lubridate::days(1)

data <- dbGetQuery(con,query) %>%
  distinct(CaseID, .keep_all = TRUE) %>% 
  mutate(
    PRODUCT_CATEGORY_LABEL = ifelse(PRODUCT_CATEGORY == "SME", "SME", "Other"),
    .nhd     = as.Date(`Next Hearing Date`),
    upcoming = case_when(
      is.na(.nhd)            ~ "No Date",
      .nhd <  today_date     ~ "Not Updated",
      .nhd == today_date     ~ "Today",
      .nhd <= next5_end      ~ "Next 5 Working Days",
      .nhd <= month_end      ~ "This Month",
      .nhd <= next_month_end ~ "Next Month",
      TRUE                   ~ "Later"
    ),
    in_this_month = !is.na(.nhd) & .nhd >= today_date & .nhd <= month_end,
    in_next_month = !is.na(.nhd) & .nhd >  month_end  & .nhd <= next_month_end,
    SuitType  = case_when(
      `Nature of Suit` == "Negotiable Instrument Act (NI Act)" ~"NI Act",
      `Nature of Suit` == "Artha Rin Aine (ARA)" ~  "ARA",
      `Nature of Suit` == "Artha Rin Aine Execution (ARAE)" ~  "ARAE",
      .default = "Other"
    ),
    Aging = round(time_length(interval(
      `Suit Filing Date`,
      case_when(
        is.na(`Last Hearing Date`) ~ as.Date(NA),
        LitigationStatus == "Active"   ~ report_date,
        LitigationStatus == "InActive" ~ `Last Hearing Date`
      )
    ), "day")),
    aging_status = round(time_length(interval(
      `Last Hearing Date`,
      case_when(
        LitigationStatus == "Active"   ~ report_date,
        LitigationStatus == "InActive" ~ as.Date(NA)
      )
    ), "day"))
  ) %>% 
  select(-.nhd) %>% 
  filter(SuitType != "Other")






history <- dbGetQuery(con,
                      paste0(
                        "WITH ranked AS (
          SELECT
              caseid AS CaseID,
              HearingDate AS hearing_date,
              CaseStatus AS case_status,
              MakeDate,
              ROW_NUMBER() OVER (
                  PARTITION BY caseid, HearingDate, CaseStatus
                  ORDER BY MakeDate DESC
              ) AS rn
          FROM [dbo].[AnalyticsLitigationAccountHearing]
      ),
      case_data AS(
        SELECT
          CaseID,
          LitigationStatus
        FROM [dbo].[AnalyticsLitigationAccount]
        WHERE [ReportPreparationDate] = (SELECT MAX([ReportPreparationDate]) FROM [dbo].[AnalyticsLitigationAccount])
      )
      
      SELECT r.CaseID, r.hearing_date, r.case_status, r.MakeDate, c.LitigationStatus
      FROM ranked r
      LEFT JOIN case_data c
        ON r.CaseID = c.CaseID
      WHERE r.rn = 1
      ORDER BY r.CaseID, r.hearing_date DESC, r.MakeDate DESC;"
                      ))



history <- history %>%
  group_by(CaseID) %>%
  mutate(
    next_hearing = lag(hearing_date),
    aging = round(time_length(interval(
      hearing_date,
      case_when(
        is.na(next_hearing) & LitigationStatus == "Active"   ~ report_date,
        is.na(next_hearing) & LitigationStatus == "InActive" ~ as.Date(NA),
        .default = next_hearing
      )
    ), "day")),
    r_num = row_number()
  ) %>%
  ungroup() 


history %>% 
  filter(r_num == 1) %>% 
  select(CaseID, aging, LitigationStatus)






rm(query, Validation, BD_Calender)

rm(query, Validation, BD_Calender)

# load("data.RDS")
# save.image("data.RDS")

/plugin marketplace add 21st-dev/claude-code-plugin
/plugin install 21st@21st