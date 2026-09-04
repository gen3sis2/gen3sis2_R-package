# #----------------------------------------#
# #####           Setup                #####
# #----------------------------------------#
# devtools::load_all()
library(gen3sis2)
library(terra)

# ---- Log level -------
#' 0: write logs to log file only
#' 1: write to log file and print to console
LOG_LEVEL <- 1

# ---- Parameters ------------
SPACE_RASTER <- file.path("benchmarking", "spaces_raster")

CONFIG_DIR <- file.path("benchmarking", "configs")

#' Add all configs that should be analyzed in this run
CONFIGS <- c(
    "config_southamerica"
)

#' Interval of analysis
SAMPLE_INTERVAL <- 0.05


run_id <- format(Sys.time(), "Run_%Y-%m-%d_%H-%M")
out <- file.path("benchmarking", "output", run_id)
dir.create(out, recursive = TRUE, showWarnings = FALSE)


# #----------------------------------------#
# #####            Profiling           #####
# #----------------------------------------#

# ----- Logging ----------------
log <- file.path(out, "log.txt")

log_msg <- function(...) {
    msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", ...)
    cat(msg, "\n", file = log, append = TRUE)
    if (LOG_LEVEL == 1) {
        cat(msg, "\n")
        flush.console()
    }
}


# ---- Build spaces if none are available -------------------------------------
if (!file.exists(file.path(SPACE_RASTER, "spaces.rds"))) {
    log_msg("Space not found, starting to build ...")
    datapath <- file.path("Simulations", "input_rasters", "SouthAmerica")

    temperature_raster <- rast(file.path(datapath, "temperature_rasters.grd"))
    aridity_raster <- rast(file.path(datapath, "aridity_rasters.grd"))
    area_raster <- rast(file.path(datapath, "area_rasters.grd"))

    # Sort rasters
    temperature_raster <- temperature_raster[[order(names(temperature_raster), decreasing = T)]]
    aridity_raster <- aridity_raster[[order(names(aridity_raster), decreasing = T)]]
    area_raster <- area_raster[[order(names(area_raster), decreasing = T)]]

    spaces_list <- list(
        temp = temperature_raster,
        arid = aridity_raster,
        area = area_raster
    )

    cost_function <- function(source, dest) {
        return(1 / 1000)
    }

    create_spaces_raster(
        raster_list = spaces_list,
        cost_function = cost_function,
        output_directory = SPACE_RASTER,
        directions = 8,
        duration = list(from = -65, to = 0, by = 1, unit = "Ma"),
        full_dists = TRUE,
        overwrite_output = TRUE,
        crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs",
        geodynamic = TRUE,
        verbose = TRUE
    )
} else {
    log_msg("Space found at: ", SPACE_RASTER)
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
        log_msg("Config not found: ", config_path)
        stop("Ivalid config: ", input_config)
    }
}


# --- Profiling run ------
run_profiling <- function(config) {
    config_path <- file.path(CONFIG_DIR, paste0(config, ".R"))
    dir.create(out, recursive = TRUE, showWarnings = FALSE)
    prof_out <- file.path(out, paste0(config, ".Rprof"))
    log_msg("Start profiling for: ", config)


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
            # run_simulation(
            gen3sis2::run_simulation(
                config = config_path,
                space = SPACE_RASTER,
                output_directory = out,
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


# --- Start profiling -----
for (config in CONFIGS) {
    run_profiling(config)
}


# --- Final message ----
message("Finished profiling, check logs")
