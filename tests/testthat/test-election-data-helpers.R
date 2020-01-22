
test_that("years, dates, and provinces utility functions", {
  expect_equal(length(election_dates()), length(election_years()))
  expect_length(election_dates(), 43)
  expect_is(election_dates(), "Date")
  expect_is(election_years(), "numeric")
  expect_is(election_provinces(), "character")
  expect_length(election_provinces(), 13)
})

test_that("election_results() utility function", {

  expect_is(election_results(), "tbl_df")
  expect_equal(
    nrow(election_results(results = c("Elected", "Defeated"))),
    nrow(electionca::results)
  )

  ns_2019 <- election_results(2019, "Nova Scotia")
  expect_true(all(lubridate::year(ns_2019$election_date) == 2019))
  expect_true(all(ns_2019$province == "Nova Scotia"))
  expect_is(ns_2019$province, "factor")
  expect_equal(levels(ns_2019$province), "Nova Scotia")
})
