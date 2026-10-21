# Load-test every package the R sandbox promises.
#
# Usage: Rscript check-r-packages.R /path/to/requirements.sandbox.r.txt
#
# Loads each package named in the requirements file plus the base /
# recommended packages below (shipped with r-base, so not installed
# separately), prints one line per failure, and exits non-zero if any
# package fails to load.  Run by ``make build-r-sandbox`` and by the
# requires_r_docker smoke test.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("usage: Rscript check-r-packages.R <requirements file>")

lines <- readLines(args[[1]])
lines <- trimws(sub("#.*$", "", lines))
listed <- lines[nzchar(lines)]

base_pkgs <- c("MASS", "nnet", "survival", "splines", "Matrix", "boot", "stats", "utils")
pkgs <- unique(c(listed, base_pkgs))

failed <- character(0)
for (p in pkgs) {
  ok <- suppressPackageStartupMessages(suppressWarnings(
    requireNamespace(p, quietly = TRUE)
  ))
  if (ok) {
    ok <- tryCatch({
      suppressPackageStartupMessages(library(p, character.only = TRUE))
      TRUE
    }, error = function(e) {
      message("  ", p, ": ", conditionMessage(e))
      FALSE
    })
  }
  if (!ok) failed <- c(failed, p)
}

if (length(failed)) {
  cat("FAILED to load ", length(failed), " of ", length(pkgs), " packages: ",
      paste(failed, collapse = ", "), "\n", sep = "")
  quit(status = 1)
}
cat("OK: loaded all ", length(pkgs), " packages\n", sep = "")
