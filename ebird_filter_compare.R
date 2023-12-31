####


## Specify portions of filter names to be deleted
filter_prefix <- 'Wisconsin--\\d{2}\\.'
filter_suffix <- ''


####


## Load the required functions
source(file.path('R', 'functions.R'))

## Get list of filter filenames
get_filenames() -> files

## Export CSV list of regions for manual ordering
export_region_list_for_ordering() -> regions


####


## Import manually ordered list of regions
import_ordered_region_list() -> ordered_regions

## Check ordered_regions vs. regions for consistency
check_regions()


####

## Compile the taxa from the list of filters
compile_taxonomy(regions) -> species

## Pull filter data from the filter HTML files
crunch_filters() -> data

## Generate a PDF showing filter comparisons across regions
generate_pdf()

## Generate a CSV index to the PDF
generate_index()
