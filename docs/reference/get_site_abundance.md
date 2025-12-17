# Gets site abundance

This function calculates the total abundance per site in a given space

## Usage

``` r
get_site_abundance(species_list, space, xy = F, empty_sites = F)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

- space:

  the space to calculate over.

- xy:

  if TRUE, site coordinates are returned as matrix columns. Default is
  FALSE.

- empty_sites:

  if TRUE, sites with no species will be included in the matrix. Default
  is FALSE.

## Value

a matrix with sites as rows and abundance as column.

## See also

[`vignette("h-support-functions", package = "gen3sis2")`](../articles/h-support-functions.md)
\[Based on Thomas Keggin's implementation for
gen3sis\](https://gitlab.ethz.ch/ele-public/gen3sis_wiki/-/blob/master/tools/keggin/traitDiversity.R)

## Examples

``` r
if (FALSE) { # \dontrun{
  # mock simulation state
  space <- system.file("extdata/SouthAmerica/species_and_spaces/space_t_2.rds", package = "gen3sis2") |> readRDS()
  
  all_species <- system.file("extdata/SouthAmerica/species_and_spaces/species_t_2.rds", package = "gen3sis2") |> readRDS()
  
  data <- list(
    space = space,
    all_species = all_species
  )
  
  get_site_abundance(data$all_species, data$space)
} # }
```
