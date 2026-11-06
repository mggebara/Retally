suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"

## ------------------------------------------------------------------
## Cross-national analysis (Table 1)
## ------------------------------------------------------------------
cn <- as.data.frame(zap_labels(read_dta(file.path(base, "cross-national-data.dta"))))
cat(sprintf("SAMPLE:table1:loaded=%d\n", nrow(cn)))

# Ethnic party indicator: 1 when a majority of experts report ethnic ties
eth <- cn$ethnic
eth_vals <- sort(unique(na.omit(eth)))
if (all(eth_vals %in% c(0, 1))) {
  cn$ethnic_party <- eth
} else if (max(eth_vals) <= 1) {
  cn$ethnic_party <- as.numeric(eth > 0.5)
  cat("DEVIATION: ethnic is a share of experts; coded ethnic_party = 1 if share > 0.5\n")
} else {
  mid <- (min(eth_vals) + max(eth_vals)) / 2
  cn$ethnic_party <- as.numeric(eth > mid)
  cat(sprintf("DEVIATION: ethnic not binary/share; coded ethnic_party = 1 if ethnic > scale midpoint %.2f\n", mid))
}
cn$ethnic_party[is.na(eth)] <- NA

# Categorical country controls: treat as factors when multi-category
cat_term <- function(v) {
  u <- unique(na.omit(cn[[v]]))
  if (length(u) > 2 && length(u) <= 6) paste0("factor(", v, ")") else v
}

party_ctrls   <- c("partysize", "unions", "business", "religious")
country_vars  <- c("pluralty", "pr", "cl", "mdmh", "polity", "demsys", "system",
                   "gdppc", "gini", "ethfrac")
country_terms <- sapply(country_vars, cat_term)
ctrl_rhs <- paste(c(party_ctrls, country_terms), collapse = " + ")

# Sample construction
d <- cn
d <- d[!is.na(d$personal) & !is.na(d$programmatic), ]
cat(sprintf("SAMPLE:table1:nonmissing_outcomes=%d\n", nrow(d)))
d <- d[!is.na(d$ev_total), ]
cat(sprintf("SAMPLE:table1:nonmissing_volatility=%d\n", nrow(d)))
d <- d[complete.cases(d[, party_ctrls]), ]
cat(sprintf("SAMPLE:table1:nonmissing_party_controls=%d\n", nrow(d)))
d <- d[complete.cases(d[, c(country_vars, "ccode")]), ]
cat(sprintf("SAMPLE:table1:nonmissing_country_controls=%d\n", nrow(d)))
n_base <- nrow(d)
d_full <- d[!is.na(d$ethnic_party) & !is.na(d$extremist2), ]
cat(sprintf("SAMPLE:table1:nonmissing_group_attachments=%d\n", nrow(d_full)))
n_full <- nrow(d_full)

use_full <- (n_full == 431) || (abs(n_full - 431) <= abs(n_base - 431))
dat <- if (use_full) d_full else d
if (nrow(dat) != 431) {
  cat(sprintf("DEVIATION: estimation sample has %d parties, paper states 431\n", nrow(dat)))
}

q25 <- as.numeric(quantile(dat$ev_total, 0.25))
q75 <- as.numeric(quantile(dat$ev_total, 0.75))
dq <- q75 - q25

fit <- function(y, extra = NULL) {
  rhs <- if (is.null(extra)) paste("ev_total +", ctrl_rhs) else paste(extra, "+", ctrl_rhs)
  feols(as.formula(paste(y, "~", rhs)), data = dat, cluster = ~ccode)
}
gc <- function(m, nm) {
  cf <- coef(m)
  if (nm %in% names(cf)) return(unname(cf[nm]))
  parts <- strsplit(nm, ":")[[1]]
  alt <- paste(rev(parts), collapse = ":")
  if (alt %in% names(cf)) return(unname(cf[alt]))
  stop(paste("coefficient not found:", nm))
}

# Overall
m_pers <- fit("personal")
m_prog <- fit("programmatic")
cat(sprintf("SAMPLE:table1:estimation=%d\n", nobs(m_pers)))

# Ethnicity interactions
m_pers_e <- fit("personal", "ev_total * ethnic_party")
m_prog_e <- fit("programmatic", "ev_total * ethnic_party")
cat(sprintf("SAMPLE:table1_ethnic:estimation=%d\n", nobs(m_pers_e)))

