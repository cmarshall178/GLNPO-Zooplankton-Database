# Current Checks
# missing required fields
# negative organism counts
# missing or nonpositive split factors
# unexpected sex values
# duplicate organism rows
# station-name standardization issues
# broken or self-referential QA links

required_columns <- c(
  "sample_num",
  "station",
  "sample_type",
  "species_name",
  "species_code",
  "organism_count",
  "source_file"
)

check_missing_required <- function(df) {
  fields_to_check <- setdiff(required_columns, c("source_file", "sample_num"))
  
  df |>
    dplyr::mutate(
      row_id = dplyr::row_number(),
      dplyr::across(dplyr::all_of(fields_to_check), as.character)
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(fields_to_check),
      names_to = "field",
      values_to = "value"
    ) |>
    dplyr::filter(is.na(value) | stringr::str_trim(value) == "") |>
    dplyr::select(protocol, row_id, source_file, sample_num, split, field)
}

check_negative_counts <- function(df) {
  df |>
    dplyr::filter(!is.na(organism_count), organism_count < 0)
}

check_nonpositive_split_factor <- function(df) {
  df |>
    dplyr::filter(!is.na(split), is.na(split_factor) | split_factor <= 0) |>
    dplyr::distinct(protocol, source_file, sample_num, split, split_factor)
}

check_unexpected_sex_values <- function(df, allowed = c("F", "M", "J", "U", NA_character_)) {
  df |>
    dplyr::filter(!(sex %in% allowed)) |>
    dplyr::distinct(protocol, source_file, sample_num, split, species_name, sex)
}

check_duplicate_organism_rows <- function(df) {
  df |>
    dplyr::count(
      protocol,
      source_file,
      sample_num,
      split,
      station,
      sample_type,
      species_name,
      species_code,
      subgroup,
      group_code,
      length_mm,
      width_mm,
      sex,
      organism_count,
      analyst_date,
      name = "n_duplicates"
    ) |>
    dplyr::filter(n_duplicates > 1)
}

check_station_standardization <- function(df) {
  df |>
    dplyr::filter(!is.na(station_raw), station_raw != station) |>
    dplyr::distinct(protocol, source_file, sample_num, station_raw, station)
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
    dplyr::distinct(
      protocol, source_file, sample_num, qa_link,
      qa_target_present, qa_self_link
    )
}

check_split_factor_consistency <- function(df) {
  df |>
    dplyr::filter(!is.na(split) & split != "") |>
    dplyr::group_by(protocol, source_file, sample_num, split) |>
    dplyr::summarise(
      n_distinct_split_factor = dplyr::n_distinct(split_factor, na.rm = TRUE),
      split_factors = paste(sort(unique(split_factor[!is.na(split_factor)])), collapse = ", "),
      .groups = "drop"
    ) |>
    dplyr::filter(n_distinct_split_factor > 1)
}

check_multiple_analyst_dates <- function(df) {
  df |>
    dplyr::filter(!is.na(analyst_date), !is.na(split), split != "") |>
    dplyr::group_by(protocol, source_file, sample_num, split) |>
    dplyr::summarise(
      n_distinct_dates = dplyr::n_distinct(analyst_date),
      dates = paste(sort(unique(as.character(analyst_date))), collapse = ", "),
      .groups = "drop"
    ) |>
    dplyr::filter(n_distinct_dates > 1)
}

check_missing_analyst_date <- function(df) {
  df |>
    dplyr::filter(is.na(analyst_date)) |>
    dplyr::distinct(protocol, source_file, sample_num, split, analyst_date_raw)
}

check_missing_split_on_counted_rows <- function(df) {
  df |>
    dplyr::filter(!is.na(organism_count), organism_count > 0, is.na(split)) |>
    dplyr::distinct(protocol, source_file, sample_num, species_name, organism_count)
}

check_unknown_protocol <- function(df) {
  df |>
    dplyr::filter(is.na(protocol)) |>
    dplyr::distinct(source_file, source_name)
}

check_rot_missing_rotvol <- function(df) {
  df |>
    dplyr::filter(protocol == "rot", is.na(rotvol_ml)) |>
    dplyr::distinct(source_file, sample_num, split, rotvol_ml)
}

check_rot_missing_subml <- function(df) {
  df |>
    dplyr::filter(
      protocol == "rot",
      !is.na(split),
      split %in% c("A", "B"),
      is.na(rot_subml_ml)
    ) |>
    dplyr::distinct(source_file, sample_num, split, submla_ml, submlb_ml, rot_subml_ml)
}

check_rot_nonpositive_rotvol <- function(df) {
  df |>
    dplyr::filter(protocol == "rot", !is.na(rotvol_ml), rotvol_ml <= 0) |>
    dplyr::distinct(source_file, sample_num, split, rotvol_ml)
}

check_rot_nonpositive_subml <- function(df) {
  df |>
    dplyr::filter(protocol == "rot", !is.na(rot_subml_ml), rot_subml_ml <= 0) |>
    dplyr::distinct(source_file, sample_num, split, rot_subml_ml)
}

check_rot_unexpected_splits <- function(df) {
  df |>
    dplyr::filter(protocol == "rot") |>
    dplyr::filter(!is.na(split), !(split %in% c("A", "B"))) |>
    dplyr::distinct(source_file, sample_num, split)
}

check_rot_width_without_length <- function(df) {
  df |>
    dplyr::filter(protocol == "rot", !is.na(width_mm), is.na(length_mm)) |>
    dplyr::distinct(source_file, sample_num, split, species_name, width_mm, length_mm)
}