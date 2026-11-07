# Functions related to performing granularity control in parallel simulations


#' Provides the input data used for the configuration of constants, not part of a simulation.
#'
#' @details a grid with the parameters of the SouthAmerica example, and species with different ranges from a random center cell
#'
#' @param side number of cells per side of the grid
#' @param species number of species
#'
#' @return list containing config and data
#' @noRd
default_input <- function(side = 50, species = 200) {
  set.seed(1) # ensures the created default values are always the same

  # Use config of SouthAmerica example provided in the package
  file_location <- system.file("extdata", "SouthAmerica", package = "gen3sis2")
  config <- create_input_config(file.path(file_location, "config", "config_southamerica.R"))

  # Use parameters of SouthAmerica example provided in the package
  config$directories$input <- file.path(file_location, "space")

  val <- setup_inputs(config, list(), list(ti = 0)) # Use the state of the last timestep (ti = 0)
  val <- setup_space(val$config, val$data, val$vars)
  state_of_last_timestep <- val$data$space$environment

  # Create sample space 
  grid <- terra::rast(
    nrows = side, 
    ncols = side, 
    xmin = 0, 
    xmax = 2 * side, 
    ymin = -side, 
    ymax = side
  )
  drawn <- sample(nrow(state_of_last_timestep), terra::ncell(grid), replace = TRUE)
  raster_list <- lapply(
    colnames(state_of_last_timestep), 
    function(i) {
      layer <- terra::setValues(grid, state_of_last_timestep[drawn, i])
      c(layer, layer) # set two identical timesteps because setup_inputs() cannot read a space with just one timestep
    }
  )
  names(raster_list) <- colnames(state_of_last_timestep)

  cost_function <- function(source, dest) {
    return(1 / 1000)
  }

  output_directory <- file.path(tempdir(), "calibration_space")
  create_spaces_raster(
    raster_list = raster_list,
    cost_function = cost_function,
    output_directory = output_directory,
    directions = 8,
    duration = list(from = -1, to = 0, by = 1, unit = "Ma"),
    full_dists = TRUE,
    overwrite_output = TRUE,
    crs = "+proj=longlat +datum=WGS84 +no_defs",
    geodynamic = FALSE
  )

  config$directories$input <- output_directory
  val <- setup_inputs(config, list(), list(ti = 0))
  val <- setup_space(val$config, val$data, val$vars)
  val <- setup_distance_matrix(val$config, val$data, val$vars)

  unlink(output_directory, recursive = TRUE) # Remove the directory

  # Create species for different sizes
  range_sizes <- rep(c(1, 10, 100, 1000), length.out = species)
  all_species <- lapply(range_sizes, function(size) {
    # cells nearest to a random center
    range <- names(sort(val$data$distance_matrix[sample(nrow(val$data$space$coordinates), 1), ])[seq_len(size)]) 
    new_species <- create_species(range, config)
    new_species$traits[, "temp"] <- val$data$space$environment[range, "temp"]
    new_species$traits[, "dispersal"] <- 1
    new_species
  })

  list(
    config = config, 
    data = list(
      space = val$data$space, 
      distance_matrix = val$data$distance_matrix, 
      all_species = all_species
    )
  )
}

#' Adjust loop call for calibration
#'
#' @param loop "dispersal", "evolution" or "ecology"
#' @param all_species list of species
#' @param input the input from default_input()
#' @param shared TRUE if data should be shared, FALSE otherwise
#' @param empty TRUE to use a function without work, for measuring overhead
#'
#' @return list of parameters and functions to run a loop
#' @noRd
loop_call <- function(loop, all_species, input, shared = FALSE, empty = FALSE) {
  data <- input$data
  config <- input$config

  if (loop == "ecology") {
    all_cells <- rownames(data$space$environment)
    all_species_presence <- do.call(
      cbind,
      lapply(all_species, FUN = function(sp) {
        all_cells %in% names(sp$abundance)
      })
    )
    rownames(all_species_presence) <- all_cells
    # take ids that have at least one species...
    occupied_cells <- rownames(all_species_presence)[
      rowSums(all_species_presence) > 0
    ]
    number_of_species <- rowSums(all_species_presence)

    if (shared) {
      env <- mori::share(data$space[["environment"]])
      presence <- mori::share(all_species_presence)
      species <- mori::share(all_species)
    } else {
      env <- data$space[["environment"]]
      presence <- all_species_presence
      species <- all_species
    }

    return(list(
      X = occupied_cells,
      FUN = if (empty) empty_cell else cell_ecology,
      arguments = list(env, presence, species, config),
      cost = number_of_species[occupied_cells]
    ))
  }

  if (loop == "dispersal") {
    cost <- estimate_cost(all_species, nrow(data$space$coordinates))
    used_function <- if (shared) disperse_duplicate else disperse
  } 
  
  if (loop == "evolution") {
    cost <- lengths(lapply(all_species, "[[", "abundance"))^2
    used_function <- if (shared) evolve_duplicate else evolve
  }

  if (empty) {
    used_function <- if (shared) empty_species_duplicate else empty_species
  }

  if (shared) {
    species <- mori::share(all_species)
    space <- mori::share(data$space)
    distance_matrix <- data$shared_distance
  } else {
    species <- all_species
    space <- data$space
    distance_matrix <- data$distance_matrix
  }

  return(list(
    X = species, 
    FUN = used_function, 
    arguments = list(space, distance_matrix, config),
    cost = cost
  ))
}


