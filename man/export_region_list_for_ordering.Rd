% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{export_region_list_for_ordering}
\alias{export_region_list_for_ordering}
\title{Export regions.csv list for manual ordering}
\usage{
export_region_list_for_ordering(
  files,
  filter_prefix,
  filter_suffix,
  output_directory = "output"
)
}
\arguments{
\item{files}{Vector of filter html file paths}

\item{filter_prefix}{Regular expression to exclude from beginning of filter
names}

\item{filter_suffix}{Regular expression to exclude from end of filter names}

\item{output_directory}{Directory to output regions.csv file. Silently
created if missing. Defaults to 'output' subfolder in current directory}
}
\value{
Unordered vector of trimmed region names
}
\description{
Export regions.csv list for manual ordering
}
