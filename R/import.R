# Find raw Excel files placed in data/raw/.
# Example files stored in data/raw/examples/ are excluded by default.
find_raw_files <- function(include_examples = FALSE) {
  raw_dir <- here::here("data", "raw")
  
  if (!fs::dir_exists(raw_dir)) {
    stop("Raw data directory does not exist: ", raw_dir)
  }
  
  all_files <- list.files(
    path = raw_dir,
    pattern = "\\.[Xx][Ll][Ss][Xx]$",
    full.names = TRUE,
    recursive = TRUE
  )
  
  if (!include_examples) {
    examples_dir <- here::here("data", "raw", "examples")
    all_files <- all_files[!stringr::str_detect(
      all_files,
      stringr::fixed(examples_dir)
    )]
  }
  
  sort(all_files)
}

classify_protocol <- function(path) {
  file_name <- fs::path_file(path)
  
  dplyr::case_when(
    stringr::str_detect(file_name, regex("Rot\\.xlsx$", ignore_case = TRUE)) ~ "rot",
    stringr::str_detect(file_name, regex("Zoop\\.xlsx$", ignore_case = TRUE)) ~ "zoop",
    TRUE ~ NA_character_
  )
}

read_zoop_excel <- function(path, sheet = 1) {
  readxl::read_excel(
    path = path,
    sheet = sheet,
    col_types = "text"
  ) |>
    janitor::clean_names() |>
    dplyr::select(-dplyr::matches("^unnamed")) |>
    dplyr::mutate(
      source_file = fs::path_rel(path, start = here::here("data", "raw")),
      source_name = fs::path_file(path),
      protocol = classify_protocol(path),
      .before = 1
    )
}

read_all_zoop <- function(include_examples = FALSE) {
  files <- find_raw_files(include_examples = include_examples)
  
  if (length(files) == 0) {
    return(tibble::tibble())
  }
  
  purrr::map_dfr(files, read_zoop_excel)
}