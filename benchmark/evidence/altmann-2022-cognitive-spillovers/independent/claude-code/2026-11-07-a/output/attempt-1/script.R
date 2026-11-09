suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-07-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
d <- read_dta(paste0(base, "formatted_data_replication.dta"))
print(dim(d)); print(names(d))
for (v in names(d)) { cat("----", v, attr(d[[v]], "label"), "\n"); x <- d[[v]]; if (length(unique(x)) <= 12) print(table(as_factor(x), useNA="ifany")) else print(summary(as.numeric(x))) }
m <- read_dta(paste0(base, "formatted_data_long_mturk.dta"))
print(dim(m))
for (v in names(m)) { cat("----", v, attr(m[[v]], "label"), "\n"); x <- m[[v]]; if (length(unique(x)) <= 12) print(table(as_factor(x), useNA="ifany")) else print(summary(as.numeric(x))) }
print(length(unique(m$subject_id)))
