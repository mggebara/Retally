suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

unlab <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  x
}
to_binary <- function(x) {
  x <- unlab(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) {
    u <- sort(unique(na.omit(x)))
    if (all(u %in% c(0, 1))) return(as.numeric(x))
    if (all(u %in% c(1, 2))) return(as.numeric(x == 1))
    return(as.numeric(x > 0))
  }
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(s))
  out[grepl("^(1|yes|y|true|treat|treatment|treated|voted|assigned)", s)] <- 1
  out[grepl("^(0|no|n|false|control|not|did not|didn|unassigned)", s)] <- 0
  out
}
to_num <- function(x) {
  x <- unlab(x)
  if (is.numeric(x)) return(as.numeric(x))
  if (is.factor(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (sum(!is.na(v)) > 0) return(v)
    return(as.numeric(x))
  }
  suppressWarnings(as.numeric(as.character(x)))
}
norm_name <- function(x) gsub("[^a-z0-9]", "", tolower(as.character(x)))
is_akb_str <- function(x) grepl("ak", tolower(as.character(unlab(x))))

# ---------------- Barangay level (Table 1) ----------------
agg <- as.data.frame(data.all)
cat(sprintf("SAMPLE:barangay_all:loaded=%d\n", nrow(agg)))
agg$Z <- to_binary(agg$assignment)
agg$city_f <- as.character(agg$city)
agg$turnout_y <- to_num(agg$turnout.party)
agg$share_akb <- to_num(agg$share.akbayan)
agg$share_uma <- to_num(agg$share.umalabka)
agg$share_tr <- to_num(agg$share.treated)

# determine treating party per barangay
akb_flag <- rep(NA, nrow(agg))
if (!is.numeric(unlab(agg$partytreat))) {
  akb_flag <- is_akb_str(agg$partytreat)
}
if (all(is.na(akb_flag)) || length(unique(akb_flag)) < 2) {
  d1 <- abs(agg$share_tr - agg$share_akb); d2 <- abs(agg$share_tr - agg$share_uma)
  akb_flag <- d1 < d2
}
# make constant within city (municipalities were assigned to party lists)
akb_city <- tapply(akb_flag, agg$city_f, function(v) mean(v, na.rm = TRUE) > 0.5)
agg$akb <- akb_city[agg$city_f]
agg$vote_treated <- ifelse(agg$akb, agg$share_akb, agg$share_uma)
if (all(is.na(agg$vote_treated))) agg$vote_treated <- agg$share_tr
# percent scaling
sc <- function(v) if (max(v, na.rm = TRUE) <= 1.0001) v * 100 else v
agg$turnout_y <- sc(agg$turnout_y)
agg$vote_treated <- sc(agg$vote_treated)

m1 <- feols(turnout_y ~ Z | city_f, data = agg)
cat(sprintf("SAMPLE:barangay_all:estimation=%d\n", nobs(m1)))
m2 <- feols(vote_treated ~ Z | city_f, data = agg)
agg_akb <- agg[agg$akb %in% TRUE, ]
agg_uma <- agg[agg$akb %in% FALSE, ]
cat(sprintf("SAMPLE:barangay_akbayan:loaded=%d\n", nrow(agg)))
cat(sprintf("SAMPLE:barangay_akbayan:akbayan_municipalities=%d\n", nrow(agg_akb)))
m3 <- feols(vote_treated ~ Z | city_f, data = agg_akb)
cat(sprintf("SAMPLE:barangay_akbayan:estimation=%d\n", nobs(m3)))
cat(sprintf("SAMPLE:barangay_umalabka:loaded=%d\n", nrow(agg)))
cat(sprintf("SAMPLE:barangay_umalabka:umalabka_municipalities=%d\n", nrow(agg_uma)))
m4 <- feols(vote_treated ~ Z | city_f, data = agg_uma)
cat(sprintf("SAMPLE:barangay_umalabka:estimation=%d\n", nobs(m4)))

# randomization inference (within-municipality permutation)
perm_p <- function(df, yvar, R = 2000) {
  obs <- coef(feols(as.formula(paste(yvar, "~ Z | city_f")), data = df))["Z"]
  stats <- replicate(R, {
    d <- df
    d$Z <- ave(d$Z, d$city_f, FUN = function(z) z[sample.int(length(z))])
    coef(feols(as.formula(paste(yvar, "~ Z | city_f")), data = d))["Z"]
  })
  mean(abs(stats) >= abs(obs) - 1e-12)
}
p1 <- tryCatch(perm_p(agg, "turnout_y"), error = function(e) NA)
p2 <- tryCatch(perm_p(agg, "vote_treated"), error = function(e) NA)

# ---------------- Individual level ----------------
sv <- as.data.frame(survey_raw)
for (nm in names(sv)) sv[[nm]] <- unlab(sv[[nm]])
cat(sprintf("SAMPLE:indiv:loaded=%d\n", nrow(sv)))
sv$Z <- to_binary(sv$assignment)
sv$city_f <- as.character(sv$city)
sv$brgy_f <- as.character(sv$barangay)

# exclude municipalities lacking both treatment and control samples
both <- tapply(sv$Z, sv$city_f, function(z) length(unique(na.omit(z))) == 2)
sv <- sv[sv$city_f %in% names(both)[both], ]
cat(sprintf("SAMPLE:indiv:exclude_cities_without_both_arms=%d\n", nrow(sv)))
sv$turnout <- to_binary(sv$turnout_all)
sv <- sv[!is.na(sv$turnout), ]
cat(sprintf("SAMPLE:indiv:valid_turnout=%d\n", nrow(sv)))

# treating party by city
akb_s <- rep(NA, nrow(sv))
aa <- to_binary(sv$assign.akbayan); au <- to_binary(sv$assign.umalabka)
ca <- tapply(aa, sv$city_f, function(v) any(v == 1, na.rm = TRUE))
cu <- tapply(au, sv$city_f, function(v) any(v == 1, na.rm = TRUE))
if (any(ca) && any(cu) && !any(ca & cu)) {
  akb_s <- ca[sv$city_f]
} else if (!is.numeric(sv$partytreat)) {
  pc <- tapply(is_akb_str(sv$partytreat), sv$city_f, function(v) mean(v) > 0.5)
  akb_s <- pc[sv$city_f]
} else {
  ta <- to_binary(sv$treat.akbayan)
  pc <- tapply(ta, sv$city_f, function(v) any(v == 1, na.rm = TRUE))
  akb_s <- pc[sv$city_f]
}
sv$akb <- as.logical(akb_s)

sv$v_akb <- to_binary(sv$vote.akbayan)
sv$v_uma <- to_binary(sv$vote.umalabka)
sv$vote_tr <- 100 * ifelse(sv$akb, sv$v_akb, sv$v_uma)

# weights: correct oversampling of attendees in treatment barangays
sv$att <- to_binary(sv$attendance)
sv$att[is.na(sv$att)] <- 0
agg$bkey <- norm_name(agg$barangay)
sv$bkey <- norm_name(sv$barangay)
attp <- to_num(agg$att.prop)
if (max(attp, na.rm = TRUE) > 1) attp <- attp / 100
attp[is.na(attp)] <- 0
names(attp) <- agg$bkey
sv$w <- 1
for (b in unique(sv$bkey)) {
  idx <- which(sv$bkey == b)
  p <- if (b %in% names(attp)) attp[[b]] else 0
  s <- mean(sv$att[idx])
  if (p > 0 && s > 0 && s < 1) {
    sv$w[idx] <- ifelse(sv$att[idx] == 1, p / s, (1 - p) / (1 - s))
  }
}

# vote sample: those who turned out (party-list)
tpl <- to_binary(sv$turnout_pl)
if (sum(!is.na(tpl)) > 0.5 * nrow(sv) && sum(tpl == 1, na.rm = TRUE) > 0.3 * nrow(sv)) {
  vt <- sv[tpl %in% 1, ]
} else {
  vt <- sv[sv$turnout == 1, ]
}
cat(sprintf("SAMPLE:indiv_vote_unweighted:loaded=%d\n", nrow(survey_raw)))
cat(sprintf("SAMPLE:indiv_vote_unweighted:turned_out=%d\n", nrow(vt)))
vt <- vt[!is.na(vt$vote_tr), ]
mF2 <- feols(vote_tr ~ Z | city_f, data = vt, cluster = ~brgy_f)
cat(sprintf("SAMPLE:indiv_vote_unweighted:estimation=%d\n", nobs(mF2)))
vt_akb <- vt[vt$akb %in% TRUE, ]
cat(sprintf("SAMPLE:indiv_vote_akbayan_unweighted:loaded=%d\n", nrow(survey_raw)))
cat(sprintf("SAMPLE:indiv_vote_akbayan_unweighted:akbayan_turned_out=%d\n", nrow(vt_akb)))
mF3 <- feols(vote_tr ~ Z | city_f, data = vt_akb, cluster = ~brgy_f)
cat(sprintf("SAMPLE:indiv_vote_akbayan_unweighted:estimation=%d\n", nobs(mF3)))

# ---------------- Anderson indices ----------------
anderson_index <- function(df, items) {
  X <- sapply(items, function(v) to_num(df[[v]]))
  X <- as.matrix(X)
  ctrl <- df$Z == 0
  for (j in seq_len(ncol(X))) {
    mu <- mean(X[ctrl, j], na.rm = TRUE); sdv <- sd(X[ctrl, j], na.rm = TRUE)
    X[, j] <- (X[, j] - mu) / sdv
  }
  S <- cov(X, use = "pairwise.complete.obs")
  Sinv <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wts <- rowSums(Sinv)
  idx <- apply(X, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * r[ok]) / sum(wts[ok])
  })
  idx <- (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
  idx
}
pov_items <- c("poverty", "gap", "cct", "corruption")
gen_items <- c("femhouse", "fempol", "equality", "discrimination", "harassment")

