suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))   # creates updated_data
dy <- as.data.frame(updated_data)
gd <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

cat("Dyadic columns:", paste(names(dy), collapse = ", "), "\n")
cat("Gender columns:", paste(names(gd), collapse = ", "), "\n")

num_ok <- function(x) is.numeric(x) && sum(!is.na(x)) > 0

# ---- Find the women-MP share of the out-party (j = "to") ----
find_women_var <- function(df) {
  nm <- names(df)
  cand <- nm[grepl("wom|fem|female|gender_prop|prop_w", nm, ignore.case = TRUE)]
  cand <- cand[sapply(df[cand], num_ok)]
  cand <- setdiff(cand, "gender")
  if (length(cand) == 0) stop("No women-share variable found")
  score <- sapply(cand, function(v) {
    s <- 0
    if (grepl("^to_|_to$|_to_|out", v, ignore.case = TRUE)) s <- s + 10
    if (grepl("^from_|_from$|_from_|in_party|own", v, ignore.case = TRUE)) s <- s - 10
    if (grepl("lag", v, ignore.case = TRUE)) s <- s + 3
    if (grepl("prop|share|pct|perc", v, ignore.case = TRUE)) s <- s + 2
    if (grepl("leader|sq|squared|_2$|dummy|parity", v, ignore.case = TRUE)) s <- s - 5
    x <- df[[v]]
    if (max(x, na.rm = TRUE) <= 1 && min(x, na.rm = TRUE) >= 0) s <- s + 2
    if (length(unique(na.omit(x))) <= 2) s <- s - 8
    s
  })
  best <- cand[which.max(score)]
  best
}

# ---- Find the dependent variable (mean 0-10 thermometer) ----
find_dv <- function(df) {
  nm <- names(df)
  pref <- c("thermometer", "mean_thermometer", "thermometer_score", "therm",
            "like", "mean_like", "evaluation", "dislike")
  cand <- nm[grepl("therm|like|eval|rating|score", nm, ignore.case = TRUE)]
  cand <- cand[sapply(df[cand], num_ok)]
  cand <- cand[sapply(cand, function(v) {
    x <- df[[v]]
    min(x, na.rm = TRUE) >= 0 && max(x, na.rm = TRUE) <= 10 &&
      mean(abs(x - round(x)), na.rm = TRUE) > 0.01
  })]
  if (length(cand) == 0) stop("No DV found")
  ord <- match(tolower(cand), pref)
  ord[is.na(ord)] <- 99
  cand[order(ord)][1]
}

prep <- function(df, label) {
  wv <- find_women_var(df)
  dv <- find_dv(df)
  cat(sprintf("[%s] women-share variable: %s ; DV: %s\n", label, wv, dv))
  df$women_j <- df[[wv]]
  if (max(df$women_j, na.rm = TRUE) > 1.5) df$women_j <- df$women_j / 100
  df$y <- df[[dv]]
  # orientation check: coalition partners should like each other more
  if ("govern_together" %in% names(df)) {
    r <- suppressWarnings(cor(df$y, df$govern_together, use = "complete.obs"))
    if (!is.na(r) && r < 0) {
      cat(sprintf("[%s] DV appears to be a dislike scale; reversing (10 - y)\n", label))
      df$y <- 10 - df$y
    }
  }
  # standardized left-right distance
  if ("rile_distance_s" %in% names(df)) {
    df$rile_z <- df$rile_distance_s
  } else {
    df$rile_z <- as.numeric(scale(df$rile_distance))
  }
  df$cy <- paste(df$country, df$year, sep = "_")
  df
}

dy <- prep(dy, "main")

# ---- Main sample ----
cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(dy)))
if (all(c("party_from", "party_to") %in% names(dy))) {
  dy <- dy[is.na(dy$party_from) | is.na(dy$party_to) | dy$party_from != dy$party_to, ]
}
dy <- dy[!is.na(dy$to_mp_number) & !is.na(dy$from_mp_number) &
           dy$to_mp_number >= 4 & dy$from_mp_number >= 4, ]
cat(sprintf("SAMPLE:main:both_parties_at_least_4_mps=%d\n", nrow(dy)))

m1 <- feols(y ~ women_j | cy, data = dy, cluster = ~cy)
m2 <- feols(y ~ women_j + rile_z + govern_together + opposition_together | cy,
            data = dy, cluster = ~cy)
cat(sprintf("SAMPLE:main:estimation=%d\n", nobs(m2)))
cat(sprintf("SAMPLE:bivariate:loaded=%d\n", nrow(dy)))
cat(sprintf("SAMPLE:bivariate:estimation=%d\n", nobs(m1)))

est_rows <- obs(m2)
n_elec <- length(unique(dy$cy[est_rows]))

# ---- Gender-disaggregated samples ----
gd <- prep(gd, "gender")
gvals <- gd$gender
if (is.factor(gvals)) gvals <- as.character(gvals)
if (is.character(gvals)) {
  g <- tolower(gvals)
  is_w <- grepl("^f|wom|female", g)
  is_m <- grepl("^m|^man|^men|^male", g) & !is_w
} else {
  u <- sort(unique(na.omit(gvals)))
  cat("Gender codes:", paste(u, collapse = ","), "\n")
  if (all(u %in% c(0, 1))) {
    is_w <- gvals == 1; is_m <- gvals == 0
  } else {
    is_w <- gvals == 2; is_m <- gvals == 1   # CSES: 1 = male, 2 = female
  }
}
is_w[is.na(is_w)] <- FALSE; is_m[is.na(is_m)] <- FALSE

run_sub <- function(d, nm) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", nm, nrow(d)))
  if (all(c("party_from", "party_to") %in% names(d))) {
    d <- d[is.na(d$party_from) | is.na(d$party_to) | d$party_from != d$party_to, ]
  }
  d <- d[!is.na(d$to_mp_number) & !is.na(d$from_mp_number) &
           d$to_mp_number >= 4 & d$from_mp_number >= 4, ]
  cat(sprintf("SAMPLE:%s:both_parties_at_least_4_mps=%d\n", nm, nrow(d)))
  m <- feols(y ~ women_j + rile_z + govern_together + opposition_together | cy,
             data = d, cluster = ~cy)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, nobs(m)))
  m
}

gw <- gd[is_w, ]
gm <- gd[is_m, ]
m3 <- run_sub(gw, "women_partisans")
m4 <- run_sub(gm, "men_partisans")

print(etable(m1, m2, m3, m4))

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["women_j"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["women_j"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["women_j"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["women_j"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rile_z"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["govern_together"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opposition_together"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_elec))
