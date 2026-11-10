library(haven)
p <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-c/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta"
d <- read_dta(p)
cat(nrow(d), ncol(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  u <- length(unique(x))
  cat(sprintf("%-40s %-10s nuniq=%5d NA=%4d | %s", v, class(x)[1], u, sum(is.na(x)), lab))
  if (u <= 8) { t <- table(as_factor(x), useNA="ifany"); cat(" ::", paste(names(t), t, sep="=", collapse="; ")) }
  else if (is.numeric(x)) cat(sprintf(" :: mean=%.3f sd=%.3f", mean(x,na.rm=TRUE), sd(x,na.rm=TRUE)))
  cat("\n")
}
