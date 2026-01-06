test_that("augment_surv_data replicates rows correctly", {
  df <- data.frame(
    age = c(5, 10),
    dead = c(1, 0),
    group = c("A", "B")
  )

  out <- augment_surv_data(df, reps = 4)

  expect_equal(nrow(out), 8)
})

test_that("augment_surv_data produces positive ages", {
  df <- data.frame(
    age = c(1, 2),
    dead = c(1, 0),
    group = c("A", "B")
  )

  out <- augment_surv_data(df, reps = 5)

  expect_true(all(out$age > 0))
})
