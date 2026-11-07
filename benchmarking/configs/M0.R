########################
### General settings ###
########################

# comb_vector <- list(seed = 20884, dispersal = 0, divergence_threshold = 65, competition = 0.9)
comb_vector <- list(seed = 93427, dispersal = 0.25, divergence_threshold = 20, competition = 0.5)

random_seed = comb_vector$seed
duration <- list(
  from = NA,
  to = NA,
  by = 1,
  unit = "Myr"
)
max_number_of_species =20000
max_number_of_coexisting_species =20000
initial_abundance =  0.05

# serves as a template
#ss_eff_emp <- list("dispersal"=NA, "dispersal_success"=NA, "environmental_filter"=NA, "competition_c"=NA, "competition_l"=NA)
#ss_eff <- list()

# ecological local equilibria variable J*
get_J <- function(a_ff, a_fh, K_f){
  J <- sum((a_ff*K_f)/(a_ff-a_fh), na.rm=T)/(1+sum((a_fh/(a_ff-a_fh)), na.rm=T)) # new
  return(J)
}

# ecological environmental function
fg <- function(x,a,b,c,ns=1){
  a <- a/c
  v <- a*exp(-((x-b)^2/(2*c^2)))
  return(v)
}

# set for first time
# assign("ss_eff", ss_eff_emp, envir = .GlobalEnv)
# a list of traits to include with each species, traits with ss_eff_ are hack traits to extract in site processes
trait_names = c("dispersal", "mean_temp", "temp_width", "competition")

# ranges to scale the input environemts with:
# not listed variable:         no scaling takes place
# listed, set to NA:           the environmental variable will be scaled from [min, max] to [0, 1]
# lsited with a given range r: the environmental variable will be scaled from [r1, r2] to [0, 1]
environmental_ranges = list("mean_temp"=c(9,26), "min_temp"=c(9,26),  "max_temp"=c(9,26))

#########################
### Observer Function ###
#########################

end_of_timestep_observer = function(data, vars, config){
  # jpeg(paste0(config$directories$output_plots, "/ranges_t", vars$ti, ".jpeg"))
  # {
  #   par(mfrow=c(1,1))
  #   plot_ranges(data$all_species[c(1:3)], data$space)
  # }
  # dev.off()
  #browser()
  # plot_richness(data$all_species, data$space)
  # # save_species()
  # save_abundance()
  # # save_divergence()
  # # save_occupancy()
  # # save_phylogeny()
  # save_traits()
  #
  # # make p/a matrices if necessary
  # if(!file.exists(file.path(config$directories$output, "occs"))){dir.create(file.path(config$directories$output, "occs"))}
  # # site names
  # all_sites <- rownames(data$space$coordinates)
  # # get 0 for absence and 1 for presence in each grid site
  # all_species_presence <- do.call( cbind, lapply(data$all_species, FUN = function(x) {ifelse(all_sites %in% names(x$abundance), 1, 0)}))
  # # colnames are species names
  # colnames(all_species_presence ) <- unlist(lapply(data$all_species, function(x){x$id}))
  # # column bind with x/y coordinates
  # presence_absence_matrix <- cbind(data$space$coordinates, all_species_presence)
  # saveRDS(presence_absence_matrix, file=file.path(config$directories$output,"occs",  paste0("pa_t_",vars$ti, ".rds")))
  # # if(!file.exists(file.path(config$directories$output, "mean_traits_sp"))){dir.create(file.path(config$directories$output, "mean_traits_sp"))}
  # # saveRDS(data$eco_by_sp, file=file.path(config$directories$output,"mean_traits_sp",  paste0("mean_trs_t_",vars$ti, ".rds")))
}


######################
### Initialization ###
######################

create_ancestor_species <- function(space, config) {
  co <- space$coordinates
  new_species <- list()
  for(i in unique(space$environment[,"patch"])){
    initial_sites <- rownames(co)[space$environment[,"patch"]==i]
    # initial_sites <- sample(initial_sites, 1)
    new_species[[i]] <- create_species(initial_sites, config)
    #set local adaptation to max optimal temp equals local temp
    new_species[[i]]$traits[ , "dispersal"] <- comb_vector$dispersal
    new_species[[i]]$traits[ , "competition"] <- comb_vector$competition # stress the difference between c_c of 0.9 (lots of competition and little coexistence) and 0.99 (almost no competition thus lots of coexistence)
    new_species[[i]]$traits[ , "mean_temp"] <- space$environment[initial_sites,"mean_temp"]
    new_species[[i]]$traits[ , "temp_width"] <- 0.4
    plot_species_presence(space, species=new_species[[i]])
  }
  return(new_species)
}


#################
### Dispersal ###
#################

# returns n dispersal values (proba distrib function)
get_dispersal_values <- function(n, species, space, config){
  # hist(rweibull(117546,shape=2, scale=50)) # sample of # of drawn max for this simulation per time step.
  # print(n)
  mean_abd <- mean(species$abundance)
  weight_abd <- species$abundance/mean_abd
  values <- rweibull(n, shape = 2, scale = 1+(mean(species$traits[,"dispersal"]*weight_abd)*49))  #from 5 to 50
  return(values)
}


##################
### Speciation ###
##################

# threshold for genetic distance after which a speciation event takes place
divergence_threshold = comb_vector$divergence_threshold # between 10 and 50 ? as 0.1 to 0.5 Myrs or 100 - 500 kyrs

# adds a value of 1 to each geographic population cluster
get_divergence_factor <- function(species, cluster_indices, space, config) {
  return(1)
}

#######################
### Trait Evolution ###
#######################

