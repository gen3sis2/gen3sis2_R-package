# Copyright (c) 2020, ETH Zurich

#' Checks if the necessary directories exist, and otherwise creates them
#' 
#' @details This function will be called by the simulation, but is made available if the directories should be created
#' manually beforehand, for example to redirect the stdout to a file in the output directory.
#' @param config_file path to the config file, if NA the default config will be used
#' @param input_directory path to input directory, if NA it will be derived from the config file path
#' @param output_directory path to output directory, if NA it will be derived from the config file path
#' @return returns a named list with the paths for the input and output directories
#'
#' @importFrom tools file_path_sans_ext
#' @example inst/examples/prepare_directories_help.R
#' @export
#' 
prepare_directories <- function(config_file = NA,
                                input_directory = NA,
                                output_directory = NA) {
  #no default config, config file must be given
  if(is.na(config_file)[1]) {
    stop("no config file provided!")
  } else if (is(config_file,"gen3sis_config")){
    cat("Config found: using config object \n")
  } else if(!base::file.exists(config_file)){
    stop("Config file does not exist! \n")
  } else {
    cat(paste("config found: ", config_file))
  }

  if(is.na(input_directory)) {
    path <- strsplit(config_file, "/")[[1]]
    path <- paste(path[1:(length(path)-2)], collapse="/")
    input_dir <- sub("[cC]onfig", "input", path)
  } else {
    input_dir <- input_directory
  }
  if(!dir.exists(input_dir)){
    stop(paste("input directory does not exist!:", input_dir))
  }
  cat(paste("space found:", input_directory),"\n")

  if(is.na(output_directory)) {
    if (is(config_file, "gen3sis_config")){
      path <- strsplit(input_dir, "/")[[1]]
      path <- paste(path[1:(length(path)-1)], collapse="/")
      output_dir <- sub("[lL]andscape", "output", path) 
    } else if (is(config_file, "character")) {
      path <- strsplit(config_file, "/")[[1]]
      path <- paste(path[1:(length(path)-1)], collapse="/")
      output_dir <- sub("[cC]onfig", "output", path)
    }
  } else {
    output_dir <- output_directory
  }

  #set and create directories
  #input data
  dir <- list()
  dir$input <- input_dir

  #output folders
  if (is(config_file, "gen3sis_config")) {
    if (!is.character(config_file$gen3sis$general$config_name)) {
      stop(
        "The gen3sis$general$config_name variable needs to be defined ",
        "in the config object. It should be a string that will be used ",
        "as the name of the subdirectory where the simulation outputs ",
        "will be stored."
      )
    }
    config_name <- config_file$gen3sis$general$config_name
  } else {
    config_name <- tools::file_path_sans_ext(basename(config_file))
  }
  dir$output <- file.path(output_dir, config_name)
  dir.create(dir$output, recursive=TRUE, showWarnings = FALSE)
  cat(paste("Output directory is:", dir$output),"\n")

  #dir$output_species <- file.path(dir$output, "species")
  #dir.create(dir$output_species, recursive=TRUE, showWarnings = FALSE)
  #dir$output_spaces <- file.path(dir$output, "spaces")
  #dir.create(dir$output_spaces, recursive=TRUE, showWarnings = FALSE)
  dir$output_plots <- file.path(dir$output, "plots")
  dir.create(dir$output_plots, recursive=TRUE, showWarnings = FALSE)
  #dir$output_val <- file.path(dir$output, "val")
  #dir.create(dir$output_val, recursive=TRUE, showWarnings = FALSE)

  return(dir)
}

#' Creates either an empty configuration or a pre-filled configuration object from a config file
#'
#' @param config_file the path to a valid configuration file. if NA it creates an empty config
#' @param config_name the name of the configuration. if NULL it will be set to a random name, if a empty config is creasted, or use the file name
#' @return list of configuration elements, similar generated from reading a config_file.R. The internal elements 
#' of this list are: "general", "initialization", "dispersal", "speciation", "mutation" and "ecology"
#' @example inst/examples/create_input_config_help.R
#' @export
create_input_config <- function(config_file = NA, config_name = NULL) {
  # Verify config name
  if (!is.null(config_name)) {
    if (length(config_name) != 1) {
      stop(sprintf("config_name must be length 1 or NULL, length %d provided instead.", length(config_name)))
    }
    
    if (!is.character(config_name)) {
      stop(sprintf("config_name must be 'character' or NULL, '%s' object provided instead.", class(config_name)))
    }
  }
  
  new_config <- create_empty_config()
  
  if(is.na(config_file)) {
    # set a name
    if(is.null(config_name)) {
      new_config$gen3sis$general$config_name <- paste0(format(Sys.time(), "%Y-%m-%d"), "-", formatC(sample(1:9999,1), digits=4, flag="0"))
    } else if (is.character(config_name)) {
      new_config$gen3sis$general$config_name <- config_name
    } else {
      stop(paste0("config_name must be 'character' or NULL, '",class(config_name),"' object provided instead."))
    }
    # return empty config
    return(invisible(new_config))
  } else if(!base::file.exists(config_file)){
    # config file does not exist, abort
    stop(paste("config file:", config_file, "does not exist") )
  } else {
    # populate config
    config <- populate_config(new_config, config_file)
    
    # Set defined config_name
    if(!is.null(config_name)){
      config$gen3sis$general$config_name <- config_name    
    }
    
    # Set config_path parameter
    config$directories$config_path <- config_file
    
    return(invisible(config))
  }
}


