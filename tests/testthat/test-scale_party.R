
test_that("party_colour works", {
  known_parties <- c(NA, "Not A Party", names(canadian_party_colours()))
  colours <- party_colour(known_parties)

  expect_identical(colours[1], "grey50")
  expect_identical(colours[2], scales::hue_pal()(1))
})

test_that("party colour works with no unknown parties", {
  expect_identical(party_colour("Liberal Party of Canada"), "#d71b1f")
  expect_identical(party_colour(NA), "grey50")
})


