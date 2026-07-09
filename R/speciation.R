# Copyright (c) 2020, ETH Zurich

#' Allows the user to define the rate at which geographic clusters accumulate differentiation
#' with each other.
#'
#' @details This function determines the increase in divergence between separated clusters of a species. This function
#' should return either (i) a single value if there is an homogeneous divergence, or (ii) a matrix indicating the divergence that
#' should be accumulated between specific pairwise geographic clusters.
#' 
#' The function can either return a single value or a full cluster by cluster matrix. If only one value is returned it will be used 
#' to increment divergence between any given distinct cluster pairs. If a matrix is returned it has to be in the dimension of
#' cluster x cluster, in which case the divergence values will be increased according to the cluster membership of any cell pairs.
#'
#' For every time step, the divergence between geographic clusters can increase by a defined number. The divergence values can be 
#' scaled optionally using the species or space information. For instance, the divergence between clusters could be higher under
#' warmer temperature, or difference in ecological traits could promote faster divergence between clusters.
#' 
#' Oppositely, for every time-step, if cluster are merged their divergence is reduced by one (1). 
#'
#' @param species the species of the current time step
#' @param cluster_indices an index vector indicating the cluster every occupied site is part of
#' @param space the space of the current time step
#' @param config the config of the simulation
#'
#' @return a single value or a matrix of divergences between all clusters occurring in clusters_indices
#' @keywords user
#' @export
get_divergence_factor <- function(species, cluster_indices, space, config){
  stop("this function documents the user function interface only, do not use it!")
}

#' User-specified function determining the rules for within-cluster divergence of populations. 
#'
#' @param species the species of the current time step
#' @param species_presence sites occupied by the species
#' @param cluster_indices an index vector indicating the cluster every occupied site is part of
#' @param divergence the uncompressed divergence matrix
#' @param space the space of the current time step
#' @param config the config of the simulation
#'
#' @return a site by site matrix of potential divergence
#' @keywords user
#' @export
get_within_cluster_divergence_factor <- function(species, species_presence, cluster_indices, divergence, space, config){
  stop("this function documents the user function interface only, do not use it!")
}

#' User-specified function determining the rules for within-cluster divergence of populations. 
#'
#' @param species the species of the current time step
#' @param species_presence sites occupied by the species
#' @param cluster_indices an index vector indicating the cluster every occupied site is part of
#' @param divergence the uncompressed divergence matrix
#' @param space the space of the current time step
#' @param config the config of the simulation
#'
#' @return a site by site matrix of effective proportional gene flow between sites
#' @keywords user
#' @export
get_effective_gene_flow <- function(species, species_presence, cluster_indices, divergence, space, config){
  stop("this function documents the user function interface only, do not use it!")
}

