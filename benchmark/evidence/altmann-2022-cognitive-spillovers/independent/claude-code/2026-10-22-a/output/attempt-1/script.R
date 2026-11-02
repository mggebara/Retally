suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-10-22-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
d <- read_dta(paste0(D,"formatted_data_replication.dta"))
str(d, give.attr=FALSE)
for (v in names(d)) { lab <- attr(d[[v]],"label"); cat(v, ":", if(is.null(lab)) "" else lab, "\n")
  if (is.labelled(d[[v]])) print(attr(d[[v]],"labels")) }
for (v in c("Treatment_Environment","Treatment_intervention","Treatment_Incentives_Baseline_sc","round","wave","high_load","Attention")) if (v %in% names(d)) print(table(d[[v]], useNA="ifany"))
m <- read_dta(paste0(D,"formatted_data_long_mturk.dta"))
str(m, give.attr=FALSE); print(summary(m))
print(table(m$Treatment_intervention)); print(length(unique(m$subject_id)))
