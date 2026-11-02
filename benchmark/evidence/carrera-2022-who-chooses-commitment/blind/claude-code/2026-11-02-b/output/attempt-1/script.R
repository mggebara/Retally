suppressMessages(library(haven)); suppressMessages(library(dplyr))
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-b/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
cat(dim(d), "\n")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x, "label"); cat(sprintf("%-32s %-10s nNA=%4d uniq=%5d | %s | ", v, class(x)[1], sum(is.na(x)), length(unique(x)), ifelse(is.null(lab), "", lab)));
  u <- sort(unique(x)); if (length(u) <= 12) cat(paste(head(u,12), collapse=","), "\n") else cat(summary(as.numeric(x))[c(1,3,4,6)], "\n") }
lbls <- lapply(d, function(x) attr(x, "labels")); lbls <- lbls[!sapply(lbls, is.null)]; print(lbls)
print(table(d$wave, d$treatment, useNA="ifany")); print(table(d$wave, d$incentive, useNA="ifany")); print(table(d$wave, d$type_of_info, useNA="ifany"))
