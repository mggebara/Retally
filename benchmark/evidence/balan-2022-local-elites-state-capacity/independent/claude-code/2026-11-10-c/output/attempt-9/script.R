# Exploratory run 9: near-miss window search with property dates; nbhd date anomalies (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
options(width = 220, warn = -1)
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% zap_labels()
ra$tf <- ra$treatment; ra$tf[ra$a7 == 654] <- 2
rs <- read_dta(file.path(B, "admin_data/randomization_schedule.dta")) %>% zap_labels()
reg <- read_dta(file.path(B, "admin_data/registration_noPII.dta")) %>% zap_labels()
hh <- read_dta(file.path(B, "admin_data/hh_distances.dta")) %>% zap_labels()
pay <- read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")) %>% zap_labels()
mid <- read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = c(a7, compound, today, month, pilot)) %>% zap_labels()
r1 <- reg %>% filter(compound1 %in% hh$compound1) %>% arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE)
u <- hh %>% filter(!is.na(compound1)) %>% select(compound1, a7h = a7) %>% left_join(r1, by = "compound1")
u$t <- ra$tf[match(u$a7h, ra$a7)]
u$d <- as.numeric(as.Date(u$start))
u$month <- rs$month[match(u$a7h, rs$a7)]
D <- function(x) as.Date(x, origin = "1970-01-01")
# nbhd date distribution: quantiles
nb <- u %>% filter(t %in% 1:3) %>% group_by(a7h, t, month) %>% summarise(n = n(), q10 = D(quantile(d, .1, na.rm=T, type=1)), q50 = D(quantile(d, .5, na.rm=T, type=1)), q90 = D(quantile(d, .9, na.rm=T, type=1)), mn = D(min(d, na.rm=T)), mx = D(max(d, na.rm=T)), .groups = "drop")
cat("Local nbhds sorted by month, q50:\n"); print(as.data.frame(nb %>% filter(t == 2) %>% arrange(month, q50)), row.names = FALSE)
cat("Central nbhds month 6/7:\n"); print(as.data.frame(nb %>% filter(t == 1, month >= 6) %>% arrange(month, q50)), row.names = FALSE)
# payment dates per nbhd (first payment)
pay$t <- ra$tf[match(pay$a7, ra$a7)]
pn <- pay %>% filter(t %in% 1:3) %>% mutate(pd = as.Date(date)) %>% group_by(t) %>% summarise(first = min(pd, na.rm=T), last = max(pd, na.rm=T), p01 = quantile(pd, .01, na.rm=T, type=1), p99 = quantile(pd, .99, na.rm=T, type=1))
cat("payment date ranges by arm:\n"); print(as.data.frame(pn))
# midline dates by arm
mid$t <- ra$tf[match(mid$a7, ra$a7)]
cat("midline date ranges by arm:\n"); print(as.data.frame(mid %>% filter(pilot == 0, t %in% 1:3) %>% mutate(dd = as.Date(today)) %>% group_by(t) %>% summarise(first = min(dd, na.rm=T), p01 = quantile(dd, .01, na.rm=T, type=1), p99 = quantile(dd, .99, na.rm=T, type=1), last = max(dd, na.rm=T))))
# near-miss search property dates
s <- u %>% filter(t %in% 1:2)
starts <- seq(as.numeric(as.Date("2018-06-14")), as.numeric(as.Date("2018-06-26")), by = 1)
ends <- seq(as.numeric(as.Date("2018-11-20")), as.numeric(as.Date("2018-12-12")), by = 1)
res <- NULL
for (st in starts) for (en in ends) { keep <- !is.na(s$d) & s$d >= st & s$d <= en; res <- rbind(res, data.frame(st = as.character(D(st)), en = as.character(D(en)), N = sum(keep), C = length(unique(s$a7h[keep])))) }
cat("property-date windows with C in 211..215:\n"); print(res %>% filter(C >= 211, C <= 215) %>% arrange(abs(N - 27776)) %>% head(25))
