library(magrittr)
library(plyr)
library(dplyr)
#library(httr)
library(rvest)
library(parallel)
#library(foreach)
#library(doParallel)
#registerDoParallel(cluster)

## Portions of filter titles to be deleted
filter_prefix <- 'Washington--'
filter_suffix <- ' Count.*'

## Custom order to facilitate comparing similar regions
ordered_regions <- c(
  'Whatcom',
  'Skagit',
  'Snohomish',
  'King',
  'Pierce',
  'Lewis',
  'Thurston',
  'Mason',
  'Kitsap',
  'Island',
  'San Juan',
  'Clallam',
  'Jefferson',
  'Grays Harbor',
  'Pacific',
  'Wahkiakum',
  'Cowlitz',
  'Clark',
  'Skamania',
  'Klickitat',
  'Yakima',
  'Kittitas',
  'Chelan',
  'Okanogan',
  'Douglas',
  'Grant',
  'Lincoln',
  'Adams',
  'Franklin',
  'Benton',
  'Walla Walla',
  'Southeast',
  'Whitman',
  'Spokane',
  'Pend Oreille',
  'Stevens',
  'Ferry')

## Import eBird taxonomy
tax <- read.csv("eBird_Taxonomy_v2016.csv",stringsAsFactors=F)

## Get filter filenames
files <- list.files('filter_htm')
## Read filter region names from HTML
makeCluster(max(1,detectCores()-1),type="FORK") -> cluster
#makeCluster(max(1,detectCores()-1),type="PSOCK") -> cluster #Windows PC
regions <-
  parSapply(cluster,files,function(x){
    read_html(paste0('filter_htm/',x)) %>%
      html_nodes(css='#cl_name') %>% html_text
  }) %>%
  unname %>%
  gsub(filter_prefix,"",.) %>%
  gsub(filter_suffix,"",.)
stopCluster(cluster)

## Check that custom region order vector is correct
#regions %in% ordered_regions
#ordered_regions %in% regions

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

pdf(paste0("output/WA_species.pdf"),onefile=T,10,14)

#s <- "Stilt Sandpiper"   # For testing

for (s in species){

# Get max number of sections for this species
maxn <- sapply(regions,function(x){data[[s]][[x]]$nsections}) %>% max
# Helper function to fill NAs to max number of sections
fillNA <- function(x){c(x,rep(NA,maxn-length(x)))}
# Create barplot matrix
m <- lapply(rev(ordered_regions),function(x){
  fillNA(data[[s]][[x]]$widths)}) %>% do.call(cbind,.)
# Helper functions for X-position of text
date_x <- function(x){c(0,cumsum(x[1:(length(x)-1)]))}
limit_x <- function(x){date_x(x)+x/2}
# Helper function to replace as.character(NA) with "NA"
replaceNA <- function(x){
  "NA" -> x[which(is.na(x))]
  return(x)}

## Functions for implementing individual-species PDFs
#ord <- tax_output %>% filter(PRIMARY_COM_NAME==s) %>% select(order) %>% extract(1,1)
#fnm <- tax_output %>% filter(PRIMARY_COM_NAME==s) %>% select(filename) %>% extract(1,1)
#pdf(paste0("output/",formatC(ord,format='d'),"_",fnm,".pdf"),10,14)

## Barplot
par(mar=c(0.1,6.1,1.1,1.1))
b <- barplot(m,beside=F,horiz=T,axes=F,col=gray(0.85),space=0.6)
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
text(x=50,offset=0,y=max(b)+2.1,labels=s,cex=1.25)
## Draw timestamp
text(x=50,offset=0,y=-1,labels=paste0("Generated ",format(Sys.time(),'%d %B %Y %H:%M:%S')),cex=0.75)
#dev.off() # For individual-taxon PDFs
}
dev.off()

## Write CSV version of PDF page number index
1:length(species) -> page_number
cbind(page_number,taxon=species) %>%
write.csv("output/pdf_index.csv",row.names=F)