suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

to_num <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    xl <- tolower(trimws(x))
    if (all(xl %in% c("yes", "no", "true", "false", NA, ""))) {
      return(ifelse(xl %in% c("yes", "true"), 1, ifelse(xl %in% c("no", "false"), 0, NA)))
    }
    return(suppressWarnings(as.numeric(x)))
  }
  as.numeric(x)
}

## ---------------- load data ----------------
e1 <- new.env()
load(file.path(base, "dyadic_data_1-4-22.Rdata"), envir = e1)
dy <- as.data.frame(e1$updated_data)
gd <- tryCatch(as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds"))),
               error = function(e) NULL)

cat("Dyadic columns:\n"); print(names(dy))
if (!is.null(gd)) { cat("Gender columns:\n"); print(names(gd)) }

## ---------------- helpers to locate variables ----------------
dv_ok <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[!is.na(x)]
  if (length(x) < 100) return(FALSE)
  mn <- min(x); mx <- max(x); m <- mean(x); s <- sd(x)
  nonint <- mean(abs(x - round(x)) > 1e-8)
  mn >= 0 && mx <= 10 && m > 1 && m < 9 && s > 0.4 && s < 4 && nonint > 0.3
}

find_dv <- function(d) {
  nm <- names(d)
  numnm <- nm[sapply(d, function(z) is.numeric(z) || is.logical(z))]
  pref <- c("thermometer_score", "mean_thermometer", "thermometer", "mean_therm",
            "dislike", "like", "mean_like", "mean_dislike", "evaluation", "rating",
            "out_party_rating", "ptv")
  for (p in pref) if (p %in% numnm && dv_ok(d[[p]])) return(p)
  cand <- numnm[grepl("therm|dislike|like|eval|rating|feel|score", numnm, ignore.case = TRUE)]
  cand <- cand[!grepl("^party_like$|^party_dislike$", cand)]
  cand <- cand[!grepl("^(from|to)_", cand)]
  for (p in cand) if (dv_ok(d[[p]])) return(p)
  for (p in c("party_like", "party_dislike")) if (p %in% numnm && dv_ok(d[[p]])) return(p)
  NULL
}

find_ws <- function(d) {
  nm <- names(d)
  cand <- nm[grepl("wom|female|fem_|fem$|_fem|prop_w|pct_w|share_w|perc_w", nm, ignore.case = TRUE)]
  cand <- cand[!grepl("^gender$", cand, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) is.numeric(d[[v]]))]
  cand <- cand[!grepl("leader|resp|voter|cand", cand, ignore.case = TRUE)]
  if (length(cand) == 0) return(NULL)
  score <- sapply(cand, function(v) {
    s <- 0
    if (grepl("^to_|_to_|_to$", v)) s <- s + 10
    if (grepl("^from_|_from_|_from$", v)) s <- s - 20
    if (grepl("lag|t1|t_1|prev", v, ignore.case = TRUE)) s <- s + 3
    if (grepl("prop|share|pct|perc|percent", v, ignore.case = TRUE)) s <- s + 2
    if (grepl("number|num|count|_n$|^n_", v, ignore.case = TRUE)) s <- s - 1
    if (grepl("sq|squared|2$|_x_|inter|dummy|parity", v, ignore.case = TRUE)) s <- s - 5
    s
  })
  cand[order(-score)][1]
}

make_ws <- function(d, v) {
  x <- as.numeric(d[[v]])
  if (grepl("number|num|count|_n$|^n_", v, ignore.case = TRUE) &&
      "to_mp_number" %in% names(d) && max(x, na.rm = TRUE) > 1) {
    x <- x / as.numeric(d$to_mp_number)
  } else if (max(x, na.rm = TRUE) > 1.0001 && max(x, na.rm = TRUE) <= 100) {
    x <- x / 100
  }
  x
}

find_col <- function(d, opts, regex = NULL) {
  for (o in opts) if (o %in% names(d)) return(o)
  if (!is.null(regex)) {
    m <- names(d)[grepl(regex, names(d), ignore.case = TRUE)]
    if (length(m)) return(m[1])
  }
  NULL
}

## ---------------- prepare main dyadic data ----------------
prep <- function(d, dvname = NULL) {
  if (is.null(dvname)) dvname <- find_dv(d)
  wsname <- find_ws(d)
  cat("DV:", ifelse(is.null(dvname), "NONE", dvname),
      " | women share:", ifelse(is.null(wsname), "NONE", wsname), "\n")
  out <- d
  out$dv <- if (!is.null(dvname)) as.numeric(d[[dvname]]) else NA_real_
  out$ws <- if (!is.null(wsname)) make_ws(d, wsname) else NA_real_
  out$rl_raw <- abs(to_num(d$rile_distance))
  out$coal <- to_num(d$govern_together)
  out$opp <- to_num(d$opposition_together)
  out$to_mp <- to_num(d$to_mp_number)
  out$from_mp <- to_num(d$from_mp_number)
  out$cy <- paste(d$country, d$year, sep = "_")
  out
}

