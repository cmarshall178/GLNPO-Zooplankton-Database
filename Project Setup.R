
#Use {renv} for dependency locking
install.packages("renv") 
renv::init() #This ensures collaborators use identical package versions.

#This creates a consistent file path for collaborators across different computers
library(here)

#Gitup setup
install.packages("usethis") 
library(usethis)
usethis::use_git()

install.packages(c(
  "targets", "tarchetypes", "tidyverse", "readxl", "here",
  "fs", "janitor", "lubridate", "rmarkdown"
))
targets::tar_make()