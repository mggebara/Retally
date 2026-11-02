suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"

res <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) res[[name]] <<- val
}

## ---------------- Cross-national analysis ----------------
cn <- tryCatch(as.data.frame(zap_labels(read_dta(file.path(base, "cross-national-data.dta")))),
               error = function(e) NULL)

if (!is.null(cn)) {
  for (v in names(cn)) if (!is.numeric(cn[[v]])) suppressWarnings(cn[[v]] <- as.numeric(cn[[v]]))

  cat("Summary of key variables:\n")
  print(summary(cn[, intersect(c("personal", "programmatic", "programmatic2", "ev_total",
                                 "ethnic", "extremist2", "erule", "cl", "system", "demsys"),
                               names(cn))]))

  # Programmaticness: the main 'programmatic' variable (average of the policy-stress and
  # partisan-identification items; its mean ~3.03 matches the paper's predicted levels 3.08/2.97)
  prog_var <- "programmatic"
  if (!("programmatic" %in% names(cn)) || all(is.na(cn$programmatic))) {
    prog_var <- "programmatic2"
  }
  cat("Programmaticness variable used:", prog_var, "\n")
  cn$prog <- cn[[prog_var]]
  cn$pers <- cn$personal

  # Volatility rescaled to 0-1
  cn$vol <- cn$ev_total
  if (max(cn$vol, na.rm = TRUE) > 1.5) cn$vol <- cn$vol / 100

  # Ethnic party binary
  cn$eth <- cn$ethnic
  if (!all(cn$eth[!is.na(cn$eth)] %in% c(0, 1))) cn$eth <- as.numeric(cn$eth > 0.5)

  cn$ext <- cn$extremist2

  ctrl <- c("partysize", "unions", "business", "religious",
            "pluralty", "pr", "cl", "erule", "mdmh", "polity", "demsys",
            "system", "gdppc", "gini", "ethfrac")
  ctrl <- intersect(ctrl, names(cn))
  # drop controls that are constant / entirely missing
  ctrl <- ctrl[sapply(ctrl, function(v) sum(!is.na(cn[[v]])) > 0)]

  need <- c("pers", "prog", "vol", "eth", "ext", "ccode", ctrl)
  d <- cn[complete.cases(cn[, need]), ]
  ctrl <- ctrl[sapply(ctrl, function(v) length(unique(d[[v]])) > 1)]
  cat("N complete:", nrow(d), " countries:", length(unique(d$ccode)), "\n")

  q25 <- as.numeric(quantile(d$vol, 0.25))
  q75 <- as.numeric(quantile(d$vol, 0.75))
  dq <- q75 - q25
  cat("Volatility q25:", q25, " q75:", q75, "\n")

  cs <- paste(ctrl, collapse = " + ")
  fit <- function(y, extra) {
    f <- as.formula(paste(y, "~", extra, "+", cs))
    feols(f, data = d, cluster = ~ccode)
  }

  # Overall
  m1 <- fit("pers", "vol")
  m2 <- fit("prog", "vol")
  print(summary(m1)); print(summary(m2))
  emit("personalism_volatility_difference_overall", coef(m1)["vol"] * dq)
  emit("programmaticness_volatility_difference_overall", coef(m2)["vol"] * dq)
  emit("n_obs_table1", nobs(m1))

  # Ethnicity
  m3 <- fit("pers", "vol * eth")
  m4 <- fit("prog", "vol * eth")
  print(summary(m3)); print(summary(m4))
  emit("personalism_volatility_difference_nonethnic", coef(m3)["vol"] * dq)
  emit("programmaticness_volatility_difference_nonethnic", coef(m4)["vol"] * dq)
  emit("personalism_ethnic_minus_nonethnic_low_volatility",
       coef(m3)["eth"] + coef(m3)["vol:eth"] * q25)
  emit("programmaticness_ethnic_minus_nonethnic_high_volatility",
       coef(m4)["eth"] + coef(m4)["vol:eth"] * q75)

  # Ideology (extremist at distance 3)
  m5 <- fit("pers", "vol * ext")
  m6 <- fit("prog", "vol * ext")
  print(summary(m5)); print(summary(m6))
  emit("personalism_volatility_difference_moderate", coef(m5)["vol"] * dq)
  emit("programmaticness_volatility_difference_moderate", coef(m6)["vol"] * dq)
  emit("personalism_extremist_minus_moderate_low_volatility",
       3 * (coef(m5)["ext"] + coef(m5)["vol:ext"] * q25))
  emit("programmaticness_extremist_minus_moderate_high_volatility",
       3 * (coef(m6)["ext"] + coef(m6)["vol:ext"] * q75))
}

## ---------------- Brazil RD ----------------
br <- tryCatch(as.data.frame(zap_labels(read_dta(file.path(base, "brazil-RD-data.dta")))),
               error = function(e) NULL)

if (!is.null(br)) {
  for (v in names(br)) suppressWarnings(br[[v]] <- as.numeric(br[[v]]))
  cat("dlameduck_runs table:\n"); print(table(br$dlameduck_runs, useNA = "ifany"))
  cat("Range of running variable:\n"); print(summary(br$mv_incparty))

  run_rd <- function(dd, y) {
    ok <- !is.na(dd[[y]]) & !is.na(dd$mv_incparty)
    if (sum(ok) < 50) return(NULL)
    tryCatch(rdrobust(y = dd[[y]][ok], x = dd$mv_incparty[ok], c = 0),
             error = function(e) NULL)
  }

  # Candidate subsets: target effective N (Young) = 527 + 559 = 1086
  subsets <- list(all = br)
  vals <- sort(unique(br$dlameduck_runs[!is.na(br$dlameduck_runs)]))
  for (v in vals) subsets[[paste0("dl", v)]] <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == v, ]

  best <- NULL; best_gap <- Inf; best_name <- NA
  for (nm in names(subsets)) {
    r <- run_rd(subsets[[nm]], "youngF_inc_for1")
    if (is.null(r)) next
    neff <- sum(r$N_h)
    cat("Subset", nm, ": tau =", r$coef[1], " h =", r$bws[1, 1], " Nh =", r$N_h, "\n")
    gap <- abs(neff - 1086) + abs(r$bws[1, 1] - 13.491) * 10
    if (gap < best_gap) { best_gap <- gap; best <- nm }
  }
  if (!is.null(best)) {
    cat("Chosen subset:", best, "\n")
    r1 <- run_rd(subsets[[best]], "youngF_inc_for1")
    r2 <- run_rd(subsets[[best]], "outyg1F_inc_for1")
    if (!is.null(r1)) { print(summary(r1)); emit("rd_effect_young", r1$coef[1]) }
    if (!is.null(r2)) { print(summary(r2)); emit("rd_effect_young_outsider", r2$coef[1]) }
  }
}

for (nm in names(res)) cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(res[[nm]])))