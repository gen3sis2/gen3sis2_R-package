# This function can be called within the observer function to save the current richness pattern

This function can be called within the observer function to save the
current richness pattern

## Usage

``` r
save_richness()
```

## Value

no return value, called for side effects

## See also

[`save_species`](save_species.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  ## save the current richness pattern from within observer for each species
  # this functions should be called inside the end_of_timestep_observer function at the config file:
  save_richness()
} # }
```