#' Function without work for calibration
#'
#' @param species the species
#' @param space the space of the current time-step
#' @param distance_matrix the distance_matrix
#' @param config the current config for this simulation run
#'
#' @return the unchanged species
#' @noRd
empty_species <- function(species, space, distance_matrix, config) {
  return(species)
}

#' Function without work for calibration
#'
#' @param species the shared species
#' @param space the shared space of the current time-step
#' @param distance_matrix the descriptor of the shared distance matrix
#' @param config the current config for this simulation run
#'
#' @return a copy of the species
#' @noRd
empty_species_duplicate <- function(species, space, distance_matrix, config) {
  return(rlang::duplicate(species, shallow = FALSE))
}



#' Function without work for calibration
#'
#' @param cell the cell
#' @param environment the environmental values
#' @param all_species_presence matrix of species presence
#' @param species unused
#' @param config the config of the simulation
#'
#' @return abundance
#' @noRd
empty_cell <- function(cell, environment, all_species_presence, species, config) {
  coo_sp <- which(all_species_presence[cell, ])
  abundance <- numeric(length(coo_sp))
  names(abundance) <- coo_sp
  return(abundance)
}


#' Calculates estimations and start values used for granularity control
#'
#' @details Measures the constants used for deciding if dispersal, evolution and ecology
#' should be run sequentially or in parallel.
#' The results are saved and used instead of the defaults by all later simulations on this machine.
#' 1. sigma:      seconds per cost unit, unique per loop, adjusted dynamically during the simulation on sequential runs.
#' 2. c_sh:       overhead introduced by sharing the distance matrix and garbage collection.
#' 3. c_parallel: overhead introduced by running in parallel, per loop, per number of workers.
#' The constants are saved to \code{granularity_constants.rds} in \code{tools::R_user_dir("gen3sis2", "data")}.
#' Delete the file to use the defaults again.
#'
#' @param workers numeric vector of worker counts to calibrate for, e.g. \code{c(4, 8)}.
#' If NULL (default), calibrates for the powers of 2 starting from 2 up to all available cores
#' and for all but one core.
#' @param iterations number of repetitions of every measurement
#'
#' @return the calibrated constants
#' @examples
#' \dontrun{
#' calibrate_granularity(workers = c(4, 8), iterations = 6)
#' }
#' @export
calibrate_granularity <- function(workers = NULL, iterations = 6) {
  # ---- Setup -----

  # Ensure iterations is a valid input to avoid creating wrong constants
  if (!is.numeric(iterations) || length(iterations) != 1 || iterations %% 1 != 0 || iterations < 1) {
    stop("Iterations must be a positive integer")
  }

  available_workers <- parallel::detectCores()
  if (available_workers < 2) {
    stop("Only one core detected, therefore only sequential execution is supported on this machine")
  }
  on.exit(future::plan(future::sequential), add = TRUE) # Close sessions after calibration

  if (is.null(workers)) {
    workers <- c()
    add_step <- 2
    while (add_step <= available_workers) {
      workers <- c(workers, add_step)
      add_step <- add_step * 2
    }

    # Add (maximum - 1) if it is not a power of 2
    if (workers[length(workers)] != available_workers & workers[length(workers)] != available_workers - 1) {
      workers <- c(workers, available_workers - 1)
    }
  } else {
    # Clean the users input
    workers <- unique(workers)
    workers <- workers[workers >= 2]
    workers <- workers[workers <= available_workers]
    if (length(workers) == 0) {
      stop("Invalid workers specified")
    }
  }

  # ---- Input ----
  input <- default_input()
  loops <- c("dispersal", "evolution", "ecology")
  sizes <- c(5, 10, 25, 50, 100, 200)

  # Random subsets of species, one per size and repetition
  subsets <- replicate(
    iterations, 
    lapply(
      sizes, 
      function(size) sample(input$data$all_species, size)
    ), 
    simplify = FALSE
  )

  runs <- expand.grid(loop = loops, size = seq_along(sizes), stringsAsFactors = FALSE)
  rows <- list()


  # ---- 1. sigma ----
  for (r in seq_len(iterations)) {
    for (i in sample(nrow(runs))) {
      loop <- loop_call(runs$loop[i], subsets[[r]][[runs$size[i]]], input)
      gc()
      # Time sequential execution
      time <- system.time(
        do.call(
          dynamic_lapply,
          c(
            list(loop$X, loop$FUN), 
            loop$arguments, 
            list(sequential = TRUE)
          )
        )
      )[["elapsed"]]

      rows[[length(rows) + 1]] <- data.frame(
        loop = runs$loop[i],
        species = sizes[runs$size[i]],
        iteration = r,
        time = time,
        cost = sum(loop$cost)
      )
    }
  }

  # sigma = (sum of time) / (sum of cost) for each loop
  measurements <- do.call(rbind, rows)

  sigma <- sapply(loops, function(loop) {
    sum(measurements$time[measurements$loop == loop]) / sum(measurements$cost[measurements$loop == loop])
  })


  # ---- 2. c_sh ----
  sharing <- list()
  for (r in seq_len(iterations)) {
    gc()
    # Time sharing of distance matrix
    share_time <- system.time(share_distance(input$data$distance_matrix))[["elapsed"]]
    # Time garbage collection
    gc_time <- system.time(gc())[["elapsed"]]

    sharing[[length(sharing) + 1]] <- data.frame(
      iteration = r, 
      share = share_time, 
      gc = gc_time
    )
  }
  sharing <- do.call(rbind, sharing)
  # Use median
  c_sh <- stats::median(sharing$share + sharing$gc)

  # ---- 3. c_parallel ----
  parallel <- list()
  input$data$shared_distance <- share_distance(input$data$distance_matrix)
  on.exit(shared_data$distance <- NULL, add = TRUE)

  for (p in workers) {
    future::plan(future::multisession, workers = p)

    # Warm-up call to load gen3sis2 into the sessions, which is only done once per simulation
    future.apply::future_lapply(
      rep("gen3sis2", future::nbrOfWorkers()),
      requireNamespace, 
      quietly=TRUE, 
      future.seed=NULL 
    )

    timed <- list()
    for (r in seq_len(iterations)) {
      for (i in sample(nrow(runs))) {
        gc()
        # Time to access function in sequential
        sequential_time <- system.time({
          loop <- loop_call(runs$loop[i], subsets[[r]][[runs$size[i]]], input, empty = TRUE)
          do.call(
            dynamic_lapply,
            c(
              list(loop$X, loop$FUN),
              loop$arguments,
              list(sequential = TRUE)
            )
          )
        })[["elapsed"]]
        gc()

        # Time to access function in parallel
        parallel_time <- system.time({
          loop <- loop_call(runs$loop[i], subsets[[r]][[runs$size[i]]], input, shared = TRUE, empty = TRUE)
          do.call(
            dynamic_lapply,
            c(
              list(loop$X, loop$FUN),
              loop$arguments,
              list(ordering = order_lpt(loop$cost))
            )
          )
        })[["elapsed"]]

        timed[[length(timed) + 1]] <- data.frame(
          workers = p,
          loop = runs$loop[i],
          species = sizes[runs$size[i]],
          iteration = r,
          overhead = parallel_time - sequential_time
        )
      }
    }
    timed <- do.call(rbind, timed)

    # c_parallel = mean overhead per worker count
    for (loop_name in loops) {
      measured <- timed[timed$loop == loop_name, ]

      c_parallel <- mean(measured$overhead)

      parallel[[length(parallel) + 1]] <- data.frame(
        workers = p, 
        loop = loop_name, 
        c_parallel = c_parallel
      )
    }
  }
  parallel <- do.call(rbind, parallel)

  # ---- Save ----
  calibration <- list(
    sigma = sigma,
    c_sh = c_sh,
    # Rows in the same order as defaults
    overhead = parallel[order(parallel$workers, match(parallel$loop, loops)), ]
  )

  # (https://stat.ethz.ch/R-manual/R-devel/library/tools/html/userdir.html)
  file <- file.path(tools::R_user_dir("gen3sis2", which = "data"), "granularity_constants.rds")
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  saveRDS(calibration, file)

  message("Calibration done. Constants were saved at ", file, " and will be used on all simulations on this machine.")
  return(calibration)
}


