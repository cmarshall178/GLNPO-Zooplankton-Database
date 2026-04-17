summarize_samples <- function(df) {
  df |>
    dplyr::group_by(
      source_file, sample_num, station, sample_type, split_factor, is_qa_sample
    ) |>
    dplyr::summarise(
      n_rows = dplyr::n(),
      total_organisms = sum(organism_count, na.rm = TRUE),
      n_taxa = dplyr::n_distinct(species_name),
      .groups = "drop"
    )
}