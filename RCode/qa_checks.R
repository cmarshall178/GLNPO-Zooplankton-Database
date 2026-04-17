library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(here)

required_columns <- c(
  "sample_num", "station", "sample_type", "species_name",
  "species_code", "organism_count", "source_file"
)

check_missing_required <- function(df) {
  df |>
    dplyr::mutate(row_id = dplyr::row_number()) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(required_columns),
      names_to = "field",
      values_to = "value"
    ) |>
    dplyr::filter(is.na(value) | value == "") |>
    dplyr::select(row_id, source_file, sample_num, field)
}

check_negative_counts <- function(df) {
  df |>
    dplyr::filter(!is.na(organism_count), organism_count < 0)
}

check_nonpositive_split_factor <- function(df) {
  df |>
    dplyr::filter(is.na(split_factor) | split_factor <= 0) |>
    dplyr::distinct(source_file, sample_num, split, split_factor)
}

check_unexpected_sex_values <- function(df) {
  allowed <- c("F", "M", "J", "U", NA_character_)
  df |>
    dplyr::filter(!(sex %in% allowed)) |>
    dplyr::distinct(source_file, sample_num, species_name, sex)
}

check_duplicate_organism_rows <- function(df) {
  df |>
    dplyr::count(
      source_file, sample_num, station, sample_type, split, species_name,
      species_code, subgroup, group_code, length_mm, sex, organism_count,
      name = "n_duplicates"
    ) |>
    dplyr::filter(n_duplicates > 1)
}

check_station_standardization <- function(df) {
  df |>
    dplyr::filter(!is.na(station_raw), station_raw != station) |>
    dplyr::distinct(source_file, sample_num, station_raw, station)
}

check_qa_links <- function(df) {
  sample_ids <- unique(df$sample_num)

  df |>
    dplyr::filter(!is.na(qa_link)) |>
    dplyr::mutate(
      qa_target_present = qa_link %in% sample_ids,
      qa_self_link = qa_link == sample_num
    ) |>
    dplyr::filter(!qa_target_present | qa_self_link) |>
    dplyr::distinct(source_file, sample_num, qa_link, qa_target_present, qa_self_link)
}

make_qa_summary <- function(missing_required, negative_counts, nonpositive_split_factor,
                            unexpected_sex_values, duplicate_organism_rows,
                            station_standardization, qa_link_issues) {
  tibble::tibble(
    check = c(
      "missing_required",
      "negative_counts",
      "nonpositive_split_factor",
      "unexpected_sex_values",
      "duplicate_organism_rows",
      "station_standardization",
      "qa_link_issues"
    ),
    n_rows_flagged = c(
      nrow(missing_required),
      nrow(negative_counts),
      nrow(nonpositive_split_factor),
      nrow(unexpected_sex_values),
      nrow(duplicate_organism_rows),
      nrow(station_standardization),
      nrow(qa_link_issues)
    )
  )
}

write_qa_summary <- function(df) {
  out_path <- here::here("outputs", "tables", "qa_summary.csv")
  readr::write_csv(df, out_path)
  out_path
}
