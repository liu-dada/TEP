test_that("example_data_sig loads correctly", {
  data("example_data_sig")

  # Check it’s a data frame
  expect_s3_class(example_data_sig, "data.frame")

  # Check expected columns
  expect_true(all(c("age", "dead", "group") %in% names(example_data_sig)))

  # Optional: check dimensions or sample values
  expect_gt(nrow(example_data_sig), 0)
})
