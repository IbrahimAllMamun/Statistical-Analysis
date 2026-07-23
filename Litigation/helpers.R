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
      l.[Present Case Status],
      l.Aging,
      NULLIF(l.[Suit Filing Date], '') AS [Suit Filing Date],
      NULLIF(l.[Suit Value], '') AS [Suit Value],
      NULLIF(l.[Law Firm], '') AS [Law Firm],
      NULLIF(NULLIF(l.[Court No],'N/A'), '') AS [Court No],
      NULLIF(l.[Next Hearing Date], '') AS [Next Hearing Date],
      NULLIF(NULLIF(l.[Cheque Number], 'N/A'), '') AS [Cheque Number],
      l.RMName,
      NULLIF(l.Litigation_Receivable, '') AS Litigation_Receivable,
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


data <- dbGetQuery(con,query)

history <- dbGetQuery(con,
    paste0(
      "WITH ranked AS (
          SELECT
              caseid,
              HearingDate,
              CaseStatus,
              MakeDate,
              ROW_NUMBER() OVER (
                  PARTITION BY caseid, HearingDate, CaseStatus
                  ORDER BY MakeDate DESC
              ) AS rn
          FROM [dbo].[AnalyticsLitigationAccountHearing]
      )
      SELECT caseid, HearingDate, CaseStatus, MakeDate
      FROM ranked
      WHERE rn = 1
      ORDER BY caseid, HearingDate DESC, MakeDate DESC;"
    ))


history <- history %>%
  select(
    CaseID = caseid,
    hearing_date = HearingDate,
    case_status = CaseStatus,
    MakeDate
  )


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

data <- data %>%
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
  ) %>% 
  select(-.nhd) %>% 
  filter(SuitType != "Other")





rm(query, Validation, BD_Calender)

rm(query, Validation, BD_Calender)


save.image("data.RDS")


# ============================================================================
# GLOBAL HELPER FUNCTIONS -- shared across NI / ARA / ARAE tabs
# ============================================================================

format_lakh_crore <- function(x) {
  if (length(x) == 0 || is.na(x)) return(NA_character_)
  neg <- x < 0
  x <- round(abs(x))
  x_str <- format(x, scientific = FALSE)
  n <- nchar(x_str)
  
  if (n <= 3) {
    result <- x_str
  } else {
    last3 <- substr(x_str, n - 2, n)
    rest  <- substr(x_str, 1, n - 3)
    rest_rev <- paste(rev(strsplit(rest, "")[[1]]), collapse = "")
    groups <- regmatches(rest_rev, gregexpr(".{1,2}", rest_rev))[[1]]
    rest_comma <- paste(
      rev(sapply(groups, function(g) paste(rev(strsplit(g, "")[[1]]), collapse = ""))),
      collapse = ","
    )
    result <- paste0(rest_comma, ",", last3)
  }
  if (neg) result <- paste0("-", result)
  result
}

# ---- one label/value block inside the case-details expander ----
info_field <- function(label, value, accent = NULL) {
  display_value <- if (length(value) == 0 || is.na(value)) {
    "\u2014"
  } else if (inherits(value, "Date") || inherits(value, "POSIXct")) {
    format(value, "%b %d, %Y")
  } else if (is.character(value) && trimws(value) == "") {
    "\u2014"
  } else {
    as.character(value)
  }
  
  field_class <- if (!is.null(accent)) paste("case-detail-field", accent) else "case-detail-field"
  
  htmltools::div(
    class = field_class,
    htmltools::div(label, class = "case-detail-label"),
    htmltools::div(display_value, class = "case-detail-value")
  )
}

# ---- status text -> colored pill class ----
status_pill_class <- function(status) {
  s <- tolower(status)
  cls <- dplyr::case_when(
    grepl("withdraw", s)  ~ "status-withdrawn",
    grepl("warrant", s)   ~ "status-warrant",
    grepl("summon", s)    ~ "status-summon",
    grepl("step", s)      ~ "status-steps",
    grepl("paper", s)     ~ "status-paper",
    TRUE                  ~ "status-default"
  )
  cls
}


# ---- aging number -> colored pill class ----
aging_pill_class <- function(days) {
  if (is.na(days)) return(NA_character_)
  if (days < 30) "aging-low" else if (days < 90) "aging-mid" else "aging-high"
}

# ---- formats one field value for display (mirrors old info_field logic) ----
fmt_val <- function(value) {
  if (length(value) == 0 || is.na(value)) return("\u2014")
  if (inherits(value, "Date") || inherits(value, "POSIXct")) return(format(value, "%b %d, %Y"))
  if (is.character(value) && trimws(value) == "") return("\u2014")
  as.character(value)
}

# ---- formats a money value (lakh/crore) with dash fallback ----
fmt_money <- function(x) {
  v <- format_lakh_crore(x)
  if (length(v) == 0 || is.na(v)) "\u2014" else v
}

