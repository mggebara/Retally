suppressMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-01-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
show <- function(d) {
  for (v in names(d)) { x <- d[[v]]; lab <- attr(x, "label")
    cat("==", v, "|", class(x)[1], "|", ifelse(is.null(lab), "", lab), "| NA:", sum(is.na(x)), "| nuniq:", length(unique(x)), "\n")
    if (length(unique(x)) <= 12) print(table(as_factor(x), useNA = "ifany")) else print(summary(as.numeric(x))) }
}
d <- read_dta(paste0(base, "formatted_data_replication.dta"))
print(dim(d)); show(d)
cat("\nrounds per subject:\n"); print(table(table(d$subject_id)))
print(with(d, table(as_factor(Treatment_Environment), as_factor(high_task_difficulty))))
m <- read_dta(paste0(base, "formatted_data_long_mturk.dta"))
print(dim(m)); show(m)
print(table(table(m$subject_id)))
