# Exploratory run 10: campaign_collector_info Month/Tmt vs schedule and dates (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
options(width = 220, warn = -1)
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% zap_labels()
ra$tf <- ra$treatment; ra$tf[ra$a7 == 654] <- 2
rs <- read_dta(file.path(B, "admin_data/randomization_schedule.dta")) %>% zap_labels()
cc <- read_dta(file.path(B, "admin_data/campaign_collector_info.dta"), col_select = c(Month, Tmt, a7, multipoly, days_carto_2poly, days_collection_2poly, days_consult, days_all_2poly, days_carto_1poly, days_collect_1poly, days_consult_1poly, days_all_1poly))
for (v in names(cc)) { lab <- attr(cc[[v]], "label", exact=TRUE); vl <- attr(cc[[v]], "labels", exact=TRUE); cat(v, ":", if (is.null(lab)) "" else lab, if (!is.null(vl)) paste(names(vl), vl, sep="=", collapse="; ") else "", "\n") }
cc <- zap_labels(cc)
print(summary(cc))
cc$t <- ra$tf[match(cc$a7, ra$a7)]; cc$sm <- rs$month[match(cc$a7, rs$a7)]
cat("Tmt vs t\n"); print(table(cc$Tmt, cc$t, useNA="ifany"))
cat("Month vs schedule month (L,C,CLI only)\n"); print(table(cc$Month[cc$t %in% 1:3], cc$sm[cc$t %in% 1:3], useNA="ifany"))
cat("Month by arm\n"); print(table(cc$Month, cc$t, useNA="ifany"))
reg <- read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, start, pilot)) %>% zap_labels()
hh <- read_dta(file.path(B, "admin_data/hh_distances.dta")) %>% zap_labels()
r1 <- reg %>% filter(compound1 %in% hh$compound1) %>% arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE)
nb <- r1 %>% group_by(a7) %>% summarise(n = n(), mn = as.Date(min(start)), md = as.Date(median(start)))
cc <- cc %>% left_join(nb, by = "a7")
cat("Month vs nbhd median registration month (L,C,CLI):\n"); print(table(cc$Month[cc$t %in% 1:3], format(cc$md[cc$t %in% 1:3], "%m"), useNA = "ifany"))
cat("Local nbhds where Month and registration disagree:\n"); print(as.data.frame(cc %>% filter(t %in% 1:3) %>% select(a7, t, Tmt, Month, sm, mn, md, n, multipoly) %>% arrange(t, Month, md)), row.names = FALSE)
