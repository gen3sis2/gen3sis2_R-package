# Contributing to gen3sis2

## 1. How to contribute

The main branches of this repo are:

    master
    development

The master branch should always reflect the state of the current release
of gen3sis2 on CRAN. The development branch contains the working
additions/changes to the code that are to be included in the next
release. You should not work on either of these branches directly.
Rather, to make changes or work on a new feature, you should create a
separate branch off the development branch. While working on your
branch, frequently merge changes from development to stay up to date.
Once your work is ready, and before you merge your branch into
development, make sure to merge any changes from development and verify
the code is compiling and tests are passing. Once these checks have been
done, create a pull request to merge your branch into development. You
can request reviewers for your pull request directly via GitHub. After
your pull request is approved, or if it has not been reviewed within 30
days, it will be merged into development. The branch hotfix-development
exists for small (one commit only) changes that are not worth creating a
new branch for (for instance, small bugfixes, readme or help files
edits, etc.). A pull request can then be created to merge those changes
into development. New features should never be merged directly into
master. Only hotfixes to the current release may be merged into master.
For hotfixes, create a separate branch from master, make the fix and
verify it, and then merge the hotfix branch into master and development.
Similarly to above, the hotfix-master branch exists for small (one
commit only) bugfixes to the current release. A pull request can then be
created to merge those changes into master and development. The gen3sis2
workflow is inspired by the RevBayes workflow:
<https://revbayes.github.io/developer>

## 2. Support functions

One of the main ways to contribute to `gen3sis2` is by writing support
functions. These functions are not essential to the simulation run but
perform specific actions that help the user. They usually retrieve
specific information, such as global mean richness (e.g.,
[`get_mean_richness()`](reference/get_mean_richness.md)), or assist in
constructing useful objects (e.g.,
[`get_presence_matrix()`](reference/get_presence_matrix.md)).

Contributors are encouraged to write new functions that solve any type
of problem—no matter how specific—and share them with the community. For
that reason, we developed a set of guidelines to help developers and
users.

### Support functions guidelines

1.  Support functions must be useful, i.e., they must help retrieve
    information, construct objects, calculate indexes, save outputs,
    etc.  
2.  Support functions are usually short. If your function does many
    things, consider refactoring it into multiple small functions.  
3.  Support functions must be written in the R/observations.R file, in
    the appropriate section (see lexicon below).  
4.  Every support function *must*:
    - Include documentation written in `roxygen2` syntax;  
    - Have tests in the test file
      (`tests/testthat/test-observations.R`);  
    - Have a file with examples stored in the examples directory
      (following the format
      `inst/examples/support_functions/your_support_function.R`).

## 3. `gen3sis2` lexicon

Ambiguous terms should be avoided in `gen3sis2`. For that reason, the
following is presented:

1.  A comprehensive lexicon, i.e., a list of terms and their meanings.
    Contributors should always name things according to this lexicon.
    For example, a “time-step” is an iteration over all simulation
    modules (dispersal, ecology, etc.) and should not be used with other
    meanings.  
2.  A list of current function prefixes. Contributors should use them
    whenever their functions perform actions similar to those
    described.  
3.  A list of notable variables. These are the most important variables
    in `gen3sis2`.

### i) Terms and their meanings

- `gen3sis`: the first version of the gen3sis project’s MEEMs engine.  
- time-step: an iteration over all simulation modules (speciation,
  dispersal, trait evolution, ecology, space modifier).  
- spaces: the organized set of environmental variables and metadata
  distributed across time and space in which the simulation takes
  place.  
- space: refers specifically to the `gen3sis_space_` class object
  containing environmental variables and site coordinates.  
- config: the set of functions and configurations written to control all
  simulation modules.  
- config file: the `.R` file written by the user with the simulation
  configuration.  
- human config: the content of the config file.  
- machine config: a list of functions and other objects obtained after
  the config file code is interpreted, adapted, parsed, and evaluated.  
- simulation state: the state of the simulation at a given time-step,
  including all species, space, config, and derived information. It is
  stored in the `val` variable inside
  [`run_simulation()`](reference/run_simulation.md) and saved to disk
  via the `save_state` argument.  
- simulation output: the summaries of a simulation returned by
  [`run_simulation()`](reference/run_simulation.md).

### ii) Function prefixes

- `get_`: used in functions that retrieve information from the
  simulation state, external sources, or objects. E.g.:
  `get_abundance_matrix`, `get_space_modifier`.  
- `apply_`: used in functions that alter the simulation state by calling
  a process. E.g.: `apply_trait_evolution`, `apply_space_modifier`.  
- `save_`: used for functions that save outputs, states and objects.  
- `run_`: used in functions that orchestrate and execute a complex set
  of processes. E.g.: `run_simulation`.

### iii) Notable variables

- `val`: short for “values”. It is the variable that contains the
  simulation state. It is a list with the `config` and `space`, among
  other components. Every relevant piece of information for `gen3sis2`
  main functions is stored in `val`.  
- `step_time`: a list containing time-related information for the
  config, such as the time unit.  
- `scale_time`: a number indicating how many times the config-timed
  processes should happen in each space time-step.