#' Update the time per cost unit of a sequential call
#'
#' @details sigma is the weighted average of the time per cost unit
#'
#' @param sigma current time per cost unit of a loop
#' @param time time of sequential execution
#' @param cost estimated cost
#' @param alpha weight of measurement
#' @param t_min lower limit to not be considered noise
#'
#' @return the adjusted sigma
#' @noRd
adjust_sigma <- function(sigma, time, cost, alpha = 0.3, t_min = 0.01) {
  if (time < t_min || sum(cost) == 0) {
    return(sigma)
  }
  return(sigma + alpha * (time / sum(cost) - sigma))
}


#' Update the error of the estimated parallel time of a parallel call
#'
#' @details delta_p is the weighted average of the errors of earlier parallel calls
#'
#' @param loop loop that was run in parallel
#' @param delta_p current delta_p
#' @param time time of parallel execution
#' @param cost estimated cost
#' @param sigma current sigma value
#' @param alpha weight of measurement
#'
#' @return the adjusted delta_p
#' @noRd
adjust_delta_p <- function(loop, delta_p, time, cost, sigma, alpha = 0.3) {
  estimated_time <- estimate_parallel_time(loop, cost, sigma)
  return(delta_p + alpha * (time - estimated_time - delta_p))
}

#' Estimates the time of a parallel call
#'
#' @param loop "dispersal", "evolution", "ecology"
#' @param cost estimated cost
#' @param sigma time per cost unit
#'
#' @return Estimated time of a parallel call
#' @noRd
estimate_parallel_time <- function(loop, cost, sigma) {
  workers <- future::nbrOfWorkers()
  constants <- granularity_constants(loop, workers)

  # Calculate T_p
  m <- ceiling(length(cost) / workers)
  # Minimum work of the busiest worker
  phi_c <- max(                       
      sum(cost) / workers,            # evenly spread work
      max(cost),                      # largest element
      sum(sort(cost)[seq_len(m)])     # least amount per worker
  )
  C <- sigma * phi_c

  return(constants$c_parallel + C)
}


