library(haven)
library(fixest)
library(survival)
set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

prep <- function(file) {
  d <- as.data.frame(zap_labels(read_dta(file.path(base, file))))
  y <- suppressWarnings(as.numeric(d$vote))
  vals <- sort(unique(y[!is.na(y)]))
  if (!all(vals %in% c(0, 1))) {
    # fallback: treat value 1 as aye, everything else no
    y <- ifelse(is.na(y), NA, as.numeric(y == 1))
  }
  d$y <- y
  # district key
  tab <- table(d$id)
  if (!is.null(d$id) && max(tab) <= 2 && length(tab) >= 400 && length(tab) <= 450) {
    d$dkey <- as.character(d$id)
  } else {
    d$dkey <- paste(d$state, d$district, sep = "_")
  }
  # incumbent key
  if (!is.null(d$cid) && any(!is.na(d$cid) & as.character(d$cid) != "")) {
    d$ikey <- as.character(d$cid)
  } else {
    d$ikey <- as.character(d$name)
  }
  d
}

covs <- c("sugcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")
fml_d <- as.formula(paste("y ~", paste(covs, collapse = " + "), "| dkey"))
fml_i <- as.formula(paste("y ~", paste(covs, collapse = " + "), "| ikey"))

switchers <- function(d, key) {
  d <- d[complete.cases(d[, c("y", covs, key)]), ]
  v <- tapply(d$y, d[[key]], function(z) length(unique(z)) > 1 & length(z) == 2)
  keep <- names(v)[v]
  d[d[[key]] %in% keep, ]
}

run_models <- function(file) {
  d <- prep(file)
  dd <- switchers(d, "dkey")
  # incumbent sample: same incumbent in both votes
  if (!is.null(d$both)) {
    di <- d[!is.na(d$both) & d$both == 1, ]
  } else {
    cnt <- table(d$ikey[!is.na(d$y)])
    di <- d[d$ikey %in% names(cnt)[cnt == 2], ]
  }
  di <- switchers(di, "ikey")
  md <- feglm(fml_d, data = dd, family = binomial("logit"), vcov = "hetero")
  mi <- feglm(fml_i, data = di, family = binomial("logit"), vcov = "hetero")
  # conditional logit alternative (for reference)
  cd <- tryCatch(clogit(as.formula(paste("y ~", paste(covs, collapse = " + "), "+ strata(dkey)")),
                        data = dd, robust = TRUE), error = function(e) NULL)
  ci <- tryCatch(clogit(as.formula(paste("y ~", paste(covs, collapse = " + "), "+ strata(ikey)")),
                        data = di, robust = TRUE), error = function(e) NULL)
  list(md = md, mi = mi, cd = cd, ci = ci, nd = nrow(dd), ni = nrow(di))
}

main <- run_models("SugarReplicate.dta")
print(summary(main$md)); print(summary(main$mi))
if (!is.null(main$cd)) print(summary(main$cd))
if (!is.null(main$ci)) print(summary(main$ci))

r1 <- tryCatch(run_models("SugarReplicate_iter1.dta"), error = function(e) NULL)
r2 <- tryCatch(run_models("SugarReplicate_iter2.dta"), error = function(e) NULL)

cf <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

cat(sprintf("RESULT:sugar_contributions_district_fe=%.6g\n", cf(main$md, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_district_fe_se=%.6g\n", se(main$md, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.6g\n", cf(main$mi, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe_se=%.6g\n", se(main$mi, "sugcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6g\n", cf(main$md, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.6g\n", cf(main$md, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6g\n", cf(main$mi, "tenure")))
if (!is.null(r1)) {
  cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.6g\n", cf(r1$md, "sugcont")))
  cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.6g\n", cf(r1$mi, "sugcont")))
}
if (!is.null(r2)) {
  cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.6g\n", cf(r2$md, "sugcont")))
  cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.6g\n", cf(r2$mi, "sugcont")))
}
cat(sprintf("RESULT:observations_district_fe=%d\n", nobs(main$md)))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", nobs(main$mi)))
if (!is.null(main$cd)) cat(sprintf("RESULT:sugar_contributions_district_clogit=%.6g\n", unname(coef(main$cd)["sugcont"])))
if (!is.null(main$ci)) cat(sprintf("RESULT:sugar_contributions_incumbent_clogit=%.6g\n", unname(coef(main$ci)["sugcont"])))