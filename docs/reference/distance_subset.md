# Subset distance matrix

This function subsets a distance matrix based on specified sites

## Usage

``` r
distance_subset(distance_matrix, site_vector)
```

## Arguments

- distance_matrix:

  a local or full distance matrix. Can be either the object or a file
  path.

- site_vector:

  a vector with site indexes.

## Value

a distance matrix with only the specified sites.

## See also

\[Based on Thomas Keggin's implementation for
gen3sis\](https://gitlab.ethz.ch/ele-public/gen3sis_wiki/-/blob/master/tools/keggin/distanceSubset.R)

## Examples

``` r
if (FALSE) { # \dontrun{
  # get and subset a distance matrix
  distance_matrix <- readRDS(system.file("extdata/TestSpaces/geodynamic_spaces/raster/distances_full/distances_full_4.rds", package = "gen3sis2"))
  distance_subset(distance_matrix, site_vector = c("7","15"))
} # }
```
