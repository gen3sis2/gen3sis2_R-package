library(gen3sis2)

# Creates an empty spaces with the right structure
empty_spaces <- create_spaces()

# It contains "env" and "meta"
names(empty_spaces)

# "meta" contains metadata and essential information about the spaces and env
names(empty_spaces$meta)
