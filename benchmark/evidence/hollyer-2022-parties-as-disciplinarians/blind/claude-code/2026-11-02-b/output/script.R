## Hollyer, Klasnja & Titiunik (2022) -- independent blind reproduction of Table 1 and Table 2
suppressPackageStartupMessages({library(haven); library(sandwich); library(lmtest); library(rdrobust)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-b/mount/hollyer_2022_parties_as_disciplinarians"

## ---------------- Table 1: cross-national party-level OLS ----------------
x <- as.data.frame(zap_labels(read_dta(file.path(D, "cross-national-data.dta"))))
x$ethnic_party <- as.numeric(x$ethnic > 0.5)          # majority of experts report ethnic/linguistic ties
x$closed_list  <- as.numeric(x$cl == 1)                # omitted: non-list (mainly SMDP)
x$open_list    <- as.numeric(x$cl == 2)
x$sys_assembly <- as.numeric(x$system == 1)            # omitted: presidential
x$sys_parl     <- as.numeric(x$system == 2)
covs <- c("partysize","unions","business","religious",                    # party level
          "pluralty","pr","closed_list","open_list","mdmh","polity",       # country level (mixed system omitted)
          "demsys","sys_assembly","sys_parl","gdppc","gini","ethfrac")

fit <- function(y, extra = NULL) {
  d <- x[complete.cases(x[, c(y, "ev_total", extra, covs, "ccode")]), ]
  if (!is.null(extra)) d$inter <- d$ev_total * d[[extra]]
  f <- as.formula(paste(y, "~", paste(c("ev_total", extra, if (!is.null(extra)) "inter", covs), collapse = " + ")))
  m <- lm(f, data = d)
  V <- vcovCL(m, cluster = ~ccode, type = "HC1")
  q <- quantile(d$ev_total, c(.25, .75), type = 2)     # Stata-style sample percentiles (party level, estimation sample)
  list(m = m, V = V, d = d, lo = unname(q[1]), hi = unname(q[2]))
}
lincom <- function(r, w) {  # w: named weights over coefficients
  b <- coef(r$m); g <- setNames(rep(0, length(b)), names(b)); g[names(w)] <- w
  est <- sum(g * b); se <- sqrt(drop(t(g) %*% r$V %*% g)); c(est = est, se = se)
}

out <- list()
for (y in c("personal", "programmatic")) {
  lab <- ifelse(y == "personal", "personalism", "programmaticness")
  ## Overall
  r0 <- fit(y)
  e <- lincom(r0, c(ev_total = r0$hi - r0$lo))
  cat(sprintf("%s overall: N=%d countries=%d p25=%.4f p75=%.4f diff=%.4f (se %.4f)\n", lab, nrow(r0$d), length(unique(r0$d$ccode)), r0$lo, r0$hi, e[1], e[2]))
  out[[paste0(lab, "_volatility_difference_overall")]] <- e[1]
  if (y == "personal") n_obs <- nrow(r0$d)
  ## Ethnicity
  r1 <- fit(y, "ethnic_party")
  e1 <- lincom(r1, c(ev_total = r1$hi - r1$lo))
  dlo <- lincom(r1, c(ethnic_party = 1, inter = r1$lo))
  dhi <- lincom(r1, c(ethnic_party = 1, inter = r1$hi))
  cat(sprintf("%s ethnic: N=%d nonethnic diff=%.4f (%.4f); eth-non low=%.4f (%.4f) high=%.4f (%.4f)\n", lab, nrow(r1$d), e1[1], e1[2], dlo[1], dlo[2], dhi[1], dhi[2]))
  out[[paste0(lab, "_volatility_difference_nonethnic")]] <- e1[1]
  if (y == "personal") out[["personalism_ethnic_minus_nonethnic_low_volatility"]] <- dlo[1]
  if (y == "programmatic") out[["programmaticness_ethnic_minus_nonethnic_high_volatility"]] <- dhi[1]
  ## Ideology (extremist party at distance 3, moderate at 0)
  r2 <- fit(y, "extremist2")
  e2 <- lincom(r2, c(ev_total = r2$hi - r2$lo))
  xlo <- lincom(r2, c(extremist2 = 3, inter = 3 * r2$lo))
  xhi <- lincom(r2, c(extremist2 = 3, inter = 3 * r2$hi))
  cat(sprintf("%s ideology: N=%d moderate diff=%.4f (%.4f); ext-mod low=%.4f (%.4f) high=%.4f (%.4f)\n", lab, nrow(r2$d), e2[1], e2[2], xlo[1], xlo[2], xhi[1], xhi[2]))
  out[[paste0(lab, "_volatility_difference_moderate")]] <- e2[1]
  if (y == "personal") out[["personalism_extremist_minus_moderate_low_volatility"]] <- xlo[1]
  if (y == "programmatic") out[["programmaticness_extremist_minus_moderate_high_volatility"]] <- xhi[1]
}
out[["n_obs_table1"]] <- n_obs

## ---------------- Table 2: Brazil RD, open-seat sample ----------------
r <- as.data.frame(zap_labels(read_dta(file.path(D, "brazil-RD-data.dta"))))
r <- r[!is.na(r$dlameduck_runs) & r$dlameduck_runs == 0, ]
for (v in c("youngF_inc_for1", "outyg1F_inc_for1")) {
  rd <- rdrobust(y = r[[v]], x = r$mv_incparty, c = 0, p = 1, kernel = "triangular", bwselect = "mserd")
  cat(sprintf("RD %s: tau=%.4f h=%.3f b=%.3f N-=%d N+=%d robust CI=[%.3f, %.3f]\n", v, rd$coef[1], rd$bws[1,1], rd$bws[2,1],
              rd$N_h[1], rd$N_h[2], rd$ci[3,1], rd$ci[3,2]))
  out[[ifelse(v == "youngF_inc_for1", "rd_effect_young", "rd_effect_young_outsider")]] <- rd$coef[1]
}

for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(out[[n]])))
