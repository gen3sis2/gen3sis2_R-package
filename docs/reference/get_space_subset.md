# Gets space subset

This function subsets the space based on specified sites

## Usage

``` r
get_space_subset(space, site_vector)
```

## Arguments

- space:

  the space to calculate over.

- site_vector:

  a vector with site indexes.

## Value

a gen3sis_space_type object with the specified sites.

## See also

\[Based on Thomas Keggin's implementation for
gen3sis\](https://gitlab.ethz.ch/ele-public/gen3sis_wiki/-/blob/master/tools/keggin/subsetLandscape.R)

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
  
  get_space_subset(data$space, site_vector = c("841","948"))
} # }
```
