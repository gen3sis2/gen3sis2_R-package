\dontrun{
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
}

