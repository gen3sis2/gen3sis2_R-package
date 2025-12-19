# Get global mean richness

This is a simple function that computes the mean richness of a given
space.

## Usage

``` r
get_mean_richness(species_list, space)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

- space:

  the space to calculate over.

## Value

a numeric value of the mean richness.

## See also

[`vignette("h-support-functions", package = "gen3sis2")`](../articles/h-support-functions.md)

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
  
  get_mean_richness(data$all_species, data$space)
} # }
```
