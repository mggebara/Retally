suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

to_num <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    xl <- tolower(trimws(x))
    num <- suppressWarnings(as.numeric(xl))
    if (sum(!is.na(num)) >= sum(!is.na(xl) & xl != "") * 0.9) return(num)
    out <- rep(NA_real_, length(xl))
    out[grepl("^(yes|treat|treated|assigned|1|true)", xl)] <- 1
    out[grepl("^(no|control|not|0|false)", xl)] <- 0
    return(out)
  }
  as.numeric(unclass(x))
}
to01 <- function(x) {
  v <- to_num(x)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) == 2 && !all(u == c(0, 1))) v <- as.numeric(v == max(u))
  v
}
norm_name <- function(x) gsub("[^a-z0-9]", "", tolower(as.character(x)))
pct <- function(x) { x <- to_num(x); if (max(x, na.rm = TRUE) <= 1.0001) x * 100 else x }

emit <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

## ---------------- Barangay level (Table 1) ----------------
d <- as.data.frame(data.all)
d$Z <- to01(d$assignment)
d$city <- as.character(d$city)
d$turnout <- pct(d$turnout.party)
d$share_t <- pct(d$share.treated)
d$share_a <- pct(d$share.akbayan)
d$share_u <- pct(d$share.umalabka)

# Identify Akbayan municipalities
pt <- d$partytreat
akb <- NULL
if (is.character(pt) || is.factor(pt)) {
  ptl <- tolower(as.character(pt))
  if (any(grepl("akb", ptl))) akb <- grepl("akb", ptl)
}
if (is.null(akb)) {
  akb <- abs(d$share_t - d$share_a) < 1e-6 & abs(d$share_t - d$share_u) > 1e-6
}
d$akb <- akb

m1 <- feols(turnout ~ Z | city, data = d)
m2 <- feols(share_t ~ Z | city, data = d)
m3 <- feols(share_a ~ Z | city, data = d[d$akb, ])
m4 <- feols(share_u ~ Z | city, data = d[!d$akb, ])

## ---------------- Individual level ----------------
s <- as.data.frame(survey_raw)
s$city_c <- as.character(if (is.factor(s$city)) as.character(s$city) else haven::as_factor(s$city))
if (all(is.na(s$city_c))) s$city_c <- as.character(s$city)
s$brgy_c <- as.character(if (is.factor(s$barangay)) as.character(s$barangay) else haven::as_factor(s$barangay))
excl <- grepl("imus|pateros|santamaria|stamaria", norm_name(s$city_c))
s <- s[!excl, ]
s$Z <- to01(s$assignment)

# Akbayan municipality indicator
aa <- to01(s$assign.akbayan)
au <- to01(s$assign.umalabka)
akb_cities <- unique(s$city_c[!is.na(aa) & aa == 1])
umk_cities <- unique(s$city_c[!is.na(au) & au == 1])
s$akb <- s$city_c %in% akb_cities
if (length(akb_cities) == 0) {
  ptl <- tolower(as.character(haven::as_factor(s$partytreat)))
  s$akb <- grepl("akb", ptl)
}

# Outcomes
va <- to01(s$vote.akbayan); vu <- to01(s$vote.umalabka)
s$vote_tp <- ifelse(s$akb, va, vu)
if (all(is.na(s$vote_tp))) s$vote_tp <- to01(s$vote)
tpl <- to01(s$turnout_pl)
tall <- to01(s$turnout_all)
s$turn <- if (sum(!is.na(tpl)) > 500) tpl else tall

# Unweighted vote among those who turned out (Table F.1)
sv <- s[!is.na(s$turn) & s$turn == 1 & !is.na(s$vote_tp), ]
if (nrow(sv) < 100) sv <- s[!is.na(s$vote_tp), ]
sv$y <- 100 * sv$vote_tp
f2 <- feols(y ~ Z | city_c, data = sv, cluster = ~brgy_c)
f3 <- feols(y ~ Z | city_c, data = sv[sv$akb, ], cluster = ~brgy_c)

