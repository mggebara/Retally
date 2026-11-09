library(haven); library(dplyr)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-07-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label"); cat(v, "|", class(x)[1], "|", if(is.null(lab)) "" else lab, "| NA:", sum(is.na(x)), "| ", paste(head(unique(as.vector(x)),8), collapse=","), "\n") }
print(table(d$wave, d$treatment, useNA="a"))
print(table(d$incentive, d$wave, useNA="a"))
print(table(d$type_of_info, d$wave, useNA="a"))
