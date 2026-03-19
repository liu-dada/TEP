# Internal environment to track augmentation usage
TEP_AUG_STATE <- new.env(parent = emptyenv())
TEP_AUG_STATE$used_aug <- FALSE
TEP_AUG_STATE$reason   <- NA_character_

#' Reset augmentation tracking state
#'
#' Clears the internal record of whether jittered data augmentation
#' was used in previous calls to \code{safe_bshazard()}.
#'
#' @export
reset_aug_state <- function() {
  TEP_AUG_STATE$used_aug <- FALSE
  TEP_AUG_STATE$reason   <- NA_character_
}