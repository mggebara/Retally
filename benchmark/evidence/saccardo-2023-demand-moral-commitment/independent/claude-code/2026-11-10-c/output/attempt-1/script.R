library(haven)
f <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-c/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta"
d <- read_dta(f)
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  u <- unique(x)
  cat(sprintf("%-40s %-10s nNA=%d nuniq=%d | %s\n", v, class(x)[1], sum(is.na(x)), length(u), lab))
  if (length(u) <= 12) print(table(as_factor(x), useNA="ifany"))
}
