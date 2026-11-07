# Copyright (c) 2020, ETH Zurich

#---------------------------------------------------#
##########        Internal functions        #########
#---------------------------------------------------#

#' selects the habitable cells from the input
#' @details a leftover from when the habitable cells were intended to be changed in the fly
#'
#' @param what the input to be subset
#'
#' @return a boolean vector indicating which inputs are habitable
#' @noRd
select_habitable_hab <- function(what) {
  # what should be a string! NA`s are considered unsuitable
  # selected <- eval(parse(text = paste(what, condition, "& !is.na(", what, ")")))
  selected <- !is.na(what)
  return(selected)
}


#' calculate the richness of a list of species over a given space
#'
#' @param species_list a list of species to include in the richness calculations
#' @param space the space to calculate the richness over
#'
#' @return a vector with the richness for every cell in the input space
#' @keywords support
#' @example inst/examples/get_geo_richness_help.R
#' @seealso \code{\link{plot_richness}}
#' @export
get_geo_richness <- function(species_list, space) {
  cell_names <- rownames(space[["coordinates"]])
  presences <- sapply(
    species_list,
    function(sp, cell_names) {
      cell_names %in% names(sp[["abundance"]])
    },
    cell_names
  )
  richness <- rowSums(presences)
  names(richness) <- cell_names
  return(richness)
}


#' calculate the individual average traits for all given species
#' currently deprecated
# @param species_list a list
#'
# @return a matrix filled with average traits vs all species
# @noRd
#get_eco_by_sp <- function(species_list) {
#  averages <- t(sapply(species_list, function(sp) {colMeans(sp[["traits"]])} ))
#  return(invisible(averages))
#}

#' saves the current phylogeny in nex format(?)
#'
#' @param phy the phylogeny up to this point
#' @param label a lable
#' @param output_file the file path and name to store the result
#'
#' @importFrom stringr str_replace str_extract
#' @importFrom utils write.table
#' @noRd
write_nex <- function(phy, label = "sp", output_file) {
  #    phy <- sgen3sis$phy  phy <- duplo  phy <- simples
  val <- dynGet("val")

  #check if we start with more than one ancestor, i.e. more than one root.
  rootphy <- phy$Speciation.Type == "ROOT"

  if (sum(rootphy) > 1) {
    phy$Ancestor[rootphy] <- 0
    phy$Speciation.Type <- as.character(phy$Speciation.Type)
    phy$Speciation.Type[rootphy] <- "COMB"
    addroot <- c(
      "0",
      "0",
      phy$Speciation.Time[1],
      val$config$gen3sis$general$duration$to - 1,
      "ROOT"
    )
    names(addroot) <- colnames(phy)
    phy <- rbind(addroot, phy)
    phy$Ancestor <- as.integer(phy$Ancestor)
    phy$Descendent <- as.integer(phy$Descendent)
    phy[, c("Ancestor", "Descendent")] <- phy[, c("Ancestor", "Descendent")] + 1
    phy$Ancestor <- as.integer(phy$Ancestor)
    phy$Descendent <- as.integer(phy$Descendent)
    phy$Speciation.Time <- as.integer(phy$Speciation.Time)
    phy$Extinction.Time <- as.numeric(phy$Extinction.Time)
    phy$Speciation.Type <- as.factor(phy$Speciation.Type)
  }

  #remove root
  phy_no_root <- phy[-1, , drop = FALSE]

  if (nrow(phy_no_root) == 0) {
    #following TreeSimGM and TreeSim convertion
    if (phy[1, "Extinction.Time"] == val$config$gen3sis$general$duration$to - 1) {
      String_final <- "1" # tree with only root
    } else {
      String_final <- "0" # tree with only root that got extinct
    }
  } else {
    Ancestral <- phy_no_root[, "Ancestor"]
    Derived <- phy_no_root[, "Descendent"]

    #Time calibrated tree
    root <- phy[phy$Speciation.Type == "ROOT", "Speciation.Time"]

    String <- paste0(label, "1:", root)
    Age <- c(root, phy_no_root[, "Speciation.Time"])
    #Age_new<-Age
    #unique(phy$Ancestor)

    Ancestral_age <- phy[unique(phy$Ancestor), "Speciation.Time"]
    names(Ancestral_age) <- phy[!duplicated(phy$Ancestor), "Ancestor"]

    Extinction <- c(0, phy_no_root[, "Extinction.Time"])

    for (i in 1:(max(phy_no_root[, "Descendent"]))) {
      String <- str_replace(
        String,
        paste(
          label,
          Ancestral[i],
          ":",
          Ancestral_age[toString(Ancestral[i])],
          sep = ""
        ),
        paste(
          "(",
          label,
          Ancestral[i],
          ":",
          Age[i + 1],
          ",",
          label,
          Derived[i],
          ":",
          Age[i + 1],
          "):",
          Ancestral_age[toString(Ancestral[i])] - Age[i + 1],
          sep = ""
        )
      )

      Ancestral_age[toString(Ancestral[i])] <- Age[i + 1]
      # print("-------")
      # print(String)
    }
    #adding ext times!
    extsps <- phy[phy$Extinction.Time > 0, c("Descendent", "Extinction.Time")]
    if (nrow(extsps) > 0) {
      for (i in 1:nrow(extsps)) {
        spi <- paste0(label, extsps$Descendent[i], ":")
        # print("-------")
        # print(spi)
        splited <- strsplit(String, spi)[[1]]
        oldnumb <- str_extract(splited[2], "\\-*\\d+\\.*\\d*")
        newnumb <- as.numeric(oldnumb) - extsps$Extinction.Time[i]
        #newnumb <- extsps$Extinction.Time[i]
        splited[2] <- sub(oldnumb, newnumb, splited[2])
        String <- paste0(splited[1], spi, splited[2])
      }
    }

    String_final <- paste("Tree tree = ", String, ";", sep = "")
    String_final <- (paste(
      "#NEXUS",
      "begin trees;",
      String_final,
      "end;",
      "[!Tree generated with the gen3sis R package, following convention of TreeSim and TreeSimGM r-packages]",
      sep = "\n"
    ))
  } #end test if there is a tree

  write.table(
    String_final,
    output_file,
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
  )

  #read phylo
  # t <- read.nexus(file.path(output_location, "phy.nex"))
  # plot(t)
}