#' Orchestrates the speciation of any species alive in the simulation
#'
#' @param config the current config object
#' @param data the current data object
#' @param vars the current vars object
#'
#' @return an expanded species list including all newly created species
#' @noRd
loop_speciation <- function(config, data, vars) {
  threw_warning <- FALSE
  if(config$gen3sis$general$verbose>=3){
    cat(paste("entering speciation module \n"))
  }
  for(spi in 1:vars$n_sp){ # loop over existing species
    # get compressed genetic distance for spi
    species <- data$all_species[[spi]]

    if(!length(species[["abundance"]])) {
      next()
    }
    # define occupied cells by species
    species_presence <- names(species[["abundance"]])

    ##calling RCPP function to define physical clusters
    if ( length(species_presence)==1 ){#check if only one cell is occupied
      clu_geo_spi_ti <- 1
    }else{
      distances <- config$gen3sis$dispersal$get_dispersal_values(length(species_presence), species, data$space, config)

      permutation <- sample(1:length(species_presence), length(species_presence))
      clu_geo_spi_ti <- Tdbscan_variable(data$distance_matrix[species_presence[permutation],species_presence[permutation],
                                                            drop=FALSE], distances, 1)
      clu_geo_spi_ti <- clu_geo_spi_ti[order(permutation)]
    }

    gen_dist_spi <- decompress_divergence(species[["divergence"]])
    # update genetic distances
    ifactor <- config$gen3sis$speciation$get_divergence_factor(species, clu_geo_spi_ti, data[["space"]], config)
    # get the divergence decay from the config
    dfactor <- config$gen3sis$speciation$divergence_decay
    
    # checks if divergence factor needs to be time-scaled
    if (config$user$needs_scaling[["get_divergence_factor"]]){
      # time-scale the genetic distance
      ifactor <- ifactor * config$user$scale_time
      # time-scale the divergence decay
      dfactor <- dfactor * config$user$scale_time
      
      # check whether the scaled divergence factor is greater than the divergence threshold.
      # This may indicate that time-scaling is distorting the divergence process, potentially 
      # causing instant speciation. e.g., if the divergence threshold is 2, and it ifactor is 3.
      
      ifactor_exceeds_threshold <- any(ifactor > config$gen3sis$speciation$divergence_threshold)
      
      if(ifactor_exceeds_threshold && !threw_warning){
        # set the flag to avoid spamming the console
        threw_warning <- TRUE
        warning(paste0("Cumulative genetic distance is up to",  signif(max(ifactor) / config$gen3sis$speciation$divergence_threshold, 3),
                       " times greater than divergence_threshold. Time scaling is likely distorting the process. Review recommended.")) 
      }
    }
    
    # update the between cluster divergence
    gen_dist_spi <- update_divergence(
      gen_dist_spi, 
      clu_geo_spi_ti, 
      ifactor = ifactor, 
      dfactor = dfactor
      )
    
    # update the within cluster divergence (or homogenisation)
    if (isTRUE(config$gen3sis$speciation$within_cluster_enabled) & length(species_presence) > 1) {
      gen_dist_spi <- update_within_cluster_divergence(
        divergence = gen_dist_spi,
        species = species,
        species_presence = species_presence,
        cluster_indices = clu_geo_spi_ti,
        space = data[["space"]],
        config = config
      )
    }

    gen_dist_spi <- compress_divergence(gen_dist_spi)

    species[["divergence"]] <- gen_dist_spi
    # scan if any cluster exceeds the threshold
    clu_gen_spi_ti_c <- Tdbscan(gen_dist_spi$compressed_matrix, config$gen3sis$speciation$divergence_threshold, 1)
    clu_gen_spi_ti <- clu_gen_spi_ti_c[gen_dist_spi$index]
    n_new_sp <- max(clu_gen_spi_ti)-1

    # update count of new species at this time-step
    vars$n_new_sp_ti <- vars$n_new_sp_ti + n_new_sp

    if ( n_new_sp > 0 ){ #if a speciation event occurred
      if(config$gen3sis$general$verbose>=3){
        cat(paste("[!]   Wellcome Strange  Thing   [!] \n"))
        cat(paste(n_new_sp,"speciation event(s) happened \n"))
      }

      #attributing the final names of the species in a vector
      desc_unique <- unique(clu_gen_spi_ti)[-1]+vars$n_sp+vars$n_sp_added_ti-1

      #udpate phy
      data$phy <- rbind(data$phy,data.frame("Ancestor"=rep(spi,n_new_sp),
                                            "Descendent"=desc_unique,
                                            "Speciation.Time"=rep(vars$ti,n_new_sp),
                                            "Extinction.Time" = rep(vars$ti, n_new_sp),
                                            "Speciation.Type"=rep("Genetic", n_new_sp)))

      #required for proper initialization of new species
      full_gen_dist <- gen_dist_spi

      gen_dist_spi$index <- gen_dist_spi$index[clu_gen_spi_ti == 1]
      ue <- unique(gen_dist_spi$index)
      gen_dist_spi$compressed_matrix <- gen_dist_spi$compressed_matrix[ue,ue, drop=FALSE]
      #update names
      if (length(ue)>0) {
        fullrange <- 1:length(ue)
        dimnames(gen_dist_spi$compressed_matrix) <- list(fullrange, fullrange)
        for (i in 1:length(gen_dist_spi$index)){
          gen_dist_spi$index[i] <- fullrange[ue==gen_dist_spi$index[i]]
        }
      }

      for (desci in desc_unique) {
        #get the value of current gen_clu
        tep_clu_gen_desci_index <- which(desc_unique==desci)+1
        new_species <- create_species_from_existing(species,
                                                    desci,
                                                    names(species[["abundance"]][clu_gen_spi_ti == tep_clu_gen_desci_index]),
                                                    config)
        data$all_species <- append(data$all_species, list(new_species))

      } # end loop over descendants

      species <- limit_species_to_cells(species = species,
                                        cells = names(species[["abundance"]][clu_gen_spi_ti == 1]))

      #update number of species added
      vars$n_sp_added_ti <- vars$n_sp_added_ti+n_new_sp

      # taking the physical clusters, but removing the already speciated species from spi (i.e. the "mother species")
      clu_geo_spi_ti <- clu_geo_spi_ti[clu_gen_spi_ti==1]

    }# end of creating new species

    data$all_species[[spi]] <- species

  } # end loop over existing species
  if(config$gen3sis$general$verbose>=3){
    cat(paste("exiting speciation module \n"))
  }
  if(config$gen3sis$general$verbose>=3 && vars$n_sp_added_ti > 0){
    cat(paste(vars$n_sp_added_ti,"new species created \n"))
  }
  return(list(config = config, data = data, vars = vars))
}


