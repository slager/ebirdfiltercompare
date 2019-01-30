<strong>This script is designed to be used by eBird Regional Editors to easily visualize differences among taxa filters in your regions.</strong>
 
To get the files, click "Clone or Download" above, then go find the zipped file on your computer, and unzip the contents into a new folder, which is by default named "ebird_filter_compare-master".

You will need R or R Studio to run this script, so install one of those programs if you have not (R Studio is a bit friendlier).

-------------------------------------------------------------------------------------------------------------------
<strong>First, set up the files you'll need</strong>

<em>Note: The download comes pre-loaded with files for Washington State, USA. If you run it as is for practice, you'll get a nice full-size chart, but it will take a half hour to run. If you'd like to practice, we suggest deleting all but 3 filters in the filter folder and list (you will learn about this below) and running it like that. It will be a shorter run, and the output will not look as nice, but you'll know it's working. If you have no interest in practice and want to jump into action, you can ignore running it with practice Washington data and skip straight to replacing these lines with your regional files as directed below.</em>
 
<strong>1. Check to see if the eBird Taxonomy is current.</strong> Make sure the folder (ebird_filter_compare-master) contains the current eBird taxonomy in csv format (e.g. eBird_Taxonomy_v2018_14Aug2018.csv). This readme was written in early 2019, so as of this writing, if it is after August 2019, you will have to download the new taxonomy.

<strong>2. Download the eBird filters for your region.</strong> There is a subfolder called filter_htm where you will need to save a copy of your current eBird filters. Note that right now this is full of Washington State, USA filter files if you want to use those for a test run, but you should replace it with your own files when ready to run the script for your region. To run it for your region, first delete all the example files from the folder. Then, using Google Chrome or Mozilla Firefox, log in to eBird Admin, and go to the filters tab. To download each one:
Right-click on filter page > "View Page Source"
File > Save Page As
Select 'Webpage, HTML Only'
After you have done this, take a second to double check you have the right number of files saved in this folder --  you should have as many files as you have filters for your region or else it will cause trouble!

<strong>3. Give the order which you want the filters to appear on the chart.</strong> Open the file called ordered_regions.csv (using Excel or a similar program). This file ranks the filters in the order you want them to appear on the output chart. When eyeballing all your region's filters, presumably it's easiest to have similar filters displaying next to each other, and/or using a north to south or west to east gradient. Currently this list is populated with the filters for Washington State, USA, but when you are ready to run your own region, erase these (leave the header alone) and fill in your own filters. The filters should be listed in descending order in only column A, without their filter prefix. If your 3 filters are: Wisconsin--North, Wisconsin--Central, Wisconsin--South, in cells A1 through A4 you should have:  REGION_NAME, North, Central, and South. Save this file as ordered_regions.csv.

<strong>Open the file called ebird_filter_compare.R in R and do the following things:</strong>

<strong>4. Set the Working Directory.</strong> Open R and set the working directiory to the folder these files are in (ebird_filter_compare-master). 

<strong>5. Edit the filter prefix to your region.</strong> Towards the top of the script, change the following code so it is removing the prefix of your particular filters. Here these lines currently say:

#Portions of filter titles to be deleted
filter_prefix <- 'Washington--'
filter_suffix <- ' Count.*'

but change one line to your region (here, Wisconsin):

#Portions of filter titles to be deleted
filter_prefix <- 'Wisconsin--'
filter_suffix <- ' Count.*'

<strong>6.  Make sure the taxonomy is pointing at the correct file.</strong> If it's after August 2019, you'll have to download a new one (as a csv), and correct the text below to point to it.

##Import eBird taxonomy
tax <- read.csv("eBird_Taxonomy_v2018_14Aug2018.csv",stringsAsFactors=F)

<strong>7. Make sure necessary R packages are installed.</strong> If this is your first time running these R packages, you may have to install them using the following code:

install.packages(“magrittr”)

install.packages(“plyr”)

install.packages(“dplyr”)

install.packages(“rvest”)

install.packages(“parallel”)

<strong>8. That's it! Run the code and await your glorious filter comparison chart. </strong>
If you see any red text in the output and it stops within the first minute, you may need to fix an error.
Regions with more filters will take longer to run. It does take about a half hour to run if you have 20 filters.
When it's done, it will show up in the output folder as taxa.pdf.

---------------------------------------------------------------------------------------------------
Common Error #1: Error in filter name list or missing a filter
If anything is marked FALSE on this output, it means there is an error with your filters. Either  you need to check your ordered list of filters, or the number of filters you have downloaded, because they don't match.
> ## Check that custom region order vector is correct
> regions %in% ordered_regions
 [1]  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE
[20]  TRUE  TRUE  TRUE  TRUE  TRUE FALSE  TRUE
> ordered_regions %in% regions
 [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
[24] TRUE TRUE