#' Convert time units
#'
#' @param x numeric. The numerical value in "from" unit
#' @param from character. The unit to convert from
#' @param to character. The unit to convert to
#'
#' @returns The numerical values in "to" unit
#' @noRd
conv_unit <- function(x, from, to) {
  if (from == "timestep" || to == "timestep") {
    return(x)
  }
  exponents <- c(yr = 0, kyr = 3, Myr = 6, Gyr = 9)
  factor <- 10^(exponents[from] - exponents[to])
  return(x * factor[[1]])
}

#' Check if time matches between space and config
#'
#' @param config_duration numeric. The numerical value in "from" unit
#' @param space_duration character. The unit to convert from
#'
#' @returns NULL
#' @noRd
check_time_match <- function(config_duration, space_duration){
  if(config_duration$unit != "timestep"){
    if(config_duration$unit != space_duration$unit) {
      text_warn <- paste0(
        "--- TIME-STEP MISMATCH ---\n  ",
          "Config's time-steps are set as ", 
          config_duration$by, " ",
          config_duration$unit, ", ",
          "but space's time-steps are set as ",
          space_duration$by, " ",
          space_duration$unit, ".\n  ",
          "Did you consider time-scaling in your config?\n  ",
          "Read more about time-scaling in the respective vignette."
        )
      warning(text_warn)
      message(text_warn)
    }

    time_proportion <- config_duration$by/conv_unit(space_duration$by, space_duration$unit, config_duration$unit)

    if(time_proportion != 1){
      text_warn <- paste0(
          "--- TIME-STEP MISMATCH ---\n  ",
          "Config's time-steps are ",
          time_proportion, " ",
          "times space's time-steps.\n  ",
          "Did you consider time-scaling in your config?\n  ",
          "Read more about time-scaling in the respective vignette."
        )
      message(text_warn)
      warning(text_warn)
    }
  } else {
    text_warn <- paste0(
      "  Config time unit is set to 'timestep'.\n  ",
        "The simulation will fully assume spaces duration.\n  ",
        "Read more about time-scaling in the respective vignette."
      )
    warning(text_warn)
    message(text_warn)
  }
}


#' Order elements using a longest processing time first algorithm
#' 
#' @details assigns each element to a worker to balance the load.
#' future.apply uses parallel::splitIndices() to assign the work to the workers,
#' padding is added to avoid uneven distribution.
#'
#' @param cost numeric vector of estimated work.
#'
#' @returns Ordering attribute for future.scheduling.
#' NULL if there are less or equal elements as workers
#' @noRd
order_lpt <- function(cost) {
  workers <- future::nbrOfWorkers()
  
  # If all species fit into workers, pass them as is
  if (length(cost) <= workers) {
    return(NULL)
  }
  
  assigned_worker <- integer(length(cost))
  worker_load <- numeric(workers) # sum of work assigned to each worker
  
  # Assign work
  for (i in order(cost, decreasing = TRUE, method = "radix")) {
    # Select worker with smallest load
    worker <- which.min(worker_load)
    
    # Add cost to worker
    worker_load[worker] <- worker_load[worker] + cost[i]
    
    # Assign work to selected worker
    assigned_worker[i] <- worker
  }
  
  # Add padding to balance load
  jobs_per_worker <- tabulate(assigned_worker, workers) # Count jobs per worker
  necessary_number_of_jobs <- workers * max(jobs_per_worker)
  
  # Grow chunk sizes so it matches what future.apply will cut
  while (any(lengths(parallel::splitIndices(necessary_number_of_jobs, workers)) < jobs_per_worker)) {
    necessary_number_of_jobs <- necessary_number_of_jobs + 1
  }
  
  # Fill chunks with padding
  padding <- lengths(parallel::splitIndices(necessary_number_of_jobs, workers)) - jobs_per_worker
  assigned_worker <- c(assigned_worker, rep(seq_len(workers), padding))
  
  return(order(assigned_worker))
}


