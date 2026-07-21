# Diversification summary

This function constructs a matrix with speciation, extinction and
diversification rate over timesteps

## Usage

``` r
diversification_summary(gen3sis_output)
```

## Arguments

- gen3sis_output:

  a simulation output object.

## Value

a matrix with timesteps as rows and speciation, extinction and
diversification rates as columns.

## See also

[`vignette("h-support-functions", package = "gen3sis2")`](../articles/h-support-functions.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  ## loading the config
  config_file <- system.file("extdata/TestConfigs/TestConfig.R",package = "gen3sis2")
  config <- create_input_config(config_file, config_name="support_example")
  
  ## loading the space
  space <- system.file("extdata/TestSpaces/geostatic_spaces/raster",package = "gen3sis2")
  
  ## running the simulation
  output_dir <- tempdir()
  s <- run_simulation(
    config = config,
    space = space,
    output_directory = output_dir,
    save_state = "all",
    verbose = 0
  )
  
  diversification_summary(s)
} # }
```