#' Updates a given divergence matrix
#'
#' @param divergence a divergence matrix
#' @param cluster_indices a cluster index
#' @param ifactor the divergence factor by which the clusters distances are to be increased
#' @param dfactor the homogenisation factor by which the within cluster divergence distances are to be decreased
#'
#' @return an updated divergence matrix
#' @noRd
update_divergence <- function(divergence, cluster_indices, ifactor, dfactor) {
  #udpate genetic distance
  clusters <- unique(cluster_indices)
  if( length(ifactor) == 1 ) {
    # scalar ifactor
    divergence <- divergence + ifactor
    dfactor <- dfactor + ifactor
  } else {
    # matrix ifactor
    divergence <- divergence + ifactor[cluster_indices, cluster_indices]
    # it is assumed that the user already modifies the diagonal of the ifactor matrix so dfactor is not touched
  }
  for ( i in clusters ){
    #in case they belong to same clusters, subtract -2 (for the default case), to that final diference is -1 given previous addition!
    divergence[cluster_indices == i, cluster_indices == i] <-
      divergence[cluster_indices == i, cluster_indices== i] - dfactor
  }
  #setting -1 to zero. Genetic differences can not be negative
  divergence[divergence < 0] <- 0
  ##end updating genetic distance##
  return(divergence)
}

#' Updates a given divergence matrix according to within cluster divergence
#'
#' @param divergence a divergence matrix
#' @param species the species of the current time step
#' @param species_presence character vector of the current occupied sites by the species
#' @param cluster_indices an index vector indicating the cluster every occupied site is part of
#' @param space the space of the current time step
#' @param config the current config object
#'
#' @return an updated divergence matrix
#' @noRd
update_within_cluster_divergence <- function(
    divergence,
    species,
    species_presence,
    cluster_indices,
    space,
    config
) {

  # the product of this function should be a matrix with values bounded between 0 and 1
  # this reflects either completely independent evolution or complete connectivity and the strongest homogenisation 
  G <- config$gen3sis$within_cluster_speciation$get_effective_gene_flow(
    species = species,
    species_presence = species_presence,
    cluster_indices = cluster_indices,
    divergence = divergence,
    space = space,
    config = config
  )
  
  pfactor <- config$gen3sis$within_cluster_speciation$get_within_cluster_divergence_factor(
    species = species,
    species_presence = species_presence,
    cluster_indices = cluster_indices,
    divergence = divergence,
    space = space,
    config = config
  )
  
  G <- G[species_presence, species_presence, drop = FALSE]
  pfactor <- pfactor[species_presence, species_presence, drop = FALSE]
  
  if(config$user$needs_scaling[["get_divergence_factor"]]){
    G <- G * config$user$scale_time
    pfactor <- pfactor * config$user$scale_time
    # might want to incorporate a warning here that determines if 
  }
  
  for (cl in unique(cluster_indices)) {
    idx <- which(cluster_indices == cl)
    
    if (length(idx) <= 1) {
      next
    }
    # unsure about this still: gene flow both limits further divergence and also removes pre-existing divergence
    # the latter is optional because the decay can be set to zero however.
    # the multiplications can happen also between the matrices, so perhaps the p-matrix should be updated by
    # the G matrix within the get_within_cluster_divergence_factor function? 
    divergence[idx, idx] <-
      divergence[idx, idx, drop = FALSE] +
      pfactor[idx, idx, drop = FALSE] *
      (1 - G[idx, idx, drop = FALSE]) -
      config$speciation$divergence_decay *
      G[idx, idx, drop = FALSE]
  }
  
  divergence[divergence < 0] <- 0
  diag(divergence) <- 0
  
  return(divergence)
}

#' Updates the total number of species
#'
#' @param config the current config object
#' @param data the current data list
#' @param vars the current vars list
#'
#' @return the updated vals list
#' @noRd
update1.n_sp.all_geo_sp_ti <- function(config, data, vars) {
  # update number of species
  vars$n_sp <- vars$n_sp+vars$n_sp_added_ti
  return(list(config = config, data = data, vars = vars))
}


#' Updates the total number of species alive
#'
#' @param config the current config object
#' @param data the current data list
#' @param vars the current vars list
#'
#' @return the updated vals list
#' @noRd
update2.n_sp_alive.geo_sp_ti <- function(config, data, vars) {
  # update number of species alive
  vars$n_sp_alive <- sum( sapply(data$all_species, function(sp){ifelse(length(sp[["abundance"]]), 1, 0) }))
  return(list(config = config, data = data, vars = vars))
}