# ============================================================================
# LAZY CASE-DETAILS DATA
# Instead of pre-rendering an HTML panel (and a nested reactable) for every one
# of ~25k cases -- which makes the self-contained file enormous and blows up
# pandoc -- we serialise each case's detail values + hearing history ONCE as
# compact JSON. The panel is then built on-demand in the browser (see the
# renderDetails() JS) only when a row is actually expanded.
# ============================================================================
build_details_data <- function(data_all, history_all) {
  # only need history for cases actually present in the data
  history_all <- history_all %>% filter(CaseID %in% unique(data_all$CaseID))
  
  # one row per case for the detail cards
  case_rows <- data_all %>% distinct(CaseID, .keep_all = TRUE)
  
  details_by_case <- lapply(split(case_rows, case_rows$CaseID), function(r) {
    active <- !is.na(r$LitigationStatus) && r$LitigationStatus == "Active"
    list(
      # Case Info values (labels live in JS, in this exact order)
      ci = c(
        fmt_val(r$`Nature of Suit`),
        fmt_money(r$`Suit Value`),
        fmt_val(r$`Suit Filing Date`),
        fmt_val(r$`Law Firm`),
        fmt_val(r$`Court No`),
        fmt_val(r$`Next Hearing Date`),
        fmt_val(r$`Cheque Number`),
        fmt_money(r$Litigation_Receivable),
        fmt_val(r$`Present Case Status`),
        fmt_val(r$LitigationStatus)
      ),
      acc = if (active) "card-active" else "card-inactive",
      # Account Info values
      ai = c(
        fmt_val(r$RMName),
        fmt_val(r$PRODUCT_CATEGORY),
        fmt_money(r$URPA),
        fmt_money(r$OVERDUE_AMOUNT),
        fmt_money(r$PRINCIPAL_OD),
        fmt_money(r$INTEREST_OD),
        fmt_val(r$MOD),
        fmt_money(r$LPI),
        fmt_money(r$NetExciseDutyTillLastYear),
        fmt_money(r$NetExciseDutyTillCurrentYear)
      )
    )
  })
  
  hist2 <- history_all %>%
    arrange(CaseID, desc(hearing_date)) %>%
    group_by(CaseID) %>%
    mutate(
      next_hearing = lag(hearing_date),
      aging = round(time_length(interval(hearing_date, next_hearing), "day"))
    ) %>%
    ungroup() %>%
    mutate(
      d  = format(hearing_date, "%d-%b-%Y"),
      sc = status_pill_class(case_status),
      ac = vapply(aging, aging_pill_class, character(1))
    )
  
  history_by_case <- lapply(split(hist2, hist2$CaseID), function(h) {
    lapply(seq_len(nrow(h)), function(i) list(
      d  = h$d[i],
      s  = h$case_status[i],
      sc = h$sc[i],
      a  = h$aging[i],
      ac = h$ac[i]
    ))
  })
  
  list(
    details = jsonlite::toJSON(details_by_case, auto_unbox = TRUE, na = "string"),
    history = jsonlite::toJSON(history_by_case, auto_unbox = TRUE, na = "null")
  )
}

