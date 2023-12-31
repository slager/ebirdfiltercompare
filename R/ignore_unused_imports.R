# https://r-pkgs.org/dependencies-in-practice.html#how-to-not-use-a-package-in-imports
ignore_unused_imports <- function() {
  rebird::ebirdtaxonomy
  invisible(NULL)
}
