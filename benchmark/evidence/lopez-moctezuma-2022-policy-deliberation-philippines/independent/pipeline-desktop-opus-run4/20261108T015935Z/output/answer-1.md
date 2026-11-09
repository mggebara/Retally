suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

num <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.numeric(unclass(x)))
  if (is.factor(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (all(is.na(v[!is.na(x)]))) v <- as.numeric(x)
    return(v)
  }
  if (is.character(x)) {
    v <- suppressWarnings(as.numeric(x))
    if (all(is.na(v[!is.na(x)]))) {
      lx <- tolower(trimws(x))
      v <- ifelse(is.na(x), NA,
                  ifelse(grepl("^(yes|treat|assigned|true|y)", lx), 1,
                         ifelse(grepl("^(no|control|false|n)", lx), 0, NA)))
    }
    return(v)
  }
  as.numeric(x)
}
to01 <- function(x) {
  v <- num(x)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) == 2 && !all(u == c(0, 1))) v <- as.numeric(v == max(u))
  v
}
norm <- function(x) tolower(trimws(as.character(x)))
emit <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NA })

# ---------------- Identify Akbayan municipalities ----------------
sv <- as.data.frame(survey_raw)
sv$city_n <- norm(sv$city)
akb_cities <- character(0)
if ("assign.akbayan" %in% names(sv)) {
  aa <- to01(sv$assign.akbayan)
  akb_cities <- unique(sv$city_n[!is.na(aa) & aa == 1])
}
if (length(akb_cities) == 0 && "partytreat" %in% names(sv)) {
  pt <- sv$partytreat
  if (is.character(pt) || is.factor(pt)) akb_cities <- unique(sv$city_n[grepl("akb", norm(pt))])
}

da <- as.data.frame(data.all)
da$city_n <- norm(da$city)
da$Z <- to01(da$assignment)
da$is_akb <- NA
pt <- da$partytreat
if (is.character(pt) || is.factor(pt) || inherits(pt, "haven_labelled")) {
  lab <- if (inherits(pt, "haven_labelled")) as.character(haven::as_factor(pt)) else norm(pt)
  if (any(grepl("akb", tolower(lab)))) da$is_akb <- grepl("akb", tolower(lab))
}
if (all(is.na(da$is_akb)) && length(akb_cities) > 0) da$is_akb <- da$city_n %in% akb_cities
if (all(is.na(da$is_akb))) da$is_akb <- num(da$partytreat) == 1
if (sum(da$is_akb) != 18 && length(akb_cities) > 0 && sum(da$city_n %in% akb_cities) == 18)
  da$is_akb <- da$city_n %in% akb_cities

pct <- function(x) { x <- num(x); if (max(x, na.rm = TRUE) <= 1.0001) x * 100 else x }
da$turnout <- pct(da$turnout.party)
da$sh_akb <- pct(da$share.akbayan)
da$sh_uma <- pct(da$share.umalabka)
da$vote_overall <- ifelse(da$is_akb, da$sh_akb, da$sh_uma)

m1 <- feols(turnout ~ Z | city, data = da)
m2 <- feols(vote_overall ~ Z | city, data = da)
m3 <- feols(sh_akb ~ Z | city, data = da[da$is_akb, ])
m4 <- feols(sh_uma ~ Z | city, data = da[!da$is_akb, ])

emit("itt_turnout_barangay_table1_col1", coef(m1)["Z"])
emit("itt_vote_overall_barangay_table1_col2", coef(m2)["Z"])
emit("itt_vote_akbayan_barangay_table1_col3", coef(m3)["Z"])
emit("itt_vote_umalabka_barangay_table1_col4", coef(m4)["Z"])
emit("n_obs_barangay_table1_cols1_2", nobs(m2))
emit("n_obs_barangay_akbayan_table1_col3", nobs(m3))
emit("n_obs_barangay_umalabka_table1_col4", nobs(m4))