## ---------------- Attendance IPW weights ----------------
att <- to01(s$attendance)
att[is.na(att)] <- 0
s$att <- att
d$key <- norm_name(d$barangay)
attp <- to_num(d$att.prop)
if (max(attp, na.rm = TRUE) > 1.0001) attp <- attp / 100
s$key <- norm_name(s$brgy_c)
s$w <- 1
for (b in unique(s$key[s$Z == 1])) {
  idx <- which(s$key == b)
  p <- attp[match(b, d$key)]
  if (is.na(p)) {
    # fuzzy match fallback
    j <- which(sapply(d$key, function(k) grepl(k, b) || grepl(b, k)))
    if (length(j) >= 1) p <- attp[j[1]]
  }
  if (is.na(p)) next
  sh <- mean(s$att[idx])
  if (sh > 0 && sh < 1) {
    s$w[idx] <- ifelse(s$att[idx] == 1, p / sh, (1 - p) / (1 - sh))
  }
}

## ---------------- Anderson (2008) indices ----------------
clean_item <- function(x) {
  v <- to_num(x)
  v[v %in% c(88, 98, 99, 888, 999, -9, -99, -1)] <- NA
  q <- quantile(v, 0.9, na.rm = TRUE)
  if (!is.na(q) && q <= 7) v[v > 7] <- NA
  v
}
anderson <- function(df, items, ctrl) {
  Zm <- sapply(items, function(it) {
    v <- clean_item(df[[it]])
    mu <- mean(v[ctrl], na.rm = TRUE); sdv <- sd(v[ctrl], na.rm = TRUE)
    (v - mu) / sdv
  })
  S <- cov(Zm, use = "pairwise.complete.obs")
  Si <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wts <- rowSums(Si)
  idx <- apply(Zm, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * r[ok]) / sum(wts[ok])
  })
  mu <- mean(idx[ctrl], na.rm = TRUE); sdv <- sd(idx[ctrl], na.rm = TRUE)
  (idx - mu) / sdv
}
pov_items <- intersect(c("poverty", "gap", "cct", "corruption"), names(s))
gen_items <- intersect(c("femhouse", "fempol", "equality", "discrimination", "harassment"), names(s))

idx_itt <- function(sub, items) {
  ctrl <- !is.na(sub$Z) & sub$Z == 0
  sub$index <- anderson(sub, items, ctrl)
  m <- feols(index ~ Z | city_c, data = sub, weights = ~w, cluster = ~brgy_c)
  coef(m)["Z"]
}
sa <- s[s$akb, ]; su <- s[!s$akb, ]
pa <- idx_itt(sa, pov_items)
pu <- idx_itt(su, pov_items)
ga <- idx_itt(sa, gen_items)
gu <- idx_itt(su, gen_items)

## ---------------- Output ----------------
emit("itt_turnout_barangay_table1_col1", coef(m1)["Z"])
emit("itt_vote_overall_barangay_table1_col2", coef(m2)["Z"])
emit("itt_vote_akbayan_barangay_table1_col3", coef(m3)["Z"])
emit("itt_vote_umalabka_barangay_table1_col4", coef(m4)["Z"])
emit("n_obs_barangay_table1_cols1_2", nobs(m2))
emit("n_obs_barangay_akbayan_table1_col3", nobs(m3))
emit("n_obs_barangay_umalabka_table1_col4", nobs(m4))
emit("itt_poverty_index_akbayan_tableC3", pa)
emit("itt_poverty_index_umalabka_tableC3", pu)
emit("itt_gender_index_akbayan_tableC4", ga)
emit("itt_gender_index_umalabka_tableC4", gu)
emit("itt_vote_overall_unweighted_tableF1_col2", coef(f2)["Z"])
emit("itt_vote_akbayan_unweighted_tableF1_col3", coef(f3)["Z"])
