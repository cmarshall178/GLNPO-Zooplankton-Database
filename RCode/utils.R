library(fs)
library(here)

ensure_project_dirs <- function() {
  fs::dir_create(here::here("data", "processed"))
  fs::dir_create(here::here("outputs", "tables"))
  fs::dir_create(here::here("outputs", "figures"))
}
