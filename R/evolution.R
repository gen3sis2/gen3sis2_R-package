# Copyright (c) 2020, ETH Zurich

#' Allows defining the function that changes the values of traits of a given
#' species at each time-step and in each site. If no operations are provided, traits are not changing
#'
#' @details This function is called for any single species alongside an index for
#' the geographical clusters within the species
#'
#' @param species the target species object whose traits will be changed
#' @param cluster_indices an index vector indicating the cluster every occupied site is part of
#' @param space the current space which can co-determine the rate of trait changes
#' @param config the current config
#'
#' @return the mutated species traits matrix
#' @keywords user
#' @export
apply_trait_evolution <- function(species, cluster_indices, space, config) {
  stop(
    "this function documents the user function interface only, do not use it"
  )
}


loop_evolution <- function(config, data, vars) {
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("entering trait evolution module \n"))
  }

  use_sequential <- TRUE
    
  if (future::nbrOfWorkers() > 1) {
    # Estimate cost
    cost <- lengths(lapply(data$all_species, "[[", "abundance"))^2
    use_sequential <- decide_execution("evolution", cost, vars$sigma$evolution, is.null(data$shared_distance), vars$delta_p$evolution)
  }

  if (!use_sequential) {
    vars$parallel_execution_ti <- TRUE

    # Share distance matrix if it has not been shared already
    if (is.null(data$shared_distance)) {
      data$shared_distance <- share_distance(
        data$distance_matrix, 
        config$gen3sis$general$profiling
      )
    }

    parallel_timing <- proc.time()

    # Share data
    species <- mori::share(data$all_species)
    space <- mori::share(data$space)

    data$all_species <- dynamic_lapply(
      species,
      evolve_duplicate,
      space,
      data$shared_distance,
      config,
      ordering = order_lpt(cost)
    )
    vars$delta_p$evolution <- adjust_delta_p("evolution", vars$delta_p$evolution, (proc.time() - parallel_timing)[["elapsed"]], cost, vars$sigma$evolution)
  } else {
    sigma_timing <- proc.time()
    data$all_species <- dynamic_lapply(
      data$all_species,
      evolve,
      data$space,
      data$distance_matrix,
      config,
      sequential = TRUE
    )
    if (future::nbrOfWorkers() > 1) {
      vars$sigma$evolution <- adjust_sigma(vars$sigma$evolution, (proc.time() - sigma_timing)[["elapsed"]], cost)
    }
  }
  
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("exiting trait evolution module \n"))
  }
  return(list(config = config, data = data, vars = vars))
}

#' Ensures saving RDS files works when working on shared data
#'
#' @param species the shared species
#' @param space the shared space of the current time-step
#' @param distance_matrix the descriptor of the shared distance matrix
#' @param config the current config for this simulation run
#'
#' @return the species as a regular R object
#' @noRd
evolve_duplicate <- function(species, space, distance_matrix, config) {
  rlang::duplicate(evolve(species, space, distance_matrix, config), shallow = FALSE)
}


evolve <- function(species, space, distance_matrix, config) {
  if (!length(species[["abundance"]])) {
    return(species)
  }

  # Use shared distance matrix
  if (inherits(distance_matrix, "big.matrix.descriptor")) {
    distance_matrix <- bigmemory::attach.big.matrix(distance_matrix, readonly = TRUE)
  }

  species_presence <- names(species[["abundance"]])

  distances <- config$gen3sis$dispersal$get_dispersal_values(
    length(species_presence),
    species,
    space,
    config
  )

  permutation <- sample(1:length(species_presence), length(species_presence))
  cluster_indices <- Tdbscan_variable(
    distance_matrix[
      species_presence[permutation],
      species_presence[permutation],
      drop = FALSE
    ],
    distances,
    1
  )
  cluster_indices <- cluster_indices[order(permutation)]

  new_traits <- config$gen3sis$trait_evolution$apply_trait_evolution(
    species,
    cluster_indices,
    space,
    config
  )

  species_traits <- colnames(species[["traits"]])
  species[["traits"]][, species_traits] <- new_traits[,
    species_traits,
    drop = FALSE
  ]

  return(species)
}


#' No evolution considered
#'
#' @param species the current species
#' @param cluster_indices indices to assign cells to geographic clusters
#' @param space the current space
#' @param config the general config
#' @return returns an invisible empty species traits when no evolution is considered
#' @keywords simulation
#'
#' @export
evolution_mode_none <- function(species, cluster_indices, space, config) {
  return(invisible(species[["traits"]]))
}
