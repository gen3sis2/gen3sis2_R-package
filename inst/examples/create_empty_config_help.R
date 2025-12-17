library(gen3sis2)

# Creates an empty config
empty_config <- create_empty_config()

# It is a list with:
# gen3sis: functions and parameters
# user: user defined objects
# directories: input and output directories
names(empty_config)

# "gen3sis" include the main functions categories 
names(empty_config$gen3sis)
