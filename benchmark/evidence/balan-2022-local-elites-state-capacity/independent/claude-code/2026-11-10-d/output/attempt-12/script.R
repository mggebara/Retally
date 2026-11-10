# Exploratory run 12: grid search over time-window definitions (counts only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
md1 <- function(x) { x <- x[!is.na(x)]; if (!length(x)) NA else as.numeric(names(which.max(table(x)))[1]) }
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, start, tot_complete)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt")], by = "a7")
u0 <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
u <- merge(hd, u0[, c("compound1","start")], by = "compound1")
u$d <- as.numeric(as.Date(u$start))
ci <- zap_labels(read_dta(file.path(B, "admin_data/campaign_collector_info.dta"), col_select = c(Month, a7)))
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
tp$a7c <- tp$compound1 %/% 1000
eo <- tp %>% filter(!is.na(a7c), !is.na(endOfCollect)) %>% group_by(a7c) %>% summarise(eoc = md1(as.numeric(endOfCollect)), .groups = "drop")
nb <- u %>% group_by(a7, trt) %>% summarise(n = n(), rmin = min(d), rmax = max(d), rmed = median(d), rmean = mean(d), .groups = "drop")
nb <- merge(nb, ci, by = "a7", all.x = TRUE)
nb <- merge(nb, eo, by.x = "a7", by.y = "a7c", all.x = TRUE)
# eoc imputation: rmax + median gap within arm-month
nb$gap <- nb$eoc - nb$rmin
g <- nb %>% group_by(trt, Month) %>% summarise(mg = median(gap, na.rm = TRUE), .groups = "drop")
nb <- merge(nb, g, by = c("trt","Month"), all.x = TRUE)
nb$eocf <- ifelse(is.na(nb$eoc), nb$rmin + nb$mg, nb$eoc)
# flag eoc that looks inconsistent with registration (re-done nbs): eoc < rmin
nb$eocc <- ifelse(nb$eocf < nb$rmin, nb$rmin + nb$mg, nb$eocf)
nb$eocc[is.na(nb$eocc)] <- nb$rmin[is.na(nb$eocc)] + 30
nb$mid <- (nb$rmin + nb$eocc) / 2
nb$col_start <- nb$rmax
cat("nbs with eoc < rmin:\n"); print(nb[!is.na(nb$eoc) & nb$eoc < nb$rmin, c("a7","trt","n","rmin","eoc","Month")])
vars <- c("rmin","rmax","rmed","rmean","eocc","mid")
res <- list()
for (arms in list(c(1,2), c(1,3))) {
  s <- nb[nb$trt %in% arms, ]
  for (Fv in vars) for (Lv in vars) {
    st <- mean(tapply(s[[Fv]], s$trt, min)); en <- mean(tapply(s[[Lv]], s$trt, max))
    for (Dv in vars) {
      k <- s[[Dv]] >= st & s[[Dv]] <= en
      res[[length(res) + 1]] <- data.frame(arms = paste(arms, collapse=""), F = Fv, L = Lv, D = Dv, N = sum(s$n[k]), cl = sum(k),
                                         st = format(as.Date(st, origin="1970-01-01")), en = format(as.Date(en, origin="1970-01-01")))
    }
  }
}
res <- do.call(rbind, res)
cat("\nC/L candidates near 213 clusters:\n"); print(res[res$arms == "12" & abs(res$cl - 213) <= 2, ], row.names = FALSE)
cat("\nC/CLI candidates near 165 clusters:\n"); print(res[res$arms == "13" & abs(res$cl - 165) <= 3, ], row.names = FALSE)
cat("\nC/L distribution of cluster counts:\n"); print(table(res$cl[res$arms == "12"]))
cat("\nC/CLI distribution of cluster counts:\n"); print(table(res$cl[res$arms == "13"]))
