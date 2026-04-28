# This script contains helper functions used across the pipeline.
#
# Main jobs:
#   - Create required folders if they do not already exist
#   - Write compiled CSV files
#   - Write QA summary tables
#   - Write sample summary tables
#
# These functions help keep _targets.R cleaner and easier to read.

ensure_project_dirs <- function() {
  fs::dir_create(here::here("data", "raw"))
  fs::dir_create(here::here("data", "processed"))
  fs::dir_create(here::here("data", "metadata"))
  fs::dir_create(here::here("outputs", "tables"))
  fs::dir_create(here::here("outputs", "figures"))
}

write_compiled_zoop_data <- function(df) {
  out_path <- here::here("data", "processed", "compiled_zoop.csv")
  
  df |>
    dplyr::filter(protocol == "zoop") |>
    dplyr::select(
      -rotvol_ml,
      -submla_ml,
      -submlb_ml,
      -rot_subml_ml,
      -width_mm
    ) |>
    readr::write_csv(out_path)
  
  out_path
}


write_compiled_rot_data <- function(df) {
  out_path <- here::here("data", "processed", "compiled_rot.csv")
    
    df |>
      dplyr::filter(protocol == "rot") |>
      dplyr::select(
        -sex
      ) |>
      readr::write_csv(out_path)
    
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