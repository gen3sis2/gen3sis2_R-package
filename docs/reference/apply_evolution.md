# Allows defining the function that changes the values of traits of a given species at each time-step and in each site. If no operations are provided, traits are not changing

Allows defining the function that changes the values of traits of a
given species at each time-step and in each site. If no operations are
provided, traits are not changing

## Usage

``` r
apply_evolution(species, cluster_indices, space, config)
```

## Arguments

- species:

  the target species object whose traits will be changed

- cluster_indices:

  an index vector indicating the cluster every occupied site is part of

- space:

  the current space which can co-determine the rate of trait changes

- config:

  the current config

## Value

the mutated species traits matrix

## Details

This function is called for any single species alongside an index for
the geographical clusters within the species
