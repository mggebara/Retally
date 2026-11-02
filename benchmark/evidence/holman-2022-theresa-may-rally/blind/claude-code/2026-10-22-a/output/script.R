# Independent blind reproduction: Holman, Merolla & Zechmeister (2022), Tables 2 and 4
suppressPackageStartupMessages({library(haven); library(dplyr)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-a/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4: global executive approval -----------------
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels()
# DV: lag_approval (approval in the quarter following the attack; the only approval measure)
# attack: kill_16 = international attack with 16+ deaths (i.e. more than 15 deaths; 60 country-quarters)
# woman executive: female_pres; controls: growth (real GDP), log_inflation, execrlc, election_qtr
# country FE: country_code (66 country-office units)
vars4 <- c("lag_approval","kill_16","female_pres","growth","log_inflation","execrlc","election_qtr","country_code","qtr")
g4 <- g[complete.cases(g[, vars4]), vars4]
m4 <- lm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + execrlc + election_qtr +
           factor(country_code), data = g4)
b4 <- coef(m4)
cat("Table 4 model: N =", nobs(m4), " units =", length(unique(g4$country_code)), " R2 =", summary(m4)$r.squared, "\n")
print(summary(m4)$coefficients[c("kill_16","female_pres","kill_16:female_pres","growth","log_inflation","execrlc","election_qtr"), ])

# Panel-corrected SEs (Beck-Katz, casewise, contemporaneous correlation across units by period)
X <- model.matrix(m4); e <- resid(m4)
X <- X[, !is.na(b4), drop = FALSE]
units <- g4$country_code; times <- g4$qtr
U <- sort(unique(units)); Ti <- sort(unique(times))
E <- matrix(NA_real_, length(Ti), length(U)); E[cbind(match(times, Ti), match(units, U))] <- e
Sigma <- matrix(0, length(U), length(U))
for (i in seq_along(U)) for (j in i:length(U)) {
  ok <- !is.na(E[, i]) & !is.na(E[, j])
  s <- if (sum(ok) > 0) sum(E[ok, i] * E[ok, j]) / sum(ok) else 0
  Sigma[i, j] <- Sigma[j, i] <- s
}
meat <- matrix(0, ncol(X), ncol(X))
for (t in seq_along(Ti)) {
  idx <- which(times == Ti[t]); if (!length(idx)) next
  ui <- match(units[idx], U)
  Xt <- X[idx, , drop = FALSE]
  meat <- meat + t(Xt) %*% Sigma[ui, ui, drop = FALSE] %*% Xt
}
QX <- qr(X); bi <- chol2inv(qr.R(QX))  # (X'X)^-1 via QR, numerically stable (growth is on a ~1e7 scale)
bread <- bi; bread[QX$pivot, QX$pivot] <- bi
dimnames(bread) <- list(colnames(X), colnames(X))
V <- bread %*% meat %*% bread
pcse <- sqrt(diag(V))
cat("PCSE: attack", pcse["kill_16"], " interaction", pcse["kill_16:female_pres"], "\n")

## ---------------- Table 2: BES panel difference-in-differences ----------------
d <- read_dta(file.path(D, "did_data.dta"),
              col_select = c("id","wave","time","treatment1","likeMayW","bestPMW",
                             "white","gender","labour","party_other","income","ideology2")) %>% zap_labels()
d$likeMayW[d$likeMayW == 9999] <- NA
d$gender <- as.numeric(d$gender == 2)  # female indicator
ctrl <- c("white","gender","labour","party_other","income","ideology2")

# time is entered before the wave dummies so that the collinear (last) wave dummy is the one dropped
f_like <- as.formula(paste("likeMayW ~ treatment1 + time + treatment1:time + factor(wave) +", paste(ctrl, collapse = " + ")))
f_bpm  <- as.formula(paste("bestPMW ~ treatment1 + time + treatment1:time + factor(wave) +", paste(ctrl, collapse = " + ")))

dl <- d[complete.cases(d[, c("likeMayW","treatment1","time","wave",ctrl)]), ]
cat("likeMay waves:\n"); print(table(dl$wave))
m_like <- lm(f_like, data = dl)
print(summary(m_like)$coefficients)

db <- d[complete.cases(d[, c("bestPMW","treatment1","time","wave",ctrl)]), ]
cat("bestPM waves:\n"); print(table(db$wave))
m_bpm <- glm(f_bpm, data = db, family = binomial("logit"))
print(summary(m_bpm)$coefficients)
cat("aliased (like):", names(coef(m_like))[is.na(coef(m_like))], "\n")
cat("aliased (bpm):", names(coef(m_bpm))[is.na(coef(m_bpm))], "\n")

bl <- coef(m_like); bb <- coef(m_bpm)
out <- c(
  intl_attack_table4 = unname(b4["kill_16"]),
  intl_attack_x_woman_exec_table4 = unname(b4["kill_16:female_pres"]),
  n_obs_table4 = nobs(m4),
  did_attack_x_time_like_may_table2 = unname(bl["treatment1:time"]),
  did_attack_like_may_table2 = unname(bl["treatment1"]),
  did_time_like_may_table2 = unname(bl["time"]),
  did_attack_x_time_may_best_pm_table2 = unname(bb["treatment1:time"]),
  did_attack_may_best_pm_table2 = unname(bb["treatment1"]),
  did_time_may_best_pm_table2 = unname(bb["time"]),
  n_obs_did_like_may_table2 = nobs(m_like),
  n_obs_did_may_best_pm_table2 = nobs(m_bpm)
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6g\n", n, out[[n]]))
