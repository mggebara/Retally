suppressMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-b/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(base, "choice_experiments.dta"))
cat("dim:", dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]
  lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  nu <- length(unique(x))
  cat(sprintf("%-40s %-10s nuniq=%5d NA=%5d | %s\n", v, class(x)[1], nu, sum(is.na(x)), lab))
  if (nu <= 12) { print(table(as_factor(x), useNA = "ifany")) }
}
