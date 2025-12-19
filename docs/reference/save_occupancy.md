# This function can be called within the observer function to save the current occupancy pattern

This function can be called within the observer function to save the
current occupancy pattern

## Usage

``` r
save_occupancy()
```

## Value

no return value, called for side effects

## Examples

``` r
if (FALSE) { # \dontrun{
  ## save occupancies from within observer
  # this functions should be called inside the end_of_timestep_observer function at the config file:
  save_occupancy()
} # }
```
