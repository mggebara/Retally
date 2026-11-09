# Independent reproduction: Lopez-Moctezuma et al. (2022), AJPS
# Table 1 (barangay ITT), SI Tables C.3/C.4 (attitude indices, ITT),
# SI Table F.1 (unweighted individual vote ITT).
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-11-07-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))
load(file.path(D, "survey_raw.RData"))

## ---------------- Table 1: barangay level, eq. (1) ----------------
a <- data.all
a$share.treated2 <- ifelse(a$partytreat == "akbayan", a$share.akbayan, a$share.umalabka)
m1 <- feols(turnout.party ~ assignment | city, data = a)
m2 <- feols(share.treated2 ~ assignment | city, data = a)
ak <- subset(a, partytreat == "akbayan")
um <- subset(a, partytreat == "umalabka")
m3 <- feols(share.akbayan ~ assignment | city, data = ak)
m4 <- feols(share.umalabka ~ assignment | city, data = um)

# permutation p-values (within-municipality re-assignment of the one treated barangay)
perm_p <- function(df, y, B = 2000) {
  b0 <- coef(feols(as.formula(paste(y, "~ assignment | city")), data = df))[["assignment"]]
  bs <- replicate(B, {
    d <- df
    d$assignment <- ave(d$assignment, d$city, FUN = function(z) sample(z))
    coef(feols(as.formula(paste(y, "~ assignment | city")), data = d))[["assignment"]]
  })
  mean(abs(bs) >= abs(b0))
}
cat(sprintf("Table1 ITT: %.3f %.3f %.3f %.3f\n", coef(m1), coef(m2), coef(m3), coef(m4)))
cat(sprintf("Table1 perm p: %.3f %.3f %.3f %.3f\n",
            perm_p(a, "turnout.party"), perm_p(a, "share.treated2"),
            perm_p(ak, "share.akbayan"), perm_p(um, "share.umalabka")))
cat(sprintf("Table1 N: %d %d %d %d\n", nobs(m1), nobs(m2), nobs(m3), nobs(m4)))

## ---------------- Individual level ----------------
s <- as.data.frame(survey_raw)
s$city <- as.character(s$city); s$barangay <- as.character(s$barangay)
s <- s[!is.na(s$city) & !is.na(s$barangay) & !is.na(s$assignment), ]

# Attendance oversampling weights (treated barangays): reweight survey so that the
# share of attendees equals the true attendee share (attendance sheets / registered voters).
norm <- function(x) tolower(gsub("[^A-Za-z0-9]", "", x))
a$key <- norm(a$barangay)
s$key <- norm(s$barangay)
s$key[s$key == "bfhomes"] <- norm("B.F Homes")
s$att0 <- ifelse(is.na(s$attendance), 0, s$attendance)
s$w <- 1
for (b in unique(s$key[s$treatment == 1])) {
  idx <- which(s$key == b)
  p_true <- a$att.prop[a$key == b]
  if (length(p_true) != 1) stop("no match for barangay ", b)
  p_surv <- mean(s$att0[idx])
  if (p_surv > 0) {
    s$w[idx] <- ifelse(s$att0[idx] == 1, p_true / p_surv, (1 - p_true) / (1 - p_surv))
  }
}
cat("weights by treated barangay:\n")
print(aggregate(w ~ barangay + att0, data = s[s$treatment == 1, ], FUN = mean))

eff <- s[!is.na(s$turnout_pl), ]   # effective sample (valid turnout answer), n = 1082
cat("effective sample:", nrow(eff), "\n")

## Unweighted vote ITT (SI Table F.1)
voters <- subset(eff, turnout_pl == 1)
f2 <- feols(I(100 * vote) ~ assignment | city, data = voters, cluster = ~barangay)
f3 <- feols(I(100 * vote.akbayan) ~ assignment | city,
            data = subset(voters, partytreat == "Akbayan"), cluster = ~barangay)
cat(sprintf("F.1 unweighted: vote %.3f (N=%d), akbayan %.3f (N=%d)\n",
            coef(f2), nobs(f2), coef(f3), nobs(f3)))
# weighted versions (Table C.2 analogue), for information only
fw2 <- feols(I(100 * vote) ~ assignment | city, data = voters, weights = ~w, cluster = ~barangay)
cat(sprintf("C.2 weighted vote: %.3f\n", coef(fw2)))

## Anderson (2008) summary indices
anderson <- function(df, items) {
  ctrl <- df$assignment == 0
  Z <- sapply(items, function(v) {
    x <- df[[v]]
    (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  S <- cov(Z, use = "pairwise.complete.obs")
  wt <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) {
    ok <- !is.na(z)
    if (!any(ok)) return(NA_real_)
    sum(wt[ok] * z[ok]) / sum(wt[ok])
  })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}
eff$poverty_o    <- 6 - eff$poverty
eff$gap_o        <- 6 - eff$gap
eff$corruption_o <- 6 - eff$corruption
eff$discrimination_o <- 6 - eff$discrimination
pov_items <- c("poverty_o", "gap_o", "cct", "corruption_o")
gen_items <- c("femhouse", "fempol", "equality", "discrimination_o", "harassment")

res <- list()
for (pt in c("Akbayan", "Umalab Ka")) {
  d <- subset(eff, partytreat == pt)
  d$pov_index <- anderson(d, pov_items)
  d$gen_index <- anderson(d, gen_items)
  mp <- feols(pov_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  mg <- feols(gen_index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  cat(sprintf("%s: poverty index ITT %.3f (p=%.3f, N=%d); gender index ITT %.3f (p=%.3f, N=%d)\n",
              pt, coef(mp), pvalue(mp), nobs(mp), coef(mg), pvalue(mg), nobs(mg)))
  res[[pt]] <- c(pov = unname(coef(mp)), gen = unname(coef(mg)))
}

cat(sprintf("RESULT:itt_turnout_barangay_table1_col1=%.4f\n", coef(m1)))
cat(sprintf("RESULT:itt_vote_overall_barangay_table1_col2=%.4f\n", coef(m2)))
cat(sprintf("RESULT:itt_vote_akbayan_barangay_table1_col3=%.4f\n", coef(m3)))
cat(sprintf("RESULT:itt_vote_umalabka_barangay_table1_col4=%.4f\n", coef(m4)))
cat(sprintf("RESULT:n_obs_barangay_table1_cols1_2=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_barangay_akbayan_table1_col3=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_barangay_umalabka_table1_col4=%d\n", nobs(m4)))
cat(sprintf("RESULT:itt_poverty_index_akbayan_tableC3=%.4f\n", res[["Akbayan"]][["pov"]]))
cat(sprintf("RESULT:itt_poverty_index_umalabka_tableC3=%.4f\n", res[["Umalab Ka"]][["pov"]]))
cat(sprintf("RESULT:itt_gender_index_akbayan_tableC4=%.4f\n", res[["Akbayan"]][["gen"]]))
cat(sprintf("RESULT:itt_gender_index_umalabka_tableC4=%.4f\n", res[["Umalab Ka"]][["gen"]]))
cat(sprintf("RESULT:itt_vote_overall_unweighted_tableF1_col2=%.4f\n", coef(f2)))
cat(sprintf("RESULT:itt_vote_akbayan_unweighted_tableF1_col3=%.4f\n", coef(f3)))
