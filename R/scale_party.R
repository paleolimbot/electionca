
#' Colours for Canadian Political Parties
#'
#' @param party A vector of party names like those seen in the `party` column of
#'   [results].
#' @param palette_extra A palette for assigning colours to rare parties like [scales::hue_pal()].
#' @param party_colours Known party colours, like those returned by
#'   [canadian_party_colours()].
#' @param na.value The colour to be used for `NA` values.
#' @param aesthetics,... Passed to [ggplot2::discrete_scale()].
#'
#' @export
#'
#' @examples
#' party_colour(c(NA, "Liberal Party of Canada", "Conservative Party of Canada"))
#'
#' library(ggplot2)
#'
#' cols_df <- tibble::tibble(
#'   col = canadian_party_colours(),
#'   party = names(col),
#'   n = seq_along(col),
#'   x = n %/% 4,
#'   y = n %% 4
#' )
#'
#' ggplot(cols_df, aes(x, y, col = party))  +
#'   geom_point(size = 10) +
#'   scale_colour_party()
#'
#' ggplot(cols_df, aes(x, y, fill = party))  +
#'   geom_tile() +
#'   scale_fill_party()
#'
party_colour <- function(party, party_colours = canadian_party_colours(),
                         palette_extra = scales::hue_pal(), na.value = "grey50") {
  all_colours <- pal_party(party, party_colours, palette_extra)()
  colour <- all_colours[as.character(party)]
  colour[is.na(party)] <- na.value
  unname(colour)
}

#' @rdname party_colour
#' @export
pal_party <- function(party = character(0), party_colours = canadian_party_colours(),
                      palette_extra = scales::hue_pal()) {
  other_values <- setdiff(party, c(names(party_colours), NA))
  other_colours <- if (length(other_values) > 0) palette_extra(length(other_values)) else character(0)
  force(party_colours)

  function(n = 0) {
    c(
      party_colours,
      stats::setNames(other_colours, other_values)
    )
  }
}

#' @rdname party_colour
#' @export
scale_colour_party <- function(..., party_colours = canadian_party_colours(),
                               palette_extra = scales::hue_pal(), aesthetics = "colour") {
  scale <- ggplot2::discrete_scale(
    aesthetics = aesthetics,
    scale_name = "party",
    palette = NULL,
    ...,
    super = ScaleParty
  )

  scale$party_colours <- party_colours
  scale$palette_extra <- palette_extra
  scale
}

#' @rdname party_colour
#' @export
scale_fill_party <- function(..., party_colours = canadian_party_colours(),
                             palette_extra = scales::hue_pal(), aesthetics = "fill") {
  scale <- ggplot2::discrete_scale(
    aesthetics = aesthetics,
    scale_name = "party",
    palette = NULL,
    ...,
    super = ScaleParty
  )

  scale$party_colours <- party_colours
  scale$palette_extra <- palette_extra
  scale
}

#' @rdname party_colour
#' @export
canadian_party_colours <- function() {
  c(
    "Liberal Party of Canada" = "#d71b1f",
    "Progressive Conservative Party" = "#0000cd",
    "New Democratic Party" = "#f89922",
    "Conservative Party of Canada" = "#1d4881",
    "Bloc Qu\u00E9b\u00E9cois" = "#b4e1ed",
    "Conservative (1867-1942)" = "#1d4881",
    "Social Credit Party of Canada" = "#2c661a",
    "Reform Party of Canada" = "#31b38c",
    "Green Party of Canada" = "#3d9b35",
    "People's Party of Canada" = "#442d7b",
    "Independent" = "#dcdcdc"
  )
}

#' @export
#' @rdname party_colour
ScaleParty <- ggplot2::ggproto(
  "ScaleParty",
  ggplot2::ScaleDiscrete,

  map = function(self, x, limits = self$get_limits()) {
    self$palette <- pal_party(
      limits,
      party_colours = self$party_colours,
      palette = self$palette_extra
    )

    ggplot2::ggproto_parent(ggplot2::ScaleDiscrete, self)$map(x, limits)
  }
)
