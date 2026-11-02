# Lopez-Moctezuma et al. (2022) -- independent blind reproduction
# Table 1 (barangay ITT), SI Tables C.3/C.4 (attitude indices, weighted ITT),
# SI Table F.1 (unweighted individual vote ITT).
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/blind/2026-10-22-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))
load(file.path(D, "survey_raw.RData"))

res <- list()
put <- function(n, v) { res[[n]] <<- v }

## ---------------- Table 1: barangay level, eq. (1) ----------------
a <- data.all
a$partytreat <- as.character(a$partytreat)
m1 <- feols(turnout.party ~ assignment | city, data = a)
m2 <- feols(share.treated ~ assignment | city, data = a)
ak <- subset(a, partytreat == "akbayan")
um <- subset(a, partytreat == "umalabka")
m3 <- feols(share.akbayan ~ assignment | city, data = ak)
m4 <- feols(share.umalabka ~ assignment | city, data = um)
print(etable(m1, m2, m3, m4, vcov = "iid"))

# within-municipality permutation p-values (informational only)
perm_p <- function(df, y, R = 2000) {
  obs <- coef(feols(as.formula(paste(y, "~ assignment | city")), data = df))[["assignment"]]
  sims <- replicate(R, {
    d2 <- df
    d2$assignment <- ave(d2$assignment, d2$city, FUN = function(z) z[sample.int(length(z))])
    coef(feols(as.formula(paste(y, "~ assignment | city")), data = d2))[["assignment"]]
  })
  mean(abs(sims) >= abs(obs) - 1e-12)
}
cat("perm p (informational):",
    perm_p(a, "turnout.party"), perm_p(a, "share.treated"),
    perm_p(ak, "share.akbayan"), perm_p(um, "share.umalabka"), "\n")

put("itt_turnout_barangay_table1_col1", coef(m1)[["assignment"]])
put("itt_vote_overall_barangay_table1_col2", coef(m2)[["assignment"]])
put("itt_vote_akbayan_barangay_table1_col3", coef(m3)[["assignment"]])
put("itt_vote_umalabka_barangay_table1_col4", coef(m4)[["assignment"]])
put("n_obs_barangay_table1_cols1_2", nobs(m1))
put("n_obs_barangay_akbayan_table1_col3", nobs(m3))
put("n_obs_barangay_umalabka_table1_col4", nobs(m4))
cat("N col2:", nobs(m2), "\n")

## ---------------- Survey data ----------------
s <- as.data.frame(survey_raw)
s$city <- as.character(s$city); s$barangay <- as.character(s$barangay)
s <- subset(s, !is.na(city) & !is.na(barangay) & !is.na(assignment))

# Anderson (2008) summary index: items oriented, standardized on control
# group (assignment == 0) mean/sd, inverse-covariance weighted average of
# available items, then re-standardized on the control group.
anderson <- function(df, items) {
  X <- as.matrix(df[, items])
  ctrl <- df$assignment == 0
  Z <- X
  for (j in seq_along(items)) {
    mu <- mean(X[ctrl, j], na.rm = TRUE); sdv <- sd(X[ctrl, j], na.rm = TRUE)
    Z[, j] <- (X[, j] - mu) / sdv
  }
  S <- cov(Z, use = "pairwise.complete.obs")
  w <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) {
    ok <- !is.na(z)
    if (!any(ok)) return(NA_real_)
    sum(w[ok] * z[ok]) / sum(w[ok])
  })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}

# orientation: higher = more agreement that the issue is a main problem
# (poverty items, 1 = agree strongly -> reversed); gender items oriented so
# higher = less sexist / more aware of gender discrimination.
s$pov_o  <- 6 - s$poverty
s$gap_o  <- 6 - s$gap
s$cor_o  <- 6 - s$corruption
s$cct_o  <- s$cct
s$femhouse_o <- s$femhouse
s$fempol_o   <- s$fempol
s$equality_o <- s$equality          # 5 = disagree strongly with sexist statement
s$harass_o   <- s$harassment        # 5 = disagree strongly with sexist statement
s$discr_o    <- 6 - s$discrimination # agree women miss out due to discrimination
s$pov_index <- anderson(s, c("pov_o", "gap_o", "cct_o", "cor_o"))
s$gen_index <- anderson(s, c("femhouse_o", "fempol_o", "equality_o", "discr_o", "harass_o"))

# effective sample: valid party-list turnout response
s <- subset(s, !is.na(turnout_pl))
cat("Effective survey sample:", nrow(s), "\n")

# attendance oversampling weights (treated barangays): survey attendee share
# s_j vs. actual attendee share p_j (att.prop, attendees / registered voters).
s$att0 <- ifelse(is.na(s$attendance), 0, s$attendance)
sh <- aggregate(att0 ~ barangay, data = s, FUN = mean)
names(sh)[2] <- "s_share"
s <- merge(s, sh, by = "barangay", all.x = TRUE)
s <- merge(s, data.all[, c("barangay", "att.prop")], by = "barangay", all.x = TRUE)
s$att.prop[is.na(s$att.prop)] <- 0
s$w <- 1
tr <- s$att.prop > 0 & s$s_share > 0
s$w[tr & s$att0 == 1] <- (s$att.prop / s$s_share)[tr & s$att0 == 1]
s$w[tr & s$att0 == 0] <- ((1 - s$att.prop) / (1 - s$s_share))[tr & s$att0 == 0]
print(unique(s[tr, c("barangay", "att.prop", "s_share")]))

sA <- subset(s, partytreat == "Akbayan")
sU <- subset(s, partytreat == "Umalab Ka")

itt_w <- function(df, y) {
  feols(as.formula(paste(y, "~ assignment | city")), data = df, weights = ~w, cluster = ~barangay)
}
pA <- itt_w(sA, "pov_index"); pU <- itt_w(sU, "pov_index")
gA <- itt_w(sA, "gen_index"); gU <- itt_w(sU, "gen_index")
print(etable(pA, pU, gA, gU))
put("itt_poverty_index_akbayan_tableC3", coef(pA)[["assignment"]])
put("itt_poverty_index_umalabka_tableC3", coef(pU)[["assignment"]])
put("itt_gender_index_akbayan_tableC4", coef(gA)[["assignment"]])
put("itt_gender_index_umalabka_tableC4", coef(gU)[["assignment"]])

## ---------------- SI Table F.1: unweighted vote ITT ----------------
v <- subset(s, turnout_pl == 1 & !is.na(vote))
v$vote100 <- 100 * v$vote
v$voteak100 <- 100 * v$vote.akbayan
f2 <- feols(vote100 ~ assignment | city, data = v, cluster = ~barangay)
f3 <- feols(voteak100 ~ assignment | city, data = subset(v, partytreat == "Akbayan"), cluster = ~barangay)
print(etable(f2, f3))
put("itt_vote_overall_unweighted_tableF1_col2", coef(f2)[["assignment"]])
put("itt_vote_akbayan_unweighted_tableF1_col3", coef(f3)[["assignment"]])

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
