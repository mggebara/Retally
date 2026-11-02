library(haven)
library(sandwich)

set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/grier_2023_sugar_roll_call_voting"

prep <- function(file, defl = 1.103) {
  d <- haven::read_dta(file.path(base, file))
  d <- haven::zap_labels(d)
  d <- as.data.frame(d)
  d$vote <- as.character(d$vote)
  d$yesvote <- ifelse(!is.na(d$vote) & d$vote == "Aye", 1, 0)
  d$cong <- as.numeric(d$cong)
  d$rsugcont <- d$totalcont
  idx <- !is.na(d$cong) & d$cong == 115
  d$rsugcont[idx] <- d$totalcont[idx] / defl
  d
}

vars <- c("yesvote", "rsugcont", "ncu", "tenure", "poverty", "bach",
          "medincome", "over65", "agcom", "id")

fit_fe_logit <- function(d) {
  d <- d[complete.cases(d[, vars]), vars]
  # Stata logit drops id dummies that perfectly predict outcome (no within-id variation)
  repeat {
    keep_ids <- tapply(d$yesvote, d$id, function(v) length(unique(v)) > 1)
    keep_ids <- names(keep_ids)[keep_ids]
    d2 <- d[as.character(d$id) %in% keep_ids, ]
    if (nrow(d2) == nrow(d)) break
    d <- d2
  }
  d$id <- factor(d$id)
  m <- glm(yesvote ~ rsugcont + ncu + tenure + poverty + bach + medincome +
             over65 + agcom + id,
           data = d, family = binomial(link = "logit"),
           control = glm.control(maxit = 200, epsilon = 1e-12))
  n <- nrow(d)
  V <- sandwich::vcovHC(m, type = "HC0") * n / (n - 1)
  se <- sqrt(diag(V))
  list(model = m, coef = coef(m), se = se, n = n)
}

# Main window
d0 <- prep("SugarReplicate.dta")
m_dist <- fit_fe_logit(d0)
m_inc <- fit_fe_logit(d0[!is.na(d0$both) & d0$both == 1, ])

# Calendar year window: deflate 2018 dollars to 2013 dollars using CPI-U annual ratio (251.107/232.957)
cpi_2018_2013 <- 251.107 / 232.957
cat(sprintf("DEVIATION: Calendar-year window (2013 vs 2018) contributions deflated with CPI-U annual ratio 2018/2013 = %.4f rather than the main-window factor 1.103\n", cpi_2018_2013))
d1 <- prep("SugarReplicate_iter1.dta", defl = cpi_2018_2013)
m1_dist <- fit_fe_logit(d1)
m1_inc <- fit_fe_logit(d1[!is.na(d1$both) & d1$both == 1, ])

# 12 months before vote window
d2 <- prep("SugarReplicate_iter2.dta")
m2_dist <- fit_fe_logit(d2)
m2_inc <- fit_fe_logit(d2[!is.na(d2$both) & d2$both == 1, ])

out <- function(name, val) cat(sprintf("RESULT:%s=%.8g\n", name, val))

out("sugar_contributions_district_fe", m_dist$coef["rsugcont"])
out("sugar_contributions_district_fe_se", m_dist$se["rsugcont"])
out("sugar_contributions_incumbent_fe", m_inc$coef["rsugcont"])
out("sugar_contributions_incumbent_fe_se", m_inc$se["rsugcont"])
out("acu_ideology_district_fe", m_dist$coef["ncu"])
out("tenure_district_fe", m_dist$coef["tenure"])
out("tenure_incumbent_fe", m_inc$coef["tenure"])
out("sugar_contributions_calendar_year_district_fe", m1_dist$coef["rsugcont"])
out("sugar_contributions_calendar_year_incumbent_fe", m1_inc$coef["rsugcont"])
out("sugar_contributions_12_months_district_fe", m2_dist$coef["rsugcont"])
out("sugar_contributions_12_months_incumbent_fe", m2_inc$coef["rsugcont"])
out("observations_district_fe", m_dist$n)
out("observations_incumbent_fe", m_inc$n)