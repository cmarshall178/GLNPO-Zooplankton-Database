# Find raw Excel files placed in data/raw/.
# Example files stored in data/raw/examples/ are excluded by default.
find_raw_files <- function(include_examples = FALSE) {
  raw_dir <- here::here("GLNPO Data", "Raw Data")
  
  if (!fs::dir_exists(raw_dir)) {
    stop("Raw data directory does not exist: ", raw_dir)
  }
  
  all_files <- list.files(
    path = raw_dir,
    pattern = "\\.[Xx][Ll][Ss][Xx]$",
    full.names = TRUE,
    recursive = TRUE
  )
  
  sort(all_files)
}

# Read a single workbook.
# Current example files use row 1 as the header.
read_zoop_excel <- function(path, sheet = 1) {
  df <- readxl::read_excel(
    path = path,
    sheet = sheet
  ) |>
    janitor::clean_names() |>
    dplyr::select(-dplyr::matches("^unnamed")) |>
    dplyr::mutate(source_file = base::basename(path), .before = 1)
  
  df
}

# Read and combine all raw workbooks into one data frame.
read_all_zoop <- function(include_examples = FALSE) {
  files <- find_raw_files(include_examples = include_examples)
  
  if (length(files) == 0) {
    return(tibble::tibble())
  }
  
  purrr::map_dfr(files, read_zoop_excel)
}
