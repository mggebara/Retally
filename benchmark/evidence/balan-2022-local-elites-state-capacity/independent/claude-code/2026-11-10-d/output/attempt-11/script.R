# Exploratory run 11: missing registration 'today' by arm/neighborhood; extra Central properties (counts only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, start, today, tot_complete, house, month_tmp_fr, day_tmpp)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt")], by = "a7")
u0 <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
u <- merge(hd, u0, by = "compound1", suffixes = c("", ".r"))
cat("NA today by trt:\n"); print(table(u$trt, is.na(u$today)))
x <- u %>% group_by(trt, a7) %>% summarise(n = n(), nna = sum(is.na(today)), .groups = "drop") %>% filter(nna > 0)
print(as.data.frame(x), row.names = FALSE)
cat("month_tmp_fr x NA today:\n"); print(table(u$month_tmp_fr, is.na(u$today), useNA = "a"))
cat("today vs as.Date(start) differences:\n"); print(table(as.numeric(u$today - as.Date(u$start)), useNA = "a"))
# windows using today only (NA dropped)
for (arms in list(c(1,2), c(1,3))) {
  s <- u[u$trt %in% arms & !is.na(u$today), ]
  fd <- tapply(as.numeric(s$today), s$trt, min); ld <- tapply(as.numeric(s$today), s$trt, max)
  st <- mean(fd); en <- mean(ld)
  cat("arms", arms, "first", format(as.Date(fd, origin="1970-01-01")), "last", format(as.Date(ld, origin="1970-01-01")), "mid", st, en, "\n")
  s$nmin <- ave(as.numeric(s$today), s$a7, FUN = min)
  k <- s$nmin >= st & s$nmin <= en
  cat("  nb-min rule N=", sum(k), " cl=", length(unique(s$a7[k])), " ; NA-only drop N=", nrow(s), " cl=", length(unique(s$a7)), "\n")
}
