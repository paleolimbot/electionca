
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
