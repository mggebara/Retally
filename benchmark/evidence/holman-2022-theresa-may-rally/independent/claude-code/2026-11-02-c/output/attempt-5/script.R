suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-02-c/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
vars <- c("lag_approval","kill_16","female_pres","growth","log_inflation","execrlc","election_qtr")
s <- g[complete.cases(g[, vars]), ] %>% arrange(country_code, qtr)
s <- s %>% group_by(country_code) %>% mutate(newspell = is.na(dplyr::lag(qtr)) | qtr - dplyr::lag(qtr) != 1) %>% ungroup()
cat("N", nrow(s), "panels", length(unique(s$country_code)), "spells", sum(s$newspell), "N - spells", nrow(s) - sum(s$newspell), "\n")
# full-data spells (approval present)
a <- g[!is.na(g$lag_approval), ]
a <- a %>% group_by(country_code) %>% mutate(newspell = is.na(dplyr::lag(qtr)) | qtr - dplyr::lag(qtr) != 1) %>% ungroup()
cat("approval spells", sum(a$newspell), "\n")
# singleton-ish: obs with no time-neighbor
s <- s %>% group_by(country_code) %>% mutate(nb = (!is.na(dplyr::lag(qtr)) & qtr - dplyr::lag(qtr) == 1) | (!is.na(dplyr::lead(qtr)) & dplyr::lead(qtr) - qtr == 1)) %>% ungroup()
cat("isolated obs", sum(!s$nb), "\n")
# women-executive attack quarters
print(s[s$kill_16 == 1, c("country","qtr","female_pres","lag_approval")], n = 70)
# Prais-Winsten-type: OLS residual rho
m <- feols(lag_approval ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr | country_code, s, notes = FALSE)
s$e <- resid(m)
s <- s %>% group_by(country_code) %>% mutate(eL = ifelse(newspell, NA, dplyr::lag(e))) %>% ungroup()
rhos <- s %>% group_by(country_code) %>% summarise(rho = sum(e * eL, na.rm = TRUE) / sum(eL[!is.na(eL)]^2))
cat("mean panel rho", mean(rhos$rho), " pooled", coef(lm(e ~ 0 + eL, s)), "\n")
