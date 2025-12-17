# 7. Support functions

``` r
library(gen3sis2)
```

## Introduction

During or after thet simulation, users may need to retrieve some
specific information that are not directly disponible. This usually
includes rates, matrices or subsets based on the simulation state. To
get this, most times users must define functions that manipulate
`gen3sis2` objects. Altought this should be considerably easy, sometimes
it can be quite inconvenient.

To facilitate this processes and wide the functionalities range of
`gen3sis2`, the package features several generic support functions that
cover many common computations, such as presence and abundance matrices,
endemism measurements, etc. This functions are designed to be used
inside and outside simulations. In this vignette, we will describe and
exemplify all the currently built-in support functions.

##### Before we continue…

As this vignette is for illustration purposes only, we will load spaces
and species objects saved with `save_spaces()` and
[`save_species()`](../reference/save_species.md), respectively, and
construct a minimal version of the `data` object, which contains the
simulation state in `gen3sis2` and is available inside the observer
function. In this version we will only have the species list and space.

``` r
space <- system.file("extdata/SouthAmerica/species_and_spaces/space_t_2.rds", package = "gen3sis2") |> readRDS()

all_species <- system.file("extdata/SouthAmerica/species_and_spaces/species_t_2.rds", package = "gen3sis2") |> readRDS()

data <- list(
  space = space,
  all_species = all_species
)
```

## `get_` functions

The `get_` functions family comprises a wide range of species and spaces
related functionalities. They are all designed to be used inside the
simulation (for example, in the observer function) or outside it, with
the files created with `save_spaces()` and
[`save_species()`](../reference/save_species.md), to retrieve some
information. I.e., they are used to *get something from the simulation
values*.

- `get_presence_matrix`

This function constructs a presence-absence matrix based on the space
sites. In this matrix, rows are site indexes and columns are species
indexes. Optionally, users can get the xy coordinates for each site as
the first two columns (`xy=TRUE`) or include all sites that don’t havy
any species (`empty_sites=TRUE`).

Inside the observer function:

``` r
get_presence_matrix(data$all_species)[1:5,] # showing just the five first sites
#>     1 2 3 4 5 6 7 8 9 10 11 12
#> 841 1 0 0 0 0 0 0 0 0  0  0  0
#> 877 1 0 0 0 0 0 0 0 0  0  0  0
#> 879 1 0 0 0 0 0 0 0 0  0  0  0
#> 912 1 0 0 0 0 0 0 0 0  0  0  0
#> 913 1 0 0 0 0 0 0 0 0  0  0  0
```

To include the site coordinates, space must be provided:

``` r
get_presence_matrix(data$all_species, data$space, xy=T)[1:5,]
#>       x   y 1 2 3 4 5 6 7 8 9 10 11 12
#> 841 -70 -34 1 0 0 0 0 0 0 0 0  0  0  0
#> 877 -70 -36 1 0 0 0 0 0 0 0 0  0  0  0
#> 879 -66 -36 1 0 0 0 0 0 0 0 0  0  0  0
#> 912 -72 -38 1 0 0 0 0 0 0 0 0  0  0  0
#> 913 -70 -38 1 0 0 0 0 0 0 0 0  0  0  0
```

With saved files:

``` r
get_presence_matrix(all_species, space)[1:5,]
#>     1 2 3 4 5 6 7 8 9 10 11 12
#> 841 1 0 0 0 0 0 0 0 0  0  0  0
#> 877 1 0 0 0 0 0 0 0 0  0  0  0
#> 879 1 0 0 0 0 0 0 0 0  0  0  0
#> 912 1 0 0 0 0 0 0 0 0  0  0  0
#> 913 1 0 0 0 0 0 0 0 0  0  0  0
```

- `get_species_prevalence`

This function calculates the species global prevalence of each species,
i.e., the proportion of sites occupied by each species in the entire
space. It returns a named vector. Names are species’ index, values are
species’ prevalence.

In the observer function:

``` r
get_species_prevalence(data$all_species, data$space)
#>           1           2           3           4           5           6 
#> 0.037900875 0.005830904 0.005830904 0.017492711 0.008746356 0.011661808 
#>           7           8           9          10          11          12 
#> 0.002915452 0.005830904 0.005830904 0.008746356 0.023323615 0.017492711
```

With loaded files:

