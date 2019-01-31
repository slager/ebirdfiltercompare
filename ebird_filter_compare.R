## Install required packages (only do the very first time)
#install.packages('magrittr')
#install.packages('plyr')
#install.packages('dplyr')
#install.packages('rvest')



## Specify portions of filter names to be deleted
filter_prefix <- 'Washington--'
filter_suffix <- ' Count.*'



## Load the required functions
source('functions.R')

## Load required packages (at beginning of each RStudio session)
load_required_packages()

## Get list of filter filenames
get_filenames() -> files

## Export CSV list of regions for manual ordering
export_region_list_for_ordering() -> regions



## Import manually ordered list of regions
import_ordered_region_list() -> ordered_regions

## Check ordered_regions vs. regions for consistency
check_regions()



## Import the latest eBird taxonomy
import_taxonomy() -> tax

## Compile the taxa from the list of filters
compile_taxonomy() -> species

## Pull filter data from the filter HTML files
crunch_filters() -> data
#readRDS("filter_data.RDS") -> data

## Generate a PDF showing filter comparisons across regions
generate_pdf()

## Generate a CSV index to the PDF
generate_index()
