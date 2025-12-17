# Verifies if all required config fields are provided

Verifies if all required config fields are provided

## Usage

``` r
verify_config(config)
```

## Arguments

- config:

  a config object

## Value

Returns TRUE for a valid config, FALSE otherwise, in which case a list
of missing parameters will be printed out as well

## See also

[`create_input_config`](create_input_config.md)
[`write_config_skeleton`](write_config_skeleton.md)

## Examples

``` r
library(gen3sis2)
# get path to input config
datapath <- system.file(file.path("extdata", "TestConfigs"), package="gen3sis2")
path_config <- file.path(datapath, "TestConfig.R")
# create config object
config_object <- create_input_config(path_config)
# check class
class(config_object)
#> [1] "gen3sis_config"
# verify config
verify_config(config_object) # TRUE! this is a valid config
#> [1] TRUE

# break config_object, change name random_seed to r4nd0m_s33d
names(config_object$gen3sis$general)[1] <- "r4nd0m_s33d"
verify_config(config_object) # FALSE! this is an invalid config
#> Missing settings in the configuration from the following categories:
#> general
#> - random_seed
#> [1] FALSE
```
