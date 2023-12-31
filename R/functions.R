
get_filenames <- function(
    path = system.file(
      file.path('extdata', 'filter_htm'),
      package = 'ebirdfiltercompare')){
  ## Get filter filenames
  files <- list.files(path, full.names = TRUE)
  cat("Found",length(files),"filter html files","\n")
  files
}

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

## Load custom-ordered regions created by user
import_ordered_region_list <- function(
    file_path = system.file(
      file.path('extdata', 'ordered_regions.csv'),
      package = 'ebirdfiltercompare')){
  ordered_regions <- read.csv(file_path,stringsAsFactors=F,header=T)[,1]
  cat("Ordered regions CSV imported","\n")
  ordered_regions
}

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
} # end check regions function

## Check that custom region order vector is correct
#regions %in% ordered_regions
#ordered_regions %in% regions

## Crunch the taxonomy

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

## Create nested data structure and crunch the filters
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
} # End crunch_filters

## Make filename-friendly taxon names and taxonomic orders
# tax_output <-
# tax %>%
# dplyr::filter(.data[['comName']] %in% species) %>%
# select(taxonOrder,.data[['comName']]) %>%
# mutate(order = taxonOrder*1000,
#        filename = .data[['comName']] %>%
#                   gsub("[(]","_",.) %>%
#                   gsub("[)]","_",.) %>%
#                   gsub("[/]","_",.) %>%
#                   gsub("[']","_",.) %>%
#                   gsub(" ","_",.)
# )



# Helper functions for X-position of text
date_x <- function(x){c(0,cumsum(x[1:(length(x)-1)]))}
limit_x <- function(x){date_x(x)+x/2}


# Helper function to replace as.character(NA) with "NA"
replaceNA <- function(x){
  x[is.na(x)] <- "NA"
  x
}


# function to generate colors
get_colors <- function(m) {
  colors   <- c("white", "#EDF8E9", "#C7E9C0", "#A1D99B", "#74C476", "#41AB5D",
                "#238B45", "#005A32")
  
  # could also use something like this
  # get_cols <- colorRampPalette(c("white", "darkgreen"))
  # colors <- get_cols(8)
  
  colors   <- colors[findInterval(m, c(0, 1, 6, 11, 51, 101, 1001, 10001, Inf))]
  colors[is.na(colors)] <- "lightgray"
  colors
}



# function to extend matrix with 0s to work around the color limits of barplot
extend_matrix <- function(m) {
  nrow_in <- nrow(m)
  ncol_in <- ncol(m)
  nrow_out <- nrow_in * ncol_in
  out <- matrix(0, ncol = ncol_in, nrow = nrow_out)
  
  starts <- seq(1, nrow_out - nrow_in + 1, by = nrow_in)
  
  for (i in seq_len(ncol_in)) {
    start <- starts[i]
    rows <- start:(start + nrow_in - 1)
    out[rows, i] <- m[, i]
  }
  
  out
}


# Helper function to create pretty pdf height
calc_pdf_height <- function(ordered_regions){
  length(ordered_regions)*(14 - 1.34) / 37 + 1.34
}


# Helper function to create pretty left margin width
calc_left_margin <- function(ordered_regions){
  (ordered_regions %>% nchar %>% max)/12*6
}



# Function to draw main PDF!!
generate_pdf <- function(data, species, ordered_regions){
  cat("Generating PDF...","\n")
  
  grDevices::pdf(paste0("output/taxa.pdf"),onefile=T,width=10,height=calc_pdf_height(ordered_regions)) #Can adjust PDF paper size as needed
  
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
} # End generate_pdf()

## Write CSV version of PDF page number index
generate_index <- function(species){
  1:length(species) -> page_number
  cbind(page_number,taxon=species) %>%
    write.csv("output/pdf_index.csv",row.names=F)
  cat("...done","\n")
} # end generate_index
