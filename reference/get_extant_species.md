# Gets extant species

This function simply identify which species has abundance \> 0 in at
least one site

## Usage

``` r
get_extant_species(species_list)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

## Value

a vector with extant species IDs.

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
  
  get_extant_species(data$all_species)
} # }
```