``` r
get_species_prevalence(all_species, space)
#>           1           2           3           4           5           6 
#> 0.037900875 0.005830904 0.005830904 0.017492711 0.008746356 0.011661808 
#>           7           8           9          10          11          12 
#> 0.002915452 0.005830904 0.005830904 0.008746356 0.023323615 0.017492711
```

- `get_extant_species`

This function returns a vector of the extant species at the current
time-step, i.e., species that are currently present in at least one
site.

In the observer function:

``` r
get_extant_species(data$all_species)
#>  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12"
```

From loaded files:

``` r
get_extant_species(all_species)
#>  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12"
```

- `get_abundance_matrix`

Similar to the `get_presence_matrix`, this function returns an abundance
matrix. Rows are sites indexes, columns are species indexes. `xy` and
`empty_sites` arguments are also present.

In the observer function:

``` r
get_abundance_matrix(data$all_species)[1:5,]
#>            1 2 3 4 5 6 7 8 9 10 11 12
#> 841 9.697987 0 0 0 0 0 0 0 0  0  0  0
#> 877 9.748367 0 0 0 0 0 0 0 0  0  0  0
#> 879 9.544444 0 0 0 0 0 0 0 0  0  0  0
#> 912 9.723510 0 0 0 0 0 0 0 0  0  0  0
#> 913 9.939520 0 0 0 0 0 0 0 0  0  0  0
```

From loaded files:

``` r
get_abundance_matrix(all_species)[1:5,]
#>            1 2 3 4 5 6 7 8 9 10 11 12
#> 841 9.697987 0 0 0 0 0 0 0 0  0  0  0
#> 877 9.748367 0 0 0 0 0 0 0 0  0  0  0
#> 879 9.544444 0 0 0 0 0 0 0 0  0  0  0
#> 912 9.723510 0 0 0 0 0 0 0 0  0  0  0
#> 913 9.939520 0 0 0 0 0 0 0 0  0  0  0
```

- `get_site_abundance`

Similar to `get_abundance_matrix`, but sums the abundance of all species
present in each site. `xy` and `empty_sites` arguments are also present.

In the observer function:

``` r
get_site_abundance(data$all_species)[1:5,,drop=F]
#>      abundance
#> 1022  9.836517
#> 1023  9.992940
#> 1058  9.808667
#> 1127  9.833123
#> 1128  9.846509
```

From loaded files:

``` r
get_site_abundance(all_species)[1:5,,drop=F]
#>      abundance
#> 1022  9.836517
#> 1023  9.992940
#> 1058  9.808667
#> 1127  9.833123
#> 1128  9.846509
```

- `get_geo_richness`

This function returns a named vector containing species richness in each
site. Names are site indexes, and values are site richness.

In the observer function:

``` r
get_geo_richness(data$all_species, data$space)[1:50]
#>  48  49  84  85  86  87  88  89 119 120 121 122 123 124 125 126 154 155 156 157 
#>   0   0   0   0   0   0   0   0   0   0   0   0   1   1   0   0   0   0   0   0 
#> 158 159 160 161 162 163 164 165 190 191 192 193 194 195 196 197 198 199 200 201 
#>   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 
#> 202 225 226 227 228 229 230 231 232 233 
#>   0   0   0   0   0   0   0   0   0   0
```

From loaded files:

``` r
get_geo_richness(all_species, space)[1:50]
#>  48  49  84  85  86  87  88  89 119 120 121 122 123 124 125 126 154 155 156 157 
#>   0   0   0   0   0   0   0   0   0   0   0   0   1   1   0   0   0   0   0   0 
#> 158 159 160 161 162 163 164 165 190 191 192 193 194 195 196 197 198 199 200 201 
#>   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 
#> 202 225 226 227 228 229 230 231 232 233 
#>   0   0   0   0   0   0   0   0   0   0
```

- `get_mean_richness`

This function simply calculates the global mean richness.

In the observer function:

``` r
get_mean_richness(data$all_species, data$space)
#> [1] 0.1516035
```

From loaded files:

``` r
get_mean_richness(all_species, space)
#> [1] 0.1516035
```

- `get_species_range`

This function calculate each species’ range, i.e., the number of sites
in which they are present. Returns a named vector; names are species
indexes, values are species range.

In the observer function:

