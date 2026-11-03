suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

e <- new.env()
load(file.path(base, "dyadic_data_1-4-22.Rdata"), envir = e)
dy <- as.data.frame(e$updated_data)
gd <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

strip_lab <- function(df) {
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) {
      df[[v]] <- as.vector(unclass(x))
      attr(df[[v]], "labels") <- attr(x, "labels")
    }
  }
  df
}
dy <- strip_lab(dy)
gd <- strip_lab(gd)

cat("Dyadic columns:\n"); print(names(dy))
cat("Gender columns:\n"); print(names(gd))

num <- function(x) suppressWarnings(as.numeric(as.vector(x)))

is_dv_like <- function(x) {
  x <- num(x)
  x <- x[is.finite(x)]
  if (length(x) < 50) return(FALSE)
  if (min(x) < 0 || max(x) > 10) return(FALSE)
  mean(abs(x - round(x)) > 1e-8) > 0.3
}

pick_dv <- function(df) {
  nm <- names(df)
  ok <- !grepl("^(to|from)_", nm, ignore.case = TRUE)
  cands <- c(nm[ok & grepl("therm", nm, ignore.case = TRUE)],
             nm[ok & grepl("^(mean_?)?(like|evaluation|rating|feeling|score)", nm, ignore.case = TRUE)],
             nm[ok & grepl("^(mean_?)?dislike", nm, ignore.case = TRUE)],
             intersect(c("party_like", "party_dislike", "dislike", "like"), nm))
  cands <- unique(cands)
  for (cn in cands) if (is_dv_like(df[[cn]])) return(cn)
  # fallback: any numeric non-to/from column in 0-10 with fractional values
  for (cn in nm[ok]) if (is.numeric(df[[cn]]) && is_dv_like(df[[cn]])) return(cn)
  NA_character_
}

pick_mp <- function(df, side) {
  nm <- names(df)
  pat <- paste0("^", side, "_.*mp")
  c1 <- nm[grepl(pat, nm, ignore.case = TRUE) & grepl("lag", nm, ignore.case = TRUE) &
             !grepl("wom|fem", nm, ignore.case = TRUE)]
  if (length(c1)) return(c1[1])
  c2 <- paste0(side, "_mp_number")
  if (c2 %in% nm) return(c2)
  c3 <- nm[grepl(pat, nm, ignore.case = TRUE) & !grepl("wom|fem", nm, ignore.case = TRUE)]
  if (length(c3)) return(c3[1])
  NA_character_
}

get_women_share <- function(df) {
  nm <- names(df)
  c0 <- nm[grepl("^to", nm, ignore.case = TRUE) & grepl("wom|fem", nm, ignore.case = TRUE) &
             !grepl("lead|leader|chair", nm, ignore.case = TRUE)]
  if (!length(c0)) {
    c0 <- nm[grepl("wom|fem", nm, ignore.case = TRUE) & !grepl("^from", nm, ignore.case = TRUE) &
               !grepl("lead|leader|chair", nm, ignore.case = TRUE)]
  }
  if (!length(c0)) stop("No women-share column found")
  score <- function(n) {
    s <- 0
    if (grepl("lag", n, ignore.case = TRUE)) s <- s + 4
    if (grepl("prop|share|pct|perc|per", n, ignore.case = TRUE)) s <- s + 2
    if (grepl("sq|squared|\\^2|_2$|cent|std|z_", n, ignore.case = TRUE)) s <- s - 5
    s
  }
  c0 <- c0[order(-sapply(c0, score))]
  mpcol <- pick_mp(df, "to")
  for (cn in c0) {
    x <- num(df[[cn]])
    if (all(!is.finite(x))) next
    xf <- x[is.finite(x)]
    if (min(xf) < 0) next
    if (max(xf) <= 1) { cat("Women share column:", cn, "(proportion)\n"); return(x) }
    isint <- all(abs(xf - round(xf)) < 1e-8)
    if (isint && !is.na(mpcol)) {
      mp <- num(df[[mpcol]])
      okk <- is.finite(x) & is.finite(mp)
      if (all(x[okk] <= mp[okk])) {
        cat("Women share column:", cn, "(count / ", mpcol, ")\n")
        return(ifelse(mp > 0, x / mp, NA))
      }
    }
    if (max(xf) <= 100) { cat("Women share column:", cn, "(percent)\n"); return(x / 100) }
  }
  stop("Could not construct women share")
}

