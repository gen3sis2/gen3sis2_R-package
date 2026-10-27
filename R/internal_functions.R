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

#' Save the current phylogeny in NEXUS format
#'
#' @param phy the phylogeny up to this point
#' @param label prefix for species labels
#' @param output_file the file path and name to store the result
#'
#' @importFrom utils write.table
#' @noRd
write_nex <- function(phy, label = "sp", output_file) {
  val <- dynGet("val")
  stop_time <- val$config$gen3sis$general$duration$to

  # Preserve the legacy multi-root convention: add a synthetic species, shift
  # species IDs by one, and retain its continuing tip in the output tree.
  rootphy <- phy$Speciation.Type == "ROOT"

  if (sum(rootphy) > 1) {
    phy$Ancestor[rootphy] <- 0
    phy$Speciation.Type <- as.character(phy$Speciation.Type)
    phy$Speciation.Type[rootphy] <- "COMB"
    addroot <- c(
      "0",
      "0",
      phy$Speciation.Time[1],
      stop_time - 1,
      "ROOT"
    )
    names(addroot) <- colnames(phy)
    phy <- rbind(addroot, phy)
    phy$Ancestor <- as.integer(phy$Ancestor)
    phy$Descendent <- as.integer(phy$Descendent)
    phy[, c("Ancestor", "Descendent")] <- phy[, c("Ancestor", "Descendent")] + 1
    phy$Ancestor <- as.integer(phy$Ancestor)
    phy$Descendent <- as.integer(phy$Descendent)
    phy$Speciation.Time <- as.numeric(phy$Speciation.Time)
    phy$Extinction.Time <- as.numeric(phy$Extinction.Time)
    phy$Speciation.Type <- as.factor(phy$Speciation.Type)
  }

  # The first row is the initial species; later rows describe branching events.
  phy_no_root <- phy[-1, , drop = FALSE]

  if (nrow(phy_no_root) == 0) {
    # Preserve the TreeSim/TreeSimGM singleton convention (no NEXUS wrapper).
    if (phy[1, "Extinction.Time"] == stop_time - 1) {
      nexus_output <- "1" # tree with only root
    } else {
      nexus_output <- "0" # tree with only root that got extinct
    }
  } else {
    # Species rows and tree nodes are different indices. Each split turns the
    # ancestor's current tip into a branching event with two children: the
    # continuing ancestor and the new daughter species, in that output order.
    # Rows must list ancestors before descendants (the simulation's order).
    species_count <- nrow(phy)
    node_count <- 2 * species_count - 1
    continuing_child <- numeric(node_count)
    daughter_child <- numeric(node_count)
    branch_start_time <- numeric(node_count)
    branch_length <- numeric(node_count)
    species_row_by_node <- numeric(node_count)
    tip_node_by_species <- numeric(species_count)
    ancestor_row <- match(phy$Ancestor, phy$Descendent)
    tip_node_by_species[1] <- 1
    species_row_by_node[1] <- 1
    branch_start_time[1] <- phy$Speciation.Time[1]
    last_node <- 1

    for (species_row in seq.int(2, species_count)) {
      event_node <- tip_node_by_species[ancestor_row[species_row]]
      continuing_node <- last_node + 1
      daughter_node <- last_node + 2
      split_time <- phy$Speciation.Time[species_row]

      continuing_child[event_node] <- continuing_node
      daughter_child[event_node] <- daughter_node
      branch_length[event_node] <- branch_start_time[event_node] - split_time
      branch_start_time[continuing_node] <- split_time
      branch_start_time[daughter_node] <- split_time
      species_row_by_node[continuing_node] <- ancestor_row[species_row]
      species_row_by_node[daughter_node] <- species_row
      tip_node_by_species[ancestor_row[species_row]] <- continuing_node
      tip_node_by_species[species_row] <- daughter_node
      last_node <- daughter_node
    }

    # Time counts down. update_extinction_times() records stop_time - 1 for
    # species still alive at the final step. Their branches end at stop_time,
    # not zero and not that sentinel. Extinct species end at their recorded
    # extinction time, including species that disappear at the final step.
    tip_end_time <- pmax(phy$Extinction.Time, stop_time)
    # Map tree nodes back to species rows explicitly: extinction times belong
    # to species, not node numbers. This mapping also includes a synthetic root.
    tip_species_rows <- species_row_by_node[tip_node_by_species]
    branch_length[tip_node_by_species] <-
      branch_start_time[tip_node_by_species] - tip_end_time[tip_species_rows]

    # Write (continuing subtree,daughter subtree):branch_length for each event.
    # A stack is a list of pending actions processed from the end. It avoids
    # recursive function calls, so very deep trees do not exhaust R's call stack.
    # Positive action: visit that node. Zero: write a comma. Negative action:
    # close the corresponding event with ')' and its incoming branch length.
    # Negative values are instructions, never negative vector indices.
    # Each tip emits one part and each event emits three: '(', ',', and '):len'.
    newick_parts <- character(4 * species_count - 3)
    pending_actions <- numeric(3 * species_count)
    pending_actions[1] <- 1
    pending_count <- 1
    part_count <- 0
    while (pending_count > 0) {
      action <- pending_actions[pending_count]
      pending_count <- pending_count - 1
      part_count <- part_count + 1
      if (action == 0) {
        newick_parts[part_count] <- ","
      } else if (action < 0) {
        event_node <- -action
        newick_parts[part_count] <- paste0("):", branch_length[event_node])
      } else if (continuing_child[action] == 0) {
        species_row <- species_row_by_node[action]
        newick_parts[part_count] <- paste0(
          label, phy$Descendent[species_row], ":", branch_length[action])
      } else {
        newick_parts[part_count] <- "("
        # Push in reverse output order: the continuing child is visited next,
        # then the comma, daughter child, and finally the closing event action.
        pending_actions[pending_count + seq_len(4)] <- c(
          -action, daughter_child[action], 0, continuing_child[action])
        pending_count <- pending_count + 4
      }
    }
    # Join once, after traversal, instead of repeatedly rebuilding a long string.
    newick_tree <- paste0(newick_parts, collapse = "")
    nexus_output <- paste("Tree tree = ", newick_tree, ";", sep = "")
    nexus_output <- (paste(
      "#NEXUS",
      "begin trees;",
      nexus_output,
      "end;",
      "[!Tree generated with the gen3sis R package, following convention of TreeSim and TreeSimGM r-packages]",
      sep = "\n"
    ))
  } #end test if there is a tree

  write.table(
    nexus_output,
    output_file,
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
  )

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