
#' Get filter html filenames
#'
#' @param path Path to check for filter html files. Defaults to package example.
#'
#' @return Vector of filter html file paths
#' @export
get_filenames <- function(
    path = system.file(
      file.path('extdata', 'filter_htm'),
      package = 'ebirdfiltercompare')){
  ## Get filter filenames
  files <- list.files(path, full.names = TRUE)
  cat("Found",length(files),"filter html files","\n")
  files
}

#' Export regions.csv list for manual ordering
#'
#' @param files Vector of filter html file paths
#' @param filter_prefix Regular expression to exclude from beginning of filter 
#' names
#' @param filter_suffix Regular expression to exclude from end of filter names
#' @param output_directory Directory to output regions.csv file. Silently 
#' created if missing. Defaults to 'output' subfolder in current directory
#'
#' @return Unordered vector of trimmed region names
#' @export
export_region_list_for_ordering <- function(
    files, filter_prefix, filter_suffix, output_directory = 'output'){
  dir.create(output_directory, showWarnings = FALSE, recursive = TRUE)
  output_file <- file.path(output_directory, 'regions.csv')
  cat("Crunching region names from filter files...","\n")
  ## Read filter region names from HTML
  regions <-
    sapply(files,function(x){ # Easily parallelized but not worth it
      (rvest::read_html)(x) %>%
        (rvest::html_nodes)(css='#cl_name') %>% (rvest::html_text)
    }) %>%
    unname |>
    gsub(filter_prefix,"", x = _) |>
    gsub(filter_suffix,"", x = _)
  write.csv(data.frame(REGION_NAME=regions),output_file,row.names=F)
  cat("Regions CSV exported for manual ordering","\n")
  regions
} #end export region list for ordering

#' Load custom-ordered regions created by user
#'
#' @param file_path Path of manually ordered regions CSV file
#'
#' @return Vector of manually ordered region names
#' @export
import_ordered_region_list <- function(
    file_path = system.file(
      file.path('extdata', 'ordered_regions.csv'),
      package = 'ebirdfiltercompare')){
  ordered_regions <- read.csv(file_path,stringsAsFactors=F,header=T)[,1]
  cat("Ordered regions CSV imported","\n")
  ordered_regions
}

#' Check that ordered regions match original regions
#'
#' @param regions Vector of regions
#' @param ordered_regions Vector of ordered regions
#'
#' @return Printed informational statements
#' @export
check_regions <- function(regions, ordered_regions){
  if (!all(regions %in% ordered_regions)){
    message("Error: Not all regions found in ordered regions:")
    print(regions %in% ordered_regions)
  }
  if (!all(ordered_regions %in% regions)){
    message("Error: Not all ordered regions found in regions:")
    print(ordered_regions %in% regions)
  }
  cat("Region name check complete.","\n","Found",length(ordered_regions),"ordered regions:","\n")
  print(ordered_regions)
  invisible(NULL)
}

#' Crunch the taxonomy
#'
#' @param files Vector of html file paths to crunch
#' @param regions Vector of region names to crunch, matching order of files
#' @param tax eBird taxonomy to use. Defaults to current taxonomy object from package
#' rebird
#'
#' @return Vector of species names found across the provided filters
#' @export
compile_taxonomy <- function(files, regions, tax = rebird:::tax){
  cat("Compiling taxonomy...","\n")
  ## Get full taxa list from each filter
  taxa <- sapply(regions,function(x) NULL)
  for (i in 1:length(files)){
    taxa[[regions[i]]] <-
      rvest::read_html(files[i]) %>%
      rvest::html_nodes(css='div[class="snam"]') %>%
      (rvest::html_text)
  }
  
  ## Collect unique taxa
  species_from_filters <- taxa |> Reduce(f = c, x = _) %>% unique
  
  ## Get list of unique taxa in taxonomic order
  species <-
    tax %>%
    dplyr::filter(.data[['comName']] %in% species_from_filters) %>%
    dplyr::pull(.data[['comName']])
  
  cat("...done","\n")
  species
} # end compile taxonomy function

