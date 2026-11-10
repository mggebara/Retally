suppressMessages(library(haven))
p <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-b/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(p)
d <- d[d$dropme != 1, ]
nm <- names(d)
cat("names starting cscom:", grep("^cscom", nm, value = TRUE), "\n")
cat("names containing clinic/cscom:", grep("cscom|clinic", nm, value = TRUE, ignore.case = TRUE), "\n")
for (v in grep("^cscom", nm, value = TRUE)) cat(v, class(d[[v]]), "nonNA", sum(!is.na(d[[v]])), "nuniq", length(unique(d[[v]])), "\n")
