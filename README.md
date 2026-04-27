---
title: "README.md"
output: html_document
date: "2026-04-16"
---

```{r Project Overview}
Planktonic Crustacean Zooplankton and Rotifer data are collected from the offshore waters of lakes Superior, Michigan, Huron, Erie and Ontario as part of the U.S. Environmental Protection Agency (U.S. EPA) Great Lakes National Program Office’s (GLNPO) regular monitoring of the Great Lakes.  Crustacean Zooplankton Samples are collected in spring (typically April) and summer (typically August) by vertical tows with a metered, 153-μm mesh net from 100 meters depth (or 2 meters above the bottom) to the surface. Shallow water Crustacean Zooplankton and Rotifer are collected by vertical tows with a metered, 63-μm mesh net from 20 meters depth (or 2 meters above the bottom) to the surface. Station-level data (mg per m3, number per m3) are summarized by major taxonomic group.
```

## 

```{r Project Goals}
Target goals include streamlining GLNPO Zooplankton compilation and quality assurance process with reproducibility and collaboration as a main feature. Designs have scalability and the potential for automatically generated reports to modernize zooplankton database exploration and outputs. 

```

## Dependencies

```{r Project setup and Dependencies}
Be sure to run the project setup R script to proper collaboration and reproducibility across different computers and local repositories. This ensures collaborators use identical package versions and that updates happen automatically. 
```

# GLNPO Zooplankton QA Project

This project provides a reproducible and collaborative R workflow for importing raw Excel files, compiling them into standardized datasets, running automated quality checks, and generating QA reports.

The project is designed to be cloned to other computers and run consistently using `targets`, `here`, and `renv`.

## Project goals

- Import raw GLNPO counting spreadsheets in Excel format
- Standardize metadata and analyst-entered fields
- Compile datasets reproducibly in code
- Run automated QA checks on compiled raw data
- Separate Zooplankton (`Zoop`) and Rotifer (`Rot`) protocols
- Generate summary tables and HTML QA reports
- Support collaboration across multiple computers

## How the pipeline is organized

This project is organized as a set of small R scripts that each have one main job. The `_targets.R` file connects those scripts into a reproducible pipeline.

# GLNPO Zooplankton & Rotifer QA Pipeline

## Overview

This project provides a **reproducible R-based workflow** for processing GLNPO zooplankton and rotifer data. It automates:

* Importing raw Excel counting sheets
* Cleaning and standardizing data
* Running quality assurance (QA) checks
* Validating against a master sample list
* Generating compiled datasets
* Producing a QA report and flagged review files

The workflow is built using the `{targets}` package, which ensures that:

* steps run in the correct order
* only updated data are reprocessed
* results are reproducible across machines

---

## Project Structure

```
GLNPO Zooplankton Database/
├── _targets.R                # Pipeline control file
├── data/
│   ├── raw/                 # Raw Excel files (optional if using Box)
│   ├── metadata/            # Master sample list(s)
│   └── processed/           # Compiled outputs (auto-generated)
├── outputs/
│   └── tables/              # QA summaries and flagged subsets
├── reports/
│   └── qa_report.Rmd        # QA report template
├── R/
│   ├── import.R             # File import functions
│   ├── clean.R              # Data cleaning
│   ├── qa_checks.R          # QA rules
│   ├── flagging.R           # Row-level QA flags
│   ├── summarize.R          # Sample summaries
│   └── utils.R              # Helper functions
├── renv/                    # Reproducible package environment
└── README.md
```

---

## Data Source (Box Integration)
## Optional if instead using Locally downloaded files
## Pipeline currently pulls from local sources - can be adjusted after discussion

Raw files are typically stored in a **shared, password-protected Box folder**.

### Setup

1. Install **Box Drive**
2. Sync the project folder locally
3. Set your Box path in `.Renviron`:

```r
usethis::edit_r_environ()
```

Add:

