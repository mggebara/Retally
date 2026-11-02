suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) return(invisible(NULL))
  cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
}

unlab <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x, levels = "default")
  x
}

to01 <- function(x) {
  if (inherits(x, "haven_labelled")) {
    xv <- as.numeric(unclass(x))
    u <- sort(unique(xv[!is.na(xv)]))
    if (all(u %in% c(0, 1))) return(xv)
    x <- haven::as_factor(x)
  }
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) {
    u <- sort(unique(x[!is.na(x)]))
    if (all(u %in% c(0, 1))) return(as.numeric(x))
    if (all(u %in% c(0, 100))) return(x / 100)
    if (all(u %in% c(1, 2))) return(ifelse(is.na(x), NA, as.numeric(x == 1)))
    return(as.numeric(x > 0))
  }
  s <- tolower(trimws(as.character(x)))
  sn <- suppressWarnings(as.numeric(s))
  if (all(is.na(s) | !is.na(sn))) return(to01(sn))
  out <- rep(NA_real_, length(s))
  neg <- grepl("control|^no|not|non|false|did ?n|^n$", s)
  pos <- grepl("treat|^yes|true|attend|voted|^y$|^1$", s) & !neg
  out[pos] <- 1
  out[neg] <- 0
  out[is.na(s) | s == "" | s == "na"] <- NA
  out
}

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.numeric(unclass(x)))
  if (is.factor(x)) {
    sn <- suppressWarnings(as.numeric(as.character(x)))
    if (sum(!is.na(sn)) > 0) return(sn)
    return(as.numeric(x))
  }
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  as.numeric(x)
}

norm <- function(s) gsub("[^a-z0-9]", "", tolower(as.character(unlab(s))))

# ---------------- Barangay level (Table 1) ----------------
d <- as.data.frame(data.all)
d$Z <- to01(d$assignment)
d$cityf <- factor(as.character(unlab(d$city)))
d$turn <- to_num(d$turnout.party)
if (max(d$turn, na.rm = TRUE) <= 1.5) d$turn <- d$turn * 100

sa <- to_num(d$share.akbayan); su <- to_num(d$share.umalabka); st <- to_num(d$share.treated)
akb_flag <- NULL
pt <- unlab(d$partytreat)
if (is.factor(pt) || is.character(pt)) {
  ptc <- tolower(as.character(pt))
  if (any(grepl("akb", ptc))) akb_flag <- grepl("akb", ptc)
}
if (is.null(akb_flag)) {
  akb_flag <- !is.na(st) & !is.na(sa) & abs(st - sa) < 1e-9
  if (sum(akb_flag) == 0 || sum(akb_flag) == nrow(d)) akb_flag <- to_num(pt) == 1
}
sc <- if (max(sa, na.rm = TRUE) < 1) 100 else 1
d$sa <- sa * sc; d$su <- su * sc; d$st <- st * sc
d$akb <- akb_flag

tryCatch({
  m1 <- feols(turn ~ Z | cityf, data = d)
  emit("itt_turnout_barangay_table1_col1", coef(m1)["Z"])
  emit("n_obs_barangay_table1_cols1_2", nobs(m1))
}, error = function(e) message("m1: ", conditionMessage(e)))
tryCatch({
  m2 <- feols(st ~ Z | cityf, data = d)
  emit("itt_vote_overall_barangay_table1_col2", coef(m2)["Z"])
}, error = function(e) message("m2: ", conditionMessage(e)))
tryCatch({
  m3 <- feols(sa ~ Z | cityf, data = d[d$akb, ])
  emit("itt_vote_akbayan_barangay_table1_col3", coef(m3)["Z"])
  emit("n_obs_barangay_akbayan_table1_col3", nobs(m3))
}, error = function(e) message("m3: ", conditionMessage(e)))
tryCatch({
  m4 <- feols(su ~ Z | cityf, data = d[!d$akb, ])
  emit("itt_vote_umalabka_barangay_table1_col4", coef(m4)["Z"])
  emit("n_obs_barangay_umalabka_table1_col4", nobs(m4))
}, error = function(e) message("m4: ", conditionMessage(e)))

