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
