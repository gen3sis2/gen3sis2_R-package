# Writes out a config skeleton

Writes out a config skeleton

## Usage

``` r
write_config_skeleton(file_path = "./config_skeleton.R", overwrite = FALSE)
```

## Arguments

- file_path:

  file path to write the file into

- overwrite:

  overwrite existing file defaults to FALSE

## Value

returns a boolean indicating success or failure

## Details

This function writes out a config skeleton, that is, an empty config
file to be edited by the user.

## Examples

``` r
# set config_empty.R file path
config_file_path <- file.path(tempdir(), "config_empty.R")
#writes out a config skeleton
write_config_skeleton(config_file_path)
#> Warning: /var/folders/85/wlm9sk6j32q_hg2dpxl1k7_40000gn/T//Rtmpu30hDj/config_empty.R exists, file not written.
#> [1] FALSE
```
