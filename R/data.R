

#' Riding names and approximate geography
#'
#' Derived from the Library of Parliament's
#' [ParlInfo site](https://lop.parl.ca/sites/ParlInfo/default/en_CA/) for
#' [ridings](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Ridings).
#' The `riding_id` column refers to the ID used by the ParlInfo database.
#'
"ridings"

#' Election Results
#'
#' Derived from the Library of Parliament's
#' [ParlInfo site](https://lop.parl.ca/sites/ParlInfo/default/en_CA/) for
#' [election candidates and results](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Elections).
#' The `person_id` column refers to the ID used by the ParlInfo database.
#'
"results"


#' Riding boundaries
#'
#' Boundaries for [ridings] for ridings that have  been in place since 2003. Derived from
#' the Open Canada Datasets for Federal Electoral Districts from
#' [2003](https://open.canada.ca/data/en/dataset/78400aed-2370-4437-97ca-7563c21bacb1),
#' [2013](https://open.canada.ca/data/en/dataset/10801c67-7f18-4ea1-bda7-8962abfc5578) and
#' [2015](https://open.canada.ca/data/en/dataset/737be5ea-27cf-48a3-91d6-e835f11834b0).
#'
"boundaries"

#' Provincial grid layout
#'
#' A layout that can be joined to [results] that works well facetted by
#' `province` with `geom_tile()`.
#'
"layout_province_grid"
