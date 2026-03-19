library(testthat)
library(TEP)
library(survival)

# ---- Test 1: Real dataset (robustness test) ----
test_that("safe_bshazard runs on challenging dataset", {

  set.seed(123)
  example_singular <- data.frame(
    age   = c(1, 1, 1, 1, 1),
    dead  = c(1, 1, 0, 0, 0),
    group = c("A", "A", "B", "B", "B")
  )

  fit <- safe_bshazard(Surv(age, dead) ~ group, data = example_singular)

  # Check it returns a model
  expect_true(inherits(fit, "bshazard"))

  # Attribute exists (TRUE or FALSE is OK)
  expect_true(is.logical(attr(fit, "used_aug")))
})

# ---- Test 2: Forced singularity (unit test) ----
test_that("safe_bshazard triggers augmentation when singular", {

  small_data <- data.frame(
    age   = c(1, 1, 2, 2, 3, 3),
    dead  = c(1, 0, 1, 0, 1, 0),
    group = c("A", "A", "B", "B", "A", "B")
  )

  call_count <- 0

  fake_bshazard <- function(...) {
    call_count <<- call_count + 1
    if (call_count == 1) {
      stop("computationally singular system")
    } else {
      # return a fake successful model
      structure(list(), class = "bshazard")
    }
  }

  testthat::local_mocked_bindings(
    bshazard = fake_bshazard,
    .package = "bshazard"
  )

  fit <- safe_bshazard(Surv(age, dead) ~ group, data = small_data)

  expect_true(attr(fit, "used_aug"))
  expect_true(!is.null(attr(fit, "aug_reason")))
})
