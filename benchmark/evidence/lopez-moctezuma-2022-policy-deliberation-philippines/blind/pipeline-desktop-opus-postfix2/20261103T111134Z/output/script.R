suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

unlab <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as.vector(unclass(x))
  attributes(x) <- attributes(x)[intersect(names(attributes(x)), c("names", "levels", "class"))]
  x
}
to01 <- function(x) {
  x <- unlab(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.character(x)) {
    xl <- tolower(trimws(x))
    out <- rep(NA_real_, length(xl))
    out[xl %in% c("1", "yes", "y", "true", "treatment", "treated", "voted", "female", "assigned")] <- 1
    out[xl %in% c("0", "no", "n", "false", "control", "did not vote", "male", "not assigned")] <- 0
    num <- suppressWarnings(as.numeric(xl))
    idx <- is.na(out) & !is.na(num) & num %in% c(0, 1)
    out[idx] <- num[idx]
    return(out)
  }
  x <- as.numeric(x)
  x[!(x %in% c(0, 1))] <- NA
  x
}
tonum <- function(x) {
  x <- unlab(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}
normname <- function(x) gsub("[^a-z0-9]", "", tolower(as.character(unlab(x))))
pct <- function(x) { x <- tonum(x); if (max(x, na.rm = TRUE) <= 1.0001) x * 100 else x }

# ---------------- Barangay level (Table 1) ----------------
agg <- as.data.frame(data.all)
agg$city <- as.character(unlab(agg$city))
agg$barangay <- as.character(unlab(agg$barangay))
agg$Z <- to01(agg$assignment)
agg$turnout_pct <- pct(agg$turnout.party)
agg$share_tr <- pct(agg$share.treated)
agg$share_akb <- pct(agg$share.akbayan)
agg$share_uma <- pct(agg$share.umalabka)

pt <- tolower(as.character(unlab(agg$partytreat)))
if (any(grepl("akb", pt))) {
  agg$is_akb <- grepl("akb", pt)
} else {
  agg$is_akb <- abs(agg$share_tr - agg$share_akb) < 1e-6 &
    !(abs(agg$share_tr - agg$share_uma) < 1e-6)
  # make party constant within city
  cm <- tapply(agg$is_akb, agg$city, mean)
  agg$is_akb <- cm[agg$city] > 0.5
}

cat(sprintf("SAMPLE:barangay_all:loaded=%d\n", nrow(agg)))
m1 <- feols(turnout_pct ~ Z | city, data = agg)
m2 <- feols(share_tr ~ Z | city, data = agg)
cat(sprintf("SAMPLE:barangay_all:estimation=%d\n", nobs(m2)))

akb_agg <- agg[agg$is_akb, ]
uma_agg <- agg[!agg$is_akb, ]
cat(sprintf("SAMPLE:barangay_akbayan:loaded=%d\n", nrow(agg)))
cat(sprintf("SAMPLE:barangay_akbayan:akbayan_municipalities=%d\n", nrow(akb_agg)))
m3 <- feols(share_akb ~ Z | city, data = akb_agg)
cat(sprintf("SAMPLE:barangay_akbayan:estimation=%d\n", nobs(m3)))
cat(sprintf("SAMPLE:barangay_umalabka:loaded=%d\n", nrow(agg)))
cat(sprintf("SAMPLE:barangay_umalabka:umalabka_municipalities=%d\n", nrow(uma_agg)))
m4 <- feols(share_uma ~ Z | city, data = uma_agg)
cat(sprintf("SAMPLE:barangay_umalabka:estimation=%d\n", nobs(m4)))

# ---------------- Individual level ----------------
sv <- as.data.frame(survey_raw)
sv$city <- as.character(unlab(sv$city))
sv$barangay <- as.character(unlab(sv$barangay))
sv$Z <- to01(sv$assignment)
sv$Tr <- to01(sv$treatment)
sv$att <- to01(sv$attendance)
cat(sprintf("SAMPLE:survey:loaded=%d\n", nrow(sv)))

# drop municipalities without both treatment and control samples
city_both <- tapply(sv$Z, sv$city, function(z) length(unique(na.omit(z))) == 2)
excl_named <- normname(sv$city) %in% c("imus", "pateros", "santamaria", "stamaria")
keep_city <- city_both[sv$city] & !excl_named
keep_city[is.na(keep_city)] <- FALSE
sv <- sv[keep_city, ]
cat(sprintf("SAMPLE:survey:drop_municipalities_without_treatment_and_control=%d\n", nrow(sv)))

# party per city
aa <- to01(sv$assign.akbayan); au <- to01(sv$assign.umalabka)
ptv <- tolower(as.character(unlab(sv$partytreat)))
if (any(grepl("akb", ptv))) {
  sv$is_akb <- grepl("akb", ptv)
} else {
  ca <- tapply(aa, sv$city, function(v) max(v, na.rm = TRUE))
  cu <- tapply(au, sv$city, function(v) max(v, na.rm = TRUE))
  sv$is_akb <- ca[sv$city] == 1 & !(cu[sv$city] == 1)
  sv$is_akb[is.na(sv$is_akb)] <- FALSE
}

# attendance weights (IPW for oversampling of meeting attendees)
sv$w <- 1
agg$bkey <- normname(agg$barangay)
sv$bkey <- normname(sv$barangay)
attp <- tonum(agg$att.prop)
if (max(attp, na.rm = TRUE) > 1) attp <- attp / 100
names(attp) <- agg$bkey
for (b in unique(sv$bkey[sv$Tr %in% 1])) {
  idx <- which(sv$bkey == b)
  ps <- mean(sv$att[idx], na.rm = TRUE)
  pp <- attp[b]
  if (is.na(pp) || is.na(ps) || pp <= 0 || ps <= 0 || ps >= 1) next
  sv$w[idx[sv$att[idx] %in% 1]] <- pp / ps
  sv$w[idx[sv$att[idx] %in% 0]] <- (1 - pp) / (1 - ps)
}

# turnout validity
tvar <- if ("turnout_all" %in% names(sv)) "turnout_all" else "turnout_pl"
sv$turn <- to01(sv[[tvar]])
svt <- sv[!is.na(sv$turn), ]
cat(sprintf("SAMPLE:survey:drop_invalid_turnout=%d\n", nrow(svt)))

# vote outcomes (in percent) among those who turned out
vtr <- to01(sv$vote)
vak <- to01(sv$vote.akbayan)
vum <- to01(sv$vote.umalabka)
pooled <- ifelse(sv$is_akb, vak, vum)
if (sum(!is.na(vtr)) > 0.5 * sum(!is.na(pooled))) pooled <- ifelse(is.na(vtr), pooled, vtr)
sv$vote_tr <- 100 * pooled
sv$vote_ak <- 100 * vak
sv$vote_um <- 100 * vum

vs <- sv[!is.na(sv$turn) & sv$turn == 1, ]
cat(sprintf("SAMPLE:tableF1_vote_overall:loaded=%d\n", nrow(survey_raw)))
cat(sprintf("SAMPLE:tableF1_vote_overall:drop_municipalities_without_treatment_and_control=%d\n", nrow(sv)))
cat(sprintf("SAMPLE:tableF1_vote_overall:drop_invalid_turnout=%d\n", nrow(svt)))
cat(sprintf("SAMPLE:tableF1_vote_overall:turned_out=%d\n", nrow(vs)))
f2 <- feols(vote_tr ~ Z | city, data = vs, cluster = ~barangay)
cat(sprintf("SAMPLE:tableF1_vote_overall:estimation=%d\n", nobs(f2)))

vsa <- vs[vs$is_akb, ]
cat(sprintf("SAMPLE:tableF1_vote_akbayan:loaded=%d\n", nrow(survey_raw)))
cat(sprintf("SAMPLE:tableF1_vote_akbayan:drop_municipalities_without_treatment_and_control=%d\n", nrow(sv)))
cat(sprintf("SAMPLE:tableF1_vote_akbayan:drop_invalid_turnout=%d\n", nrow(svt)))
cat(sprintf("SAMPLE:tableF1_vote_akbayan:turned_out=%d\n", nrow(vs)))
cat(sprintf("SAMPLE:tableF1_vote_akbayan:akbayan_municipalities=%d\n", nrow(vsa)))
f3 <- feols(vote_ak ~ Z | city, data = vsa, cluster = ~barangay)
cat(sprintf("SAMPLE:tableF1_vote_akbayan:estimation=%d\n", nobs(f3)))

# ---------------- Attitude indices (Anderson 2008) ----------------
make_index <- function(d, items) {
  X <- sapply(items, function(v) tonum(d[[v]]))
  X <- as.matrix(X)
  ctrl <- d$Z %in% 0
  Zs <- X
  for (j in seq_len(ncol(X))) {
    mu <- mean(X[ctrl, j], na.rm = TRUE); s <- sd(X[ctrl, j], na.rm = TRUE)
    Zs[, j] <- (X[, j] - mu) / s
  }
  S <- cov(Zs, use = "pairwise.complete.obs")
  Wm <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wv <- rowSums(Wm)
  idx <- apply(Zs, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(wv[ok] * r[ok]) / sum(wv[ok])
  })
  mu <- mean(idx[ctrl], na.rm = TRUE); s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - mu) / s
}