run_index <- function(party_akb, items, label) {
  d <- sv[sv$akb %in% party_akb, ]
  cat(sprintf("SAMPLE:%s:loaded=%d\n", label, nrow(survey_raw)))
  cat(sprintf("SAMPLE:%s:party_municipalities=%d\n", label, nrow(d)))
  d$idx <- anderson_index(d, items)
  m <- feols(idx ~ Z | city_f, data = d, weights = ~w, cluster = ~brgy_f)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", label, nobs(m)))
  unname(coef(m)["Z"])
}
pa <- run_index(TRUE, pov_items, "poverty_akbayan")
pu <- run_index(FALSE, pov_items, "poverty_umalabka")
ga <- run_index(TRUE, gen_items, "gender_akbayan")
gu <- run_index(FALSE, gen_items, "gender_umalabka")

# ---------------- Results ----------------
cat(sprintf("RESULT:itt_turnout_barangay_table1_col1=%.6f\n", coef(m1)["Z"]))
cat(sprintf("RESULT:itt_vote_overall_barangay_table1_col2=%.6f\n", coef(m2)["Z"]))
cat(sprintf("RESULT:itt_vote_akbayan_barangay_table1_col3=%.6f\n", coef(m3)["Z"]))
cat(sprintf("RESULT:itt_vote_umalabka_barangay_table1_col4=%.6f\n", coef(m4)["Z"]))
cat(sprintf("RESULT:n_obs_barangay_table1_cols1_2=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_barangay_akbayan_table1_col3=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_barangay_umalabka_table1_col4=%d\n", nobs(m4)))
cat(sprintf("RESULT:itt_poverty_index_akbayan_tableC3=%.6f\n", pa))
cat(sprintf("RESULT:itt_poverty_index_umalabka_tableC3=%.6f\n", pu))
cat(sprintf("RESULT:itt_gender_index_akbayan_tableC4=%.6f\n", ga))
cat(sprintf("RESULT:itt_gender_index_umalabka_tableC4=%.6f\n", gu))
cat(sprintf("RESULT:itt_vote_overall_unweighted_tableF1_col2=%.6f\n", coef(mF2)["Z"]))
cat(sprintf("RESULT:itt_vote_akbayan_unweighted_tableF1_col3=%.6f\n", coef(mF3)["Z"]))
