# Check if the used time unit is accepted

Check if the used time unit is accepted

## Usage

``` r
time_unit_check(time_unit = NULL)
```

## Arguments

- time_unit:

  character. The used time unit. If NULL, returns a vector of accepted
  time units.

## Value

if time_unit is character, return TRUE or FALSE. If time_unit = NULL,
returns a vector of accepted time units.

## Examples

``` r
if (FALSE) { # \dontrun{
  # return TRUE
  time_unit_check("a")
  time_unit_check("ka")
  time_unit_check("Ma")
  time_unit_check("Ga")
  time_unit_check("timestep")
  
  # return FALSE
  time_unit_check("eons")
} # }
```