internal_categories <- c("general",
                         "initialization",
                         "dispersal",
                         "speciation",
                         "mutation",
                         "ecology"
                         )


#' Initializes a config with the values from a provided config file
#'
#' @param config config object to fill
#' @param config_file config file to retrieve settings from
#'
#' @return empty list as in a config object
#' @noRd
populate_config <- function(config, config_file) {
  user_config_env <- new.env()
  
  machine_config <- config_interpreter(config_file)
  
  current_wd <- getwd()
  config_wd <- dirname(normalizePath(config_file))
  setwd(config_wd)
  on.exit(setwd(current_wd), add = TRUE)
   
  eval(machine_config$machine_config, envir = user_config_env)
  
  # source(config_file, chdir=TRUE, local=user_config_env)
  for ( category in internal_categories) {
    config[["gen3sis"]][[category]] <- populate_settings_list(config[["gen3sis"]][[category]], user_config_env)
  }
  
  # Populate config_name variable from file name if it has not been
  # set yet
  if (is.null(config$gen3sis$general$config_name)) {
    config_name <- tools::file_path_sans_ext(basename(config_file))
    config$gen3sis$general$config_name <- config_name
  }
  
  user_settings <- ls(user_config_env)
  presence <- rep(FALSE, length(user_settings))
  for (category in internal_categories){
    presence <- presence | (user_settings %in% names(config[["gen3sis"]][[category]]))
  }
  if(any(!presence)){
    for( i in user_settings[which(!presence)] ) {
      config[["user"]][[i]] <- user_config_env[[i]]
    }
  }
  
  # set config flags
  config$user$needs_scaling <- machine_config$needs_scaling
  
  return(invisible(config))
}

#' Helper function taking on a set of user options for the given category
#'
#' @details This function is a helper function to take on a set of user options for the given category.
#' @param config_list a named list of settings to look for
#' @param user_env an environment containing all the user provided config options
#'
#' @return returns the config list with either the user provided options or the original values intact
#' @noRd
populate_settings_list <- function(config_list, user_env) {
  general_settings <- names(config_list)
  user_settings <- ls(user_env)
  for( setting in user_settings) {
    if ( setting %in% general_settings) {
      config_list[[setting]] <- user_env[[setting]]
    }
  }
  return(invisible(config_list))
}


#' Verifies if all required config fields are provided
#'
#' @param config a config object
#' @return Returns TRUE for a valid config, FALSE otherwise, in which case a list of
#' missing parameters will be printed out as well
#' @seealso \code{\link{create_input_config}}    \code{\link{write_config_skeleton}}   
#' @example inst/examples/verify_config_help.R
#' @export
verify_config <- function(config) {
  missing_settings <- list()
  unset_settings <- list()
  reference <- create_empty_config()
  
  # check if all categories are present
  for(category in internal_categories) {
    presence <- names(reference[["gen3sis"]][[category]]) %in%  names(config[["gen3sis"]][[category]])
    if( !all( presence ) ) {
      setting_name <- list(names(reference[["gen3sis"]][[category]])[!presence])
      names(setting_name) <- category
      missing_settings <- append(missing_settings, setting_name)
    }
  }
  if(length(missing_settings)){
    message_vector <- c()
    for (categ in names(missing_settings)){
      categ_name <- paste0(categ,"\n")
      categ_message <- c(categ_name,paste0("- ",missing_settings[[categ]],"\n"))
      message_vector <- append(message_vector, categ_message)
    }
    
    c("Missing settings in the configuration from the following categories:\n",message_vector) |>
      message()
    return(FALSE)
  }
  
  # check if all required settings are set
  for(category in internal_categories) {
    settings <- names(config[["gen3sis"]][[category]])
    null_settings <- sapply(config[["gen3sis"]][[category]], is.null)
    if( any( as.logical(null_settings) ) ) {
      setting_name <- list(names(null_settings))
      names(setting_name) <- category
      unset_settings <- append(unset_settings, setting_name)
    }
  }
  if(length(unset_settings)) {
    message_vector <- c()
    for (categ in names(unset_settings)){
      categ_name <- paste0(categ,"\n")
      categ_message <- c(categ_name,paste0("- ",unset_settings[[categ]],"\n"))
      message_vector <- append(message_vector, categ_message)
    }
    
    c("These settings must be set in the configuration:\n",message_vector) |>
      message()
    return(FALSE)
  }
  
  # check if time_unit is accepted 
  # time_unit_check() returns a logical when a time unit is provided
  # and a character vector of accepted units when called with NULL.
  tu <- NULL
  if (!is.null(config$user$step_time) && !is.null(config$user$step_time$unit)) {
    tu <- config$user$step_time$unit
  }
  accepted <- time_unit_check(tu)
  # accepted should be a single TRUE value for a valid unit
  if (!is.logical(accepted) || length(accepted) != 1 || is.na(accepted) || !accepted) {
    message(paste0("Time unit '",tu,"' is not accepted. \nAccepted time units are: ", paste(time_unit_check(), collapse = " ")))
    return(FALSE)
  }
  
  return(TRUE)
}


