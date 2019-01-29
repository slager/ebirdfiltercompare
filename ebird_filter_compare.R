## Required packages
library(magrittr)
library(plyr)
library(dplyr)
#library(httr)
library(rvest)
library(parallel)
#library(foreach)
#library(doParallel)
#registerDoParallel(cluster)

# Portions of filter titles to be deleted
filter_prefix <- 'Washington--'
filter_suffix <- ' Count.*'

## Get filter filenames
files <- list.files('filter_htm')
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

## Custom order to facilitate comparing similar regions
ordered_regions <- read.csv('ordered_regions.csv',stringsAsFactors=F,header=T)[,1]

## Import eBird taxonomy
tax <- read.csv("eBird_Taxonomy_v2018_14Aug2018.csv",stringsAsFactors=F)

## Check that custom region order vector is correct
regions %in% ordered_regions
ordered_regions %in% regions

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

## Create nested data structure
data <-
lapply(species,function(x){
  lapply(ordered_regions,function(x){
    list(
      widths=100,
      dates="Jan 1",
      limits=as.integer(NA),
      nsections=1L)
  }) %>% setNames(regions)
}) %>% setNames(species)


## Fill with data from filters
system.time( #(Takes 1/2 hour -- Should parallelize/make more efficient code)
## For each filter...
for (file in files){
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
    data[[species_list[i]]][[r]][['widths']] <-
      html %>%
      html_nodes(css=paste0('#',codes[i],'_out')) %>%
      html_nodes(css='td[style]') %>%
      html_attr('style') %>%
      gsub('width:',"",.) %>%
      gsub('%',"",.) %>%
      as.numeric
    data[[species_list[i]]][[r]][['dates']] <-
      html %>%
      html_nodes(css=paste0('#',codes[i],'_out')) %>%
      html_nodes(css='.dt') %>%
      html_text
    data[[species_list[i]]][[r]][['limits']] <-
      html %>%
      html_nodes(css=paste0('#',codes[i],'_out')) %>%
      #html_nodes(css='input[class^="lim"], span[class^="lim"]') %>%
      { if (length(html_nodes(.,css='input[class^="lim"]')) > 0){
        html_nodes(.,css='input[class^="lim"]') %>% html_attr('value')
        } else {
        html_nodes(.,css='span[class^="lim"]') %>% html_text}
      } %>%
      as.numeric
    data[[species_list[i]]][[r]][['nsections']] <- length(data[[species_list[i]]][[r]][['limits']])
      }} # End big for loop
) # sys.time closure

## Save the data that took so long to scrape together
saveRDS(data,"filter_data.RDS")
#readRDS("filter_data.RDS") -> data #Load the file

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

pdf(paste0("output/taxa.pdf"),onefile=T,10,14) #Can adjust PDF paper size as needed

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
par(mar=c(1.1,6.1,2.1,1.1)) #Can adjust left margin value (6.1) higher if your region mames are long
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

## Write CSV version of PDF page number index
1:length(species) -> page_number
cbind(page_number,taxon=species) %>%
write.csv("output/pdf_index.csv",row.names=F)
