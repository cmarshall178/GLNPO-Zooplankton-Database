# This script finds and imports raw Excel files and metadata workbooks.
# Raw counting sheets are read as text to avoid Excel type-guessing issues.
# Clean column names
# Protocol is inferred from file names ending in Zoop.xlsx or Rot.xlsx.
# Import the master sample list used to validate sample IDs

find_raw_files <- function(include_examples = FALSE) {
  default_raw_dir <- here::here("data", "raw")
  
  # Optional Box Drive path.
  # Set in .Renviron as:
  # GLNPO_BOX_PATH=C:/Users/yourname/Box/GLNPO Zooplankton
  box_dir <- Sys.getenv("GLNPO_BOX_PATH", unset = "")
  
  raw_dir <- dplyr::case_when(
    nzchar(box_dir) && fs::dir_exists(box_dir) ~ box_dir,
    TRUE ~ default_raw_dir
  )
  
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
  
  # Ignore temporary Excel lock files.
  all_files <- all_files[!stringr::str_detect(fs::path_file(all_files), "^~\\$")]
  
  sort(all_files)
}

classify_protocol <- function(path) {
  file_name <- fs::path_file(path)
  
  dplyr::case_when(
    stringr::str_detect(file_name, stringr::regex("Rot\\.xlsx$", ignore_case = TRUE)) ~ "rot",
    stringr::str_detect(file_name, stringr::regex("Zoop\\.xlsx$", ignore_case = TRUE)) ~ "zoop",
    TRUE ~ NA_character_
  )
}

read_zoop_excel <- function(path, sheet = 1) {
  raw_root <- Sys.getenv("GLNPO_BOX_PATH", unset = "")
  
  if (!nzchar(raw_root) || !fs::dir_exists(raw_root)) {
    raw_root <- here::here("data", "raw")
  }
  
  readxl::read_excel(
    path = path,
    sheet = sheet,
    col_types = "text"
  ) |>
    janitor::clean_names(
      replace = c("µ" = "u")
    ) |>
    dplyr::select(-dplyr::matches("^unnamed")) |>
    dplyr::mutate(
      source_file = fs::path_rel(path, start = raw_root),
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

read_master_zoop <- function(path) {
  readxl::read_excel(
    path = path,
    sheet = "Zooplankton",
    col_types = "text"
  ) |>
    janitor::clean_names(
      replace = c("µ" = "u")
    ) |>
    dplyr::rename(
      station_master = station_id,
      sample_num = sample_id,
      depth_code = depth_code
    ) |>
    dplyr::mutate(
      sample_num = stringr::str_squish(as.character(sample_num)),
      station_master = stringr::str_squish(as.character(station_master)),
      station_master = stringr::str_to_upper(station_master),
      station_master = stringr::str_replace_all(station_master, "\\s+", ""),
      station_master = stringr::str_replace(
        station_master,
        "^([A-Z]+)([0-9].*)$",
        "\\1 \\2"
      ),
      depth_code = stringr::str_to_upper(
        stringr::str_squish(as.character(depth_code))
      )
    ) |>
    dplyr::select(
      sample_num,
      station_master,
      depth_code
    ) |>
    dplyr::distinct()
}

read_species_key <- function(path) {
  zoop_key <- readxl::read_excel(
    path = path,
    sheet = "Zoops",
    col_types = "text"
  ) |>
    janitor::clean_names(
      replace = c("µ" = "u")
    ) |>
    dplyr::mutate(protocol = "zoop", .before = 1)
  
  rot_key <- readxl::read_excel(
    path = path,
    sheet = "Rots",
    col_types = "text"
  ) |>
    janitor::clean_names(
      replace = c("µ" = "u")
    ) |>
    dplyr::mutate(protocol = "rot", .before = 1)
  
  dplyr::bind_rows(zoop_key, rot_key) |>
    dplyr::rename(
      key_species_name = combo,
      key_species_code = speccode,
      key_subgroup = subgroup,
      key_group_code = group
    ) |>
    dplyr::mutate(
      protocol = stringr::str_to_lower(protocol),
      key_species_name = stringr::str_squish(as.character(key_species_name)),
      key_species_code = stringr::str_to_upper(
        stringr::str_squish(as.character(key_species_code))
      ),
      key_subgroup = stringr::str_to_upper(
        stringr::str_squish(as.character(key_subgroup))
      ),
      key_group_code = stringr::str_to_upper(
        stringr::str_squish(as.character(key_group_code))
      )
    ) |>
    dplyr::select(
      protocol,
      key_species_name,
      key_species_code,
      key_subgroup,
      key_group_code
    ) |>
    dplyr::distinct()
}