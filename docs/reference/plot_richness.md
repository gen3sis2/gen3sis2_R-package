# Plot the richness of the given list of species on a space

Plot the richness of the given list of species on a space

## Usage

``` r
plot_richness(species_list, space, col = NULL)
```

## Arguments

- species_list:

  a list of species to use in the richness calculation

- space:

  a corresponding space object

- col:

  a vector containing a color palette. For discrete values, the first
  element in the vector will be assigned to zero values. If NULL,
  gen3sis2 internal palette will be used. Default is NULL

## Value

no return value, called for plot

## Examples

``` r
library(gen3sis2)

all_species <- readRDS(system.file(
  "extdata/SouthAmerica/species_and_spaces/species_t_2.rds",
  package = "gen3sis2"
))
space <- readRDS(system.file(
  "extdata/SouthAmerica/species_and_spaces/space_t_2.rds",
  package = "gen3sis2"
))

plot_richness(all_species, space)
```
