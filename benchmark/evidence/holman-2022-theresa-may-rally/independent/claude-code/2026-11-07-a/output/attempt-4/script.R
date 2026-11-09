library(haven); library(dplyr); library(fixest)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-07-a/mount/holman_2022_theresa_may_rally"
g <- zap_labels(read_dta(file.path(D,"global_approval.dta")))
vars <- c("lag_approval","kill_16","female_pres","growth","log_inflation","execrlc","election_qtr")
s <- g[complete.cases(g[,vars]),] %>% arrange(country_code, qtr) %>% group_by(country_code) %>%
  mutate(newrun = is.na(lag(qtr)) | qtr != lag(qtr)+1, run = cumsum(newrun)) %>% ungroup()
cat("N", nrow(s), "runs", sum(s$newrun), "N - runs", nrow(s)-sum(s$newrun), "panels", length(unique(s$country_code)), "\n")
# OLS w/ dummies, residuals, rho
X <- model.matrix(~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr + factor(country_code), s)
y <- s$lag_approval
ols <- lm.fit(X, y); e <- ols$residuals
s$e <- e
s <- s %>% group_by(country_code) %>% mutate(el = ifelse(newrun, NA, lag(e))) %>% ungroup()
# rho regress per panel then average
rp <- s %>% group_by(country_code) %>% summarise(r = { ok <- !is.na(el); sum(e[ok]*el[ok])/sum(el[ok]^2) }, rf = { ok <- !is.na(el); sum(e[ok]*el[ok])/sum(e^2) })
rho_reg <- mean(rp$r); rho_freg <- mean(rp$rf)
ok <- !is.na(s$el); rho_pool <- sum(s$e[ok]*s$el[ok])/sum(s$el[ok]^2)
cat("rho reg-avg", rho_reg, " freg", rho_freg, " pooled", rho_pool, "\n")
pw <- function(rho, keepfirst=TRUE) {
  Xt <- X; yt <- y
  idx <- which(!s$newrun)
  Xt[idx,] <- X[idx,] - rho*X[idx-1,]; yt[idx] <- y[idx] - rho*y[idx-1]
  f <- which(s$newrun)
  Xt[f,] <- X[f,]*sqrt(1-rho^2); yt[f] <- y[f]*sqrt(1-rho^2)
  if (!keepfirst) { Xt <- Xt[idx,]; yt <- yt[idx] }
  fit <- lm.fit(Xt, yt)
  b <- fit$coefficients
  r2 <- 1 - sum(fit$residuals^2)/sum((yt-mean(yt))^2)
  cat(sprintf("rho=%.4f keep=%s N=%d b1=%.3f bint=%.3f cons=%.3f R2=%.4f\n", rho, keepfirst, length(yt), b["kill_16"], b["kill_16:female_pres"], b["(Intercept)"], r2))
}
for (r in c(rho_reg, rho_freg, rho_pool)) { pw(r, TRUE); pw(r, FALSE) }
cat("OLS cons", ols$coefficients[1], "\n")
