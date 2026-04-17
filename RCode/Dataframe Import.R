
#here::i_am("GLNPO Zooplankton Database")
install.packages("usethis") 
library(usethis)
usethis::use_git()
usethis::use_github()

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
