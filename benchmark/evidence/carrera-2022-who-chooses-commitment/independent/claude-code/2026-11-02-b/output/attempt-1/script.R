suppressMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-b/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/"
d <- read_dta(paste0(base, "cleaned_commitment_study_data.dta"))
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label")
  cat(sprintf("%-32s %-10s nNA=%4d  %s | ", v, class(x)[1], sum(is.na(x)), ifelse(is.null(lab), "", lab)))
  if (is.numeric(x)) {
    u <- unique(x)
    if (length(u) <= 12) cat(paste(sort(u), collapse = ",")) else
      cat(sprintf("mean=%.3f min=%.2f max=%.2f", mean(x, na.rm = TRUE), min(x, na.rm = TRUE), max(x, na.rm = TRUE)))
  } else cat(paste(head(unique(as.character(x)), 8), collapse = " / "))
  cat("\n")
}
print(table(d$wave, d$treatment, useNA = "ifany"))
print(table(d$wave, d$type_of_info, useNA = "ifany"))
print(table(d$wave, d$incentive, useNA = "ifany"))
dd <- read_dta(paste0(base, "cleaned_commitment_study_daily_data.dta"))
cat("daily names not in main:", setdiff(names(dd), names(d)), "\n")
