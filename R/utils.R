ensure_project_dirs <- function() {
  fs::dir_create(here::here("data", "raw"))
  fs::dir_create(here::here("data", "processed"))
  fs::dir_create(here::here("data", "metadata"))
  fs::dir_create(here::here("outputs", "tables"))
  fs::dir_create(here::here("outputs", "figures"))
}

write_compiled_data <- function(df, file_name) {
  out_path <- here::here("data", "processed", file_name)
  readr::write_csv(df, out_path)
  out_path
}

write_qa_summary <- function(df, file_name) {
  out_path <- here::here("outputs", "tables", file_name)
  readr::write_csv(df, out_path)
  out_path
}

write_sample_summary <- function(df, file_name) {
  out_path <- here::here("outputs", "tables", file_name)
  readr::write_csv(df, out_path)
  out_path
}

make_qa_summary <- function(check_list) {
  tibble::tibble(
    check = names(check_list),
    n_rows_flagged = purrr::map_int(check_list, nrow)
  )
}