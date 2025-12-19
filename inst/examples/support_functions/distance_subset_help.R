\dontrun{
  # get and subset a distance matrix
  distance_matrix <- readRDS(system.file("extdata/TestSpaces/geodynamic_spaces/raster/distances_full/distances_full_4.rds", package = "gen3sis2"))
  distance_subset(distance_matrix, site_vector = c("7","15"))
}