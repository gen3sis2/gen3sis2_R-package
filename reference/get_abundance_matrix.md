# Get abundance matrix

This function constructs an abundance matrix based on the space sites.

## Usage

``` r
get_abundance_matrix(
  species_list,
  space = NULL,
  xy = FALSE,
  empty_sites = FALSE
)
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

an abundance matrix with sites as rows and species as columns.

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
  
  get_abundance_matrix(data$all_species)[1:5,]
} # }
```
