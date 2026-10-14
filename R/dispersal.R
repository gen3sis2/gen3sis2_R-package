# Copyright (c) 2020, ETH Zurich

#' Allows the user to generate dispersal value(s) for a given species. The simulation request the user
#' to return a vector of dispersal values with length specified by the num_draws parameter
#'
#' @details Dispersal values are used for two different operations.
#' First, for colonization, dispersal values are used to evaluate pairwise dispersal
#' events between colonized and uninhabited sites.
#' Second, for geographic clustering, dispersal values are used during the clustering of
#' species populations when determining which sites
#' are in range of each other and belong to the same geographic cluster.
#'
#' num_draws tells the user how many dispersal values are requested by the simulation when this function is called and must
#' be returned. It can be of varying length depending on the operation calling it, i.e. colonization or geographic clustering.
#' If the dispersal is considered as fixed the function should return a vector of length num_draws with repeated identical
#' values, or varying values in case of more complex dispersal kernels.
#'
#' Note: if the distances are randomized the cluster formation may be asymmetrical. Therefore the ordering of all
#' clustering operations is randomized.
#'
#' @param num_draws the number of dispersal values drawn
#' @param species the species for which the values are to be produced
#' @param space the space of the current time step
#' @param config the config of the simulation
#'
#' @return a numerical vector of length num_draws with dispersal values
#' @keywords user
#' @export
get_dispersal_values <- function(num_draws, species, space, config) {
  stop(
    "this function documents the user function interface only, do not use it"
  )
}

# TODO same as in evolution
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
  
  # Order by species count (more species means more work that needs to be done # TODO das beweisen da prinizip darauf basiert, dass species job länge ensprechen)
  for (i in order(cost, decreasing = TRUE, method = "radix")) {
    # Get all workers that have space for jobs
    workers_with_space <- which(jobs_per_worker > 0)
    # Select worker with smalles load
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

# Same as num_draws in disperse
# Cost is number of draws: one draw for each (occupied, free_cell) pair
estimate_cost <- function(species, cells) {
  occupied_cells <- as.numeric(lengths(lapply(species, "[[", "abundance")))
  occupied_cells * (cells - occupied_cells)
}

#' The top level loop for dispersal
#'
#' @details orchestrates the dispersal of all species.
#' This is a per species process that looks at every species individually
#'
#' @param config config object
#' @param data general data container
#' @param vars general variables container
#'
#' @return returns the standard val(config, data, vars) list
#' @noRd
loop_dispersal <- function(config, data, vars) {
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("entering dispersal module \n"))
  }
  
  if (future::nbrOfWorkers() > 1) {
    # Estimate cost per species
    cost <- estimate_cost(data$all_species, nrow(data$space$coordinates))

    # Share data
    species <- mori::share(data$all_species)
    space <- mori::share(data$space)

    data$all_species <- dynamic_lapply(
      species,
      disperse_duplicate,
      space,
      data$shared_distance,
      config,
      future.scheduling = order_lpt(cost)
    )
  } else {
    data$all_species <- dynamic_lapply(
      data$all_species,
      disperse,
      data$space,
      data$distance_matrix,
      config
    )
  }
  
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("exiting dispersal module \n"))
  }
  return(list(config = config, data = data, vars = vars))
}

# Ensure saveRDS works properly
disperse_duplicate <- function(species, space, distance_matrix, config) {
  rlang::duplicate(disperse(species, space, distance_matrix, config), shallow = FALSE)
}


#' Disperses a given species
#'
#' @details This function selects all suitable sites from the space and checks whether the given
#' species can reach and colonize any one of them
#'
#' @param species the species to apply dispersal to
#' @param space the space of the current time-step
#' @param distance_matrix the distance matrix between sites to check the dispersal capabilities against
#' @param config the config of the simulation
#'
#' @return the dispersed species object
#' @noRd
disperse <- function(species, space, distance_matrix, config) {
  if (!length(species[["abundance"]])) {
    return(species)
  }

  # Use shared distance matrix
  if (inherits(distance_matrix, "big.matrix.descriptor")) {
    distance_matrix <- bigmemory::attach.big.matrix(distance_matrix, readonly = TRUE)
  }

  presence_spi_ti <- names(species[["abundance"]])

  all_cells <- rownames(space$coordinates)
  free_cells <- all_cells[!(all_cells %in% presence_spi_ti)]
  num_draws <- length(free_cells) * length(presence_spi_ti)
  r_disp <- config$gen3sis$dispersal$get_dispersal_values(num_draws, species, space, config)
  
  geo_disp <- distance_matrix[presence_spi_ti, free_cells, drop=FALSE] #lines mark where they are present, cols the possible suitable sites
  geo_disp <- geo_disp <= r_disp

  colonized <- rep(FALSE, length(all_cells))
  names(colonized) <- all_cells
  colonized[free_cells] <- apply(geo_disp, 2, any)

  tep_occ_id <- all_cells[colonized]
  if (length(tep_occ_id) > 0) {
    # if there are new occurrences....
    # destiny of genes
    dest <- which(colonized)
    # origin of genes
    if (length(presence_spi_ti) == 1) {
      orig <- rep(1, length(dest))
    } else {
      orig <- apply(
        geo_disp[, colonized[free_cells], drop = FALSE],
        2,
        function(x) {
          a <- which(x)
          ifelse(length(a) > 1, sample(a, 1), a)
        }
      )
    }
    orig <- as.numeric(presence_spi_ti[orig])
    dest <- tep_occ_id

    species <- disperse_species(species, as.character(orig), dest, config)
  }
  return(species)
}
