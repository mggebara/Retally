suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))   # creates updated_data
dy <- as.data.frame(updated_data)
gd <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

cat("Dyadic columns:\n"); print(names(dy))
cat("Gender columns:\n"); print(names(gd))

num <- function(x) suppressWarnings(as.numeric(as.character(x)))

# ---------------------------------------------------------------- helpers
pick_dv <- function(d) {
  nm <- names(d)
  excl <- c("party_like", "party_dislike")
  pats <- c("^thermometer_score$", "therm", "^mean_like$", "like_score", "^like$",
            "^dislike$", "mean.*like", "like", "rating", "eval", "sympath")
  for (p in pats) {
    cands <- setdiff(nm[grepl(p, nm, ignore.case = TRUE)], excl)
    cands <- cands[!grepl("^(from|to)_", cands)]
    for (cc in cands) {
      x <- num(d[[cc]])
      ux <- unique(x[!is.na(x)])
      if (length(ux) > 10 && min(ux) >= 0 && max(ux) <= 10) return(cc)
    }
  }
  NA_character_
}

pick_women <- function(d) {
  nm <- names(d)
  c1 <- nm[grepl("wom|fem", nm, ignore.case = TRUE)]
  c1 <- c1[!grepl("lead|from", c1, ignore.case = TRUE)]
  c1 <- c1[grepl("^to|_to|to_", c1, ignore.case = TRUE)]
  if (length(c1) == 0) {
    c1 <- nm[grepl("wom|fem", nm, ignore.case = TRUE)]
    c1 <- c1[!grepl("lead|from|^gender$", c1, ignore.case = TRUE)]
  }
  if (length(c1) == 0) return(NULL)
  # keep numeric, non-constant
  c1 <- c1[sapply(c1, function(cc) { x <- num(d[[cc]]); sum(!is.na(x)) > 0 && length(unique(x[!is.na(x)])) > 2 })]
  if (length(c1) == 0) return(NULL)
  ord <- c(c1[grepl("lag", c1, ignore.case = TRUE) & grepl("prop|share|pct|perc|per", c1, ignore.case = TRUE)],
           c1[grepl("lag", c1, ignore.case = TRUE)],
           c1[grepl("prop|share|pct|perc|per", c1, ignore.case = TRUE)],
           c1)
  ord <- unique(ord)
  # prefer proportions (not counts)
  for (cc in ord) {
    x <- num(d[[cc]])
    if (max(x, na.rm = TRUE) <= 100 && !grepl("number|count|^n_", cc, ignore.case = TRUE))
      return(list(name = cc, x = if (max(x, na.rm = TRUE) > 1.5) x / 100 else x))
  }
  # fall back: count / total MPs
  cc <- ord[1]
  x <- num(d[[cc]]) / num(d[["to_mp_number"]])
  list(name = paste0(cc, "/to_mp_number"), x = x)
}

pick_dist <- function(d) {
  nm <- names(d)
  c1 <- nm[grepl("rile", nm, ignore.case = TRUE) & grepl("dist|diff|abs", nm, ignore.case = TRUE)]
  if (length(c1) == 0)
    c1 <- nm[grepl("(lr|left_right|leftright|ideo).*(dist|diff)|(dist|diff).*(lr|left|ideo)", nm, ignore.case = TRUE)]
  c1 <- c1[!grepl("lag|_1$|t1", c1, ignore.case = TRUE) | length(c1) == 1]
  if (length(c1) > 0) return(list(name = c1[1], x = abs(num(d[[c1[1]]]))))
  if (all(c("from_rile", "to_rile") %in% nm))
    return(list(name = "abs(from_rile - to_rile)", x = abs(num(d$from_rile) - num(d$to_rile))))
  NULL
}

prep <- function(d) {
  out <- data.frame(country = as.character(d$country), year = num(d$year))
  out$cy <- paste(out$country, out$year, sep = "_")
  dvn <- pick_dv(d)
  cat("DV column:", dvn, "\n")
  y <- num(d[[dvn]])
  out$govern_together <- num(d$govern_together)
  out$opposition_together <- num(d$opposition_together)
  if (grepl("dislike", dvn, ignore.case = TRUE)) {
    cc <- suppressWarnings(cor(y, out$govern_together, use = "complete.obs"))
    if (!is.na(cc) && cc < 0) { cat("Reversing DV (dislike scale)\n"); y <- 10 - y }
  }
  out$y <- y
  w <- pick_women(d); cat("Women share column:", w$name, "\n")
  out$women <- w$x
  ds <- pick_dist(d); cat("Distance column:", ds$name, "\n")
  out$dist_raw <- ds$x
  out$from_mp <- num(d$from_mp_number)
  out$to_mp <- num(d$to_mp_number)
  if (all(c("party_from", "party_to") %in% names(d))) {
    out$pf <- as.character(d$party_from); out$pt <- as.character(d$party_to)
  } else { out$pf <- NA; out$pt <- NA }
  out
}

