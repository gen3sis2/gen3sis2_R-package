# Plot simulation default summary object

Plot simulation default summary object

## Usage

``` r
plot_summary(output, summary_title = NULL, summary_legend = NULL)
```

## Arguments

- output:

  a sgen3sis output object resulting from a gen3sis simulation (i.e.
  run_simulation)

- summary_title:

  summary plot title as character. If NULL, title is computed from input
  name.

- summary_legend:

  either a string using \n for new lines or NULL. If NULL, provides
  default summary and simulation information.

## Value

no return value, called for plot

## See also

[`run_simulation`](run_simulation.md)

## Examples

``` r
library(gen3sis2)

s <- readRDS(system.file("extdata/SouthAmerica/output/sgen3sis.rds", package = "gen3sis2"))

plot_summary(s)

library(gen3sis2)

s <- readRDS(system.file("extdata/SouthAmerica/output/sgen3sis.rds", package = "gen3sis2"))

plot_summary(s)
```
