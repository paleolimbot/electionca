
<!-- README.md is generated from README.Rmd. Please edit that file -->

# electionca

<!-- badges: start -->

<!-- badges: end -->

The goal of electionca is to provide Canadian (general) election data in
an easily accessible format for R users. It is based on the Library of
Parliament’s [History of the Federal Electoral
Ridings, 1867-2010](https://open.canada.ca/data/en/dataset/ea8f2c37-90b6-4fee-857e-984d3060184e),
but also includes results from the
[2011](https://www.elections.ca/content.aspx?section=ele&document=index&dir=pas/41ge&lang=e)
and
[2015](https://www.elections.ca/content.aspx?section=ele&document=index&dir=pas/42ge&lang=e)
general elections. Geography for elections since 2003 was derived from
the
[2003](https://open.canada.ca/data/en/dataset/78400aed-2370-4437-97ca-7563c21bacb1)
and
[2015](https://open.canada.ca/data/en/dataset/737be5ea-27cf-48a3-91d6-e835f11834b0)
riding boundaries; geography for previous elections is currently
missing.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("paleolimbot/electionca")
```

## Example

This package contains geographic information about ridings
(`boundaries`), and results from each riding, for each general election
(`results`).

``` r
library(electionca)
boundaries
#> Simple feature collection with 659 features and 4 fields
#> geometry type:  POLYGON
#> dimension:      XY
#> bbox:           xmin: -141.0181 ymin: 41.67695 xmax: -52.5823 ymax: 89.99943
#> epsg (SRID):    4326
#> proj4string:    +proj=longlat +datum=WGS84 +no_defs
#> # A tibble: 659 x 5
#>    riding    riding_label   province   geo_id                      geometry
#>    <chr>     <chr>          <chr>      <chr>                  <POLYGON [°]>
#>  1 vegrevil… Vegreville--W… Alberta    2003_… ((-112.5474 53.99663, -112.5…
#>  2 bruce--g… Bruce--Grey--… Ontario    2003_… ((-80.93519 45.25007, -80.59…
#>  3 lambton-… Lambton--Kent… Ontario    2003_… ((-81.24406 43.2119, -81.224…
#>  4 london--… London--Fansh… Ontario    2003_… ((-81.16698 43.05102, -81.15…
#>  5 edmonton… Edmonton--Mil… Alberta    2003_… ((-113.4286 53.48668, -113.4…
#>  6 fleetwoo… Fleetwood--Po… British C… 2003_… ((-122.7003 49.20478, -122.6…
#>  7 london_n… London North … Ontario    2003_… ((-81.19803 42.98447, -81.19…
#>  8 cardigan  Cardigan       Prince Ed… 2003_… ((-62.55005 45.86056, -62.69…
#>  9 brampton… Brampton West  Ontario    2003_… ((-79.77164 43.69462, -79.76…
#> 10 mississa… Mississauga--… Ontario    2003_… ((-79.64377 43.65257, -79.63…
#> # … with 649 more rows
results
#> # A tibble: 39,992 x 8
#>    election_date province  riding   name    party  votes elected occupation
#>    <date>        <chr>     <chr>    <chr>   <chr>  <dbl> <lgl>   <chr>     
#>  1 1867-08-07    New Brun… albert   John W… Liber…   778 TRUE    farmer    
#>  2 1867-08-07    New Brun… albert   Henry … Unkno…   714 FALSE   <NA>      
#>  3 1867-08-07    New Brun… carleton Hon. C… Liber…    NA TRUE    general m…
#>  4 1867-08-07    New Brun… charlot… John B… Liber…  1214 TRUE    businessm…
#>  5 1867-08-07    New Brun… charlot… Robert… Unkno…   918 FALSE   <NA>      
#>  6 1867-08-07    New Brun… city_an… Hon. J… Conse…    NA TRUE    lawyer    
#>  7 1867-08-07    New Brun… city_of… Hon. S… Liber…  1402 TRUE    druggist  
#>  8 1867-08-07    New Brun… city_of… John W… Unkno…   610 FALSE   <NA>      
#>  9 1867-08-07    New Brun… glouces… Hon. T… Liber…  1061 TRUE    editor    
#> 10 1867-08-07    New Brun… glouces… John M… Unkno…   671 FALSE   <NA>      
#> # … with 39,982 more rows
```
