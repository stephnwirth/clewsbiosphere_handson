# Hands-on session 1: browser version
# R runs inside this browser tab (webR). Nothing is installed on your computer.
# Run a line with Ctrl+Enter (Cmd+Enter on a Mac), or select several lines and do the same.

# 1. Packages -------------------------------------------------------------------
# Pre-built for the browser. This takes a minute or two the first time.
install.packages(c("magrittr", "lpjmlkit"),
                 repos = c("https://pik-piam.r-universe.dev", "https://repo.r-wasm.org"))
library(magrittr)
library(lpjmlkit)

# 2. Data -----------------------------------------------------------------------
# LPJmL output (SSP5-8.5, MPI-ESM1-2-HR), cut down to the two periods we need:
# 2015-2025 and 2085-2095 (~27 MB download)
data_url <- "https://raw.githubusercontent.com/stephnwirth/clewsbiosphere_handson/main/data/lpjml_lecture.zip"
download.file(data_url, "lpjml_lecture.zip", mode = "wb")
unzip("lpjml_lecture.zip")
fol <- "lpjml_lecture/"
list.files(fol)

grid <- lpjmlkit::read_io(paste0(fol, "grid.bin.json"))$data
# calculate cell area
lat <- grid[, , 2]
lon <- grid[, , 1]
cellarea <- drop(lpjmlkit::read_io(filename = paste0(fol, "terr_area.bin.json"))$data) # in m2

# helper to draw a global map of one value per grid cell (0.5 degree resolution)
plot_map <- function(values, title = "", zlim = range(values, na.rm = TRUE),
                     col = hcl.colors(100, "YlGn", rev = TRUE)) {
  m <- matrix(NA_real_, nrow = 720, ncol = 360)
  m[cbind(round((lon + 180) / 0.5 + 0.5), round((lat + 90) / 0.5 + 0.5))] <-
    pmin(pmax(values, zlim[1]), zlim[2]) # values outside zlim get the end colours
  layout(matrix(1:2, ncol = 2), widths = c(6, 1))
  par(mar = c(2, 2, 3, 1))
  image(seq(-179.75, 179.75, 0.5), seq(-89.75, 89.75, 0.5), m, zlim = zlim,
        col = col, main = title, xlab = "", ylab = "", ylim = c(-60, 90), asp = 1)
  par(mar = c(2, 0.5, 3, 3))
  image(1, seq(zlim[1], zlim[2], length.out = length(col)),
        t(seq_along(col)), col = col, axes = FALSE, xlab = "", ylab = "")
  axis(4, las = 1)
  box()
  layout(1)
}

# 3. Now some data --------------------------------------------------------------
fpc_meta <- lpjmlkit::read_meta(filename = paste0(fol, "fpc_2015-2025.bin.json"))
fpc_meta # what does all this mean?
bands <- fpc_meta$band_names

fpc_2020_raw <- lpjmlkit::read_io(filename = paste0(fol, "fpc_2015-2025.bin.json")) %>%
                lpjmlkit::transform("year_month_day")
fpc_2090_raw <- lpjmlkit::read_io(filename = paste0(fol, "fpc_2085-2095.bin.json")) %>%
                lpjmlkit::transform("year_month_day")

fpc_2020 <- fpc_2020_raw %>% lpjmlkit::as_array()
fpc_2090 <- fpc_2090_raw %>% lpjmlkit::as_array()
str(fpc_2020)

# what has been the global natural area in 2015 in km2?
sum(fpc_2020[, "2015", "natural stand fraction"] * cellarea) / 10^6 # from m2 to km2
sum(fpc_2020[, "2015", "natural stand fraction"] * cellarea) / 10^4 / 10^9 # from m2 to Gha

# is that reasonable? what is roughly the surface of the earth? how much of that is land?
4 * pi * 6371^2 / 3 # in km2

# how will the global area covered by boreal needleleaved evergreen trees
# change over the 21st century? compare 2015-2025 with 2085-2095
bne_2020_map <- lpjmlkit::as_array(fpc_2020_raw,
                                   subset = list(band = "boreal needleleaved evergreen tree"),
                                   aggregate = list(year = mean))
bne_2090_map <- lpjmlkit::as_array(fpc_2090_raw,
                                   subset = list(band = "boreal needleleaved evergreen tree"),
                                   aggregate = list(year = mean))
plot_map(bne_2020_map, title = "2020 boreal forest extent", zlim = c(0, 1))
plot_map(bne_2090_map, title = "2090 boreal forest extent", zlim = c(0, 1))

BNE_2020 <- sum(fpc_2020[, , "boreal needleleaved evergreen tree"] *
                  fpc_2020[, , 1] * # because all fpc is given as fraction of the total natural area
                  cellarea) / 10^6 # from m2 to km2
BNE_2090 <- sum(fpc_2090[, , "boreal needleleaved evergreen tree"] *
                  fpc_2020[, , 1] *
                  cellarea) / 10^6 # from m2 to km2

BNE_2090 / BNE_2020 * 100 # reduction by 25%

# 4. Why would that happen? -----------------------------------------------------
temp_2020 <- subset(fpc_2020_raw, band = 4:6) # temperate
temp_2020 <- lpjmlkit::as_array(temp_2020, aggregate = list(year = mean, band = sum))
temp_2090 <- subset(fpc_2090_raw, band = 4:6) # temperate
temp_2090 <- lpjmlkit::as_array(temp_2090, aggregate = list(year = mean, band = sum))
change_in_temp <- temp_2090 - temp_2020
plot_map(change_in_temp, title = "change in temperate tree cover",
         zlim = c(-1, 1), col = hcl.colors(100, "BrBG"))

bor_2020 <- subset(fpc_2020_raw, band = 7:9) # boreal
bor_2020 <- lpjmlkit::as_array(bor_2020, aggregate = list(year = mean, band = sum))
bor_2090 <- subset(fpc_2090_raw, band = 7:9) # boreal
bor_2090 <- lpjmlkit::as_array(bor_2090, aggregate = list(year = mean, band = sum))
change_in_bor <- bor_2090 - bor_2020
plot_map(change_in_bor, title = "change in boreal tree cover",
         zlim = c(-1, 1), col = hcl.colors(100, "BrBG"))
