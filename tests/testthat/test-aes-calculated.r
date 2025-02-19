test_that("constants aren't calculated", {
  expect_equal(is_calculated_aes(aes(1, "a", TRUE)), c(FALSE, FALSE, FALSE))
})

test_that("names surrounded by .. is calculated", {
  expect_equal(is_calculated_aes(aes(..x.., ..x, x..)), c(TRUE, FALSE, FALSE))

  # even when nested
  expect_equal(is_calculated_aes(aes(f(..x..))), TRUE)
})

test_that("call to stat() is calculated", {
  expect_true(is_calculated_aes(aes(stat(x))))
})

test_that("strip_dots remove dots around calculated aesthetics", {
  expect_identical(strip_dots(aes(..density..))$x, quo(density))
  expect_identical(strip_dots(aes(mean(..density..)))$x, quo(mean(density)))
  expect_equal(
    strip_dots(aes(sapply(..density.., function(x) mean(x)))$x),
    quo(sapply(density, function(x) mean(x)))
  )
})

test_that("strip_dots handles tidy evaluation pronouns", {
  expect_identical(strip_dots(aes(.data$x), strip_pronoun = TRUE)$x, quo(x))
  expect_identical(strip_dots(aes(.data[["x"]]), strip_pronoun = TRUE)$x, quo(x))

  var <- "y"
  f <- function() {
    var <- "x"
    aes(.data[[var]])$x
  }
  expect_identical(quo_get_expr(strip_dots(f(), strip_pronoun = TRUE)), quote(x))
})

test_that("make_labels() deprases mappings properly", {
  # calculation stripped from labels
  expect_identical(make_labels(aes(x = ..y..)), list(x = "y"))
  expect_identical(make_labels(aes(x = stat(y))), list(x = "y"))

  # symbol is always deparsed without backticks
  expect_identical(make_labels(aes(x = `a b`)), list(x = "a b"))
  # long expression is abbreviated with ...
  x_lab <- make_labels(aes(x = 2 * x * exp(`coef 1` * x^2) * 2 * x * exp(`coef 1` * x^2) * 2 * x))$x
  expect_length(x_lab, 1L)
  expect_match(x_lab, "...$")
  # if the mapping is a literal or NULL, the aesthetics is used
  expect_identical(make_labels(aes(x = 1)), list(x = "x"))
  expect_identical(make_labels(aes(x = NULL)), list(x = "x"))
})

test_that("staged aesthetics warn appropriately for duplicated names", {
  # Test should *not* report `NA` as the duplicated aes (#4707)
  df <- data.frame(x = 1, y = 1, lab = "test")

  # One warning in plot code due to evaluation of `aes()`
  expect_snapshot_warning(
    p <- ggplot(df, aes(x, y, label = lab)) +
      geom_label(
        aes(colour = stage(lab, after_scale = colour),
            color  = after_scale(color))
      ) +
      # Guide would trigger another warning when plot is printed, due to the
      # `guide_geom.legend` also using `Geom$use_defaults` method, which we
      # test next
      guides(colour = "none")
  )
  # One warning in building due to `stage()`/`after_scale()`
  expect_snapshot_warning(ggplot_build(p))
})
