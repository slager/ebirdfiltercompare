## This script is designed to be used by eBird Regional Editors to easily visualize differences among taxa filters in your regions.
 
To get the required files, click "Clone or Download" above, then go find the zipped file on your computer, and unzip the contents into a new folder, which is by default named "ebird\_filter\_compare-master".

-------------------------------------------------------------------------------------------------------------------

## 1. Set up the files you'll need

*Note: The download comes pre-loaded with files for Washington State, USA. If you run it as is for practice, you'll get a nice full-size chart, but it will take a half hour to run. If you'd like to practice, we suggest deleting all but 3 filters in the filter folder and list (you will learn about this below) and running it like that. It will be a shorter run, and the output will not look as nice, but you'll know it's working. If you have no interest in practice and want to jump into action, you can ignore running it with practice Washington data and skip straight to replacing these lines with your regional files as directed below.*
 
### 1a. Check to see if the eBird Taxonomy is current.

Make sure the folder (ebird\_filter\_compare-master) contains the current eBird taxonomy in csv format (e.g. eBird\_Taxonomy\_v2018\_14Aug2018.csv). This readme was written in early 2019, so as of this writing, if it is after August 2019, you will have to download the new taxonomy.

### 1b. Download the eBird filters for your region.

There is a subfolder called filter\_htm where you will need to save a copy of your current eBird filters. Note that right now this is full of Washington State, USA filter files if you want to use those for a test run, but you should replace it with your own files when ready to run the script for your region. To run it for your region, first delete all the example files from the folder. Then, using Google Chrome or Mozilla Firefox, log in to eBird Admin, and go to the filters tab. To download each one:

Right-click on filter page > "View Page Source"

File > Save Page As

Select 'Webpage, HTML Only'

After you have done this, take a second to double check you have the right number of files saved in this folder --  you should have as many files as you have filters for your region or else it will cause trouble!

## 2. Setup RStudio

### 2a. Download and install [R Studio](https://www.rstudio.com/).

### 2b. Create an RStudio project

Open RStudio, select File > New Project..., choose "Existing Directory", and select the directory to the folder your files are in (ebird\_filter\_compare-master). Press the "Create Project" button.

### 2c. Open the script in RStudio

Go to File > Open File... and select "ebird\_filter\_compare.R"

### 2d. Install required R packages

On your first time running the script you'll need to install required packages. To do this, remove the initial "#" symbol from each of the following lines. Next, select these lines, and then go to Code > Run Selected Lines. You will see the progress of the packages being downloaded and installed in the RStudio Console pane. It usually takes less than 2 minutes.

```
#install.packages('magrittr')
#install.packages('plyr')
#install.packages('dplyr')
#install.packages('rvest')
```
### 2e. Re-add the "#" symbols to the above 4 lines

Do this once the packages have been installed. This disables those lines of code so that you won't accidentally try to re-install the packages later.

## 3. Check filter names and choose filter order

### 3a. Edit the filter prefix and suffix for your region.

Towards the top of the script, change the following code so it is removing the prefix of your particular filters. Here these lines currently say:
```
#Portions of filter titles to be deleted
filter_prefix <- 'Washington--'
filter_suffix <- ' Count.*'
```
but change one line to your region (here, Wisconsin):
```
#Portions of filter titles to be deleted
filter_prefix <- 'Wisconsin--'
filter_suffix <- ' Count.*'
```
If you don't want to delete a filter prefix or suffix, just remove all text between the apostrophes above.

### 3b. Extract the filter names from your saved filter files

Run the script up to and including this line:
```
write.csv(data.frame(REGION_NAME=regions),'regions.csv',row.names=F)

```
This will extract the filter names from the HTML files. 

### 3c. Set up the order in which you want the filters to appear on the chart.

Open the file called regions.csv (using Excel or a similar program). Inspect the names of the filter regions to ensure that the filter name prefixes and suffixes were being excluded properly. If not, you can adjust those and re-run the previous steps as necessary.

In Excel, rank the filters in the order you want them to appear on the output chart. When eyeballing all your region's filters, presumably it's easiest to have similar filters displaying next to each other, and/or using a north to south or west to east gradient. Currently this list is populated with the filters for Washington State, USA, but when you are ready to run your own region, erase these (leave the header alone) and fill in your own filters. The filters should be listed in descending order in only column A, without their filter prefix. If your 3 filters are: Wisconsin--North, Wisconsin--Central, Wisconsin--South, in cells A1 through A4 you should have:  REGION\_NAME, North, Central, and South. Save this file, changing the name to ordered\_regions.csv.

## 4.  Make sure the taxonomy is pointing at the correct file.

If it's after August 2019, you'll have to download a new one (as a csv), and correct the text below to point to it.
```
##Import eBird taxonomy
tax <- read.csv("eBird_Taxonomy_v2018_14Aug2018.csv",stringsAsFactors=F)
```

## 5. Run the code!

At this point, you should be able to run the entire script file and await your glorious filter comparison chart.

If you see any red text in the output and it stops within the first minute, you probably need to fix an error.

Regions with more filters will take longer to run. It does take about a half hour to run if you have 20 filters.

When it's done, it will show up in the output folder as taxa.pdf.

---------------------------------------------------------------------------------------------------
Common Error #1: Error in filter name list or missing a filter
If anything is marked FALSE on this output, it means there is an error with your filters. Either  you need to check your ordered list of filters, or the number of filters you have downloaded, because they don't match.
```
> ##Check that custom region order vector is correct
> regions %in% ordered_regions
 [1]  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE
[20]  TRUE  TRUE  TRUE  TRUE  TRUE FALSE  TRUE
> ordered_regions %in% regions
 [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
[24] TRUE TRUE
```
