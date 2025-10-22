# Copyright (c) 2020, ETH Zurich



#' Prepare the internal data structures to be called with the observe_xx functions and call the user provide observer
#' Unless a problem shows up the save_xx functions call getDyn() to get access to the internal state, no prep here.
#'
#' @param data the current data object 
#' @param vars the current vars object
#' @param config the current config
#'
#' @noRd
call_main_observer <- function(data, vars, config) {
  end_of_timestep_seed <- .GlobalEnv$.Random.seed
  config$gen3sis$general$end_of_timestep_observer(data, vars, config)
  .GlobalEnv$.Random.seed <- end_of_timestep_seed 
}


# save_ functions ----

#' This function can be called within the observer function to save the current occupancy pattern
#' @return no return value, called for side effects
#' 
#' @example inst/examples/save_occupancy_help.R
#' @export
save_occupancy <- function() {
  config <- dynGet("config")
  data <- dynGet("data")
  vars <-  dynGet("vars")
  save_space()
  dir.create(file.path(config$directories$output, "occupancy"), showWarnings=FALSE, recursive=TRUE)
  tmp <- get_geo_richness(data$all_species, data$space)
  tmp <- tmp > 0 
  saveRDS(object = tmp,
          file = file.path(config$directories$output, "occupancy", paste0("occupancy_t_", vars$ti, ".rds")))
}


#' This function can be called within the observer function to save the current richness pattern
#' @return no return value, called for side effects
#' 
#' @seealso \code{\link{save_species}}   
#' @example inst/examples/save_richness_help.R
#' @export
save_richness <- function() {
  config <- dynGet("config")
  data <- dynGet("data")
  vars <-  dynGet("vars")
  save_space()
  dir.create(file.path(config$directories$output, "richness"), showWarnings=FALSE, recursive=TRUE)
  richness <- get_geo_richness(data$all_species, data$space)
  saveRDS(object = richness,
          file = file.path(config$directories$output, "richness", paste0("richness_t_", vars$ti, ".rds")))
}


#' This function can be called within the observer function to save the current phylogeny.
#' @return no return value, called for side effects
#' 
#' @example inst/examples/save_phylogeny_help.R
#' @export
save_phylogeny <- function(){
  config <- dynGet("config")
  data <- dynGet("data")
  vars <-  dynGet("vars")
  
  directory <- file.path(config$directories$output, "phylogeny")
  dir.create(directory, showWarnings=FALSE, recursive=TRUE)
  
  file <- file.path(directory, paste0("phylogeny_t_", vars$ti, ".nex"))
  write_nex(phy=data$phy, label="species", output_file=file)
}


#' This function can be called within the observer function to save the full species list.
#' @return no return value, called for side effects
#' 
#' @seealso \code{\link{save_space}}   
#' @example inst/examples/save_species_help.R
#' @export
save_species <- function() {
  config <- dynGet("config")
  data <- dynGet("data")
  vars <-  dynGet("vars")
  save_space()
  dir.create(file.path(config$directories$output, "species"), showWarnings=FALSE, recursive=TRUE)
  species <- data$all_species
  saveRDS(object = species,
          file = file.path(config$directories$output, "species", paste0("species_t_", vars$ti, ".rds")))
}


#' This function can be called within the observer function to save 
#' the current space, can be called independently by the user and is called by 
#' other observer functions relying on the space to be present (e.g. save_species)
#' @return no return value, called for side effects
#' 
#' @seealso \code{\link{save_species}}   
#' @example inst/examples/save_space_help.R
#' @export
save_space <- function() {
  config <- dynGet("config")
  data <- dynGet("data")
  vars <-  dynGet("vars")
  space_file = file.path(config$directories$output, "spaces", paste0("space_t_", vars$ti, ".rds"))
  if( !base::file.exists(space_file)){
    dir.create(file.path(config$directories$output, "spaces"), showWarnings=FALSE, recursive=TRUE)
    space <- data$space
    saveRDS(object = space, file = space_file)
  }
}


#' This function can be called within the observer function to save the species abundances.
#' @return no return value, called for side effects
#' 
#' @seealso \code{\link{save_species}}   
#' @example inst/examples/save_abundance_help.R
#' @export
save_abundance <- function() {
  save_extract("abundance")
}


#' This function can be called within the observer function to save the species traits.
#' @return no return value, called for side effects
#' 
#' @seealso \code{\link{save_species}}   
#' @example inst/examples/save_traits_help.R
#' @export
save_traits <- function() {
  save_extract("traits")
}


