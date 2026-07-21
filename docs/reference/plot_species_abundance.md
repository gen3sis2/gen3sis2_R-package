# Plot a species' abundance on a given space

Plot a species' abundance on a given space

## Usage

``` r
plot_species_abundance(species, space, col = NULL)
```

## Arguments

- species:

  a single species object

- space:

  a space object

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
one_species <- all_species[[1]]
space <- readRDS(system.file(
  "extdata/SouthAmerica/species_and_spaces/space_t_2.rds",
  package = "gen3sis2"
))

plot_species_abundance(one_species, space)

library(gen3sis2)

all_species <- readRDS(system.file(
  "extdata/SouthAmerica/species_and_spaces/species_t_2.rds",
  package = "gen3sis2"
))
one_species <- all_species[[1]]
space <- readRDS(system.file(
  "extdata/SouthAmerica/species_and_spaces/space_t_2.rds",
  package = "gen3sis2"
))

plot_species_abundance(one_species, space)
```
