library(haven); library(dplyr)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
cat(dim(d), "\n")
for (v in names(d)) { lab <- attr(d[[v]], "label"); x <- d[[v]]
  s <- if (is.numeric(x)) paste(round(summary(as.numeric(x)),2), collapse=" ") else paste(head(unique(as.character(x)),6), collapse="|")
  cat(v, "|", ifelse(is.null(lab),"",lab), "|", class(x)[1], "| NA:", sum(is.na(x)), "|", s, "\n") }
for (v in c("wave","treatment","incentive","type_of_info","incentivetext","wavenum")) { cat("--",v,"\n"); print(table(as_factor(d[[v]]), useNA="ifany")) }
print(table(d$wave, d$treatment, useNA="ifany"))
