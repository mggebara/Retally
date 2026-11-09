# Independent, blind reproduction: Lopez-Moctezuma et al. (2022), AJPS.
# Table 1 (barangay ITT), SI Tables C.3/C.4 (attitude indices, weighted ITT),
# SI Table F.1 (unweighted individual vote ITT).
suppressPackageStartupMessages(library(fixest))
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/blind/2026-11-07-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))
load(file.path(D, "survey_raw.RData"))

# ---------------- Table 1: barangay level, eq. (1) ----------------
a <- data.all
a$city <- factor(a$city)
m1 <- feols(turnout.party ~ assignment | city, data = a)
m2 <- feols(share.treated ~ assignment | city, data = a)
ak <- subset(a, partytreat == "akbayan")
um <- subset(a, partytreat == "umalabka")
m3 <- feols(share.akbayan ~ assignment | city, data = ak)
m4 <- feols(share.umalabka ~ assignment | city, data = um)
for (m in list(m1, m2, m3, m4)) print(summary(m))

# ---------------- Individual level ----------------
s <- as.data.frame(survey_raw)
s$city <- as.character(s$city); s$barangay <- as.character(s$barangay)
s <- s[!is.na(s$turnout_pl), ]               # effective sample (valid turnout answer)
cat("Effective survey sample:", nrow(s), "\n")

# Inverse-probability weights for oversampling of meeting attendees in barangays
# where meetings were held: attendees weighted by true attendance share / survey
# attendance share; non-attendees by (1 - true)/(1 - survey). Others weight 1.
att <- a[a$treatment == 1, c("barangay", "att.prop")]
s$w <- 1
for (b in att$barangay) {
  idx <- which(s$barangay == b)
  if (length(idx) == 0) { cat("no survey match for", b, "\n"); next }
  ps <- mean(s$attendance[idx], na.rm = TRUE)
  pt <- att$att.prop[att$barangay == b]
  cat(sprintf("%-25s survey att %.3f  true att %.4f  n=%d\n", b, ps, pt, length(idx)))
  ia <- idx[!is.na(s$attendance[idx]) & s$attendance[idx] == 1]
  ina <- idx[!is.na(s$attendance[idx]) & s$attendance[idx] == 0]
  if (ps > 0) s$w[ia] <- pt / ps
  s$w[ina] <- (1 - pt) / (1 - ps)
}

# Anderson (2008) inverse-covariance weighted index, standardized on controls
anderson <- function(X, ctrl) {
  Z <- sapply(seq_len(ncol(X)), function(j) {
    x <- X[, j]; (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  S <- cov(Z, use = "pairwise.complete.obs")
  wv <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) {
    ok <- !is.na(z); if (!any(ok)) return(NA_real_)
    sum(wv[ok] * z[ok]) / sum(wv[ok])
  })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}

# Orientation
s$pov_poverty    <- 6 - s$poverty      # higher = agree more that poverty is a main problem
s$pov_gap        <- 6 - s$gap
s$pov_corruption <- 6 - s$corruption
s$pov_cct        <- s$cct
s$gen_femhouse   <- s$femhouse         # female rep. equal or better
s$gen_fempol     <- s$fempol
s$gen_equality   <- s$equality         # higher = disagree "equality = special favors"
s$gen_discrim    <- 6 - s$discrimination # higher = agree women miss jobs due to discrimination
s$gen_harass     <- s$harassment       # higher = disagree "complaints cause problems"

pov_items <- c("pov_poverty", "pov_gap", "pov_cct", "pov_corruption")
gen_items <- c("gen_femhouse", "gen_fempol", "gen_equality", "gen_discrim", "gen_harass")

itt_index <- function(party, items) {
  d <- s[s$partytreat == party & !is.na(s$assignment), ]
  d$index <- anderson(as.matrix(d[, items]), d$assignment == 0)
  m <- feols(index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  print(summary(m))
  unname(coef(m)["assignment"])
}
pov_ak <- itt_index("Akbayan", pov_items)
pov_um <- itt_index("Umalab Ka", pov_items)
gen_ak <- itt_index("Akbayan", gen_items)
gen_um <- itt_index("Umalab Ka", gen_items)

# ---------------- SI Table F.1 (unweighted) ----------------
v <- s[s$turnout_pl == 1, ]
v$vote100 <- 100 * v$vote
v$voteak100 <- 100 * v$vote.akbayan
f2 <- feols(vote100 ~ assignment | city, data = v, cluster = ~barangay)
f3 <- feols(voteak100 ~ assignment | city, data = v[v$partytreat == "Akbayan", ], cluster = ~barangay)
print(summary(f2)); print(summary(f3))

res <- c(
  itt_turnout_barangay_table1_col1 = coef(m1)[["assignment"]],
  itt_vote_overall_barangay_table1_col2 = coef(m2)[["assignment"]],
  itt_vote_akbayan_barangay_table1_col3 = coef(m3)[["assignment"]],
  itt_vote_umalabka_barangay_table1_col4 = coef(m4)[["assignment"]],
  n_obs_barangay_table1_cols1_2 = nobs(m2),
  n_obs_barangay_akbayan_table1_col3 = nobs(m3),
  n_obs_barangay_umalabka_table1_col4 = nobs(m4),
  itt_poverty_index_akbayan_tableC3 = pov_ak,
  itt_poverty_index_umalabka_tableC3 = pov_um,
  itt_gender_index_akbayan_tableC4 = gen_ak,
  itt_gender_index_umalabka_tableC4 = gen_um,
  itt_vote_overall_unweighted_tableF1_col2 = coef(f2)[["assignment"]],
  itt_vote_akbayan_unweighted_tableF1_col3 = coef(f3)[["assignment"]]
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
