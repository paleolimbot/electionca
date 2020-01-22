
#' Plot an election map
#'
#' @inheritParams election_results
#' @param years A vector of [election_years()] that will be included
#'   in the plot. Riding geography is currently only available
#'   for elections after 2006.
#'
#' @return A [ggplot2::ggplot()]
#' @export
#'
#' @examples
#' plot_election(2019, "Ontario")
#' plot_election_map(2019, "Ontario")
#'
#' @importFrom ggplot2 ggplot aes vars
#' @importFrom magrittr %>%
#' @importFrom rlang .data
plot_election_map <- function(years = 2006:2019, provinces = election_provinces()) {
  # required for stat_sf() to work
  requireNamespace("sf", quietly = TRUE)

  plot_data <- election_results(
    years = years,
    provinces = provinces,
    results = "Elected"
  ) %>%
    dplyr::inner_join(electionca::boundaries, by = c("election_date", "riding")) %>%
    dplyr::mutate(party = forcats::fct_reorder(.data$party, .data$votes, sum, .desc = TRUE))

  ggplot(plot_data, aes(fill = .data$party, geometry = .data$boundary))  +
    ggplot2::geom_sf(size = 0.1) +
    ggplot2::theme_void() +
    scale_fill_party() +
    ggplot2::facet_wrap(vars(lubridate::year(.data$election_date))) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.margin = ggplot2::margin(2, 2, 2, 2, unit = "pt")
    ) +
    ggplot2::labs(fill = NULL) +
    ggplot2::guides(fill = ggplot2::guide_legend(ncol = 2))
}

#' @rdname plot_election_map
#' @export
plot_election <- function(years = 2006:2019, provinces = election_provinces()) {
  plot_data <- election_results(
    years = years,
    provinces = provinces,
    results = "Elected"
  ) %>%
    dplyr::select(-.data$province) %>%
    dplyr::left_join(
      electionca::layout_province_grid,
      by = c("election_date", "riding")
    ) %>%
    dplyr::mutate(
      party = forcats::fct_reorder(.data$party, .data$votes, sum, .desc = TRUE),
      province = factor(.data$province, levels = provinces)
    )

  ggplot(plot_data, aes(.data$geom_x, .data$geom_y, fill = .data$party)) +
    ggplot2::geom_tile() +
    ggplot2::theme_void() +
    ggplot2::facet_grid(
      vars(.data$province), vars(lubridate::year(.data$election_date)),
      scales = "free", space = "free", switch = "y"
    ) +
    ggplot2::theme(
      strip.text.y = ggplot2::element_text(angle = 180, hjust = 1),
      plot.margin = ggplot2::margin(2, 2, 2, 2, unit = "pt")
    ) +
    ggplot2::scale_y_reverse() +
    scale_fill_party() +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(fill = NULL) +
    ggplot2::guides(fill = ggplot2::guide_legend(ncol = 2))
}
