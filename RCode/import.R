library(dplyr)
library(purrr)
library(readxl)
library(stringr)
library(tibble)
library(here)
library(fs)
library(janitor)

# Find raw Excel files placed directly in data/raw/.
# Example files stored in data/raw/examples/ are excluded by default.
find_raw_files <- function(include_examples = FALSE) {
  raw_dir <- here::here("data", "raw")
  all_files <- list.files(raw_dir, pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

  if (!include_examples) {
    all_files <- all_files[!stringr::str_detect(all_files, "examples")]
  }

  sort(all_files)
}

# Read a single workbook. The attached example files use row 1 as the header.
read_zoop_excel <- function(path, sheet = 1) {
  df <- readxl::read_excel(path, sheet = sheet) |>
    janitor::clean_names()

  # Remove pivot-summary artifact columns created inside some workbooks.
  df <- df |>
    dplyr::select(-dplyr::matches("^unnamed")) |>
    dplyr::mutate(source_file = basename(path), .before = 1)

  df
}

read_all_zoop <- function(include_examples = FALSE) {
  files <- find_raw_files(include_examples = include_examples)

  if (length(files) == 0) {
    return(tibble::tibble())
  }

  purrr::map_dfr(files, read_zoop_excel)
}
