# Independent reproduction: Holman, Merolla & Zechmeister (2022), Tables 2 and 4
suppressMessages({library(haven); library(dplyr); library(plm); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4: global executive approval ----------------
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
# DV: the dataset's executive approval measure (lag_approval, aligned by the authors);
# attack: international attack with more than 15 deaths (kill_16 = 16+ deaths);
# woman executive: female_pres; controls: GDP (growth), log inflation, DPI executive
# left-centre-right placement (execrlc, entered linearly), election; country fixed effects.
gv <- c("lag_approval", "kill_16", "female_pres", "growth", "log_inflation", "execrlc", "election_qtr", "country_code", "qtr")
gs <- g[complete.cases(g[, gv]), gv]
m4 <- lm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + execrlc +
           election_qtr + factor(country_code), data = gs)
# Panel-corrected (Beck-Katz) standard errors
pg <- pdata.frame(gs, index = c("country_code", "qtr"))
m4p <- plm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + execrlc + election_qtr,
           data = pg, model = "within")
vbk <- vcovBK(m4p, cluster = "time")
cat("Table 4 (OLS, country FE), coefficients:\n"); print(coef(m4)[c("kill_16", "female_pres", "kill_16:female_pres")])
cat("Panel-corrected SEs (within model):\n"); print(coeftest(m4p, vcov = vbk)[c("kill_16", "kill_16:female_pres"), ])
cat("R2 (LSDV):", summary(m4)$r.squared, " N:", nobs(m4), "\n")

## ---------------- Table 2: BES panel difference-in-differences ----------------
dd0 <- read_dta(file.path(D, "did_data.dta"),
               col_select = c(id, wave, likeMayW, bestPMW, post_attack, time, white, gender,
                              labour, party_other, income, ideology2)) %>% zap_labels()
# Manchester attack: respondent surveyed after the 22 May 2017 bombing in wave 12 (post_attack)
dd <- dd0 %>% mutate(treatment1 = post_attack)
ctrl <- "white + gender + labour + party_other + income + ideology2"
# May likeability (OLS), waves with the like-May item (9-16), wave fixed effects.
# time is collinear with the wave dummies; R drops the last collinear wave dummy (as Stata does).
f_like <- as.formula(paste("likeMayW ~ treatment1 + time + treatment1:time + factor(wave) +", ctrl))
m_like <- lm(f_like, data = dd)
# May best PM (1 = May, 0 = Corbyn), same specification, linear probability model
f_bpm <- as.formula(paste("bestPMW ~ treatment1 + time + treatment1:time + factor(wave) +", ctrl))
m_bpm <- lm(f_bpm, data = dd)
cat("Table 2 May likeability:\n"); print(summary(m_like)$coefficients[c("treatment1:time", "treatment1", "time", "(Intercept)"), ])
cat("Table 2 May best PM (LPM):\n"); print(summary(m_bpm)$coefficients[c("treatment1:time", "treatment1", "time", "(Intercept)"), ])
cat("Dropped (aliased) terms like:", names(coef(m_like))[is.na(coef(m_like))], "\n")
cat("Dropped (aliased) terms bpm:", names(coef(m_bpm))[is.na(coef(m_bpm))], "\n")

## Diagnostics (alternative specifications; not scored)
g2 <- g %>% group_by(country_code) %>% mutate(
  lead1 = ifelse(dplyr::lead(qtr) == qtr + 1, dplyr::lead(lag_approval), NA),
  lead2 = ifelse(dplyr::lead(qtr, 2) == qtr + 2, dplyr::lead(lag_approval, 2), NA),
  lagk = ifelse(dplyr::lag(qtr) == qtr - 1, dplyr::lag(kill_16), NA)) %>% ungroup()
for (dv in c("lag_approval", "lead1", "lead2")) for (rlc in c("execrlc", "factor(execrlc)")) {
  f <- as.formula(paste(dv, "~ kill_16 * female_pres + growth + log_inflation +", rlc, "+ election_qtr + factor(country_code)"))
  m <- lm(f, data = g2)
  cat(sprintf("diag T4 dv=%s rlc=%s: attack=%.3f inter=%.3f N=%d R2=%.4f\n", dv, rlc, coef(m)["kill_16"], coef(m)["kill_16:female_pres"], nobs(m), summary(m)$r.squared))
}
m <- lm(lag_approval ~ lagk * female_pres + growth + log_inflation + execrlc + election_qtr + factor(country_code), data = g2)
cat(sprintf("diag T4 lagged attack: attack=%.3f inter=%.3f N=%d R2=%.4f\n", coef(m)["lagk"], coef(m)["lagk:female_pres"], nobs(m), summary(m)$r.squared))
rm(dd); gc()
dt1 <- read_dta(file.path(D, "did_data.dta"), col_select = c(treatment1))$treatment1
dd0$treatment1 <- as.numeric(dt1); rm(dt1)
ml <- lm(f_like, data = dd0); mb <- lm(f_bpm, data = dd0)
cat(sprintf("diag T2 treatment1: like inter=%.4f att=%.4f time=%.4f | bpm inter=%.4f att=%.4f time=%.4f\n",
  coef(ml)["treatment1:time"], coef(ml)["treatment1"], coef(ml)["time"], coef(mb)["treatment1:time"], coef(mb)["treatment1"], coef(mb)["time"]))
rm(ml, mb); gc()

cat("DEVIATION: Table 2 May best PM column estimated as a linear probability model (OLS), not logit\n")
cat("DEVIATION: Table 4 approval timing uses the dataset's lag_approval with the contemporaneous kill_16 indicator\n")

out <- c(
  intl_attack_table4 = unname(coef(m4)["kill_16"]),
  intl_attack_x_woman_exec_table4 = unname(coef(m4)["kill_16:female_pres"]),
  n_obs_table4 = nobs(m4),
  did_attack_x_time_like_may_table2 = unname(coef(m_like)["treatment1:time"]),
  did_attack_like_may_table2 = unname(coef(m_like)["treatment1"]),
  did_time_like_may_table2 = unname(coef(m_like)["time"]),
  did_attack_x_time_may_best_pm_table2 = unname(coef(m_bpm)["treatment1:time"]),
  did_attack_may_best_pm_table2 = unname(coef(m_bpm)["treatment1"]),
  did_time_may_best_pm_table2 = unname(coef(m_bpm)["time"]),
  n_obs_did_like_may_table2 = nobs(m_like),
  n_obs_did_may_best_pm_table2 = nobs(m_bpm))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
