suppressPackageStartupMessages({library(haven); library(dplyr)})
P <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-c/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(P)
cat(dim(d), "\n")
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
nm <- names(d)
for (i in seq_along(nm)) cat(nm[i], "|", lab[i], "|", sum(!is.na(d[[i]])), "\n")