# ---------------- Individual level ----------------
s <- as.data.frame(survey_raw)
s$cityc <- as.character(unlab(s$city))
excl <- grepl("imus|pateros|santa ?maria|sta\\.? ?maria", tolower(s$cityc))
s <- s[!excl, ]
s$cityf <- factor(s$cityc)
s$Z <- to01(s$assignment)
s$bkey <- norm(s$barangay)

# party of municipality
s$akb <- NA
if ("assign.akbayan" %in% names(s)) {
  aa <- to01(s$assign.akbayan)
  akb_cities <- unique(s$cityc[!is.na(aa) & aa == 1])
  au <- if ("assign.umalabka" %in% names(s)) to01(s$assign.umalabka) else rep(NA, nrow(s))
  uma_cities <- unique(s$cityc[!is.na(au) & au == 1])
  if (length(akb_cities) > 0) s$akb <- s$cityc %in% akb_cities
}
if (all(is.na(s$akb)) || sum(s$akb, na.rm = TRUE) == 0) {
  pts <- tolower(as.character(unlab(s$partytreat)))
  if (any(grepl("akb", pts))) s$akb <- grepl("akb", pts) else s$akb <- to_num(s$partytreat) == 1
}

# attendance weights
s$att <- to01(s$attendance)
s$w <- 1
tryCatch({
  d$bkey <- norm(d$barangay)
  ap <- to_num(d$att.prop)
  if (max(ap, na.rm = TRUE) > 1) ap <- ap / 100
  apmap <- setNames(ap, d$bkey)
  for (b in unique(s$bkey[!is.na(s$Z) & s$Z == 1])) {
    idx <- which(s$bkey == b)
    pa <- apmap[b]
    if (is.na(pa)) next
    ps <- mean(s$att[idx], na.rm = TRUE)
    if (is.na(ps) || ps <= 0 || ps >= 1) next
    wv <- ifelse(is.na(s$att[idx]), 1, ifelse(s$att[idx] == 1, pa / ps, (1 - pa) / (1 - ps)))
    s$w[idx] <- wv
  }
}, error = function(e) message("weights: ", conditionMessage(e)))

# unweighted vote outcomes (Table F.1)
s$turnpl <- if ("turnout_pl" %in% names(s)) to01(s$turnout_pl) else NA
s$vote01 <- to01(s$vote) * 100
s$voteakb <- to01(s$vote.akbayan) * 100
vs <- s
if (sum(vs$turnpl == 1, na.rm = TRUE) > 50) vs <- vs[!is.na(vs$turnpl) & vs$turnpl == 1, ]

tryCatch({
  mv <- feols(vote01 ~ Z | cityf, data = vs, cluster = ~barangay)
  emit("itt_vote_overall_unweighted_tableF1_col2", coef(mv)["Z"])
}, error = function(e) message("mv: ", conditionMessage(e)))
tryCatch({
  mva <- feols(voteakb ~ Z | cityf, data = vs[vs$akb %in% TRUE, ], cluster = ~barangay)
  emit("itt_vote_akbayan_unweighted_tableF1_col3", coef(mva)["Z"])
}, error = function(e) message("mva: ", conditionMessage(e)))

