library(readxl)
library(scorecard)
crg_main_dev_sample <- read_excel("Aggregated_MainDevelopmentSample.xlsx")

bin_tree_1 = scorecard::woebin(crg_main_dev_sample, y="Ever90DPD",
                               x = NULL, var_skip = c("LeadReferenceNo","OrganizationType", "FinanceDistrict"), 
                               positive = "bad|1", bin_num_limit = 6, method="tree")

bin_tree_2 = scorecard::woebin(crg_main_dev_sample, y="Ever90DPD",
                               x = NULL, var_skip = c("LeadReferenceNo","OrganizationType", "FinanceDistrict"), 
                               positive = "bad|1", bin_num_limit = 6, method="chimerge") 


num_vars <- setdiff(
  num_vars,
  c("Ever90DPD", "LeadReferenceNo","OrganizationType", "FinanceDistrict")
)

# Tree binning
num_vars <- c("AmountRequested",
              "AgeOfBusiness",
              "Retail",
              "WholeSale",
              "NetExposure",
              "CashSecurity",
              "TermInMonth",
              "LDeposit",
              "PrevHighestNetExposure",
              "NoOfLongTerm",
              "LongTermExposure",
              "NoOfShortTerm",
              "ShortTermExposure",
              "IsThirdPartyPayment",
              "IsTopupNetoffFinancing",
              "Godown",
              "Showroom",
              "Factory",
              "Office",
              "Rented",
              "Owned",
              "CostOfGoodsSold",
              "CurrentAssets",
              "FixedAssets",
              "GeneralAndAdministrativeExpenses",
              "NonOperatingProfit",
              "OtherAssets",
              "Sales",
              "ShortTermLiability",
              "DBRBeforeLoan",
              "DBRAfterLoan",
              "NetOperationProfitMargin",
              "OperatingProfitMargin",
              "TotalAssetTurnover",
              "FinancialLeverage",
              "PayableTurnover",
              "CashConvCycle",
              "DSCR",
              "DebtBurdenRatioAAL",
              "DebtBurdenRatioBAL",
              "NetProfitMarginAT",
              "ReturnOnEquity",
              "InventoryTurnover",
              "ReceivableTurnover",
              "GrossMargin",
              "ReturnOnAsset",
              "CurrentRatio",
              "QuickRatio",
              "BankTransaction",
              "InterestBurden",
              "NetExposuretoEquity",
              "FixedAssettoEquity"
)
bin_tree_1 <- scorecard::woebin(
  crg_main_dev_sample,
  y = "Ever90DPD",
  x = num_vars,
  positive = "bad|1",
  bin_num_limit = 6,
  method = "tree"
)

# ChiMerge binning
bin_tree_2 <- scorecard::woebin(
  crg_main_dev_sample,
  y = "Ever90DPD",
  x = num_vars,
  positive = "bad|1",
  bin_num_limit = 6,
  method = "chimerge"
)




bin_tree_2$AmountRequested
bin_tree_2$NetExposure
bin_tree_1$NetExposure



bin_summary_df <- data.table::rbindlist(bin_tree_1)
write.xlsx(bin_summary_df, file = "binning_tree_1.xlsx")

bin_summary_df2 <- data.table::rbindlist(bin_tree_2)
write.xlsx(bin_summary_df2, file = "binning_chi_merge.xlsx")



bin_tree_2 <- woebin(
  crg_main_dev_sample,
  y = "Ever90DPD",
  x = num_vars,
  positive = "bad|1",
  method = "chimerge"
)

breaks_list <- list(
  AmountRequested = c(1700000, 3000000)
)

bin_adj <- woebin(
  crg_main_dev_sample,
  y = "Ever90DPD",
  x = "AmountRequested",
  breaks_list = breaks_list,
  positive = "bad|1"
)
bin_adj$AmountRequested



