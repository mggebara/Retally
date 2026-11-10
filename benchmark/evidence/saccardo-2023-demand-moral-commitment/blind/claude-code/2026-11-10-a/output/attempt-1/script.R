suppressPackageStartupMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(D, "choice_experiments.dta"))
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  u <- unique(x); nu <- length(u)
  s <- if (nu <= 12) paste(sort(as.character(u), na.last=TRUE), collapse=",") else if (is.numeric(x)) sprintf("num min=%g max=%g mean=%g", min(x,na.rm=T), max(x,na.rm=T), mean(x,na.rm=T)) else paste(head(as.character(u),5), collapse="|")
  cat(sprintf("%-40s nNA=%5d nu=%5d [%s] %s\n", v, sum(is.na(x)), nu, lab, substr(s,1,150)))
}
print(table(d$treatment, useNA="ifany"))
print(table(d$sample, useNA="ifany"))
print(table(d$treatment, d$wave, useNA="ifany"))
print(table(d$sample, d$treatment, useNA="ifany"))
for (v in names(d)) if (!is.null(attr(d[[v]],"labels"))) {cat(v, "\n"); print(attr(d[[v]],"labels"))}