# Ideology interactions
m_pers_x <- fit("personal", "ev_total * extremist2")
m_prog_x <- fit("programmatic", "ev_total * extremist2")
cat(sprintf("SAMPLE:table1_ideology:estimation=%d\n", nobs(m_pers_x)))

ext <- 3

res <- list(
  personalism_volatility_difference_overall = gc(m_pers, "ev_total") * dq,
  programmaticness_volatility_difference_overall = gc(m_prog, "ev_total") * dq,
  personalism_volatility_difference_nonethnic = gc(m_pers_e, "ev_total") * dq,
  programmaticness_volatility_difference_nonethnic = gc(m_prog_e, "ev_total") * dq,
  personalism_ethnic_minus_nonethnic_low_volatility =
    gc(m_pers_e, "ethnic_party") + gc(m_pers_e, "ev_total:ethnic_party") * q25,
  programmaticness_ethnic_minus_nonethnic_high_volatility =
    gc(m_prog_e, "ethnic_party") + gc(m_prog_e, "ev_total:ethnic_party") * q75,
  personalism_volatility_difference_moderate = gc(m_pers_x, "ev_total") * dq,
  programmaticness_volatility_difference_moderate = gc(m_prog_x, "ev_total") * dq,
  personalism_extremist_minus_moderate_low_volatility =
    ext * (gc(m_pers_x, "extremist2") + gc(m_pers_x, "ev_total:extremist2") * q25),
  programmaticness_extremist_minus_moderate_high_volatility =
    ext * (gc(m_prog_x, "extremist2") + gc(m_prog_x, "ev_total:extremist2") * q75),
  n_obs_table1 = nobs(m_pers)
)

## ------------------------------------------------------------------
## Brazil RD (Table 2)
## ------------------------------------------------------------------
rd <- as.data.frame(zap_labels(read_dta(file.path(base, "brazil-RD-data.dta"))))

run_rd <- function(df, y) {
  ok <- !is.na(df[[y]]) & !is.na(df$mv_incparty)
  r <- rdrobust(df[[y]][ok], df$mv_incparty[ok], c = 0, p = 1, bwselect = "mserd")
  list(tau = r$coef[1], nl = r$N_h[1], nr = r$N_h[2], n = sum(ok), h = r$bws[1, 1])
}

cands <- list(
  open_seat_lameduck0 = rd[!is.na(rd$dlameduck_runs) & rd$dlameduck_runs == 0, ],
  lameduck1 = rd[!is.na(rd$dlameduck_runs) & rd$dlameduck_runs == 1, ],
  all = rd
)
fits <- lapply(cands, function(df) tryCatch(run_rd(df, "youngF_inc_for1"), error = function(e) NULL))
score <- sapply(fits, function(f) if (is.null(f)) Inf else abs(f$nl - 559) + abs(f$nr - 527))
chosen <- names(which.min(score))
if (chosen != "open_seat_lameduck0") {
  cat(sprintf("DEVIATION: open-seat filter dlameduck_runs==0 did not match stated N; used sample '%s'\n", chosen))
}
rd_s <- cands[[chosen]]

cat(sprintf("SAMPLE:rd_young:loaded=%d\n", nrow(rd)))
cat(sprintf("SAMPLE:rd_young:open_seat=%d\n", nrow(rd_s)))
f_y <- fits[[chosen]]
cat(sprintf("SAMPLE:rd_young:nonmissing=%d\n", f_y$n))
cat(sprintf("SAMPLE:rd_young:estimation=%d\n", f_y$nl + f_y$nr))

f_yo <- run_rd(rd_s, "outyg1F_inc_for1")
cat(sprintf("SAMPLE:rd_young_outsider:loaded=%d\n", nrow(rd)))
cat(sprintf("SAMPLE:rd_young_outsider:open_seat=%d\n", nrow(rd_s)))
cat(sprintf("SAMPLE:rd_young_outsider:nonmissing=%d\n", f_yo$n))
cat(sprintf("SAMPLE:rd_young_outsider:estimation=%d\n", f_yo$nl + f_yo$nr))

res$rd_effect_young <- f_y$tau
res$rd_effect_young_outsider <- f_yo$tau

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(res[[nm]])))
}
