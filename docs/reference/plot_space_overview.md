# Plot the outline of a given space over time

Plot the outline of a given space over time

## Usage

``` r
plot_space_overview(space, env_names = NULL, breaks = NULL)
```

## Arguments

- space:

  the input space to be plotted

- env_names:

  character. A vector containing variable names to plot

- breaks:

  numeric. A vector containing time slices to plot. If NULL, the older
  and the most recent time-steps will be used. Default is NULL

## Value

no return value, called for plot

## Examples

``` r
library(gen3sis2)

spaces <- readRDS(system.file(
  "extdata/SouthAmerica/space/spaces.rds",
  package = "gen3sis2"
))

plot_space_overview(spaces)
```