#' Creates an empty config object
#'
#' @details All config fields are created and set to NA if they can be omitted by the user
#' or set to NULL if they must be provided before starting a simulation.
#' @return returns an empty config structure
#' @export
create_empty_config <- function(){
  config <- list()
  config[["gen3sis"]] <- list("general" = list( "random_seed" = NA,
                                              "start_time" = NA,
                                              "end_time" = NA,
                                              "max_number_of_species" = NA,
                                              "max_number_of_coexisting_species" = NA,
                                              "end_of_timestep_observer" = function(...){},
                                              "trait_names" = list(),
                                              "environmental_ranges" = list(),
                                              "verbose" = FALSE,
                                              "config_name" = NULL
                                              ),
                            "initialization" = list( "initial_abundance" = NULL,
                                                     "create_ancestor_species" = NULL
                                                     ),
                            "dispersal" = list( "max_dispersal" = Inf,
                                                "get_dispersal_values" = NULL
                                                 ),
                            "speciation" = list( "divergence_threshold" = NULL,
                                                 "get_divergence_factor" = NULL
                                                 ),
                            "mutation" = list( "apply_evolution" = NULL
                                               ),
                            "ecology" = list("apply_ecology" = NULL
                                             )
                            )
  config[["user"]] <- list()
  config[["directories"]] <- list()
  class(config) <- "gen3sis_config"
  return(config)
}


#' Completes the settings of a given config
#'
#' @details This function conducts the final checks and settings before the simulations runs.
#' currently these include setting the random seed and adding a dispersal trait if not done by the user
#' @param config the current config for this simulation run
#' @noRd
complete_config <- function(config) {
  # random seed
  seed <- config[["gen3sis"]][["general"]][["random_seed"]]
  if( !is.null(seed) && !is.na(seed) ) {
    set.seed(seed)
  }

  # dispersal trait
  config[["gen3sis"]][["general"]][["trait_names"]] <- unique(c(config[["gen3sis"]][["general"]][["trait_names"]], "dispersal"))

  return(invisible(config))
}


#' Writes out a config skeleton
#'
#' @details This function writes out a config skeleton, that is, an empty config file to be edited by the user.
#' @param file_path file path to write the file into
#' @param overwrite overwrite existing file defaults to FALSE
#'
#' @return returns a boolean indicating success or failure
#' @example inst/examples/write_config_skeleton_help.R
#' @export
write_config_skeleton <- function(file_path = "./config_skeleton.R", overwrite = FALSE) {
  # Check arguments
  if(!is.character(file_path) || length(file_path) != 1) {
    stop("file_path must be a character string containing the path to write the skeleton.")
  } else if (!is.logical(overwrite) || length(overwrite) != 1) {
    stop("overwrite must be a logical value.")
  } else if (!tools::file_ext(file_path)=="R") {
    stop("File path must end with .R")
  }
  
  # Writes the file
  if( base::file.exists(file_path) & !overwrite) {
    warning(file_path, " exists, file not written.")
    return(FALSE)
  } else {
    new_file <- file(file_path, open = "w")
    writeLines(skeleton_config(), new_file)
    close(new_file)
    return(TRUE)
  }
}

