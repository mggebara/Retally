# Exploratory run 8: brute-force search of window cutoffs matching sample sizes (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
options(width = 220, warn = -1)
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% zap_labels()
ra$tf <- ra$treatment; ra$tf[ra$a7 == 654] <- 2
rs <- read_dta(file.path(B, "admin_data/randomization_schedule.dta")) %>% zap_labels()
reg <- read_dta(file.path(B, "admin_data/registration_noPII.dta")) %>% zap_labels()
hh <- read_dta(file.path(B, "admin_data/hh_distances.dta")) %>% zap_labels()
tr <- read_dta(file.path(B, "admin_data/taxroll_noPII.dta")) %>% zap_labels()
r1 <- reg %>% filter(compound1 %in% hh$compound1) %>% arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE)
u <- hh %>% filter(!is.na(compound1)) %>% select(compound1, a7h = a7) %>% left_join(r1, by = "compound1")
u$t <- ra$tf[match(u$a7h, ra$a7)]
u$d <- as.numeric(as.Date(u$start))
cat("hh in taxroll by arm:\n"); print(table(u$t, u$compound1 %in% tr$compound1))
u$month <- rs$month[match(u$a7h, rs$a7)]
nb <- u %>% filter(!is.na(t)) %>% group_by(a7h, t, month) %>% summarise(nmin = min(d, na.rm=T), nmax = max(d, na.rm=T), nmed = as.numeric(median(d, na.rm=T)), n = n(), .groups = "drop")
cat("nbhd month vs nmin by arm (L,C,CLI):\n")
print(as.data.frame(nb %>% filter(t %in% 1:3) %>% group_by(t, month) %>% summarise(k = n(), nmin_lo = as.Date(min(nmin), origin="1970-01-01"), nmin_hi = as.Date(max(nmin), origin="1970-01-01"), nmax_hi = as.Date(max(nmax), origin="1970-01-01"), props = sum(n), .groups="drop")))
u <- u %>% left_join(nb %>% select(a7h, nmin, nmax, nmed), by = "a7h")
D <- function(x) as.Date(x, origin = "1970-01-01")
bf <- function(arms, ntarget, ctarget) {
  s <- u %>% filter(t %in% arms)
  cat("\n=== arms", arms, " universe N", nrow(s), " clusters", length(unique(s$a7h)), " target", ntarget, ctarget, "\n")
  starts <- seq(as.numeric(as.Date("2018-06-10")), as.numeric(as.Date("2018-07-25")), by = 0.5)
  ends <- seq(as.numeric(as.Date("2018-10-25")), as.numeric(as.Date("2018-12-15")), by = 0.5)
  for (dv in c("d", "nmin", "nmax", "nmed")) {
    x <- s[[dv]]; best <- NULL
    for (st in starts) for (en in ends) {
      keep <- !is.na(x) & x >= st & x <= en
      N <- sum(keep); C <- length(unique(s$a7h[keep]))
      if (C == ctarget && abs(N - ntarget) <= 40) best <- rbind(best, data.frame(dv = dv, st = as.character(D(st)), en = as.character(D(en)), N = N, C = C))
    }
    if (!is.null(best)) { best <- best %>% group_by(N, C) %>% summarise(st = paste(range(st), collapse="~"), en = paste(range(en), collapse="~"), .groups="drop"); cat(dv, "\n"); print(as.data.frame(best)) } else cat(dv, ": none\n")
  }
}
bf(1:2, 27764, 213)
bf(c(1,3), 20636, 165)
