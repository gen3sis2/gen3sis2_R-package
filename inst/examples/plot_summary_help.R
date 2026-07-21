library(gen3sis2)

s <- readRDS(system.file(
  "extdata/SouthAmerica/output/sgen3sis.rds",
  package = "gen3sis2"
))

plot_summary(s)
