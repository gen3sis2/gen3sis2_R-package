# This function can be called within the observer function to save the current space, can be called independently by the user and is called by other observer functions relying on the space to be present (e.g. save_species)

This function can be called within the observer function to save the
current space, can be called independently by the user and is called by
other observer functions relying on the space to be present (e.g.
save_species)

## Usage

``` r
save_space()
```

## Value

no return value, called for side effects

## See also

[`save_species`](save_species.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  ## save space from within observer for each species
  # this functions should be called inside the end_of_timestep_observer function at the config file:
  save_space()
} # }
```
