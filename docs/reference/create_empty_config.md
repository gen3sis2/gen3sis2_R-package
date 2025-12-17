# Creates an empty config object

Creates an empty config object

## Usage

``` r
create_empty_config()
```

## Value

returns an empty config structure

## Details

All config fields are created and set to NA if they can be omitted by
the user or set to NULL if they must be provided before starting a
simulation.

## Examples

``` r
library(gen3sis2)

# Creates an empty config
empty_config <- create_empty_config()

# It is a list with:
# gen3sis: functions and parameters
# user: user defined objects
# directories: input and output directories
names(empty_config)
#> [1] "gen3sis"     "user"        "directories"

# "gen3sis" include the main functions categories 
names(empty_config$gen3sis)
#> [1] "general"         "initialization"  "dispersal"       "speciation"     
#> [5] "trait_evolution" "ecology"         "space_modifier" 
```
