
clean_zoop <- function(df) {
  if (nrow(df) == 0) {
    return(tibble::tibble())
  }
  
  df |>
    dplyr::rename(
      sample_num = samplenum,
      sample_type = sampletype,
      split_factor = splitfactor,
      analyst_date = analystdate,
      species_name = combo,
      species_code = speccode,
      group_code = group,
      length_mm = length,
      width_mm = width,
      organism_count = organismcount
    ) |>
    dplyr::mutate(
      station_raw = station,
      station = stringr::str_squish(station),
      station = stringr::str_replace_all(station, "\\s+", " "),
      qa_link = dplyr::na_if(as.character(qa_link), "-1"),
      
      analyst_date = dplyr::na_if(as.character(analyst_date), ""),
      analyst_date = dplyr::if_else(
        stringr::str_detect(analyst_date, "^[0-9]+$"),
        suppressWarnings(
          as.character(as.Date(as.numeric(analyst_date), origin = "1899-12-30"))
        ),
        analyst_date,
        missing = analyst_date
      ),
      analyst_date = as.Date(
        suppressWarnings(
          lubridate::parse_date_time(
            analyst_date,
            orders = c("ymd", "mdy", "dmy", "Ymd", "mdY", "dmY", "b d Y", "d b Y")
          )
        )
      ),
      
      split_factor = readr::parse_number(as.character(split_factor)),
      length_mm = suppressWarnings(as.numeric(length_mm)),
      width_mm = suppressWarnings(as.numeric(width_mm)),
      organism_count = suppressWarnings(as.numeric(organism_count)),
      sex = dplyr::na_if(stringr::str_squish(as.character(sex)), ""),
      comment = dplyr::na_if(stringr::str_squish(as.character(comment)), ""),
      is_qa_sample = !is.na(qa_link)
    ) |>
    dplyr::select(
      source_file, sample_num, station, station_raw, sample_type, qa_link,
      split, split_factor, analyst, analyst_date, scope_used, power_used,
      species_name, species_code, subgroup, group_code, length_mm, width_mm, sex,
      organism_count, comment, is_qa_sample
    )
}