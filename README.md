## This script is designed to be used by eBird Regional Editors to easily visualize differences among taxa filters in your regions.

![BTYW example](https://github.com/slager/ebird_filter_compare/blob/master/inst/img/btyw.png)

------------------------------------------------------------------------

## 1. Setup R and RStudio

### 2a. [Download and install R](https://cran.r-project.org/).

This step is only necessary if you have not previously installed R on your computer. You'll first follow the above link to your operating system (Windows, Mac, or Linux). Windows users will want to click on the link for the "base" version, and Mac users will want to click the version named R-3.x.x.pkg. Once the file downloads, install it on your computer the way you normally would.

### 2b. Download and install [R Studio](https://www.rstudio.com/).

This is only necessary if you don't already have RStudio on your computer. Select the version that corresponds to your operating system, and install it the way you normally would.

### 2c. Create and open an RStudio project

Open RStudio, select File \> New Project..., choose "New Directory", and create a new folder (e.g., on your Desktop) to work in. Press the "Create Project" button. The project will either open automatically, or you can open it by double-clicking on the Rproj file.

## 2. Install the eBird filter compare package

Install the `remotes` package if you haven't already:
```
installed <- rownames(installed.packages())
if (!"remotes" %in% installed)
  install.packages("remotes")
```

Install the `ebirdfiltercompare` package from this GitHub repository

```
remotes::install_github('slager/ebirdfiltercompare', build_vignettes = TRUE)
```

Load the package
```
library(ebirdfiltercompare)
```

## 3. Continue with the instructions in the vignette

There are two options for how to view the vignette

To launch an HTML vignette in your browser, run this line and then click on 'HTML' in the resulting window.
```
browseVignettes('ebirdfiltercompare')
```

To launch a vignette inside Rstudio, run this line:

```
vignette('ebirdfiltercompare')
```
