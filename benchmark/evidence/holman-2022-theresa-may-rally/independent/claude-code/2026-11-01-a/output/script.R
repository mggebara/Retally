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
# Panel models (respondent random effects, Stata xtreg default) with wave fixed effects.
# time is collinear with the wave dummies, so the last collinear wave dummy is dropped (as Stata does).
fit_re <- function(dv) {
  d <- dd[!is.na(dd[[dv]]), c("id", "wave", dv, "treatment1", "time", "white", "gender", "labour", "party_other", "income", "ideology2")]
  d <- d[complete.cases(d), ]
  waves <- sort(unique(d$wave)); keep <- waves[-c(1, length(waves))]   # base = first wave; last wave aliased with time
  for (w in keep) d[[paste0("w", w)]] <- as.numeric(d$wave == w)
  d$att_time <- d$treatment1 * d$time
  f <- as.formula(paste(dv, "~ att_time + treatment1 + time +", paste0("w", keep, collapse = " + "), "+", ctrl))
  m <- plm(f, data = pdata.frame(as.data.frame(d), index = c("id", "wave")), model = "random", random.method = "swar")
  list(m = m, n = nobs(m), cf = summary(m)$coefficients)
}
r_like <- fit_re("likeMayW"); r_bpm <- fit_re("bestPMW")
cat("Table 2 May likeability (RE):\n"); print(r_like$cf[c("att_time", "treatment1", "time", "(Intercept)"), ])
cat("Table 2 May best PM (RE LPM):\n"); print(r_bpm$cf[c("att_time", "treatment1", "time", "(Intercept)"), ])

cat("DEVIATION: Table 2 May best PM column estimated as a linear probability model (random-effects GLS), not logit\n")
cat("DEVIATION: Table 4 approval timing uses the dataset's lag_approval with the contemporaneous kill_16 indicator\n")

out <- c(
  intl_attack_table4 = unname(coef(m4)["kill_16"]),
  intl_attack_x_woman_exec_table4 = unname(coef(m4)["kill_16:female_pres"]),
  n_obs_table4 = nobs(m4),
  did_attack_x_time_like_may_table2 = unname(coef(r_like$m)["att_time"]),
  did_attack_like_may_table2 = unname(coef(r_like$m)["treatment1"]),
  did_time_like_may_table2 = unname(coef(r_like$m)["time"]),
  did_attack_x_time_may_best_pm_table2 = unname(coef(r_bpm$m)["att_time"]),
  did_attack_may_best_pm_table2 = unname(coef(r_bpm$m)["treatment1"]),
  did_time_may_best_pm_table2 = unname(coef(r_bpm$m)["time"]),
  n_obs_did_like_may_table2 = r_like$n,
  n_obs_did_may_best_pm_table2 = r_bpm$n)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