#' This function can be called within the observer function to save the compressed species divergence.
#' @return no return value, called for side effects
#' 
#' @seealso \code{\link{save_species}}   
#' @example inst/examples/save_divergence_help.R
#' @export
save_divergence <- function() {
  save_extract("divergence")
}


#' Save a named element from all species.
#' @param element Name of element to save, e.g. "abundance" or "traits"
#' @noRd
save_extract <- function(element) {
  config <- dynGet("config")
  data <- dynGet("data")
  vars <-  dynGet("vars")
  save_space()
  dir.create(file.path(config$directories$output, element), showWarnings=FALSE, recursive=TRUE)
  tmp <- lapply(data$all_species, function(x){return(x[[element]])})
  names(tmp) <- sapply(data$all_species, function(x){x$id})
  saveRDS(object = tmp,
          file = file.path(config$directories$output, element, paste0(element, "_t_", vars$ti, ".rds")))
}


# get_ functions to use inside observer ----

#' construct_community_matrices
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#' @param xy if TRUE, cell coorinates are returned as matix columns. Default is FALSE.
#' @param empty_sites if TRUE, cells with no species will be included in the matrix. Default is FALSE.
#' @param mode "abundane" or "presence" 
#'
#' @returns For internal use only. Returns a community matrix with abundance or presence.
#' @noRd
construct_community_matrices <- function(species_list, space, xy, empty_sites, mode){
  species_id <- sapply(species_list, function(sp){
    sp$id
  })
  
  sites_occupied <- sapply(species_list, function(sp){
    names(sp$abundance)
  }) |> unlist() |> c() |> unique()
  
  community_matrix <- matrix(nrow = length(sites_occupied), ncol = length(species_list))
  
  row.names(community_matrix) <- sites_occupied
  colnames(community_matrix) <- species_id
  
  for (sp in species_list) {
    community_matrix[names(sp$abundance),sp$id] <- sp$abundance
  } 
  
  if(empty_sites){
    empty_sites <- setdiff(row.names(space$coordinates), sites_occupied)
    empty_mtx <- matrix(nrow = length(empty_sites), ncol = length(species_list))
    row.names(empty_mtx) <- empty_sites
    colnames(empty_mtx) <- species_id
    
    community_matrix <- rbind(community_matrix,empty_mtx)
  }
  
  community_matrix[is.na(community_matrix)] <- 0
  
  if(xy){
    coords_mtx <- space$coordinates[row.names(community_matrix),]
    community_matrix <- cbind(coords_mtx, community_matrix)
  }
  
  if(mode == "presence"){
    community_matrix[community_matrix >= 1] <- 1
  }
  
  return(community_matrix)
}

#' get_abundance_matrix
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#' @param xy if TRUE, cell coorinates are returned as matix columns. Default is FALSE.
#' @param empty_sites if TRUE, cells with no species will be included in the matrix. Default is FALSE.
#'
#' @returns an abundance matrix with cells as rows and species as columns.
#' @export
#'
#' @examples #TODO
get_abundance_matrix <- function(species_list, space = NULL, xy=FALSE, empty_sites = FALSE){
  abundance_matrix <- construct_community_matrices(
    species_list = species_list,
    space = space,
    xy = xy,
    empty_sites = empty_sites,
    mode = "abundance")
  return(abundance_matrix)
}

#' get_presence_matrix
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#' @param xy if TRUE, cell coorinates are returned as matix columns. Default is FALSE.
#' @param empty_sites if TRUE, cells with no species will be included in the matrix. Default is FALSE.
#'
#' @returns a presence matrix with cells as rows and species as columns.
#' @export
#'
#' @examples # TODO
get_presence_matrix <- function(species_list, space = NULL, xy=FALSE, empty_sites = FALSE){
  presence_matrix <- construct_community_matrices(
    species_list = species_list,
    space = space,
    xy = xy,
    empty_sites = empty_sites,
    mode = "presence")
  return(presence_matrix)
}

#' Get global mean richness
#' 
#' This is a simple function that computes the mean richness of a given space.
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#'
#' @returns a numeric value of the mean richness.
#' @export
#'
#' @examples #TODO
get_mean_richness <- function(species_list, space){
  return(get_geo_richness(species_list, space) |> mean())
}

