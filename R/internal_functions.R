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
    # Splitting a tip creates an event: continuing ancestor first, daughter
    # second. Integer indices avoid searching or rebuilding serialized strings.
    n <- nrow(phy)
    left <- right <- integer(2L * n - 1L)
    age <- branch_length <- numeric(2L * n - 1L)
    species <- integer(2L * n - 1L)
    tip <- integer(n)
    ancestor <- match(phy$Ancestor, phy$Descendent)
    tip[1L] <- 1L
    species[1L] <- 1L
    age[1L] <- phy$Speciation.Time[1L]
    used <- 1L

    for (i in seq.int(2L, n)) {
      parent <- tip[ancestor[i]]
      continuing <- used + 1L
      daughter <- used + 2L
      event_time <- phy$Speciation.Time[i]
      left[parent] <- continuing
      right[parent] <- daughter
      branch_length[parent] <- age[parent] - event_time
      age[continuing] <- age[daughter] <- event_time
      species[continuing] <- ancestor[i]
      species[daughter] <- i
      tip[ancestor[i]] <- continuing
      tip[i] <- daughter
      used <- daughter
    }
    # Preserve the convention that only positive extinction times shorten tips.
    extinction <- phy$Extinction.Time
    extinction[extinction <= 0] <- 0
    branch_length[tip] <- age[tip] - extinction

    # Emit newick_parts (tokens in serialization terminology) in one iterative 
    # depth-first pass, including the root edge.
    # Preallocation and a single join keep serialization linear in output size;
    # an explicit stack also supports trees deeper than R's recursion limit.
    newick_parts <- character(4L * n - 3L)
    stack <- integer(3L * n)
    stack[1L] <- 1L
    top <- 1L
    count <- 0L
    while (top > 0L) {
      node <- stack[top]
      top <- top - 1L
      count <- count + 1L
      if (node == 0L) {
        newick_parts[count] <- ","
      } else if (node < 0L) {
        newick_parts[count] <- paste0("):", branch_length[-node])
      } else if (left[node] == 0L) {
        newick_parts[count] <- paste0(label, phy$Descendent[species[node]],
                                ":", branch_length[node])
      } else {
        newick_parts[count] <- "("
        stack[top + seq_len(4L)] <- c(-node, right[node], 0L, left[node])
        top <- top + 4L
      }
    }
    String <- paste0(newick_parts, collapse = "")
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