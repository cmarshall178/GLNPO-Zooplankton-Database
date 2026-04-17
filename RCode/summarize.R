library(dplyr)
library(readr)
library(here)

summarize_samples <- function(df) {
  df |>
    dplyr::group_by(source_file, sample_num, station, sample_type, split_factor, is_qa_sample) |>
    dplyr::summarise(
      n_rows = dplyr::n(),
      total_organisms = sum(organism_count, na.rm = TRUE),
      n_taxa = dplyr::n_distinct(species_name),
      .groups = "drop"
    )
}

write_sample_summary <- function(df) {
  out_path <- here::here("outputs", "tables", "sample_summary.csv")
  readr::write_csv(df, out_path)
  out_path
}