restrict <- function(o) {
  keep <- (is.na(o$from_mp) | o$from_mp >= 4) & (is.na(o$to_mp) | o$to_mp >= 4)
  keep <- keep & (is.na(o$pf) | is.na(o$pt) | o$pf != o$pt)
  o <- o[keep, ]
  cc <- complete.cases(o[, c("y", "women", "dist_raw", "govern_together", "opposition_together", "cy")])
  o$dist_std <- NA_real_
  o$dist_std[cc] <- (o$dist_raw[cc] - mean(o$dist_raw[cc])) / sd(o$dist_raw[cc])
  o
}

fit_models <- function(o) {
  m1 <- feols(y ~ women | cy, data = o, cluster = ~cy)
  m2 <- feols(y ~ women + dist_std + govern_together + opposition_together | cy,
              data = o, cluster = ~cy)
  list(m1 = m1, m2 = m2)
}

res <- list()
sf <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NA })

# ---------------------------------------------------------------- main models
od <- sf(restrict(prep(dy)))
mm <- sf(fit_models(od))
if (is.list(mm)) {
  print(summary(mm$m1)); print(summary(mm$m2))
  res$women_mps_coef_bivariate <- unname(coef(mm$m1)["women"])
  res$women_mps_coef_full <- unname(coef(mm$m2)["women"])
  res$right_left_distance_coef_full <- unname(coef(mm$m2)["dist_std"])
  res$coalition_partners_coef_full <- unname(coef(mm$m2)["govern_together"])
  res$opposition_partners_coef_full <- unname(coef(mm$m2)["opposition_together"])
  res$n_directed_dyads <- nobs(mm$m2)
  used <- od[obs(mm$m2), ]
  res$n_election_studies <- length(unique(used$cy))
  cat("N bivariate:", nobs(mm$m1), "\n")
}

# ---------------------------------------------------------------- gender models
og <- sf(prep(gd))
if (is.data.frame(og)) {
  g <- gd$gender
  gch <- tolower(as.character(if (is.factor(g)) as.character(g) else g))
  cat("Gender values:\n"); print(table(gch, useNA = "ifany"))
  gn <- suppressWarnings(as.numeric(gch))
  if (all(is.na(gn[!is.na(gch)]))) {
    is_w <- grepl("^f|wom|female", gch)
    is_m <- grepl("^m|^men|male", gch) & !is_w
  } else {
    u <- sort(unique(gn[!is.na(gn)]))
    if (all(u %in% c(1, 2))) { is_w <- gn == 2; is_m <- gn == 1 }
    else { is_w <- gn == 1; is_m <- gn == 0 }
  }
  is_w[is.na(is_w)] <- FALSE; is_m[is.na(is_m)] <- FALSE
  ow <- sf(restrict(og[is_w, ]))
  om <- sf(restrict(og[is_m, ]))
  mw <- sf(feols(y ~ women + dist_std + govern_together + opposition_together | cy,
                 data = ow, cluster = ~cy))
  mmn <- sf(feols(y ~ women + dist_std + govern_together + opposition_together | cy,
                  data = om, cluster = ~cy))
  if (inherits(mw, "fixest")) {
    print(summary(mw))
    res$women_mps_coef_women_partisans <- unname(coef(mw)["women"])
    res$n_obs_women_partisans <- nobs(mw)
  }
  if (inherits(mmn, "fixest")) {
    print(summary(mmn))
    res$women_mps_coef_men_partisans <- unname(coef(mmn)["women"])
    res$n_obs_men_partisans <- nobs(mmn)
  }
}

# ---------------------------------------------------------------- output
nms <- c("women_mps_coef_bivariate", "women_mps_coef_full", "women_mps_coef_women_partisans",
         "women_mps_coef_men_partisans", "right_left_distance_coef_full",
         "coalition_partners_coef_full", "opposition_partners_coef_full",
         "n_directed_dyads", "n_obs_women_partisans", "n_obs_men_partisans",
         "n_election_studies")
for (n in nms) {
  v <- if (is.null(res[[n]])) NA else res[[n]]
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 6)))
}
