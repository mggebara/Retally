library(haven); library(dplyr)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label");
  cat(sprintf("%-32s %-10s nNA=%4d lab=%s\n", v, class(x)[1], sum(is.na(x)), ifelse(is.null(lab),"",lab)))
  if (length(unique(x)) <= 12) print(table(as_factor(x), useNA="ifany")) else print(summary(as.numeric(x)))
}
