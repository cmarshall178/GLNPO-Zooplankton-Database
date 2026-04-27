# run these 3 lines to initiate the pipeline
rm(list = ls())
targets::tar_destroy(ask = FALSE)
targets::tar_make(callr_function = NULL, reporter = "verbose")


R.version.string
.libPaths()
renv::paths$library()

# if rstudio or R need updating- run these codes individually in the console
renv::status()
renv::restore()
renv::rebuild()
renv::snapshot()
targets::tar_make(callr_function = NULL, reporter = "verbose")