#' Gets a matrix of traits present in occupied cells in the space
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#' @param summary if TRUE, will return traits mean and standard deviation. If FALSE, will return traits values. Default is FALSE.
#'
#' @returns a trait matrix with cells as rows and traits as columns.
#' @export
#'
#' @examples # TODO
get_traits_matrix <- function(species_list, space, summary = F) {
  if(summary){
    mtx_list <- lapply(species_list, function(sp){
      sp_mtx <- sp$traits
      
      t_names <- colnames(sp_mtx)
      t_list <- lapply(t_names, function(tn){
        
        traits_summary <- c(mean(sp_mtx[,tn]), sd(sp_mtx[,tn])) |>
          matrix() |>
          t()
        
        colnames(traits_summary) <- paste0(tn,c("_mean","_sd"))
        
        traits_summary
      })
      
      t_mtx <- do.call(cbind, t_list)
      row.names(t_mtx) <- sp$id
      
      t_mtx
    })
    
    trait_mtx <- do.call(rbind, mtx_list)
  } else {
    mtx_list <- lapply(species_list, function(sp){
      trait_mtx <- sp$traits
      site_mtx <- matrix(row.names(trait_mtx))
      colnames(site_mtx) <- "site"
      trait_mtx <- cbind(site_mtx, trait_mtx)
      row.names(trait_mtx) <- rep(sp$id, nrow(trait_mtx))
      trait_mtx
    })
    
    trait_mtx <- do.call(rbind, mtx_list)
  }
  
  return(trait_mtx)
}

#' Gets the prevalence of each species in a given space
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#'
#' @returns a vector containing species prevalence in decimal percentages.
#' @export
#'
#' @examples # TODO
get_species_prevalence <- function(species_list, space){
  browser()
  
  prevalence <- sapply(species_list, function(sp){
    sum(sp$abundance > 0) / nrow(na.omit(space$environment))
  })
  
  names(prevalence) <- sapply(species_list, function(sp){
    sp$id
  })
  
  return(prevalence)
}

#' Gets the extant species in the simulation
#'
#' @param species_list a list of species to include in the calculations.
#'
#' @returns a vector with extant species IDs.
#' @export
#'
#' @examples # TODO
get_extant_species <- function(species_list) {
  extant <- sapply(species_list, \(sp){any(sp$abundance > 0)})
  species_id <- sapply(species_list, \(sp){sp$id})
  
  return(species_id[extant])
}


#' Gets the total abundance per cell in a given space
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#' @param xy if TRUE, cell coorinates are returned as matix columns. Default is FALSE.
#' @param empty_sites if TRUE, cells with no species will be included in the matrix. Default is FALSE.
#'
#' @returns a matrix with cells as rows and abundance as column.
#' @export
#' 
#' @seealso [Based on Thomas Keggin's implementation for gen3sis](https://gitlab.ethz.ch/ele-public/gen3sis_wiki/-/blob/master/tools/keggin/traitDiversity.R)
#'
#' @examples #TODO
get_cell_abundance <- function(species_list, space, xy = F, empty_sites = F) {
  abundance_vector <- sapply(species_list, function(sp){
    sp$abundance
  }) |> unlist()
  
  abundance_vector <- tapply(abundance_vector, names(abundance_vector), sum)
  abundance_matrix <- as.matrix(abundance_vector)
  colnames(abundance_matrix) <- "abundance"
  
  if(empty_sites){
    empty_cells <- setdiff(row.names(space$coordinates), row.names(abundance_matrix))
    empty_mtx <- matrix(0, nrow = length(empty_cells))
    row.names(empty_mtx) <- empty_cells 
    colnames(empty_mtx) <- "abundance"
    
    abundance_matrix <- rbind(abundance_matrix, empty_mtx)
  }
  
  if(xy){
    coords_mtx <- space$coordinates[row.names(abundance_matrix),]
    abundance_matrix <- cbind(coords_mtx, abundance_matrix)
  }
  
  return(abundance_matrix)
}

#' Gets the number of cells each species is present in
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#'
#' @returns a named vector containing species (names) and its range (values). 
#' @export
#'
#' @examples #TODO
get_species_range <- function(species_list, space) {
  pa_mtx <- get_presence_matrix(species_list, space)
  return(colSums(pa_mtx))
}

#' Gets the weighted endemism for each cell in a given space
#'
#' @param species_list a list of species to include in the calculations.
#' @param space the space to calculate over.
#'
#' @returns a named vector with the weighted endemism (values) for each cell (names).
#' @export
#' 
#' @examples #TODO
get_weighted_endemism <- function(species_list, space) {
  richness <- get_geo_richness(species_list, space)
  species_range <- get_species_range(species_list, space)
  
  pa_mtx <- get_presence_matrix(species_list, space, empty_sites = T)
  
  species_present <- apply(pa_mtx, 1, function(cell){
    names(cell)[cell == 1]
  })
  
  total_range <- sapply(species_present, function(cell){
    sum(species_range[cell])
  })
  
  richness <- richness[names(total_range)]
  
  weighted_endemism <- richness / total_range
  weighted_endemism[is.na(weighted_endemism)] <- 0
  
  return(weighted_endemism)
}

