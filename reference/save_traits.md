# This function can be called within the observer function to save the species traits.

This function can be called within the observer function to save the
species traits.

## Usage

``` r
save_traits()
```

## Value

no return value, called for side effects

## See also

[`save_species`](save_species.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  ## save the current traits pattern from within observer for each population of each species
  # this functions should be called inside the end_of_timestep_observer function at the config file:
  save_traits()
} # }
```
