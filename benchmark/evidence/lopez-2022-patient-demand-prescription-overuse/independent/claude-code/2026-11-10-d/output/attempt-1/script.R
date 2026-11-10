suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-d/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
cat(dim(d), "\n")
nm <- names(d)
iscc <- grepl("^[A-Za-z0-9_]+x[A-Z][A-Za-z0-9_]*$", nm)
cat("n interaction-like:", sum(iscc), "\n")
nonint <- nm[!iscc]
cat("n non-interaction:", length(nonint), "\n")
for (v in nonint) { lab <- attr(d[[v]], "label"); x <- d[[v]]
  cat(sprintf("%s | %s | %s | nNA=%d | mean=%s\n", v, ifelse(is.null(lab),"",lab), class(x)[1], sum(is.na(x)), if(is.numeric(x)) format(mean(x,na.rm=TRUE),digits=4) else "")) }
cat("sample interaction names:\n"); print(head(nm[iscc], 80)); print(tail(nm[iscc], 40))
