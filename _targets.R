# This the control center of the entire workflow. It tells R:
# What to run, in what order, and when something needs to be re-run.
# This allows the project to have a reproducible pipeline.
# This creates a dependency chain: raw_data → clean_data → QA Flags and Report

# The workflow:
# find raw Excel files
# import all files
# clean and standardize them
# save a compiled CSV
#run QA checks
# write QA summary tables
# render a report

#Users usually do not need to run individual scripts manually.
# Instead, run:
#
#   targets::tar_make()
#
# The pipeline will:
#   1. Find raw Excel files
#   2. Import and clean the data
#   3. Separate Zoop and Rot protocols
#   4. Run QA checks
#   5. Write compiled and flagged CSV files
#   6. Generate the HTML QA report

# _targets.R
# Main pipeline controller for GLNPO Zooplankton + Rotifer QA workflow

library(targets)
library(tarchetypes)
library(here)

# Source all R scripts
source(here::here("R", "import.R"))
source(here::here("R", "clean.R"))
source(here::here("R", "qa_checks.R"))
source(here::here("R", "flagging.R"))
source(here::here("R", "summarize.R"))
source(here::here("R", "utils.R"))

# Global package dependencies
tar_option_set(
  packages = c(
    "dplyr",
    "purrr",
    "readxl",
    "readr",
    "stringr",
    "tibble",
    "tidyr",
    "lubridate",
    "here",
    "fs",
    "janitor",
    "rmarkdown"
  )
)

