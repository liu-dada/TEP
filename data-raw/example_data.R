## code to prepare `example_data` dataset goes here
library(readxl)
example_data <- read_excel("C:/Users/churc/Downloads/Sample file small.xlsx",sheet = 1)

usethis::use_data(example_data, overwrite = TRUE)
