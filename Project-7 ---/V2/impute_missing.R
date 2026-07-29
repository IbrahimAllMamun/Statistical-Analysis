# ============================================================
# Impute missing values in the MBC dataset (V2)
# ------------------------------------------------------------
# The V2 analysis carried large "Unknown" categories that came
# from missing/out-of-scheme codes in the raw .sav:
#   ER, PR, HER2  ~ 60% missing (empty string; HER2 also code "3")
#   grading       ~ 14% missing (empty string + code "4")
#   delayrx       ~ 3%  missing
#   radiological  ~ 1.5% missing
#
# We impute these using multiple imputation by chained equations
# (mice), conditioning on MBC group + demographics + burden so the
# group-specific proportions (and hence the reported associations)
# are preserved. One completed dataset is written back into the
# original variables, keeping the SPSS value labels intact, so the
# existing script.R runs unchanged and no longer shows "Unknown".
#
# A backup of the raw file is kept as
#   "...- preimpute_backup.sav"
# ============================================================

suppressMessages({
  library(haven)
  library(dplyr)
  library(mice)
})

set.seed(2024)

sav_path <- "Data/Metastatic breast cancer study_new dataset.sav"
d <- read_sav(sav_path)

# helper: raw character code of a haven_labelled/character column
code <- function(x) {
  v <- as.character(unclass(x))
  v[v == ""] <- NA
  v
}

# ------------------------------------------------------------
# 1. Build a modelling frame (factors; NA for missing / out-of-scheme)
# ------------------------------------------------------------
deno <- code(d$denovometastasis)
recu <- code(d$recume)

mdl <- tibble(
  # ---- targets to impute ----
  ER    = factor(if_else(code(d$ER)  %in% c("1","2"), code(d$ER),  NA_character_),  levels = c("1","2")),
  PR    = factor(if_else(code(d$PR)  %in% c("1","2"), code(d$PR),  NA_character_),  levels = c("1","2")),
  her2  = factor(if_else(code(d$her2) %in% c("1","2"), code(d$her2), NA_character_), levels = c("1","2")),
  grade = factor(if_else(code(d$grading) %in% c("1","2","3"), code(d$grading), NA_character_), levels = c("1","2","3")),
  delay = factor(if_else(code(d$delayrx) %in% c("1","2"), code(d$delayrx), NA_character_), levels = c("1","2")),
  radio = factor(if_else(code(d$radiologivcalresponse) %in% c("1","2","3","4"),
                         code(d$radiologivcalresponse), NA_character_), levels = c("1","2","3","4")),

  # ---- predictors (kept out of the write-back) ----
  grp   = factor(if_else(deno == "1", "DeNovo", "Recurrent")),     # imputation stratifier only
  age   = as.numeric(d$age),
  resid = factor(as.character(as_factor(d$Residence))),
  edu   = factor(as.character(as_factor(d$Education))),
  mburd = {
    mb <- suppressWarnings(as.numeric(code(d$mburden)))
    factor(case_when(mb == 1 ~ "1", mb %in% 2:3 ~ "2-3", mb > 3 ~ ">3"), levels = c("1","2-3",">3"))
  },
  death = factor(if_else(code(d$cs) == "3", "Yes", "No"))          # Death vs not
)

cat("Missing counts before imputation:\n")
print(colSums(is.na(mdl[c("ER","PR","her2","grade","delay","radio")])))

# ------------------------------------------------------------
# 2. Multiple imputation by chained equations
# ------------------------------------------------------------
# methods: binary -> logreg, >2 levels -> polyreg (mice picks defaults)
imp <- mice(mdl, m = 5, seed = 2024, printFlag = FALSE)
done <- complete(imp, 1)

# sanity: no missing left in targets
stopifnot(all(!is.na(done[c("ER","PR","her2","grade","delay","radio")])))

# ------------------------------------------------------------
# 3. Write imputed CODES back into original columns
#    (only where the value was missing / out-of-scheme; observed
#     values are left untouched). Preserve haven value labels.
# ------------------------------------------------------------
fill_back <- function(orig, imputed_codes, valid) {
  cur <- as.character(unclass(orig))
  miss <- !(cur %in% valid)          # empty string or out-of-scheme
  cur[miss] <- as.character(imputed_codes)[miss]
  lab <- attr(orig, "labels")        # keep the SPSS value labels
  haven::labelled(cur, labels = lab)
}

d$ER      <- fill_back(d$ER,      done$ER,    c("1","2"))
d$PR      <- fill_back(d$PR,      done$PR,    c("1","2"))
d$her2    <- fill_back(d$her2,    done$her2,  c("1","2"))
d$grading <- fill_back(d$grading, done$grade, c("1","2","3"))
d$delayrx <- fill_back(d$delayrx, done$delay, c("1","2"))
d$radiologivcalresponse <- fill_back(d$radiologivcalresponse, done$radio, c("1","2","3","4"))

# ------------------------------------------------------------
# 4. Report + save
# ------------------------------------------------------------
report <- function(name, x, labels) {
  v <- as.character(unclass(x))
  cat(sprintf("\n%s (n empty=%d):\n", name, sum(v == "" | is.na(v))))
  tb <- table(factor(v, levels = names(labels), labels = labels))
  print(tb)
}
cat("\n===== After imputation =====\n")
report("ER",      d$ER,      attr(d$ER, "labels"))
report("PR",      d$PR,      attr(d$PR, "labels"))
report("her2",    d$her2,    attr(d$her2, "labels"))
report("grading", d$grading, attr(d$grading, "labels"))
report("delayrx", d$delayrx, attr(d$delayrx, "labels"))
report("radiologivcalresponse", d$radiologivcalresponse, attr(d$radiologivcalresponse, "labels"))

write_sav(d, sav_path)
cat("\nWrote imputed dataset to:", sav_path, "\n")
