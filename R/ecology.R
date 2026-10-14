# Copyright (c) 2020, ETH Zurich

#' Allows the user to define the ecological consequences for species within each site,
#' defining thus species survival and abundance
#'
#' @details The arguments of the function allows to apply abiotic and biotic ecological rules to species in each
#' site. Based on those rules, the function updates the abundance of each species in each site. If the abundance
#' is null, the species is absent or extinct. Ecology can account for local environmental conditions, the abundance of
#' species, and/or their traits.
#'
#' @param abundance a named vector of abundances with one abundance value per species
#' @param traits a named matrix containing the species traits, one row per species
#' @param local_environment the environmental values for the given site
#' @param config the config of the simulation
#'
#' @return an abundance vector with the new abundance values for every species.
#' An abundance value of 0 indicates species death, any other values indicates survival.
#'
#' @keywords user
#' @export
apply_ecology <- function(abundance, traits, local_environment, config) {
  stop(
    "this function documents the user function interface only, do not use it."
  )
}

# TODO docstring
#' @export
cell_ecology <- function(cell, environment, all_species_presence, species, config) {
    # strat loop over ids with at least one species...
    local_environment <- environment[cell, , drop = FALSE]

    coo_sp <- which(all_species_presence[cell, ])
    # create coocuring species traits for idi
    traits <- matrix(
        nrow = length(coo_sp),
        ncol = length(config$gen3sis$general$trait_names)
    )
    abundance <- numeric(length(coo_sp))

    colnames(traits) <- config$gen3sis$general$trait_names

    i <- 1
    for (spi in coo_sp) {
        traits[i, ] <- species[[spi]][["traits"]][
            cell,
            config$gen3sis$general$trait_names
        ]
        abundance[i] <- species[[spi]][["abundance"]][cell]
        i <- i + 1
    }

    rownames(traits) <- coo_sp
    names(abundance) <- coo_sp

    NEW_abd <- config$gen3sis$ecology$apply_ecology(
        abundance,
        traits,
        local_environment,
        config
    )

    names(NEW_abd) <- coo_sp
    NEW_abd
}

#' Orchestrates for applying the ecology function to all sites
#'
#' @details The ecology is applied on a per site basis over all species occurring in each site.
#' Therefore this function iterates over all sites and collects the abundance and traits of any species occurring there.
#' It then calls the user supplied apply_ecology function to this collection and apply ecology to each site.
#'
#' @param config the general config of the simulation
#' @param data the general data list
#' @param vars the general variables list
#'
#' @return returns the standard val(config, data, vars) list
#' @noRd
loop_ecology <- function(config, data, vars) {
  # skip ecology function if config$exp$enable_eco_mec is FALSE
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("entering ecology module @ time", vars$ti, "\n"))
  }

  all_cells <- rownames(data$space$environment)
  all_species_presence <- do.call(
    cbind,
    lapply(data$all_species, FUN = function(sp) {
      all_cells %in% names(sp$abundance)
    })
  )
  rownames(all_species_presence) <- all_cells

  # take ids that have at least one species...
  #occupied_cells <- rownames(geo_sp_ti[rowSums(data$geo_sp_ti)>0, ,drop=FALSE])
  occupied_cells <- rownames(all_species_presence)[
    rowSums(all_species_presence) > 0
  ]
  
  number_of_species <- rowSums(all_species_presence)
  if (any(number_of_species > config$gen3sis$general$max_number_of_coexisting_species)) {
    vars$flag <- "max_number_coexisting_species"
    return(list(config = config, data = data, vars = vars))
  }

  if (future::nbrOfWorkers() > 1) {
    # Share input
    env <- mori::share(data$space[["environment"]])
    presence <- mori::share(all_species_presence)
    species <- mori::share(data$all_species)
    
    NEW_abd <- dynamic_lapply(
      occupied_cells,
      cell_ecology,
      env,
      presence,
      species,
      config
    )
  } else {
    NEW_abd <- dynamic_lapply(
      occupied_cells,
      cell_ecology,
      data$space[["environment"]],
      all_species_presence,
      data$all_species,
      config
    )
  }

  # TODO nested for loop takes a long time, omptimize (more total % than speciation)
  for (i in seq_along(occupied_cells)) {
    # Row of the i-th occupied cell (row i is only the same cell when every cell is occupied)
    coo_sp <- which(all_species_presence[occupied_cells[i], ])
    for (spi in coo_sp) {
      data$all_species[[spi]][["abundance"]][occupied_cells[i]] <- NEW_abd[[i]][[toString(spi)]]
    }
  }
  
  species_list <- lapply(data$all_species, function(i) {
    limit_species_to_cells(i, names(i[["abundance"]])[i[["abundance"]] != 0])
  })
  data$all_species <- species_list
  
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("exiting ecology module @ time", vars$ti, "\n"))
  }
  return(list(config = config, data = data, vars = vars))
}