apply_trait_evolution <- function(species, cluster_indices, space, config) {
  trait_evolutionary_power <-0.01
  pw_tr_hom <- 0.5 # percentage of movement of local trait towards weighted trait mean within each population cluster
  # pw_tr_hom = ZERO means no change while a value of ONE means that traits are equal within each populations cluster)
  traits <- species[["traits"]]
  # site names
  sites <- rownames(traits)
  #homogenize trait based on abundance
  # Homogenize all traits by weighted abundance, attention, exclude here any trait that should be more neutral
  # Bring traits closer to 50% of it's distance to the abundance weighted mean of the demographically connected
  # population cluster
  trn <- config$gen3sis$general$trait_names
  for(cluster_index in unique(cluster_indices)){
    # cluster_index <- 1
    sites_cluster <- sites[which(cluster_indices == cluster_index)]
    B_t <- sum(species$abundance[sites_cluster])# total biomass
    B_r <- species$abundance[sites_cluster]/B_t# relative biomass
    for (ti in trn){
      # par(mfrow=c(1,2))
      # hist(traits[sites_cluster, ti], main="before")
      traits_ti <- traits[sites_cluster, ti]
      mean_trait <- sum(traits_ti*B_r)
      tr_hom <- mean_trait-traits_ti
      traits[sites_cluster, ti] <- traits_ti+(tr_hom*pw_tr_hom)
      # hist(traits[sites_cluster, ti], main="after")
    }
  }
  
  #mutate all traits except dispersal and competitive ability M0 and summary effective traits, which where excluded previously
  for (ti in c("mean_temp", "temp_width", "competition", "dispersal")){#trn[!trn%in%"dispersal"]){ # do not evolve dispersal
    if(ti=="competition"){ # check if competition and scale proportionally 0.1 variance /10 = 1, while 1 variance /1 = 1
      tep_sd=trait_evolutionary_power/10
    } else {
      tep_sd=trait_evolutionary_power
    }
    mutation_deltas <-rnorm(length(traits[, ti]), mean=0, sd=tep_sd)
    traits[, ti] <- traits[, ti] + mutation_deltas
  }
  # set bounds so that the species cant evolve a niche beyond that present in the data
  # note that all temperature values are scaled between 0 and 1
  if(any(traits[, "temp_width"] > 1)){traits[which(traits[,"temp_width"]>1), "temp_width"] <- 1}
  if(any(traits[, "temp_width"] <= 0)){traits[which(traits[,"temp_width"]<=0), "temp_width"] <- 0.001} #limit of zero to avoid zero divisions on specialist/generalist trade-off
  if(any(traits[, "competition"] > 1)){traits[which(traits[,"competition"]>1), "competition"] <- 1}
  if(any(traits[, "competition"] < 0.9)){traits[which(traits[,"competition"]<0.9), "competition"] <- 0.9}
  if(any(traits[, "dispersal"] > 1)){traits[which(traits[,"dispersal"]>1), "dispersal"] <- 1}
  if(any(traits[, "dispersal"] < 0)){traits[which(traits[,"dispersal"]<0), "dispersal"] <- 0}

  return(traits)
}

#################################################
### Environmental and Ecological Interactions ###
#################################################

apply_ecology <- function(abundance, traits, space, config) {
  ns <- length(abundance)
  #### get rf, here r_f is the per capita growth rate of biomass that depends on the local site conditions
  # set env niche
  env_min_fg <- fg(x=space[,"min_temp"], a=1, b=traits[, "mean_temp"], c=traits[, "temp_width"])
  env_max_fg <- fg(x=space[,"max_temp"], a=1, b=traits[, "mean_temp"], c=traits[, "temp_width"])
  # set growth rate
  g <- .1
  # abundance_tii first is only what the env. determines to be the new abundances
  r_f <- g*sqrt(env_min_fg*env_max_fg) # geometric mean

  ###### get (a_ff) = same species interaction coefficient and (afh)= heterospecific interaction coefficient
  # get traits Competition
  c_c <- rep(0.8,ns) # intra competition
  c_l <- traits[,"competition"]

  # set a_ff and a_fh
  a_ff <- 1-c_c
  a_fh <- 1-c_l

  # check if conditions are met in order to continue
  if (any(a_ff<=a_fh)){
    stop("a_ff has to be bigger than a_fh for this equilibrium function to be used! Check your intial and evolutionary conditions of the competition traits.")
  }
  
  ####### get K_f = the carrying capacity of species f (that is the equilibrium for the case without heterospecific biomass
  K_f <- r_f/a_ff
  ###### get J = the total biomass J* of the community in equilibrium
  J <- get_J(a_ff, a_fh, K_f)
  wistop <- FALSE
  keep_on_while <- rep(TRUE, ns)
  while(wistop==FALSE){
    shall_live <- (a_ff*K_f)>(a_fh*J)
    if (all(!shall_live)){ # in case all shall die
      B_f <- as.numeric(shall_live) # set all to zero, since we only have shall_live==FALSE
      wistop <- TRUE
    }
    if (all(shall_live[keep_on_while])){
      B_f <- ((a_ff*K_f)-(a_fh*J))/(a_ff-a_fh)
      B_f[!shall_live] <- 0
      wistop <- TRUE
    } else{
      a_ff[!shall_live] <- 0
      a_fh[!shall_live] <- 0
      K_f[!shall_live] <- 0
      keep_on_while <- shall_live
      if (sum(keep_on_while)==0){
        B_f[!shall_live] <- 0
        wistop <- TRUE
      }
      J <- get_J(a_ff, a_fh, K_f)
    }
  }
  names(B_f) <- names(abundance)
  B_f[B_f<0] <- 0 # set extinct species abundance to zero
  return(B_f)
}

#----------------------#
#### Space modifier ####
#----------------------#

get_modifiers <- function(space, config, all_species) {
  NULL
}

apply_modifiers <- function(space, config, modifiers) {
  space$environment
}