suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

to01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    lx <- tolower(trimws(x))
    out <- rep(NA_real_, length(lx))
    out[lx %in% c("yes", "y", "1", "true", "voted", "treatment", "treated", "attended")] <- 1
    out[lx %in% c("no", "n", "0", "false", "did not vote", "control", "not voted")] <- 0
    num <- suppressWarnings(as.numeric(lx))
    out[is.na(out) & !is.na(num)] <- num[is.na(out) & !is.na(num)]
    return(out)
  }
  x <- as.numeric(x)
  u <- sort(unique(x[!is.na(x)]))
  if (length(u) == 2 && all(u == c(1, 2))) x <- ifelse(x == 1, 1, 0)
  x
}

to_num_item <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  lx <- tolower(trimws(x))
  num <- suppressWarnings(as.numeric(lx))
  if (mean(!is.na(num[!is.na(lx) & lx != ""])) > 0.8) return(num)
  out <- rep(NA_real_, length(lx))
  out[grepl("strongly disagree", lx)] <- 1
  out[is.na(out) & grepl("disagree", lx)] <- 2
  out[is.na(out) & grepl("strongly agree", lx)] <- 4
  out[is.na(out) & grepl("agree", lx)] <- 3
  out[is.na(out) & !is.na(num)] <- num[is.na(out) & !is.na(num)]
  out
}

normname <- function(x) gsub("[^a-z0-9]", "", tolower(as.character(x)))

# ---------------- Barangay level ----------------
da <- as.data.frame(data.all)
da$Z <- to01(da$assignment)
da$city_f <- as.character(da$city)

# Identify Akbayan barangays
pt <- da$partytreat
is_akb <- NULL
if (is.character(pt) || is.factor(pt)) {
  ptc <- tolower(as.character(pt))
  if (any(grepl("akb", ptc))) is_akb <- grepl("akb", ptc)
  else if (any(grepl("umal", ptc))) is_akb <- !grepl("umal", ptc)
}
if (is.null(is_akb)) {
  tb <- table(pt)
  v18 <- names(tb)[tb == 18]
  if (length(v18) == 1 && length(tb) == 2) {
    is_akb <- as.character(pt) == v18
  } else {
    vals <- names(tb)
    m <- sapply(vals, function(v) mean(as.numeric(da$share.akbayan[as.character(pt) == v]), na.rm = TRUE))
    is_akb <- as.character(pt) == vals[which.max(m)]
  }
}
da$akb <- is_akb

turn <- as.numeric(da$turnout.party)
if (max(turn, na.rm = TRUE) <= 1.5) turn <- turn * 100
sa <- as.numeric(da$share.akbayan)
su <- as.numeric(da$share.umalabka)
share_scale <- if (max(sa, na.rm = TRUE) <= 1) 100 else 1
sa <- sa * share_scale
su <- su * share_scale
da$turn <- turn
da$sa <- sa
da$su <- su
da$vote_pooled <- ifelse(da$akb, sa, su)
if (sum(da$akb) != 18 && "share.treated" %in% names(da)) {
  st <- as.numeric(da$share.treated)
  if (max(st, na.rm = TRUE) <= 1) st <- st * 100
  da$vote_pooled <- st
}

fit_b <- function(f, d) tryCatch(feols(f, data = d), error = function(e) NULL)
m1 <- fit_b(turn ~ Z | city_f, da)
m2 <- fit_b(vote_pooled ~ Z | city_f, da)
m3 <- fit_b(sa ~ Z | city_f, da[da$akb, ])
m4 <- fit_b(su ~ Z | city_f, da[!da$akb, ])
if (!is.null(m1)) emit("itt_turnout_barangay_table1_col1", unname(coef(m1)["Z"]))
if (!is.null(m2)) emit("itt_vote_overall_barangay_table1_col2", unname(coef(m2)["Z"]))
if (!is.null(m3)) emit("itt_vote_akbayan_barangay_table1_col3", unname(coef(m3)["Z"]))
if (!is.null(m4)) emit("itt_vote_umalabka_barangay_table1_col4", unname(coef(m4)["Z"]))
if (!is.null(m2)) emit("n_obs_barangay_table1_cols1_2", nobs(m2))
if (!is.null(m3)) emit("n_obs_barangay_akbayan_table1_col3", nobs(m3))
if (!is.null(m4)) emit("n_obs_barangay_umalabka_table1_col4", nobs(m4))

# ---------------- Individual level ----------------
sv <- as.data.frame(survey_raw)
sv$Z <- to01(sv$assignment)
sv$city_f <- as.character(sv$city)
sv$brgy_f <- paste(normname(sv$city), normname(sv$barangay), sep = "_")

excl <- grepl("imus|pateros|santamaria|stamaria", normname(sv$city))
sv <- sv[!excl, ]

# party identification
ptc <- sv$partytreat
sv_akb <- NULL
if (is.character(ptc) || is.factor(ptc)) {
  p2 <- tolower(as.character(ptc))
  if (any(grepl("akb", p2))) sv_akb <- grepl("akb", p2)
  else if (any(grepl("umal", p2))) sv_akb <- !grepl("umal", p2)
}
va <- to01(sv$vote.akbayan)
vu <- to01(sv$vote.umalabka)
if (is.null(sv_akb)) {
  vals <- unique(as.character(ptc[!is.na(ptc)]))
  m <- sapply(vals, function(v) mean(va[as.character(ptc) == v], na.rm = TRUE))
  sv_akb <- as.character(ptc) == vals[which.max(m)]
}
sv_akb[is.na(sv_akb)] <- FALSE
sv$akb <- sv_akb

