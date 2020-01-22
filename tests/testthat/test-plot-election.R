
context("test-plot-election")

test_that("plot_election_map() works", {
  vdiffr::expect_doppelganger(
    "plot_election_map(), defaults",
    plot_election_map()
  )
})

test_that("plot_election() works", {
  vdiffr::expect_doppelganger(
    "plot_election(), defaults",
    plot_election()
  )
})

test_that("plot_votes() works", {
  vdiffr::expect_doppelganger(
    "plot_votes(), defaults",
    plot_votes()
  )
})

test_that("plot_seats() works", {
  vdiffr::expect_doppelganger(
    "plot_seats(), defaults",
    plot_seats()
  )
})
