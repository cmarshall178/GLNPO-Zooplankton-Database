# This script contains QA rules.
#
# Each function checks for one type of issue and returns the rows or samples
# that should be reviewed.
#
# Examples:
#   - missing required values
#   - negative organism counts
#   - inconsistent split factors
#   - sample IDs not found in the master list
#   - Zoop D-split taxa outside the allowed list
#   - Rot measurement rules for length and width
#   - incorrect power used by protocol

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
    dplyr::select(row_id, protocol, source_file, sample_num, split, field)
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

check_unexpected_sex_values <- function(
    df,
    allowed = c("F", "M", "J", "U", NA_character_)
) {
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
      protocol,
      source_file,
      sample_num,
      qa_link,
      qa_target_present,
      qa_self_link
    )
}

check_split_factor_consistency <- function(df) {
  df |>
    dplyr::filter(!is.na(split), split != "") |>
    dplyr::group_by(protocol, source_file, sample_num, split) |>
    dplyr::summarise(
      n_distinct_split_factor = dplyr::n_distinct(split_factor, na.rm = TRUE),
      split_factors = paste(
        sort(unique(split_factor[!is.na(split_factor)])),
        collapse = ", "
      ),
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
    dplyr::filter(
      !is.na(row_id),
      is.na(analyst_date),
      !is.na(analyst_date_raw),
      stringr::str_trim(as.character(analyst_date_raw)) != ""
    ) |>
    dplyr::select(
      row_id,
      protocol,
      source_file,
      sample_num,
      split,
      analyst_date_raw
    ) |>
    dplyr::distinct()
}

check_missing_split_on_counted_rows <- function(df) {
  df |>
    dplyr::filter(!is.na(organism_count), organism_count > 0, is.na(split)) |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      species_name,
      organism_count
    )
}

check_unknown_protocol <- function(df) {
  df |>
    dplyr::filter(is.na(protocol)) |>
    dplyr::distinct(source_file, source_name)
}

# -------------------------------
# Master sample list checks
# -------------------------------

check_sample_not_in_master <- function(df, master) {
  df |>
    dplyr::filter(!is_qa_sample) |>
    dplyr::filter(!(sample_num %in% master$sample_num)) |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      station,
      sample_type
    )
}

check_station_mismatch_vs_master <- function(df, master) {
  df |>
    dplyr::filter(!is_qa_sample) |>
    dplyr::inner_join(master, by = "sample_num") |>
    dplyr::filter(station != station_master) |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      station,
      station_master
    )
}

check_depth_mismatch_vs_master <- function(df, master) {
  df |>
    dplyr::filter(!is_qa_sample) |>
    dplyr::inner_join(master, by = "sample_num") |>
    dplyr::filter(sample_type != depth_code) |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      sample_type,
      depth_code
    )
}

check_d20_sample_id_suffix <- function(df) {
  df |>
    dplyr::filter(!is_qa_sample) |>
    dplyr::filter(sample_type == "D20") |>
    dplyr::filter(!stringr::str_detect(sample_num, "4$")) |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      station,
      sample_type
    )
}

check_d100_sample_id_suffix <- function(df) {
  df |>
    dplyr::filter(!is_qa_sample) |>
    dplyr::filter(protocol == "zoop", sample_type == "D100") |>
    dplyr::filter(!stringr::str_detect(sample_num, "3$")) |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      station,
      sample_type
    )
}

check_rot_not_allowed_in_d100 <- function(df) {
  df |>
    dplyr::filter(!is_qa_sample) |>
    dplyr::filter(protocol == "rot", sample_type == "D100") |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      station,
      sample_type
    )
}

check_d20_missing_protocol_pair <- function(df) {
  d20_pairs <- df |>
    dplyr::filter(!is_qa_sample) |>
    dplyr::filter(sample_type == "D20") |>
    dplyr::distinct(station, sample_num, protocol)
  
  d20_expected <- d20_pairs |>
    dplyr::distinct(station, sample_num) |>
    tidyr::crossing(protocol = c("zoop", "rot"))
  
  d20_expected |>
    dplyr::anti_join(
      d20_pairs,
      by = c("station", "sample_num", "protocol")
    ) |>
    dplyr::distinct(station, sample_num, protocol)
}

# -------------------------------
# Species key checks
# -------------------------------

check_species_code_not_in_key <- function(df, species_key) {
  valid_codes <- species_key |>
    dplyr::distinct(protocol, key_species_code)
  
  df |>
    dplyr::mutate(
      species_code = stringr::str_to_upper(
        stringr::str_squish(as.character(species_code))
      )
    ) |>
    dplyr::anti_join(
      valid_codes,
      by = c("protocol" = "protocol", "species_code" = "key_species_code")
    ) |>
    dplyr::distinct(
      row_id,
      protocol,
      source_file,
      sample_num,
      split,
      species_name,
      species_code,
      subgroup,
      group_code
    )
}