pov_items <- c("poverty", "gap", "cct", "corruption")
gen_items <- c("femhouse", "fempol", "equality", "discrimination", "harassment")

run_index <- function(d, items, nm, party_lab) {
  d$idx <- make_index(d, items)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", nm, nrow(survey_raw)))
  cat(sprintf("SAMPLE:%s:drop_municipalities_without_treatment_and_control=%d\n", nm, nrow(sv)))
  cat(sprintf("SAMPLE:%s:%s_municipalities=%d\n", nm, party_lab, nrow(d)))
  m <- feols(idx ~ Z | city, data = d, weights = ~w, cluster = ~barangay)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, nobs(m)))
  unname(coef(m)["Z"])
}

sv_akb <- sv[sv$is_akb, ]
sv_uma <- sv[!sv$is_akb, ]
p_akb <- run_index(sv_akb, pov_items, "tableC3_poverty_akbayan", "akbayan")
p_uma <- run_index(sv_uma, pov_items, "tableC3_poverty_umalabka", "umalabka")
g_akb <- run_index(sv_akb, gen_items, "tableC4_gender_akbayan", "akbayan")
g_uma <- run_index(sv_uma, gen_items, "tableC4_gender_umalabka", "umalabka")

# ---------------- Results ----------------
cat(sprintf("RESULT:itt_turnout_barangay_table1_col1=%.6f\n", coef(m1)["Z"]))
cat(sprintf("RESULT:itt_vote_overall_barangay_table1_col2=%.6f\n", coef(m2)["Z"]))
cat(sprintf("RESULT:itt_vote_akbayan_barangay_table1_col3=%.6f\n", coef(m3)["Z"]))
cat(sprintf("RESULT:itt_vote_umalabka_barangay_table1_col4=%.6f\n", coef(m4)["Z"]))
cat(sprintf("RESULT:n_obs_barangay_table1_cols1_2=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_barangay_akbayan_table1_col3=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_barangay_umalabka_table1_col4=%d\n", nobs(m4)))
cat(sprintf("RESULT:itt_poverty_index_akbayan_tableC3=%.6f\n", p_akb))
cat(sprintf("RESULT:itt_poverty_index_umalabka_tableC3=%.6f\n", p_uma))
cat(sprintf("RESULT:itt_gender_index_akbayan_tableC4=%.6f\n", g_akb))
cat(sprintf("RESULT:itt_gender_index_umalabka_tableC4=%.6f\n", g_uma))
cat(sprintf("RESULT:itt_vote_overall_unweighted_tableF1_col2=%.6f\n", coef(f2)["Z"]))
cat(sprintf("RESULT:itt_vote_akbayan_unweighted_tableF1_col3=%.6f\n", coef(f3)["Z"]))