``` r
get_species_range(data$all_species, data$space)
#>  1  2  3  4  5  6  7  8  9 10 11 12 
#> 13  2  2  6  3  4  1  2  2  3  8  6
```

From loaded files:

``` r
get_species_range(all_species, space)
#>  1  2  3  4  5  6  7  8  9 10 11 12 
#> 13  2  2  6  3  4  1  2  2  3  8  6
```

- `get_weighted_endemism`

This function calculate the weighted endemism $`WE`$ of each site. The
function calculate this following the equation
``` math

\text{Weighted Endemism} = \frac{\text{Site richness}}{\sum_{j \in \text{site}} \text{Species range}_j}
```

Higher values indicate that the site contains more rare species.

In the observer function:

``` r
get_weighted_endemism(data$all_species, data$space)[255:259] # only five sites
#> 628 629 630 631 632 
#>   0   0   0   0   0
```

From loaded files:

``` r
get_weighted_endemism(all_species, space)[255:259] # only five sites
#> 628 629 630 631 632 
#>   0   0   0   0   0
```

- `get_traits_matrix`

This function returns a matrix with traits values of each species in
each site it occupies. In the matrix, rows names indicate the species’
index, and col names indicate the trait or site.

``` r
get_traits_matrix(data$all_species)[1:5,] # only the first five
#>   site  temp                dispersal
#> 1 "841" "0.602343893955346" "1"      
#> 1 "877" "0.603049427753426" "1"      
#> 1 "879" "0.602873050245513" "1"      
#> 1 "912" "0.598723361700469" "1"      
#> 1 "913" "0.599730847101387" "1"
```

Users can also summarize the traits of each species using the
`summarize_fun` argument. It accept functions and named vectors of
functions. In case no names are provided, the function will use the
placeholder “summary” to indicate the function name.

In the observer function:

``` r
get_traits_matrix(data$all_species, summarize_fun = c(
  "mean" = mean, 
  "var_coef" = function(x){
    sd(x)/mean(x)
  }
  )
)
#>    temp_mean temp_var_coef dispersal_mean dispersal_var_coef
#> 1  0.5994269  0.0041257861              1                  0
#> 2  0.7372003  0.0005400367              1                  0
#> 3  0.6654328  0.0004653160              1                  0
#> 4  0.7183894  0.0015728410              1                  0
#> 5  0.6087647  0.0014994325              1                  0
#> 6  0.5572590  0.0032826311              1                  0
#> 7  0.7080964            NA              1                 NA
#> 8  0.6966293  0.0014631700              1                  0
#> 9  0.6848832  0.0009042992              1                  0
#> 10 0.7026039  0.0029176286              1                  0
#> 11 0.6676913  0.0029266811              1                  0
#> 12 0.7077804  0.0018768045              1                  0
```

From loaded files

``` r
get_traits_matrix(all_species, summarize_fun = c(
  "mean" = mean, 
  "var_coef" = function(x){
    sd(x)/mean(x)
  }
  )
)
#>    temp_mean temp_var_coef dispersal_mean dispersal_var_coef
#> 1  0.5994269  0.0041257861              1                  0
#> 2  0.7372003  0.0005400367              1                  0
#> 3  0.6654328  0.0004653160              1                  0
#> 4  0.7183894  0.0015728410              1                  0
#> 5  0.6087647  0.0014994325              1                  0
#> 6  0.5572590  0.0032826311              1                  0
#> 7  0.7080964            NA              1                 NA
#> 8  0.6966293  0.0014631700              1                  0
#> 9  0.6848832  0.0009042992              1                  0
#> 10 0.7026039  0.0029176286              1                  0
#> 11 0.6676913  0.0029266811              1                  0
#> 12 0.7077804  0.0018768045              1                  0
```

- `get_trait_abundance`

This function returns a `data.frame` with site index, traits, abundance,
and species indexes as columns. This is mainly used as internal function
for other purposes, but can also be useful in some cases.

In the observer function:

``` r
get_trait_abundance(data$all_species)[1:5,]
#>   site      temp dispersal abundance species
#> 1  841 0.6023439         1  9.697987       1
#> 2  877 0.6030494         1  9.748367       1
#> 3  879 0.6028731         1  9.544444       1
#> 4  912 0.5987234         1  9.723510       1
#> 5  913 0.5997308         1  9.939520       1
```

