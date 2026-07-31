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
apply_ecology <- function(abundance, traits, within_site_divergence, local_environment, config) {
  stop(
    "this function documents the user function interface only, do not use it."
  )
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
    lapply(data$all_species, FUN = function(species) {
      all_cells %in% names(species[["abundance"]])
    })
  )
  rownames(all_species_presence) <- all_cells

  # take ids that have at least one species...
  #occupied_cells <- rownames(geo_sp_ti[rowSums(data$geo_sp_ti)>0, ,drop=FALSE])
  occupied_cells <- rownames(all_species_presence)[
    rowSums(all_species_presence) > 0
  ]

  for (cell in occupied_cells) {
    coo_sp <- which(all_species_presence[cell, ])
    
    if (length(coo_sp) > config$gen3sis$general$max_number_of_coexisting_species) {
      vars$flag <- "max_number_coexisting_species"
      return(list(config = config, data = data, vars = vars))
    }
    
    local_environment <- data$space[["environment"]][cell, , drop = FALSE]

    # create trait matrix for co-occurring species
    traits <- matrix(
      NA,
      nrow = length(coo_sp),
      ncol = length(config$gen3sis$general$trait_names),
      dimnames = list(
        as.character(coo_sp),
        config$gen3sis$general$trait_names
      )
    )
    
    abundance <- numeric(length(coo_sp))
    within_site_divergence <- numeric(length(coo_sp))
    
    names(abundance) <- as.character(coo_sp)
    names(within_site_divergence) <- as.character(coo_sp)

    for (i in seq_along(coo_sp)) {
      spi <- coo_sp[i]
      species <- data$all_species[[spi]]
      
      traits[i, ] <-
        species[["traits"]][
          cell,
          config$gen3sis$general$trait_names
        ]
      
      abundance[i] <-
        species[["abundance"]][cell]
      
      within_site_divergence[i] <-
        species[["divergence"]][["within_site"]][cell]
    }


    ecological_result <-
      config$gen3sis$ecology$apply_ecology(
        abundance = abundance,
        traits = traits,
        within_site_divergence = within_site_divergence,
        local_environment = local_environment,
        config = config
      )
    if(is.list(ecological_result)){
      new_abundance <-
        ecological_result[["abundance"]]
      
      new_within_site_divergence <-
        ecological_result[["within_site_divergence"]]
    }else{
      new_abundance <- ecological_result
    }

    
    for (i in seq_along(coo_sp)) {
      spi <- coo_sp[i]
      
      data$all_species[[spi]][["abundance"]][cell] <-
        new_abundance[i]
      
      if(is.list(ecological_result)){
        data$all_species[[spi]][["divergence"]][["within_site"]][cell] <-
          new_within_site_divergence[i]
      }
    }

  } #end loop over ids with at least one species...
  
  # remove cells that have experienced local extinction
  data$all_species <- lapply(
    data$all_species,
    function(species) {
      retained_cells <- names(species[["abundance"]])[
        species[["abundance"]] > 0
      ]
      
      if (length(retained_cells) < length(species[["abundance"]])) {
        species <- limit_species_to_cells(
          species,
          retained_cells
        )
      }
      
      return(species)
    }
  )
  
  if (config$gen3sis$general$verbose >= 3) {
    cat(paste("exiting ecology module @ time", vars$ti, "\n"))
  }
  return(list(config = config, data = data, vars = vars))
}
