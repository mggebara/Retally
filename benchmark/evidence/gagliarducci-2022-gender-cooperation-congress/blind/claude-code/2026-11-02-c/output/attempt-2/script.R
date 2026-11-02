suppressMessages({library(haven); library(dplyr)})
R <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-02-c/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/"
b <- read_dta(paste0(R, "AnalysisData/bills_analysis_101-111_replication.dta"))
# definition of pct opposite
x <- b %>% filter(!is.na(pct_cosponsors_opposite))
cat("ratio to n:", summary(x$pct_cosponsors_opposite - x$numb_cosponsors_opposite/x$numb_cosponsors), "\n")
cat("ratio to n+1:", summary(x$pct_cosponsors_opposite - x$numb_cosponsors_opposite/(x$numb_cosponsors+1)), "\n")
cat("NA pct by ncosp==0:\n"); print(table(is.na(b$pct_cosponsors_opposite), b$numb_cosponsors==0, useNA="ifany"))
cat("pct>1:", sum(b$pct_cosponsors_opposite>1, na.rm=T), "\n")
print(table(b$private, is.na(b$sponsor_female), useNA="ifany"))
cat("MV1_female vs mixed:\n"); print(table(mixed=b$mixed_gender_election, mvna=is.na(b$MV1_female), useNA="ifany"))
cat("MV1_democrat sample:", head(sort(unique(b$MV1_democrat)),5), "\n")
cat("femaleXMV check:", summary(b$femaleXMV1_female - b$sponsor_female*b$MV1_female), "\n")
c <- read_dta(paste0(R, "IntermediateData/bills_analysis_101-111_clean.dta"))
cat("clean dims", dim(c), "\n")
for (v in setdiff(names(c), names(b))) { lab <- attr(c[[v]], "label"); if (is.null(lab)) lab <- ""; cat(sprintf("%-30s %s | na=%d\n", v, substr(lab,1,70), sum(is.na(c[[v]])))) }
d <- read_dta(paste0(R, "RawData/DistrictCharacteristics_Clean.dta"))
cat("district names:", names(d), "\n")
# sponsor-congress counts
k <- b %>% filter(!is.na(sponsor_female)) %>% distinct(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served)
cat("n sponsor-terms:", nrow(k), "\n")
k2 <- b %>% filter(!is.na(sponsor_female)) %>% distinct(v2, sponsor_name)
cat("n sponsor-terms by name:", nrow(k2), "\n")
