# Checks if the necessary directories exist, and otherwise creates them

Checks if the necessary directories exist, and otherwise creates them

## Usage

``` r
prepare_directories(
  config_file = NA,
  input_directory = NA,
  output_directory = NA
)
```

## Arguments

- config_file:

  path to the config file, if NA the default config will be used

- input_directory:

  path to input directory, if NA it will be derived from the config file
  path

- output_directory:

  path to output directory, if NA it will be derived from the config
  file path

## Value

returns a named list with the paths for the input and output directories

## Details

This function will be called by the simulation, but is made available if
the directories should be created manually beforehand, for example to
redirect the stdout to a file in the output directory.

## Examples

``` r
if (FALSE) { # \dontrun{
  # this is an internal function used to attribute directories by deduction
  # called at the start of a simulation run

  prepare_directories(
    config_file = "./any/config.R", # must be provided
    input_directory = "./any/space/dir/", # if NA, will be derived from config_file
    output_directory = "./any/output/dir" # if NA, will be derived from config_file
  )
} # }
```