# ---- Attitude items: clean non-substantive codes and orient (higher = more agreement)
bad_pat <- "know|refus|no answer|n/a|^na$|not appl|^dk|missing|no opinion|no response|undecided|can.?t say|cannot say"
orient_rev <- function(lo_lab, hi_lab) {
  lo_lab <- tolower(lo_lab); hi_lab <- tolower(hi_lab)
  (grepl("agree", lo_lab) && !grepl("disagree", lo_lab) && grepl("disagree", hi_lab))
}
clean_item <- function(x) {
  if (inherits(x, "haven_labelled")) {
    v <- as.numeric(unclass(x))
    labs <- attr(x, "labels")
    if (!is.null(labs) && length(labs) > 0) {
      lab_names <- names(labs)
      bad <- as.numeric(labs[grepl(bad_pat, tolower(lab_names))])
      v[v %in% bad] <- NA
      good <- labs[!(as.numeric(labs) %in% bad)]
      if (length(good) >= 2) {
        gv <- as.numeric(good)
        if (orient_rev(names(good)[which.min(gv)], names(good)[which.max(gv)])) {
          v <- max(gv) + min(gv) - v
        }
      }
    }
    x <- v
  } else if (is.factor(x) || is.character(x)) {
    xc <- as.character(x)
    sn <- suppressWarnings(as.numeric(xc))
    if (sum(!is.na(sn)) > 0 && all(is.na(xc) | !is.na(sn) | grepl(bad_pat, tolower(xc)))) {
      x <- sn
    } else {
      lev <- if (is.factor(x)) levels(x) else sort(unique(xc[!is.na(xc)]))
      lev <- lev[!grepl(bad_pat, tolower(lev))]
      v <- match(xc, lev)
      v <- as.numeric(v)
      if (length(lev) >= 2 && orient_rev(lev[1], lev[length(lev)])) v <- length(lev) + 1 - v
      return(v)
    }
  }
  v <- as.numeric(x)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) > 0) {
    core <- u[u >= 0 & u <= 7]
    if ((max(u) >= 8 || min(u) < 0) && length(core) >= 2 && max(core) <= 5) {
      v[v > 5 | v < 0] <- NA
    }
  }
  v
}

# Anderson (2008) summary index
anderson <- function(df, items) {
  ctrl <- !is.na(df$Z) & df$Z == 0
  X <- sapply(items, function(v) clean_item(df[[v]]))
  X <- as.matrix(X)
  Zm <- X
  for (j in seq_len(ncol(X))) {
    mu <- mean(X[ctrl, j], na.rm = TRUE); sdv <- sd(X[ctrl, j], na.rm = TRUE)
    Zm[, j] <- (X[, j] - mu) / sdv
  }
  Sig <- cov(Zm, use = "pairwise.complete.obs")
  inv <- tryCatch(solve(Sig), error = function(e) MASS::ginv(Sig))
  wts <- rowSums(inv)
  idx <- apply(Zm, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * r[ok]) / sum(wts[ok])
  })
  mu <- mean(idx[ctrl], na.rm = TRUE); sdv <- sd(idx[ctrl], na.rm = TRUE)
  (idx - mu) / sdv
}

pov_items <- intersect(c("poverty", "gap", "cct", "corruption"), names(s))
gen_items <- intersect(c("femhouse", "femsenate", "femrep", "fempol", "equality", "discrimination", "harassment"), names(s))
extra_fem <- grep("^fem(house|senate|rep|pol|cong|lgu|mayor|gov|council|leader)", names(s), value = TRUE)
gen_items <- unique(c(gen_items, extra_fem))

run_index <- function(items, sub, name) {
  tryCatch({
    df <- s[sub, ]
    df$idx <- anderson(df, items)
    m <- feols(idx ~ Z | cityf, data = df, weights = ~w, cluster = ~barangay)
    emit(name, coef(m)["Z"])
  }, error = function(e) message(name, ": ", conditionMessage(e)))
}
run_index(pov_items, s$akb %in% TRUE, "itt_poverty_index_akbayan_tableC3")
run_index(pov_items, s$akb %in% FALSE, "itt_poverty_index_umalabka_tableC3")
run_index(gen_items, s$akb %in% TRUE, "itt_gender_index_akbayan_tableC4")
run_index(gen_items, s$akb %in% FALSE, "itt_gender_index_umalabka_tableC4")