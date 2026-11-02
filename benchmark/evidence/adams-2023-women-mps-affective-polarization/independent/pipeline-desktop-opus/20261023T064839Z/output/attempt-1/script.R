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

# ---- locate out-party (j = "to") women share variable ----
find_women_var <- function(df) {
  nm <- names(df)
  cand <- nm[grepl("wom|fem", nm, ignore.case = TRUE)]
  to_cand <- cand[grepl("^to_|_to_|_to$|^to", cand, ignore.case = TRUE)]
  if (length(to_cand) == 0) to_cand <- cand[!grepl("^from", cand, ignore.case = TRUE)]
  if (length(to_cand) == 0) return(NA_character_)
  # keep numeric
  to_cand <- to_cand[sapply(to_cand, function(v) is.numeric(df[[v]]))]
  if (length(to_cand) == 0) return(NA_character_)
  # exclude counts / leader dummies if possible
  pref <- to_cand[grepl("lag|t1|t_1|prior|prev", to_cand, ignore.case = TRUE)]
  pool <- if (length(pref) > 0) pref else to_cand
  pref2 <- pool[grepl("prop|share|pct|perc|per", pool, ignore.case = TRUE)]
  if (length(pref2) > 0) pool <- pref2
  notlead <- pool[!grepl("leader|number|count|num", pool, ignore.case = TRUE)]
  if (length(notlead) > 0) pool <- notlead
  # choose the one whose values look like a proportion (most distinct values)
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

prep <- function(df, wvar, dv) {
  df$women_j <- as.numeric(df[[wvar]])
  if (max(df$women_j, na.rm = TRUE) > 1.5) df$women_j <- df$women_j / 100
  df$dv <- as.numeric(df[[dv]])
  df$rl_raw <- abs(as.numeric(df$rile_distance))
  df$coal <- as.numeric(df$govern_together)
  df$opp <- as.numeric(df$opposition_together)
  df$cy <- paste(df$country, df$year, sep = "_")
  keep <- !is.na(df$to_mp_number) & !is.na(df$from_mp_number) &
    as.numeric(df$to_mp_number) >= 4 & as.numeric(df$from_mp_number) >= 4 &
    !is.na(df$dv) & !is.na(df$women_j) & !is.na(df$rl_raw) &
    !is.na(df$coal) & !is.na(df$opp)
  df <- df[keep, ]
  df$rl_std <- (df$rl_raw - mean(df$rl_raw)) / sd(df$rl_raw)
  df
}

wvar <- find_women_var(dyad)
dv <- find_dv(dyad)
cat("Women share variable:", wvar, " DV:", dv, "\n")

d <- prep(dyad, wvar, dv)
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
tryCatch({
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
    } else {                             # 0/1 female dummy
      is_f <- g == 1; is_m <- g == 0
    }
    is_f[is.na(is_f)] <- FALSE; is_m[is.na(is_m)] <- FALSE
  }
  gw <- prep(gend[is_f, ], wvar_g, dv_g)
  gm <- prep(gend[is_m, ], wvar_g, dv_g)
  m3 <- feols(dv ~ women_j + rl_std + coal + opp | cy, data = gw, cluster = ~cy)
  m4 <- feols(dv ~ women_j + rl_std + coal + opp | cy, data = gm, cluster = ~cy)
  print(summary(m3)); print(summary(m4))
  res$women_mps_coef_women_partisans <<- unname(coef(m3)["women_j"])
  res$women_mps_coef_men_partisans <<- unname(coef(m4)["women_j"])
  res$n_obs_women_partisans <<- nobs(m3)
  res$n_obs_men_partisans <<- nobs(m4)
}, error = function(e) cat("Gender models failed:", conditionMessage(e), "\n"))

for (n in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", n, format(res[[n]], digits = 6)))
}