# ---- builds the filter panel (branch, CIF search, account search, product + status checkboxes) ----
# suffix must be unique per tab (e.g. "ni", "ara", "arae") to avoid id/JS collisions
render_filter_panel <- function(data_tab, table_id, suffix) {
  cif_lookup <- data_tab %>% distinct(Branch, LitigationStatus, CIF)
  account_lookup <- data_tab %>%
    distinct(Branch, LitigationStatus, PRODUCT_CATEGORY_LABEL, CIF, ClientName, AccountNumber)
  
  upcoming_labs <- c("Today","Next 5 Working Days","This Month","Next Month","Later","Not Updated","No Date")
  
  branch_select_id     <- paste0("branch-select-", suffix)
  cif_input_id         <- paste0("cif-input-", suffix)
  account_input_id     <- paste0("account-input-", suffix)
  cif_datalist_id      <- paste0("customer-options-", suffix)
  account_datalist_id  <- paste0("account-options-", suffix)
  status_group_id      <- paste0("litigation-status-filters-", suffix)
  status_cb_class      <- paste0("litigation-status-cb-", suffix)
  product_group_id     <- paste0("product-filters-", suffix)
  product_cb_class     <- paste0("product-cb-", suffix)
  update_cif_fn        <- paste0("updateCifOptions_", suffix)
  update_status_fn     <- paste0("updateLitigationStatusFilter_", suffix)
  update_product_fn    <- paste0("updateProductFilter_", suffix)
  update_account_fn    <- paste0("updateAccountOptions_", suffix)
  clear_all_fn         <- paste0("clearAllFilters_", suffix)
  cif_lookup_var       <- paste0("cifLookup_", suffix)
  account_lookup_var   <- paste0("accountLookup_", suffix)
  
  clientname_input_id     <- paste0("clientname-input-", suffix)
  clientname_datalist_id  <- paste0("clientname-options-", suffix)
  update_clientname_fn    <- paste0("updateClientNameOptions_", suffix)
  
  upcoming_select_id   <- paste0("upcoming-select-", suffix)
  
  
  clear_customer_fn    <- paste0("clearCustomerFilters__", suffix)
  clear_account_fn     <- paste0("clearAccountFilters__", suffix)
  
  htmltools::tagList(
    htmltools::tags$script(htmltools::HTML(glue::glue("
      var {cif_lookup_var}     = {jsonlite::toJSON(cif_lookup, dataframe = 'rows')};
      var {account_lookup_var} = {jsonlite::toJSON(account_lookup, dataframe = 'rows')};
      

      function {update_cif_fn}() {{
        var branch = document.getElementById('{branch_select_id}').value;
        var acct = document.getElementById('{account_input_id}').value;
        var cname = document.getElementById('{clientname_input_id}').value;
        
        var statusChecked = Array.from(document.querySelectorAll('.{status_cb_class}'))
          .filter(function(b) {{ return b.checked; }}).map(function(b) {{ return b.value; }});
        var statusAll = statusChecked.length === document.querySelectorAll('.{status_cb_class}').length;
        var prodChecked = Array.from(document.querySelectorAll('.{product_cb_class}'))
          .filter(function(b) {{ return b.checked; }}).map(function(b) {{ return b.value; }});
        var prodAll = prodChecked.length === document.querySelectorAll('.{product_cb_class}').length;

        var matches = {account_lookup_var}.filter(function(row) {{
          var branchOk = (branch === '' || row.Branch === branch);
          var acctOk   = (acct === '' || String(row.AccountNumber).indexOf(acct) !== -1);
          var statusOk = (statusAll || statusChecked.includes(row.LitigationStatus));
          var prodOk   = (prodAll || prodChecked.includes(row.PRODUCT_CATEGORY_LABEL));
          var cnameOk  = (cname === '' || String(row.ClientName).indexOf(cname) !== -1);
          return branchOk && acctOk && statusOk && prodOk && cnameOk;
        }});

        var uniqueCifs = [...new Set(matches.map(function(r) {{ return r.CIF; }}))].sort();
        var datalist = document.getElementById('{cif_datalist_id}');
        datalist.innerHTML = '';
        uniqueCifs.forEach(function(cif) {{
          var opt = document.createElement('option');
          opt.value = cif;
          datalist.appendChild(opt);
        }});
      }}
      
      function {update_clientname_fn}() {{
        var branch = document.getElementById('{branch_select_id}').value;
        var cif = document.getElementById('{cif_input_id}').value;
        var acct = document.getElementById('{account_input_id}').value;
        var statusChecked = Array.from(document.querySelectorAll('.{status_cb_class}'))
          .filter(function(b) {{ return b.checked; }}).map(function(b) {{ return b.value; }});
        var statusAll = statusChecked.length === document.querySelectorAll('.{status_cb_class}').length;
        var prodChecked = Array.from(document.querySelectorAll('.{product_cb_class}'))
          .filter(function(b) {{ return b.checked; }}).map(function(b) {{ return b.value; }});
        var prodAll = prodChecked.length === document.querySelectorAll('.{product_cb_class}').length;

        var matches = {account_lookup_var}.filter(function(row) {{
          var branchOk = (branch === '' || row.Branch === branch);
          var cifOk    = (cif === '' || String(row.CIF).indexOf(cif) !== -1);
          var acctOk   = (acct === '' || String(row.AccountNumber).indexOf(acct) !== -1);
          var statusOk = (statusAll || statusChecked.includes(row.LitigationStatus));
          var prodOk   = (prodAll || prodChecked.includes(row.PRODUCT_CATEGORY_LABEL));
          return branchOk && cifOk && acctOk && statusOk && prodOk;
        }});

        var uniqueNames = [...new Set(matches.map(function(r) {{ return r.ClientName; }}))].sort();
        var datalist = document.getElementById('{clientname_datalist_id}');
        datalist.innerHTML = '';
        uniqueNames.forEach(function(nm) {{
          var opt = document.createElement('option');
          opt.value = nm;
          datalist.appendChild(opt);
        }});
      }}

      function {update_account_fn}() {{
        var branch = document.getElementById('{branch_select_id}').value;
        var cif = document.getElementById('{cif_input_id}').value;
        var statusChecked = Array.from(document.querySelectorAll('.{status_cb_class}'))
          .filter(function(b) {{ return b.checked; }}).map(function(b) {{ return b.value; }});
        var statusAll = statusChecked.length === document.querySelectorAll('.{status_cb_class}').length;
        var prodChecked = Array.from(document.querySelectorAll('.{product_cb_class}'))
          .filter(function(b) {{ return b.checked; }}).map(function(b) {{ return b.value; }});
        var prodAll = prodChecked.length === document.querySelectorAll('.{product_cb_class}').length;
        var cname = document.getElementById('{clientname_input_id}').value;

        var matches = {account_lookup_var}.filter(function(row) {{
          var branchOk = (branch === '' || row.Branch === branch);
          var cifOk    = (cif === '' || String(row.CIF).indexOf(cif) !== -1);
          var statusOk = (statusAll || statusChecked.includes(row.LitigationStatus));
          var prodOk   = (prodAll || prodChecked.includes(row.PRODUCT_CATEGORY_LABEL));
          var cnameOk  = (cname === '' || String(row.ClientName).indexOf(cname) !== -1);
          return branchOk && cifOk && statusOk && prodOk && cnameOk;
        }});

        var uniqueAccts = [...new Set(matches.map(function(r) {{ return r.AccountNumber; }}))].sort();
        var datalist = document.getElementById('{account_datalist_id}');
        datalist.innerHTML = '';
        uniqueAccts.forEach(function(a) {{
          var opt = document.createElement('option');
          opt.value = a;
          datalist.appendChild(opt);
        }});
      }}

      function {update_status_fn}() {{
        var boxes = document.querySelectorAll('.{status_cb_class}');
        var allChecked = true;
        var selected = [];
        boxes.forEach(function(b) {{
          if (b.checked) selected.push(b.value);
          else allChecked = false;
        }});
        Reactable.setFilter('{table_id}', 'LitigationStatus', allChecked ? undefined : selected);
        {update_cif_fn}();
        {update_account_fn}();
        {update_clientname_fn}();
      }}
      
      // ADD ClientName Filter

      function {update_product_fn}() {{
        var boxes = document.querySelectorAll('.{product_cb_class}');
        var allChecked = true;
        var selected = [];
        boxes.forEach(function(b) {{
          if (b.checked) selected.push(b.value);
          else allChecked = false;
        }});
        Reactable.setFilter('{table_id}', 'PRODUCT_CATEGORY_LABEL', allChecked ? undefined : selected);
        {update_cif_fn}();
        {update_account_fn}();
        {update_clientname_fn}();
      }}

      function {clear_all_fn}() {{
        console.log('All-Cleared')
        document.getElementById('{branch_select_id}').value = '';
        document.getElementById('{cif_input_id}').value = '';
        document.getElementById('{account_input_id}').value = '';
        document.querySelectorAll('.{status_cb_class}').forEach(function(b) {{ b.checked = (b.value === 'Active'); }});
        document.querySelectorAll('.{product_cb_class}').forEach(function(b) {{ b.checked = (b.value === 'SME'); }});
        document.getElementById('{clientname_input_id}').value = '';
        document.getElementById('{upcoming_select_id}').value = '';
        
        Reactable.setFilter('{table_id}', 'Branch', undefined);
        Reactable.setFilter('{table_id}', 'CIF', undefined);
        Reactable.setFilter('{table_id}', 'AccountNumber', undefined);
        Reactable.setFilter('{table_id}', 'LitigationStatus', undefined);
        Reactable.setFilter('{table_id}', 'PRODUCT_CATEGORY_LABEL', undefined);
        Reactable.setFilter('{table_id}', 'ClientName', undefined);
        Reactable.setFilter('{table_id}', 'upcoming', undefined);

        {update_status_fn}();
        {update_product_fn}();
        {update_cif_fn}();
        {update_account_fn}();
        {update_clientname_fn}();
      }}
      
      
      function {clear_customer_fn}() {{
        document.getElementById('{cif_input_id}').value = '';
        document.getElementById('{clientname_input_id}').value = '';
        
        Reactable.setFilter('{table_id}', 'CIF', undefined);
        Reactable.setFilter('{table_id}', 'ClientName', undefined);

        {update_status_fn}();
        {update_product_fn}();
        {update_cif_fn}();
        {update_clientname_fn}();
      }}
      
      function {clear_account_fn}() {{
        document.getElementById('{account_input_id}').value = '';
        Reactable.setFilter('{table_id}', 'AccountNumber', undefined);

        {update_status_fn}();
        {update_product_fn}();
        {update_account_fn}();
      }}

      // ---- apply Active-only + SME-only defaults on initial load ----
      (function() {{
        function initFilters() {{
          try {{
            // real column; setting undefined is a harmless no-op, but throws
            // 'instance not found' if the table hasn't mounted yet
            Reactable.setFilter('{table_id}', 'Branch', undefined);
          }} catch (e) {{
            setTimeout(initFilters, 100);
            return;
          }}
          if (!document.querySelector('.{status_cb_class}')
              || !document.querySelector('.{product_cb_class}')) {{
            setTimeout(initFilters, 100);
            return;
          }}
          {clear_all_fn}();
        }}
        initFilters();
      }})();
    "))),
    
    htmltools::tags$div(
      class = "filter-panel",
      
      htmltools::tags$a("⬇ Download CSV", class = "download-btn",
                        onclick = paste0("downloadFiltered('",table_id, "', 'litigation_",suffix,".csv')")),
      
      htmltools::tags$div(
        class = "filter-group",
        htmltools::tags$label("Branch", class = "filter-label"),
        htmltools::tags$select(
          id = branch_select_id,
          class = "filter-select",
          onchange = glue::glue("Reactable.setFilter('{table_id}', 'Branch', event.target.value); {update_cif_fn}(); {update_account_fn}(); {update_clientname_fn}(); {clear_account_fn}(); {clear_customer_fn}();"),
          htmltools::tags$option(value = "", "(All)"),
          lapply(sort(unique(data_tab$Branch)), htmltools::tags$option)
        )
      ),
      
      htmltools::tags$div(
        class = "filter-group",
        htmltools::tags$label("Client Name", class = "filter-label"),
        htmltools::tags$input(
          id = clientname_input_id,
          type = "text",
          class = "filter-search",
          list = clientname_datalist_id,
          oninput = glue::glue("Reactable.setFilter('{table_id}', 'ClientName', event.target.value === '' ? undefined : event.target.value); {update_cif_fn}(); {update_account_fn}(); {update_status_fn}();  {update_product_fn}(); {clear_account_fn}();"),
          placeholder = "Search Client Name..."
        ),
        htmltools::tags$datalist(
          id = clientname_datalist_id,
          lapply(sort(unique(data_tab$ClientName)), function(nm) htmltools::tags$option(value = nm))
        )
      ),
      
      htmltools::tags$div(
        class = "filter-group",
        htmltools::tags$label("Customer Number", class = "filter-label"),
        htmltools::tags$input(
          id = cif_input_id,
          type = "text",
          class = "filter-search",
          list = cif_datalist_id,
          oninput = glue::glue("Reactable.setFilter('{table_id}', 'CIF', event.target.value === '' ? undefined : event.target.value); {update_account_fn}(); {update_clientname_fn}(); {update_status_fn}();  {update_product_fn}(); {clear_account_fn}(); "),
          placeholder = "Search Customer..."
        ),
        htmltools::tags$datalist(
          id = cif_datalist_id,
          lapply(sort(unique(data_tab$CIF)), function(acc) htmltools::tags$option(value = acc))
        )
      ),
      
      htmltools::tags$div(
        class = "filter-group",
        htmltools::tags$label("Account Number", class = "filter-label"),
        htmltools::tags$input(
          id = account_input_id,
          type = "text",
          class = "filter-search",
          list = account_datalist_id,
          oninput = glue::glue("Reactable.setFilter('{table_id}', 'AccountNumber', event.target.value === '' ? undefined : event.target.value); {update_cif_fn}(); {update_clientname_fn}(); {update_status_fn}();  {update_product_fn}(); "),
          placeholder = "Search Account..."
        ),
        htmltools::tags$datalist(
          id = account_datalist_id,
          lapply(sort(unique(data_tab$AccountNumber)), function(acc) htmltools::tags$option(value = acc))
        )
      ),
      
      htmltools::tags$div(
        class = "filter-group",
        htmltools::tags$label("Upcoming Hearing", class = "filter-label"),
        htmltools::tags$select(
          id = upcoming_select_id,
          class = "filter-select",
          onchange = glue::glue("Reactable.setFilter('{table_id}', 'upcoming', event.target.value === '' ? undefined : event.target.value); {update_cif_fn}(); {update_account_fn}(); {update_clientname_fn}();"),
          htmltools::tags$option(value = "", "(All)"),
          lapply(upcoming_labs, htmltools::tags$option)
        )
      ),
      
      htmltools::tags$div(
        class = "filter-group",
        htmltools::tags$label("Product Category", class = "filter-label"),
        htmltools::tags$div(
          class = "checkbox-list",
          id = product_group_id,
          lapply(c("SME", sort(setdiff(unique(data_tab$PRODUCT_CATEGORY_LABEL), "SME"))), function(prod) {
            cb <- htmltools::tags$input(
              type = "checkbox",
              value = prod,
              class = product_cb_class,
              onchange = paste0(update_product_fn, "()")
            )
            if (prod == "SME") cb$attribs$checked <- "checked"
            htmltools::tags$label(cb, prod)
          })
        )
      ),
      
      htmltools::tags$div(
        class = "filter-group",
        htmltools::tags$label("Litigation Status", class = "filter-label"),
        htmltools::tags$div(
          class = "checkbox-list",
          id = status_group_id,
          lapply(sort(unique(data_tab$LitigationStatus)), function(status) {
            cb <- htmltools::tags$input(
              type = "checkbox",
              value = status,
              class = status_cb_class,
              onchange = paste0(update_status_fn, "()")
            )
            if (status == "Active") cb$attribs$checked <- "checked"
            htmltools::tags$label(cb, status)
          })
        )
      ),
      
      
      htmltools::tags$div(
        class = "filter-links",
        htmltools::tags$a("Clear all", onclick = paste0(clear_all_fn, "()"))
      )
    )
  )
}


# ---- builds the grouped reactable case table ----
render_case_table <- function(data_tab, history_tab, suit_label, table_id) {
  reactable(
    data_tab %>% select(all_of(c(
      "name_cif", "AccountNumber", "CaseID", "Branch", "LitigationStatus", "CIF", "PRODUCT_CATEGORY_LABEL", "ClientName", "upcoming", "in_this_month", "in_next_month"
    ))),
    elementId = table_id,
    theme = reactableTheme(style = list(fontFamily = "IDLC, sans-serif")),
    groupBy = c("name_cif", "AccountNumber"),
    columns = list(
      name_cif = colDef(
        minWidth = 320,
        name = "Name / CIF",
        aggregate = "unique",
        html = TRUE,
        grouped = JS("function(cellInfo) { return cellInfo.value }")
      ),
      AccountNumber = colDef(
        maxWidth = 300,
        minWidth = 250,
        name = "Account Number",
        aggregate = JS("function(values, rows) {
          let n = new Set(values).size;
          let s = n === 1 ? '' : 's';
          return n + ' Account' + s;
        }"),
        grouped = JS("function(cellInfo) { return cellInfo.value }")
      ),
      CaseID = colDef(
        maxWidth = 200,
        name = "Case ID",
        html = TRUE,  # required so the details JS return renders as HTML, not text
        aggregate = JS("function(values, rows) {
          let n = new Set(values).size;
          let s = n === 1 ? '' : 's';
          return n + ' Case' + s;
        }"),
        details = JS("function(rowInfo) { return renderCaseDetails(String(rowInfo.row['CaseID'])); }")
      ),
      Branch = colDef(maxWidth = 200, aggregate = JS("function(values, rows) { return values[0] }")),
      LitigationStatus = colDef(
        maxWidth = 150,
        name = "Litigation Status",
        aggregate = JS("function(values, rows) {
          let activeCount = values.filter(function(v) { return v === 'Active'; }).length;
          return activeCount + ' Active';
        }"),
        cell = function(value) {
          if (is.null(value) || is.na(value)) return("\u2014")
          cls <- if (value == "Active") "status-active" else "status-inactive"
          htmltools::span(value, class = paste("status-pill", cls))
        },
        # filterMethod = JS("
        #   function(rows, columnId, filterValue) {
        #     console.log('LitigationStatus filter', columnId, filterValue,
        #                 'sample row value=', rows[0] && rows[0].values[columnId]);
        #     if (!filterValue || filterValue.length === 0) return rows;
        #     return rows.filter(function(row) {
        #       return filterValue.includes(row.values[columnId]);
        #     });
        #   }
        # ")
        filterMethod = JS("
          function(rows, columnId, filterValue) {
            if (!filterValue || filterValue.length === 0) return rows;
            return rows.filter(function(row) {
              return filterValue.includes(row.values[columnId]);
            });
          }
        ")
      ),
      PRODUCT_CATEGORY_LABEL = colDef(
        show = FALSE,
        filterMethod = JS("
          function(rows, columnId, filterValue) {
            if (!filterValue || filterValue.length === 0) return rows;
            return rows.filter(function(row) {
              return filterValue.includes(row.values[columnId]);
            });
          }
        ")
      ),
      CIF = colDef(show = FALSE),
      ClientName = colDef(
        show = FALSE,
        filterMethod = JS("
          function(rows, columnId, filterValue) {
            if (!filterValue) return rows;
            return rows.filter(function(row) {
              return String(row.values[columnId]).toLowerCase().indexOf(String(filterValue).toLowerCase()) !== -1;
            });
          }
        ")
      ),
      upcoming = colDef(
        show = FALSE,
        filterMethod = JS("
          function(rows, columnId, filterValue) {
            if (!filterValue) return rows;
            // Month buckets use date-derived flags, not labels -- so a
            // 'Next 5 Working Days' row is counted in whichever month its
            // hearing date actually falls in.
            if (filterValue === 'This Month') {
              return rows.filter(function(row) { return row.values['in_this_month'] === true; });
            }
            if (filterValue === 'Next Month') {
              return rows.filter(function(row) { return row.values['in_next_month'] === true; });
            }
            return rows.filter(function(row) {
              return String(row.values[columnId]) === String(filterValue);
            });
          }
        ")
      ),
      in_this_month = colDef(show = FALSE),
      in_next_month = colDef(show = FALSE)
    ),
    rowStyle = JS("
      function(rowInfo) {
        if (!rowInfo) return {};
        if (rowInfo.level === 0) return { backgroundColor: '#FFFFFF', fontWeight: '400' };
        if (rowInfo.level === 1) return { backgroundColor: '#F9F9F9', fontWeight: '400' };
        return { backgroundColor: '#F3F3F3' };
      }
    "),
    bordered = TRUE,
    defaultPageSize = 50,
    showPageSizeOptions = TRUE,
    pageSizeOptions = c(25, 50, 100),
    paginationType = "jump"
  )
}















# =====================================================================
# SUMMARY -- pre-aggregated, reactable NATIVE filtering (no crosstalk)
# - Data is collapsed to one row per SuitType x Present_Case_Status x
#   Branch x Product. Statuses are unique within each suit.
# - groupBy = "SuitType": expand shows the status rows (one tier only).
# - Branch/Product filtering uses reactable's OWN column filters
#   (custom dropdowns) -- which CAN filter grouped/aggregated data,
#   unlike crosstalk. No Shiny, no second expand tier.
# =====================================================================

# ---- per-suit-type procedural status orderings ----
# Each suit type moves through a different sequence; these lists encode the
# real procedural order (filing -> evidence -> judgment -> disposal).
status_order_ni <- c(
  "Summon Return", "Account Statement Submission", "Paper Submission",
  "Report Submission", "Petition Hearing", "Charge Hearing",
  "Witness", "Cross Examination", "Defence Witness",
  "Argument", "Section-342", "Section-342/Argument", "WP&A",
  "For Judgment", "Judgment",
  "Warrant of Arrest", "For Withdraw", "Transferred",
  "Judgment & Decreed", "Withdrawn"
)

status_order_ara <- c(
  "Summon Return", "Court Fee Submission", "Paper Submission", "Written Statement",
  "Mediators Report Submission",
  "P.H.", "Petition Hearing", "Ex Parte Hearing",
  "Witness", "Cross Examination",
  "Argument", "For Order", "For Judgment",
  "For Withdraw",
  "Decreed", "Sole Decreed", "Judgment & Decreed", "Withdrawn"
)

status_order_arae <- c(
  "Summon Return", "Paper Submission", "Report Submission", "Steps",
  "Petition Hearing", "For Order",
  "Steps For Warrant of Arrest Under Section 34 (1)", "Warrant of Arrest",
  "Warrant of arrest to Borrower", "Warrant of arrest to Guarantor",
  "Deposition of money",
  "Certificate Under Section 33 (5)/33 (7)", "Certificate Received",
  "Transferred", "For Withdraw",
  "Disposed Under Section 33(9)", "Abated", "Withdrawn"
)

# Map the SuitType's *display name* to its ordering vector.
# Adjust these keys to match the exact strings in your `Nature of Suit` column.
status_orders <- list(
  "Negotiable Instrument Act (NI Act)"   = status_order_ni,
  "Artha Rin Aine (ARA)"                 = status_order_ara,
  "Artha Rin Aine Execution (ARAE)"      = status_order_arae
)

# Build a lookup: one row per (SuitType, Present_Case_Status, rank).
# Any status not in a suit's list gets a large rank (sorted to the bottom),
# and the "\u2014" missing bucket goes last of all.
build_status_rank <- function() {
  purrr::imap_dfr(status_orders, function(ord, suit) {
    tibble::tibble(
      SuitType            = suit,
      Present_Case_Status = ord,
      .status_rank        = seq_along(ord)
    )
  })
}

suits <- c("NI Act", "ARA", "ARAE")

build_summary_data <- function(data_all) {
  rank_lookup <- build_status_rank()
  
  data_all %>%
    distinct(CaseID, .keep_all = TRUE) %>%
    mutate(
      SuitValue     = suppressWarnings(as.numeric(`Suit Value`)),
      Receivable    = suppressWarnings(as.numeric(Litigation_Receivable)),
      OverdueAmount = suppressWarnings(as.numeric(OVERDUE_AMOUNT)),
      Aging         = suppressWarnings(as.numeric(Aging))
    ) %>%
    group_by(
      Branch,
      Product = PRODUCT_CATEGORY_LABEL,
      SuitType,
      Present_Case_Status = dplyr::coalesce(`Present Case Status`, "\u2014"),
      LitigationStatus,
      upcoming,
      in_this_month,
      in_next_month
    ) %>%
    summarise(
      Cases         = dplyr::n(),
      SuitValue     = sum(SuitValue, na.rm = TRUE),
      Receivable    = sum(Receivable, na.rm = TRUE),
      OverdueAmount = sum(OverdueAmount, na.rm = TRUE),
      Aging         = mean(Aging, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      dplyr::across(c(SuitValue, Receivable, OverdueAmount), ~tidyr::replace_na(., 0)),
      Aging = ifelse(is.nan(Aging), NA_real_, Aging)
    ) %>%
    dplyr::left_join(rank_lookup, by = c("SuitType", "Present_Case_Status")) %>%
    dplyr::mutate(
      .suit_rank   = match(SuitType, suits),                    # NI=1, ARA=2, ARAE=3
      .suit_rank   = dplyr::coalesce(.suit_rank, 999L),          # unknown suits last
      .status_rank = dplyr::case_when(
        Present_Case_Status == "\u2014" ~ 9999,
        is.na(.status_rank)             ~ 9000,
        TRUE                            ~ .status_rank
      )
    ) %>%
    dplyr::arrange(.suit_rank, .status_rank, Present_Case_Status) %>%   # suit order, then status order
    dplyr::select(-.status_rank, -.suit_rank)
}

# data_new <- build_summary_data(data)
# 
# 
# suits <- c("Negotiable Instrument Act (NI Act)","Artha Rin Aine (ARA)","Artha Rin Aine Execution (ARAE)")
# 
# data_new %>% 
#   select(SuitType, Present_Case_Status) %>% 
#   distinct() %>% 
#   filter(SuitType == suits[3]) %>% 
#   pull(Present_Case_Status)



summary_lakh_js <- "
  window.fmtLakhCr = function(num) {
    if (num == null || isNaN(num)) return '\u2014';
    var neg = num < 0; num = Math.round(Math.abs(num));
    var str = num.toString();
    if (str.length <= 3) return (neg?'-':'') + str;
    var last3 = str.slice(-3);
    var rest = str.slice(0, -3).replace(/\\B(?=(\\d{2})+(?!\\d))/g, ',');
    return (neg?'-':'') + rest + ',' + last3;
  };
"

render_summary <- function(data_all) {
  sdat <- build_summary_data(data_all)
  
  money_cell <- reactable::JS("function(ci){ return ci.value==null||isNaN(ci.value) ? '\u2014' : fmtLakhCr(ci.value); }")
  aging_cell <- reactable::JS("function(ci){ return ci.value==null||isNaN(ci.value) ? '\u2014' : Math.round(Math.abs(ci.value)) + ' Days'; }")
  
  # custom dropdown filter for a column: exact-match select of that column's values
  make_select_filter <- function(colId) {
    reactable::JS(sprintf("
      function(column, state) {
        var opts = [...new Set(state.data.map(function(r){ return r['%s']; }))].sort();
        var el = document.createElement('select');
        el.style.width = '100%%';
        el.onchange = function(e){ column.setFilter(e.target.value || undefined); };
        var all = document.createElement('option'); all.value = ''; all.text = 'All'; el.appendChild(all);
        opts.forEach(function(v){
          var o = document.createElement('option'); o.value = v; o.text = v;
          if (v === column.filterValue) o.selected = true;
          el.appendChild(o);
        });
        return el;
      }
    ", colId))
  }
  
  # exact-match filter method (select gives an exact value; group rows kept if any child matches)
  exact_filter <- reactable::JS("
    function(rows, columnId, filterValue) {
      if (!filterValue) return rows;          // <-- ADD THIS
      return rows.filter(function(row) {
        function anyMatch(r) {
          if (r.subRows && r.subRows.length) return r.subRows.some(anyMatch);
          return String(r.values[columnId]) === String(filterValue);
        }
        return anyMatch(row);
      });
    }
  ")
  
  array_filter <- reactable::JS("
    function(rows, columnId, filterValue) {
      if (!filterValue || filterValue.length === 0) return rows;
      return rows.filter(function(row) {
        function anyMatch(r) {
          if (r.subRows && r.subRows.length) return r.subRows.some(anyMatch);
          return filterValue.includes(r.values[columnId]);
        }
        return anyMatch(row);
      });
    }
  ")
  
  tbl <- reactable::reactable(
    sdat,
    groupBy = c("SuitType", "Present_Case_Status"),
    filterable = FALSE,
    # we enable filtering only on Branch/Product below
    defaultExpanded = FALSE,
    height = "calc(100vh - 150px)",
    theme = reactable::reactableTheme(
      style = list(fontFamily = "IDLC, sans-serif"),
      footerStyle = list(
        fontWeight = 700,
        background = "#EEF2F8",
        color = "#203764",
        borderTop = "2px solid #203764"
      )
    ), 
    columns = list(
      SuitType = reactable::colDef(
        name = "Nature of Suit",
        grouped = JS("function(cellInfo) { return cellInfo.value }"),
        footer = "Total"
      ),
      Present_Case_Status = reactable::colDef(
        name = "Present Case Status",
        minWidth = 220,
        grouped = JS("function(cellInfo) { return cellInfo.value }")
      ),
      
      Cases         = reactable::colDef(
        name = "Cases",
        aggregate = "sum",
        footer = reactable::JS("
          function(colInfo) {
            var t = colInfo.data.reduce(function(a, r){ return a + (r['Cases'] || 0); }, 0);
            return t.toLocaleString('en-IN');
          }
        ")
      ),
      SuitValue     = reactable::colDef(
        name = "Suit Value",
        aggregate = "sum",
        aggregated = money_cell,
        cell = money_cell,
        footer = reactable::JS("
          function(colInfo) {
            var t = colInfo.data.reduce(function(a, r){ return a + (r['SuitValue'] || 0); }, 0);
            return fmtLakhCr(t);
          }
        ")
      ),
      Receivable    = reactable::colDef(
        name = "Receivable",
        aggregate = "sum",
        aggregated = money_cell,
        cell = money_cell,
        footer = reactable::JS("
          function(colInfo) {
            var t = colInfo.data.reduce(function(a, r){ return a + (r['Receivable'] || 0); }, 0);
            return fmtLakhCr(t);
          }
        ")
      ),
      OverdueAmount = reactable::colDef(
        name = "Overdue",
        aggregate = "sum",
        aggregated = money_cell,
        cell = money_cell,
        footer = reactable::JS("
          function(colInfo) {
            var t = colInfo.data.reduce(function(a, r){ return a + (r['OverdueAmount'] || 0); }, 0);
            return fmtLakhCr(t);
          }
        ")
      ),
      Aging         = reactable::colDef(
        name = "Aging (Avg.)",
        aggregate = "mean",
        aggregated = aging_cell,
        cell = aging_cell,
        footer = reactable::JS("
          function(colInfo) {
            var num = 0, den = 0;
            colInfo.data.forEach(function(r) {
              var a = r['Aging'], n = r['Cases'] || 0;
              if (a != null && !isNaN(a) && n > 0) {
                num += Math.abs(a) * n;
                den += n;
              }
            });
            if (!den) return '\u2014';
            return Math.round(num / den) + ' Days';
          }
        ")
      ),
      
      # Branch / Product: shown as filter rows via custom dropdowns, but the
      # column body itself hidden (we don't want them as visible columns).
      Branch = reactable::colDef(
        show = FALSE,
        filterable = TRUE,
        filterInput = make_select_filter("Branch"),
        filterMethod = exact_filter
      ),
      Product = reactable::colDef(
        show = FALSE,
        filterable = TRUE,
        filterInput = make_select_filter("Product"),
        filterMethod = array_filter
      ),
      LitigationStatus = reactable::colDef(
        show = FALSE,
        filterable = TRUE,
        filterInput = make_select_filter("LitigationStatus"),
        filterMethod = array_filter
      ),
      in_this_month = colDef(show = FALSE),
      in_next_month = colDef(show = FALSE),
      upcoming = colDef(
        show = FALSE,
        filterable = TRUE,
        filterInput = make_select_filter("upcoming"),
        filterMethod = JS("
          function(rows, columnId, filterValue) {
            if (!filterValue) return rows;
            // Month buckets use date-derived flags, not labels -- so a
            // 'Next 5 Working Days' row is counted in whichever month its
            // hearing date actually falls in.
            if (filterValue === 'This Month') {
              return rows.filter(function(row) { return row.values['in_this_month'] === true; });
            }
            if (filterValue === 'Next Month') {
              return rows.filter(function(row) { return row.values['in_next_month'] === true; });
            }
            return rows.filter(function(row) {
              return String(row.values[columnId]) === String(filterValue);
            });
          }
        ")
      )
    ),
    bordered = TRUE,
    highlight = TRUE,
    defaultPageSize = 25,
    showPageSizeOptions = TRUE,
    pageSizeOptions = c(10, 25, 50),
    elementId = "summary-table"
  )
  
  # Because Branch/Product are hidden, their filter inputs won't render in the
  # header. So expose them as external dropdowns that drive the same filters.
  branches   <- sort(unique(sdat$Branch))
  products   <- c("SME", sort(setdiff(unique(sdat$Product), "SME")))
  lit_status <- sort(unique(sdat$LitigationStatus))
  upcoming_labs   <- c("Today","Next 5 Working Days","This Month","Next Month","Later","Not Updated")
  
  
  
  
  # checkbox group -> Reactable.setFilter with an array (undefined if all checked)
  cb_group <- function(label, values, cb_class, fn_name, default_checked = NULL) {
    htmltools::div(
      class = "filter-group",          # <-- was summary-filter-group
      htmltools::tags$label(label, class = "filter-label"),
      htmltools::div(
        class = "checkbox-list",
        lapply(values, function(v) {
          cb <- htmltools::tags$input(
            type = "checkbox", value = v, class = cb_class,
            onchange = paste0(fn_name, "()")
          )
          if (is.null(default_checked) || v %in% default_checked) {
            cb$attribs$checked <- "checked"
          }
          htmltools::tags$label(cb, v)
        })
      )
    )
  }
  
  filter_bar <- htmltools::div(
    class = "filter-panel",
    id = "summary-filter-panel",
    # ---- Branch: dropdown ----
    htmltools::div(
      class = "filter-group",
      htmltools::tags$label("Branch", class = "filter-label"),
      htmltools::tags$select(
        class = "filter-select",
        onchange = "Reactable.setFilter('summary-table', 'Branch', this.value || undefined)",
        htmltools::tags$option(value = "", "(All)"),
        lapply(branches, htmltools::tags$option)
      )
    ),
    
    cb_group("Product Category",  products,   "sum-product-cb", "updateSumProduct", default_checked = "SME"),
    cb_group("Litigation Status", lit_status, "sum-status-cb",  "updateSumStatus"),
    
    htmltools::div(
      class = "filter-group",
      htmltools::tags$label("Upcoming Hearing", class = "filter-label"),
      htmltools::tags$select(
        class = "filter-select",
        onchange = "Reactable.setFilter('summary-table', 'upcoming', this.value || undefined)",
        htmltools::tags$option(value = "", "(All)"),
        lapply(upcoming_labs, htmltools::tags$option)
      )
    ),
    
    htmltools::div(
      class = "filter-links",
      htmltools::tags$a("Clear all", onclick = "clearSummaryFilters()")
    )
  )
  
  
  table <- htmltools::tagList(
    htmltools::tags$script(htmltools::HTML(summary_lakh_js)),
    htmltools::tags$script(htmltools::HTML("
      function sumApply(cbClass, colId) {
        var boxes = document.querySelectorAll('.' + cbClass);
        var selected = [], allChecked = true;
        boxes.forEach(function(b) {
          if (b.checked) selected.push(b.value); else allChecked = false;
        });
        Reactable.setFilter('summary-table', colId, allChecked ? undefined : selected);
      }
      function updateSumProduct() { sumApply('sum-product-cb', 'Product'); }
      function updateSumStatus()  { sumApply('sum-status-cb',  'LitigationStatus'); }

      function clearSummaryFilters() {
        document.querySelectorAll('#summary-filter-panel select.filter-select').forEach(function(s){ s.value = ''; });
        document.querySelectorAll('.sum-product-cb').forEach(function(b){ b.checked = (b.value === 'SME'); });
        document.querySelectorAll('.sum-status-cb').forEach(function(b){ b.checked = true; });
        Reactable.setFilter('summary-table', 'Branch', undefined);
        Reactable.setFilter('summary-table', 'upcoming', undefined);
        updateSumProduct(); updateSumStatus();
      }

      // apply the SME-only default once the table has mounted
      (function initSummaryFilters() {
        try { Reactable.setFilter('summary-table', 'Branch', undefined); }
        catch (e) { setTimeout(initSummaryFilters, 100); return; }
        updateSumProduct(); updateSumStatus();
      })();
    ")),
    htmltools::div(class = "summary-breakdown-wrap", tbl),
    htmltools::tags$script(htmltools::HTML("
      (function() {
        function neutralize() {
          var tbl = document.getElementById('summary-table');
          if (!tbl) { setTimeout(neutralize, 200); return; }

          // Capture-phase click blocker: if the click is on a 2nd-level
          // (Present Case Status) group row, stop it before reactable expands it.
          tbl.addEventListener('click', function(e) {
            var cell = e.target.closest('.rt-td, [role=\"cell\"], td');
            if (!cell) return;
            var row = cell.parentElement;
            if (!row) return;
            var idx = Array.prototype.indexOf.call(row.children, cell);
            // The expander lives in the grouping cell. If a status-level group
            // cell (col 1) is what triggered it, block expansion.
            // We detect a status-level GROUP row by: col-1 cell has group content
            // AND col-0 (SuitType) cell in this row is empty (nested row).
            var firstCell = row.children[0];
            var isNested = firstCell && firstCell.textContent.trim() === '';
            var statusCell = row.children[1];
            var statusIsGroup = statusCell && statusCell.querySelector('[class*=\"expander\"], button');
            if (isNested && statusIsGroup) {
              e.stopPropagation();
              e.preventDefault();
            }
          }, true);  // <-- true = capture phase, runs BEFORE reactable's handler

          // also hide the arrows visually
          var apply = function() {
            tbl.querySelectorAll('[class*=\"expander\"], button.rt-expander').forEach(function(btn) {
              var cell = btn.closest('.rt-td, [role=\"cell\"], td');
              if (!cell) return;
              var row = cell.parentElement;
              if (!row) return;
              if (Array.prototype.indexOf.call(row.children, cell) === 1) {
                var firstCell = row.children[0];
                if (firstCell && firstCell.textContent.trim() === '') {
                  btn.style.visibility = 'hidden';
                }
              }
            });
          };
          apply();
          new MutationObserver(apply).observe(tbl, { childList: true, subtree: true });
        }
        neutralize();
      })();
    "))
    )
  
  list(
    filter = filter_bar,
    table = table
  )
}