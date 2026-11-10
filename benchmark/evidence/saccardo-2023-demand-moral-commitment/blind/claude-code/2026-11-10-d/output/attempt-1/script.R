library(haven); library(dplyr)
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-d/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(D,"choice_experiments.dta"))
cat("dims", dim(d), "\n")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label");
  cat(v, "|", class(x)[1], "|", if(!is.null(lab)) lab else "", "| nNA=", sum(is.na(x)), "| uniq=", length(unique(x)), "\n")
  if (length(unique(x)) <= 12) print(table(as_factor(x), useNA="ifany")) else if (is.numeric(x)) print(summary(as.numeric(x))) }
print(with(d, table(as_factor(treatment), as_factor(sample), useNA="ifany")))
print(with(d, table(as_factor(treatment), wave, useNA="ifany")))
