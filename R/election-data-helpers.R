
#' Choices for election years and provinces
#'
#' @export
#'
#' @examples
#' election_dates()
#' election_years()
#' election_provinces()
#'
election_dates <- function() {
  sort(unique(electionca::results$election_date))
}

#' @rdname election_dates
#' @export
election_years <- function() {
  lubridate::year(election_dates())
}

#' @rdname election_dates
#' @export
election_provinces <- function() {
  levels(electionca::layout_province_grid$province)
}

#' Fetch election results in tidy format
#'
#' Fetches election results in the format that you probably want for
#' plotting. For more complex operations, use joins of [results],
#' [ridings], and/or [boundaries]. Note that in elections before
#' 1968 there was more than one MP elected from several ridings.
#'
#' @param years One or more [election_years()] to include in the data
#' @param provinces One or more [election_provinces()] (or terretories)
#'   include in the data. The order of `provinces` is kept in the data
#'   by making the `province` variable a factor.
#' @param results One or both of "Elected" and/or "Defeated" to include
#'   in the data
#'
#' @return A [tibble::tibble()] of a join between [results] and [ridings].
#' @export
#'
#' @examples
#' election_results(
#'   years = 2015:2019,
#'   provinces = c("Nova Scotia", "New Brunswick")
#' )
#'
#' @importFrom magrittr %>%
#' @importFrom rlang .data
election_results <- function(years = election_years(),
                             provinces = election_provinces(),
                             results = "Elected") {
  electionca::results %>%
    dplyr::filter(
      lubridate::year(.data$election_date) %in% years,
      .data$result %in% results
    ) %>%
    dplyr::left_join(
      electionca::ridings %>%
        dplyr::select(.data$riding, .data$province, .data$riding_label, .data$riding_id),
      by = "riding"
    ) %>%
    dplyr::filter(
      .data$province %in% provinces
    ) %>%
    dplyr::mutate(
      province = factor(.data$province, levels = provinces)
    )
}
