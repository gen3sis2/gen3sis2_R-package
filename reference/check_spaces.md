# Check gen3sis_spaces

Check gen3sis_spaces

## Usage

``` r
check_spaces(spaces = NULL)
```

## Arguments

- spaces:

  either a gen3sis_spaces object to be checked, or NULL

## Value

If a spaces object is provided, either a stop with printed error report
or a pass statement. If spaces=NULL, this function returns lists of
accepted values categories according to `check_spaces()`

## Examples

``` r
if (FALSE) { # \dontrun{
# checks the structure of the gen3sis_space
check_spaces(your_spaces)

# return a list with accepted types and time units
check_spaces(NULL)
} # }
```
