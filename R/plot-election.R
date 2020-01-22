
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
      vars(forcats::fct_rev(.data$province)), vars(lubridate::year(.data$election_date)),
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



#' Plot the results of an election (bar chart)
#'
#' Plots the number of votes or the number of seats as a bar chart. Use
#' `position = "fill"` to visualize vote proportions.
#'
#' @inheritParams election_results
#' @param x_var,fill_var A variable in [election_results()] to map to the `x` or `fill`
#'   aesthetics, respectively
#' @param facet_var A variable to use with [ggplot2::facet_wrap()]
#' @param facet_scales Scales, most usefully "free" or "fixed".
#' @param position A position, most usefully "stack" or "fill".
#' @param n_parties The number of parties to include.
#'
#' @return A [ggplot2::ggplot()]
#' @export
#'
#' @examples
#' plot_votes()
#' plot_seats()
#'
plot_votes <- function(years = 2006:2019, provinces = election_provinces(),
                       x_var = "election_year", fill_var = "party", facet_var = NULL,
                       facet_scales = "fixed", position = "stack", n_parties = 5) {
  plot_data <- election_results(
    years = years,
    provinces = provinces,
    results = c("Elected", "Defeated")
  ) %>%
    dplyr::mutate(
      party = .data$party %>%
        forcats::fct_lump(n = n_parties, w = .data$votes) %>%
        forcats::fct_reorder(.data$votes, sum),
      election_date = factor(.data$election_date),
      election_year = factor(.data$election_year)
    )

    mapping <- aes(
      x = .data[[x_var]],
      weights = .data$votes / 1e6,
      fill = .data[[fill_var]]
    )

    labels <- ggplot2::labs(
      x = x_var,
      fill = fill_var
    )

    if (is.null(fill_var)) {
      mapping$fill <- NULL
      scale_fill <- NULL
    } else if(fill_var == "party") {
      scale_fill <- scale_fill_party()
    }

    if (is.null(facet_var)) {
      facet <- NULL
    } else {
      facet <- ggplot2::facet_wrap(vars(.data[[facet_var]]), scales = facet_scales)
    }

    if (position == "fill") {
      scale_y <- ggplot2::scale_y_continuous(
        labels = scales::percent_format(),
        name = "Proportion of votes"
      )
    } else {
      scale_y <- ggplot2::scale_y_continuous(name = "Millions of votes")
    }

    ggplot(plot_data, mapping) +
      ggplot2::geom_bar(position = position) +
      labels +
      scale_fill +
      facet +
      scale_y +
      ggplot2::theme(legend.position = "bottom")
}

#' @rdname plot_votes
#' @export
plot_seats <- function(years = 2006:2019, provinces = election_provinces(),
                       x_var = "election_year", fill_var = "party", facet_var = NULL,
                       facet_scales = "fixed", position = "stack") {
  plot_data <- election_results(
    years = years,
    provinces = provinces,
    results = "Elected"
  ) %>%
    dplyr::mutate(
      party = .data$party %>%
        forcats::fct_infreq() %>%
        forcats::fct_rev(),
      election_date = factor(.data$election_date),
      election_year = factor(.data$election_year)
    )

  mapping <- aes(
    x = .data[[x_var]],
    fill = .data[[fill_var]]
  )

  labels <- ggplot2::labs(
    x = x_var,
    fill = fill_var
  )

  if (is.null(fill_var)) {
    mapping$fill <- NULL
    scale_fill <- NULL
  } else if(fill_var == "party") {
    scale_fill <- scale_fill_party()
  }

  if (is.null(facet_var)) {
    facet <- NULL
  } else {
    facet <- ggplot2::facet_wrap(vars(.data[[facet_var]]), scales = facet_scales)
  }

  if (position == "fill") {
    scale_y <- ggplot2::scale_y_continuous(
      labels = scales::percent_format(),
      name = "Proportion of seats"
    )
  } else {
    scale_y <- ggplot2::scale_y_continuous(name = "Number of seats")
  }

  ggplot(plot_data, mapping) +
    ggplot2::geom_bar(position = position) +
    labels +
    scale_fill +
    facet +
    scale_y +
    ggplot2::theme(legend.position = "bottom")
}
