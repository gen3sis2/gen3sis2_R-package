# This function can be called within the observer function to save the current phylogeny.

This function can be called within the observer function to save the
current phylogeny.

## Usage

``` r
save_phylogeny()
```

## Value

no return value, called for side effects

## Examples

``` r
if (FALSE) { # \dontrun{
  ## save phylogeny as a nexus tree from within observer for each species
  # this functions should be called inside the end_of_timestep_observer function at the config file:
  save_phylogeny()
} # }
```
