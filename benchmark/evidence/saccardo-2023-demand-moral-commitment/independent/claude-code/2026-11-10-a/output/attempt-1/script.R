suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  u <- unique(x)
  cat(sprintf("%-35s %-10s nmiss=%d nuniq=%d | %s | %s\n", v, class(x)[1], sum(is.na(x)), length(u), lab,
      paste(head(sort(u), 8), collapse=",")))
}
cat("\n")
print(table(d$treatment, useNA="a"))
print(table(d$sample, useNA="a"))
print(table(d$wave, useNA="a"))
print(with(d, table(treatment, wave, useNA="a")))
print(with(d, table(treatment, sample, useNA="a")))
print(attr(d$treatment, "labels")); print(attr(d$sample, "labels"))
