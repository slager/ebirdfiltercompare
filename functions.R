## Install required packages (if needed)
#install.packages('magrittr')
#install.packages('plyr')
#install.packages('dplyr')
#install.packages('rvest')

load_required_packages <- function(){
## Load required packages
library(magrittr)
library(plyr)
library(dplyr,warn.conflicts=F)
library(rvest)
cat("...done","\n")
}

# Portions of filter titles to be deleted (Uncomment if not in function mode)
#filter_prefix <- 'Washington--'
#filter_suffix <- ' Count.*'

get_filenames <- function(){
## Get filter filenames
files <- list.files('filter_htm')
files
}

export_region_list_for_ordering <- function(){
cat("Crunching region names from filter files...","\n")
## Read filter region names from HTML
regions <-
  sapply(files,function(x){ # Easily parallelized but not worth it
    read_html(paste0('filter_htm/',x)) %>%
      html_nodes(css='#cl_name') %>% html_text
  }) %>%
  unname %>%
  gsub(filter_prefix,"",.) %>%
  gsub(filter_suffix,"",.)
write.csv(data.frame(REGION_NAME=regions),'regions.csv',row.names=F)
cat("Regions CSV exported for manual ordering","\n")
regions
} #end export region list for ordering

## Load custom-ordered regions created by user
import_ordered_region_list <- function(){
ordered_regions <- read.csv('ordered_regions.csv',stringsAsFactors=F,header=T)[,1]
cat("Ordered regions CSV imported","\n")
ordered_regions
}

check_regions <- function(){
  if (!all(regions %in% ordered_regions)){
    message("Not all regions found in ordered regions:")
    print(regions %in% ordered_regions)
  }
  if (!all(ordered_regions %in% regions)){
    message("Not all ordered regions found in regions:")
    print(ordered_regions %in% regions)
  }
  cat("Region name check complete.","\n","Found",length(ordered_regions),"ordered regions:","\n")
  print(ordered_regions)
} # end check regions function

## Check that custom region order vector is correct
#regions %in% ordered_regions
#ordered_regions %in% regions

## Crunch the taxonomy

import_taxonomy <- function(){
## Import eBird taxonomy
cat("...done","\n")
read.csv(taxonomy_filename,stringsAsFactors=F)
}

compile_taxonomy <- function(){
cat("Compiling taxonomy...","\n")
## Get full taxa list from each filter
taxa <- sapply(regions,function(x) NULL)
for (i in 1:length(files)){
    taxa[[regions[i]]] <-
      read_html(paste0('filter_htm/',files[i])) %>%
      html_nodes(css='div[class="snam"]') %>%
      gsub('<div class="snam">',"",.) %>%
      gsub(' <em.*',"",.) %>%
      gsub('</div>',"",.)
}

## Collect unique taxa
species_from_filters <- taxa %>% Reduce(c,.) %>% unique

## Get list of unique taxa in taxonomic order
species <-
  tax %>%
  filter(PRIMARY_COM_NAME %in% species_from_filters) %>%
  use_series(PRIMARY_COM_NAME)

cat("...done","\n")
species
} # end compile taxonomy function

## Create nested data structure and crunch the filters
crunch_filters <- function(){
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
  html <- read_html(paste0('filter_htm/',file))
  r <- # Region name
    html %>%
    html_nodes(css='#cl_name') %>%
    html_text %>%
    unname %>%
    gsub(filter_prefix,"",.) %>%
    gsub(filter_suffix,"",.)
  species_list <- # Species list for region
    html %>%
    html_nodes(css='div[class="snam"]') %>%
    gsub('<div class="snam">',"",.) %>%
    gsub(' <em.*',"",.) %>%
    gsub('</div>',"",.)
  codes <- # Get species codes from eBird Taxonomy
    tax %>% filter(PRIMARY_COM_NAME %in% species_list) %>% use_series(SPECIES_CODE)
  for (i in 1:length(codes)){
    ## Use CSS selectors to scrape data from HTML
    # Save nodeset1
    nodeset1 <- html %>% html_nodes(css=paste0('#',codes[i],'_out'))
    filter_data[[species_list[i]]][[r]][['widths']] <-
      nodeset1 %>%
      html_nodes(css='td[style]') %>%
      html_attr('style') %>%
      gsub('width:',"",.) %>%
      gsub('%',"",.) %>%
      as.numeric
    filter_data[[species_list[i]]][[r]][['dates']] <-
      nodeset1 %>%
      html_nodes(css='.dt') %>%
      html_text
    # Save nodelim
    nodelim <- html_nodes(nodeset1,css='input[class^="lim"]')
    filter_data[[species_list[i]]][[r]][['limits']] <-
      nodeset1 %>%
      { if (length(nodelim) > 0){
        nodelim %>% html_attr('value')
        } else {
        html_nodes(.,css='span[class^="lim"]') %>% html_text}
      } %>%
      as.numeric
    filter_data[[species_list[i]]][[r]][['nsections']] <- length(filter_data[[species_list[i]]][[r]][['limits']])
  }
  tracker + 1 -> tracker
  Sys.time() -> end_time
  if (tracker==1){
    cat("It took",as.numeric(difftime(end_time,begin_time)),"sec to crunch 1 filter","\n")
    cat("Estimated",as.numeric(difftime(end_time,begin_time,units="mins")*length(files)),"min to crunch all filters","\n")
  }
  cat(tracker,"filters crunched","\n")
  } # End big for loop for crunching

