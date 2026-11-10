library(haven); library(dplyr)
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-d/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(D,"choice_experiments.dta"))
print(dim(d))
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label"); u <- unique(x); cat(v, "|", class(x)[1], "|", if(!is.null(lab)) lab, "| nuniq", length(u), "| NA", sum(is.na(x)), "|", if (length(u)<=12) paste(head(sort(u),12), collapse=","), "\n") }
for (v in c("treatment","sample","wave","choice","professionals")) { print(v); print(table(as_factor(d[[v]]), useNA="ifany")) }
