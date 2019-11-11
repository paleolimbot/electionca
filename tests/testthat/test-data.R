
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

test_that("there are the correct number of seats in each parliament", {

  known_seat_numbers <- tibble::tribble(
    ~election_date,  ~n,
      "1867-08-07", 180,
      "1872-07-20", 200,
      "1874-01-22", 206,
      "1878-09-17", 206,
      "1882-06-20", 211,
      "1887-02-22", 215,
      "1891-03-05", 215,
      "1896-06-23", 213,
      "1900-11-07", 213,
      "1904-11-03", 214,
      "1908-10-26", 221,
      "1911-09-21", 221,
      "1917-12-17", 235,
      "1921-12-06", 235,
      "1925-10-29", 245,
      "1926-09-14", 245,
      "1930-07-28", 245,
      "1935-10-14", 245,
      "1940-03-26", 245,
      "1945-06-11", 245,
      "1949-06-27", 262,
      "1953-08-10", 265,
      "1957-06-10", 265,
      "1958-03-31", 265,
      "1962-06-18", 265,
      "1963-04-08", 265,
      "1965-11-08", 265,
      "1968-06-25", 264,
      "1972-10-30", 264,
      "1974-07-08", 264,
      "1979-05-22", 282,
      "1980-02-18", 282,
      "1984-09-04", 282,
      "1988-11-21", 295,
      "1993-10-25", 295,
      "1997-06-02", 301,
      "2000-11-27", 301,
      "2004-06-28", 308,
      "2006-01-23", 308,
      "2008-10-14", 308,
      "2011-05-02", 308,
      "2015-10-19", 338,
      "2019-10-21", 338
    ) %>%
    dplyr::mutate(
      election_date = as.Date(election_date),
      n = as.integer(n)
    )

  seat_numbers <- results %>%
    dplyr::filter(result == "Elected") %>%
    dplyr::count(election_date) %>%
    dplyr::arrange(election_date)

  expect_identical(seat_numbers, known_seat_numbers)
})

test_that("ridings and results are internally consistent", {
  expect_identical(dplyr::semi_join(results, ridings, by = "riding"), results)
  expect_identical(dplyr::semi_join(ridings, results, by = "riding"), ridings)
})

test_that("results and boundaries are internally consistent", {
  recent_results <- results %>% dplyr::filter(election_date >= "2005-01-01")
  expect_identical(
    dplyr::semi_join(recent_results, boundaries, by = c("riding", "election_date")),
    recent_results
  )

  expect_identical(
    dplyr::semi_join(boundaries, recent_results, by = c("riding", "election_date")) %>%
      dplyr::select(-boundary),
    boundaries %>% dplyr::select(-boundary)
  )
})
