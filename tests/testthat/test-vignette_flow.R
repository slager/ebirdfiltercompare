test_that("vignette flow works", {
  filter_prefix <- 'Wisconsin--\\d{2}\\.'
  filter_suffix <- ''
  expect_no_error(
    get_filenames() -> files
  )
  expect_no_error(
    export_region_list_for_ordering(
      files, filter_prefix, filter_suffix,
      output_directory = tempdir()) -> regions
  )
  expect_no_error(
    import_ordered_region_list() -> ordered_regions
  )
  expect_no_error(
    check_regions(regions, ordered_regions)
  )
  expect_no_error(
    compile_taxonomy(files, regions) -> species
  )
  expect_no_error(
    crunch_filters(files, species, ordered_regions,
                   filter_prefix, filter_suffix) -> data
  )
  expect_no_error(
    generate_pdf(data, species, ordered_regions,
                 output_directory = tempdir())
  )
  expect_no_error(
    generate_index(species, output_directory = tempdir())
  )
})
