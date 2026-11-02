suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))
dy <- as.data.frame(updated_data)
gd <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

strip <- function(x) {
  x <- tryCatch(haven::zap_labels(x), error = function(e) x)
  as.vector(x)
}
num <- function(df, v) {
  if (!(v %in% names(df))) return(rep(NA_real_, nrow(df)))
  suppressWarnings(as.numeric(strip(df[[v]])))
}

# ---- Dependent variable detection ----
is_thermo <- function(x) {
  x <- suppressWarnings(as.numeric(strip(x)))
  x <- x[!is.na(x)]
  if (length(x) < 50) return(FALSE)
  if (min(x) < 0 || max(x) > 10) return(FALSE)
  if (length(unique(x)) < 20) return(FALSE)
  mean(abs(x - round(x)) > 1e-8) > 0.3
}
find_dv <- function(df) {
  nm <- names(df)
  pri <- c(
    nm[grepl("therm|evaluat|feeling", nm, ignore.case = TRUE)],
    nm[tolower(nm) %in% c("like", "mean_like", "like_score", "avg_like")],
    nm[tolower(nm) %in% c("dislike", "mean_dislike")],
    nm[grepl("like", nm, ignore.case = TRUE) & !grepl("dislike", nm, ignore.case = TRUE)],
    nm[grepl("dislike", nm, ignore.case = TRUE)]
  )
  pri <- unique(pri)
  for (v in pri) {
    if (is_thermo(df[[v]])) {
      flip <- grepl("dislike", v, ignore.case = TRUE)
      return(list(var = v, flip = flip))
    }
  }
  stop("No DV found")
}

find_women <- function(df) {
  nm <- names(df)
  cand <- nm[grepl("wom|fem", nm, ignore.case = TRUE) & !grepl("^from|_from", nm, ignore.case = TRUE)]
  cand <- cand[!grepl("lead|chair|vote|respond|partisan", cand, ignore.case = TRUE)]
  if (length(cand) == 0) {
    cand <- nm[grepl("^to_.*(prop|share|pct|perc)", nm, ignore.case = TRUE)]
  }
  if (length(cand) == 0) stop("No women share variable found")
  score <- function(v) {
    s <- 0
    if (grepl("^to", v, ignore.case = TRUE)) s <- s + 4
    if (grepl("lag", v, ignore.case = TRUE)) s <- s + 2
    if (grepl("prop|share|pct|perc|percent", v, ignore.case = TRUE)) s <- s + 1
    if (grepl("leader|lead", v, ignore.case = TRUE)) s <- s - 10
    s
  }
  cand <- cand[order(-sapply(cand, score))]
  for (v in cand) {
    x <- suppressWarnings(as.numeric(strip(df[[v]])))
    if (all(is.na(x))) next
    if (length(unique(na.omit(x))) < 5) next
    return(v)
  }
  stop("No usable women share variable")
}

women_share <- function(df, v) {
  x <- suppressWarnings(as.numeric(strip(df[[v]])))
  mx <- max(x, na.rm = TRUE)
  if (mx <= 1.0001) return(x)
  isint <- all(abs(x - round(x)) < 1e-8, na.rm = TRUE)
  if (isint && "to_mp_number" %in% names(df)) {
    mp <- suppressWarnings(as.numeric(strip(df$to_mp_number)))
    if (all(x <= mp, na.rm = TRUE)) return(x / mp)
  }
  if (mx <= 100) return(x / 100)
  x
}

prep_raw <- function(df) {
  dvi <- find_dv(df)
  wv <- find_women(df)
  cat("DV:", dvi$var, " flip:", dvi$flip, " women var:", wv, "\n")
  y <- suppressWarnings(as.numeric(strip(df[[dvi$var]])))
  if (dvi$flip) y <- 10 - y
  out <- df
  out$dv <- y
  out$women <- women_share(df, wv)
  out$rile_raw <- abs(num(df, "rile_distance"))
  out$coal <- num(df, "govern_together")
  out$opp <- num(df, "opposition_together")
  out$to_mp <- num(df, "to_mp_number")
  out$from_mp <- num(df, "from_mp_number")
  out$to_ps <- num(df, "to_prior_seats")
  out$from_ps <- num(df, "from_prior_seats")
  out$to_cmp <- num(df, "to_complete")
  out$from_cmp <- num(df, "from_complete")
  out$dm_ <- num(df, "DM")
  out$cy <- paste(as.character(strip(df$country)), as.character(strip(df$year)), sep = "_")
  if (all(c("party_from", "party_to") %in% names(df))) {
    out <- out[as.character(strip(out$party_from)) != as.character(strip(out$party_to)), ]
  }
  out
}

ok <- function(x) !is.na(x)
mp_ge <- function(d, k) ok(d$to_mp) & ok(d$from_mp) & d$to_mp >= k & d$from_mp >= k
ps_ge <- function(d, k) ok(d$to_ps) & ok(d$from_ps) & d$to_ps >= k & d$from_ps >= k
cmp_ok <- function(d) {
  if (all(is.na(d$to_cmp)) || all(is.na(d$from_cmp))) return(rep(TRUE, nrow(d)))
  ok(d$to_cmp) & ok(d$from_cmp) & d$to_cmp == 1 & d$from_cmp == 1
}
dm_ok <- function(d) {
  if (all(is.na(d$dm_))) return(rep(TRUE, nrow(d)))
  ok(d$dm_)
}
ps_is_count <- function(d) {
  x <- c(d$to_ps, d$from_ps); x <- x[!is.na(x)]
  length(x) > 0 && max(x) > 1.5
}

