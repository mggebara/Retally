suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

res <- list()
put <- function(name, expr) {
  v <- tryCatch(expr, error = function(e) { message(name, ": ", conditionMessage(e)); NA_real_ })
  res[[name]] <<- as.numeric(v)[1]
}

# ---------- helpers ----------
to01 <- function(x, yes_pattern = "^(1|yes|y|voted|treat|treatment|treated|assigned|true)$") {
  if (is.logical(x)) return(as.numeric(x))
  if (inherits(x, "haven_labelled")) x <- as.numeric(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    xl <- tolower(trimws(x))
    num <- suppressWarnings(as.numeric(xl))
    if (all(is.na(xl) | xl == "" | !is.na(num))) {
      x <- num
    } else {
      out <- rep(NA_real_, length(xl))
      out[grepl(yes_pattern, xl) | grepl("^yes|^treat|^voted", xl)] <- 1
      out[grepl("^(0|no|n|control|false|did not|didn)", xl)] <- 0
      return(out)
    }
  }
  x <- as.numeric(x)
  u <- sort(unique(x[!is.na(x)]))
  if (all(u %in% c(0, 1))) return(x)
  if (all(u %in% c(1, 2))) return(ifelse(is.na(x), NA, ifelse(x == 1, 1, 0)))
  # anything else: 1 = yes, 0 = no, other codes missing
  ifelse(x %in% c(0, 1), x, NA)
}
num <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.numeric(x))
  if (is.factor(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (mean(is.na(v[!is.na(x)])) > 0.5) v <- as.numeric(x)
    return(v)
  }
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  as.numeric(x)
}
pct <- function(x) { x <- num(x); if (max(x, na.rm = TRUE) <= 1.0001) x * 100 else x }
normname <- function(x) tolower(gsub("[^a-z0-9]", "", tolower(as.character(x))))

# ---------- Barangay level (Table 1) ----------
da <- data.all
da$Z <- to01(da$assignment)
da$cityf <- as.character(da$city)

turn <- num(da$turnout.party)
if (max(turn, na.rm = TRUE) > 100) {
  turn <- num(da$vote.num.party) / num(da$reg.num) * 100
} else if (max(turn, na.rm = TRUE) <= 1.0001) {
  turn <- turn * 100
}
da$turnout_pct <- turn
da$share_tr <- pct(da$share.treated)
sa <- pct(da$share.akbayan); su <- pct(da$share.umalabka)

# party of each barangay: from partytreat if informative, else from share.treated matching
pt <- tolower(as.character(da$partytreat))
if (any(grepl("akb", pt))) {
  da$akb <- grepl("akb", pt)
} else {
  da$akb <- abs(da$share_tr - sa) < abs(da$share_tr - su)
}
city_party <- da %>% group_by(cityf) %>% summarise(akb = mean(akb) > 0.5, .groups = "drop")
da <- da %>% select(-akb) %>% left_join(city_party, by = "cityf")

m1 <- feols(turnout_pct ~ Z | cityf, data = da)
m2 <- feols(share_tr ~ Z | cityf, data = da)
m3 <- feols(share_tr ~ Z | cityf, data = da[da$akb, ])
m4 <- feols(share_tr ~ Z | cityf, data = da[!da$akb, ])
put("itt_turnout_barangay_table1_col1", coef(m1)["Z"])
put("itt_vote_overall_barangay_table1_col2", coef(m2)["Z"])
put("itt_vote_akbayan_barangay_table1_col3", coef(m3)["Z"])
put("itt_vote_umalabka_barangay_table1_col4", coef(m4)["Z"])
put("n_obs_barangay_table1_cols1_2", nobs(m2))
put("n_obs_barangay_akbayan_table1_col3", nobs(m3))
put("n_obs_barangay_umalabka_table1_col4", nobs(m4))

# randomization inference (within-municipality permutation) for reference
ri_p <- function(d, y, B = 2000) {
  obs <- coef(feols(as.formula(paste(y, "~ Z | cityf")), data = d))["Z"]
  sims <- replicate(B, {
    dd <- d
    dd$Z <- ave(dd$Z, dd$cityf, FUN = function(z) sample(z))
    coef(feols(as.formula(paste(y, "~ Z | cityf")), data = dd))["Z"]
  })
  mean(abs(sims) >= abs(obs))
}
invisible(tryCatch(ri_p(da, "share_tr", 500), error = function(e) NA))

# ---------- Individual level ----------
sv <- as.data.frame(survey_raw)
sv$cityf <- as.character(sv$city)
sv$brgy <- as.character(sv$barangay)
sv$Z <- to01(sv$assignment)
sv$turn <- to01(sv$turnout_all)
if (all(is.na(sv$turn))) sv$turn <- to01(sv$turnout_pl)

# party of municipality
ptS <- tolower(as.character(sv$partytreat))
if (any(grepl("akb", ptS))) {
  sv$akb <- grepl("akb", ptS)
} else {
  aa <- to01(sv$assign.akbayan)
  akb_cities <- unique(sv$cityf[!is.na(aa) & aa == 1])
  if (length(akb_cities) > 0) {
    sv$akb <- sv$cityf %in% akb_cities
  } else {
    cp <- setNames(city_party$akb, normname(city_party$cityf))
    sv$akb <- as.logical(cp[normname(sv$cityf)])
  }
}

