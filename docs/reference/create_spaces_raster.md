# Create an spaces input from a named list of rasters or raster files and user defined cost function

Create an spaces input from a named list of rasters or raster files and
user defined cost function

## Usage

``` r
create_spaces_raster(
  raster_list,
  cost_function,
  directions = 16,
  output_directory,
  full_dists = FALSE,
  overwrite_output = FALSE,
  verbose = FALSE,
  duration = list(from = NA, to = NA, by = NA, unit = "Ma"),
  geodynamic = NULL,
  ...
)
```

## Arguments

- raster_list:

  list of named list(s) of raster(s) or raster file(s) name(s). Starting
  from the past towards the present. NOTE: the list names are important
  since these are the environmental names

- cost_function:

  function that returns a cost value between a pair of sites (neighbors)
  that should have the following signature:
  `cost_function <- function(src, src_habitable, dest, dest_habitable){ rules for environmental factors to be considered (e.g. elevation) return(cost value) }`
  where: \*\*src\*\* is a vector of environmental conditions for the
  origin sites, \*\*src_habitable\*\* (TRUE or FALSE) for habitable
  condition of the origin sites, \*\*dest\*\* is a vector of
  environmental conditions for the destination site, dest_habitable
  (TRUE or FALSE) for habitable condition of the destination cell

- directions:

  4, 8 or 16 neighbors, dictates the connection of cell neighbors on
  adjacency matrix (see gistance package). This does not control the
  dispersal processes directly in the simulation, it only makes diagonal
  distances less biased. E.g., when using directions = 4, diagonals are
  not directly computed, thus inflating distances for diagonal movement.
  Default is 16.

- output_directory:

  path for storing the gen3sis ready space (i.e. space.rds, metadata.txt
  and full- and/or local_distance folders)

- full_dists:

  should a full distance matrix be calculated? TRUE or FALSE? Default is
  FALSE. If TRUE calculates the entire distance matrix for every
  time-step and between all habitable cells (faster CPU time, higher
  storage required). If FALSE (default), only local distances are
  calculated (slower CPU time when simulating but smaller gen3sis space
  size)

- overwrite_output:

  TRUE or FALSE

- verbose:

  print distance calculation progress (default: FALSE)

- duration:

  list with from, to, by and unit. Use negative value to represent past,
  0 to represent present and positive values to represent future. E.g.,
  a spaces from 10 Ma in the past to 10 Ma into the future, each
  timestep comprising 5 Ma:
  `duration = list(from = -10, to = 10, by = 5, unit = "Ma")`

- geodynamic:

  True or False, if the space is dynamic (e.g. sea-level change) or
  static. Default is NULL, i.e. deciding final value based on the input
  data using [`?is_geodynamic`](is_geodynamic.md).

- ...:

  additional arguments to be passed to the
  [`create_spaces`](create_spaces.md) function. Possible arguments
  include:

  - `author`: author of the space, see
    [`?create_spaces`](create_spaces.md)

  - `source`: source of the space, see
    [`?create_spaces`](create_spaces.md)

  - `crs`: the coordinate reference system in crs format (see
    raster::crs). Default is defined by
    [`create_spaces`](create_spaces.md)

  - `description`: list with env and methods, see
    [`?create_spaces`](create_spaces.md)

## Value

no return object. This function saves the space input files for gen3sis
at the output_directory

## Details

This function creates the input spaces.rds files needed by the
run_simulation function. It uses as input the dynamic rasters and user
defined geodesimal corrections as well as rules to define the connection
costs between sites

## See also

[`run_simulation`](run_simulation.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(terra)
library(gen3sis2)
# Get some rasters for each timestep
temperature <- terra::rast("your/temperature_raster.tif")
aridity <- terra::rast("your/aridity_raster.tif")
precipitation <- terra::rast("your/precipitation_raster.tif")
  
# Organize them
environmental_variables <- list(
  temperature = temperature,
  aridity = aridity,
  precipitation = precipitation
)
  
create_spaces_raster(
  raster_list = environmental_variables,
  cost_function = function(source, dest) { # any cost function
    if (!all(source$habitable, dest$habitable)) {
      return(2 / 1000)
    } else {
      return(1 / 1000)
    }
  },
  directions = 8,
  output_directory = "./where/to/save",
  full_dists = TRUE, # save full distance matrices
  overwrite_output = TRUE,
  verbose = TRUE,
  duration = list(from = 65, to = 0, by = -1, unit = "Ma"),
  geodynamic = TRUE
)
} # }
```
