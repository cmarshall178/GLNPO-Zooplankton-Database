
#here::i_am("GLNPO Zooplankton Database")
install.packages("usethis") 
library(usethis)

library(tidyverse)
library(here)
library(readxl)
library(lubridate)
library(janitor)

files <- list.files(
  path = "C:/Users/cmars/OneDrive/Desktop/CCM Work Files/GLNPO Zooplankton Database/GLNPO Data/Raw Data/GLNPO 2024 Spring/Erie/D20/Zoops",
  pattern = "\\.xlsx$",
  full.names = TRUE
)

read_zoop <- function(files) {
  read_excel(files, sheet = "Sheet1", col_types = "text") %>%
    
    # Drop pivot table columns entirely
    select(-starts_with("...")) %>%
    
    # Mutate columns to be consistent
    mutate(QA_LINK = as.character(QA_LINK)) %>% 
    mutate(
      ANALYSTDATE = as.character(ANALYSTDATE),
      ANALYSTDATE = trimws(ANALYSTDATE),
      ANALYSTDATE = parse_date_time(ANALYSTDATE,
                    orders = c("mdy", "ymd", "mdy HMS"))) %>% 
    mutate(source_file = basename(files))
}

zoop_data <- map_dfr(files, read_zoop)


# Detect header row dynamically
detect_header_row <- function(path, sheet = 1, n_max = 20) {
  preview <- read_excel(path, sheet = sheet, col_names = FALSE, n_max = n_max)
  
  header_row <- preview %>%
    mutate(row_id = row_number()) %>%
    pivot_longer(-row_id) %>%
    group_by(row_id) %>%
    summarise(non_na = sum(!is.na(value))) %>%
    arrange(desc(non_na)) %>%
    slice(1) %>%
    pull(row_id)
  
  return(header_row)
}

# Clean a single Excel file
load_zoop_excel <- function(path) {
  
  header_row <- detect_header_row(path)
  
  df <- read_excel(path, skip = header_row - 1) %>%
    clean_names()
  
  # Remove empty / pivot artifact columns
  df <- df %>%
    select(where(~ !all(is.na(.)))) %>%
    select(-matches("^unnamed"))
  
  df
}

# Load all raw files
load_all_zoop <- function() {
  files <- list.files(here("Raw Data/GLNPO 2024 Spring/Erie/D20/Rots"), pattern = ".xlsx$", full.names = TRUE)
  
  map_dfr(files, load_zoop_excel, .id = "source_file")
}



load_raw_data <- function() {
  read_xls(here("Raw Data/GLNPO 2024 Spring/Erie/D20/Rots/"), col_types = cols())
}

# 1. Get a vector of file paths
file_list <- list.files(here(path = "Raw Data/GLNPO 2024 Spring/Erie/D20/Rots", pattern = "*.xlsx", full.names = TRUE))

# 2. Read and combine all files into one dataframe
combined_data <- file_list %>%
  set_names() %>% # Keeps filenames as identifiers if needed
  map_dfr(read_excel, .id = "source_file")




load_taxonomy <- function() {
  read_csv(here("data/metadata/taxonomy_reference.csv"), col_types = cols())
}
