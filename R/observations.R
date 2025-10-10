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

##### TO CLEAN AND ADD AS SUPPORT

make p/a matrices if necessary

if(!file.exists(file.path(config$directories$output, "abs"))){dir.create(file.path(config$directories$output, "abs"))}

# site names

all_sites <- rownames(data$space$coordinates)

# get 0 for absence and 1 for presence in each grid site

all_species_abundance <- do.call( cbind, lapply(data$all_species, FUN = function(x) {ifelse(all_sites %in% names(x$abundance), x$abundance, NA)}))

# colnames are species names

colnames(all_species_abundance ) <- unlist(lapply(data$all_species, function(x){x$id}))

# column bind with x/y coordinates

abundance_matrix <- cbind(data$space$coordinates, all_species_abundance)

abundance_matrix <- abundance_matrix[order(abundance_matrix[,"x"]),]

abundance_matrix <- abundance_matrix[abundance_matrix[, "x"]<=-20, ]

# Select rows where all values are NA

rows_with_all_NA <- apply(abundance_matrix[,-c(1,2)], 1, function(x) all(is.na(x)))

# Subset the data frame to keep only those rows

abundance_matrix <- abundance_matrix[!rows_with_all_NA, ]

#abundance_matrix <- cbind(unique_id=1:nrow(abundance_matrix), abundance_matrix)

ncols <- ncol(abundance_matrix)

df <- as.data.frame(abundance_matrix)

abundance_long <- reshape(as.data.frame(df),

varying = list(names(df)[3:ncols]), # Columns to melt into long format

v.names = "N_density", # Name of the variable that holds values

timevar = "sp_id", # The new variable that will hold the column names (species IDs in this case)

times = names(df)[3:ncols], # The original column names to use as species IDs

idvar = c("x", "y"), # ID variables

direction = "long")

abundance_long <- abundance_long[\

Preview unavailable
(abundance_long$N_density),]

#if x>=15 then set continent to North America else South America

abundance_long$continent <- ifelse(abundance_long$x>=15, "North America", "South America")

abundance_long$sim_id <- basename(config$directories$output)

abundance_long$time_kya <- vars$ti*10000 # scalling 10Ma to kya.

new_cols <- config$user$comb_vector

abundance_long <- do.call(cbind, c(abundance_long, new_cols))

saveRDS(abundance_long, file=file.path(config$directories$output,"abs",  paste0("abd_Saupe_t_",vars$ti, ".rds")))

if(!file.exists(file.path(config$directories$output, "mean_traits_sp"))){dir.create(file.path(config$directories$output, "mean_traits_sp"))}

saveRDS(data$eco_by_sp, file=file.path(config$directories$output,"mean_traits_sp",  paste0("mean_trs_t_",vars$ti, ".rds")))
