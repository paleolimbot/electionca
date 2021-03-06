
library(tidyverse)
library(xml2)
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

# ---- candidates info ----

download_cache(
  "https://lop.parl.ca/ParlinfoWebApi/Parliament/GetCandidates",
  "data-raw/candidates.xml"
)

read_candidate_node <- function(candidate_node) {
  children <- xml_children(candidate_node)
  values <- as.list(xml_text(children))
  names(values) <- xml_name(children)
  as_tibble(values)
}

candidates_xml <- read_xml("data-raw/candidates.xml")

lop_candidates <- candidates_xml %>%
  xml_children() %>%
  map_dfr(read_candidate_node) %>%
  # filter to the candiates we're going to consider, since this limits the ridings
  # we have to consider as well
  filter(IsGeneral == "true") %>%
  # make sure the riding_id is set so that we can semi_join() to filter
  # ridings
  mutate(riding_id = as.numeric(ConstituencyId)) %>%
  # one candidate has no riding_id...fixing here
  mutate(
    riding_id = if_else(
      ElectionCanadaLastName == "Lépine" & PartyNameEn == "Green Party of Canada",
      3264,
      riding_id
    )
  )

# ---- historic riding geoloc info ----

# best ridings info
# https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Ridings
# raw data at
# https://lop.parl.ca/ParlinfoWebApi/Organization/GetConstituencyList/1
# single riding info
# https://lop.parl.ca/ParlinfoWebApi/Organization/GetFullOrganization/674
#
download_cache(
  "https://lop.parl.ca/ParlinfoWebApi/Organization/GetConstituencyList/1",
  "data-raw/lop_ridings.json"
)

related_ridings <- function(riding_id) {
  url <- glue::glue("https://lop.parl.ca/ParlinfoWebApi/Organization/GetFullOrganization/{riding_id}")
  message(url)
  Sys.sleep(runif(1, min = 0.1, max = 0.5))
  json <- jsonlite::read_json(url)
  tibble(
    related_riding_id = map_dbl(json$History, "OrganizationId"),
    related_riding_is_future = map_lgl(json$History, "IsFuture")
  )
}

related_ridings_mem <- memoise::memoise(
  related_ridings,
  cache = memoise::cache_filesystem("data-raw/memcache")
)

lop_ridings_json <- jsonlite::read_json("data-raw/lop_ridings.json")
lop_ridings <- tibble(
  riding_label = map_chr(lop_ridings_json, "LongEn"),
  riding = sanitize_riding(riding_label),
  province = map_chr(lop_ridings_json, c("Constituency", "ProvinceEn")),
  notes = map_chr(lop_ridings_json, c("Constituency", "HFERNotesEn")),
  riding_id = map_dbl(lop_ridings_json, "OrganizationId")
) %>%
  # only consider ridings for which there is a candidate
  semi_join(lop_candidates, by = "riding_id") %>%
  extract(notes, c("year_start", "year_end"), "\\(\\s*([0-9]{4})\\s*-\\s*([0-9]{4})?\\s*\\)") %>%
  mutate(
    year_start = as.numeric(year_start),
    year_end = as.numeric(year_end)
  ) %>%
  mutate(
    # errors that cause problems...Kitchener--Conestoga was probably
    # a 2004 riding rather than a 2005 one, and Dauphin--Swan River
    # ends in 2004
    year_start = if_else(riding %in% c("kitchener--conestoga", "westlock--st_paul"), 2004, year_start),
    year_end = if_else(riding %in% c("dauphin--swan_river", "toronto_centre--rosedale"), 2004, year_end)
  ) %>%
  arrange(province, year_start, riding)

lop_riding_relations <- lop_ridings %>%
  select(riding_id) %>%
  mutate(relations = map(riding_id, related_ridings_mem)) %>%
  unnest(relations)

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
  select(province, riding, year_start, geometry)

boundaries_2015 <- boundaries_2015_raw %>%
  st_transform(3979) %>%
  select(province_code = PROVCODE, riding_label = ENNAME) %>%
  left_join(provinces, by = "province_code") %>%
  mutate(riding = sanitize_riding(riding_label), year_start = 2015) %>%
  select(province, riding, year_start, geometry)

boundaries <- rbind(boundaries_2003_2013, boundaries_2015) %>%
  st_simplify(dTolerance = 100, preserveTopology = TRUE) %>%
  # this makes sure there is exactly one multipolygon for each  riding
  group_by(province, riding, year_start) %>%
  summarise() %>%
  ungroup() %>%
  mutate(boundary_id = 1:n())

boundaries_summary <- boundaries %>%
  st_centroid() %>%
  st_transform(4326) %>%
  cbind(., st_coordinates(.)) %>%
  st_set_geometry(NULL) %>%
  rename(lon = X, lat = Y)

# ---- find historic riding geography using relations -----

