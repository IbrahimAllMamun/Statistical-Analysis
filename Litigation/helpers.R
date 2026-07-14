# Load the config configuration object
cfg <- config::get()

# ── DB Connection ─────────────────────────────────────────────────────────────
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = cfg$DB_DRIVER,
                      Server   = cfg$DB_SERVER,
                      Database = cfg$DB_DATABASE,
                      UID      = cfg$DB_UID,
                      PWD      = cfg$DB_PWD,
                      Port     = cfg$DB_PORT)

query <- paste0(
    "SELECT
        l.AccountNumber,
        l.ClientName,
        l.CaseID,
        l.Branch,
        l.LitigationStatus,
        l.[Nature of Suit],
        l.CIF,
        NULLIF(l.[Suit Filing Date], '') AS [Suit Filing Date],
        NULLIF(l.[Suit Value], '') AS [Suit Value],
        NULLIF(l.[Law Firm], '') AS [Law Firm],
        NULLIF(NULLIF(l.[Court No],'N/A'), '') AS [Court No],
        NULLIF(l.[Next Hearing Date], '') AS [Next Hearing Date],
        NULLIF(NULLIF(l.[Cheque Number], 'N/A'), '') AS [Cheque Number],
        l.RMName,
        NULLIF(l.Litigation_Receivable, '') AS Litigation_Receivable,
        l.HearingDetails,
        l.URPA,
        NULLIF(a.MONTHSOVERDUE, '') AS MOD,
        l.OVERDUE_AMOUNT,
        a.PRINCIPAL_OD,
        a.INTEREST_OD,
        l.LPI,
        l.NetExciseDutyTillLastYear,
        l.NetExciseDutyTillCurrentYear,
        l.PRODUCT_CATEGORY
    FROM [dbo].[AnalyticsLitigationAccount] l
    LEFT JOIN [dbo].[AnalyticsCLAccount] a
        ON a.ACCOUNT_NUMBER = l.AccountNumber
    WHERE l.[ReportPreparationDate] = (SELECT MAX([ReportPreparationDate]) FROM [dbo].[AnalyticsLitigationAccount])"
    )


all_litigation <- dbGetQuery(con,query)




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
    mutate(SL = row_number())
    # distinct(hearing_date, case_status, .keep_all = T)
    # arrange(desc(hearing_date), desc(SL)) %>%
}

# history <- 
all_litigation[15, ] %>%
  mutate(case_data = map(HearingDetails, split_hearings)) %>%
  select(CaseID, case_data) %>%
  unnest(case_data) %>% 
  print(n = 100)


# all_litigation %>% View()


all_litigation <- all_litigation %>%
  distinct(CaseID, .keep_all = TRUE) %>% 
  mutate(
    PRODUCT_CATEGORY_LABEL = ifelse(PRODUCT_CATEGORY=="SME", "SME", "Other")
  ) %>% 
  select(-HearingDetails)










saveRDS(list(history=history, all_litigation=all_litigation), "data.RDS")

