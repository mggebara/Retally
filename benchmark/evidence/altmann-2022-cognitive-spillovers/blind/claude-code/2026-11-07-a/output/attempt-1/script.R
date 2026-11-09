suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-07-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
d <- read_dta(paste0(D,"formatted_data_replication.dta"))
for (v in names(d)) { cat("\n==", v, ":", attr(d[[v]],"label"), " class:", class(d[[v]])[1], "\n");
  lb <- attr(d[[v]],"labels"); if(!is.null(lb)) print(lb)
  x <- d[[v]]; if (length(unique(x))<=15) print(table(as.vector(x), useNA="ifany")) else print(summary(as.numeric(as.vector(x)))) }
cat("rows", nrow(d), "subjects", length(unique(d$subject_id)), "\n")
print(table(d$round))
m <- read_dta(paste0(D,"formatted_data_long_mturk.dta"))
for (v in names(m)) { cat("\n==", v, ":", attr(m[[v]],"label"), "\n"); lb <- attr(m[[v]],"labels"); if(!is.null(lb)) print(lb)
  x <- m[[v]]; if (length(unique(x))<=15) print(table(as.vector(x), useNA="ifany")) else print(summary(as.numeric(as.vector(x)))) }
cat("mturk subjects", length(unique(m$subject_id)), "\n")
