ensure_project_dirs <- function() {
  fs::dir_create(here::here("data", "raw"))
  fs::dir_create(here::here("data", "processed"))
  fs::dir_create(here::here("data", "metadata"))
  fs::dir_create(here::here("outputs", "tables"))
  fs::dir_create(here::here("outputs", "figures"))
}

build_qa_summary <- function(...) {
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