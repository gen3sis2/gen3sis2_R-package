# This function can be called within the observer function to save the species abundances.

This function can be called within the observer function to save the
species abundances.

## Usage

``` r
save_abundance()
```

## Value

no return value, called for side effects

## See also

[`save_species`](save_species.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  ## save abundances from within observer
  # this functions should be called inside the end_of_timestep_observer function at the config file:
  save_abundance()
} # }
```
