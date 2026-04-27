flag_from_row_id <- function(df, flagged_df, flag_name) {
  flagged_ids <- flagged_df |>
    dplyr::filter(!is.na(row_id)) |>
    dplyr::distinct(row_id) |>
    dplyr::mutate(flag_value = TRUE)
  
  df |>
    dplyr::left_join(flagged_ids, by = "row_id") |>
    dplyr::mutate(
      !!flag_name := dplyr::coalesce(.data$flag_value, FALSE)
    ) |>
    dplyr::select(-flag_value)
}

flag_from_keys <- function(df, flagged_df, by, flag_name) {
  flagged_keys <- flagged_df |>
    dplyr::distinct(dplyr::across(dplyr::all_of(by))) |>
    dplyr::mutate(flag_value = TRUE)
  
  df |>
    dplyr::left_join(flagged_keys, by = by) |>
    dplyr::mutate(
      !!flag_name := dplyr::coalesce(.data$flag_value, FALSE)
    ) |>
    dplyr::select(-flag_value)
}

add_flag_summary_columns <- function(df) {
  flag_cols <- names(df)[stringr::str_starts(names(df), "flag_")]
  
  if (length(flag_cols) == 0) {
    return(
      df |>
        dplyr::mutate(any_flag = FALSE, flag_count = 0L, flag_notes = "")
    )
  }
  
  df |>
    dplyr::rowwise() |>
    dplyr::mutate(
      any_flag = any(c_across(dplyr::all_of(flag_cols))),
      flag_count = sum(c_across(dplyr::all_of(flag_cols))),
      flag_notes = paste(
        names(which(unlist(dplyr::c_across(dplyr::all_of(flag_cols))))),
        collapse = "; "
      )
    ) |>
    dplyr::ungroup()
}

build_zoop_flagged_data <- function(
    zoop_data,
    zoop_missing_required,
    zoop_negative_counts,
    zoop_nonpositive_split_factor,
    zoop_unexpected_sex_values,
    zoop_duplicate_organism_rows,
    zoop_station_standardization,
    zoop_qa_link_issues,
    zoop_split_factor_consistency,
    zoop_multiple_analyst_dates,
    zoop_missing_analyst_date,
    zoop_missing_split_on_counted_rows,
    zoop_unexpected_power_used,
    zoop_d_split_allowed_taxa,
    sample_not_in_master,
    station_mismatch_vs_master,
    depth_mismatch_vs_master,
    d20_sample_id_suffix,
    d100_sample_id_suffix
) {
  out <- zoop_data
  
  out <- flag_from_row_id(out, zoop_missing_required, "flag_missing_required")
  out <- flag_from_row_id(out, zoop_negative_counts, "flag_negative_counts")
  
  out <- flag_from_keys(
    out, zoop_nonpositive_split_factor,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_nonpositive_split_factor"
  )
  
  out <- flag_from_keys(
    out, zoop_unexpected_sex_values,
    by = c("source_file", "sample_num", "split", "species_name", "sex"),
    flag_name = "flag_unexpected_sex_values"
  )
  
  out <- flag_from_keys(
    out, zoop_duplicate_organism_rows,
    by = c(
      "source_file", "sample_num", "split", "station", "sample_type",
      "species_name", "species_code", "subgroup", "group_code",
      "length_mm", "width_mm", "sex", "organism_count", "analyst_date"
    ),
    flag_name = "flag_duplicate_organism_rows"
  )
  
  out <- flag_from_keys(
    out, zoop_station_standardization,
    by = c("source_file", "sample_num", "station_raw", "station"),
    flag_name = "flag_station_standardized"
  )
  
  out <- flag_from_keys(
    out, zoop_qa_link_issues,
    by = c("source_file", "sample_num", "qa_link"),
    flag_name = "flag_qa_link_issue"
  )
  
  out <- flag_from_keys(
    out, zoop_split_factor_consistency,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_split_factor_consistency"
  )
  
  out <- flag_from_keys(
    out, zoop_multiple_analyst_dates,
    by = c("source_file", "sample_num", "split"),
    flag_name = "review_multiple_analyst_dates_in_split"
  )
  
  out <- flag_from_row_id(
    out, zoop_missing_analyst_date,
    flag_name = "flag_missing_analyst_date"
  )
  
  out <- flag_from_keys(
    out, zoop_missing_split_on_counted_rows,
    by = c("source_file", "sample_num", "species_name", "organism_count"),
    flag_name = "flag_missing_split_on_counted_rows"
  )
  
  out <- flag_from_keys(
    out, zoop_unexpected_power_used,
    by = c("source_file", "sample_num", "split", "power_used"),
    flag_name = "flag_unexpected_power_used"
  )
  
  out <- flag_from_keys(
    out, zoop_d_split_allowed_taxa,
    by = c("source_file", "sample_num", "split", "species_name", "species_code", "organism_count"),
    flag_name = "flag_d_split_taxon_not_allowed"
  )
  
  shared_master <- sample_not_in_master |>
    dplyr::filter(protocol == "zoop")
  
  out <- flag_from_keys(
    out, shared_master,
    by = c("source_file", "sample_num", "station", "sample_type"),
    flag_name = "flag_sample_not_in_master"
  )
  
  out <- flag_from_keys(
    out, station_mismatch_vs_master |>
      dplyr::filter(protocol == "zoop"),
    by = c("source_file", "sample_num", "station"),
    flag_name = "flag_station_mismatch_vs_master"
  )
  
  out <- flag_from_keys(
    out, depth_mismatch_vs_master |>
      dplyr::filter(protocol == "zoop"),
    by = c("source_file", "sample_num", "sample_type"),
    flag_name = "flag_depth_mismatch_vs_master"
  )
  
  out <- flag_from_keys(
    out, d20_sample_id_suffix |>
      dplyr::filter(protocol == "zoop"),
    by = c("source_file", "sample_num", "station", "sample_type"),
    flag_name = "flag_bad_d20_sample_id_suffix"
  )
  
  out <- flag_from_keys(
    out, d100_sample_id_suffix |>
      dplyr::filter(protocol == "zoop"),
    by = c("source_file", "sample_num", "station", "sample_type"),
    flag_name = "flag_bad_d100_sample_id_suffix"
  )
  
  add_flag_summary_columns(out)
}

