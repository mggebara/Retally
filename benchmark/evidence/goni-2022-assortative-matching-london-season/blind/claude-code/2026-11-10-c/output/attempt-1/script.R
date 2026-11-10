suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-c/mount/goni_2022_assortative_matching_london_season/data/"
for (f in c("final-data.dta","final-data-sec4.dta")) {
  x <- read_dta(paste0(D, f), n_max = 5)
  cat("=====", f, ncol(x), "\n")
  lab <- sapply(x, function(v) { l <- attr(v, "label"); if (is.null(l)) "" else l })
  cls <- sapply(x, function(v) class(v)[1])
  for (i in seq_along(lab)) cat(names(x)[i], "|", cls[i], "|", lab[i], "\n")
}
