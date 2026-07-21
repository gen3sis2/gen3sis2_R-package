# Allows the user to define the ecological consequences for species within each site, defining thus species survival and abundance

Allows the user to define the ecological consequences for species within
each site, defining thus species survival and abundance

## Usage

``` r
apply_ecology(abundance, traits, local_environment, config)
```

## Arguments

- abundance:

  a named vector of abundances with one abundance value per species

- traits:

  a named matrix containing the species traits, one row per species

- local_environment:

  the environmental values for the given site

- config:

  the config of the simulation

## Value

an abundance vector with the new abundance values for every species. An
abundance value of 0 indicates species death, any other values indicates
survival.

## Details

The arguments of the function allows to apply abiotic and biotic
ecological rules to species in each site. Based on those rules, the
function updates the abundance of each species in each site. If the
abundance is null, the species is absent or extinct. Ecology can account
for local environmental conditions, the abundance of species, and/or
their traits.