list(
  
  # -------------------------------
  # Project setup
  # -------------------------------
  tar_target(
    project_dirs,
    ensure_project_dirs(),
    cue = tar_cue(mode = "always")
  ),
  
  # -------------------------------
  # Metadata
  # -------------------------------
  tar_target(
    master_zoop,
    read_master_zoop(
      here::here("data", "metadata", "ALL 241 Sample ID_FINAL_03202024.xlsx")
    )
  ),
  
  tar_target(
    species_key,
    read_species_key(
      here::here("data", "metadata", "GLNPO Species List.xlsx")
    )
  ),
  
  # -------------------------------
  # Import + clean
  # -------------------------------
  tar_target(
    raw_files,
    find_raw_files(),
    format = "file"
  ),
  
  tar_target(
    raw_data,
    read_all_zoop()
  ),
  
  tar_target(
    unknown_protocol,
    check_unknown_protocol(raw_data)
  ),
  
  tar_target(
    clean_data,
    clean_zoop(raw_data)
  ),
  
  # -------------------------------
  # Split protocols
  # -------------------------------
  tar_target(
    zoop_data,
    dplyr::filter(clean_data, protocol == "zoop")
  ),
  
  tar_target(
    rot_data,
    dplyr::filter(clean_data, protocol == "rot")
  ),
  
  # -------------------------------
  # Write compiled data
  # -------------------------------
  tar_target(
    zoop_compiled_csv,
    write_compiled_zoop_data(clean_data),
    format = "file"
  ),
  
  tar_target(
    rot_compiled_csv,
    write_compiled_rot_data(clean_data),
    format = "file"
  ),
  
  # -------------------------------
  # MASTER LIST QA (ALL DATA)
  # -------------------------------
  tar_target(
    sample_not_in_master,
    check_sample_not_in_master(clean_data, master_zoop)
  ),
  
  tar_target(
    station_mismatch_vs_master,
    check_station_mismatch_vs_master(clean_data, master_zoop)
  ),
  
  tar_target(
    depth_mismatch_vs_master,
    check_depth_mismatch_vs_master(clean_data, master_zoop)
  ),
  
  tar_target(
    d20_sample_id_suffix,
    check_d20_sample_id_suffix(clean_data)
  ),
  
  tar_target(
    d100_sample_id_suffix,
    check_d100_sample_id_suffix(clean_data)
  ),
  
  tar_target(
    rot_not_allowed_in_d100,
    check_rot_not_allowed_in_d100(clean_data)
  ),
  
  tar_target(
    d20_missing_protocol_pair,
    check_d20_missing_protocol_pair(clean_data)
  ),
  
  # -------------------------------
  # SPECIES KEY QA
  # -------------------------------
  tar_target(
    species_code_not_in_key,
    check_species_code_not_in_key(clean_data, species_key)
  ),
  
  tar_target(
    species_metadata_mismatch,
    check_species_metadata_mismatch(clean_data, species_key)
  ),
  
  # -------------------------------
  # ZOOP QA
  # -------------------------------
  tar_target(zoop_missing_required, check_missing_required(zoop_data)),
  tar_target(zoop_negative_counts, check_negative_counts(zoop_data)),
  tar_target(zoop_nonpositive_split_factor, check_nonpositive_split_factor(zoop_data)),
  tar_target(zoop_unexpected_sex_values, check_unexpected_sex_values(zoop_data)),
  tar_target(zoop_duplicate_organism_rows, check_duplicate_organism_rows(zoop_data)),
  tar_target(zoop_station_standardization, check_station_standardization(zoop_data)),
  tar_target(zoop_qa_link_issues, check_qa_links(zoop_data)),
  tar_target(zoop_split_factor_consistency, check_split_factor_consistency(zoop_data)),
  tar_target(zoop_multiple_analyst_dates, check_multiple_analyst_dates(zoop_data)),
  tar_target(zoop_missing_analyst_date, check_missing_analyst_date(zoop_data)),
  tar_target(zoop_missing_split_on_counted_rows, check_missing_split_on_counted_rows(zoop_data)),
  tar_target(zoop_unexpected_power_used, check_unexpected_power_used(zoop_data)),
  tar_target(zoop_d_split_allowed_taxa, check_zoop_d_split_allowed_taxa(zoop_data)),
  
  # -------------------------------
  # ROT QA
  # -------------------------------
  tar_target(rot_missing_required, check_missing_required(rot_data)),
  tar_target(rot_negative_counts, check_negative_counts(rot_data)),
  tar_target(rot_nonpositive_split_factor, check_nonpositive_split_factor(rot_data)),
  tar_target(rot_duplicate_organism_rows, check_duplicate_organism_rows(rot_data)),
  tar_target(rot_station_standardization, check_station_standardization(rot_data)),
  tar_target(rot_qa_link_issues, check_qa_links(rot_data)),
  tar_target(rot_split_factor_consistency, check_split_factor_consistency(rot_data)),
  tar_target(rot_multiple_analyst_dates, check_multiple_analyst_dates(rot_data)),
  tar_target(rot_missing_analyst_date, check_missing_analyst_date(rot_data)),
  tar_target(rot_missing_split_on_counted_rows, check_missing_split_on_counted_rows(rot_data)),
  tar_target(rot_missing_rotvol, check_rot_missing_rotvol(rot_data)),
  tar_target(rot_missing_subml, check_rot_missing_subml(rot_data)),
  tar_target(rot_nonpositive_rotvol, check_rot_nonpositive_rotvol(rot_data)),
  tar_target(rot_nonpositive_subml, check_rot_nonpositive_subml(rot_data)),
  tar_target(rot_unexpected_splits, check_rot_unexpected_splits(rot_data)),
  tar_target(rot_required_length_and_width, check_rot_required_length_and_width(rot_data)),
  tar_target(rot_collotheca_width_only, check_rot_collotheca_width_only(rot_data)),
  tar_target(rot_unexpected_width_without_length, check_rot_unexpected_width_without_length(rot_data)),
  tar_target(rot_unexpected_power_used, check_unexpected_power_used(rot_data)),
  
  # -------------------------------
  # FLAGGED DATASETS
  # -------------------------------
  tar_target(
    zoop_flagged_data,
    build_zoop_flagged_data(
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
      d100_sample_id_suffix,
      species_code_not_in_key,
      species_metadata_mismatch
    )
  ),
  
  tar_target(
    rot_flagged_data,
    build_rot_flagged_data(
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
      rot_not_allowed_in_d100,
      species_code_not_in_key,
      species_metadata_mismatch
    )
  ),
  
  # -------------------------------
  # WRITE FLAGGED FILES
  # -------------------------------
  tar_target(
    zoop_flagged_csv,
    write_flagged_zoop_data(zoop_flagged_data),
    format = "file"
  ),
  
  tar_target(
    rot_flagged_csv,
    write_flagged_rot_data(rot_flagged_data),
    format = "file"
  ),
  
  tar_target(
    zoop_flagged_only_csv,
    write_zoop_flagged_only(zoop_flagged_data),
    format = "file"
  ),
  
  tar_target(
    rot_flagged_only_csv,
    write_rot_flagged_only(rot_flagged_data),
    format = "file"
  ),
  
  # -------------------------------
  # SUMMARIES
  # -------------------------------
  tar_target(
    zoop_sample_summary,
    summarize_zoop_samples(zoop_data)
  ),
  
  tar_target(
    rot_sample_summary,
    summarize_rot_samples(rot_data)
  ),
  
  # -------------------------------
  # QA REPORT
  # -------------------------------
  tar_render(
    qa_report,
    "reports/qa_report.Rmd"
  )
)