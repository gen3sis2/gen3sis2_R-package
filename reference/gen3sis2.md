# gen3sis2: General Engine for Eco-Evolutionary Simulations

Contains an engine for spatially-explicit eco-evolutionary mechanistic
models with a modular implementation and several support functions. It
allows exploring the consequences of ecological and macroevolutionary
processes across realistic or theoretical spatio-temporal spaces on
biodiversity patterns as a general term.

## Details

Gen3sis2 is implemented in a mix of R and C++ code, and wrapped into an
R-package. All high-level functions that the user may interact with are
written in R, and are documented via the standard R / Roxygen help files
for R-packages. Runtime-critical functions are implemented in C++ and
coupled to R via the Rcpp framework. Additionally, the package provides
several convenience functions to generate input data, configuration
files and plots, as well as tutorials in the form of vignettes that
illustrate how to declare models and run simulations.

## References

O. Hagen, B. Flück, F. Fopp, J.S. Cabral, F. Hartig, M. Pontarp, T.F.
Rangel, L. Pellissier. (2021). gen3sis: A general engine for
eco-evolutionary simulations of the processes that shape Earth’s
biodiversity. PLoS biology

## See also

[`create_input_config`](create_input_config.md)
[`create_spaces_raster`](create_spaces_raster.md)
[`run_simulation`](run_simulation.md) [`plot_summary`](plot_summary.md)

## Author

**Maintainer**: Oskar Hagen <oskar@hagen.bio> (space Ecology, WSL and
ETH Zürich, Switzerland)

Authors:

- Oskar Hagen <oskar@hagen.bio> (space Ecology, WSL and ETH Zürich,
  Switzerland)

- Admir C. de O. Junior <admircjunior@gmail.com>

- Bouwe Reijenga <bouwe.reijenga@earth.ox.ac.uk>

- Benjamin Flück <benjamin.flueck@alumni.ethz.ch> (space Ecology, WSL
  and ETH Zürich, Switzerland)

- Fabian Fopp <fabian.fopp@usys.ethz.ch> (space Ecology, WSL and ETH
  Zürich, Switzerland)

- Juliano S. Cabral <juliano.sarmento_cabral@uni-wuerzburg.de>
  (Ecosystem Modeling, Center for Computational and Theoretical Biology,
  University of Würzburg, Würzburg, Germany)

- Florian Hartig <florian.hartig@biologie.uni-regensburg.de>
  (Theoretical Ecology, University of Regensburg, Regensburg, Germany)

- Mikael Pontarp <mikael.pontarp@biol.lu.se> (Department of Biology,
  Lund University, Lund, Sweden)

- Thiago F. Rangel <rangel.tf@gmail.com> (Department of Ecology,
  Universidade Federal de Goiás, Goiás, Brazil)

- Loïc Pellissier <loic.pellissier@usys.ethz.ch> (space Ecology, WSL and
  ETH Zürich, Switzerland) \[thesis advisor\]

Other contributors:

- ETH Zürich \[copyright holder\]

- Charles Novaes de Santana <charles.novaes@usys.ethz.ch> (space
  Ecology, WSL and ETH Zürich, Switzerland) \[contributor\]

- Theo Gaboriau <theo.gaboriau@unil.ch> (Department of Computational
  Biology, Lausanne University, Switzerland) \[contributor\]

## Examples

``` r
if (FALSE) { # \dontrun{

# 1. Load gen3sis and all necessary input data is set (space and config).

library(gen3sis2)

# get path to example input inside package
path_config <- system.file("extdata/TestConfigs/TestConfig.R", package = "gen3sis2")
path_space <- system.file("extdata/TestSpaces/geodynamic_spaces/raster", package = "gen3sis2")

# 2. Run simulation

sim <- run_simulation(
  config = path_config,
  space = path_space,
  output_directory = tempdir())

# 3. Visualize the outputs
# plot summary of entire simulation
plot_summary(sim)
# plot richness at a given time-step
# this only works if species is saved for this time-step
space_t_3 <- readRDS(file.path(tempdir(),"TestConfig","spaces","space_t_3.rds"))
species_t_3 <- readRDS(file.path(tempdir(),"TestConfig","species","species_t_3.rds"))

plot_richness(species_t_3, space_t_3)
} # }
```
