![](./man/figures/gen3sis_logo.png)

[![Contributors](https://img.shields.io/github/contributors/gen3sis2/gen3sis2_R-package)](https://github.com/gen3sis2/gen3sis2_R-package/graphs/contributors)

# General Engine for Eco-Evolutionary Simulations

This is the repository for the R-package of the gen3sis engine [project-gen3sis git](https://github.com/project-gen3sis/R-package).

gen3sis is a spatially-explicit eco-evolutionary mechanistic model with a modular implementation. It allows exploring the consequences of ecological and macroevolutionary processes across realistic or theoretical spatio-temporal spaces.

gen3sis is licensed under a [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.html) deriving from ETHZ 2020 <doi.org/10.5905/ethz-1007-251> and has package authorship according to: http://epub.wu.ac.at/3269/1/Report114.pdf

### How to cite
* O Hagen, B Flueck, F Fopp, JS Cabral, F Hartig, M Pontarp, TF Rangel, L Pellissier (2021) gen3sis: A general engine for eco-evolutionary simulations of the processes that shape Earth’s biodiversity. PLOS Biology. [doi:10.1371/journal.pbio.3001340](https://doi.org/10.1371/journal.pbio.3001340)


### How to install

<!---gen3sis is avabaile on [CRAN](https://CRAN.R-project.org/package=gen3sis). You can install the latest CRAN release via

```{r}
install.packages("gen3sis")
```
--->
you can install the latest development release from GitHub via 

```
devtools::install_github(repo = "ohagen/gen3sis_rf", dependencies = TRUE, build_vignettes = TRUE)
```

Below the status of the automatic CI R-CMD-check tests for the main branches:

- DEVELOPMENT [![R-CMD-check](https://github.com/ohagen/gen3sis_rf/actions/workflows/R-CMD-check.yaml/badge.svg?branch=development)](https://github.com/ohagen/gen3sis_rf/actions/workflows/R-CMD-check.yaml?query=branch%3Adevelopment)

- MASTER [![R-CMD-check](https://github.com/ohagen/gen3sis_rf/actions/workflows/R-CMD-check.yaml/badge.svg?branch=master)](https://github.com/ohagen/gen3sis_rf/actions/workflows/R-CMD-check.yaml)

### How to use

#### Run one simulation

Load and run a simulation with the desired config and spaces. Example data is provided with the package.

```
library("gen3sis2")

spaces <- system.file(file.path("extdata", "TestSpaces","geostatic_spaces","raster"), package="gen3sis2")
config_file <- system.file(file.path("extdata", "TestConfigs","TestConfig.R"), package="gen3sis2")

sim <- run_simulation(
  config = config_file, 
  space = spaces,
  output_directory = tempdir(),
  verbose = 0
)
```

A summary statistics is stored at 'sim' more data can be save using the observer function

####  Visualize a simulation

Plot the summary statistics of a simulation

```
plot_summary(sim)
```

#### Check installed version

Make sure you have the latest gen3sis version

```
#print package version
paste("gen3sis2 version:", packageVersion("gen3sis2"))
```

### How to contribute

Great that you are considering contributing! We welcome contributions from the community, whether they are bug fixes, new features, documentation improvements, or anything else that can help improve the package. Feel free to also reach out over e-mail to discuss ideas.
For guidelines on contributing to this project, please refer to the [CONTRIBUTING.md](./CONTRIBUTING.md) file. In short, the main branches of this repo are:

- **master** – reflects the current CRAN release (if at all). Only hotfixes or release-ready changes are merged here, typically just before CRAN submission.
- **development** – serves as the main working branch. All new features, improvements, and fixes should be merged here from separate feature or bugfix branches.


### Credits
We thank the developers of the following methods and dependencies:

- **Rcpp** Dirk Eddelbuettel and James Joseph Balamuta (2018). Extending R with C++: A Brief Introduction to Rcpp. The American Statistician. 72(1). URL https://doi.org/10.1080/00031305.2017.1375990.

- **BH** Dirk Eddelbuettel, John W. Emerson and Michael J. Kane (2021). BH: Boost C++ Header Files. R package. https://CRAN.R-project.org/package=BH

- **Matrix** Bates D, Maechler M, Jagan M (2025). Matrix: Sparse and Dense Matrix Classes and Methods. R package. https://CRAN.R-project.org/package=Matrix

- **tidyterra** Hernangómez D. (2023). Using the tidyverse with terra objects: the tidyterra package. https://doi.org/10.21105/joss.05751

- **terra** Hijmans R, Brown A, Barbosa M (2026). terra: Spatial Data Analysis  https://cran.r-project.org/web/packages/terra/index.html

- **h3jsr** O'Brien L. (2023). h3jsr: Access Uber's H3 Library. https://CRAN.R-project.org/package=h3jsr

- **sf** Pebesma E. (2018). Simple Features for R: Standardized Support for Spatial Vector Data. https://r-spatial.github.io/sf/

- **igraph** Csárdi G., Nepusz T. (2006). The igraph software package for complex network research. https://igraph.org>

- **sp** Roger S. Bivand, Edzer Pebesma, Virgilio Gomez-Rubio, 2013. Applied spatial data analysis with R, Second edition. Springer, NY. https://asdar-book.org/

- **stringr** Wickham H (2025). stringr: Simple, Consistent Wrappers for Common String Operations. https://CRAN.R-project.org/package=stringr

- **ggplot2** Wickham H. (2016). https://ggplot2.tidyverse.org

- **scales** Wickham H., Pedersen T., Seidel D. (2025). scales: Scale Functions for Visualization. https://CRAN.R-project.org/package=scales

- **patchwork** Pedersen T. (2025). patchwork: The Composer of Plots. https://CRAN.R-project.org/package=patchwork

- **testthat** Wickham H. (2011). testthat: Get Started with Testing. The R Journal, vol. 3, no. 1, pp. 5--10, https://journal.r-project.org/archive/2011-1/RJournal_2011-1_Wickham.pdf

- **formatR** Yihui Xie (2021). formatR: Format R Code Automatically. R package. https://CRAN.R-project.org/package=formatR

- **scico** Crameri, F. (2018). Scientific colour maps. Zenodo. http://doi.org/10.5281/zenodo.1243862 & Crameri, F., G.E. Shephard, and P.J. Heron (2020). The misuse of colour in science communication, Nature Communications, 11, 5444. doi:10.1038/s41467-020-19160-7

## Contributors



<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

All contributions to this project are gratefully acknowledged using the [`allcontributors` package](https://github.com/ropensci/allcontributors) following the [allcontributors](https://allcontributors.org) specification. Contributions of any kind are welcome!

<table>

<tr>
<td align="center">
<a href="https://github.com/ohagen">
<img src="https://avatars.githubusercontent.com/u/17259233?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=ohagen">ohagen</a>
</td>
<td align="center">
<a href="https://github.com/AdmirJr">
<img src="https://avatars.githubusercontent.com/u/102635734?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=AdmirJr">AdmirJr</a>
</td>
<td align="center">
<a href="https://github.com/benj919">
<img src="https://avatars.githubusercontent.com/u/926479?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=benj919">benj919</a>
</td>
<td align="center">
<a href="https://github.com/florianhartig">
<img src="https://avatars.githubusercontent.com/u/5457753?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=florianhartig">florianhartig</a>
</td>
<td align="center">
<a href="https://github.com/loic-pellissier">
<img src="https://avatars.githubusercontent.com/u/62331405?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=loic-pellissier">loic-pellissier</a>
</td>
</tr>


<tr>
<td align="center">
<a href="https://github.com/bouwerutger">
<img src="https://avatars.githubusercontent.com/u/44290366?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=bouwerutger">bouwerutger</a>
</td>
<td align="center">
<a href="https://github.com/gen3sis2">
<img src="https://avatars.githubusercontent.com/u/41071747?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=LewisAJones">LewisAJones</a>
</td>
<td align="center">
<a href="https://github.com/yihui">
<img src="https://avatars.githubusercontent.com/u/163582?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=yihui">yihui</a>
</td>
<td align="center">
<a href="https://github.com/FFopp">
<img src="https://avatars.githubusercontent.com/u/62299258?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=FFopp">FFopp</a>
</td>
<td align="center">
<a href="https://github.com/mmore500">
<img src="https://avatars.githubusercontent.com/u/10763333?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=mmore500">mmore500</a>
</td>
</tr>


<tr>
<td align="center">
<a href="https://github.com/ZHG2017">
<img src="https://avatars.githubusercontent.com/u/31282190?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=ZHG2017">ZHG2017</a>
</td>
<td align="center">
<a href="https://github.com/cakloecker">
<img src="https://avatars.githubusercontent.com/u/62482275?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=cakloecker">cakloecker</a>
</td>
<td align="center">
<a href="https://github.com/cndesantana">
<img src="https://avatars.githubusercontent.com/u/5500983?v=4" width="100px;" alt=""/>
</a><br>
<a href="https://github.com/gen3sis2/gen3sis2_R-package/commits?author=cndesantana">cndesantana</a>
</td>
</tr>

</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->