# Environment for the shared distance matrix
shared_data <- new.env(parent = emptyenv())


#' Share distance matrix across workers
#' 
#' @details with profiling=TRUE, uses a backingfile to store the matrix in a file
#' because otherwise it can lead to errors on certain operating systems
#' 
#' @param distance_matrix matrix to be shared.
#' @param profiling TRUE if the simulation is profiled, FALSE otherwise.
#'
#' @return the descriptor of the shared matrix
#' @noRd
share_distance <- function(distance_matrix, profiling = FALSE) {
    if (profiling) {
      share_file <- basename(tempfile("shared_distance_", fileext = ".bin"))
      x <- bigmemory::as.big.matrix(
        distance_matrix,
        backingfile = share_file, # Without backingfile, Rprof profiling can result in an error
        backingpath = tempdir(),
        descriptorfile = paste0(share_file, ".desc") # Prevents warning message
      )
      return (bigmemory::describe(x))
    } 

    # Save to global state, otherwise reference is deleted after return
    shared_data$distance <- bigmemory::as.big.matrix(distance_matrix)
    return(bigmemory::describe(shared_data$distance))  
}


#' Set the plan for the given number of cores
#'
#' @param cores integer value or NULL, number of cores to be used
#' If cores=1, use sequential plan.
#' If cores=x with x greater than 1, use multisession with x cores.
#' If cores=NULL, use all but one core.
#' @param verbose integer value.
#' If verbose=0, no printed statement.
#' If verbose=1 (default), print selected plan.
#' @noRd
define_cores <- function(cores, verbose = 1) {
  available_cores <- parallel::detectCores()
  
  # Select amount of cores used for run
  if (is.null(cores)) {
    cores <- max(1, (available_cores - 1))
    if (verbose >= 1) {
      cat("No cores specified: ", available_cores, " available, using ", cores, "\n")
    }
  } else {
    # Ensure input is a positive integer
    if (!is.numeric(cores) || cores %% 1 != 0 || as.integer(cores) <= 0) {
      stop("Cores must be a positive integer or NULL, aborting simulation.")
    }
    # Use all cores if input exceeds available cores
    cores <- min(cores, available_cores)
    if (verbose >= 1) {
      cat("Using ", cores, " cores", "\n")
    }
  }
  
  # Select plan
  if (cores == 1) {
    future::plan(future::sequential)
    used_plan <- "sequential"
  } 
  else {
    future::plan(future::multisession, workers = cores)
    used_plan <- "multisession"
  }
  
  if (verbose >= 1) cat("Running: ", used_plan, "\n")
}


#' Helper function to skip padding
#'
#' @param x element of X, NULL if padding
#' @param f The function applied to x
#' @param ... additional arguments
#'
#' @returns NULL if padding, otherwise the result of f(x, ...)
#' @noRd
skip_padding <- function(x, f, ...) {
  if (is.null(x)) {
    return(NULL)
  }
  return(f(x, ...))
}


#' Apply a function to each element in parallel or sequentially
#' 
#' @details calls future_lapply() using the pre-defined plan.
#' sequential = TRUE sets the plan to sequential for this call, keeping the workers alive. 
#' 
#' @param X list or vector of elements
#' @param FUN function applied to each X
#' @param ... additional arguments to be passed to FUN
#' @param ordering ordering calculated from order_lpt or NULL
#' @param sequential TRUE to run sequentially
#'
#' @return a list of the results of function FUN on inputs X
#' @noRd
dynamic_lapply <- function(X, FUN, ..., ordering = NULL, sequential = FALSE) {
  # Set plan to sequential
  if (sequential && future::nbrOfWorkers() > 1) {
    parallel_plan <- future::plan() # Save current plan
    future::plan(future::sequential, .cleanup = FALSE)
    on.exit(future::plan(parallel_plan, .cleanup = FALSE), add = TRUE)
  }
  
  input_length <- length(X)
  
  # Add padding to the end of the input
  if (length(ordering) > input_length) {
    X <- c(X, vector("list", length(ordering) - input_length))
  }
  
  results <- future.apply::future_lapply(
    X, skip_padding, FUN, ...,
    future.seed = TRUE,
    future.globals = FALSE,
    future.scheduling = structure(1, ordering = ordering)
  )
  
  # Drop the padding
  return(results[seq_len(input_length)])
}