#' Balances the step time from config and from space
#'
#' This function calculates how many times the events described as time-dependent in the config occur in each space time-step.
#'
#' @param step_time numeric. The numerical baseline of the config step_time, i.e., the x from \code{step_time <- list(x=any_number, unit=accepted_unit)}
#' @param time_unit character. The time unit from the config file. Currently available time units are:
#' \itemize{
#'  \item "a": annum (1 year)
#'  \item "ka": kilo annum (1,000 years)
#'  \item "Ma": mega annum (1,000,000 years)
#'  \item "Ga": giga annum (1,000,000,000 years)
#'  \item "timestep": bypass the entire time-conversion and assumes the config in the same unit as the space 
#' } 
#' 
#' @param space gen3sis_space. The simulation space.
#'
#' @returns For internal use only.
#' @noRd
simulation_timeframe <- function(step_time, time_unit, space = space, needs_scaling) {
  if(time_unit == "timestep") {
    return(1)
  }
  
  space_timestep <- space$duration$by
  space_tunit <- space$duration$unit
  
  scale_time <- (conv_unit(1, from = space_tunit, to = time_unit) * space_timestep)/step_time
  
  if (time_unit != space_tunit){
    message(
      paste0(
        'Space time unit is "',space_tunit,'" but config time unit is "', time_unit,'".\n',
        '1 ',space_tunit,' = ',conv_unit(1, from = space_tunit, to = time_unit),' ',time_unit,'\n',
        'Each space timestep comprises ', space_timestep,' ', space_tunit, '\n',
        'Specified config values will be mutiplied by ', scale_time, 'to cope with space.'
      )
    )  
  }
  
  if (scale_time > 2 | scale_time < 0.1) {
    warning(
      "Significant mismatch between space time and config time. Review recommended."
    )
  }
  
  message(c("The following will be implicitly time-scaled:", paste0("\n- ",names(which(needs_scaling)))))
  
  return(scale_time)
}

#' Reads the user's config file and adapt it to be used inside the simulation  
#'
#' @param config_file character. The path to the config file
#'
#' @returns For internal use only.
#' 
#' @noRd
config_interpreter <- function(config_file) {
  # read and clean
  human_config <- suppressWarnings(readLines(config_file))
  human_config <- human_config[!grepl("^\\s*#", human_config)]
  
  # ensure compatibility
  if(!any(grepl("^step_time", human_config))){
    new_line <- grep("^start_time", human_config)-1
    human_config <- c(human_config[1:new_line-1],"",human_config[new_line:length(human_config)])
    human_config[new_line] <- 'step_time <- list(x=1,unit="timestep")'
  }
  
  # module flags
  flag_names <- c("get_dispersal_values", "get_divergence_factor")
  flag_positions <- sapply(flag_names, function(f){ 
    grep(paste0("^", f), human_config)
    }
  )
  
  # detect scale_time usage per module
  uses_scale_time <- sapply(flag_positions, function(start) {
    depth <- 0
    lines <- integer(0)
    for (i in start:length(human_config)) {
      depth <- depth + stringr::str_count(human_config[i], "\\{") -
        stringr::str_count(human_config[i], "\\}")
      lines <- c(lines, i)
      if (depth == 0 && i > start) {
        break
      }
    }
    any(grepl("\\bscale_time\\b", human_config[lines]))
  })
  
  ### deactivated for now
  # add divergence_threshold 
  # uses_scale_time <- c(
  #   uses_scale_time,
  #   divergence_threshold = any(grepl("\\bscale_time\\b", human_config[grepl("^divergence_threshold", human_config)]))
  # )
  ###
  
  
  needs_scaling <- !uses_scale_time
  
  # adapt scale_time calls
  sim_lines <- grep("\\bscale_time\\b", human_config)
  human_config[sim_lines] <- gsub("\\bscale_time\\b", "config$user$scale_time", human_config[sim_lines])
  
  machine_config <- parse(text = paste(human_config, collapse = "\n"))
  
  return_list <- list(machine_config = machine_config, needs_scaling = needs_scaling)
  
  return(return_list)
}


#' Check if the used time unit is accepted
#'
#' @param time_unit character. The used time unit. If NULL, returns a vector of accepted time units.
#'
#' @returns if time_unit is character, return TRUE or FALSE. If time_unit = NULL, returns a vector of accepted time units. 
#' @export
#'
#' @examples "TODO"
time_unit_check <- function(time_unit=NULL){
  accepted_timeunits <- c("a","ka", "Ma", "Ga","timestep")
  
  if(is.null(time_unit)){
    return(accepted_timeunits)
  } else {
    is.accepted <- time_unit %in% accepted_timeunits
    return(is.accepted) 
  }
}
