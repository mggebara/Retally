suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-c/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/"
d <- read_dta(paste0(D, "LSS_analysis_datasets_20201108.dta"))
cat(dim(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
pref <- sub("[0-9x_].*$", "", nm)
print(sort(table(pref), decreasing=TRUE)[1:40])
inter <- grepl("x", nm) & grepl("[0-9]x", nm)
cat("n interaction-like names:", sum(inter), "\n")
for (i in which(!inter)) {
  x <- d[[i]]
  cat(i, nm[i], "|", lab[i], "|", class(x)[1], "| nNA", sum(is.na(x)), "| nuniq", length(unique(x)),
      if (is.numeric(x)) paste("| mean", signif(mean(x, na.rm=TRUE), 4)) else "", "\n")
}
cat("sample interaction names:\n"); print(head(nm[inter], 60)); print(tail(nm[inter], 30))
