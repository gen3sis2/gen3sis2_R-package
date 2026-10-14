
#' TODO docstring
# TODO remove log_msg, only for testing, use cat with verbose setting instead
define_cores <- function(cores = NULL,
                         log_msg = NULL,
                         verbose = 1) {
    available_cores <- parallel::detectCores()

    # Select amount of cores used for run
    if (is.null(cores)) {
        cores <- max(1, (available_cores - 1))
        if (verbose >= 1) {
            log_msg("No cores specified: ", available_cores, " available, using ", cores)
        }
    } else {
        # Ensure input is a positive integer
        if (!is.numeric(cores) || cores %% 1 != 0 || as.integer(cores) <= 0) {
            stop("Cores must be a positive integer or NULL, aborting simulation.")
        }
        # Use all cores if input exceeds available cores
        cores <- min(cores, available_cores)
        if (verbose >= 1) {
            log_msg("Using ", cores, " cores")
        }
    }

    # Select pararellization method
    if (cores == 1) {
        future::plan(future::sequential)
        used_plan <- "sequential"
    } 
    # TODO mutlisession only for now
    #else if (parallelly::supportsMulticore()) { # Forking is not supported on Windows
    #    future::plan(future::multicore, workers = cores)
    #    used_plan <- "multicore"
    #} 
    else {
        future::plan(future::multisession, workers = cores)
        used_plan <- "multisession"
    }

    if (verbose >= 1) log_msg("Running: ", used_plan) # cat("Running: ", used_plan, "\n")
}


# TODO for simplicity only, not sure if it will make final version
dynamic_lapply <- function(X, FUN, ...) {
    future.apply::future_lapply(
        X, FUN, ...,
        future.seed = TRUE,
        future.globals = FALSE
    )
}
