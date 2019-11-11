
library(tidyverse)
library(sf)

provinces <- tibble::tribble(
  ~province_code,         ~province,
  "AB",                   "Alberta",
  "BC",          "British Columbia",
  "MB",                  "Manitoba",
  "NB",             "New Brunswick",
  "NL", "Newfoundland and Labrador",
  "NS",               "Nova Scotia",
  "NT",     "Northwest Territories",
  "NU",                   "Nunavut",
  "ON",                   "Ontario",
  "PE",      "Prince Edward Island",
  "QC",                    "Quebec",
  "SK",              "Saskatchewan",
  "YT",                     "Yukon"
)

sanitize_riding <- . %>%
  stringi::stri_trans_general("Latin-ASCII") %>%
  str_to_lower() %>%
  str_replace_all("(\\b)st-", "\\1st. ") %>%
  str_replace_all("\\.? ", "_") %>%
  str_remove_all("[^a-z_-]")

download_cache <- function(url, dest) {
  if (!file.exists(dest)) {
    curl::curl_download(url, dest)
  }
}

unzip_cache <- function(dest, exdir) {
  if (!dir.exists(exdir)) {
    unzip(dest, exdir = exdir)
  }
}

# ---- riding known boundaries read ----

# electoral districts, 2003
# https://open.canada.ca/data/en/dataset/78400aed-2370-4437-97ca-7563c21bacb1
# GDB: http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2003/federal_electoral_districts_boundaries_2003_en.gdb.zip

download_cache(
  "http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2003/federal_electoral_districts_boundaries_2003_en.gdb.zip",
  "data-raw/boundaries_2003.zip"
)
unzip_cache("data-raw/boundaries_2003.zip", exdir = "data-raw/boundaries_2003")
boundaries_2003_raw <- read_sf("data-raw/boundaries_2003/federal_electoral_districts_boundaries_2003_en.gdb/")

# electoral districts, 2013
# https://open.canada.ca/data/en/dataset/10801c67-7f18-4ea1-bda7-8962abfc5578
# GDB: http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2013/federal_electoral_districts_boundaries_2013_en.gdb.zip
download_cache(
  "http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2013/federal_electoral_districts_boundaries_2013_en.gdb.zip",
  "data-raw/boundaries_2013.zip"
)
unzip_cache("data-raw/boundaries_2013.zip", exdir = "data-raw/boundaries_2013")
boundaries_2013_raw <- read_sf("data-raw/boundaries_2013/federal_electoral_districts_boundaries_2013_en.gdb/")

# electoral districts, 2015
# https://open.canada.ca/data/en/dataset/737be5ea-27cf-48a3-91d6-e835f11834b0
# SHP: http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2015/federal_electoral_districts_boundaries_2015_shp_en.zip
download_cache(
  "http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2015/federal_electoral_districts_boundaries_2015_shp_en.zip",
  "data-raw/boundaries_2015.zip"
)
unzip_cache("data-raw/boundaries_2015.zip", exdir = "data-raw/boundaries_2015")
boundaries_2015_raw <- read_sf("data-raw/boundaries_2015/FED_CA_2_2_ENG.shp")

# ---- boundaries clean ----

boundaries_2003_2013 <- rbind(
  boundaries_2003_raw %>% mutate(year_start = 2004),
  boundaries_2013_raw %>% mutate(year_start = 2013)
) %>%
  st_transform(3979) %>%
  select(year_start, province_code = provcode, riding_label = name) %>%
  left_join(provinces, by = "province_code") %>%
  mutate(
    riding_label = riding_label %>%
      # two typos
      str_replace_all("¿", "--") %>%
      str_replace("Vaudreuil-Soulanges", "Vaudreuil--Soulanges") %>%
      str_replace("Northwest Territories", "Western Arctic"),
    riding = sanitize_riding(riding_label)
  ) %>%
  rename(geometry = Shape) %>%
  select(province_code, riding, year_start, geometry)

boundaries_2015 <- boundaries_2015_raw %>%
  st_transform(3979) %>%
  select(province_code = PROVCODE, riding_label = ENNAME) %>%
  left_join(provinces, by = "province_code") %>%
  mutate(riding = sanitize_riding(riding_label), year_start = 2015) %>%
  select(province_code, riding, year_start, geometry)

boundaries_combined <- rbind(boundaries_2003_2013, boundaries_2015) %>%
  st_simplify(dTolerance = 100, preserveTopology = TRUE) %>%
  # this makes sure there is exactly one multipolygon for each  riding
  group_by(province_code, riding, year_start) %>%
  summarise() %>%
  ungroup() %>%
  mutate(boundary_id = 1:n())

boundaries_browse <- boundaries_combined %>% st_set_geometry(NULL)

# ---- join election dates ----

boundaries <- electionca::results %>%
  distinct(election_date, riding) %>%
  mutate(
    year_start = case_when(
      election_date >= "2015-01-01" ~ 2015,
      election_date >= "2013-01-01" ~ 2013,
      # apparently these didn't come into effect until after the 2004 election
      election_date >= "2005-01-01" ~ 2004,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(year_start)) %>%
  separate(riding, c("province_code", "riding_start", "riding_join"), sep = "/", remove = FALSE) %>%
  left_join(boundaries_combined, by = c("province_code", "riding_join" = "riding", "year_start")) %>%
  select(election_date, riding, boundary = geometry) %>%
  st_as_sf()

usethis::use_data(boundaries, overwrite = TRUE)

# ---- cleanup ----

# unlink("data-raw/boundaries_2015.zip")
# unlink("data-raw/boundaries_2015/", recursive = TRUE)
# unlink("data-raw/boundaries_2003.zip")
# unlink("data-raw/boundaries_2003/", recursive = TRUE)
# unlink("data-raw/boundaries_2013.zip")
# unlink("data-raw/boundaries_2013/", recursive = TRUE)
