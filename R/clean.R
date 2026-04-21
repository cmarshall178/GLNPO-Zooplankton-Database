
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
      organism_count = organismcount
    ) |>
    dplyr::mutate(
      sample_num = stringr::str_squish(as.character(sample_num)),
      
      station_raw = as.character(station),
      station = stringr::str_squish(as.character(station)),
      station = stringr::str_to_upper(station),
      station = stringr::str_replace_all(station, "\\s+", ""),
      station = stringr::str_replace(station, "^([A-Z]+)([0-9].*)$", "\\1 \\2"),
      
      sample_type = dplyr::na_if(stringr::str_squish(as.character(sample_type)), ""),
      split = dplyr::na_if(stringr::str_squish(as.character(split)), ""),
      split = stringr::str_to_upper(split),
      
      qa_link = dplyr::na_if(stringr::str_squish(as.character(qa_link)), ""),
      qa_link = dplyr::na_if(qa_link, "-1"),
      
      analyst = dplyr::na_if(stringr::str_squish(as.character(analyst)), ""),
      sex = dplyr::na_if(stringr::str_squish(as.character(sex)), ""),
      comment = dplyr::na_if(stringr::str_squish(as.character(comment)), ""),
      
      split_factor = readr::parse_number(as.character(split_factor)),
      
      analyst_date_raw = dplyr::na_if(as.character(analyst_date), ""),
      analyst_date_raw = dplyr::if_else(
        stringr::str_detect(analyst_date_raw, "^[0-9]+$"),
        suppressWarnings(
          as.character(as.Date(as.numeric(analyst_date_raw), origin = "1899-12-30"))
        ),
        analyst_date_raw,
        missing = analyst_date_raw
      ),
      analyst_date = as.Date(
        suppressWarnings(
          lubridate::parse_date_time(
            analyst_date_raw,
            orders = c("ymd", "mdy", "dmy", "Ymd", "mdY", "dmY", "b d Y", "d b Y")
          )
        )
      ),
      
      length_mm = suppressWarnings(as.numeric(length_mm)),
      width_mm = suppressWarnings(as.numeric(width)),
      organism_count = suppressWarnings(as.numeric(organism_count)),
      
      rotvol_ml = suppressWarnings(as.numeric(rotvol)),
      submla_ml = suppressWarnings(as.numeric(submla)),
      submlb_ml = suppressWarnings(as.numeric(submlb)),
      
      tow_type = dplyr::case_when(
        stringr::str_detect(station, "D100") ~ "D100",
        stringr::str_detect(station, "D20") ~ "D20",
        TRUE ~ NA_character_
      ),
      
      is_qa_sample = !is.na(qa_link)
    ) |>
    dplyr::group_by(source_file, sample_num, split) |>
    dplyr::mutate(
      split_factor = dplyr::coalesce(
        split_factor,
        dplyr::first(split_factor[!is.na(split_factor)], default = NA_real_)
      ),
      
      rotvol_ml = dplyr::coalesce(
        rotvol_ml,
        dplyr::first(rotvol_ml[!is.na(rotvol_ml)], default = NA_real_)
      ),
      
      submla_ml = dplyr::coalesce(
        submla_ml,
        dplyr::first(submla_ml[!is.na(submla_ml)], default = NA_real_)
      ),
      
      submlb_ml = dplyr::coalesce(
        submlb_ml,
        dplyr::first(submlb_ml[!is.na(submlb_ml)], default = NA_real_)
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      rot_subml_ml = dplyr::case_when(
        protocol == "rot" & split == "A" ~ submla_ml,
        protocol == "rot" & split == "B" ~ submlb_ml,
        TRUE ~ NA_real_
      )
    ) |>
    dplyr::select(
      protocol, source_file, source_name, sample_num, station, station_raw,
      tow_type, sample_type, qa_link, split, split_factor, analyst,
      analyst_date, analyst_date_raw, scope_used, power_used, species_name,
      species_code, subgroup, group_code, length_mm, width_mm, sex,
      organism_count, rotvol_ml, submla_ml, submlb_ml, rot_subml_ml,
      comment, is_qa_sample
    )
}