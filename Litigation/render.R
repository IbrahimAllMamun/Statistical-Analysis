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

# ------ DB Connection ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = cfg$DB_DRIVER,
                      Server   = cfg$DB_SERVER,
                      Database = cfg$DB_DATABASE,
                      UID      = cfg$DB_UID,
                      PWD      = cfg$DB_PWD,
                      Port     = cfg$DB_PORT)


Validation <- tbl(con, DBI::Id(schema = "SME", table = "Holiday")) %>% collect()
BD_Calender <- create.calendar(name = "BD", holidays = Validation$Date, weekdays = c("friday", "saturday"))



report_update_date <- dbGetQuery(con,"SELECT MAX([ReportPreparationDate]) dt FROM [dbo].[AnalyticsLitigationAccount]") %>% pull(dt)

report_date <- as.Date(bizdays::add.bizdays(report_update_date, -1, "BD"))

prev_report_date <- as.Date(bizdays::add.bizdays(report_date, -1, "BD"))



today_date <- Sys.Date()


date(report_update_date) == today_date



base_dir <- "\\\\CUMULUS/IDLCDrive/Shares/Ibrahim_PBM/Litigation/"

file_name = "litigation_dashboard.html"

if (date(report_update_date) == today_date){
  message("DB synced. Generating Dashboard.")
  rmarkdown::render(
    input       = "litigation_dashboard.RMD",
    output_file = paste0(base_dir, file_name),
    output_dir  = base_dir,
    envir       = new.env()
  )
} else {message("DB Didn't sync.")}


# rmarkdown::render(
#   input       = "litigation_dashboard.RMD",
#   output_file = paste0(base_dir, file_name),
#   output_dir  = base_dir,
#   envir       = new.env()
# )