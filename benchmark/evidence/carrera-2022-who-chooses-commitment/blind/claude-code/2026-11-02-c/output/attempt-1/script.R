library(haven); library(dplyr)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-c/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
cat(dim(d), "\n")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label"); cat(v, "|", class(x)[1], "|", if(!is.null(lab)) lab else "", "| NA:", sum(is.na(x)), "| uniq:", length(unique(x)), "| ", paste(head(unique(as.character(x)),8), collapse=","), "\n") }
print(table(d$wave, d$treatment, useNA="ifany"))
print(table(d$wave, d$incentive, useNA="ifany"))
print(table(d$wave, d$type_of_info, useNA="ifany"))
