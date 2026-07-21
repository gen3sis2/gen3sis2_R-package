library(gen3sis2)

spaces <- readRDS(system.file(
  "extdata/SouthAmerica/space/spaces.rds",
  package = "gen3sis2"
))

plot_space_overview(spaces)
