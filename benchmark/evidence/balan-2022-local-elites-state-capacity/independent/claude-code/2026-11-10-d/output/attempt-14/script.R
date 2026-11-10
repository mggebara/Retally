# Exploratory run 14: property-level date window variants (counts only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, start, tot_complete)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt")], by = "a7")
u0 <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
u <- merge(hd, u0[, c("compound1","start")], by = "compound1")
u$d <- as.numeric(as.Date(u$start))
for (arms in list(c(1,2), c(1,3), c(1,2,3))) {
  s <- u[u$trt %in% arms, ]
  fd <- tapply(s$d, s$trt, min); ld <- tapply(s$d, s$trt, max)
  st <- mean(fd); en <- mean(ld)
  cat("\narms", arms, " N0", nrow(s), " cl0", length(unique(s$a7)), " start", st, format(as.Date(st, origin="1970-01-01")), " end", en, format(as.Date(en, origin="1970-01-01")), "\n")
  for (rs in c("floor","ceil","raw")) {
    a <- switch(rs, floor = floor(st), ceil = ceiling(st), raw = st)
    b <- switch(rs, floor = floor(en), ceil = ceiling(en), raw = en)
    for (incl in c(TRUE, FALSE)) {
      k <- if (incl) s$d >= a & s$d <= b else s$d > a & s$d < b
      cat(sprintf("  %-5s incl=%-5s N=%d cl=%d\n", rs, incl, sum(k), length(unique(s$a7[k]))))
    }
  }
  # by arm drop counts
  k <- s$d >= floor(st) & s$d <= ceiling(en)
  print(table(s$trt, k))
}
