# This function can be called within the observer function to save the full species list.

This function can be called within the observer function to save the
full species list.

## Usage

``` r
save_species()
```

## Value

no return value, called for side effects

## See also

[`save_space`](save_space.md)

## Examples

``` r
if (FALSE) { # \dontrun{
#adding the call to the end_of_timestep_observer function at the config file or object 
#will automatically save all the species at an rds file at the outputfolder/species folder
# and the respective space at outputfolder/spaces for the times steps the observer 
# function is called (i.e. call_observer parameter at the run_simulation function)
save_species()
} # }
```
