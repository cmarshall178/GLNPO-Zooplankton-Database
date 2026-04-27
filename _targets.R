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

library(targets)
library(here)

source(here::here("R", "import.R"))
source(here::here("R", "clean.R"))
source(here::here("R", "qa_checks.R"))
source(here::here("R", "summarize.R"))
source(here::here("R", "utils.R"))
source(here::here("R", "flagging.R"))

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
    master_zoop,
    read_master_zoop(here::here("data", "metadata", "ALL 241 Sample ID_FINAL_03202024.xlsx"))
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
    unknown_protocol,
    check_unknown_protocol(raw_data)
  ),
  
  tar_target(
    clean_data,
    clean_zoop(raw_data)
  ),
  
  tar_target(
    sample_not_in_master,
    check_sample_not_in_master(clean_data, master_zoop)
  ),
  
  tar_target(
    master_sample_missing_in_data,
    check_master_sample_missing_in_data(clean_data, master_zoop)
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
  
  tar_target(
    zoop_data,
    dplyr::filter(clean_data, protocol == "zoop")
  ),
  
  tar_target(
    rot_data,
    dplyr::filter(clean_data, protocol == "rot")
  ),
  
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
  
  tar_target(
    zoop_d_split_allowed_taxa,
    check_zoop_d_split_allowed_taxa(zoop_data)
  ),
  
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
  
  tar_target(
    zoop_qa_summary,
    make_qa_summary(list(
      unknown_protocol = unknown_protocol,
      zoop_missing_required = zoop_missing_required,
      zoop_negative_counts = zoop_negative_counts,
      zoop_nonpositive_split_factor = zoop_nonpositive_split_factor,
      zoop_unexpected_sex_values = zoop_unexpected_sex_values,
      zoop_duplicate_organism_rows = zoop_duplicate_organism_rows,
      zoop_station_standardization = zoop_station_standardization,
      zoop_qa_link_issues = zoop_qa_link_issues,
      zoop_split_factor_consistency = zoop_split_factor_consistency,
      zoop_multiple_analyst_dates = zoop_multiple_analyst_dates,
      zoop_missing_analyst_date = zoop_missing_analyst_date,
      zoop_missing_split_on_counted_rows = zoop_missing_split_on_counted_rows,
      zoop_unexpected_power_used = zoop_unexpected_power_used,
      zoop_d_split_allowed_taxa = zoop_d_split_allowed_taxa,
      sample_not_in_master = sample_not_in_master,
      master_sample_missing_in_data = master_sample_missing_in_data,
      station_mismatch_vs_master = station_mismatch_vs_master,
      depth_mismatch_vs_master = depth_mismatch_vs_master,
      d20_sample_id_suffix = d20_sample_id_suffix,
      d100_sample_id_suffix = d100_sample_id_suffix,
      rot_not_allowed_in_d100 = rot_not_allowed_in_d100,
      d20_missing_protocol_pair = d20_missing_protocol_pair
    ))
  ),
  
  tar_target(
    rot_qa_summary,
    make_qa_summary(list(
      unknown_protocol = unknown_protocol,
      rot_missing_required = rot_missing_required,
      rot_negative_counts = rot_negative_counts,
      rot_nonpositive_split_factor = rot_nonpositive_split_factor,
      rot_duplicate_organism_rows = rot_duplicate_organism_rows,
      rot_station_standardization = rot_station_standardization,
      rot_qa_link_issues = rot_qa_link_issues,
      rot_split_factor_consistency = rot_split_factor_consistency,
      rot_multiple_analyst_dates = rot_multiple_analyst_dates,
      rot_missing_analyst_date = rot_missing_analyst_date,
      rot_missing_split_on_counted_rows = rot_missing_split_on_counted_rows,
      rot_missing_rotvol = rot_missing_rotvol,
      rot_missing_subml = rot_missing_subml,
      rot_nonpositive_rotvol = rot_nonpositive_rotvol,
      rot_nonpositive_subml = rot_nonpositive_subml,
      rot_unexpected_splits = rot_unexpected_splits,
      rot_required_length_and_width = rot_required_length_and_width,
      rot_collotheca_width_only = rot_collotheca_width_only,
      rot_unexpected_width_without_length = rot_unexpected_width_without_length,
      rot_unexpected_power_used = rot_unexpected_power_used,
      sample_not_in_master = sample_not_in_master,
      master_sample_missing_in_data = master_sample_missing_in_data,
      station_mismatch_vs_master = station_mismatch_vs_master,
      depth_mismatch_vs_master = depth_mismatch_vs_master,
      d20_sample_id_suffix = d20_sample_id_suffix,
      d100_sample_id_suffix = d100_sample_id_suffix,
      rot_not_allowed_in_d100 = rot_not_allowed_in_d100,
      d20_missing_protocol_pair = d20_missing_protocol_pair
    ))
  ),
  
  tar_target(
    zoop_qa_summary_csv,
    write_qa_summary(zoop_qa_summary, "zoop_qa_summary.csv"),
    format = "file"
  ),
  
  tar_target(
    rot_qa_summary_csv,
    write_qa_summary(rot_qa_summary, "rot_qa_summary.csv"),
    format = "file"
  ),
  
  tar_target(
    zoop_sample_summary,
    summarize_zoop_samples(zoop_data)
  ),
  
  tar_target(
    rot_sample_summary,
    summarize_rot_samples(rot_data)
  ),
  
  tar_target(
    zoop_sample_summary_csv,
    write_sample_summary(zoop_sample_summary, "zoop_sample_summary.csv"),
    format = "file"
  ),
  
  tar_target(
    rot_sample_summary_csv,
    write_sample_summary(rot_sample_summary, "rot_sample_summary.csv"),
    format = "file"
  ),
  
  tar_target(
    zoop_flagged_data,
    build_zoop_flagged_data(
      zoop_data = zoop_data,
      zoop_missing_required = zoop_missing_required,
      zoop_negative_counts = zoop_negative_counts,
      zoop_nonpositive_split_factor = zoop_nonpositive_split_factor,
      zoop_unexpected_sex_values = zoop_unexpected_sex_values,
      zoop_duplicate_organism_rows = zoop_duplicate_organism_rows,
      zoop_station_standardization = zoop_station_standardization,
      zoop_qa_link_issues = zoop_qa_link_issues,
      zoop_split_factor_consistency = zoop_split_factor_consistency,
      zoop_multiple_analyst_dates = zoop_multiple_analyst_dates,
      zoop_missing_analyst_date = zoop_missing_analyst_date,
      zoop_missing_split_on_counted_rows = zoop_missing_split_on_counted_rows,
      zoop_unexpected_power_used = zoop_unexpected_power_used,
      zoop_d_split_allowed_taxa = zoop_d_split_allowed_taxa,
      sample_not_in_master = sample_not_in_master,
      station_mismatch_vs_master = station_mismatch_vs_master,
      depth_mismatch_vs_master = depth_mismatch_vs_master,
      d20_sample_id_suffix = d20_sample_id_suffix,
      d100_sample_id_suffix = d100_sample_id_suffix
    )
  ),
  
  tar_target(
    rot_flagged_data,
    build_rot_flagged_data(
      rot_data = rot_data,
      rot_missing_required = rot_missing_required,
      rot_negative_counts = rot_negative_counts,
      rot_nonpositive_split_factor = rot_nonpositive_split_factor,
      rot_duplicate_organism_rows = rot_duplicate_organism_rows,
      rot_station_standardization = rot_station_standardization,
      rot_qa_link_issues = rot_qa_link_issues,
      rot_split_factor_consistency = rot_split_factor_consistency,
      rot_multiple_analyst_dates = rot_multiple_analyst_dates,
      rot_missing_analyst_date = rot_missing_analyst_date,
      rot_missing_split_on_counted_rows = rot_missing_split_on_counted_rows,
      rot_missing_rotvol = rot_missing_rotvol,
      rot_missing_subml = rot_missing_subml,
      rot_nonpositive_rotvol = rot_nonpositive_rotvol,
      rot_nonpositive_subml = rot_nonpositive_subml,
      rot_unexpected_splits = rot_unexpected_splits,
      rot_required_length_and_width = rot_required_length_and_width,
      rot_collotheca_width_only = rot_collotheca_width_only,
      rot_unexpected_width_without_length = rot_unexpected_width_without_length,
      rot_unexpected_power_used = rot_unexpected_power_used,
      sample_not_in_master = sample_not_in_master,
      station_mismatch_vs_master = station_mismatch_vs_master,
      depth_mismatch_vs_master = depth_mismatch_vs_master,
      d20_sample_id_suffix = d20_sample_id_suffix,
      rot_not_allowed_in_d100 = rot_not_allowed_in_d100
    )
  ),
  
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
  
  tar_target(
    qa_report,
    rmarkdown::render(
      input = here::here("reports", "qa_report.Rmd"),
      output_file = "qa_report.html",
      output_dir = here::here("outputs"),
      params = list(
        raw_files = raw_files,
        unknown_protocol = unknown_protocol,
        zoop_data = zoop_data,
        rot_data = rot_data,
        zoop_qa_summary = zoop_qa_summary,
        rot_qa_summary = rot_qa_summary,
        zoop_sample_summary = zoop_sample_summary,
        rot_sample_summary = rot_sample_summary,
        zoop_missing_required = zoop_missing_required,
        zoop_negative_counts = zoop_negative_counts,
        zoop_nonpositive_split_factor = zoop_nonpositive_split_factor,
        zoop_unexpected_sex_values = zoop_unexpected_sex_values,
        zoop_duplicate_organism_rows = zoop_duplicate_organism_rows,
        zoop_station_standardization = zoop_station_standardization,
        zoop_qa_link_issues = zoop_qa_link_issues,
        zoop_split_factor_consistency = zoop_split_factor_consistency,
        zoop_multiple_analyst_dates = zoop_multiple_analyst_dates,
        zoop_missing_analyst_date = zoop_missing_analyst_date,
        zoop_missing_split_on_counted_rows = zoop_missing_split_on_counted_rows,
        zoop_unexpected_power_used = zoop_unexpected_power_used,
        zoop_d_split_allowed_taxa = zoop_d_split_allowed_taxa,
        zoop_flagged_data = zoop_flagged_data,
        rot_flagged_data = rot_flagged_data,
        rot_missing_required = rot_missing_required,
        rot_negative_counts = rot_negative_counts,
        rot_nonpositive_split_factor = rot_nonpositive_split_factor,
        rot_duplicate_organism_rows = rot_duplicate_organism_rows,
        rot_station_standardization = rot_station_standardization,
        rot_qa_link_issues = rot_qa_link_issues,
        rot_split_factor_consistency = rot_split_factor_consistency,
        rot_multiple_analyst_dates = rot_multiple_analyst_dates,
        rot_missing_analyst_date = rot_missing_analyst_date,
        rot_missing_split_on_counted_rows = rot_missing_split_on_counted_rows,
        rot_missing_rotvol = rot_missing_rotvol,
        rot_missing_subml = rot_missing_subml,
        rot_nonpositive_rotvol = rot_nonpositive_rotvol,
        rot_nonpositive_subml = rot_nonpositive_subml,
        rot_unexpected_splits = rot_unexpected_splits,
        rot_required_length_and_width = rot_required_length_and_width,
        rot_collotheca_width_only = rot_collotheca_width_only,
        rot_unexpected_width_without_length = rot_unexpected_width_without_length,
        rot_unexpected_power_used = rot_unexpected_power_used,
        sample_not_in_master = sample_not_in_master,
        master_sample_missing_in_data = master_sample_missing_in_data,
        station_mismatch_vs_master = station_mismatch_vs_master,
        depth_mismatch_vs_master = depth_mismatch_vs_master,
        d20_sample_id_suffix = d20_sample_id_suffix,
        d100_sample_id_suffix = d100_sample_id_suffix,
        rot_not_allowed_in_d100 = rot_not_allowed_in_d100,
        d20_missing_protocol_pair = d20_missing_protocol_pair
      ),
      envir = new.env(parent = globalenv())
    ),
    format = "file"
  )
)