build_rot_flagged_data <- function(
    rot_data,
    rot_missing_required,
    rot_negative_counts,
    rot_nonpositive_split_factor,
    rot_duplicate_organism_rows,
    rot_station_standardization,
    rot_qa_link_issues,
    rot_split_factor_consistency,
    rot_multiple_analyst_dates,
    rot_missing_analyst_date,
    rot_missing_split_on_counted_rows,
    rot_missing_rotvol,
    rot_missing_subml,
    rot_nonpositive_rotvol,
    rot_nonpositive_subml,
    rot_unexpected_splits,
    rot_required_length_and_width,
    rot_collotheca_width_only,
    rot_unexpected_width_without_length,
    rot_unexpected_power_used,
    sample_not_in_master,
    station_mismatch_vs_master,
    depth_mismatch_vs_master,
    d20_sample_id_suffix,
    rot_not_allowed_in_d100
) {
  out <- rot_data
  
  out <- flag_from_row_id(out, rot_missing_required, "flag_missing_required")
  out <- flag_from_row_id(out, rot_negative_counts, "flag_negative_counts")
  
  out <- flag_from_keys(
    out, rot_nonpositive_split_factor,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_nonpositive_split_factor"
  )
  
  out <- flag_from_keys(
    out, rot_duplicate_organism_rows,
    by = c(
      "source_file", "sample_num", "split", "station", "sample_type",
      "species_name", "species_code", "subgroup", "group_code",
      "length_mm", "width_mm", "sex", "organism_count", "analyst_date"
    ),
    flag_name = "flag_duplicate_organism_rows"
  )
  
  out <- flag_from_keys(
    out, rot_station_standardization,
    by = c("source_file", "sample_num", "station_raw", "station"),
    flag_name = "flag_station_standardized"
  )
  
  out <- flag_from_keys(
    out, rot_qa_link_issues,
    by = c("source_file", "sample_num", "qa_link"),
    flag_name = "flag_qa_link_issue"
  )
  
  out <- flag_from_keys(
    out, rot_split_factor_consistency,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_split_factor_consistency"
  )
  
  out <- flag_from_keys(
    out, rot_multiple_analyst_dates,
    by = c("source_file", "sample_num", "split"),
    flag_name = "review_multiple_analyst_dates_in_split"
  )
  
  out <- flag_from_row_id(
    out, rot_missing_analyst_date,
    flag_name = "flag_missing_analyst_date"
  )
  
  out <- flag_from_keys(
    out, rot_missing_split_on_counted_rows,
    by = c("source_file", "sample_num", "species_name", "organism_count"),
    flag_name = "flag_missing_split_on_counted_rows"
  )
  
  out <- flag_from_keys(
    out, rot_missing_rotvol,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_missing_rotvol"
  )
  
  out <- flag_from_keys(
    out, rot_missing_subml,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_missing_subml"
  )
  
  out <- flag_from_keys(
    out, rot_nonpositive_rotvol,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_nonpositive_rotvol"
  )
  
  out <- flag_from_keys(
    out, rot_nonpositive_subml,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_nonpositive_subml"
  )
  
  out <- flag_from_keys(
    out, rot_unexpected_splits,
    by = c("source_file", "sample_num", "split"),
    flag_name = "flag_unexpected_splits"
  )
  
  out <- flag_from_keys(
    out, rot_required_length_and_width,
    by = c("source_file", "sample_num", "split", "species_name", "species_code"),
    flag_name = "flag_required_length_and_width"
  )
  
  out <- flag_from_keys(
    out, rot_collotheca_width_only,
    by = c("source_file", "sample_num", "split", "species_name", "species_code"),
    flag_name = "flag_collotheca_missing_width"
  )
  
  out <- flag_from_keys(
    out, rot_unexpected_width_without_length,
    by = c("source_file", "sample_num", "split", "species_name", "species_code"),
    flag_name = "flag_unexpected_width_without_length"
  )
  
  out <- flag_from_keys(
    out, rot_unexpected_power_used,
    by = c("source_file", "sample_num", "split", "power_used"),
    flag_name = "flag_unexpected_power_used"
  )
  
  shared_master <- sample_not_in_master |>
    dplyr::filter(protocol == "rot")
  
  out <- flag_from_keys(
    out, shared_master,
    by = c("source_file", "sample_num", "station", "sample_type"),
    flag_name = "flag_sample_not_in_master"
  )
  
  out <- flag_from_keys(
    out, station_mismatch_vs_master |>
      dplyr::filter(protocol == "rot"),
    by = c("source_file", "sample_num", "station"),
    flag_name = "flag_station_mismatch_vs_master"
  )
  
  out <- flag_from_keys(
    out, depth_mismatch_vs_master |>
      dplyr::filter(protocol == "rot"),
    by = c("source_file", "sample_num", "sample_type"),
    flag_name = "flag_depth_mismatch_vs_master"
  )
  
  out <- flag_from_keys(
    out, d20_sample_id_suffix |>
      dplyr::filter(protocol == "rot"),
    by = c("source_file", "sample_num", "station", "sample_type"),
    flag_name = "flag_bad_d20_sample_id_suffix"
  )
  
  out <- flag_from_keys(
    out, rot_not_allowed_in_d100,
    by = c("source_file", "sample_num", "station", "sample_type"),
    flag_name = "flag_rot_not_allowed_in_d100"
  )
  
  add_flag_summary_columns(out)
}

write_flagged_zoop_data <- function(df) {
  out_path <- here::here("data", "processed", "compiled_zoop_flagged.csv")
  readr::write_csv(df, out_path)
  out_path
}

write_flagged_rot_data <- function(df) {
  out_path <- here::here("data", "processed", "compiled_rot_flagged.csv")
  readr::write_csv(df, out_path)
  out_path
}

write_zoop_flagged_only <- function(df) {
  out_path <- here::here("outputs", "tables", "zoop_flagged_only.csv")
  df |>
    dplyr::filter(any_flag) |>
    readr::write_csv(out_path)
  out_path
}

write_rot_flagged_only <- function(df) {
  out_path <- here::here("outputs", "tables", "rot_flagged_only.csv")
  df |>
    dplyr::filter(any_flag) |>
    readr::write_csv(out_path)
  out_path
}