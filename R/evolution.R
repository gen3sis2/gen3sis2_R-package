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


# TODO same as in disperal, define once, avoid duplicate, fine for now
# Longest processing time first
order_lpt <- function(cost) {
  workers <- future::nbrOfWorkers()
  
  # If all species fit into workers, pass them as is
  if (length(cost) <= workers) {
    return(1)
  }
  
  assigned_worker <- integer(length(cost))
  worker_load <- numeric(workers)
  # Split jobs equally across workers
  jobs_per_worker <- lengths(parallel::splitIndices(length(cost), workers))
  
  # Order by species count (more species means more work that needs to be done)
  for (i in order(cost, decreasing = TRUE, method = "radix")) {
    # Get all workers that have space for jobs
    workers_with_space <- which(jobs_per_worker > 0)
    # Select worker with smallest load
    worker <- workers_with_space[which.min(worker_load[workers_with_space])]
    
    # Add cost to worker
    worker_load[worker] <- worker_load[worker] + cost[i]
    
    # Assign species to selected worker
    assigned_worker[i] <- worker
    
    # Remove a slot of selected worker
    jobs_per_worker[worker] <- jobs_per_worker[worker] - 1
  }
  
  return(structure(1, ordering = order(assigned_worker)))
}


loop_evolution <- function(config, data, vars) {
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("entering trait evolution module \n"))
  }
  
  if (future::nbrOfWorkers() > 1) {
    # Estimate cost per species
    # Tdbscan_variable accounts for most of the work, cost is calculated with its input size
    cost <- lengths(lapply(data$all_species, "[[", "abundance"))^2
    
    # Share data
    species <- mori::share(data$all_species)
    space <- mori::share(data$space)

    data$all_species <- dynamic_lapply(
      species,
      evolve_duplicate,
      space,
      data$shared_distance,
      config,
      future.scheduling = order_lpt(cost)
    )
  } else {
    data$all_species <- dynamic_lapply(
      data$all_species,
      evolve,
      data$space,
      data$distance_matrix,
      config
    )
  }
  
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("exiting trait evolution module \n"))
  }
  return(list(config = config, data = data, vars = vars))
}

# Ensure saveRDS works properly (See Persistence https://cran.r-project.org/web/packages/mori/refman/mori.html#share)
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
