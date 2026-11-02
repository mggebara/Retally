# Independent, blind reproduction: Lopez-Moctezuma et al. (2022), AJPS
# Policy Deliberation and Voter Persuasion (Philippines)
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/blind/2026-11-01-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))   # data.all
load(file.path(D, "survey_raw.RData")) # survey_raw

## ---------------- Table 1: barangay level, eq (1) -----------------
ag <- data.all
ag$city <- factor(ag$city)
m1 <- feols(turnout.party ~ assignment | city, data = ag)
m2 <- feols(share.treated ~ assignment | city, data = ag)
m3 <- feols(share.akbayan ~ assignment | city, data = subset(ag, partytreat == "akbayan"))
m4 <- feols(share.umalabka ~ assignment | city, data = subset(ag, partytreat == "umalabka"))
for (m in list(m1, m2, m3, m4)) print(summary(m))

## ---------------- Survey: sample and attendance weights -----------------
s <- as.data.frame(survey_raw)
s$barangay <- as.character(s$barangay); s$city <- as.character(s$city)
s <- s[!is.na(s$city) & !is.na(s$barangay) & !is.na(s$assignment), ]

# Inverse-probability weights for oversampling of meeting attendees in
# barangays where town halls were held: population share of attendees
# (att.prop = attendees / registered voters, from attendance sheets) over
# the share of self-reported attendees among survey respondents.
agw <- data.frame(barangay = as.character(ag$barangay), att.prop = ag$att.prop,
                  treat_agg = ag$treatment, stringsAsFactors = FALSE)
s <- merge(s, agw, by = "barangay", all.x = TRUE)
s$att.prop[is.na(s$att.prop)] <- 0          # unmatched names are all controls with no meetings
samp_share <- tapply(s$attendance, s$barangay, mean, na.rm = TRUE)
s$samp.share <- as.numeric(samp_share[s$barangay])
s$w <- 1
adj <- s$treatment == 1 & s$samp.share > 0 & !is.na(s$attendance)
s$w[adj & s$attendance == 1] <- (s$att.prop / s$samp.share)[adj & s$attendance == 1]
s$w[adj & s$attendance == 0] <- ((1 - s$att.prop) / (1 - s$samp.share))[adj & s$attendance == 0]
s$w[s$treatment == 1 & is.na(s$attendance)] <- NA
print(aggregate(w ~ barangay + attendance, data = s, FUN = mean))

# Effective sample: valid response to the (party-list) turnout question
se <- s[!is.na(s$turnout_pl), ]
cat("Effective survey sample:", nrow(se), "\n")
se$party <- ifelse(se$partytreat == "Akbayan", "akbayan", "umalabka")

## ---------------- SI Table F.1 (unweighted), cols 2-3 -----------------
vt <- se[se$turnout_pl == 1, ]
f2 <- feols(I(100 * vote) ~ assignment | city, data = vt, cluster = ~barangay)
f3 <- feols(I(100 * vote.akbayan) ~ assignment | city, data = subset(vt, party == "akbayan"), cluster = ~barangay)
print(summary(f2)); print(summary(f3))

## ---------------- Anderson (2008) summary indices -----------------
anderson_index <- function(d, items) {
  ctrl <- d$assignment == 0
  Z <- sapply(items, function(v) {
    x <- d[[v]]
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
# Orientation: positive = more agreement with the platform-relevant concern
se$poverty_o    <- 6 - se$poverty       # 1 = agree strongly poverty is a main problem
se$gap_o        <- 6 - se$gap
se$corruption_o <- 6 - se$corruption
se$cct_o        <- se$cct
se$femrep_o     <- se$femhouse          # female rep. would do equal/better job
se$fempol_o     <- se$fempol            # women's influence too little / about right
se$equality_o   <- se$equality          # disagree "women demanding equality seek favors"
se$discrim_o    <- 6 - se$discrimination # agree "women miss out on jobs due to discrimination"
se$harass_o     <- se$harassment        # disagree "harassment complainers cause problems"
pov_items <- c("poverty_o", "gap_o", "cct_o", "corruption_o")
gen_items <- c("femrep_o", "fempol_o", "equality_o", "discrim_o", "harass_o")

att_res <- list()
for (p in c("akbayan", "umalabka")) {
  d <- se[se$party == p, ]
  d$pov_index <- anderson_index(d, pov_items)
  d$gen_index <- anderson_index(d, gen_items)
  mp <- feols(pov_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  mg <- feols(gen_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  print(summary(mp)); print(summary(mg))
  att_res[[p]] <- c(pov = unname(coef(mp)["assignment"]), gen = unname(coef(mg)["assignment"]))
}

## ---------------- RESULT lines -----------------
cf <- function(m) unname(coef(m)["assignment"])
cat(sprintf("RESULT:itt_turnout_barangay_table1_col1=%.6f\n", cf(m1)))
cat(sprintf("RESULT:itt_vote_overall_barangay_table1_col2=%.6f\n", cf(m2)))
cat(sprintf("RESULT:itt_vote_akbayan_barangay_table1_col3=%.6f\n", cf(m3)))
cat(sprintf("RESULT:itt_vote_umalabka_barangay_table1_col4=%.6f\n", cf(m4)))
cat(sprintf("RESULT:n_obs_barangay_table1_cols1_2=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_barangay_akbayan_table1_col3=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_barangay_umalabka_table1_col4=%d\n", nobs(m4)))
cat(sprintf("RESULT:itt_poverty_index_akbayan_tableC3=%.6f\n", att_res$akbayan["pov"]))
cat(sprintf("RESULT:itt_poverty_index_umalabka_tableC3=%.6f\n", att_res$umalabka["pov"]))
cat(sprintf("RESULT:itt_gender_index_akbayan_tableC4=%.6f\n", att_res$akbayan["gen"]))
cat(sprintf("RESULT:itt_gender_index_umalabka_tableC4=%.6f\n", att_res$umalabka["gen"]))
cat(sprintf("RESULT:itt_vote_overall_unweighted_tableF1_col2=%.6f\n", cf(f2)))
cat(sprintf("RESULT:itt_vote_akbayan_unweighted_tableF1_col3=%.6f\n", cf(f3)))
