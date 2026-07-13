rmarkdown::render(
  input       = "litigation_dashboard_v2.Rmd",
  output_file = "output/litigation_dashboard.html",
  output_dir  = "output/",
  envir       = new.env()
)