# Exploratory run 6: dates from start timestamp, neighborhood date profile, time-window variants (counts only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, house, today, start, end, exempt, tot_complete)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt","stratum")], by = "a7")
rgd <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
cat("today empty:", sum(rgd$today == "" | is.na(rgd$today)), " start empty:", sum(rgd$start == "" | is.na(rgd$start)), "\n")
print(head(rgd$start[rgd$today == ""], 5)); print(head(rgd$today[rgd$today != ""], 3))
u <- merge(hd, rgd[, c("compound1","house","today","start","exempt")], by = "compound1", all.x = TRUE)
u$dt <- as.Date(substr(u$start, 1, 10))
cat("missing dt:", sum(is.na(u$dt)), "\n")
print(u %>% group_by(trt) %>% summarise(first = min(dt, na.rm=TRUE), last = max(dt, na.rm=TRUE), n = n()))
u <- merge(u, rs[, c("a7","month")], by = "a7")
nb <- u %>% group_by(trt, a7, month) %>% summarise(n = n(), dmin = min(dt), dmed = median(dt), dmax = max(dt), .groups = "drop") %>% arrange(trt, dmin)
for (t in 1:3) {
  cat("\n--- trt", t, "\n")
  x <- nb[nb$trt == t, ]
  cat(paste(sprintf("%d:%s/%s/%s(n%d,m%d)", x$a7, format(x$dmin, "%m%d"), format(x$dmed, "%m%d"), format(x$dmax, "%m%d"), x$n, x$month), collapse = " "), "\n")
}
ci <- zap_labels(read_dta(file.path(B, "admin_data/campaign_collector_info.dta"), col_select = c(Month, Tmt, a7, multipoly, days_carto_2poly, days_collection_2poly, days_consult, days_all_2poly, col1_today)))
cat("\ncampaign_collector_info:\n"); print(head(as.data.frame(ci), 10)); print(table(ci$Month, ci$Tmt))
cat("start of month per Month in ci col1_today:\n"); print(ci %>% group_by(Month) %>% summarise(mn = min(col1_today, na.rm=TRUE), mx = max(col1_today, na.rm=TRUE)))
