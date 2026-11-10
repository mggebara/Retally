suppressMessages({library(haven)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-b/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
cat(dim(d), "\n")
nm <- names(d)
base <- nm[!grepl("x", nm, fixed=TRUE)]
cat("N non-interaction names:", length(base), "\n")
for (v in base) { lab <- attr(d[[v]], "label"); if (is.null(lab)) lab <- ""
  x <- d[[v]]; nn <- sum(!is.na(x)); m <- if (is.numeric(x)) round(mean(x, na.rm=TRUE),3) else class(x)[1]
  cat(v, "|", lab, "|", nn, "|", m, "\n") }
inter <- nm[grepl("x", nm, fixed=TRUE)]
cat("N with x:", length(inter), "\n")
cat(head(inter, 300), "\n")
cat(tail(inter, 100), "\n")
