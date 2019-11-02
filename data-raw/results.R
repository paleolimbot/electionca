
library(tidyverse)

# basic data

sanitize_riding <- . %>%
  stringi::stri_trans_general("Latin-ASCII") %>%
  str_to_lower() %>%
  str_replace_all("\\.? ", "_") %>%
  str_remove_all("[^a-z_-]")

# ---- candidates raw ----

# History of the Federal Electoral Ridings, 1867-2010
# https://open.canada.ca/data/en/dataset/ea8f2c37-90b6-4fee-857e-984d3060184e
# http://www.lop.parl.gc.ca/Content/LOP/OpenData/HFER_e.csv
results_historical_raw <- read_csv(
  "http://www.lop.parl.gc.ca/Content/LOP/OpenData/HFER_e.csv",
  col_types = cols(
    `Election Date` = col_date(format = ""),
    `Election Type` = col_character(),
    Parliament = col_double(),
    Province = col_character(),
    Riding = col_character(),
    `Last Name` = col_character(),
    `First Name` = col_character(),
    Gender = col_character(),
    Occupation = col_character(),
    Party = col_character(),
    Votes = col_character(),
    `Votes (%)` = col_double(),
    Elected = col_double()
  ),
  locale = locale(encoding = "ISO-8859-1")
)

# 41st general election (2011)
# ZIP: http://www.elections.ca/scripts/OVR2011/34/data_donnees/pollbypoll_bureauparbureau_canada.zip
curl::curl_download(
  "http://www.elections.ca/scripts/OVR2011/34/data_donnees/pollbypoll_bureauparbureau_canada.zip",
  "data-raw/results_2011.zip"
)
unzip("data-raw/results_2011.zip", exdir = "data-raw/results_2011")
results_2011_raw <- read_csv(
  "data-raw/results_2011/table_tableau12.csv",
  col_types = cols(
    Province = col_character(),
    `Electoral District Name/Nom de circonscription` = col_character(),
    `Electoral District Number/Numéro de circonscription` = col_double(),
    `Candidate/Candidat` = col_character(),
    `Candidate Residence/Résidence du candidat` = col_character(),
    `Candidate Occupation/Profession du candidat` = col_character(),
    `Votes Obtained/Votes obtenus` = col_double(),
    `Percentage of Votes Obtained /Pourcentage des votes obtenus` = col_double(),
    `Majority/Majorité` = col_double(),
    `Majority Percentage/Pourcentage de majorité` = col_double()
  ),
  locale = locale(encoding = "ISO-8859-1")
)

# 42nd general election (2015)
# https://www.elections.ca/content.aspx?section=ele&document=index&dir=pas/42ge&lang=e
# https://open.canada.ca/data/en/dataset/775f3136-1aa3-4854-a51e-1a2dab362525
# CSV: http://www.elections.ca/res/rep/off/ovr2015app/41/data_donnees/table_tableau12.csv
results_2015_raw <- read_csv(
  "https://www.elections.ca/res/rep/off/ovr2015app/41/data_donnees/table_tableau12.csv",
  col_types = cols(
    Province = col_character(),
    `Electoral District Name/Nom de circonscription` = col_character(),
    `Electoral District Number/Numéro de circonscription` = col_double(),
    `Candidate/Candidat` = col_character(),
    `Candidate Residence/Résidence du candidat` = col_character(),
    `Candidate Occupation/Profession du candidat` = col_character(),
    `Votes Obtained/Votes obtenus` = col_double(),
    `Percentage of Votes Obtained /Pourcentage des votes obtenus` = col_double(),
    `Majority/Majorité` = col_double(),
    `Majority Percentage/Pourcentage de majorité` = col_double()
  )
)

# ---- candidates cleaning ----

results_historical <- results_historical_raw %>%
  rename_all(str_to_lower) %>%
  rename_all(str_replace_all, " ", "_") %>%
  rename(vote_pct = `votes_(%)`) %>%
  mutate(
    name = paste(first_name, last_name),
    elected = as.logical(elected),
    votes = votes %>% na_if("NULL") %>% na_if("accl.") %>% as.numeric()
  ) %>%
  filter(election_type == "Gen") %>%
  select(-first_name, -last_name, -gender, -election_type, -parliament, -vote_pct)

parties_2011_2015 <- c(
  "NDP-New Democratic Party/NPD-Nouveau Parti démocratique",
  "Independent/Indépendant",
  "Liberal/Libéral",
  "Green Party/Parti Vert",
  "Conservative/Conservateur",
  "CHP Canada/PHC Canada",
  "Marxist-Leninist/Marxiste-Léniniste",
  "Bloc Québécois/Bloc Québécois",
  "Rhinoceros/Rhinocéros",
  "Libertarian/Libertarien",
  "CAP/PAC",
  "Communist/Communiste",
  "Radical Marijuana/Radical Marijuana",
  "Animal Alliance/Environment Voters/Animal Alliance/Environment Voters",
  "United Party/Parti Uni",
  "PC Party/Parti PC",
  "No Affiliation/Aucune appartenance",
  "WBP/WBP",
  "Pirate Party/Parti Pirate",
  "FPNP/FPNP",
  "Heritage Party/Parti de l'Héritage Chrétien",
  "Pirate/Pirate",
  "Democratic Advancement/Avancement de la Démocratie",
  "Canada Party/Parti Canada",
  "The Bridge/Le Lien",
  "Forces et Démocratie - Allier les forces de nos régions/Forces et Démocratie - Allier les forces de nos régions",
  "ATN/ADN",
  "PACT/PRCT",
  "Seniors Party/Parti des aînés"
)

results_2011_2015 <- bind_rows(
  results_2011_raw %>% mutate(election_date = as.Date("2011-05-02")),
  results_2015_raw %>% mutate(election_date = as.Date("2015-10-19"))
) %>%
  rename_all(str_remove, "\\s*/.*") %>%
  rename_all(str_to_lower) %>%
  rename_all(str_replace_all, " ", "_") %>%
  select(
    election_date,
    province,
    riding = electoral_district_name,
    candidate,
    occupation = candidate_occupation,
    votes = votes_obtained
  ) %>%
  mutate(
    elected = str_detect(candidate, "\\*\\*"),
    candidate = str_remove(candidate, "\\*\\*\\s+")
  ) %>%
  extract(
    candidate,
    c("name", "party"),
    paste0("^(.*?)\\s+(", paste0(parties_2011_2015, collapse = "|"), ")")
  ) %>%
  mutate(
    occupation = str_remove_all(occupation, "(^/)|(/$)"),
    party = str_remove(party, "/.*"),
    province = str_remove(province, "/.*"),
    riding = str_remove(riding, "/.*")
  )

# ---- results combine ----

results <- bind_rows(
  results_historical,
  results_2011_2015
) %>%
  mutate(
    riding = sanitize_riding(riding)
  ) %>%
  select(election_date, province, riding, name, party, votes, elected, everything())

usethis::use_data(results, overwrite = TRUE)

# ---- cleanup ----

unlink("data-raw/results_2011.zip")
unlink("data-raw/results_2011/", recursive = TRUE)
