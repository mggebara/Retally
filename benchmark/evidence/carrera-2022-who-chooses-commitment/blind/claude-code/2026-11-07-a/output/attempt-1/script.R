suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-07-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
cat(dim(d), "\n")
for (v in names(d)) { lab <- attr(d[[v]], "label"); x <- d[[v]]
  cat(sprintf("%-35s %-10s lab=%s | nNA=%d | ", v, class(x)[1], ifelse(is.null(lab),"",lab), sum(is.na(x))))
  u <- unique(x); if (length(u) <= 12) cat(paste(head(sort(u),12), collapse=","), "\n") else if (is.numeric(x)) cat("mean=", mean(as.numeric(x), na.rm=TRUE), " range=", range(as.numeric(x), na.rm=TRUE), "\n") else cat("nuniq=", length(u), "ex:", paste(head(u,4), collapse=" | "), "\n")
  vl <- attr(x, "labels"); if (!is.null(vl)) cat("   labels:", paste(names(vl), vl, sep="=", collapse="; "), "\n")
}
print(table(d$wave, d$treatment, useNA="ifany"))
print(table(d$wave, d$incentive, useNA="ifany"))
print(table(d$wave, d$type_of_info, useNA="ifany"))
