% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{generate_index}
\alias{generate_index}
\title{Write CSV version of PDF page number index}
\usage{
generate_index(species, output_directory = "output")
}
\arguments{
\item{species}{Vector of species names found across the filters}

\item{output_directory}{Directory to write the species index CSV. Silently
created if missing.}
}
\value{
Nothing. Side effect is the index CSV file written to the output
directory.
}
\description{
Write CSV version of PDF page number index
}
