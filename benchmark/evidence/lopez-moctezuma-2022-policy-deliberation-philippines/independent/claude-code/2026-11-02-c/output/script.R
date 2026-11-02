## Independent reproduction: Lopez-Moctezuma et al. (2022), AJPS
## Table 1 (barangay ITT), SI Tables C.3/C.4 (attitude indices ITT), SI Table F.1 (unweighted vote ITT)
suppressPackageStartupMessages(library(fixest))
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-11-02-c/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))   # data.all
load(file.path(D, "survey_raw.RData")) # survey_raw

res <- list()
## ---------------- Table 1: barangay level, eq. (1): Y = city FE + beta * assignment
agg <- data.all
m1 <- feols(turnout.party ~ assignment | city, data = agg)
m2 <- feols(share.treated ~ assignment | city, data = agg)
m3 <- feols(share.akbayan ~ assignment | city, data = subset(agg, partytreat == "akbayan"))
m4 <- feols(share.umalabka ~ assignment | city, data = subset(agg, partytreat == "umalabka"))
res$itt_turnout_barangay_table1_col1 <- coef(m1)["assignment"]
res$itt_vote_overall_barangay_table1_col2 <- coef(m2)["assignment"]
res$itt_vote_akbayan_barangay_table1_col3 <- coef(m3)["assignment"]
res$itt_vote_umalabka_barangay_table1_col4 <- coef(m4)["assignment"]
res$n_obs_barangay_table1_cols1_2 <- nobs(m2)
res$n_obs_barangay_akbayan_table1_col3 <- nobs(m3)
res$n_obs_barangay_umalabka_table1_col4 <- nobs(m4)

## ---------------- Survey data
s <- as.data.frame(survey_raw)
s$city <- as.character(s$city); s$barangay <- as.character(s$barangay)
s <- subset(s, !is.na(turnout_pl) & !is.na(city) & !is.na(barangay))  # effective sample (fn. 11)

## Attendance-oversampling weights in treated barangays: post-stratify survey attendance
## share (p_s) to actual attendance share from attendance sheets (att.prop, attendees / registered voters).
ap <- agg[, c("barangay", "att.prop")]
s <- merge(s, ap, by = "barangay", all.x = TRUE)
s$att.prop[is.na(s$att.prop)] <- 0
ps <- tapply(s$attendance, s$barangay, function(x) mean(x, na.rm = TRUE))
s$p_s <- ps[s$barangay]
s$w <- 1
tr <- s$treatment == 1 & !is.na(s$attendance) & s$p_s > 0
s$w[tr & s$attendance == 1] <- (s$att.prop / s$p_s)[tr & s$attendance == 1]
s$w[tr & s$attendance == 0] <- ((1 - s$att.prop) / (1 - s$p_s))[tr & s$attendance == 0]
cat("weights summary (treated barangays):\n"); print(summary(s$w[s$treatment == 1]))

## ---------------- SI Table F.1 (unweighted): vote for treating party among voters
v <- subset(s, turnout_pl == 1)
f2 <- feols(I(100 * vote) ~ assignment | city, data = v, cluster = ~barangay)
f3 <- feols(I(100 * vote.akbayan) ~ assignment | city, data = subset(v, partytreat == "Akbayan"), cluster = ~barangay)
res$itt_vote_overall_unweighted_tableF1_col2 <- coef(f2)["assignment"]
res$itt_vote_akbayan_unweighted_tableF1_col3 <- coef(f3)["assignment"]

## ---------------- Anderson (2008) summary index
anderson_index <- function(dat, items) {
  ctrl <- dat$assignment == 0
  Z <- sapply(items, function(k) {
    x <- dat[[k]]
    (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  S <- cov(Z, use = "pairwise.complete.obs")
  wts <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) {
    ok <- !is.na(z)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * z[ok]) / sum(wts[ok])
  })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}
## Orientation: poverty items (1 = agree strongly ... 5 = disagree strongly) reversed so that
## higher = more agreement that the issue is a main problem; cct (1 = prefers CCT) kept.
## Gender items oriented toward awareness of gender discrimination: femhouse, fempol (1 = progressive),
## equality and harassment (higher = disagree with sexist statement) kept; discrimination
## (1 = agree women miss out on jobs due to discrimination) reversed.
for (k in c("poverty", "gap", "corruption", "discrimination")) s[[k]] <- 6 - s[[k]]
pov_items <- c("poverty", "gap", "cct", "corruption")
gen_items <- c("femhouse", "fempol", "equality", "discrimination", "harassment")
## Diagnostics (not scored): index ITTs under alternative weighting
s$w_none <- 1
ps2 <- tapply(s$attendance, s$barangay, function(x) mean(x, na.rm = TRUE))[s$barangay]
s$w_att <- 1
a2 <- s$treatment == 1 & !is.na(s$attendance) & s$attendance == 1 & ps2 > 0
s$w_att[a2] <- (s$att.prop / ps2)[a2]
for (p in c("Akbayan", "Umalab Ka")) {
  d <- subset(s, partytreat == p)
  d$pov_index <- anderson_index(d, pov_items); d$gen_index <- anderson_index(d, gen_items)
  for (ww in c("w_none", "w_att")) {
    d$ww <- d[[ww]]
    cat(sprintf("DIAG %s %s: poverty=%.3f gender=%.3f\n", p, ww,
        coef(feols(pov_index ~ assignment | city, data = d, weights = ~ww, notes = FALSE))["assignment"],
        coef(feols(gen_index ~ assignment | city, data = d, weights = ~ww, notes = FALSE))["assignment"]))
  }
}
for (p in c("Akbayan", "Umalab Ka")) {
  d <- subset(s, partytreat == p)
  d$pov_index <- anderson_index(d, pov_items)
  d$gen_index <- anderson_index(d, gen_items)
  mp <- feols(pov_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  mg <- feols(gen_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  tag <- if (p == "Akbayan") "akbayan" else "umalabka"
  res[[paste0("itt_poverty_index_", tag, "_tableC3")]] <- coef(mp)["assignment"]
  res[[paste0("itt_gender_index_", tag, "_tableC4")]] <- coef(mg)["assignment"]
  cat(p, ": N pov =", nobs(mp), " N gen =", nobs(mg), "\n")
}

ord <- c("itt_turnout_barangay_table1_col1", "itt_vote_overall_barangay_table1_col2",
         "itt_vote_akbayan_barangay_table1_col3", "itt_vote_umalabka_barangay_table1_col4",
         "n_obs_barangay_table1_cols1_2", "n_obs_barangay_akbayan_table1_col3",
         "n_obs_barangay_umalabka_table1_col4", "itt_poverty_index_akbayan_tableC3",
         "itt_poverty_index_umalabka_tableC3", "itt_gender_index_akbayan_tableC4",
         "itt_gender_index_umalabka_tableC4", "itt_vote_overall_unweighted_tableF1_col2",
         "itt_vote_akbayan_unweighted_tableF1_col3")
for (k in ord) cat(sprintf("RESULT:%s=%.6f\n", k, as.numeric(res[[k]])))
