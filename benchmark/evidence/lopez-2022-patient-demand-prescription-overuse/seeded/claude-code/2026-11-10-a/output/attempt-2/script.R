suppressMessages(library(haven))
p <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(p)
d <- d[d$dropme != 1, ]
nm <- names(d)
v <- grep("cscom|clinic|CSCOM", nm, value = TRUE, ignore.case = TRUE)
print(v)
for (x in v) cat(x, class(d[[x]])[1], "nuniq", length(unique(d[[x]])), "NA", sum(is.na(d[[x]])), "\n")
cat("last names:", tail(nm, 5), "\n")
cat("date nuniq", length(unique(d$date)), "\n")
