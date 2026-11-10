suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/"
d <- read_dta(paste0(D, "LSS_analysis_datasets_20201108.dta"))
nm <- names(d)
cat(length(nm), "cols", nrow(d), "rows\n")
pre <- gsub("[0-9].*$", "", nm)
print(sort(table(pre), decreasing=TRUE)[1:60])
nonCC <- nm[!grepl("^(CC|M[0-9])", nm) & !grepl("x", nm)]
cat("NON-CC/M cols:", length(nonCC), "\n"); print(nonCC)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
cc <- nm[grepl("^CC[0-9]+$", nm)]
for (v in cc) cat(v, ":", lab[v], " | nNA=", sum(is.na(d[[v]])), " mean=", mean(d[[v]], na.rm=TRUE), "\n")
m <- nm[grepl("^M", nm) & !grepl("x", nm)]; cat("M cols:", length(m), "\n"); print(m)
for (v in m) cat(v, ":", lab[v], " | nNA=", sum(is.na(d[[v]])), " mean=", mean(d[[v]], na.rm=TRUE), "\n")
for (v in nonCC) cat(v, ":", lab[v], " | class=", class(d[[v]])[1], " nNA=", sum(is.na(d[[v]])), " mean=", suppressWarnings(mean(as.numeric(d[[v]]), na.rm=TRUE)), "\n")