#' Decide if a call should be executed sequentially or in parallel
#'
#' @details compares the estimated sequential time with the estimated parallel time
#'
#' @param loop "dispersal", "evolution", "ecology"
#' @param cost estimated cost
#' @param sigma time per cost unit
#' @param delta_sh TRUE if the distance matrix of this time step has not been shared yet, FALSE otherwise
#' @param delta_p error of the estimated parallel time
#'
#' @return TRUE to run sequentially, FALSE otherwise
#' @noRd
decide_execution <- function(loop, cost, sigma, delta_sh, delta_p = 0) {
  if (length(cost) == 0) {
      return(TRUE)
  }

  workers <- future::nbrOfWorkers()
  constants <- granularity_constants(loop, workers)

  # Calculate T_s
  T_s <- sigma * sum(cost)

  # Calculate T_p
  parallel_time <- estimate_parallel_time(loop, cost, sigma)
  T_p <- parallel_time + delta_p + delta_sh * constants$c_sh

  # Decision
  return(T_s <= T_p)
}

#' Pre-defined constants for the granularity decision
#'
#' @details the defaults are measurements from a linux server
#'
#' @param loop "dispersal", "evolution", "ecology"
#' @param workers number of workers used in the run
#'
#' @return list of constants
#' @noRd
granularity_constants <- function(loop, workers) {
  # Default values (calibrated on linux 04.11.2026)
  calibration <- list(
    sigma = c(dispersal = 7.797e-08, evolution = 7.473e-08, ecology = 0.0001042),
    c_sh = 0.6025,
    overhead = data.frame(
      workers = rep(c(2, 4, 6, 8, 12, 16, 32, 55, 63), each = 3), # repeated once per loop
      loop = rep(c("dispersal", "evolution", "ecology"), times = 9), # repeated once per worker
      c_parallel = c(0.08264, 0.08533, 0.07411, 0.09, 0.07853, 0.05417, 0.09717, 0.09958, 0.03786, 0.1011, 0.1034, 0.04594, 0.1064, 0.1056, 0.04114, 0.1168, 0.1159, 0.04983, 0.161, 0.1614, 0.1164, 0.2179, 0.2228, 0.2026, 0.2325, 0.2391, 0.2416)
    )
  )

  file <- file.path(tools::R_user_dir("gen3sis2", which = "data"), "granularity_constants.rds")
  if (file.exists(file)) {
    calibration  <- readRDS(file)
  }

  overhead <- calibration$overhead[calibration$overhead$loop == loop, ]

  # If worker count is not in the list, use the constants of the closest worker count
  worker_constants <- overhead[which.min(abs(overhead$workers - workers)), ]

  return(list(
    sigma = calibration$sigma[[loop]],
    c_parallel = worker_constants$c_parallel,
    c_sh = calibration$c_sh
  ))
}