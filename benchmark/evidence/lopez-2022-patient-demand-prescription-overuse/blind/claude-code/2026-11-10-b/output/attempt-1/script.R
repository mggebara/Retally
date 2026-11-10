suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-b/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/"
d <- read_dta(paste0(D, "LSS_analysis_datasets_20201108.dta"))
cat(dim(d), "\n")
nm <- names(d)
pre <- sub("^([A-Za-z]+).*", "\\1", nm)
print(head(sort(table(pre), decreasing=TRUE), 60))
nox <- nm[!grepl("x", nm)]
cat(length(nox), "non-interaction names\n")
for (v in nox) { lab <- attr(d[[v]], "label"); cat(v, ":", if(is.null(lab)) "" else lab, " | nNA=", sum(is.na(d[[v]])), " mean=", suppressWarnings(round(mean(as.numeric(d[[v]]), na.rm=TRUE),3)), "\n") }
