# Holman, Merolla & Zechmeister (2022) -- independent reproduction of Table 2 and Table 4
library(haven); library(dplyr)
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-07-a/mount/holman_2022_theresa_may_rally"

## ---------------- Table 2: difference-in-differences on BES panel ----------------
dd <- zap_labels(read_dta(file.path(D, "did_data.dta"),
  col_select = c(id, wave, time, treatment1, likeMayW, bestPMW, white, gender, labour, party_other, income, ideology2)))
ctrls <- c("white", "gender", "labour", "party_other", "income", "ideology2")

did <- function(dv) {
  s <- dd[complete.cases(dd[, c(dv, "treatment1", "time", ctrls, "wave")]), ]
  waves <- sort(unique(s$wave))
  # wave dummies: base = first wave; time is collinear with wave dummies, so (as Stata
  # would when time enters before i.wave) the last post-attack wave dummy is omitted
  keep <- setdiff(waves, c(min(waves), max(waves)))
  for (w in keep) s[[paste0("w", w)]] <- as.numeric(s$wave == w)
  s$attack_x_time <- s$treatment1 * s$time
  f <- as.formula(paste(dv, "~ attack_x_time + treatment1 + time +", paste(ctrls, collapse = "+"), "+",
                        paste0("w", keep, collapse = "+")))
  m <- lm(f, data = s)
  list(b = coef(m), n = nobs(m))
}
like <- did("likeMayW")   # OLS, 0-10 scale
bpm  <- did("bestPMW")    # linear probability model, 1 = May, 0 = Corbyn

## ---------------- Table 4: global executive approval ----------------
g <- zap_labels(read_dta(file.path(D, "global_approval.dta")))
# country_code 33 and 34 are both "Macedonia" (same country, duplicated panel); keep one
g <- g %>% filter(country_code != 34) %>% arrange(country_code, qtr) %>% group_by(country_code) %>%
  # 'growth' holds the level of real GDP (annual, repeated by quarter); convert to
  # year-on-year growth in percent, as the paper controls for GDP growth
  mutate(gdp_growth = ifelse(lag(qtr, 4) == qtr - 4, 100 * (growth / lag(growth, 4) - 1), NA)) %>% ungroup()
# DV: 'lag_approval' is approval in the following quarter (it is missing in each country's last quarter)
# Attack: kill_16 = international attack with 16+ (i.e. more than 15) deaths
m4 <- lm(lag_approval ~ kill_16 * female_pres + gdp_growth + log_inflation + execrlc + election_qtr +
           factor(country_code), data = g)
b4 <- coef(m4)

cat("DEVIATION: Table 2 May-best-PM column estimated as a linear probability model (coefficients reported on the probability scale)\n")
cat("DEVIATION: Table 4 estimated by OLS with country dummies (panel-corrected SEs affect only standard errors, not reported here)\n")
cat(sprintf("RESULT:intl_attack_table4=%.4f\n", b4["kill_16"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.4f\n", b4["kill_16:female_pres"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nobs(m4)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.4f\n", like$b["attack_x_time"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.4f\n", like$b["treatment1"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.4f\n", like$b["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.4f\n", bpm$b["attack_x_time"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.4f\n", bpm$b["treatment1"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.4f\n", bpm$b["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", like$n))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", bpm$n))
