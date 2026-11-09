library(haven); library(dplyr)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-07-a/mount/holman_2022_theresa_may_rally"
g <- zap_labels(read_dta(file.path(D,"global_approval.dta")))
g <- g %>% filter(country_code!=34) %>% arrange(country_code, qtr) %>% group_by(country_code) %>%
  mutate(gr4 = ifelse(lag(qtr,4)==qtr-4, 100*(growth/lag(growth,4)-1), NA)) %>% ungroup()
for (gv in c("gr4","growth")) {
vars <- c("lag_approval","kill_16","female_pres",gv,"log_inflation","execrlc","election_qtr")
s <- g[complete.cases(g[,vars]),] %>% arrange(country_code, qtr) %>% group_by(country_code) %>%
  mutate(newrun = is.na(lag(qtr)) | qtr != lag(qtr)+1) %>% ungroup()
s$gv <- s[[gv]]
X <- model.matrix(~ kill_16*female_pres + gv + log_inflation + execrlc + election_qtr + factor(country_code), s)
y <- s$lag_approval
ols <- lm.fit(X, y); e <- ols$residuals; s$e <- e
cat(gv, "N", nrow(s), "OLS R2", 1-sum(e^2)/sum((y-mean(y))^2), "\n")
s <- s %>% group_by(country_code) %>% mutate(el = ifelse(newrun, NA, lag(e)), elpos = lag(e)) %>% ungroup()
rp <- s %>% group_by(country_code) %>% summarise(r = { ok <- !is.na(el); sum(e[ok]*el[ok])/sum(el[ok]^2) },
   rpos = { ok <- !is.na(elpos); sum(e[ok]*elpos[ok])/sum(elpos[ok]^2) })
pw <- function(rho, gaps=TRUE) {
  nr <- if (gaps) s$newrun else !duplicated(s$country_code)
  Xt <- X; yt <- y; idx <- which(!nr)
  Xt[idx,] <- X[idx,] - rho*X[idx-1,]; yt[idx] <- y[idx] - rho*y[idx-1]
  f <- which(nr); Xt[f,] <- X[f,]*sqrt(1-rho^2); yt[f] <- y[f]*sqrt(1-rho^2)
  fit <- lm.fit(Xt, yt); b <- fit$coefficients
  r2 <- 1 - sum(fit$residuals^2)/sum((yt-mean(yt))^2)
  cat(sprintf("  rho=%.4f gaps=%s b1=%.3f bint=%.3f cons=%.3f R2=%.4f\n", rho, gaps, b["kill_16"], b["kill_16:female_pres"], b["(Intercept)"], r2))
}
pw(mean(rp$r)); pw(mean(rp$rpos), FALSE)
cat("  OLS b1", ols$coefficients["kill_16"], "bint", ols$coefficients["kill_16:female_pres"], "cons", ols$coefficients[1], "\n")
}
