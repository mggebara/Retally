# Exploratory run 8: time-window variants with timestamps; find the 15 extra properties (counts only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, house, today, start, end, exempt, tot_complete, a7_compound, double_sensi, who)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
cat("hd a7 not in 356:\n"); print(hd[!hd$a7 %in% ra$a7, ])
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt","stratum")], by = "a7")
r <- rg[rg$compound1 %in% hd$compound1, ]
r$nrec <- ave(r$compound1, r$compound1, FUN = length)
u0 <- r %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
u <- merge(hd, u0[, c("compound1","house","start","exempt","nrec","tot_complete","double_sensi","who","a7_compound")], by = "compound1")
u$ts <- as.numeric(u$start)
u <- u %>% group_by(a7) %>% mutate(med = median(ts), dev = (ts - med) / 86400) %>% ungroup()
cat("properties > 10 days from nb median by trt:\n"); print(table(u$trt, abs(u$dev) > 10))
cat("nrec>1 by trt:\n"); print(table(u$trt, u$nrec > 1))
cat("tot_complete0 by trt:\n"); print(table(u$trt, u$tot_complete))
cat("double_sensi by trt:\n"); print(table(u$trt, u$double_sensi))
cat("a7_compound != a7 by trt:\n"); print(table(u$trt, u$a7_compound != u$a7))
print(as.data.frame(u[abs(u$dev) > 10 & u$trt %in% c(1,3), c("compound1","a7","trt","start","dev")])[1:min(40, sum(abs(u$dev) > 10 & u$trt %in% c(1,3))), ])

tsv <- function(arms, var) {
  s <- u[u$trt %in% arms, ]
  x <- s[[var]]
  f <- tapply(x, s$trt, min); l <- tapply(x, s$trt, max)
  st <- mean(f); en <- mean(l)
  k <- x >= st & x <= en
  cat(sprintf("arms %s var %s start %s end %s : N=%d clusters=%d (from %d/%d)\n", paste(arms, collapse=""), var,
      format(as.POSIXct(st, origin="1970-01-01", tz="UTC")), format(as.POSIXct(en, origin="1970-01-01", tz="UTC")), sum(k), length(unique(s$a7[k])), nrow(s), length(unique(s$a7))))
}
u <- u %>% group_by(a7) %>% mutate(nmin = min(ts), nmax = max(ts), nmed = median(ts), nmean = mean(ts)) %>% ungroup()
for (v in c("ts","nmin","nmax","nmed","nmean")) { tsv(c(1,2), v); tsv(c(1,3), v) }
# brute force: which single cutoff (from below or above) on nb-level dmin drops exactly 8 clusters for C/L, 25 for C/CLI
nb <- u %>% group_by(a7, trt) %>% summarise(n = n(), dmin = min(ts), dmax = max(ts), dmed = median(ts), .groups = "drop")
for (arms in list(c(1,2), c(1,3))) {
  z <- nb[nb$trt %in% arms, ]
  cat("\narms", arms, ": nb sorted by dmin, cumulative from start and from end\n")
  z <- z[order(z$dmin), ]; z$cum <- cumsum(z$n); z$k <- seq_len(nrow(z))
  print(as.data.frame(z[1:30, c("a7","trt","n","cum","k")] %>% mutate(d = format(as.POSIXct(z$dmin[1:30], origin="1970-01-01", tz="UTC")))))
  z <- z[order(-z$dmax), ]; z$cum <- cumsum(z$n); z$k <- seq_len(nrow(z))
  print(as.data.frame(z[1:30, c("a7","trt","n","cum","k")] %>% mutate(d = format(as.POSIXct(z$dmax[1:30], origin="1970-01-01", tz="UTC")))))
}