# exclude municipalities without respondents in both treatment and control barangays
both <- sv %>% filter(!is.na(Z)) %>% group_by(cityf) %>%
  summarise(ok = any(Z == 1) & any(Z == 0), .groups = "drop")
okc <- both$cityf[both$ok]
sv <- sv[sv$cityf %in% okc & !grepl("imus|pateros|santa ?maria|sta\\.? ?maria", tolower(sv$cityf)), ]
# drop invalid turnout answers
sv <- sv[!is.na(sv$turn) & !is.na(sv$Z), ]

# vote for the treating party list
v <- to01(sv$vote)
va <- to01(sv$vote.akbayan); vu <- to01(sv$vote.umalabka)
vt <- ifelse(sv$akb, va, vu)
if (all(is.na(v))) v <- vt
sv$vote_tr <- v * 100
sv$vote_akb <- va * 100

# attendance-oversampling weights
sv$att <- to01(sv$attendance)
sv$w <- 1
tryCatch({
  ap <- num(da$att.prop)
  if (max(ap, na.rm = TRUE) > 1.0001) ap <- ap / 100
  apmap <- setNames(ap, normname(da$barangay))
  bstats <- sv %>% filter(Z == 1) %>% group_by(brgy) %>%
    summarise(p_s = mean(att == 1, na.rm = TRUE), .groups = "drop")
  bstats$p_t <- as.numeric(apmap[normname(bstats$brgy)])
  for (i in seq_len(nrow(bstats))) {
    b <- bstats$brgy[i]; ps <- bstats$p_s[i]; ptv <- bstats$p_t[i]
    if (is.na(ps) || is.na(ptv) || ps <= 0 || ps >= 1) next
    idx <- sv$brgy == b & sv$Z == 1
    a <- sv$att[idx]
    sv$w[idx] <- ifelse(!is.na(a) & a == 1, ptv / ps, (1 - ptv) / (1 - ps))
  }
}, error = function(e) message("weights: ", conditionMessage(e)))
sv$w[is.na(sv$w) | sv$w <= 0] <- 1

# Unweighted individual vote ITT (Table F.1)
voters <- sv[sv$turn == 1, ]
mf2 <- feols(vote_tr ~ Z | cityf, data = voters[!is.na(voters$vote_tr), ], cluster = ~brgy)
put("itt_vote_overall_unweighted_tableF1_col2", coef(mf2)["Z"])
vak <- voters[voters$akb & !is.na(voters$vote_akb), ]
mf3 <- feols(vote_akb ~ Z | cityf, data = vak, cluster = ~brgy)
put("itt_vote_akbayan_unweighted_tableF1_col3", coef(mf3)["Z"])

# ---------- Anderson (2008) summary indices ----------
anderson_index <- function(d, items) {
  X <- sapply(items, function(it) num(d[[it]]))
  X <- as.matrix(X)
  ctrl <- d$Z == 0
  for (k in seq_len(ncol(X))) {
    mu <- mean(X[ctrl, k], na.rm = TRUE); s <- sd(X[ctrl, k], na.rm = TRUE)
    X[, k] <- (X[, k] - mu) / s
  }
  S <- cov(X, use = "pairwise.complete.obs")
  Si <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wts <- rowSums(Si)
  idx <- apply(X, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * r[ok]) / sum(wts[ok])
  })
  mu <- mean(idx[ctrl], na.rm = TRUE); s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - mu) / s
}
pov_items <- c("poverty", "gap", "cct", "corruption")
gen_items <- c("femhouse", "fempol", "equality", "discrimination", "harassment")

run_index <- function(items, akb_flag) {
  d <- sv[sv$akb == akb_flag, ]
  d$idx <- anderson_index(d, items)
  d <- d[!is.na(d$idx), ]
  m <- feols(idx ~ Z | cityf, data = d, weights = ~w, cluster = ~brgy)
  coef(m)["Z"]
}
put("itt_poverty_index_akbayan_tableC3", run_index(pov_items, TRUE))
put("itt_poverty_index_umalabka_tableC3", run_index(pov_items, FALSE))
put("itt_gender_index_akbayan_tableC4", run_index(gen_items, TRUE))
put("itt_gender_index_umalabka_tableC4", run_index(gen_items, FALSE))

# ---------- output ----------
nm <- c("itt_turnout_barangay_table1_col1", "itt_vote_overall_barangay_table1_col2",
        "itt_vote_akbayan_barangay_table1_col3", "itt_vote_umalabka_barangay_table1_col4",
        "n_obs_barangay_table1_cols1_2", "n_obs_barangay_akbayan_table1_col3",
        "n_obs_barangay_umalabka_table1_col4", "itt_poverty_index_akbayan_tableC3",
        "itt_poverty_index_umalabka_tableC3", "itt_gender_index_akbayan_tableC4",
        "itt_gender_index_umalabka_tableC4", "itt_vote_overall_unweighted_tableF1_col2",
        "itt_vote_akbayan_unweighted_tableF1_col3")
for (n in nm) {
  v <- if (is.null(res[[n]])) NA_real_ else res[[n]]
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 8)))
}
