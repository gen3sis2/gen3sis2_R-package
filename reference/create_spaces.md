# create empty gen3sis_spaces

create empty gen3sis_spaces

## Usage

``` r
create_spaces(
  env = list(NA),
  type = "raster",
  duration = list(from = NA, to = NA, by = NA, unit = "Myr"),
  area = list(extent = NA, total_area = NA, n_sites = NA, unit = "km2"),
  crs = "EPSG:4326",
  cost_function = list(NA),
  geodynamic = NULL,
  type_spec = list(res = NA),
  author = "missing",
  source = "missing",
  description = list(environment = "missing", methods = "missing")
)
```

## Arguments

- env:

  named list of environmental variables in a with X,Y, and time-steps
  from the most recent of future time-step

- type:

  string with type of gen3sis spaces. Accepted values are
  `check_spaces()$type`

- duration:

  list containing information on temporal dimension list(from, to, by,
  unit) \*from\* is the oldest time-step; negative number if starting in
  the past, zero if starting in the present \*to\* CAN ONLY BE smaller
  than \*from\*, since \*to\* is the latest time \*by\* is the time
  interval increment. Note that this is constant and can only be
  positive; \*unit\* is the time unit used. Accepted units are
  `check_spaces()$duration` e.g. list(-20, 0, 1, "Myr") has a space that
  covers the last 20 Ma until the present, every 1 Ma. list(-800, 300,
  10, "mil") has a space that covers the last 800 kyra or mil for
  millions of years and goes until the future 300 kya at every 100 mil
  years.

- area:

  list containing information on the 2D spacial dimension: list(extent,
  total_area, n_sites, unit) \*extent\* is a named vector with (xmin,
  xmax, ymin, ymax)
  [`terra::ext`](https://rspatial.github.io/terra/reference/ext.html),
  \*total_area\* is the covered area by the points, raster or h3 grid,
  \*n_sites\* is the number of sites and \*unit\* is theunit of the
  area, accepted units are square meter (m2) and square kilometer (km2)
  `check_spaces()$area`

- crs:

  Coordinate Reference Systems, as string and PROJ.4 format. Default is,
  WGS 84 – WGS84 - World Geodetic System 1984 crs="+proj=longlat
  +datum=WGS84 +no_defs"

- cost_function:

  list of cost_function(s) used to calculate the cost distances between
  sites. Depends on type and other methods used to calculate the cost
  distances.

- geodynamic:

  boolean for if sites change location or disappear over time ,default
  is NULL and deduces from NA over time. If false, only one
  cost_distance is calculated and used i.e. whencost_distances are the
  same, i.e. no geodynamic changes in the space

- type_spec:

  list containing type specific information, e.g. res (resolution) for
  raster and h3 spaces

- author:

  string with the name of the author. Default is NULL which gives the
  system user name obtained from `Sys.info()["user"]` This is far from
  ideal, but it is better than nothing. Please fill this up and even
  consider leaving a contact information

- source:

  string with the source of the data, ideally should contain a
  publication with DOI and a valid URL Default is list(env="missing",
  methods="missing")

- description:

  list with "env" and "methods" containing information on the
  environmental data, methods used and other relevant information such
  as source to raw data. Default is list("missing" The "env" should
  describe the environmental data used, including it's units

## Value

an informal and empty gen3sis_spaces object

## Examples

``` r
library(gen3sis2)

# Creates an empty spaces with the right structure
empty_spaces <- create_spaces()

# It contains "env" and "meta"
names(empty_spaces)
#> [1] "env"  "meta"

# "meta" contains metadata and essential information about the spaces and env
names(empty_spaces$meta)
#> [1] "type"          "type_spec"     "duration"      "area"         
#> [5] "crs"           "cost_function" "author"        "source"       
#> [9] "description"  
```
