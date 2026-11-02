suppressMessages(library(haven))
d <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-02-c/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
lab <- read_dta(paste0(d,"formatted_data_replication.dta"))
str(lab, give.attr=FALSE, list.len=100)
for (v in names(lab)) { l <- attr(lab[[v]],"label"); lb <- attr(lab[[v]],"labels"); cat(v, ":", if(!is.null(l)) l, "\n"); if(!is.null(lb)) print(lb) }
for (v in names(lab)) if (length(unique(lab[[v]]))<15) {cat("--",v,"\n"); print(table(lab[[v]],useNA="ifany"))}
on <- read_dta(paste0(d,"formatted_data_long_mturk.dta"))
str(on, give.attr=FALSE)
for (v in names(on)) if (length(unique(on[[v]]))<15) {cat("--",v,"\n"); print(table(on[[v]],useNA="ifany"))}
print(summary(on))
