suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"
load(file.path(base, "dyadic_data_1-4-22.Rdata"))   # creates updated_data
dyad <- as.data.frame(updated_data)
gend <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

strip_labels <- function(df) {
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) {
      df[[v]] <- as.vector(unclass(x)); attributes(df[[v]]) <- NULL
    }
  }
  df
}
gend_raw_gender <- gend$gender
dyad <- strip_labels(dyad)
gend <- strip_labels(gend)

cat("Dyadic columns:\n"); print(names(dyad))

# ---- locate the out-party women share variable ----
find_women_var <- function(df) {
  nm <- names(df)
  cand <- nm[grepl("wom|fem", nm, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) is.numeric(df[[v]]))]
  if (length(cand) == 0) stop("No women-share variable found")
  score <- sapply(cand, function(v) {
    s <- 0
    lv <- tolower(v)
    if (grepl("^to_|_to_|_to$|to_", lv)) s <- s + 10
    if (grepl("^from_|_from_|_from$|from_", lv)) s <- s - 20
    if (grepl("lag|t_1|t1|prior|prev", lv)) s <- s + 5
    if (grepl("prop|share|pct|perc|ratio|frac", lv)) s <- s + 3
    if (grepl("lead|leader", lv)) s <- s - 15
    if (grepl("number|num|count|_n$", lv)) s <- s - 4
    if (grepl("sq|squared|2$", lv)) s <- s - 6
    x <- df[[v]]
    rng <- range(x, na.rm = TRUE)
    if (rng[1] >= 0 && rng[2] <= 1 && length(unique(na.omit(x))) > 2) s <- s + 4
    if (rng[1] >= 0 && rng[2] <= 100 && rng[2] > 1 && length(unique(na.omit(x))) > 2) s <- s + 1
    if (length(unique(na.omit(x))) <= 2) s <- s - 10
    s
  })
  cat("Women-share candidates and scores:\n"); print(score)
  names(score)[which.max(score)]
}

find_dv <- function(df) {
  nm <- names(df)
  th <- nm[grepl("therm", nm, ignore.case = TRUE)]
  th <- th[sapply(th, function(v) is.numeric(df[[v]]))]
  if (length(th) > 0) return(th[1])
  if ("party_like" %in% nm) return("party_like")
  stop("No DV found")
}

prep <- function(df, wvar, dvvar) {
  out <- df
  out$dv <- out[[dvvar]]
  w <- out[[wvar]]
  if (max(w, na.rm = TRUE) > 1.0001) w <- w / 100
  out$women_to <- w
  out$country_c <- as.character(out$country)
  out$year_c <- as.character(out$year)
  out$cy <- paste(out$country_c, out$year_c, sep = "_")
  if (all(c("party_from", "party_to") %in% names(out))) {
    out <- out[is.na(out$party_from) | is.na(out$party_to) |
                 as.character(out$party_from) != as.character(out$party_to), ]
  }
  if (all(c("to_mp_number", "from_mp_number") %in% names(out))) {
    out <- out[!is.na(out$to_mp_number) & !is.na(out$from_mp_number) &
                 out$to_mp_number >= 4 & out$from_mp_number >= 4, ]
  }
  out$govern_together <- as.numeric(out$govern_together)
  out$opposition_together <- as.numeric(out$opposition_together)
  out
}

wvar <- find_women_var(dyad)
dvvar <- find_dv(dyad)
cat("Using women var:", wvar, " DV:", dvvar, "\n")
cat("DV summary:\n"); print(summary(dyad[[dvvar]]))

d <- prep(dyad, wvar, dvvar)
full_vars <- c("dv", "women_to", "rile_distance", "govern_together", "opposition_together", "cy")
d_full <- d[complete.cases(d[, full_vars]), ]
d_full$rile_std <- (d_full$rile_distance - mean(d_full$rile_distance)) / sd(d_full$rile_distance)
cat("rile_distance mean/sd in sample:", mean(d_full$rile_distance), sd(d_full$rile_distance), "\n")

m1 <- feols(dv ~ women_to | cy, data = d_full, cluster = ~cy)
m2 <- feols(dv ~ women_to + rile_std + govern_together + opposition_together | cy,
            data = d_full, cluster = ~cy)
print(summary(m1)); print(summary(m2))
cat("Adj R2 m1:", r2(m1, "ar2"), " m2:", r2(m2, "ar2"), "\n")

# ---- gender-disaggregated models ----
g_wvar <- if (wvar %in% names(gend)) wvar else find_women_var(gend)
g_dvvar <- if (dvvar %in% names(gend)) dvvar else find_dv(gend)
g <- prep(gend, g_wvar, g_dvvar)

cat("Gender values:\n"); print(table(gend$gender, useNA = "ifany"))
labs <- attr(gend_raw_gender, "labels")
if (!is.null(labs)) { cat("Gender labels:\n"); print(labs) }

classify_gender <- function(x, labs) {
  res <- rep(NA_character_, length(x))
  if (is.factor(x) || is.character(x)) {
    xs <- tolower(trimws(as.character(x)))
    res[grepl("^f|wom|female", xs)] <- "women"
    res[grepl("^m|^man|^men|male", xs) & !grepl("female|wom", xs)] <- "men"
    return(res)
  }
  if (!is.null(labs)) {
    ln <- tolower(names(labs))
    fv <- labs[grepl("fem|wom", ln)]
    mv <- labs[grepl("male|^men|^man", ln) & !grepl("fem|wom", ln)]
    if (length(fv) && length(mv)) {
      res[x %in% fv] <- "women"; res[x %in% mv] <- "men"; return(res)
    }
  }
  vals <- sort(unique(na.omit(x)))
  if (all(vals %in% c(1, 2))) { res[x == 2] <- "women"; res[x == 1] <- "men" }
  else if (all(vals %in% c(0, 1))) { res[x == 1] <- "women"; res[x == 0] <- "men" }
  res
}
g$gcat <- classify_gender(g$gender, labs)
print(table(g$gcat, useNA = "ifany"))

fit_g <- function(sub) {
  sub <- sub[complete.cases(sub[, full_vars]), ]
  sub$rile_std <- (sub$rile_distance - mean(d_full$rile_distance)) / sd(d_full$rile_distance)
  feols(dv ~ women_to + rile_std + govern_together + opposition_together | cy,
        data = sub, cluster = ~cy)
}
m3 <- fit_g(g[!is.na(g$gcat) & g$gcat == "women", ])
m4 <- fit_g(g[!is.na(g$gcat) & g$gcat == "men", ])
print(summary(m3)); print(summary(m4))

n_elec <- length(unique(d_full$cy[obs(m2)]))

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["women_to"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["women_to"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["women_to"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["women_to"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rile_std"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["govern_together"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opposition_together"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_elec))
