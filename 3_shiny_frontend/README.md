
<!-- README.md is generated from README.Rmd. Please edit that file -->

# treeful

<!-- badges: start -->
<!-- badges: end -->

The goal of treeful is to …

## Installation

You can install the development version of treeful from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("3ful/treeful")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(treeful)
#> The legacy packages maptools, rgdal, and rgeos, underpinning the sp package,
#> which was just loaded, will retire in October 2023.
#> Please refer to R-spatial evolution reports for details, especially
#> https://r-spatial.org/r/2023/05/15/evolution4.html.
#> It may be desirable to make the sf package available;
#> package maintainers should consider adding sf to Suggests:.
#> The sp package is now running under evolution status 2
#>      (status 2 uses the sf package in place of rgdal)
#> Warning: replacing previous import 'data.table::shift' by 'raster::shift' when
#> loading 'treeful'
#> rgeos version: 0.6-4, (SVN revision 699)
#>  GEOS runtime version: 3.10.2-CAPI-1.16.0 
#>  Please note that rgeos will be retired during October 2023,
#> plan transition to sf or terra functions using GEOS at your earliest convenience.
#> See https://r-spatial.org/r/2023/05/15/evolution4.html for details.
#>  GEOS using OverlayNG
#>  Linking to sp version: 2.0-0 
#>  Polygon checking: TRUE
#> Warning: replacing previous import 'DT::dataTableOutput' by
#> 'shiny::dataTableOutput' when loading 'treeful'
#> Warning: replacing previous import 'DT::renderDataTable' by
#> 'shiny::renderDataTable' when loading 'treeful'
## basic example code
```

What is special about using `README.Rmd` instead of just `README.md`?
You can include R chunks like so:

``` r
summary(cars)
#>      speed           dist       
#>  Min.   : 4.0   Min.   :  2.00  
#>  1st Qu.:12.0   1st Qu.: 26.00  
#>  Median :15.0   Median : 36.00  
#>  Mean   :15.4   Mean   : 42.98  
#>  3rd Qu.:19.0   3rd Qu.: 56.00  
#>  Max.   :25.0   Max.   :120.00
```

You’ll still need to render `README.Rmd` regularly, to keep `README.md`
up-to-date. `devtools::build_readme()` is handy for this.

You can also embed plots, for example:

<img src="man/figures/README-pressure-1.png" width="100%" />

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub and CRAN.
