# Allows the user to populate the world at the beginning of a simulation

Allows the user to populate the world at the beginning of a simulation

## Usage

``` r
create_ancestor_species(space, config)
```

## Arguments

- space:

  the space over which to create the species

- config:

  the configuration information

## Value

a list of species

## Details

Using this function, any number of new species can be created. For every
species, a number of habitable sites from the space are selected and
call 'create_species'. In another step, the user must initialize the
species\[\["traits"\]\] matrix with the desired initial traits values