#' Gets a subset of the species list with species occurring in the specified cells
#'
#' @param species_list a list of species to include in the calculations.
#' @param cell_vector a vector with cell indexes.
#' @param trim_cells if TRUE, species traits will be trimmed to the specified cells. Default is FALSE. 
#'
#' @returns a list with selected species.
#' @export
#'
#' @examples # TODO
get_species_subset <- function(species_list, cell_vector, trim_cells = FALSE){
  pa_mtx <- get_presence_matrix(species_list)
  pa_mtx <- pa_mtx[cell_vector, , drop = FALSE]
  
  sp_subset <- colnames(pa_mtx)[colSums(pa_mtx) > 0]
  species_subset <- Filter(\(sp) sp$id %in% sp_subset, species_list)
  
  if (trim_cells) {
    species_subset <- lapply(species_subset, function(sp){
      sp$abundance <- sp$abundance[names(sp$abundance) %in% cell_vector]
      sp$traits <- sp$traits[rownames(sp$traits) %in% cell_vector, , drop = FALSE]
      sp
    })
  }
  
  return(species_subset)
}

#' Gets a subset of the space based on specified cells
#'
#' @param space the space to calculate over.
#' @param cell_vector a vector with cell indexes.
#'
#' @returns a gen3sis_space_type object with the specified cells.
#' @export
#' @seealso [Based on Thomas Keggin's implementation for gen3sis](https://gitlab.ethz.ch/ele-public/gen3sis_wiki/-/blob/master/tools/keggin/subsetLandscape.R)
#' @examples #TODO
get_space_subset <- function(space, cell_vector){
  if(length(cell_vector) < 2){
    stop("Must subset at least 2 cells.")
  }
  
  space_subset <- space
  
  # environment
  space_subset$environment <- subset(space$environment,
                                         rownames(space$environment) %in% cell_vector)
  
  # coordinates
  space_subset$coordinates <- subset(space$coordinates,
                                         rownames(space$coordinates) %in% cell_vector)
  
  # extent
  #subset_landscape$extent <- extent(rasterFromXYZ(subset_landscape$coordinates))
  
  extent <- c(xmin = min(space_subset$coordinates[,"x"]),
              xmax = max(space_subset$coordinates[,"x"]),
              ymin = min(space_subset$coordinates[,"y"]),
              ymax = max(space_subset$coordinates[,"y"]))
  
  return(space_subset) 
}


# miscellaneous tools ----

#' Construct a matrix with speciation, extinction and diversification rate over timesteps
#'
#' @param gen3sis_output a simulation output object.
#'
#' @returns a matrix with timesteps as rows and speciation, extinction and diversification rates as columns.
#' @export
#'
#' @examples # TODO
diversification_summary <- function(gen3sis_output){
  extant_lineages <- gen3sis_output$summary$phylo_summary[1:nrow(gen3sis_output$summary$phylo_summary)-1,2] 
  speciation <- gen3sis_output$summary$phylo_summary[2:nrow(gen3sis_output$summary$phylo_summary),3]
  extinction <- gen3sis_output$summary$phylo_summary[2:nrow(gen3sis_output$summary$phylo_summary),4]
  
  speciation_rate <- speciation / extant_lineages
  extinction_rate <- extinction / extant_lineages
  diversification_rate <- speciation_rate - extinction_rate
  
  diverse_df <- data.frame(timestep=names(diversification_rate), DR=diversification_rate, SR=speciation_rate, ER=extinction_rate)
  
  return(diverse_df)  
}

#' Subsets a distance matrix to specified cells
#'
#' @param distance_matrix a local or full distance matrix. Can be either the object or a file path.
#' @param cell_vector a vector with cell indexes.
#'
#' @returns a distance matrix with only the specified cells.
#' @export
#' @seealso [Based on Thomas Keggin's implementation for gen3sis](https://gitlab.ethz.ch/ele-public/gen3sis_wiki/-/blob/master/tools/keggin/distanceSubset.R)
#'
#' @examples # TODO
distance_subset <- function(distance_matrix, cell_vector){
  # load the file if distance_matrix is a path
  if(is.character(distance_matrix) && file.exists(distance_matrix)) {
    distance_matrix <- readRDS(distance_matrix)
  }
  
  # convert cell ids to character to match matrix names
  cell_vector <- as.character(cell_vector)
  
  # subset the matrix
  distance_subset <- distance_matrix[cell_vector,cell_vector]
  
  return(distance_subset)
}