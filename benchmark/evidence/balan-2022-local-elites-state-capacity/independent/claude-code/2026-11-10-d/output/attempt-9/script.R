# Exploratory run 9: neighborhood-level candidate time variables (counts/dates only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, start, tot_complete)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt")], by = "a7")
u0 <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
u <- merge(hd, u0[, c("compound1","start")], by = "compound1")
nb <- u %>% group_by(a7, trt) %>% summarise(n = n(), rmin = as.Date(min(start)), rmax = as.Date(max(start)), .groups = "drop")
ci <- zap_labels(read_dta(file.path(B, "admin_data/campaign_collector_info.dta"), col_select = c(Month, a7, days_carto_2poly, days_collection_2poly, days_all_2poly, days_carto_1poly, days_collect_1poly, days_all_1poly)))
nb <- merge(nb, ci, by = "a7", all.x = TRUE)
md <- zap_labels(read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = c(a7, month, today, treatment)))
mdn <- md %>% filter(!is.na(a7)) %>% group_by(a7) %>% summarise(mmonth = as.numeric(names(which.max(table(month)))[1]), mmin = min(as.Date(today), na.rm=TRUE), mmed = median(as.Date(today), na.rm=TRUE), mmax = max(as.Date(today), na.rm=TRUE), .groups = "drop")
nb <- merge(nb, mdn, by = "a7", all.x = TRUE)
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
tp$a7c <- tp$compound1 %/% 1000
tpn <- tp %>% filter(!is.na(a7c)) %>% group_by(a7c) %>% summarise(eoc = names(which.max(table(endOfCollect)))[1], neoc = length(unique(endOfCollect)), pmin = min(as.Date(date), na.rm=TRUE), pmax = max(as.Date(date), na.rm=TRUE), .groups = "drop")
nb <- merge(nb, tpn, by.x = "a7", by.y = "a7c", all.x = TRUE)
options(width = 250)
for (t in 1:3) { cat("\n--- trt", t, "\n"); print(as.data.frame(nb[nb$trt == t, ] %>% arrange(rmin)), row.names = FALSE) }
cat("\nclass endOfCollect:", class(tp$endOfCollect), " date:", class(tp$date), "\n")
