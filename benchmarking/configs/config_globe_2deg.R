######################################
###            METADATA            ###
######################################
# Version: 1.0
#
# Author:
#
# Date: 04.09.2026
#
# space: Globe 2°
#
# Publications: R-package gen3sis
#
# Description: Config used for profiling of run_simulation
######################################

######################################
###         General settings       ###
######################################

# set the random seed for the simulation
random_seed <- 6

# duration <- list(
#     from = 60,
#     to = 0,
#     by = -1,
#     unit = "Myr"
# )
duration <- list(
    from = NA,
    to = NA,
    by = -1,
    unit = "timestep"
)

# maximum total number of species in the simulation before it is aborted
max_number_of_species <- 50000

# maximum number of species within one cell before the simulation is aborted
max_number_of_coexisting_species <- 20000

# a list of traits to include with each species
trait_names <- c("temp", "dispersal")

# ranges to scale the input environments with:
environmental_ranges <- list(
    "temp" = NA
)

# environmental_ranges <- list(
#     "temp" = c(-45, 55),
#     "area" = c(2361.5, 12923.4),
#     "arid" = c(1, 0.5)
# )


######################################
###            Observer            ###
######################################

# a place to inspect the internal state of the simulation and collect additional information if desired
end_of_timestep_observer <- function(data, vars, config) {
    save_species()
    # plot_richness(data$all_species, data$space)
}

######################################
###         Initialization         ###
######################################

# the initial abundance of a newly colonized cell, both during setup and later when colonizing a cell during the dispersal
initial_abundance <- 1

# defines the initial species traits and ranges
# place species within rectangle, our case entire globe

# Taken from gen3sis1 config_worldcenter
create_ancestor_species <- function(space, config) {
    range <- c(-180, 180, -90, 90)
    co <- space$coordinates
    selection <- co[, "x"] >= range[1] &
        co[, "x"] <= range[2] &
        co[, "y"] >= range[3] &
        co[, "y"] <= range[4]
    initial_cells <- rownames(co)[selection]
    new_species <- create_species(initial_cells, config)
    # set local adaptation to max optimal temp equals local temp
    new_species$traits[, "temp"] <- space$environment[, "temp"]
    new_species$traits[, "dispersal"] <- 1
    return(list(new_species))
}


######################################
###             Dispersal          ###
######################################

# returns n dispersal values
get_dispersal_values <- function(n, species, space, config) {
    values <- rweibull(n, shape = 3, scale = 999)

    return(values)
}

######################################
###          Speciation            ###
######################################

# threshold for genetic distance after which a speciation event takes place
# divergence_threshold <- 2 # this is 1Myrs
#divergence_threshold <- 4
divergence_threshold <- 6

# factor by which the divergence is increased between geographically isolated population
# can also be a matrix between the different population clusters
get_divergence_factor <- function(species, cluster_indices, space, config) {
    return(1)
}


######################################
###            Evolution           ###
######################################

# mutate the traits of a species and return the new traits matrix
apply_trait_evolution <- function(species, cluster_indices, space, config) {
    trait_evolutionary_power <- 0.001
    traits <- species[["traits"]]
    cells <- rownames(traits)
    # homogenize trait based on abundance
    for (cluster_index in unique(cluster_indices)) {
        cells_cluster <- cells[which(cluster_indices == cluster_index)]
        mean_abd <- mean(species$abundance[cells_cluster])
        weight_abd <- species$abundance[cells_cluster] / mean_abd
        traits[cells_cluster, "temp"] <- mean(
            traits[cells_cluster, "temp"] * weight_abd
        )
    }
    # mutations
    mutation_deltas <- rnorm(
        length(traits[, "temp"]),
        mean = 0,
        sd = trait_evolutionary_power
    )
    traits[, "temp"] <- traits[, "temp"] + mutation_deltas

    return(traits)
}


######################################
###             Ecology            ###
######################################

# called for every cell with all occurring species, this function calculates the who survives in the current cells
# returns a vector of abundances
# set the abundance to 0 for every species supposed to die

apply_ecology <- function(abundance, traits, space, config) {
    abundance_scale <- 10
    abundance_threshold <- 1
    # abundance threshold
    survive <- abundance >= abundance_threshold
    abundance[!survive] <- 0
    abundance <- ((1 - abs(traits[, "temp"] - space[, "temp"])) *
        abundance_scale) *
        as.numeric(survive)
    # abundance threshold
    abundance[abundance < abundance_threshold] <- 0
    k <- (space[, "temp"] + 0.1) * abundance_scale^2
    total_ab <- sum(abundance)


    if (total_ab > k) {
        alive <- which(abundance > 0)
        while (total_ab > k && length(alive) > 0) {
            loose <- alive[sample.int(length(alive), 1)]
            abundance[loose] <- abundance[loose] - 1
            total_ab <- total_ab - 1
            if (abundance[loose] <= 0) alive <- alive[alive != loose]
        }
        abundance[abundance < 0] <- 0
    }

    return(abundance)
}

get_modifiers <- function(space, config, all_species) {
    NULL
}

apply_modifiers <- function(space, config, modifiers) {
    space$environment
}
