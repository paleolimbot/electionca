
library(tidyverse)
library(sf)

# ---- general data -----

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
  str_replace_all("\\.? ", "_") %>%
  str_remove_all("[^a-z_-]")

# ---- ridings read ----

# electoral districts, 2003
# https://open.canada.ca/data/en/dataset/78400aed-2370-4437-97ca-7563c21bacb1
# GDB: http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2003/federal_electoral_districts_boundaries_2003_en.gdb.zip

curl::curl_download(
  "http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2003/federal_electoral_districts_boundaries_2003_en.gdb.zip",
  "data-raw/boundaries_2003.zip"
)
unzip("data-raw/boundaries_2003.zip", exdir = "data-raw/boundaries_2003")
boundaries_2003_raw <- read_sf("data-raw/boundaries_2003/federal_electoral_districts_boundaries_2003_en.gdb/")

# electoral districts, 2015
# https://open.canada.ca/data/en/dataset/737be5ea-27cf-48a3-91d6-e835f11834b0
# SHP: http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2015/federal_electoral_districts_boundaries_2015_shp_en.zip
curl::curl_download(
  "http://ftp.maps.canada.ca/pub/elections_elections/Electoral-districts_Circonscription-electorale/federal_electoral_districts_boundaries_2015/federal_electoral_districts_boundaries_2015_shp_en.zip",
  "data-raw/boundaries_2015.zip"
)
unzip("data-raw/boundaries_2015.zip", exdir = "data-raw/boundaries_2015")
boundaries_2015_raw <- read_sf("data-raw/boundaries_2015/FED_CA_2_2_ENG.shp")

# ---- ridings clean ----

boundaries_2003 <- boundaries_2003_raw %>%
  st_transform(3979) %>%
  select(province_code = provcode, riding_label = name) %>%
  left_join(provinces, by = "province_code") %>%
  mutate(
    riding_label = riding_label %>%
      # two typos
      str_replace_all("¿", "--") %>%
      str_replace("Vaudreuil-Soulanges", "Vaudreuil--Soulanges") %>%
      str_replace("Northwest Territories", "Western Arctic"),
    riding = sanitize_riding(riding_label)
  ) %>%
  group_by(province_code) %>%
  mutate(geo_id = sprintf("2003_%s_%0.3d", province_code, 1:n())) %>%
  ungroup() %>%
  rename(geometry = Shape) %>%
  select(riding, riding_label, province, geo_id, geometry)

boundaries_2015 <- boundaries_2015_raw %>%
  st_transform(3979) %>%
  select(province_code = PROVCODE, riding_label = ENNAME) %>%
  left_join(provinces, by = "province_code") %>%
  mutate(riding = sanitize_riding(riding_label)) %>%
  group_by(province_code) %>%
  mutate(geo_id = sprintf("2015_%s_%0.3d", province_code, 1:n())) %>%
  ungroup() %>%
  select(riding, riding_label, province, geo_id, geometry)

boundaries <- rbind(boundaries_2003, boundaries_2015) %>%
  st_simplify(dTolerance = 100, preserveTopology = TRUE) %>%
  st_transform(4326)

usethis::use_data(boundaries, overwrite = TRUE)

# ---- cleanup ----

unlink("data-raw/boundaries_2015.zip")
unlink("data-raw/boundaries_2015/", recursive = TRUE)
unlink("data-raw/boundaries_2003.zip")
unlink("data-raw/boundaries_2003/", recursive = TRUE)
