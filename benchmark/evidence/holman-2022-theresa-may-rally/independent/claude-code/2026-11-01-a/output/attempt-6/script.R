# Independent reproduction: Holman, Merolla & Zechmeister (2022), Tables 2 and 4
suppressMessages({library(haven); library(dplyr); library(plm); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4: global executive approval ----------------
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
# DV: the dataset's executive approval measure (lag_approval, aligned by the authors);
# attack: international attack with more than 15 deaths (kill_16 = 16+ deaths);
# woman executive: female_pres; controls: GDP (growth), log inflation, DPI executive
# left-centre-right placement (execrlc, categorical), election; country fixed effects.
gv <- c("lag_approval", "kill_16", "female_pres", "growth", "log_inflation", "execrlc", "election_qtr", "country_code", "qtr")
gs <- g[complete.cases(g[, gv]), gv]
m4 <- lm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + factor(execrlc) +
           election_qtr + factor(country_code), data = gs)
# Panel-corrected (Beck-Katz) standard errors
pg <- pdata.frame(gs, index = c("country_code", "qtr"))
m4p <- plm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + factor(execrlc) + election_qtr,
           data = pg, model = "within")
vbk <- vcovBK(m4p, cluster = "time")
cat("Table 4 (OLS, country FE), coefficients:\n"); print(coef(m4)[c("kill_16", "female_pres", "kill_16:female_pres")])
cat("Panel-corrected SEs (within model):\n"); print(coeftest(m4p, vcov = vbk)[c("kill_16", "kill_16:female_pres"), ])
cat("R2 (LSDV):", summary(m4)$r.squared, " N:", nobs(m4), "\n")

## ---------------- Table 2: BES panel difference-in-differences ----------------
dd <- read_dta(file.path(D, "did_data.dta"),
               col_select = c(id, wave, likeMayW, bestPMW, treatment1, time, white, gender,
                              labour, party_other, income, ideology2)) %>% zap_labels()
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
