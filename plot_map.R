# Helper to draw a global map of one value per grid cell (0.5 degree resolution).
# Uses the vectors `lon` and `lat` (one entry per cell) read in hands_on_session.R.
# Values outside zlim are drawn in the colour of the nearest end of the scale.
# The ocean is mid-grey so land and sea stay distinguishable in light and dark mode
# (the webR app shows plots colour-inverted when the browser is in dark mode).
plot_map <- function(values, title = "", zlim = range(values, na.rm = TRUE),
                     col = hcl.colors(100, "YlGn", rev = TRUE), ocean = "grey60") {
  m <- matrix(NA_real_, nrow = 720, ncol = 360)
  m[cbind(round((lon + 180) / 0.5 + 0.5), round((lat + 90) / 0.5 + 0.5))] <-
    pmin(pmax(values, zlim[1]), zlim[2])
  op <- par(bg = "white", fg = "black", col.axis = "black", col.main = "black")
  on.exit(par(op), add = TRUE) # white background, black text: readable in dark mode too
  layout(matrix(1:2, ncol = 2), widths = c(6, 1))
  par(mar = c(2, 2, 3, 1))
  plot.new()
  plot.window(xlim = c(-180, 180), ylim = c(-60, 90), asp = 1)
  usr <- par("usr")
  rect(usr[1], usr[3], usr[2], usr[4], col = ocean, border = NA)
  image(seq(-179.75, 179.75, 0.5), seq(-89.75, 89.75, 0.5), m, zlim = zlim, col = col, add = TRUE)
  axis(1, at = seq(-150, 150, 50)); axis(2, at = c(-50, 0, 50)); box(); title(main = title)
  par(mar = c(2, 0.5, 3, 3))
  image(1, seq(zlim[1], zlim[2], length.out = length(col)),
        t(seq_along(col)), col = col, axes = FALSE, xlab = "", ylab = "")
  axis(4, las = 1)
  box()
  layout(1)
}
