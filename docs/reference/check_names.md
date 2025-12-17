# Check names of spaces

Check names of spaces

## Usage

``` r
check_names(reference, datags, error_report = NULL)
```

## Arguments

- reference:

  string with the variable name to be tested, e.g. type, env

- datags:

  list of which `names(datags) is contrastet for reference`

- error_report:

  an error report that increases in case mismatches are found for each
  sub-list. default is NULL

## Value

an error report with the mismatches found
