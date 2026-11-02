suppressMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-01-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
d <- read_dta(paste0(base, "formatted_data_replication.dta"))
print(dim(d))
for (v in names(d)) {
  x <- d[[v]]
  lab <- attr(x, "label"); vl <- attr(x, "labels")
  cat("\n==", v, "| class:", class(x)[1], "| label:", if (is.null(lab)) "" else lab, "| NA:", sum(is.na(x)), "\n")
  if (!is.null(vl)) print(vl)
  u <- unique(x)
  if (length(u) <= 12) print(table(as.vector(x), useNA="ifany")) else print(summary(as.numeric(x)))
}
m <- read_dta(paste0(base, "formatted_data_long_mturk.dta"))
print(dim(m))
for (v in names(m)) {
  x <- m[[v]]; lab <- attr(x, "label"); vl <- attr(x, "labels")
  cat("\n==", v, "| label:", if (is.null(lab)) "" else lab, "| NA:", sum(is.na(x)), "\n")
  if (!is.null(vl)) print(vl)
  if (length(unique(x)) <= 12) print(table(as.vector(x), useNA="ifany")) else print(summary(as.numeric(x)))
}
cat("mturk subjects:", length(unique(m$subject_id)), "\n")
cat("lab subjects:", length(unique(d$subject_id)), "\n")