#' Create nested data structure and crunch the filters
#'
#' @param files Vector of filter html files to crunch
#' @param species Vector of species names to crunch
#' @param ordered_regions Ordered vector of regions, as desired in output
#' @param filter_prefix Regular expression to remove from beginning of filter
#' names
#' @param filter_suffix Regular expression to remove from end of filter names
#' @param tax eBird taxonomy to use. Defaults to current taxonomy object from package
#' rebird
#' @return Nested list containing structured filter information
#' @export
crunch_filters <- function(files, species, ordered_regions, filter_prefix, filter_suffix, tax = rebird:::tax){
  cat("Preparing data structure...","\n")
  ## Create nested data structure
  filter_data <-
    lapply(species,function(x){
      lapply(ordered_regions,function(x){
        list(
          widths=100,
          dates="Jan 1",
          limits=as.integer(NA),
          nsections=1L)
      }) %>% setNames(ordered_regions)
    }) %>% setNames(species)
  ## Fill with data from filters
  cat("Started crunching filters at",paste(Sys.time()),"\n")
  cat(length(files),"filters to crunch","\n")
  0 -> tracker
  ## For each filter...
  for (file in files){
    Sys.time() -> begin_time
    html <- rvest::read_html(file)
    r <- # Region name
      html %>%
      rvest::html_nodes(css='#cl_name') %>%
      (rvest::html_text) %>%
      unname |>
      gsub(filter_prefix,"", x = _) |>
      gsub(filter_suffix,"", x = _)
    species_list <- # Species list for region
      html %>%
      rvest::html_nodes(css='div[class="snam"]') %>%
      (rvest::html_text)
    codes <- # Get species codes from eBird Taxonomy
      tax %>% dplyr::filter(.data[['comName']] %in% species_list) %>% dplyr::pull(.data[['speciesCode']])
    for (i in 1:length(codes)){
      ## Use CSS selectors to scrape data from HTML
      # Save nodeset1
      nodeset1 <- html %>% rvest::html_nodes(css=paste0('#',codes[i],'_out'))
      widths <- nodeset1 %>%
        rvest::html_nodes(css='td[style]') %>%
        rvest::html_attr('style') |>
        gsub('width:',"", x = _) |>
        gsub('%',"", x = _) %>%
        as.numeric
      if (length(widths) >0){
        filter_data[[species_list[i]]][[r]][['widths']] <- widths
      }
      dates <- nodeset1 %>%
        rvest::html_nodes(css='.dt') %>%
        (rvest::html_text)
      if (length(dates) > 0){
        filter_data[[species_list[i]]][[r]][['dates']] <- dates
      }
      # Save nodelim
      nodelim <- rvest::html_nodes(nodeset1,css='input[class^="lim"]')
      if (length(nodelim) > 0){
        limits <- nodelim %>% rvest::html_attr('value')
      } else {
        limits <- rvest::html_nodes(nodeset1,css='span[class^="lim"]') %>%
          (rvest::html_text)
      }
      limits <- as.numeric(limits)
      if (length(limits) > 0){
        filter_data[[species_list[i]]][[r]][['limits']] <- limits
      }
      filter_data[[species_list[i]]][[r]][['nsections']] <- length(filter_data[[species_list[i]]][[r]][['limits']])
    }
    tracker + 1 -> tracker
    Sys.time() -> end_time
    if (tracker==1){
      cat("It took",as.numeric(difftime(end_time,begin_time,units="secs")),"sec to crunch 1 filter","\n")
      cat("Estimated",as.numeric(difftime(end_time,begin_time,units="mins")*length(files)),"min to crunch all filters","\n")
    }
    cat(tracker,"filters crunched","\n")
  } # End big for loop for crunching
  
  filter_data
}


