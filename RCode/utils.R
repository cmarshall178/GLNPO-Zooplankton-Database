
ensure_project_dirs <- function() {
  fs::dir_create(here::here("GLNPO Data", "Raw Data"))
  fs::dir_create(here::here("GLNPO Data", "Processed Data"))
  fs::dir_create(here::here("GLNPO Data", "Metadata"))
  fs::dir_create(here::here("Outputs", "Tables"))
  fs::dir_create(here::here("Outputs", "Tigures"))
}

make_qa_summary <- function(...) {
  checks <- list(...)
  
  tibble::tibble(
    check = names(checks),
    n_rows_flagged = purrr::map_int(checks, nrow)
  )
}

write_compiled_data <- function(df) {
  out_path <- here::here("data", "processed", "compiled_zooplankton.csv")
  readr::write_csv(df, out_path)
  out_path
}

write_qa_summary <- function(df) {
  out_path <- here::here("outputs", "tables", "qa_summary.csv")
  readr::write_csv(df, out_path)
  out_path
}

write_sample_summary <- function(df) {
  out_path <- here::here("outputs", "tables", "sample_summary.csv")
  readr::write_csv(df, out_path)
  out_path
}