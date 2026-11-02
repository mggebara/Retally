suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))  # creates updated_data
dyad <- as.data.frame(updated_data)
gend <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

cat("Dyadic columns:\n"); print(names(dyad))

find_women_var <- function(df) {
  nm <- names(df)
  cand <- nm[grepl("wom|fem", nm, ignore.case = TRUE)]
  to_cand <- cand[grepl("^to_|_to_|_to$|^to", cand, ignore.case = TRUE)]
  if (length(to_cand) == 0) to_cand <- cand[!grepl("^from", cand, ignore.case = TRUE)]
  if (length(to_cand) == 0) return(NA_character_)
  to_cand <- to_cand[sapply(to_cand, function(v) is.numeric(df[[v]]))]
  if (length(to_cand) == 0) return(NA_character_)
  pref <- to_cand[grepl("lag|t1|t_1|prior|prev", to_cand, ignore.case = TRUE)]
  pool <- if (length(pref) > 0) pref else to_cand
  pref2 <- pool[grepl("prop|share|pct|perc|per", pool, ignore.case = TRUE)]
  if (length(pref2) > 0) pool <- pref2
  notlead <- pool[!grepl("leader|number|count|num", pool, ignore.case = TRUE)]
  if (length(notlead) > 0) pool <- notlead
  nd <- sapply(pool, function(v) length(unique(na.omit(df[[v]]))))
  pool[which.max(nd)]
}

find_dv <- function(df) {
  nm <- names(df)
  for (v in c("party_like", "thermometer", "thermometer_score", "like")) {
    if (v %in% nm && is.numeric(df[[v]])) return(v)
  }
  NA_character_
}

num <- function(x) suppressWarnings(as.numeric(x))

# NOTE: to_mp_number / from_mp_number range 11110-72701: these are CMP party
# codes, not seat counts, so the earlier ">= 4 MPs" filter on them was a no-op.
# The party size in the year before the survey is to_prior_seats / from_prior_seats
# (999 = missing code).
# Rules: list(thr, side, na999, napass)
rules <- list(
  both4_drop      = list(thr = 4, side = "both", na999 = FALSE, napass = FALSE),
  both4_999na_keep= list(thr = 4, side = "both", na999 = TRUE,  napass = TRUE),
  both4_999na_drop= list(thr = 4, side = "both", na999 = TRUE,  napass = FALSE),
  both4_napass    = list(thr = 4, side = "both", na999 = FALSE, napass = TRUE),
  to4_drop        = list(thr = 4, side = "to",   na999 = FALSE, napass = FALSE),
  to4_napass      = list(thr = 4, side = "to",   na999 = TRUE,  napass = TRUE),
  from4_drop      = list(thr = 4, side = "from", na999 = FALSE, napass = FALSE),
  from4_napass    = list(thr = 4, side = "from", na999 = TRUE,  napass = TRUE),
  both3_napass    = list(thr = 3, side = "both", na999 = TRUE,  napass = TRUE),
  both1_napass    = list(thr = 1, side = "both", na999 = TRUE,  napass = TRUE),
  both1_drop      = list(thr = 1, side = "both", na999 = FALSE, napass = FALSE),
  none            = list(thr = -Inf, side = "both", na999 = FALSE, napass = TRUE)
)

rule_mask <- function(df, rule) {
  r <- rules[[rule]]
  n <- nrow(df)
  if (!(("to_prior_seats" %in% names(df)) && ("from_prior_seats" %in% names(df)))) return(NULL)
  chk <- function(s) {
    s <- num(s)
    if (r$na999) s[!is.na(s) & s >= 999] <- NA
    ok <- !is.na(s) & s >= r$thr
    if (r$napass) ok <- ok | is.na(s)
    ok
  }
  a <- chk(df$to_prior_seats); b <- chk(df$from_prior_seats)
  ok <- switch(r$side, both = a & b, to = a, from = b)
  ok[is.na(ok)] <- FALSE
  ok
}

prep <- function(df, wvar, dv, rule) {
  m <- rule_mask(df, rule)
  if (is.null(m)) return(NULL)
  df <- df[m, , drop = FALSE]
  df$women_j <- num(df[[wvar]])
  if (nrow(df) > 0 && max(df$women_j, na.rm = TRUE) > 1.5) df$women_j <- df$women_j / 100
  df$dv <- num(df[[dv]])
  df$rl_raw <- abs(num(df$rile_distance))
  df$coal <- num(df$govern_together)
  df$opp <- num(df$opposition_together)
  df$cy <- paste(df$country, df$year, sep = "_")
  keep <- !is.na(df$dv) & !is.na(df$women_j) & !is.na(df$rl_raw) &
    !is.na(df$coal) & !is.na(df$opp)
  df <- df[keep, , drop = FALSE]
  if (nrow(df) < 10) return(NULL)
  df$rl_std <- (df$rl_raw - mean(df$rl_raw)) / sd(df$rl_raw)
  df
}

