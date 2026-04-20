# This the control center of the entire workflow. It tells R:
# What to run, in what order, and when something needs to be re-run.
# This allows the project to have a reproducible pipeline.
# This creates a dependency chain: raw_data → clean_data → outliers

# The workflow:
# find raw Excel files
# import all files
# clean and standardize them
# save a compiled CSV
#run QA checks
# write QA summary tables
# render a report

library(targets)
library(here)

source(here::here("R", "import.R"))
source(here::here("R", "clean.R"))
source(here::here("R", "qa_checks.R"))
source(here::here("R", "summarize.R"))
source(here::here("R", "utils.R"))

tar_option_set(
  packages = c(
    "dplyr",
    "purrr",
    "readxl",
    "readr",
    "stringr",
    "tibble",
    "tidyr",
    "here",
    "fs",
    "janitor",
    "rmarkdown",
    "lubridate"
  )
)

list(
  tar_target(
    project_dirs,
    ensure_project_dirs(),
    cue = tar_cue(mode = "always")
  ),
  
  tar_target(
    raw_files,
    find_raw_files(include_examples = FALSE)
  ),
  
  tar_target(
    raw_data,
    read_all_zoop(include_examples = FALSE)
  ),
  
  tar_target(
    clean_data,
    clean_zoop(raw_data)
  ),
  
  tar_target(
    compiled_csv,
    write_compiled_data(clean_data),
    format = "file"
  ),
  
  tar_target(
    missing_required,
    check_missing_required(clean_data)
  ),
  
  tar_target(
    negative_counts,
    check_negative_counts(clean_data)
  ),
  
  tar_target(
    nonpositive_split_factor,
    check_nonpositive_split_factor(clean_data)
  ),
  
  tar_target(
    unexpected_sex_values,
    check_unexpected_sex_values(clean_data)
  ),
  
  tar_target(
    duplicate_organism_rows,
    check_duplicate_organism_rows(clean_data)
  ),
  
  tar_target(
    station_standardization,
    check_station_standardization(clean_data)
  ),
  
  tar_target(
    qa_link_issues,
    check_qa_links(clean_data)
  ),
  
  tar_target(
    qa_summary,
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
  ),
  
  tar_target(
    qa_summary_csv,
    write_qa_summary(qa_summary),
    format = "file"
  ),
  
  tar_target(
    sample_summary,
    summarize_samples(clean_data)
  ),
  
  tar_target(
    sample_summary_csv,
    write_sample_summary(sample_summary),
    format = "file"
  ),
  
  tar_target(
    qa_report,
    rmarkdown::render(
      input = here::here("reports", "qa_report.Rmd"),
      output_file = "qa_report.html",
      output_dir = here::here("outputs"),
      params = list(
        clean_data = clean_data,
        raw_files = raw_files,
        compiled_csv = compiled_csv,
        missing_required = missing_required,
        negative_counts = negative_counts,
        nonpositive_split_factor = nonpositive_split_factor,
        unexpected_sex_values = unexpected_sex_values,
        duplicate_organism_rows = duplicate_organism_rows,
        station_standardization = station_standardization,
        qa_link_issues = qa_link_issues,
        qa_summary = qa_summary,
        sample_summary = sample_summary,
        sample_summary_csv = sample_summary_csv
      ),
      envir = new.env(parent = globalenv())
    ),
    format = "file"
  )
)
  