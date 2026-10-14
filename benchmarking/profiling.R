# This file only serves as a helper for testing and is irrelevant for the actual implementation
# should be removed before merging


# #----------------------------------------#
# #####           Setup                #####
# #----------------------------------------#
# preclean: necessary to force a clean build
# without-keep.source: ensure future workers start efficently
install.packages(".", repos = NULL, type = "source", INSTALL_opts = c("--preclean", "--without-keep.source"))
library(gen3sis2)
source(file.path("implementations", "dynamic_lapply.R"))

# Added to description
#library(rlang)
#library(bigmemory)
#library(mori)

library(bench)
Sys.setenv(TZ = "Europe/Berlin")

# ---- Log level -------
#' 0: write logs to log file only
#' 1: write to log file and print to console
LOG_LEVEL <- 0

# ---- Parameters ------------
SPACE_RASTER <- file.path("benchmarking", "spaces", "global_2deg")
CONFIG_DIR <- file.path("benchmarking", "configs")

# Configs that should be analyzed in this run
CONFIGS <- c(
    "config_globe_2deg"
)

#' Interval of analysis
SAMPLE_INTERVAL <- 0.1

# Cores to benchmark on
# First entry is the baseline for the speedup
CORES <- c(
    1,
    2,
    4,
    8,
    16,
    32,
    64
)


run_id <- format(Sys.time(), "Run_%Y-%m-%d_%H-%M")
out <- file.path("results", run_id)
dir.create(out, recursive = TRUE, showWarnings = FALSE)


# #----------------------------------------#
# #####            Profiling           #####
# #----------------------------------------#

# ----- Logging ----------------
log_file <- file.path(out, "log.txt")

log_msg <- function(...) {
    msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", ...)
    cat(msg, "\n", file = log_file, append = TRUE)
    if (LOG_LEVEL == 1) {
        cat(msg, "\n")
        flush.console()
    }
}

# ---- Validate configs -------
for (config in CONFIGS) {
    config_path <- file.path(CONFIG_DIR, paste0(config, ".R"))
    if (!file.exists(config_path)) {
        log_msg("Config not found: ", config_path)
        stop("Config not found: ", config_path)
    }
    input_config <- create_input_config(config_path)
    if (!verify_config(input_config)) {
        log_msg("Config not valid: ", config_path)
        stop("Ivalid config: ", input_config)
    }
}


# --- Profiling run ------
run_profiling <- function(config) {
    config_path <- file.path(CONFIG_DIR, paste0(config, ".R"))
    prof_dir <- file.path(out, paste0("profile_", config))
    dir.create(prof_dir, recursive = TRUE, showWarnings = FALSE)
    prof_out <- file.path(out, paste0(config, ".Rprof"))
    log_msg("Start profiling for: ", config)

    define_cores(cores = 1, log_msg = log_msg)

    error_occured <- FALSE
    error_message <- NA_character_
    system_time_start <- Sys.time()

    tryCatch(
        {
            utils::Rprof(
                filename = prof_out,
                interval = SAMPLE_INTERVAL,
                memory.profiling = TRUE,
                gc.profiling = TRUE,
                line.profiling = TRUE
            )
            run_simulation(
                config = config_path,
                space = SPACE_RASTER,
                output_directory = prof_dir,
                verbose = 0
            )
        },
        error = function(e) {
            error_occured <<- TRUE
            error_message <<- conditionMessage(e)
        },
        finally = utils::Rprof(NULL) # Ensure Rprof stops on error
    )
    system_time_stop <- Sys.time()
    total_runtime <- difftime(
        system_time_stop,
        system_time_start,
        units = "hours"
    )[[1]]

    if (error_occured) {
        log_msg("Failed run: ", error_message)
    } else {
        log_msg("Finished successfully in ", total_runtime, "hours")
    }
}


# --- Benchmarking run ------------
# Use the same config for all given core counts
run_benchmark <- function(config, cores) {
    config_path <- file.path(CONFIG_DIR, paste0(config, ".R"))
    bench_out <- file.path(out, sprintf("%s_cores%02d", config, cores))
    dir.create(bench_out, recursive = TRUE, showWarnings = FALSE)

    log_msg("Start benchmarking for: ", config, " with cores: ", cores)
    define_cores(cores = cores, log_msg = log_msg)

    run_simulation(
        config = config_path,
        space = SPACE_RASTER,
        output_directory = bench_out,
        verbose = 0
    )
}


# --- Start profiling and benchmarking-----

# TODO Unload terra if it was laoded, may be nice to have for later before simulation starts

for (config in CONFIGS) {
    log_msg("---- Profiling ----")
    run_profiling(config)

    log_msg("---- Benchmarking ----")

    seconds <- vapply(CORES, function(k) {
        future::plan(future::sequential) # Reset workers
        s <- system.time(
            run_benchmark(config, k)
        )[["elapsed"]]
        return (s)
    }, numeric(1))

    res <- data.frame(
        config = config, 
        cores = CORES, 
        seconds = seconds, 
        hours = seconds / 3600
    )
    res$speedup <- res$seconds[1] / res$seconds

    utils::write.csv(res, file.path(out, paste0(config, "_benchmark.csv")),
        row.names = FALSE
    )
    saveRDS(res, file.path(out, paste0(config, "_bench_mark.rds")))
}


# --- Final message ----
message("Finished, check logs")