check_species_metadata_mismatch <- function(df, species_key) {
  df_standard <- df |>
    dplyr::mutate(
      species_name = stringr::str_squish(as.character(species_name)),
      species_code = stringr::str_to_upper(
        stringr::str_squish(as.character(species_code))
      ),
      subgroup = stringr::str_to_upper(
        stringr::str_squish(as.character(subgroup))
      ),
      group_code = stringr::str_to_upper(
        stringr::str_squish(as.character(group_code))
      )
    )
  
  df_standard |>
    dplyr::inner_join(
      species_key,
      by = c("protocol" = "protocol", "species_code" = "key_species_code")
    ) |>
    dplyr::filter(
      species_name != key_species_name |
        subgroup != key_subgroup |
        group_code != key_group_code
    ) |>
    dplyr::distinct(
      row_id,
      protocol,
      source_file,
      sample_num,
      split,
      species_name,
      key_species_name,
      species_code,
      subgroup,
      key_subgroup,
      group_code,
      key_group_code
    )
}

# -------------------------------
# Zoop-specific checks
# -------------------------------

check_zoop_d_split_allowed_taxa <- function(df) {
  allowed_speccodes <- c(
    "LIMMACR",
    "SENCALA",
    "EPILACU",
    "HOLGIBB",
    "DIPBIRG",
    "DIPSP",
    "DIPFLUV",
    "LETKIND",
    "POLPEDI",
    "EURLAME",
    "SIDCRYS",
    "DAPLUMH"
  )
  
  df |>
    dplyr::filter(protocol == "zoop") |>
    dplyr::mutate(
      split = stringr::str_to_upper(as.character(split)),
      species_code = stringr::str_to_upper(
        stringr::str_squish(as.character(species_code))
      )
    ) |>
    dplyr::filter(split == "D") |>
    dplyr::filter(
      is.na(species_code) | !(species_code %in% allowed_speccodes)
    ) |>
    dplyr::distinct(
      source_file,
      sample_num,
      split,
      species_name,
      species_code,
      organism_count
    )
}

# -------------------------------
# Rot-specific checks
# -------------------------------

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
    dplyr::distinct(
      source_file,
      sample_num,
      split,
      submla_ml,
      submlb_ml,
      rot_subml_ml
    )
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

check_rot_required_length_and_width <- function(df) {
  df |>
    dplyr::filter(protocol == "rot") |>
    dplyr::mutate(
      species_code = stringr::str_to_upper(as.character(species_code))
    ) |>
    dplyr::filter(
      stringr::str_starts(species_code, "TRI") |
        stringr::str_starts(species_code, "CON") |
        stringr::str_starts(species_code, "COO") |
        stringr::str_starts(species_code, "FIL")
    ) |>
    dplyr::filter(is.na(length_mm) | is.na(width_mm) | width_mm <= 0) |>
    dplyr::mutate(
      expected_measurement_rule = "Both length_mm and width_mm required"
    ) |>
    dplyr::distinct(
      source_file,
      sample_num,
      split,
      species_name,
      species_code,
      length_mm,
      width_mm,
      expected_measurement_rule
    )
}

check_rot_collotheca_width_only <- function(df) {
  df |>
    dplyr::filter(protocol == "rot") |>
    dplyr::mutate(
      species_code = stringr::str_to_upper(as.character(species_code))
    ) |>
    dplyr::filter(stringr::str_starts(species_code, "COL")) |>
    dplyr::filter(is.na(width_mm) | width_mm <= 0) |>
    dplyr::mutate(
      expected_measurement_rule = "Width_mm required; length_mm not required"
    ) |>
    dplyr::distinct(
      source_file,
      sample_num,
      split,
      species_name,
      species_code,
      length_mm,
      width_mm,
      expected_measurement_rule
    )
}

check_rot_unexpected_width_without_length <- function(df) {
  df |>
    dplyr::filter(protocol == "rot") |>
    dplyr::mutate(
      species_code = stringr::str_to_upper(as.character(species_code))
    ) |>
    dplyr::filter(
      !is.na(width_mm),
      width_mm > 0,
      is.na(length_mm)
    ) |>
    dplyr::filter(
      !stringr::str_starts(species_code, "COL")
    ) |>
    dplyr::distinct(
      source_file,
      sample_num,
      split,
      species_name,
      species_code,
      width_mm,
      length_mm
    )
}

# -------------------------------
# Protocol power check
# -------------------------------

check_unexpected_power_used <- function(df) {
  df |>
    dplyr::filter(
      (protocol == "rot" & !is.na(power_used) & power_used != 100) |
        (protocol == "zoop" & !is.na(power_used) & power_used != 30)
    ) |>
    dplyr::distinct(
      protocol,
      source_file,
      sample_num,
      split,
      power_used
    )
}