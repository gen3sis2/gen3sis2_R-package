# Get traits matrix

This function constructs a matrix of traits present in occupied sites in
the space

## Usage

``` r
get_traits_matrix(species_list, summarize_fun = NULL)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

- summarize_fun:

  a function or a named vector of functions to summarize trait values.
  Accept custom functions.

## Value

a trait matrix with sites as rows and traits as columns.

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
  
  get_traits_matrix(data$all_species)[1:5,]
} # }
```