dd <- prep(dy)

## fallback: build DV from individual-level data if not found
if (all(is.na(dd$dv))) {
  cat("DV not found in dyadic file; aggregating multilevel data\n")
  e2 <- new.env()
  load(file.path(base, "multilevel_1-5-22.Rdata"), envir = e2)
  ml <- as.data.frame(e2$multilevel_data)
  agg <- ml %>% group_by(country, year, party_from, party_to) %>%
    summarise(dv_agg = mean(as.numeric(thermometer_score), na.rm = TRUE), .groups = "drop")
  dd <- dd %>% left_join(agg, by = c("country", "year", "party_from", "party_to"))
  dd$dv <- dd$dv_agg
}

restrict <- function(d) {
  d %>% filter(!is.na(to_mp), !is.na(from_mp), to_mp >= 4, from_mp >= 4,
               !is.na(dv), !is.na(ws), !is.na(rl_raw), !is.na(coal), !is.na(opp))
}

s <- restrict(dd)
rl_sd <- sd(s$rl_raw)
s$rl <- s$rl_raw / rl_sd
cat("Sample N:", nrow(s), " elections:", length(unique(s$cy)), " rl raw mean/sd:",
    mean(s$rl_raw), rl_sd, "\n")

m2 <- feols(dv ~ ws + rl + coal + opp | cy, data = s, cluster = ~cy)

## orientation check: CSES thermometer is 0 = dislike, 10 = like.
flip <- FALSE
if (coef(m2)["coal"] < 0 && coef(m2)["ws"] < 0) {
  cat("DV appears reverse-coded; using 10 - DV\n")
  flip <- TRUE
  s$dv <- 10 - s$dv
  m2 <- feols(dv ~ ws + rl + coal + opp | cy, data = s, cluster = ~cy)
}
m1 <- feols(dv ~ ws | cy, data = s, cluster = ~cy)

print(summary(m1)); print(summary(m2))
cat("Adj R2 m1:", r2(m1, "ar2"), " m2:", r2(m2, "ar2"), "\n")

## ---------------- gender-disaggregated models ----------------
gw <- NULL; gm <- NULL
tryCatch({
  if (is.null(gd)) stop("no gender data")
  g <- gd
  if (is.null(find_ws(g))) {
    wsn <- find_ws(dy)
    key <- intersect(c("country", "year", "party_from", "party_to"), names(g))
    add <- dy[, c(key, wsn)]
    add <- add[!duplicated(add[, key]), ]
    g <- left_join(g, add, by = key)
  }
  gdv <- find_dv(g)
  gp <- prep(g, gdv)
  if (all(is.na(gp$dv))) stop("no gender DV")
  if (flip) gp$dv <- 10 - gp$dv
  gv <- g$gender
  if (is.factor(gv)) gv <- as.character(gv)
  if (is.character(gv)) {
    fem <- grepl("^f|wom|^2$", trimws(gv), ignore.case = TRUE)
    male <- grepl("^m(?!.*wom)|^men|^1$", trimws(gv), ignore.case = TRUE, perl = TRUE) & !fem
  } else {
    gvn <- as.numeric(gv)
    u <- sort(unique(gvn[!is.na(gvn)]))
    if (all(u %in% c(1, 2))) { fem <- gvn == 2; male <- gvn == 1 }
    else { fem <- gvn == 1; male <- gvn == 0 }
  }
  fem[is.na(fem)] <- FALSE; male[is.na(male)] <- FALSE
  cat("Gender table:\n"); print(table(gv, useNA = "ifany"))
  gw_d <- restrict(gp[fem, ]); gw_d$rl <- gw_d$rl_raw / rl_sd
  gm_d <- restrict(gp[male, ]); gm_d$rl <- gm_d$rl_raw / rl_sd
  gw <- feols(dv ~ ws + rl + coal + opp | cy, data = gw_d, cluster = ~cy)
  gm <- feols(dv ~ ws + rl + coal + opp | cy, data = gm_d, cluster = ~cy)
  print(summary(gw)); print(summary(gm))
}, error = function(e) cat("Gender models failed:", conditionMessage(e), "\n"))

## ---------------- output ----------------
emit("women_mps_coef_bivariate", coef(m1)["ws"])
emit("women_mps_coef_full", coef(m2)["ws"])
emit("women_mps_coef_women_partisans", if (!is.null(gw)) coef(gw)["ws"] else NA)
emit("women_mps_coef_men_partisans", if (!is.null(gm)) coef(gm)["ws"] else NA)
emit("right_left_distance_coef_full", coef(m2)["rl"])
emit("coalition_partners_coef_full", coef(m2)["coal"])
emit("opposition_partners_coef_full", coef(m2)["opp"])
emit("n_directed_dyads", nobs(m2))
emit("n_obs_women_partisans", if (!is.null(gw)) nobs(gw) else NA)
emit("n_obs_men_partisans", if (!is.null(gm)) nobs(gm) else NA)
emit("n_election_studies", length(unique(s$cy)))