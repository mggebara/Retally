# Exploratory run 11: broader window search over nbhd date definitions (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
options(width = 220, warn = -1)
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% zap_labels()
ra$tf <- ra$treatment; ra$tf[ra$a7 == 654] <- 2
reg <- read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, start)) %>% zap_labels()
hh <- read_dta(file.path(B, "admin_data/hh_distances.dta")) %>% zap_labels()
pay <- read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")) %>% zap_labels()
cc <- read_dta(file.path(B, "admin_data/campaign_collector_info.dta"), col_select = c(Month, a7)) %>% zap_labels()
r1 <- reg %>% filter(compound1 %in% hh$compound1) %>% arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE)
u <- hh %>% filter(!is.na(compound1)) %>% select(compound1, a7h = a7) %>% left_join(r1 %>% select(compound1, start), by = "compound1")
u$t <- ra$tf[match(u$a7h, ra$a7)]
u$d <- as.numeric(as.Date(u$start))
u <- u %>% filter(t %in% 1:3)
u$Month <- cc$Month[match(u$a7h, cc$a7)]
# payment dates per nbhd
pay$pd <- as.numeric(as.Date(pay$date))
pn <- pay %>% filter(!is.na(pd)) %>% group_by(a7) %>% summarise(pmin = min(pd), pmed = as.numeric(median(pd)), pmax = max(pd))
nb <- u %>% group_by(a7h, t, Month) %>% summarise(nmin = min(d, na.rm=T), nmax = max(d, na.rm=T), nmed = as.numeric(median(d, na.rm=T)), nmean = mean(d, na.rm=T),
  q10 = as.numeric(quantile(d, .1, na.rm=T, type=1)), q90 = as.numeric(quantile(d, .9, na.rm=T, type=1)), n = n(), .groups = "drop")
# arm-month start = min nmin within arm x Month
nb <- nb %>% group_by(t, Month) %>% mutate(amstart = min(nmin), ammed = as.numeric(median(nmin))) %>% ungroup()
nb <- nb %>% left_join(pn, by = c("a7h" = "a7"))
u <- u %>% left_join(nb %>% select(-t, -Month), by = "a7h")
D <- function(x) as.character(as.Date(x, origin = "1970-01-01"))
bf <- function(arms, ntarget, ctarget) {
  s <- u %>% filter(t %in% arms)
  cat("\n=== arms", arms, " N", nrow(s), " C", length(unique(s$a7h)), " target", ntarget, ctarget, "\n")
  starts <- seq(as.numeric(as.Date("2018-06-10")), as.numeric(as.Date("2018-07-25")), by = 0.5)
  ends <- seq(as.numeric(as.Date("2018-10-25")), as.numeric(as.Date("2019-01-05")), by = 0.5)
  for (dv in c("d", "nmin", "nmax", "nmed", "nmean", "q10", "q90", "amstart", "ammed", "pmin", "pmed", "pmax")) {
    x <- s[[dv]]; xs <- sort(unique(x))
    res <- NULL
    for (st in starts) { k1 <- !is.na(x) & x >= st
      for (en in ends) { keep <- k1 & x <= en; C <- length(unique(s$a7h[keep]))
        if (abs(C - ctarget) <= 1) res <- rbind(res, data.frame(st = st, en = en, N = sum(keep), C = C)) } }
    if (is.null(res)) { cat(sprintf("%-8s no window with C near target\n", dv)); next }
    res$dist <- abs(res$N - ntarget) + 1000 * abs(res$C - ctarget)
    b <- res %>% arrange(dist) %>% group_by(N, C) %>% summarise(st = paste(D(range(st)), collapse="~"), en = paste(D(range(en)), collapse="~"), dist = min(dist), .groups = "drop") %>% arrange(dist) %>% head(3)
    for (i in seq_len(nrow(b))) cat(sprintf("%-8s N=%d C=%d st=%s en=%s\n", dv, b$N[i], b$C[i], b$st[i], b$en[i]))
  }
}
bf(1:2, 27776, 213)
bf(c(1,3), 20645, 165)
