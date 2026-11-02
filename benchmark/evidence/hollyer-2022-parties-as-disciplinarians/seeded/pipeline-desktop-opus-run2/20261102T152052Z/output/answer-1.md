suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(rdrobust)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians"

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

results <- list()

## ------------------------------------------------------------------
## Cross-national analysis (Table 1)
## ------------------------------------------------------------------
cn_ok <- tryCatch({
  d <- read_dta(file.path(base_dir, "cross-national-data.dta"))
  d <- as.data.frame(zap_labels(d))
  for (v in names(d)) if (!is.character(d[[v]])) d[[v]] <- as.numeric(d[[v]])
  d$gini <- d$gini / 100

  # Stata summarize, detail percentiles == R quantile type 2
  spct <- function(x, p) as.numeric(quantile(x, probs = p, type = 2, na.rm = TRUE))

  pc <- c("partysize", "unions", "business", "religious")
  cc <- c("pluralty", "pr", "cl", "mdmh", "system", "demsys", "polity", "gdppc", "gini", "ethfrac")
  rhs_controls <- "partysize + unions + business + religious + pluralty + factor(pr) + relevel(factor(cl), ref = '3') + mdmh + relevel(factor(system), ref = '1') + demsys + polity + gdppc + gini + ethfrac"

  fit_model <- function(y, keyvars, keyrhs) {
    vars <- unique(c(y, keyvars, pc, cc, "ccode"))
    s <- d[complete.cases(d[, vars]), , drop = FALSE]
    # ensure base levels exist
    f <- as.formula(paste(y, "~", keyrhs, "+", rhs_controls))
    m <- lm(f, data = s)
    vc <- tryCatch(vcovCL(m, cluster = s$ccode, type = "HC1", cadjust = TRUE), error = function(e) NULL)
    list(m = m, s = s, vc = vc)
  }

  avg_pred <- function(fm, setv) {
    nd <- fm$s
    for (nm in names(setv)) nd[[nm]] <- setv[[nm]]
    mean(predict(fm$m, newdata = nd))
  }

  ## Overall models
  overall <- function(y) {
    fm <- fit_model(y, "ev_total", "ev_total")
    lov <- spct(fm$s$ev_total, 0.25); hiv <- spct(fm$s$ev_total, 0.75)
    lo <- avg_pred(fm, list(ev_total = lov)); hi <- avg_pred(fm, list(ev_total = hiv))
    b <- coef(fm$m)["ev_total"]
    se <- if (!is.null(fm$vc)) sqrt(fm$vc["ev_total", "ev_total"]) * (hiv - lov) else NA
    list(lo = lo, hi = hi, diff = hi - lo, se = se, n = nrow(fm$s),
         nclust = length(unique(fm$s$ccode)))
  }
  o1 <- overall("personal")
  o2 <- overall("programmatic")
  results$personalism_volatility_difference_overall <- o1$diff
  results$programmaticness_volatility_difference_overall <- o2$diff
  results$personalism_volatility_difference_overall_se <- o1$se
  results$programmaticness_volatility_difference_overall_se <- o2$se
  results$personalism_low_volatility_overall <- o1$lo
  results$personalism_high_volatility_overall <- o1$hi
  results$programmaticness_low_volatility_overall <- o2$lo
  results$programmaticness_high_volatility_overall <- o2$hi
  results$n_obs_table1 <- o1$n
  results$n_countries_table1 <- o1$nclust

  ## Interaction models
  interact <- function(y, z) {
    fm <- fit_model(y, c("ev_total", z), paste0(z, " * ev_total"))
    hia <- spct(fm$s[[z]], 0.90)
    lov <- spct(fm$s$ev_total, 0.25); hiv <- spct(fm$s$ev_total, 0.75)
    p11 <- avg_pred(fm, setNames(list(0, lov), c(z, "ev_total")))
    p12 <- avg_pred(fm, setNames(list(0, hiv), c(z, "ev_total")))
    p21 <- avg_pred(fm, setNames(list(hia, lov), c(z, "ev_total")))
    p22 <- avg_pred(fm, setNames(list(hia, hiv), c(z, "ev_total")))
    list(low_diff = p12 - p11, high_diff = p22 - p21,
         gap_lowv = p21 - p11, gap_highv = p22 - p12, hia = hia, n = nrow(fm$s))
  }
  e1 <- interact("personal", "ethnic")
  e2 <- interact("programmatic", "ethnic")
  x1 <- interact("personal", "extremist2")
  x2 <- interact("programmatic", "extremist2")

  results$personalism_volatility_difference_nonethnic <- e1$low_diff
  results$programmaticness_volatility_difference_nonethnic <- e2$low_diff
  results$personalism_ethnic_minus_nonethnic_low_volatility <- e1$gap_lowv
  results$programmaticness_ethnic_minus_nonethnic_high_volatility <- e2$gap_highv
  results$personalism_volatility_difference_moderate <- x1$low_diff
  results$programmaticness_volatility_difference_moderate <- x2$low_diff
  results$personalism_extremist_minus_moderate_low_volatility <- x1$gap_lowv
  results$programmaticness_extremist_minus_moderate_high_volatility <- x2$gap_highv
  results$personalism_volatility_difference_ethnic <- e1$high_diff
  results$programmaticness_volatility_difference_ethnic <- e2$high_diff
  results$personalism_volatility_difference_extremist <- x1$high_diff
  results$programmaticness_volatility_difference_extremist <- x2$high_diff
  results$extremist2_p90 <- x1$hia
  TRUE
}, error = function(e) { message("Cross-national error: ", conditionMessage(e)); FALSE })

## ------------------------------------------------------------------
## Brazil RD (Table 2)
## ------------------------------------------------------------------
rd_ok <- tryCatch({
  b <- read_dta(file.path(base_dir, "brazil-RD-data.dta"))
  b <- as.data.frame(zap_labels(b))
  for (v in names(b)) b[[v]] <- as.numeric(b[[v]])
  idx <- which(b$dlameduck_runs == 0)
  bs <- b[idx, ]
  run_rd <- function(yv) {
    ok <- !is.na(bs[[yv]]) & !is.na(bs$mv_incparty)
    rdrobust(y = bs[[yv]][ok], x = bs$mv_incparty[ok])
  }
  r1 <- run_rd("youngF_inc_for1")
  r2 <- run_rd("outyg1F_inc_for1")
  results$rd_effect_young <- r1$Estimate[1]
  results$rd_effect_young_outsider <- r2$Estimate[1]
  results$rd_young_robust_pvalue <- r1$pv[3]
  results$rd_young_outsider_robust_pvalue <- r2$pv[3]
  results$rd_young_h <- r1$bws["h", 1]
  results$rd_young_outsider_h <- r2$bws["h", 1]
  TRUE
}, error = function(e) { message("RD error: ", conditionMessage(e)); FALSE })

main_names <- c(
  "personalism_volatility_difference_overall",
  "programmaticness_volatility_difference_overall",
  "personalism_volatility_difference_nonethnic",
  "programmaticness_volatility_difference_nonethnic",
  "personalism_ethnic_minus_nonethnic_low_volatility",
  "programmaticness_ethnic_minus_nonethnic_high_volatility",
  "personalism_volatility_difference_moderate",
  "programmaticness_volatility_difference_moderate",
  "personalism_extremist_minus_moderate_low_volatility",
  "programmaticness_extremist_minus_moderate_high_volatility",
  "n_obs_table1",
  "rd_effect_young",
  "rd_effect_young_outsider"
)
for (nm in main_names) emit(nm, results[[nm]])
for (nm in setdiff(names(results), main_names)) emit(nm, results[[nm]])