breaks_list <- list(
  AmountRequested=c(2100000),
  AgeOfBusiness=c("14%,%missing"),
  Retail=c(75),
  WholeSale=c(70),
  NetExposure=c(2400000),
  CashSecurity=c(50000),
  TermInMonth=c(22),
  LDeposit=c(5000,50000),
  PrevHighestNetExposure=c(1500000,2700000),
  NoOfLongTerm=c(1,3),
  LongTermExposure=c(2200000),
  NoOfShortTerm=c(1,2),
  ShortTermExposure=c(225000),
  IsThirdPartyPayment=c(),
  Godown=c(1,2),
  Showroom=c(),
  Factory=c(),
  Office=c(),
  Rented=c(),
  Owned=c(),
  CostOfGoodsSold=c(),
  CurrentAssets=c(),
  FixedAssets=c(),
  GeneralAndAdministrativeExpenses=c(),
  NonOperatingProfit=c(),
  OtherAssets=c(),
  Sales=c(),
  ShortTermLiability=c(),
  DBRBeforeLoan=c(),
  DBRAfterLoan=c(),
  NetOperationProfitMargin=c(),
  OperatingProfitMargin=c(),
  TotalAssetTurnover=c(),
  FinancialLeverage=c(),
  PayableTurnover=c(),
  CashConvCycle=c(),
  DSCR=c(),
  DebtBurdenRatioAAL=c(),
  DebtBurdenRatioBAL=c(),
  NetProfitMarginAT=c(),
  ReturnOnEquity=c(),
  InventoryTurnover=c(),
  ReceivableTurnover=c(),
  GrossMargin=c(),
  ReturnOnAsset=c(),
  CurrentRatio=c(),
  QuickRatio=c(),
  BankTransaction=c(),
  InterestBurden=c(),
  NetExposuretoEquity=c(),
  FixedAssettoEquity=c()
  
)




#================================
breaks_list <- list(
  
  AmountRequested = c(1700000, 3000000),
  
  AgeOfBusiness = c("16%,%missing"),
  
  Retail = c(75),
  WholeSale = c(75),
  
  NetExposure = c(2000000, 2400000),
  
  CashSecurity = c(130000),
  
  TermInMonth = c(18, 22),
  
  LDeposit = c(5000, 50000),
  
  PrevHighestNetExposure = c(1500000, 2700000),
  
  NoOfLongTerm = c(1, 3),
  
  LongTermExposure = c(2200000),
  
  NoOfShortTerm = c(1, 2),
  
  ShortTermExposure = c(225000),
  
  IsTopupNetoffFinancing = c(1),
  
  Godown = c(1, 2),
  
  Showroom = c(1, 2, 3),
  
  Factory = c(1),
  
  Office = c(1),
  
  Rented = c(1),
  
  Owned = c(1),
  
  CostOfGoodsSold = c(30000000, 60000000, 130000000),
  
  CurrentAssets = c(5500000, 12000000, 16500000),
  
  FixedAssets = c(800000, 4200000, 8800000),
  
  GeneralAndAdministrativeExpenses = c(1400000, 1800000),
  
  OtherAssets = c(200000, 550000),
  
  Sales = c(40000000, 75000000, 140000000),
  
  ShortTermLiability = c(50000, 600000, 1850000),
  
  DBRBeforeLoan = c(0.20, 0.28, 0.44),
  
  DBRAfterLoan = c(0.41, 0.52),
  
  NetOperationProfitMargin = c(7.5, 10.5),
  
  OperatingProfitMargin = c(7.5, 10.5),
  
  TotalAssetTurnover = c(2, 3),
  
  FinancialLeverage = c(1.07, 1.35),
  
  PayableTurnover = c(12.5),
  
  CashConvCycle = c(95, 135),
  
  DSCR = c(1.95, 2.45),
  
  DebtBurdenRatioAAL = c(0.20, 0.28),
  
  DebtBurdenRatioBAL = c(0.07, 0.35),
  
  NetProfitMarginAT = c(7.5, 10.5),
  
  ReturnOnEquity = c(18, 31, 36),
  
  InventoryTurnover = c(75, 135),
  
  ReceivableTurnover = c(30, 48),
  
  GrossMargin = c(5, 12, 15),
  
  ReturnOnAsset = c(17, 24, 31),
  
  CurrentRatio = c(6, 12),
  
  QuickRatio = c(0.5, 5.5),
  
  BankTransaction = c(20, 60),
  
  InterestBurden = c(0.90, 0.93, 0.95),
  
  NetExposuretoEquity = c(9, 23),
  
  FixedAssettoEquity = c(24)
)

bin_custom <- scorecard::woebin(
  crg_main_dev_sample,
  y = "Ever90DPD",
  x = names(breaks_list),
  breaks_list = breaks_list,
  positive = "bad|1"
)
iv_table <- data.frame(
  Variable = names(bin_custom),
  IV = sapply(bin_custom, \(x) unique(x$total_iv))
) |>
  dplyr::arrange(desc(IV))

iv_table
bin_custom$AgeOfBusiness

bin_summary_df3 <- data.table::rbindlist(bin_custom)
write.xlsx(bin_summary_df3, file = "binning_chi_merge2.xlsx")

bin_custom$IsTopupNetoffFinancing



# Step 2: Turn bins into woe
bin_f_woe  = scorecard::woebin_ply(crg_main_dev_sample , bin_tree_1)
View(bin_f_woe)



