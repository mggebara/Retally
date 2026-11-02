suppressMessages({library(haven)})
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-10-22-a/mount/holman_2022_theresa_may_rally"
# sample-size checks only (no estimation)
g <- as.data.frame(zap_labels(read_dta(file.path(M, "global_approval.dta"))))
g <- g[order(g$country_code, g$qtr), ]
ok <- complete.cases(g[, c("lag_approval", "kill_16", "female_pres", "growth", "log_inflation", "execrlc", "election_qtr")])
s <- g[ok, c("country_code", "country", "qtr")]
newspell <- ave(s$qtr, s$country_code, FUN = function(x) c(1, as.numeric(diff(x) != 1)))
cat("complete obs:", nrow(s), " spells:", sum(newspell), " panels:", length(unique(s$country_code)), "\n")
cat("obs minus spells:", nrow(s) - sum(newspell), " obs minus panels:", nrow(s) - length(unique(s$country_code)), "\n")
spl <- tapply(newspell, s$country, sum); print(spl[spl > 1])
# panels with singleton spells
len <- ave(s$qtr, s$country_code, cumsum(newspell), FUN = length)
cat("obs in spells of length 1:", sum(len == 1), "\n")