From loaded files:

``` r
get_trait_abundance(all_species)[1:5,]
#>   site      temp dispersal abundance species
#> 1  841 0.6023439         1  9.697987       1
#> 2  877 0.6030494         1  9.748367       1
#> 3  879 0.6028731         1  9.544444       1
#> 4  912 0.5987234         1  9.723510       1
#> 5  913 0.5997308         1  9.939520       1
```

- `get_trait_diversity`

Trait diversity is calculated as follows:

``` math

FD_{s,t} = \sum_{i=1}^{n_s} \left( \frac{A_{i,s}}{\sum_{j=1}^{n_s} A_{j,s}} \right) (T_{i,s,t} - \bar{T}_{s,t})^2
```
where - $`A_{i,s}`$ is species $`i`$ abundance in site $`s`$;  
- $`T_{i,s,t}`$ is the value of trait $`t`$ for the species $`i`$ in
site $`s`$;  
- $`\bar{T}_{s,t}`$ is the mean value of trait $`t`$ of the species in
the site $`s`$; - $`n_s`$ is the number of species in the site $`s`$;  
- $`TD_{s,t}`$ is the weighted variance (trait diversity) of trait $`t`$
in site $`s`$.

The function return a matrix with sites as rows and trait diversity in
each site.

In the observer function:

``` r
get_trait_diversity(data$all_species)[1:5,]
#>     temp dispersal
#> 841    0         0
#> 877    0         0
#> 879    0         0
#> 912    0         0
#> 913    0         0
```

From loaded files:

``` r
get_trait_diversity(all_species)[1:5,]
#>     temp dispersal
#> 841    0         0
#> 877    0         0
#> 879    0         0
#> 912    0         0
#> 913    0         0
```

- `get_species_subset`

This function subsets the species list based on a vector of site
indexes. For example, if `site_vector=c("1606")`, it select only the
species that are present in the site “1606”. If `trim_cells=TRUE`, it
will only return information for this site within the `gen3sis_species`
object.

In the observer function:

``` r
get_species_subset(data$all_species, site_vector = c("841"), trim_sites = T)
#> [[1]]
#> $id
#> [1] "1"
#> 
#> $abundance
#>      841 
#> 9.697987 
#> 
#> $traits
#>          temp dispersal
#> 841 0.6023439         1
#> 
#> $divergence
#> $divergence$index
#> 841 877 879 912 913 914 948 949 950 951 984 985 986 
#>   1   1   2   3   4   2   5   6   7   2   8   9  10 
#> 
#> $divergence$compressed_matrix
#>    1 2 3 4 5 6 7 8 9 10
#> 1  0 1 1 1 2 2 2 3 2  2
#> 2  1 0 1 1 2 2 2 3 2  2
#> 3  1 1 0 1 2 2 2 3 2  2
#> 4  1 1 1 0 2 2 2 3 2  2
#> 5  2 2 2 2 0 1 1 1 1  1
#> 6  2 2 2 2 1 0 1 1 1  1
#> 7  2 2 2 2 1 1 0 1 1  1
#> 8  3 3 3 3 1 1 1 0 0  1
#> 9  2 2 2 2 1 1 1 0 0  1
#> 10 2 2 2 2 1 1 1 1 1  0
#> 
#> 
#> attr(,"class")
#> [1] "gen3sis_species"
```

From loaded files:

``` r
get_species_subset(all_species, site_vector = c("841"), trim_sites = T)
#> [[1]]
#> $id
#> [1] "1"
#> 
#> $abundance
#>      841 
#> 9.697987 
#> 
#> $traits
#>          temp dispersal
#> 841 0.6023439         1
#> 
#> $divergence
#> $divergence$index
#> 841 877 879 912 913 914 948 949 950 951 984 985 986 
#>   1   1   2   3   4   2   5   6   7   2   8   9  10 
#> 
#> $divergence$compressed_matrix
#>    1 2 3 4 5 6 7 8 9 10
#> 1  0 1 1 1 2 2 2 3 2  2
#> 2  1 0 1 1 2 2 2 3 2  2
#> 3  1 1 0 1 2 2 2 3 2  2
#> 4  1 1 1 0 2 2 2 3 2  2
#> 5  2 2 2 2 0 1 1 1 1  1
#> 6  2 2 2 2 1 0 1 1 1  1
#> 7  2 2 2 2 1 1 0 1 1  1
#> 8  3 3 3 3 1 1 1 0 0  1
#> 9  2 2 2 2 1 1 1 0 0  1
#> 10 2 2 2 2 1 1 1 1 1  0
#> 
#> 
#> attr(,"class")
#> [1] "gen3sis_species"
```

