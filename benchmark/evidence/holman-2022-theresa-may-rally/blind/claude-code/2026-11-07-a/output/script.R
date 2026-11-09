# Holman, Merolla & Zechmeister (2022) -- independent, blind reproduction
# Table 4 (global executive approval TSCS) and Table 2 (BES panel DiD)
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-07-a/mount/holman_2022_theresa_may_rally"
res <- list()

## ---------------- Table 4 ----------------
g <- read_dta(file.path(D, "global_approval.dta"))
g <- zap_labels(g)
# Attack indicator: international terrorist attack with more than 15 deaths (kill_16 = 16+ deaths;
# 60 country-quarters, matching the paper's count). Outcome: executive approval (lag_approval, the only
# approval series in the file). Country (country x office, 'country_code') fixed effects.
g4 <- g %>% filter(!is.na(lag_approval), !is.na(kill_16), !is.na(female_pres), !is.na(growth),
                   !is.na(log_inflation), !is.na(execrlc), !is.na(election_qtr), !is.na(country_code))
cat("Table 4: attack quarters in data:", sum(g$kill_16 == 1, na.rm = TRUE),
    "; in estimation sample:", sum(g4$kill_16 == 1), "; under women:", sum(g4$kill_16 == 1 & g4$female_pres == 1), "\n")
m4 <- lm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + execrlc + election_qtr +
           factor(country_code), data = g4)
b4 <- coef(m4)
# Panel-corrected (Beck-Katz) standard errors for reference
pc <- tryCatch({
  library(plm)
  pd <- pdata.frame(as.data.frame(g4), index = c("country_code", "qtr"))
  mp <- plm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + execrlc + election_qtr,
            data = pd, model = "within")
  sqrt(diag(vcovBK(mp, cluster = "time")))
}, error = function(e) { cat("PCSE failed:", conditionMessage(e), "\n"); NULL })
cat("Table 4 coefficients:\n"); print(b4[c("kill_16", "female_pres", "kill_16:female_pres", "growth",
                                           "log_inflation", "execrlc", "election_qtr")])
if (!is.null(pc)) { cat("PCSE:\n"); print(pc) }
cat("R2:", summary(m4)$r.squared, " N:", nobs(m4), "\n")
res$intl_attack_table4 <- b4[["kill_16"]]
res$intl_attack_x_woman_exec_table4 <- b4[["kill_16:female_pres"]]
res$n_obs_table4 <- nobs(m4)

## ---------------- Table 2 ----------------
d <- read_dta(file.path(D, "did_data.dta"),
              col_select = c(id, wave, likeMayW, bestPMW, treatment1, post_attack, time,
                             white, gender, labour, party_other, income, ideology2))
d <- zap_labels(d)
d$likeMayW[d$likeMayW > 10] <- NA
d$bestPMW[!(d$bestPMW %in% c(0, 1))] <- NA
d$female <- as.numeric(d$gender == 2)
cat("treatment1 == post_attack:", all(d$treatment1 == d$post_attack, na.rm = TRUE), "\n")
# Manchester attack (surveyed after the attack in wave 12), time (waves >= 12), interaction,
# wave fixed effects, full controls (ethnically British, gender, Labour, other party, income,
# ideology with missing coded to the scale midpoint = ideology2). Time is collinear with the wave
# dummies; as in Stata, the last collinear wave dummy is the one dropped.
f <- ~ treatment1 + time + factor(wave) + white + female + labour + party_other + income + ideology2 + treatment1:time

dl <- d %>% filter(!is.na(likeMayW))
ml <- lm(update(f, likeMayW ~ .), data = dl)
cat("Like May (OLS):\n"); print(summary(ml)$coefficients)
dl_n <- nobs(ml)

db <- d %>% filter(!is.na(bestPMW))
mb <- glm(update(f, bestPMW ~ .), data = db, family = binomial("logit"))
cat("May best PM (logit):\n"); print(summary(mb)$coefficients)
cat("Aliased (like):", names(coef(ml))[is.na(coef(ml))], " (bestPM):", names(coef(mb))[is.na(coef(mb))], "\n")

res$did_attack_x_time_like_may_table2 <- coef(ml)[["treatment1:time"]]
res$did_attack_like_may_table2 <- coef(ml)[["treatment1"]]
res$did_time_like_may_table2 <- coef(ml)[["time"]]
res$did_attack_x_time_may_best_pm_table2 <- coef(mb)[["treatment1:time"]]
res$did_attack_may_best_pm_table2 <- coef(mb)[["treatment1"]]
res$did_time_may_best_pm_table2 <- coef(mb)[["time"]]
res$n_obs_did_like_may_table2 <- dl_n
res$n_obs_did_may_best_pm_table2 <- nobs(mb)

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
