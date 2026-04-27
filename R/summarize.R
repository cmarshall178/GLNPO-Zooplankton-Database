# This script creates sample-level summaries.
#
# Main jobs:
#   - Summarize Zoop samples separately from Rot samples
#   - Count rows, organisms, and taxa
#   - Count length and width measurements
#   - Include Rot-specific volume fields in Rot summaries only
#
# These summaries are written to outputs/tables/.

summarize_zoop_samples <- function(df) {
  df |>
    dplyr::filter(protocol == "zoop") |>
    dplyr::group_by(
      protocol,
      source_file,
      sample_num,
      station,
      sample_type,
      split,
      split_factor,
      is_qa_sample
    ) |>
    dplyr::summarise(
      n_rows = dplyr::n(),
      total_organisms = sum(organism_count, na.rm = TRUE),
      n_taxa = dplyr::n_distinct(species_name),
      n_length_measured = sum(!is.na(length_mm)),
      .groups = "drop"
    )
}

summarize_rot_samples <- function(df) {
  df |>
    dplyr::filter(protocol == "rot") |>
    dplyr::group_by(
      protocol,
      source_file,
      sample_num,
      station,
      sample_type,
      split,
      split_factor,
      is_qa_sample
    ) |>
    dplyr::summarise(
      n_rows = dplyr::n(),
      total_organisms = sum(organism_count, na.rm = TRUE),
      n_taxa = dplyr::n_distinct(species_name),
      rotvol_ml = dplyr::first(rotvol_ml[!is.na(rotvol_ml)], default = NA_real_),
      rot_subml_ml = dplyr::first(rot_subml_ml[!is.na(rot_subml_ml)], default = NA_real_),
      n_length_measured = sum(!is.na(length_mm)),
      n_width_measured = sum(!is.na(width_mm)),
      .groups = "drop"
    )
}