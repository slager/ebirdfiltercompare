## This script is designed to be used by eBird Regional Editors to easily visualize differences among taxa filters in your regions.

![BTYW example](https://github.com/slager/ebird_filter_compare/blob/master/btyw.png)
 
To get the required files, click "Clone or Download" above, then go find the zipped file on your computer, and unzip (extract) the contents, which will appear in a new folder named something like "ebird\_filter\_compare-master".

-------------------------------------------------------------------------------------------------------------------

## 1. Set up the files you'll need

*Note: The download comes pre-loaded with files for Washington State, USA. If you run it as is for practice, you'll get a nice full-size chart, but it will take about half an hour to run. If you'd like to practice, we suggest deleting all but 3 Washington filters in the filter folder and list (you will learn about this below) and running it like that so that you know it's working. If you have no interest in practice and want to jump into action, you can ignore running it with practice Washington data and skip straight to replacing these lines with your regional files as directed below.*
 
### 1a. Check to see if the eBird Taxonomy is current.

Make sure the folder (ebird\_filter\_compare-master) contains the current eBird taxonomy in csv format (e.g. eBird\_Taxonomy\_v2018\_14Aug2018.csv). This readme was written in early 2019, so as of this writing, if it is after August 2019, you will have to download the new taxonomy.

### 1b. Download the eBird filters for your region.

There is a subfolder called filter\_htm where you will need to save a copy of your current eBird filters. Note that right now this is full of Washington State, USA filter files if you want to use those for a test run, but you should replace it with your own files when ready to run the script for your region. To run it for your region, first delete all the example files from the folder. Then, using Google Chrome or Mozilla Firefox, log in to eBird Admin, and go to the filters tab. To download each one:

Right-click on filter page > "View Page Source"

File > Save Page As

Select 'Webpage, HTML Only'

After you have done this, take a second to double check you have the right number of files saved in this folder --  you should have as many files as you have filters for your region or else it will cause trouble!

## 2. Setup R and RStudio

### 2a. [Download and install R](https://cran.r-project.org/).

This step is only necessary if you have not previously installed R on your computer. You'll first follow the above link to your operating system (Windows, Mac, or Linux). Windows users will want to click on the link for the "base" version, and Mac users will want to click the version named R-3.x.x.pkg. Once the file downloads, install it on your computer the way you normally would.

### 2b. Download and install [R Studio](https://www.rstudio.com/).

This is only necessary if you don't already have RStudio on your computer. Select the version that corresponds to your operating system, and install it the way you normally would.

### 2c. Create an RStudio project

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

Do this once the packages have been installed. This disables those lines of code so that you won't accidentally re-install the packages later.

## 3. Check filter names and choose filter order

### 3a. Edit the filter prefix and suffix for your region.

We want to remove filter name prefixes and suffixes so that very long filter names won't take up precious space on the final output chart. Towards the top of the script, change the following code so it is removing the prefix of your particular filters. Here these lines currently say:
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
In this case, what's being removed is the state name and the word "County" or "Counties". If you don't want to delete a filter prefix or suffix, just remove all text between the apostrophes above.

### 3b. Extract the filter names from your saved filter files

Run the script up to and including these lines:
```
## Export CSV list of regions for manual ordering
export_region_list_for_ordering() -> regions
```
This will extract the filter names from the HTML files and save the list as regions.csv

### 3c. Set up the order in which you want the filters to appear on the chart.

Open the file called regions.csv in Excel or a similar program. Inspect the names of the filter regions to ensure that the filter name prefixes and suffixes were being deleted properly. If not, you can adjust the prefixes/suffixes and re-run the previous steps as necessary.

In Excel, rank the filters in the order you want them to appear on the output chart. When eyeballing all your region's filters, presumably it's easiest to have similar filters displaying next to each other, and/or using a north to south or west to east gradient. Currently this list is populated with the filters for Washington State, USA, but when you are ready to run your own region, erase these (leave the header alone) and fill in your own filters. The filters should be listed in descending order in only column A, without their filter prefix. If your 3 filters are: Wisconsin--North, Wisconsin--Central, Wisconsin--South, in cells A1 through A4 you should have:  REGION\_NAME, North, Central, and South. Save this file, changing the name to ordered\_regions.csv.

## 4.  Check your regions and ordered regions for consistency

Select and run the following lines:
```
## Import manually ordered list of regions
import_ordered_region_list() -> ordered_regions

## Check ordered_regions vs. regions for consistency
check_regions()
```
If you see error messages, it probably means you need to proofread your ordered list of filters, or the number of filter HTML files you have downloaded, because they don't match.

## 5.  Make sure the taxonomy is pointing at the correct file.

If it's before August 2019, you can skip this entire step. If you are reading this in the distant future, after August 2019, and you've downloaded the eBird taxonomy version 2019 or later, you'll need to adjust this line in the code to point to the correct taxonomy filename.
```
"eBird_Taxonomy_v2018_14Aug2018_utf8.csv" -> taxonomy_filename
```

## 6. Run the code to crunch your filter comparisons!

At this point, you should be able to run the last chunk of the script file (or even the entire script file all at once) and await your glorious filter comparison chart.

If you see any red text or error messages in the output and it stops within the first minute, you probably need to fix an error.

Regions with more filters will take longer to run. It does take about a half hour to run if you have 20 filters.

When it's done, it will show up in the output folder as taxa.pdf.