# these ridings are unrelated to other ridings or only have associations within themselves
ridings_geo_manual <- tibble::tribble(
                              ~riding,               ~province, ~riding_id, ~lat, ~lon,
       "alberta_provisional_district", "Northwest Territories",        459,    52.202380, -113.620941,
                    "assiniboia_east", "Northwest Territories",        666,    51.130294, -102.910833,
                    "assiniboia_west", "Northwest Territories",        668,    51.027296, -108.794806,
  "saskatchewan_provisional_district", "Northwest Territories",       7650,    51.568571, -105.721331,
           "cape_breton--the_sydneys",           "Nova Scotia",       1700,    46.207857, -60.670202,
                        "bellechasse",                "Quebec",        913,    46.688108, -70.734611,
                        "bonaventure",                "Quebec",       1071,    48.123075, -65.431589,
                              "gaspe",                "Quebec",       3206,    48.841555, -64.517820,
                         "kamouraska",                "Quebec",       4083,    47.565160, -69.867798,
                             "lislet",                "Quebec",       4314,    47.102894, -70.356807,
                          "montmagny",                "Quebec",       5441,    46.949393, -70.542881 ,
                           "rimouski",                "Quebec",       7255,    48.445941, -68.508984,
                        "temiscouata",                "Quebec",       9143,    47.575505, -68.859313,
                  "montmagny--lislet",                "Quebec",       5446,    0,    0,
               "iles-de-la-madeleine",                "Quebec",       3825,    47.368700, -61.916021,
       "riviere-du-loup--temiscouata",                "Quebec",       7284,    47.766289, -69.312980,
                        "temiscouata",                "Quebec",       9144,    47.575505, -68.859313,
  "bonaventure--iles-de-la-madeleine",                "Quebec",       1075,    0,    0,
       "riviere-du-loup--temiscouata",                "Quebec",       7285,    47.766289, -69.312980,
        "kamouraska--riviere-du-loup",                "Quebec",       4086,    0,    0,
              "rimouski--temiscouata",                "Quebec",       7261,    0,    0,
                "gatineau--la_lievre",                "Quebec",       3218,    45.533681, -75.712866
) %>%
  filter(lat != 0) %>%
  select(riding_id, lon, lat)


ridings_geo <- lop_ridings %>%
  filter(is.na(year_end) | year_end > 2004) %>%
  mutate(year_start_join = pmax(2004, year_start)) %>%
  left_join(
    boundaries_summary,
    by =  c("province", "riding", "year_start_join" = "year_start")
  ) %>%
  filter(is.finite(lon), is.finite(lat)) %>%
  select(riding_id, boundary_id, lon, lat) %>%
  mutate(loc_iter = 0) %>%
  bind_rows(ridings_geo_manual)

# takes 8 iterations
for (i in 1:10) {

  ridings_geo_new <- lop_ridings %>%
    select(riding_id) %>%
    anti_join(ridings_geo, by =  "riding_id") %>%
    left_join(lop_riding_relations, by = "riding_id") %>%
    inner_join(ridings_geo, by = c("related_riding_id" = "riding_id")) %>%
    group_by(riding_id) %>%
    summarise(lon = mean(lon), lat = mean(lat), loc_iter = i)

  if (nrow(ridings_geo_new) == 0) {
    break
  }

  ridings_geo <- bind_rows(ridings_geo, ridings_geo_new)
}

# not perfect, but pretty good! could get better by
# looking at some of the ridings that take 4+ iterations to
# resolve
ridings <- lop_ridings %>%
  left_join(ridings_geo, by = "riding_id") %>%
  # ditch the "riding_id" for a more human readable unique identifier
  left_join(provinces, by = "province") %>%
  mutate(riding_maybe_not_unique = paste(province_code, year_start, riding, sep = "/")) %>%
  group_by(riding_maybe_not_unique) %>%
  mutate(riding = if_else(
    rep(n(), n()) == 1,
    riding_maybe_not_unique,
    str_replace(riding_maybe_not_unique, "[0-9]{4}", paste0("\\0", letters[1:n()])))
  ) %>%
  ungroup() %>%
  select(riding, riding_label, year_start, year_end, riding_id, province, lon, lat)

# ---- clean election results  ----

results <- lop_candidates %>%
  transmute(
    election_date = lubridate::ymd_hms(ElectionDate) %>% as.Date(),
    name = paste(ElectionCanadaFirstName, ElectionCanadaMiddleName, ElectionCanadaLastName) %>%
      str_replace(" NA ", " "),
    party = PartyNameEn,
    riding_id,
    votes = as.numeric(Votes),
    result = ResultLongEn,
    person_id = as.numeric(PersonId) %>% na_if(0)
  ) %>%
  left_join(ridings %>% select(riding_id, riding), by = "riding_id") %>%
  select(election_date, riding, name, party, votes, result, person_id) %>%
  arrange(election_date, riding, desc(votes))

# ---- use data ----

usethis::use_data(results, overwrite = TRUE)
usethis::use_data(ridings, overwrite = TRUE)

# ---- cleanup ----

# unlink("data-raw/boundaries_2015.zip")
# unlink("data-raw/boundaries_2015/", recursive = TRUE)
# unlink("data-raw/boundaries_2003.zip")
# unlink("data-raw/boundaries_2003/", recursive = TRUE)
# unlink("data-raw/boundaries_2013.zip")
# unlink("data-raw/boundaries_2013/", recursive = TRUE)
# unlink("data-raw/lop_ridings.json")
# unlink("data-raw/candidates.xml")
