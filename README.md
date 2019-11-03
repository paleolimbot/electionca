
<!-- README.md is generated from README.Rmd. Please edit that file -->

# electionca

<!-- badges: start -->

<!-- badges: end -->

The goal of electionca is to provide Canadian (general) election data in
an easily accessible format for R users. It is based on the Library of
Parliament’s [ParlInfo
site](https://lop.parl.ca/sites/ParlInfo/default/en_CA/), but also
includes geography for elections since 2003
([2003](https://open.canada.ca/data/en/dataset/78400aed-2370-4437-97ca-7563c21bacb1)
and
[2015](https://open.canada.ca/data/en/dataset/737be5ea-27cf-48a3-91d6-e835f11834b0)).
Approximate geography is derived for historical ridings based on riding
associations noted by the Library of Parliament.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("paleolimbot/electionca")
```

## Example

This package contains geographic information about
[ridings](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Ridings)
(`ridings`), [results from each
riding](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Elections)
for each general election (`results`), and low-resolution boundaries,
where these are known (2004-present).

``` r
library(electionca)
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
ridings
#> # A tibble: 1,493 x 9
#>    riding_id riding_label year_start year_end province riding_slug
#>        <dbl> <chr>             <dbl>    <dbl> <chr>    <chr>      
#>  1      1371 Calgary            1904     1908 Alberta  calgary    
#>  2      5224 Medicine Hat       1907     2015 Alberta  medicine_h…
#>  3      2704 Edmonton           1908     1917 Alberta  edmonton   
#>  4      5037 Macleod            1908     1968 Alberta  macleod    
#>  5      7064 Red Deer           1908     2015 Alberta  red_deer   
#>  6      8822 Strathcona         1908     1925 Alberta  strathcona 
#>  7      9615 Victoria           1908     1925 Alberta  victoria   
#>  8       808 Battle River       1917     1953 Alberta  battle_riv…
#>  9      1119 Bow River          1917     1968 Alberta  bow_river  
#> 10      1395 Calgary West       1917     1953 Alberta  calgary_we…
#> # … with 1,483 more rows, and 3 more variables: boundary_id <int>,
#> #   lon <dbl>, lat <dbl>
boundaries
#> Simple feature collection with 984 features and 4 fields
#> geometry type:  GEOMETRY
#> dimension:      XY
#> bbox:           xmin: -2371619 ymin: -724687.7 xmax: 3012991 ymax: 4654012
#> epsg (SRID):    3978
#> proj4string:    +proj=lcc +lat_1=49 +lat_2=77 +lat_0=49 +lon_0=-95 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs
#> # A tibble: 984 x 5
#>    province riding    year_start                       geometry boundary_id
#>  * <chr>    <chr>          <dbl>                  <POLYGON [m]>       <int>
#>  1 Alberta  banff--a…       2013 ((-1480862 604541.3, -1478280…           1
#>  2 Alberta  banff--a…       2015 ((-1480862 604541.3, -1478280…           2
#>  3 Alberta  battle_r…       2013 ((-1154940 662319.9, -1154328…           3
#>  4 Alberta  battle_r…       2015 ((-1262781 491857.4, -1261876…           4
#>  5 Alberta  bow_river       2013 ((-1299247 413966.2, -1298078…           5
#>  6 Alberta  bow_river       2015 ((-1299614 400326.3, -1297659…           6
#>  7 Alberta  calgary_…       2004 ((-1310951 424734.8, -1310560…           7
#>  8 Alberta  calgary_…       2013 ((-1313558 421783.7, -1312380…           8
#>  9 Alberta  calgary_…       2015 ((-1313553 421786.7, -1312376…           9
#> 10 Alberta  calgary_…       2004 ((-1305088 433897.2, -1304074…          10
#> # … with 974 more rows
```
