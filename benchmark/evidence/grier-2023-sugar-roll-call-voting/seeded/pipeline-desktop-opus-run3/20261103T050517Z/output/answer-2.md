suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting"

prep <- function(file) {
  d <- as.data.frame(haven::read_dta(file.path(base, file)))
  d <- haven::zap_labels(d)
  d$vote <- as.character(d$vote)
  d$yesvote <- ifelse(!is.na(d$vote) & d$vote == "Aye", 1, 0)
  d$cong <- as.numeric(d$cong)
  d$rsugcont <- as.numeric(d$totalcont)
  d$rsugcont[d$cong == 115 & !is.na(d$cong)] <- d$rsugcont[d$cong == 115 & !is.na(d$cong)] / 1.103
  for (v in c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom", "both")) {
    d[[v]] <- as.numeric(d[[v]])
  }
  d$id <- as.factor(d$id)
  vars <- c("yesvote", "rsugcont", "ncu", "tenure", "poverty", "bach",
            "medincome", "over65", "agcom", "id")
  d <- d[complete.cases(d[, vars]), ]
  d
}

fml <- yesvote ~ rsugcont + ncu + tenure + poverty + bach + medincome + over65 + agcom | id

fit <- function(d) {
  m <- tryCatch(
    feglm(fml, data = d, family = binomial("logit"), vcov = "hetero"),
    error = function(e) NULL
  )
  m
}

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.10g\n", name, val))
  }
}

get_coef <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

# Table 1
d0 <- prep("SugarReplicate.dta")
m1 <- fit(d0)
d0b <- d0[!is.na(d0$both) & d0$both == 1, ]
m2 <- fit(d0b)

if (!is.null(m1)) print(summary(m1))
if (!is.null(m2)) print(summary(m2))

# Table 3 row 1 (calendar year windows)
d1 <- prep("SugarReplicate_iter1.dta")
m3 <- fit(d1)
m4 <- fit(d1[!is.na(d1$both) & d1$both == 1, ])

# Table 3 row 2 (12 months before vote)
d2 <- prep("SugarReplicate_iter2.dta")
m5 <- fit(d2)
m6 <- fit(d2[!is.na(d2$both) & d2$both == 1, ])

emit("sugar_contributions_district_fe", get_coef(m1, "rsugcont"))
emit("sugar_contributions_incumbent_fe", get_coef(m2, "rsugcont"))
emit("acu_ideology_district_fe", get_coef(m1, "ncu"))
emit("tenure_district_fe", get_coef(m1, "tenure"))
emit("tenure_incumbent_fe", get_coef(m2, "tenure"))
emit("sugar_contributions_calendar_year_district_fe", get_coef(m3, "rsugcont"))
emit("sugar_contributions_calendar_year_incumbent_fe", get_coef(m4, "rsugcont"))
emit("sugar_contributions_12_months_district_fe", get_coef(m5, "rsugcont"))
emit("sugar_contributions_12_months_incumbent_fe", get_coef(m6, "rsugcont"))
if (!is.null(m1)) emit("observations_district_fe", nobs(m1))
if (!is.null(m2)) emit("observations_incumbent_fe", nobs(m2))
