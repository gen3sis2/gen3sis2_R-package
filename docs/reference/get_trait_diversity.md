# Get trait diversity

This function calculates trait diversity per cell (sensu Leps et al
2006)

## Usage

``` r
get_trait_diversity(species_list, traits = NULL)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

- traits:

  a vector with trait names.

## Value

a matrix with site as rows and trait diversity as columns.

## References

De Bello, F., Lepš, J. and Sebastià, M.-T. (2006), Variations in species
and functional plant diversity along climatic and grazing gradients.
Ecography, 29: 801-810. https://doi.org/10.1111/j.2006.0906-7590.04683.x

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
  
  get_trait_diversity(data$all_species)[1:5,]
} # }
```
