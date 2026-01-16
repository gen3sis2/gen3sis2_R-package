# classic arithmetic mean Ne
ne_am <- function(individualss){
  n <- length(individualss)
  am <- n/(sum(1/individualss))
  return(am)
}

# sequence of individuals
individuals_time <- c(10,1233,200,400,180, 400)

# simulating a loop over time steps with the varrying number of individuals
# note that this has to be converted to number of individuals per generation internally
n_stepi <- 0
individuals_time_proxyi <- 0
for (individuals in individuals_time){
  res <- get_effective_population_size(n_stepi, individuals_time_proxyi, individuals)
  ne <- res$Ne
  individuals_time_proxyi <- res$individuals_time_proxy
  n_stepi <- n_stepi + 1
}
identical(round(ne,10), round(ne_am(individuals_time),10))
# should be identical to ne_am
