#significant data example
set.seed(123)

n <- 100  # per group

# Control group (lower hazard → longer survival)
age_ctrl <- rexp(n, rate = 1/800)
dead_ctrl <- rbinom(n, 1, 0.7)

# Treatment group (higher hazard → shorter survival)
age_treat <- rexp(n, rate = 1/400)
dead_treat <- rbinom(n, 1, 0.7)

example_data_sig <- data.frame(
  age = c(age_ctrl, age_treat),
  dead = c(dead_ctrl, dead_treat),
  group = c(rep("Control", n), rep("GTE", n))
)

library(survival)

survdiff(Surv(age, dead) ~ group, data = example_data_sig)

usethis::use_data(example_data_sig, overwrite = TRUE)
