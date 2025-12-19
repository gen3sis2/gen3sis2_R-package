# calculate the richness of a list of species over a given space

calculate the richness of a list of species over a given space

## Usage

``` r
get_geo_richness(species_list, space)
```

## Arguments

- species_list:

  a list of species to include in the richness calculations

- space:

  the space to calculate the richnness over

## Value

a vector with the richness for every cell in the input space

## See also

[`plot_richness`](plot_richness.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  # get path containing example rasters
  datapath <- system.file(file.path("extdata", "WorldCenter"), package="gen3sis")
  # get species at t0
  species_t_0 <- readRDS(file.path(datapath, 
                                   "output/config_worldcenter/species/species_t_0.rds"))
  # get space at t0
  space_t_0 <- readRDS(file.path(datapath, 
                                     "output/config_worldcenter/spaces/space_t_0.rds"))
  
  # plot richness
  plot_richness(species_t_0, space_t_0)
  
  # get geo richness, i.e. richness per sites
  richness_t_0 <- get_geo_richness(species_t_0, space_t_0)
  
  # histogram of richness at t0
  hist(richness_t_0)
} # }
```
