# Get trait evenness

This function calculates trait evenness per cell (functional evenness,
sensu Mouillot et al. (2005))

## Usage

``` r
get_trait_evenness(species_list, traits = NULL)
```

## Arguments

- species_list:

  a list of species to include in the calculations.

- traits:

  a vector with trait names.

## Value

a matrix with site as rows and trait eveness as columns.

## References

Mouillot D, Mason WH, Dumay O, Wilson JB. Functional regularity: a
neglected aspect of functional diversity. Oecologia. 2005
Jan;142(3):353-9. doi: 10.1007/s00442-004-1744-7. Epub 2004 Nov 20.
PMID: 15655690.

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
  
  get_trait_evenness(data$all_species, c("temp"))
} # }
"inst/examples/support_functions/get_trait_evenness.R"
#> [1] "inst/examples/support_functions/get_trait_evenness.R"
```
