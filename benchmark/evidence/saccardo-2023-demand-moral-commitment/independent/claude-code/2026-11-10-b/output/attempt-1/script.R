library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-b/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  u <- unique(x); nu <- length(u)
  cat(sprintf("%-40s | %s | nuniq=%d | NA=%d | %s\n", v, lab, nu, sum(is.na(x)),
     if (nu <= 12) paste(head(sort(as.character(u)),12), collapse=",") else paste(round(suppressWarnings(range(as.numeric(x), na.rm=TRUE)),2), collapse="..")))
}
cat("\n---tables\n")
print(table(d$treatment, useNA="a")); print(table(d$sample, useNA="a")); print(table(d$wave, d$treatment, useNA="a"))
print(attr(d$treatment, "labels")); print(attr(d$sample, "labels"))