get_rile_dist <- function(df) {
  nm <- names(df)
  c0 <- nm[grepl("rile|left.?right|lr_", nm, ignore.case = TRUE) &
             grepl("dist|diff|abs|gap", nm, ignore.case = TRUE) &
             !grepl("voter|mass|public|perceiv|lag|prior|prev", nm, ignore.case = TRUE)]
  if (length(c0)) {
    c0 <- c0[order(-grepl("elite|rile", c0, ignore.case = TRUE))]
    cat("Rile distance column:", c0[1], "\n")
    return(abs(num(df[[c0[1]]])))
  }
  fr <- if ("from_rile" %in% nm) "from_rile" else nm[grepl("^from.*rile", nm, ignore.case = TRUE)][1]
  tr <- if ("to_rile" %in% nm) "to_rile" else nm[grepl("^to.*rile", nm, ignore.case = TRUE)][1]
  if (is.na(fr) || is.na(tr)) stop("No rile variables")
  cat("Rile distance computed as |", fr, "-", tr, "|\n")
  abs(num(df[[fr]]) - num(df[[tr]]))
}

prep <- function(df) {
  out <- data.frame(country = as.character(df$country), year = num(df$year))
  out$cy <- paste(out$country, out$year, sep = "_")
  dvn <- pick_dv(df)
  cat("DV column:", dvn, "\n")
  out$y <- num(df[[dvn]])
  out$dvname <- dvn
  out$women <- get_women_share(df)
  out$rile_raw <- get_rile_dist(df)
  out$coal <- num(df$govern_together)
  out$opp <- num(df$opposition_together)
  fm <- pick_mp(df, "from"); tm <- pick_mp(df, "to")
  cat("MP columns:", fm, tm, "\n")
  out$from_mp <- num(df[[fm]]); out$to_mp <- num(df[[tm]])
  if (all(c("party_from", "party_to") %in% names(df))) {
    out$self <- as.character(df$party_from) == as.character(df$party_to)
  } else out$self <- FALSE
  out
}

d <- prep(dy)
d <- d %>% filter(from_mp >= 4, to_mp >= 4, !(self %in% TRUE))
d <- d %>% filter(is.finite(y), is.finite(women), is.finite(rile_raw), is.finite(coal), is.finite(opp))
d$rile_z <- (d$rile_raw - mean(d$rile_raw)) / sd(d$rile_raw)
cat("Rile raw mean/sd:", mean(d$rile_raw), sd(d$rile_raw), "\n")

fit_full <- function(dd) feols(y ~ women + rile_z + coal + opp | cy, data = dd, cluster = ~cy)

m2 <- fit_full(d)
# orientation check: DV should be a liking (thermometer) score; coalition partners rate each other warmer
if (coef(m2)["coal"] < 0 && grepl("dislike", d$dvname[1], ignore.case = TRUE)) {
  cat("DV appears reversed (dislike scale); using 10 - DV\n")
  d$y <- 10 - d$y
  m2 <- fit_full(d)
}
m1 <- feols(y ~ women | cy, data = d, cluster = ~cy)
print(summary(m1)); print(summary(m2))

# gender-disaggregated
g <- prep(gd)
gv <- gd$gender
labs <- attr(gv, "labels")
gnum <- num(gv)
if (is.character(gv) || is.factor(gv)) {
  gl <- tolower(as.character(gv))
  is_w <- grepl("^f|wom|fem", gl)
  is_m <- grepl("^m|^man|^men|male", gl) & !is_w
} else if (!is.null(labs)) {
  ln <- tolower(names(labs))
  wv <- labs[grepl("^f|wom|fem", ln)]
  mv <- labs[grepl("^m|male|^man|^men", ln) & !grepl("^f|wom|fem", ln)]
  is_w <- gnum %in% wv; is_m <- gnum %in% mv
} else {
  u <- sort(unique(gnum[is.finite(gnum)]))
  if (all(u %in% c(1, 2))) { is_w <- gnum == 2; is_m <- gnum == 1 }
  else { is_w <- gnum == 1; is_m <- gnum == 0 }
}
is_w[is.na(is_w)] <- FALSE; is_m[is.na(is_m)] <- FALSE
cat("Gender table:\n"); print(table(as.character(gv), useNA = "ifany"))
g$is_w <- is_w; g$is_m <- is_m
g <- g %>% filter(from_mp >= 4, to_mp >= 4, !(self %in% TRUE)) %>%
  filter(is.finite(y), is.finite(women), is.finite(rile_raw), is.finite(coal), is.finite(opp))
g$rile_z <- (g$rile_raw - mean(d$rile_raw)) / sd(d$rile_raw)

gw <- g[g$is_w, ]; gm <- g[g$is_m, ]
m3 <- fit_full(gw); m4 <- fit_full(gm)
if (coef(m3)["coal"] + coef(m4)["coal"] < 0 && grepl("dislike", g$dvname[1], ignore.case = TRUE)) {
  cat("Gender DV appears reversed; using 10 - DV\n")
  gw$y <- 10 - gw$y; gm$y <- 10 - gm$y
  m3 <- fit_full(gw); m4 <- fit_full(gm)
}
print(summary(m3)); print(summary(m4))

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["women"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["women"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["women"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["women"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rile_z"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["coal"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opp"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", as.integer(nobs(m3))))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", as.integer(nobs(m4))))
cat(sprintf("RESULT:n_election_studies=%d\n", length(unique(d$cy))))