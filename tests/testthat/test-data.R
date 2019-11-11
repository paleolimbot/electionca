
test_that("locations exist for all ridings", {
  expect_true(all(is.finite(ridings$lon)))
  expect_true(all(is.finite(ridings$lat)))
})

test_that("the correct number of elections exist", {
  expect_equal(dplyr::n_distinct(results$election_date), 43)
  expect_equal(lubridate::year(range(results$election_date)), c(1867, 2019))
})

test_that("there is exactly one winner for every riding since 1968 and at least one for others", {
  election_ridings <- results %>%
    dplyr::distinct(election_date, riding) %>%
    dplyr::arrange(election_date, riding)

  election_ridings <- results %>%
    dplyr::group_by(election_date, riding) %>%
    dplyr::summarise(
      n_winners = sum(result == "Elected", na.rm = TRUE),
      n_loosers = sum(result == "Defeated", na.rm = TRUE),
      n_na = sum(is.na(result))
    )

  recent_election_ridings <- election_ridings %>%
    dplyr::filter(election_date >= "1968-01-01")

  expect_true(all(election_ridings$n_winners >= 1))
  expect_true(all(recent_election_ridings$n_winners == 1))
})

test_that("ridings and results are internally consistent", {
  expect_identical(dplyr::semi_join(results, ridings, by = "riding"), results)
  expect_identical(dplyr::semi_join(ridings, results, by = "riding"), ridings)
})

test_that("boundaries and ridings are internally consistent", {
  expect_true(all(boundaries$boundary_id %in% ridings$boundary_id))
  expect_true(all(ridings$boundary_id %in% c(boundaries$boundary_id, NA)))
})