#' Function to draw main PDF
#'
#' @param data Nested list containing structured filter information
#' @param species Vector of species names present across all the filters
#' @param ordered_regions Ordered vector of regions, as desired in output
#' @param output_directory Directory to output PDF file. Defaults to 'output'. 
#' Silently created if missing.
#'
#' @return Nothing. Side effect is taxa.pdf is written to output directory
#' @export
generate_pdf <- function(
    data, species, ordered_regions,
    output_directory = 'output'){
  dir.create(output_directory, showWarnings = FALSE, recursive = TRUE)
  output_file <- file.path(output_directory, 'taxa.pdf')
  cat("Generating PDF...","\n")
  
  grDevices::pdf(output_file,onefile=T,width=10,height=calc_pdf_height(ordered_regions)) #Can adjust PDF paper size as needed
  
  #s <- "Stilt Sandpiper"   # For testing
  
  for (s in species){
    
    # Get max number of sections for this species
    maxn <- sapply(ordered_regions,function(x){data[[s]][[x]]$nsections}) %>% max
    # Helper function to fill NAs to max number of sections
    fillNA <- function(x){c(x,rep(NA,maxn-length(x)))}
    # Create barplot matrix
    m <- lapply(rev(ordered_regions),function(x){
      fillNA(data[[s]][[x]]$widths)}) |> do.call(cbind, args = _)
    
    # matrix of limits used to select colors
    limits <- lapply(rev(ordered_regions),function(x){
      fillNA(data[[s]][[x]]$limits)}) |> do.call(cbind, args = _)
    
    
    ## Functions for implementing individual-species PDFs
    #ord <- tax_output %>% dplyr::filter(.data[['comName']]==s) %>% select(order) %>% extract(1,1)
    #fnm <- tax_output %>% dplyr::filter(.data[['comName']]==s) %>% select(filename) %>% extract(1,1)
    #pdf(paste0("output/",formatC(ord,format='d'),"_",fnm,".pdf"),10,14)
    
    ## Barplot
    graphics::par(mar=c(1.1,calc_left_margin(ordered_regions),2.1,1.1)) #Can adjust left margin value (6.1) higher if your region mames are long
    colors <- get_colors(limits)
    m_extend <- extend_matrix(m)
    b <- graphics::barplot(m_extend,beside=F,horiz=T,axes=F,col=colors,space=0.6)
    graphics::mtext(rev(ordered_regions),side=2,at=b,las=2)
    
    for (i in 1:length(ordered_regions)){
      ## Draw date labels
      graphics::text(
        x = date_x(data[[s]][[rev(ordered_regions)[i]]]$widths),
        y = b[i] + (b[2]-b[1])*.45,
        labels = data[[s]][[rev(ordered_regions)[i]]]$dates,
        pos=4,offset=0,cex=0.6)
      ## Draw filter limits
      graphics::text(
        x = limit_x(data[[s]][[rev(ordered_regions)[i]]]$widths),
        y = b[i],
        labels= replaceNA(data[[s]][[rev(ordered_regions)[i]]]$limits), #can remove replaceNA after adjusting code elsewhere
        cex=0.8)
    }
    
    ## Draw taxon title
    graphics::mtext(side=3,at=50,text=s,cex=1.25)
    
    ## Draw timestamp
    graphics::mtext(side=1,at=50,text=paste0("Generated ",format(Sys.time(),'%d %B %Y %H:%M:%S')),cex=0.75)
    #dev.off() # For individual-taxon PDFs
  }
  grDevices::dev.off()
  cat("...done","\n")
  invisible(NULL)
}

#' Write CSV version of PDF page number index
#'
#' @param species Vector of species names found across the filters
#' @param output_directory Directory to write the species index CSV. Silently
#' created if missing.
#'
#' @return Nothing. Side effect is the index CSV file written to the output
#' directory.
#' @export
generate_index <- function(species, output_directory = 'output'){
  dir.create(output_directory, showWarnings = FALSE, recursive = TRUE)
  output_file <- file.path(output_directory, 'pdf_index.csv')
  1:length(species) -> page_number
  cbind(page_number,taxon=species) %>%
    write.csv(output_file,row.names=F)
  cat("...done","\n")
  invisible(NULL)
}
