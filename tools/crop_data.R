suppressMessages({library(magrittr); library(lpjmlkit); library(jsonlite)})
# Usage: Rscript tools/crop_data.R <folder with unzipped lpjml_output> <output folder>
args <- commandArgs(trailingOnly = TRUE)
src <- paste0(args[1], "/"); out <- paste0(args[2], "/")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
invisible(file.copy(paste0(src, c("grid.bin","grid.bin.json","terr_area.bin","terr_area.bin.json")), out, overwrite = TRUE))
meta_txt <- readLines(paste0(src, "fpc.bin.json"))
m <- fromJSON(paste0(src, "fpc.bin.json"))
stopifnot(m$order == "cellseq", m$datatype == "float", m$nstep == 1)
bytes_per_year <- m$ncell * m$nbands * 4
stopifnot(file.size(paste0(src, "fpc.bin")) == bytes_per_year * m$nyear)
con <- file(paste0(src, "fpc.bin"), "rb")
for (yrs in list(2015:2025, 2085:2095)) {
  tag <- paste0(min(yrs), "-", max(yrs)); fn <- paste0("fpc_", tag, ".bin")
  seek(con, (min(yrs) - m$firstyear) * bytes_per_year)
  writeBin(readBin(con, "raw", bytes_per_year * length(yrs)), paste0(out, fn))
  # edit only the year/filename fields so the header text stays as LPJmL wrote it
  txt <- meta_txt
  txt <- sub('"firstyear" : [0-9]+', paste0('"firstyear" : ', min(yrs)), txt)
  txt <- sub('"lastyear" : [0-9]+',  paste0('"lastyear" : ', max(yrs)), txt)
  txt <- sub('"nyear" : [0-9]+',     paste0('"nyear" : ', length(yrs)), txt)
  txt <- sub('"filename" : "fpc.bin"', paste0('"filename" : "', fn, '"'), txt)
  writeLines(txt, paste0(out, fn, ".json"))
}
close(con)
# verify byte-exact equality against lpjmlkit's own reading of the full file
full <- read_io(paste0(src, "fpc.bin.json")) %>% transform("year_month_day") %>% as_array()
for (yrs in list(2015:2025, 2085:2095)) {
  part <- read_io(paste0(out, "fpc_", min(yrs), "-", max(yrs), ".bin.json")) %>% transform("year_month_day") %>% as_array()
  cat(min(yrs), "-", max(yrs), ": dims", dim(part), " identical to full subset:",
      identical(unname(part), unname(full[, as.character(yrs), ])), " dimnames ok:",
      identical(dimnames(part)[[2]], as.character(yrs)), "\n")
}