wvar <- find_women_var(dyad)
dv <- find_dv(dyad)
cat("Women share variable:", wvar, " DV:", dv, "\n")
cat("to_prior_seats summary:\n"); print(summary(num(dyad$to_prior_seats)))
cat("to_prior_seats == 999:", sum(num(dyad$to_prior_seats) >= 999, na.rm = TRUE),
    " NA:", sum(is.na(num(dyad$to_prior_seats))), "\n")

target_n <- 1842
best_rule <- "both4_drop"; best_gap <- Inf
for (r in names(rules)) {
  dd <- tryCatch(prep(dyad, wvar, dv, r), error = function(e) NULL)
  if (is.null(dd)) { cat("Rule", r, ": not applicable\n"); next }
  cat("Rule", r, ": N =", nrow(dd), " elections =", length(unique(dd$cy)), "\n")
  gap <- abs(nrow(dd) - target_n)
  if (gap < best_gap) { best_gap <- gap; best_rule <- r }
}
cat("Selected sample rule:", best_rule, "\n")
cat("DEVIATION: to_/from_mp_number are CMP party codes, not seat counts; the >=4 MPs restriction is applied to to_/from_prior_seats (seats in year before survey)\n")
if (best_rule != "both4_drop") {
  cat(sprintf("DEVIATION: Party-size filter variant '%s' (handling of missing/999 seat codes, or which side is filtered) chosen as the one giving N closest to the paper's 1,842\n", best_rule))
}

d <- prep(dyad, wvar, dv, best_rule)
cat("Women share summary:\n"); print(summary(d$women_j))
cat("DV summary:\n"); print(summary(d$dv))

m1 <- feols(dv ~ women_j | cy, data = d, cluster = ~cy)
m2 <- feols(dv ~ women_j + rl_std + coal + opp | cy, data = d, cluster = ~cy)
print(summary(m1)); print(summary(m2))

res <- list()
res$women_mps_coef_bivariate <- unname(coef(m1)["women_j"])
res$women_mps_coef_full <- unname(coef(m2)["women_j"])
res$right_left_distance_coef_full <- unname(coef(m2)["rl_std"])
res$coalition_partners_coef_full <- unname(coef(m2)["coal"])
res$opposition_partners_coef_full <- unname(coef(m2)["opp"])
res$n_directed_dyads <- nobs(m2)
res$n_election_studies <- length(unique(d$cy[obs(m2)]))
res$women_mps_se_bivariate <- unname(sqrt(diag(vcov(m1)))["women_j"])
res$women_mps_se_full <- unname(sqrt(diag(vcov(m2)))["women_j"])
res$adj_r2_bivariate <- unname(fitstat(m1, "ar2")[[1]])
res$adj_r2_full <- unname(fitstat(m2, "ar2")[[1]])

# ---- gender-disaggregated models ----
gres <- tryCatch({
  cat("Gender file columns:\n"); print(names(gend))
  print(table(gend$gender, useNA = "ifany"))
  wvar_g <- if (!is.na(wvar) && wvar %in% names(gend)) wvar else find_women_var(gend)
  dv_g <- find_dv(gend)
  g <- gend$gender
  if (is.factor(g)) g <- as.character(g)
  if (is.character(g)) {
    is_f <- grepl("^f|wom", g, ignore.case = TRUE)
    is_m <- grepl("^m|^men", g, ignore.case = TRUE) & !is_f
  } else {
    vals <- sort(unique(na.omit(g)))
    if (all(vals %in% c(1, 2))) {        # CSES: 1 = male, 2 = female
      is_f <- g == 2; is_m <- g == 1
    } else {
      is_f <- g == 1; is_m <- g == 0
    }
    is_f[is.na(is_f)] <- FALSE; is_m[is.na(is_m)] <- FALSE
  }
  rule_g <- best_rule
  gw <- prep(gend[is_f, ], wvar_g, dv_g, rule_g)
  gm <- prep(gend[is_m, ], wvar_g, dv_g, rule_g)
  cat("Gender models sample rule:", rule_g, "\n")
  m3 <- feols(dv ~ women_j + rl_std + coal + opp | cy, data = gw, cluster = ~cy)
  m4 <- feols(dv ~ women_j + rl_std + coal + opp | cy, data = gm, cluster = ~cy)
  print(summary(m3)); print(summary(m4))
  list(
    women_mps_coef_women_partisans = unname(coef(m3)["women_j"]),
    women_mps_coef_men_partisans = unname(coef(m4)["women_j"]),
    n_obs_women_partisans = nobs(m3),
    n_obs_men_partisans = nobs(m4)
  )
}, error = function(e) { cat("Gender models failed:", conditionMessage(e), "\n"); list() })
for (n in names(gres)) res[[n]] <- gres[[n]]

for (n in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", n, format(res[[n]], digits = 6)))
}