# turnout
tvar <- if ("turnout_pl" %in% names(sv)) "turnout_pl" else "turnout_all"
sv$turnout <- to01(sv[[tvar]])
if (all(is.na(sv$turnout)) && "turnout_all" %in% names(sv)) sv$turnout <- to01(sv$turnout_all)

vote_treat <- ifelse(sv$akb, va, vu)
if (all(is.na(vote_treat))) vote_treat <- to01(sv$vote)
sv$vote_treat <- vote_treat * 100
sv$va100 <- va * 100

svt <- sv[!is.na(sv$turnout), ]
svv <- svt[svt$turnout == 1 & !is.na(svt$vote_treat), ]

mf1 <- tryCatch(feols(vote_treat ~ Z | city_f, data = svv, cluster = ~brgy_f), error = function(e) NULL)
if (!is.null(mf1)) emit("itt_vote_overall_unweighted_tableF1_col2", unname(coef(mf1)["Z"]))
svva <- svt[svt$turnout == 1 & svt$akb & !is.na(svt$va100), ]
mf2 <- tryCatch(feols(va100 ~ Z | city_f, data = svva, cluster = ~brgy_f), error = function(e) NULL)
if (!is.null(mf2)) emit("itt_vote_akbayan_unweighted_tableF1_col3", unname(coef(mf2)["Z"]))

# ---------------- Weights for attendee oversampling ----------------
sv$att <- to01(sv$attendance)
sv$w <- 1
ap <- as.numeric(da$att.prop)
if (all(is.na(ap)) && "att.prop.turn" %in% names(da)) ap <- as.numeric(da$att.prop.turn)
if (max(ap, na.rm = TRUE) > 1) ap <- ap / 100
da$brgy_key <- paste(normname(da$city), normname(da$barangay), sep = "_")
da$brgy_only <- normname(da$barangay)
sv$brgy_only <- normname(sv$barangay)
ap_map <- setNames(ap, da$brgy_key)
ap_map2 <- setNames(ap, da$brgy_only)
sv$p_true <- ap_map[sv$brgy_f]
miss <- is.na(sv$p_true)
sv$p_true[miss] <- ap_map2[sv$brgy_only[miss]]
for (b in unique(sv$brgy_f)) {
  idx <- which(sv$brgy_f == b)
  p <- sv$p_true[idx[1]]
  s <- mean(sv$att[idx], na.rm = TRUE)
  if (is.na(p) || is.na(s) || s <= 0 || s >= 1 || p <= 0) next
  a <- sv$att[idx]
  wb <- ifelse(is.na(a), 1, ifelse(a == 1, p / s, (1 - p) / (1 - s)))
  sv$w[idx] <- wb
}
sv$w[!is.finite(sv$w) | sv$w <= 0] <- 1

# ---------------- Anderson summary indices ----------------
anderson_index <- function(d, items) {
  items <- items[items %in% names(d)]
  X <- sapply(items, function(v) to_num_item(d[[v]]))
  X <- as.matrix(X)
  ctrl <- d$Z == 0 & !is.na(d$Z)
  Zs <- X
  for (j in seq_len(ncol(X))) {
    mu <- mean(X[ctrl, j], na.rm = TRUE)
    s <- sd(X[ctrl, j], na.rm = TRUE)
    Zs[, j] <- (X[, j] - mu) / s
  }
  keep <- apply(Zs, 2, function(z) any(is.finite(z)))
  Zs <- Zs[, keep, drop = FALSE]
  S <- cov(Zs, use = "pairwise.complete.obs")
  Sinv <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wts <- rowSums(Sinv)
  idx <- apply(Zs, 1, function(z) {
    ok <- is.finite(z)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * z[ok]) / sum(wts[ok])
  })
  mu <- mean(idx[ctrl], na.rm = TRUE)
  s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - mu) / s
}

pov_items <- c("poverty", "gap", "cct", "corruption")
gen_items <- c("femhouse", "fempol", "equality", "discrimination", "harassment")

run_index <- function(d, items) {
  d$idx <- anderson_index(d, items)
  d <- d[!is.na(d$idx) & !is.na(d$Z), ]
  m <- tryCatch(feols(idx ~ Z | city_f, data = d, weights = ~w, cluster = ~brgy_f),
                error = function(e) NULL)
  if (is.null(m)) return(NA_real_)
  unname(coef(m)["Z"])
}

sA <- sv[sv$akb, ]
sU <- sv[!sv$akb, ]
emit("itt_poverty_index_akbayan_tableC3", tryCatch(run_index(sA, pov_items), error = function(e) NA))
emit("itt_poverty_index_umalabka_tableC3", tryCatch(run_index(sU, pov_items), error = function(e) NA))
emit("itt_gender_index_akbayan_tableC4", tryCatch(run_index(sA, gen_items), error = function(e) NA))
emit("itt_gender_index_umalabka_tableC4", tryCatch(run_index(sU, gen_items), error = function(e) NA))

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}