## Save the data that took so long to scrape together
saveRDS(filter_data,"filter_data.RDS")
filter_data
#readRDS("filter_data.RDS") #Load the file
} # End crunch_filters

## Make filename-friendly taxon names and taxonomic orders
# tax_output <-
# tax %>%
# filter(PRIMARY_COM_NAME %in% species) %>%
# select(TAXON_ORDER,PRIMARY_COM_NAME) %>%
# mutate(order = TAXON_ORDER*1000,
#        filename = PRIMARY_COM_NAME %>%
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
calc_pdf_height <- function(){
  length(files)*(14 - 1.34) / 37 + 1.34
}


# Helper function to create pretty left margin width
calc_left_margin <- function(){
  (ordered_regions %>% nchar %>% max)/12*6
}



# Function to draw main PDF!!
generate_pdf <- function(){
cat("Generating PDF...","\n")

pdf(paste0("output/taxa.pdf"),onefile=T,width=10,height=calc_pdf_height()) #Can adjust PDF paper size as needed

#s <- "Stilt Sandpiper"   # For testing

for (s in species){

# Get max number of sections for this species
maxn <- sapply(regions,function(x){data[[s]][[x]]$nsections}) %>% max
# Helper function to fill NAs to max number of sections
fillNA <- function(x){c(x,rep(NA,maxn-length(x)))}
# Create barplot matrix
m <- lapply(rev(ordered_regions),function(x){
  fillNA(data[[s]][[x]]$widths)}) %>% do.call(cbind,.)

# matrix of limits used to select colors
limits <- lapply(rev(ordered_regions),function(x){
  fillNA(data[[s]][[x]]$limits)}) %>% do.call(cbind,.)


## Functions for implementing individual-species PDFs
#ord <- tax_output %>% filter(PRIMARY_COM_NAME==s) %>% select(order) %>% extract(1,1)
#fnm <- tax_output %>% filter(PRIMARY_COM_NAME==s) %>% select(filename) %>% extract(1,1)
#pdf(paste0("output/",formatC(ord,format='d'),"_",fnm,".pdf"),10,14)

## Barplot
par(mar=c(1.1,calc_left_margin(),2.1,1.1)) #Can adjust left margin value (6.1) higher if your region mames are long
colors <- get_colors(limits)
m_extend <- extend_matrix(m)
b <- barplot(m_extend,beside=F,horiz=T,axes=F,col=colors,space=0.6)
mtext(rev(ordered_regions),side=2,at=b,las=2)

for (i in 1:length(regions)){
  ## Draw date labels
  text(
    x = date_x(data[[s]][[rev(ordered_regions)[i]]]$widths),
    y = b[i] + (b[2]-b[1])*.45,
    labels = data[[s]][[rev(ordered_regions)[i]]]$dates,
    pos=4,offset=0,cex=0.6)
  ## Draw filter limits
  text(
    x = limit_x(data[[s]][[rev(ordered_regions)[i]]]$widths),
    y = b[i],
    labels= replaceNA(data[[s]][[rev(ordered_regions)[i]]]$limits), #can remove replaceNA after adjusting code elsewhere
    cex=0.8)
}

## Draw taxon title
mtext(side=3,at=50,text=s,cex=1.25)

## Draw timestamp
mtext(side=1,at=50,text=paste0("Generated ",format(Sys.time(),'%d %B %Y %H:%M:%S')),cex=0.75)
#dev.off() # For individual-taxon PDFs
}
dev.off()
cat("...done","\n")
} # End generate_pdf()

## Write CSV version of PDF page number index
generate_index <- function(){
1:length(species) -> page_number
cbind(page_number,taxon=species) %>%
write.csv("output/pdf_index.csv",row.names=F)
cat("...done","\n")
} # end generate_index