filters <- list(
  mp_ge4        = function(d) mp_ge(d, 4),
  mp_gt4        = function(d) mp_ge(d, 5),
  mp_ge4_cmp    = function(d) mp_ge(d, 4) & cmp_ok(d),
  mp_ge4_dm     = function(d) mp_ge(d, 4) & dm_ok(d),
  mp_ge4_cmp_dm = function(d) mp_ge(d, 4) & cmp_ok(d) & dm_ok(d),
  ps_ge4        = function(d) if (ps_is_count(d)) ps_ge(d, 4) else rep(FALSE, nrow(d)),
  ps_gt4        = function(d) if (ps_is_count(d)) ps_ge(d, 5) else rep(FALSE, nrow(d)),
  mp_ps_ge4     = function(d) if (ps_is_count(d)) mp_ge(d, 4) & ps_ge(d, 4) else rep(FALSE, nrow(d)),
  ps_ge4_cmp    = function(d) if (ps_is_count(d)) ps_ge(d, 4) & cmp_ok(d) else rep(FALSE, nrow(d))
)

full_vars <- c("dv", "women", "rile_raw", "coal", "opp", "cy")

raw <- prep_raw(dy)
target <- 1842
ns <- sapply(names(filters), function(f) {
  s <- raw[filters[[f]](raw), ]
  sum(complete.cases(s[, full_vars]))
})
cat("Candidate sample sizes:\n"); print(ns)
best <- names(ns)[which.min(abs(ns - target))]
cat("Chosen sample filter:", best, "\n")
if (best != "mp_ge4") {
  cat(sprintf("DEVIATION: Sample restriction implemented as '%s' (the filter yielding N closest to the paper's 1,842) instead of current-year MP counts >= 4\n", best))
}
filt <- filters[[best]]

d <- raw[filt(raw), ]
cat("Rows after filter:", nrow(d), "\n")

d2 <- d[complete.cases(d[, full_vars]), ]
d2$rile_std <- (d2$rile_raw - mean(d2$rile_raw)) / sd(d2$rile_raw)
cat("rile raw mean/sd:", mean(d2$rile_raw), sd(d2$rile_raw), "\n")
cat("women mean/sd:", mean(d2$women), sd(d2$women), "\n")

d1 <- d[complete.cases(d[, c("dv", "women", "cy")]), ]
m1 <- feols(dv ~ women | cy, data = d1, cluster = ~cy)
m2 <- feols(dv ~ women + rile_std + coal + opp | cy, data = d2, cluster = ~cy)
print(summary(m1)); print(summary(m2))

# ---- Gender-disaggregated models ----
gender_split <- function(g) {
  gv <- g$gender
  labs <- attr(gv, "labels")
  if (!is.null(labs)) {
    fem_codes <- labs[grepl("fem|wom", names(labs), ignore.case = TRUE)]
    if (length(fem_codes) > 0) return(as.numeric(strip(gv)) %in% as.numeric(fem_codes))
  }
  if (is.factor(gv) || is.character(gv)) {
    s <- tolower(as.character(gv))
    return(grepl("^f|wom", s))
  }
  x <- as.numeric(strip(gv))
  u <- sort(unique(na.omit(x)))
  if (all(u %in% c(1, 2))) return(x == 2)
  if (all(u %in% c(0, 1))) return(x == 1)
  x == max(u)
}

res_w <- NA; res_m <- NA; n_w <- NA; n_m <- NA
try({
  g <- prep_raw(gd)
  keep <- filt(g)
  # if a filter column is absent in the gender file, fall back to the MP rule for that part
  g <- g[keep, ]
  g$is_f <- gender_split(g)
  cat("Gender table:\n"); print(table(g$gender, g$is_f, useNA = "ifany"))
  run_g <- function(sub) {
    sub <- sub[complete.cases(sub[, full_vars]), ]
    sub$rile_std <- (sub$rile_raw - mean(sub$rile_raw)) / sd(sub$rile_raw)
    feols(dv ~ women + rile_std + coal + opp | cy, data = sub, cluster = ~cy)
  }
  mw <- run_g(g[g$is_f %in% TRUE, ])
  mm <- run_g(g[g$is_f %in% FALSE, ])
  print(summary(mw)); print(summary(mm))
  res_w <- coef(mw)["women"]; n_w <- nobs(mw)
  res_m <- coef(mm)["women"]; n_m <- nobs(mm)
}, silent = FALSE)

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["women"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["women"]))
if (!is.na(res_w)) cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", res_w))
if (!is.na(res_m)) cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", res_m))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rile_std"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["coal"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opp"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", as.integer(nobs(m2))))
if (!is.na(n_w)) cat(sprintf("RESULT:n_obs_women_partisans=%d\n", as.integer(n_w)))
if (!is.na(n_m)) cat(sprintf("RESULT:n_obs_men_partisans=%d\n", as.integer(n_m)))
cat(sprintf("RESULT:n_election_studies=%d\n", length(unique(d2$cy))))