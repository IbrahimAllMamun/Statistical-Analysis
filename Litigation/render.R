rmarkdown::render(
  input       = "litigation_dashboard.RMD",
  output_file = "output/litigation_dashboard.html",
  output_dir  = "output/",
  envir       = new.env()
)