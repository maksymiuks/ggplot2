#' Simultaneously dodge and jitter
#'
#' This is primarily used for aligning points generated through
#' `geom_point()` with dodged boxplots (e.g., a `geom_boxplot()` with
#' a fill aesthetic supplied).
#'
#' @family position adjustments
#' @param jitter.width degree of jitter in x direction. Defaults to 40% of the
#'   resolution of the data.
#' @param jitter.height degree of jitter in y direction. Defaults to 0.
#' @param dodge.width the amount to dodge in the x direction. Defaults to 0.75,
#'   the default `position_dodge()` width.
#' @inheritParams position_jitter
#' @export
#' @examples
#' set.seed(596)
#' dsub <- diamonds[sample(nrow(diamonds), 1000), ]
#' ggplot(dsub, aes(x = cut, y = carat, fill = clarity)) +
#'   geom_boxplot(outlier.size = 0) +
#'   geom_point(pch = 21, position = position_jitterdodge())
position_jitterdodge <- function(jitter.width = NULL, jitter.height = 0,
                                 dodge.width = 0.75, seed = NA) {
  if (!is.null(seed) && is.na(seed)) {
    seed <- sample.int(.Machine$integer.max, 1L)
  }

  ggproto(NULL, PositionJitterdodge,
    jitter.width = jitter.width,
    jitter.height = jitter.height,
    dodge.width = dodge.width,
    seed = seed
  )
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
PositionJitterdodge <- ggproto("PositionJitterdodge", Position,
  jitter.width = NULL,
  jitter.height = NULL,
  dodge.width = NULL,

  required_aes = c("x", "y"),

  setup_params = function(self, data) {
    flipped_aes <- has_flipped_aes(data)
    data <- flip_data(data, flipped_aes)
    width <- self$jitter.width %||% (resolution(data$x, zero = FALSE) * 0.4)
    # Adjust the x transformation based on the number of 'dodge' variables
    dodgecols <- intersect(c("fill", "colour", "linetype", "shape", "size", "alpha"), colnames(data))
    if (length(dodgecols) == 0) {
      cli::cli_abort("{.fn position_jitterdodge} requires at least one aesthetic to dodge by")
    }
    ndodge    <- lapply(data[dodgecols], levels)  # returns NULL for numeric, i.e. non-dodge layers
    ndodge    <- length(unique0(unlist(ndodge)))

    list(
      dodge.width = self$dodge.width,
      jitter.height = self$jitter.height,
      jitter.width = width / (ndodge + 2),
      seed = self$seed,
      flipped_aes = flipped_aes
    )
  },

  compute_panel = function(data, params, scales) {
    data <- flip_data(data, params$flipped_aes)
    data <- collide(data, params$dodge.width, "position_jitterdodge", pos_dodge,
      check.width = FALSE)

    trans_x <- if (params$jitter.width > 0) function(x) jitter(x, amount = params$jitter.width)
    trans_y <- if (params$jitter.height > 0) function(x) jitter(x, amount = params$jitter.height)

    data <- with_seed_null(params$seed, transform_position(data, trans_x, trans_y))
    flip_data(data, params$flipped_aes)
  }
)
