suppressPackageStartupMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/data/raw/"
p <- read_dta(paste0(D,"panel_g1.dta"))
cat("NAMES panel_g1:\n"); print(names(p))
print(table(p$survey_season, useNA="ifany"))
for (v in c("group","buy_treatment","season_ante","season_post","form_used","season_spring2020","survey_round")) if (v %in% names(p)) {cat(v,"\n"); print(table(p[[v]], p$survey_season, useNA="ifany"))}
b <- read_dta(paste0(D,"buy_data.dta")); str(b); print(table(b$survey_season,b$buy_treatment))
r <- read_dta(paste0(D,"anonym_returns_data.dta"))
cat("NAMES returns:\n"); print(names(r))
print(table(r$treatment, useNA="ifany"))
print(class(r$add5_sold_when_e_1)); print(head(r$add5_sold_when_e_1)); print(class(r$ea_code)); print(head(r$ea_code))
print(summary(r$add4_random_bag))
