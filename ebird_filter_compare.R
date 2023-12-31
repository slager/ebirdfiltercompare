## Specify portions of filter names to be deleted
filter_prefix <- 'Wisconsin--\\d{2}\\.'
filter_suffix <- ''

## Get list of filter filenames
get_filenames() -> files

## Export CSV list of regions for manual ordering
export_region_list_for_ordering(files, filter_prefix, filter_suffix) -> regions

## Import manually ordered list of regions
import_ordered_region_list() -> ordered_regions

## Check ordered_regions vs. regions for consistency
check_regions(regions, ordered_regions)

## Compile the taxa from the list of filters
compile_taxonomy(files, regions) -> species

## Pull filter data from the filter HTML files
crunch_filters(files, species, ordered_regions, filter_prefix, filter_suffix) -> data

## Generate a PDF showing filter comparisons across regions
generate_pdf(data, species, ordered_regions)

## Generate a CSV index to the PDF
generate_index(species)
