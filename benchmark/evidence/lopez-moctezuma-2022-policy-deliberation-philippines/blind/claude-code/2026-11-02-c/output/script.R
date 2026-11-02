# Independent, blind reproduction: Lopez-Moctezuma et al. (2022), AJPS
# Table 1 (barangay ITT), SI Tables C.3/C.4 (attitude index ITT), SI Table F.1 (unweighted vote ITT)
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/blind/2026-11-02-c/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))
load(file.path(D, "survey_raw.RData"))

## ---------------- Table 1: barangay level, eq. (1) ----------------
agg <- data.all
agg$city <- as.character(agg$city)
m1 <- feols(turnout.party ~ assignment | city, data = agg)
m2 <- feols(share.treated ~ assignment | city, data = agg)
m3 <- feols(share.akbayan ~ assignment | city, data = subset(agg, partytreat == "akbayan"))
m4 <- feols(share.umalabka ~ assignment | city, data = subset(agg, partytreat == "umalabka"))
for (m in list(m1, m2, m3, m4)) print(coeftable(m))

## ---------------- Survey data ----------------
s <- as.data.frame(survey_raw)
s$barangay <- as.character(s$barangay); s$city <- as.character(s$city)
# effective sample: valid response to the (party-list) turnout question (paper fn. 11: 1,082)
s <- s[!is.na(s$turnout_pl) & !is.na(s$assignment) & !is.na(s$city), ]
cat("Survey effective N:", nrow(s), "\n")

# map survey barangay names onto aggregate names to get attendance-sheet proportions
namemap <- c("Escopa IV" = "Escopa 4", "B. F. Homes" = "B.F Homes", "Putho Tuntungin" = "Putho",
             "Barangay Zone VI (Pob.)" = "Barangay Zone VI", "Santo Rosario-Silangan" = "San Rosario-Silangan")
s$brgy_agg <- ifelse(s$barangay %in% names(namemap), namemap[s$barangay], s$barangay)
stopifnot(all(s$brgy_agg %in% agg$barangay))
s$att_true <- agg$att.prop[match(s$brgy_agg, agg$barangay)]

# Inverse-probability weights for oversampling of meeting attendees in treated barangays:
# attendees weighted by (true attendance share / survey attendance share), non-attendees by the
# complementary ratio; respondents in barangays without meetings get weight 1.
p_surv <- tapply(s$attendance, s$barangay, function(x) mean(x, na.rm = TRUE))
s$p_surv <- p_surv[s$barangay]
s$w <- 1
tr <- s$att_true > 0 & !is.na(s$attendance) & s$p_surv > 0
s$w[tr & s$attendance == 1] <- (s$att_true / s$p_surv)[tr & s$attendance == 1]
s$w[tr & s$attendance == 0] <- ((1 - s$att_true) / (1 - s$p_surv))[tr & s$attendance == 0]
print(aggregate(w ~ barangay + attendance, data = s[s$att_true > 0, ], FUN = mean))

## ---------------- SI Table F.1: unweighted vote ITT ----------------
s$vote100 <- 100 * s$vote
s$vote_akb100 <- 100 * s$vote.akbayan
f2 <- feols(vote100 ~ assignment | city, data = subset(s, !is.na(vote)), cluster = ~barangay)
f3 <- feols(vote_akb100 ~ assignment | city, data = subset(s, partytreat == "Akbayan" & !is.na(vote.akbayan)),
            cluster = ~barangay)
print(coeftable(f2)); print(coeftable(f3))

## ---------------- Anderson (2008) summary indices ----------------
rev5 <- function(x) 6 - x   # 1 = agree strongly ... 5 = disagree strongly  ->  higher = more agreement
anderson_index <- function(d, vars) {
  X <- as.matrix(d[, vars])
  ctrl <- d$assignment == 0
  Z <- X
  for (j in seq_along(vars)) {
    mu <- mean(X[ctrl, j], na.rm = TRUE); sdv <- sd(X[ctrl, j], na.rm = TRUE)
    Z[, j] <- (X[, j] - mu) / sdv
  }
  S <- cov(Z, use = "pairwise.complete.obs")
  wts <- rowSums(solve(S))
  num <- apply(Z, 1, function(z) sum(wts[!is.na(z)] * z[!is.na(z)]))
  den <- apply(Z, 1, function(z) sum(wts[!is.na(z)]))
  idx <- ifelse(den == 0, NA, num / den)
  idx[rowSums(!is.na(Z)) == 0] <- NA
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}
s$poverty_o <- rev5(s$poverty); s$gap_o <- rev5(s$gap); s$corruption_o <- rev5(s$corruption)
s$equality_o <- rev5(s$equality); s$discrimination_o <- rev5(s$discrimination); s$harassment_o <- rev5(s$harassment)
pov_vars <- c("poverty_o", "gap_o", "cct", "corruption_o")
gen_vars <- c("femhouse", "fempol", "equality_o", "discrimination_o", "harassment_o")

res_idx <- list()
for (p in c("Akbayan", "Umalab Ka")) {
  d <- subset(s, partytreat == p)
  d$pov_index <- anderson_index(d, pov_vars)
  d$gen_index <- anderson_index(d, gen_vars)
  mp <- feols(pov_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  mg <- feols(gen_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  cat("Party:", p, "\n"); print(coeftable(mp)); print(coeftable(mg))
  res_idx[[p]] <- c(pov = unname(coef(mp)["assignment"]), gen = unname(coef(mg)["assignment"]))
}

## ---------------- RESULTS ----------------
out <- c(
  itt_turnout_barangay_table1_col1 = unname(coef(m1)["assignment"]),
  itt_vote_overall_barangay_table1_col2 = unname(coef(m2)["assignment"]),
  itt_vote_akbayan_barangay_table1_col3 = unname(coef(m3)["assignment"]),
  itt_vote_umalabka_barangay_table1_col4 = unname(coef(m4)["assignment"]),
  n_obs_barangay_table1_cols1_2 = nobs(m2),
  n_obs_barangay_akbayan_table1_col3 = nobs(m3),
  n_obs_barangay_umalabka_table1_col4 = nobs(m4),
  itt_poverty_index_akbayan_tableC3 = res_idx[["Akbayan"]][["pov"]],
  itt_poverty_index_umalabka_tableC3 = res_idx[["Umalab Ka"]][["pov"]],
  itt_gender_index_akbayan_tableC4 = res_idx[["Akbayan"]][["gen"]],
  itt_gender_index_umalabka_tableC4 = res_idx[["Umalab Ka"]][["gen"]],
  itt_vote_overall_unweighted_tableF1_col2 = unname(coef(f2)["assignment"]),
  itt_vote_akbayan_unweighted_tableF1_col3 = unname(coef(f3)["assignment"])
)
if (nobs(m1) != nobs(m2)) cat("NOTE: turnout regression N =", nobs(m1), "\n")
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
cat("DEVIATION: attendance IPW weights constructed from data_agg att.prop (attendance sheets / registered voters) vs. barangay survey attendance share; exact authors' weight formula not documented\n")
cat("DEVIATION: all five-point attitude items reversed (6-x) so higher = more agreement; binary items kept as coded\n")
