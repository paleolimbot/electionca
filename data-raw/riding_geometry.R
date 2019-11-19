
library(tidyverse)
library(sf)

ridings <- electionca::ridings
results <- electionca::results

# order for the purposes of plotting
province_order <- c(
  "Yukon", "Northwest Territories", "Nunavut", "Newfoundland and Labrador",
  "Nova Scotia", "Prince Edward Island", "New Brunswick", "Quebec",
  "Ontario", "Manitoba", "Saskatchewan", "Alberta", "British Columbia"
)

ridings_sorted <- results %>%
  distinct(election_date, riding) %>%
  left_join(ridings, by = "riding") %>%
  mutate(province = factor(province, levels = province_order)) %>%
  arrange(election_date, province, desc(lon), lat) %>%
  group_by(election_date, province) %>%
  mutate(
    geom_number = 1:n(),
    geom_y = (geom_number - 1) %/% 20,
    geom_x = (geom_number - 1) %% 20
  ) %>%
  ungroup()

layout_province_grid <- ridings_sorted %>%
  select(election_date, riding, province, geom_x, geom_y)



usethis::use_data(layout_province_grid, overwrite = TRUE)