```
GLNPO_BOX_PATH=C:/Users/yourname/Box/GLNPO Zooplankton
```

Restart R.

The pipeline will automatically read from this folder.

---

## How to Run the Pipeline

Open the `.Rproj` file, then run in the console:

```r
targets::tar_make()
```

This will:

1. Locate raw Excel files
2. Import and clean data
3. Separate Zoop and Rot protocols
4. Run QA checks
5. Generate compiled datasets
6. Create flagged datasets
7. Render the QA report

---

## Outputs

### Compiled datasets

Located in:

```
data/processed/
```

* `compiled_zoop.csv`
* `compiled_rot.csv`

These are cleaned, standardized datasets.

---

### Flagged datasets (for review)

* `compiled_zoop_flagged.csv`
* `compiled_rot_flagged.csv`

Each row includes:

* QA flag columns (`flag_*`)
* `any_flag` (TRUE/FALSE)
* `flag_count`
* `flag_notes` (which checks were triggered)

---

### Flagged-only review files

Located in:

```
outputs/tables/
```

* `zoop_flagged_only.csv`
* `rot_flagged_only.csv`

These contain only rows that need review.

---

### QA Report

```
outputs/qa_report.html
```

Includes:

* QA summaries
* Master list validation
* Example flagged records
* Sample summaries

---

## Workflow Logic

### 1. Import (`R/import.R`)

* Reads all Excel files
* Standardizes column names
* Identifies protocol (Zoop vs Rot)

### 2. Cleaning (`R/clean.R`)

* Standardizes fields (station, sample ID, splits)
* Parses dates and numeric values
* Handles Rot-specific fields (ROTVOL, SUBML)
* Adds `row_id` for QA tracking

### 3. QA Checks (`R/qa_checks.R`)

Identifies issues such as:

* Missing required values
* Negative counts
* Split factor inconsistencies
* Master list mismatches
* Incorrect taxa for Zoop D-splits
* Rot measurement rule violations
* Protocol-specific power usage

### 4. Flagging (`R/flagging.R`)

* Converts QA results into row-level flags
* Adds summary columns (`any_flag`, `flag_count`, `flag_notes`)
* Produces review-ready datasets

### 5. Summarizing (`R/summarize.R`)

* Creates sample-level summaries for Zoop and Rot

### 6. Reporting (`reports/qa_report.Rmd`)

* Generates an HTML QA report for review

---

## Key QA Rules

### Master list validation

* Sample IDs must match the master list
* Station and depth must match expected values
* QA samples (with "Q") are excluded

### Sample ID rules

* D100 Zoop samples end in **3**
* D20 samples (Zoop + Rot) end in **4**

### Zooplankton rules

* D-split contains only approved adult taxa
* Power used should match protocol

### Rotifer rules

* ROTVOL and SUBML values must be valid
* Certain taxa require both length and width
* Collotheca requires width only
* Width = 0 is treated as “not measured”

---

## Important Notes

* Do not edit files in `data/processed/` (they are overwritten)
* Raw Excel files should remain unchanged
* Always open the `.Rproj` file before running the pipeline
* QA flags indicate records for review, not guaranteed errors

---

## Updating the Pipeline

### If new data are added

Simply run:

```r
targets::tar_make()
```

Only new or changed files will be processed.

---

### If R or RStudio is updated

Run:

```r
renv::restore()
renv::rebuild()
```

Then rerun the pipeline.

---

## Troubleshooting

### Packages out of sync

```r
renv::status()
renv::restore()
```

### Pipeline errors

```r
targets::tar_meta(fields = c(error, warnings), complete_only = TRUE)
```

### Reset pipeline

```r
targets::tar_destroy(ask = FALSE)
targets::tar_make()
```

---

## Intended Use

This workflow is designed to:

* standardize data processing across analysts
* identify data issues early
* support QA/QC before database ingestion
* provide transparent, reproducible outputs

---

## Contact

For questions or updates to QA rules, contact the project maintainer.
