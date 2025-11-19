library(gen3sis2)

space <- system.file("extdata/SouthAmerica/species_and_spaces/space_t_2.rds", package = "gen3sis2") |> readRDS()
all_species <- system.file("extdata/SouthAmerica/species_and_spaces/species_t_2.rds", package = "gen3sis2") |> readRDS()

data <- list(
  space = space,
  all_species = all_species
)

# Inside the observer function:
  
get_presence_matrix(data$all_species)[1:5,] # showing just the five first sites

# With saved files:
  
get_presence_matrix(all_species, space)[1:5,]