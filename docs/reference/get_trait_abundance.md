# Get abundance and traits matrix

This function constructs a data.frame with abundance and trait
information for each species and site

## Usage

``` r
get_trait_abundance(species_list)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

## Value

a data.frame with traits values, abundance, and site and species
indexes.

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
  
  get_trait_abundance(data$all_species)[1:5,]
} # }
```