- `get_space_subset`

This function subsets the space based on a vector of site indexes. For
example, if `site_vector=c("1606","1805")`, it will return the same
space inputed, but with information only for the sites “1606” and
“1805”.

In the observer function:

``` r
get_space_subset(data$space, site_vector = c("841","948"))
#> $id
#> [1] 2
#> 
#> $timestep
#> [1] "-2Ma"
#> 
#> $environment
#>          area    arid      temp
#> 841 0.7435652 1.61136 0.5721426
#> 948 0.6703778 1.89888 0.6072875
#> 
#> $coordinates
#>       x   y
#> 841 -70 -34
#> 948 -72 -40
#> 
#> $extent
#> xmin xmax ymin ymax 
#>  -95  -23  -69   13 
#> 
#> $duration
#> $duration$from
#> [1] -5
#> 
#> $duration$to
#> [1] 0
#> 
#> $duration$by
#> [1] 1
#> 
#> $duration$unit
#> [1] "Ma"
#> 
#> 
#> $geodynamic
#> [1] TRUE
#> 
#> $type
#> [1] "raster"
#> 
#> $type_spec_res
#> [1] 2 2
#> 
#> attr(,"class")
#> [1] "gen3sis_space_raster" "list"
```

From loaded files:

``` r
get_space_subset(space, site_vector = c("841","948"))
#> $id
#> [1] 2
#> 
#> $timestep
#> [1] "-2Ma"
#> 
#> $environment
#>          area    arid      temp
#> 841 0.7435652 1.61136 0.5721426
#> 948 0.6703778 1.89888 0.6072875
#> 
#> $coordinates
#>       x   y
#> 841 -70 -34
#> 948 -72 -40
#> 
#> $extent
#> xmin xmax ymin ymax 
#>  -95  -23  -69   13 
#> 
#> $duration
#> $duration$from
#> [1] -5
#> 
#> $duration$to
#> [1] 0
#> 
#> $duration$by
#> [1] 1
#> 
#> $duration$unit
#> [1] "Ma"
#> 
#> 
#> $geodynamic
#> [1] TRUE
#> 
#> $type
#> [1] "raster"
#> 
#> $type_spec_res
#> [1] 2 2
#> 
#> attr(,"class")
#> [1] "gen3sis_space_raster" "list"
```

## Miscellaneous functions

These functions are design to be used not necessarly inside the
simulation, and serve as multiple purposes.

- `distance_subset`

This function subsets a distance matrix based on a vector of site
indexes. For example, if `site_vector=c("7","15")`, it will return a
distance matrix with information only for sites “7” and “15”.

``` r
distance_matrix <- readRDS(system.file("extdata/TestSpaces/geodynamic_spaces/raster/distances_full/distances_full_4.rds", package = "gen3sis2"))

distance_subset(distance_matrix, site_vector = c("7","15"))
#>           7       15
#> 7     0.000 5629.481
#> 15 5629.481    0.000
```

- `diversification_summary`

This function takes a simulation output object and returns a
`data.frame` with times-steps and calculated Diversification (DR),
Speciation (SR) and Extinction (ER) rates.

``` r
s <- readRDS(system.file("extdata/SouthAmerica/output/sgen3sis.rds",package = "gen3sis2"))

diversification_summary(s)
#>   timestep        DR        SR ER
#> 5        5 0.0000000 0.0000000  0
#> 4        4 0.0000000 0.0000000  0
#> 3        3 0.0000000 0.0000000  0
#> 2        2 0.2000000 0.2000000  0
#> 1        1 0.4166667 0.4166667  0
#> 0        0 0.7058824 0.7058824  0
```

## Contribute with your own functions

`gen3sis2` is built over an open and collaborative science philosophy.
Anyone can contribute to the project. If you have written a function
with a functionality not yet covered by the current support functions,
we encourage you share it with us. Support functions are written in the
R/observations.R file. To know how to contribute to the project, read
the CONTIBUTING.md file.
