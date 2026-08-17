# Package index

## Run simulation

Main gen3sis2 functions to run and summarize simulations

- [`gen3sis2`](gen3sis2.md) : gen3sis2: General Engine for
  Eco-Evolutionary Simulations
- [`run_simulation()`](run_simulation.md) : Run a simulation in gen3sis
  and return a summary object possibly saving outputs and plots to the
  output folder

## User defined simulation functions

Functions defined by the user and called by the simulation

- [`apply_ecology()`](apply_ecology.md) : Allows the user to define the
  ecological consequences for species within each site, defining thus
  species survival and abundance
- [`apply_modifiers()`](apply_modifiers.md) : Allows the user to
  populate the world at the beginning of a simulation
- [`apply_trait_evolution()`](apply_trait_evolution.md) : Allows
  defining the function that changes the values of traits of a given
  species at each time-step and in each site. If no operations are
  provided, traits are not changing
- [`create_ancestor_species()`](create_ancestor_species.md) : Allows the
  user to populate the world at the beginning of a simulation
- [`get_dispersal_values()`](get_dispersal_values.md) : Allows the user
  to generate dispersal value(s) for a given species. The simulation
  request the user to return a vector of dispersal values with length
  specified by the num_draws parameter
- [`get_divergence_factor()`](get_divergence_factor.md) : Allows the
  user to define the rate at which geographic clusters accumulate
  differentiation with each other.
- [`get_modifiers()`](get_modifiers.md) : Computed the object used to
  modify the environmental variables trough the simulation

## Simulation related

Functions that are used in the simulation but are not user defined

- [`create_species()`](create_species.md) : Creates a new species
- [`evolution_mode_none()`](evolution_mode_none.md) : No evolution
  considered

## Configuration file

Functions to create and handle configs

- [`create_empty_config()`](create_empty_config.md) : Creates an empty
  config object
- [`create_input_config()`](create_input_config.md) : Creates either an
  empty configuration or a pre-filled configuration object from a config
  file
- [`prepare_directories()`](prepare_directories.md) : Checks if the
  necessary directories exist, and otherwise creates them
- [`verify_config()`](verify_config.md) : Verifies if all required
  config fields are provided
- [`write_config_skeleton()`](write_config_skeleton.md) : Writes out a
  config skeleton

## Spaces input

Functions to create and handle spaces input

- [`check_names()`](check_names.md) : Check names of spaces
- [`check_spaces()`](check_spaces.md) : Check gen3sis_spaces
- [`create_spaces()`](create_spaces.md) : create empty gen3sis_spaces
- [`create_spaces_raster()`](create_spaces_raster.md) : Create an spaces
  input from a named list of rasters or raster files and user defined
  cost function
- [`is_geodynamic()`](is_geodynamic.md) : Determine if environmental
  data is geodynamic

## Plotting functions

Functions used to plot gen3sis 2 spaces and species

- [`color_richness()`](color_richness.md) : Define richness color scale
  which is colour-vision deficient and colour-blind people safe based on
  scientific colour maps by Fabio Crameri
- [`color_richness_CVDCBP()`](color_richness_CVDCBP.md) : Define gen3sis
  richness color scale for non colour-vision deficient
- [`plot_ranges()`](plot_ranges.md) : Plot species ranges of the given
  list of species on a space
- [`plot_richness()`](plot_richness.md) : Plot the richness of the given
  list of species on a space
- [`plot_space()`](plot_space.md) : Plot the environment variable of a
  given space
- [`plot_space_overview()`](plot_space_overview.md) : Plot the outline
  of a given space over time
- [`plot_species_abundance()`](plot_species_abundance.md) : Plot a
  species' abundance on a given space
- [`plot_species_presence()`](plot_species_presence.md) : Plot a
  species' presence on a given space
- [`plot_summary()`](plot_summary.md) : Plot simulation default summary
  object
- [`raster_plot_aesthetics()`](raster_plot_aesthetics.md) : Provides the
  default gen3sis2 plot aesthetics for raster spaces
- [`set_color()`](set_color.md) : Set the color scale for plots, adding
  zero_col if zero values are present
- [`sf_plot_aesthetics()`](sf_plot_aesthetics.md) : Provides the default
  gen3sis2 plot aesthetics for H3 and points spaces

## Support functions

Functions that can be used to save, get and handle sumation information

- [`distance_subset()`](distance_subset.md) : Subset distance matrix
- [`diversification_summary()`](diversification_summary.md) :
  Diversification summary
- [`get_abundance_matrix()`](get_abundance_matrix.md) : Get abundance
  matrix
- [`get_divergence_matrix()`](get_divergence_matrix.md) : Returns the
  full divergence matrix for a given species (site x site).
- [`get_extant_species()`](get_extant_species.md) : Gets extant species
- [`get_geo_richness()`](get_geo_richness.md) : calculate the richness
  of a list of species over a given space
- [`get_mean_richness()`](get_mean_richness.md) : Get global mean
  richness
- [`get_presence_matrix()`](get_presence_matrix.md) : Get
  presence-absence matrix
- [`get_site_abundance()`](get_site_abundance.md) : Gets site abundance
- [`get_space_subset()`](get_space_subset.md) : Gets space subset
- [`get_species_prevalence()`](get_species_prevalence.md) : Get species
  prevalence
- [`get_species_range()`](get_species_range.md) : Gets species range
- [`get_species_subset()`](get_species_subset.md) : Gets species subset
- [`get_trait_abundance()`](get_trait_abundance.md) : Get abundance and
  traits matrix
- [`get_trait_diversity()`](get_trait_diversity.md) : Get trait
  diversity
- [`get_trait_evenness()`](get_trait_evenness.md) : Get trait evenness
- [`get_traits_matrix()`](get_traits_matrix.md) : Get traits matrix
- [`get_weighted_endemism()`](get_weighted_endemism.md) : Gets weighted
  endemism
- [`save_abundance()`](save_abundance.md) : This function can be called
  within the observer function to save the species abundances.
- [`save_divergence()`](save_divergence.md) : This function can be
  called within the observer function to save the compressed species
  divergence.
- [`save_occupancy()`](save_occupancy.md) : This function can be called
  within the observer function to save the current occupancy pattern
- [`save_phylogeny()`](save_phylogeny.md) : This function can be called
  within the observer function to save the current phylogeny.
- [`save_richness()`](save_richness.md) : This function can be called
  within the observer function to save the current richness pattern
- [`save_space()`](save_space.md) : This function can be called within
  the observer function to save the current space, can be called
  independently by the user and is called by other observer functions
  relying on the space to be present (e.g. save_species)
- [`save_species()`](save_species.md) : This function can be called
  within the observer function to save the full species list.
- [`save_traits()`](save_traits.md) : This function can be called within
  the observer function to save the species traits.
- [`time_unit_check()`](time_unit_check.md) : Check if the used time
  unit is accepted
