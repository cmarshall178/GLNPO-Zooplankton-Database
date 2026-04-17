#install.packages("targets")
library(targets)
library(tarchetypes)
library(here)

source(here::here("RCode/import.R"))
source(here::here("RCode/clean.R"))
source(here::here("RCode/qa_checks.R"))
source(here::here("RCode/summarize.R"))
source(here::here("RCode/utils.R"))

tar_option_set(
  packages = c(
    "dplyr", "purrr", "readxl", "readr", "stringr", "tibble",
    "tidyr", "lubridate", "here", "fs", "janitor", "rmarkdown"
  )
)


list(
  tar_target(project_dirs, ensure_project_dirs(), cue = tar_cue(mode = "always")),

  tar_target(raw_files, find_raw_files(include_examples = TRUE)),
  tar_target(raw_data, read_all_zoop(include_examples = TRUE)),
  tar_target(clean_data, clean_zoop(raw_data)),
  tar_target(compiled_csv, write_compiled_data(clean_data), format = "file"),

  tar_target(missing_required, check_missing_required(clean_data)),
  tar_target(negative_counts, check_negative_counts(clean_data)),
  tar_target(nonpositive_split_factor, check_nonpositive_split_factor(clean_data)),
  tar_target(unexpected_sex_values, check_unexpected_sex_values(clean_data)),
  tar_target(duplicate_organism_rows, check_duplicate_organism_rows(clean_data)),
  tar_target(station_standardization, check_station_standardization(clean_data)),
  tar_target(qa_link_issues, check_qa_links(clean_data)),

  tar_target(
    qa_summary,
    make_qa_summary(
      missing_required = missing_required,
      negative_counts = negative_counts,
      nonpositive_split_factor = nonpositive_split_factor,
      unexpected_sex_values = unexpected_sex_values,
      duplicate_organism_rows = duplicate_organism_rows,
      station_standardization = station_standardization,
      qa_link_issues = qa_link_issues
    )
  ),
  tar_target(qa_summary_csv, write_qa_summary(qa_summary), format = "file"),

  tar_target(sample_summary, summarize_samples(clean_data)),
  tar_target(sample_summary_csv, write_sample_summary(sample_summary), format = "file"),

  tar_render(qa_report, "reports/qa_report.Rmd")
)
