# Gets species subset

This function subsets the species list with species occurring in the
specified sites

## Usage

``` r
get_species_subset(species_list, site_vector, trim_sites = FALSE)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

- site_vector:

  a vector with site indexes.

- trim_sites:

  if TRUE, species traits will be trimmed to the specified sites.
  Default is FALSE.

## Value

a list with selected species.

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
  
  get_species_subset(data$all_species, site_vector = c("841"), trim_sites = T)
} # }
```