# ---------------- Individual level ----------------
sv <- sv[!grepl("imus|pateros|santa maria|sta\\.? maria", sv$city_n), ]
sv$Z <- to01(sv$assignment)
sv$turn <- to01(sv$turnout_pl)
sv <- sv[!is.na(sv$turn), ]
sv$is_akb <- sv$city_n %in% akb_cities
sv$brgy_n <- norm(sv$barangay)
sv$att <- to01(sv$attendance)

# attendance weights: match survey attendee share to actual attendee share (sign-in sheets)
da$brgy_n <- norm(da$barangay)
ap <- num(da$att.prop)
if (max(ap, na.rm = TRUE) > 1) ap <- ap / 100
actual <- setNames(ap, da$brgy_n)
sv$w <- 1
for (b in unique(sv$brgy_n[sv$Z == 1])) {
  idx <- which(sv$brgy_n == b)
  a <- sv$att[idx]
  ps <- mean(a == 1, na.rm = TRUE)
  pa <- if (b %in% names(actual)) actual[[b]] else NA
  if (!is.na(pa) && !is.na(ps) && ps > 0 && ps < 1) {
    sv$w[idx] <- ifelse(!is.na(a) & a == 1, pa / ps, (1 - pa) / (1 - ps))
  }
}

# unweighted vote ITT (SI Table F.1)
vt <- sv[sv$turn == 1, ]
vt$vote_party <- ifelse(vt$is_akb, to01(vt$vote.akbayan), to01(vt$vote.umalabka))
if ("vote" %in% names(vt)) {
  vv <- to01(vt$vote)
  if (sum(!is.na(vv)) > 0) vt$vote_party <- ifelse(is.na(vv), vt$vote_party, vv)
}
vt$vote_party <- 100 * vt$vote_party
vt$vote_akb <- 100 * to01(vt$vote.akbayan)
f1 <- safe(coef(feols(vote_party ~ Z | city, data = vt, cluster = ~barangay))["Z"])
f3 <- safe(coef(feols(vote_akb ~ Z | city, data = vt[vt$is_akb, ], cluster = ~barangay))["Z"])

# Anderson summary index
anderson <- function(d, items) {
  Zm <- sapply(items, function(v) {
    x <- num(d[[v]])
    ctl <- d$Z == 0
    (x - mean(x[ctl], na.rm = TRUE)) / sd(x[ctl], na.rm = TRUE)
  })
  S <- cov(Zm, use = "pairwise.complete.obs")
  wts <- rowSums(solve(S))
  idx <- apply(Zm, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA)
    sum(wts[ok] * r[ok]) / sum(wts[ok])
  })
  ctl <- d$Z == 0
  (idx - mean(idx[ctl], na.rm = TRUE)) / sd(idx[ctl], na.rm = TRUE)
}
pov_items <- intersect(c("poverty", "gap", "cct", "corruption"), names(sv))
gen_items <- intersect(c("femhouse", "fempol", "equality", "discrimination", "harassment"), names(sv))
itt_index <- function(d, items) {
  d$idx <- anderson(d, items)
  coef(feols(idx ~ Z | city, data = d, weights = ~w, cluster = ~barangay))["Z"]
}
sa <- sv[sv$is_akb, ]; su <- sv[!sv$is_akb, ]
p_a <- safe(itt_index(sa, pov_items))
p_u <- safe(itt_index(su, pov_items))
g_a <- safe(itt_index(sa, gen_items))
g_u <- safe(itt_index(su, gen_items))

emit("itt_poverty_index_akbayan_tableC3", p_a)
emit("itt_poverty_index_umalabka_tableC3", p_u)
emit("itt_gender_index_akbayan_tableC4", g_a)
emit("itt_gender_index_umalabka_tableC4", g_u)
emit("itt_vote_overall_unweighted_tableF1_col2", f1)
emit("itt_vote_akbayan_unweighted_tableF1_col3", f3)
