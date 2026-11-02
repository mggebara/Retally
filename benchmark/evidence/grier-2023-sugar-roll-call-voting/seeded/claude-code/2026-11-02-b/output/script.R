suppressPackageStartupMessages({library(haven); library(fixest); library(dplyr)})
set.seed(42)
dd <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/seeded/2026-11-02-b/mount/grier_2023_sugar_roll_call_voting"
prep <- function(f) {
  d <- as.data.frame(read_dta(file.path(dd, f)))
  d$yesvote <- as.integer(!is.na(d$vote) & d$vote == "Aye")
  d$rsugcont <- ifelse(d$cong == 115, d$totalcont / 1.103, d$totalcont)
  d
}
fml <- yesvote ~ rsugcont + ncu + tenure + poverty + bach + medincome + over65 + agcom | id
fit <- function(d) feglm(fml, data = d, family = binomial("logit"), vcov = "hetero")
res <- list()
for (spec in list(c("SugarReplicate.dta", ""), c("SugarReplicate_iter1.dta", "calendar_year_"),
                  c("SugarReplicate_iter2.dta", "12_months_"))) {
  d <- prep(spec[1])
  m1 <- fit(d)
  m2 <- fit(d[!is.na(d$both) & d$both == 1, ])
  cat("==", spec[1], "\n"); print(etable(m1, m2, digits = 5))
  res[[paste0("sugar_contributions_", spec[2], "district_fe")]] <- coef(m1)[["rsugcont"]]
  res[[paste0("sugar_contributions_", spec[2], "incumbent_fe")]] <- coef(m2)[["rsugcont"]]
  if (spec[2] == "") {
    res$acu_ideology_district_fe <- coef(m1)[["ncu"]]
    res$tenure_district_fe <- coef(m1)[["tenure"]]
    res$tenure_incumbent_fe <- coef(m2)[["tenure"]]
    res$observations_district_fe <- nobs(m1)
    res$observations_incumbent_fe <- nobs(m2)
  }
}
for (n in names(res)) cat(sprintf("RESULT:%s=%.6g\n", n, res[[n]]))
