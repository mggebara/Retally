suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-c/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
cat(dim(d), "\n")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x, "label"); cat(sprintf("%-35s %-10s nNA=%4d  %s | ", v, class(x)[1], sum(is.na(x)), ifelse(is.null(lab), "", lab)))
  if (is.numeric(x)) cat(sprintf("mean=%.3f min=%.3f max=%.3f nuniq=%d", mean(x,na.rm=T), min(x,na.rm=T), max(x,na.rm=T), length(unique(x)))) else cat(paste(head(unique(x),5), collapse=";"))
  cat("\n") }
print(table(d$wave, d$treatment, useNA="ifany"))
print(table(d$incentive, d$wave, useNA="ifany"))
print(table(d$type_of_info, d$wave, useNA="ifany"))
for (v in names(d)) { l <- attr(d[[v]], "labels"); if (!is.null(l)) { cat(v, ": "); print(l) } }
