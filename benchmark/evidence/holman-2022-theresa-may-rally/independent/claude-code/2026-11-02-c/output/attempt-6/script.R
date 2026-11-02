suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-02-c/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
key <- paste(g$country_code, g$qtr)
sh <- function(v, k) g[[v]][match(paste(g$country_code, g$qtr - k), key)]
base <- c("female_pres","growth","log_inflation","execrlc","election_qtr")
res <- list()
for (yk in -2:1) for (ak in -1:2) for (ck in 0:1) {
  y <- sh("lag_approval", yk); a <- sh("kill_16", ak)
  X <- sapply(base, function(v) sh(v, ck))
  ok <- !is.na(y) & !is.na(a) & complete.cases(X)
  res[[length(res) + 1]] <- data.frame(yk = yk, ak = ak, ck = ck, N = sum(ok))
}
r <- do.call(rbind, res); print(r)
cat("closest:\n"); print(r[order(abs(r$N - 4328)), ][1:6, ])
vars <- c("lag_approval","kill_16", base)
cc <- complete.cases(g[, vars])
for (v in setdiff(names(g), vars)) cat(v, sum(cc & !is.na(g[[v]])), "\n")
# drop isolated / short spells?
