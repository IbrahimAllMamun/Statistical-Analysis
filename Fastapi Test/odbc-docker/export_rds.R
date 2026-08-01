# Load a save.image() workspace (data.RDS) and export every data.frame it
# contains to a UTF-8 CSV, plus a _columns.tsv describing each column's R class
# so the loader can restore correct SQL types.
#
# Usage: Rscript export_rds.R <in_file> <out_dir>

options(warn = 1)
args    <- commandArgs(trailingOnly = TRUE)
in_file <- if (length(args) >= 1) args[[1]] else "/work/data.RDS"
out_dir <- if (length(args) >= 2) args[[2]] else "/work/odbc-docker/export"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

e <- new.env()
message("Loading workspace: ", in_file)
# Undefined S4 classes (e.g. the saved odbc connection) only warn; load succeeds.
res <- try(suppressWarnings(load(in_file, envir = e)), silent = TRUE)
if (inherits(res, "try-error")) {
  message("FATAL: load() failed: ",
          conditionMessage(attr(res, "condition")))
  quit(status = 2)
}

objs <- ls(e)
message("Objects in workspace: ", paste(objs, collapse = ", "))

# Some objects (e.g. the saved `con` odbc connection) are S4 instances whose
# defining package isn't installed here; merely touching them errors. Skip those.
is_df <- function(n) {
  tryCatch(is.data.frame(get(n, envir = e)), error = function(err) FALSE)
}
df_names <- Filter(is_df, objs)
if (length(df_names) == 0) {
  message("FATAL: no data.frame objects found.")
  quit(status = 3)
}
message("Data-frame tables to export: ", paste(df_names, collapse = ", "))

meta <- data.frame(table = character(), column = character(),
                   rclass = character(), stringsAsFactors = FALSE)

for (nm in df_names) {
  df <- get(nm, envir = e)

  # Record ORIGINAL classes before any coercion.
  orig <- vapply(df, function(col) paste(class(col), collapse = "|"),
                 character(1))
  meta <- rbind(meta, data.frame(table = nm, column = names(df),
                                 rclass = as.character(orig),
                                 stringsAsFactors = FALSE))

  # Coerce to unambiguous, CSV-safe representations.
  for (cn in names(df)) {
    col <- df[[cn]]
    if (inherits(col, "Date")) {
      df[[cn]] <- format(col, "%Y-%m-%d")
    } else if (inherits(col, "POSIXct")) {
      df[[cn]] <- format(col, "%Y-%m-%d %H:%M:%S")
    } else if (is.factor(col)) {
      df[[cn]] <- as.character(col)
    } else if (is.list(col)) {
      df[[cn]] <- vapply(col, function(x) paste(unlist(x), collapse = ";"),
                         character(1))
    }
  }

  csv_path <- file.path(out_dir, paste0(nm, ".csv"))
  write.csv(df, csv_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  message(sprintf("  wrote %s  (%d rows x %d cols)",
                  csv_path, nrow(df), ncol(df)))
}

write.table(meta, file.path(out_dir, "_columns.tsv"), sep = "\t",
            row.names = FALSE, quote = FALSE, fileEncoding = "UTF-8")
message("Wrote ", file.path(out_dir, "_columns.tsv"))
message("DONE. Exported ", length(df_names), " table(s).")
