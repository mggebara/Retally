suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
})

set.seed(42)

base <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting"

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as.character(haven::as_factor(x))
  as.character(x)
}
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  as.numeric(x)
}

prep <- function(file) {
  d <- as.data.frame(haven::read_dta(file.path(base, file)))
  vote <- trimws(to_chr(d$vote))
  d$yesvote <- ifelse(!is.na(vote) & vote == "Aye", 1, 0)
  cong <- to_num(d$cong)
  tc <- to_num(d$totalcont)
  d$rsugcont <- ifelse(!is.na(cong) & cong == 115, tc / 1.103, tc)
  for (v in c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom", "both", "id")) {
    d[[v]] <- to_num(d[[v]])
  }
  d
}

xvars <- c("rsugcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

fit_fe_logit <- function(d) {
  d <- d[complete.cases(d[, c("yesvote", xvars, "id")]), ]
  # Stata drops i.id dummies that perfectly predict the outcome (no within-id variation)
  m <- tapply(d$yesvote, d$id, mean)
  keep_ids <- as.numeric(names(m)[m > 0 & m < 1])
  d <- d[d$id %in% keep_ids, ]
  d$idf <- factor(d$id)
  f <- as.formula(paste("yesvote ~", paste(xvars, collapse = " + "), "+ idf"))
  fit <- suppressWarnings(glm(f, data = d, family = binomial(link = "logit"),
                              control = glm.control(epsilon = 1e-12, maxit = 200)))
  n <- nobs(fit)
  se <- tryCatch({
    V <- sandwich::vcovHC(fit, type = "HC0") * n / (n - 1)
    sqrt(diag(V))
  }, error = function(e) rep(NA, length(coef(fit))))
  list(fit = fit, n = n, se = se)
}

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.10g\n", name, val))
  }
}

# Table 1
d0 <- prep("SugarReplicate.dta")
r1 <- tryCatch(fit_fe_logit(d0), error = function(e) NULL)
r2 <- tryCatch(fit_fe_logit(d0[!is.na(d0$both) & d0$both == 1, ]), error = function(e) NULL)

# Table 3 row 1 (calendar year)
d1 <- prep("SugarReplicate_iter1.dta")
r3 <- tryCatch(fit_fe_logit(d1), error = function(e) NULL)
r4 <- tryCatch(fit_fe_logit(d1[!is.na(d1$both) & d1$both == 1, ]), error = function(e) NULL)

# Table 3 row 2 (12 months before vote)
d2 <- prep("SugarReplicate_iter2.dta")
r5 <- tryCatch(fit_fe_logit(d2), error = function(e) NULL)
r6 <- tryCatch(fit_fe_logit(d2[!is.na(d2$both) & d2$both == 1, ]), error = function(e) NULL)

cf <- function(r, v) if (is.null(r)) NA else unname(coef(r$fit)[v])

emit("sugar_contributions_district_fe", cf(r1, "rsugcont"))
emit("sugar_contributions_incumbent_fe", cf(r2, "rsugcont"))
emit("acu_ideology_district_fe", cf(r1, "ncu"))
emit("tenure_district_fe", cf(r1, "tenure"))
emit("tenure_incumbent_fe", cf(r2, "tenure"))
emit("sugar_contributions_calendar_year_district_fe", cf(r3, "rsugcont"))
emit("sugar_contributions_calendar_year_incumbent_fe", cf(r4, "rsugcont"))
emit("sugar_contributions_12_months_district_fe", cf(r5, "rsugcont"))
emit("sugar_contributions_12_months_incumbent_fe", cf(r6, "rsugcont"))
if (!is.null(r1)) emit("observations_district_fe", r1$n)
if (!is.null(r2)) emit("observations_incumbent_fe", r2$n)
