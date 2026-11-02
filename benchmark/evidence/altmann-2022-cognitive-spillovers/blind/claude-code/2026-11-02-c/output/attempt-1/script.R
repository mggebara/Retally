library(haven); library(dplyr)
D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-02-c/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
show <- function(df) for (v in names(df)) { x <- df[[v]]; lab <- attr(x,"label")
  cat("\n##", v, "|", class(x)[1], "|", if(!is.null(lab)) lab else "", "| nuniq=", length(unique(x)), "| NA=", sum(is.na(x)), "\n")
  if (length(unique(x)) <= 12) print(table(as_factor(x), useNA="ifany")) else print(summary(as.numeric(x))) }
d <- read_dta(paste0(D,"formatted_data_replication.dta"))
print(dim(d)); show(d)
m <- read_dta(paste0(D,"formatted_data_long_mturk.dta"))
print(dim(m)); show(m)
print(table(as_factor(d$Treatment_Environment), as_factor(d$Treatment_intervention), useNA="ifany"))
cat("subjects", length(unique(d$subject_id)), "\n")
cat("mturk subjects", length(unique(m$subject_id)), "\n")
