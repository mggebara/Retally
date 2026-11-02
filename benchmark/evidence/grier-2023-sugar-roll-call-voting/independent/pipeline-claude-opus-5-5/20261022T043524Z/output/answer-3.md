# Conditional logit replaces unconditional feglm (matches Stata clogit / xtlogit, fe);
# sugar contributions missing for members with no recorded sugar money are set to 0.
library(haven)
library(fixest)
library(survival)
set.seed(42)

base <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

covs_all <- c("sugcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

recode_vote <- function(v) {
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    y <- ifelse(s %in% c("yes", "yea", "aye", "y", "1"), 1,
                ifelse(s %in% c("no", "nay", "n", "0"), 0, NA))
    return(as.numeric(y))
  }
  y <- suppressWarnings(as.numeric(v))
  vals <- sort(unique(y[!is.na(y)]))
  if (all(vals %in% c(0, 1))) return(y)
  if (all(vals %in% 1:9) && max(vals) > 2) {
    return(ifelse(y <= 3, 1, ifelse(y <= 6, 0, NA)))
  }
  if (all(vals %in% c(1, 2))) return(ifelse(y == 1, 1, 0))
  ifelse(is.na(y), NA, as.numeric(y == 1))
}

prep <- function(file) {
  d <- as.data.frame(zap_labels(read_dta(file.path(base, file))))
  cat("File:", file, " vars:", paste(names(d), collapse = ", "), "\n")
  vcol <- intersect(c("vote", "Vote", "aye", "yea", "votes"), names(d))[1]
  d$y <- recode_vote(d[[vcol]])
  cat("y table:\n"); print(table(d$y, useNA = "ifany"))
  cat("Missingness among non-missing votes:\n")
  for (v in intersect(covs_all, names(d))) {
    cat(sprintf("  %s: %d NA\n", v, sum(is.na(d[[v]]) & !is.na(d$y))))
  }
  # Members with no recorded sugar-industry money should have zero contributions
  nmiss <- sum(is.na(d$sugcont) & !is.na(d$y))
  if (nmiss > 0) {
    cat('DEVIATION: Recoded missing sugcont to 0 (no recorded sugar contributions) for', nmiss, 'voting members\n')
    d$sugcont[is.na(d$sugcont)] <- 0
  }
  if (!is.null(d$cid) && any(!is.na(d$cid) & as.character(d$cid) != "")) {
    d$ikey <- as.character(d$cid)
  } else if (!is.null(d$name)) {
    d$ikey <- as.character(d$name)
  } else {
    d$ikey <- as.character(d$id)
  }
  d
}

get_covs <- function(d) {
  cv <- intersect(covs_all, names(d))
  cv <- cv[sapply(cv, function(v) mean(!is.na(suppressWarnings(as.numeric(d[[v]])))) > 0.5)]
  cv
}

switchers <- function(d, key, covs) {
  d <- d[!is.na(d[[key]]) & d[[key]] != "", ]
  d <- d[complete.cases(d[, c("y", covs)]), ]
  if (nrow(d) == 0) return(d)
  v <- tapply(d$y, d[[key]], function(z) length(unique(z)) > 1)
  keep <- names(v)[v]
  d[d[[key]] %in% keep, ]
}

run_models <- function(file) {
  d <- prep(file)
  covs <- get_covs(d)
  cat("Covariates used:", paste(covs, collapse = ", "), "\n")
  d$dkey <- as.character(d$id)
  dd <- switchers(d, "dkey", covs)
  if (!is.null(d$both)) {
    di <- d[!is.na(d$both) & d$both == 1, ]
    if (nrow(switchers(di, "ikey", covs)) == 0) di <- d
  } else {
    di <- d
  }
  di <- switchers(di, "ikey", covs)
  cat("District switcher obs:", nrow(dd), " Incumbent switcher obs:", nrow(di), "\n")
  rhs <- paste(covs, collapse = " + ")
  cd <- clogit(as.formula(paste("y ~", rhs, "+ strata(dkey)")), data = dd, robust = TRUE)
  ci <- clogit(as.formula(paste("y ~", rhs, "+ strata(ikey)")), data = di, robust = TRUE)
  md <- tryCatch(feglm(as.formula(paste("y ~", rhs, "| dkey")), data = dd,
                       family = binomial("logit"), vcov = "hetero"), error = function(e) NULL)
  mi <- tryCatch(feglm(as.formula(paste("y ~", rhs, "| ikey")), data = di,
                       family = binomial("logit"), vcov = "hetero"), error = function(e) NULL)
  list(md = md, mi = mi, cd = cd, ci = ci, nd = nrow(dd), ni = nrow(di))
}

main <- run_models("SugarReplicate.dta")
print(summary(main$cd)); print(summary(main$ci))

r1 <- tryCatch(run_models("SugarReplicate_iter1.dta"), error = function(e) { message(e$message); NULL })
r2 <- tryCatch(run_models("SugarReplicate_iter2.dta"), error = function(e) { message(e$message); NULL })

cf <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[match(v, names(coef(m)))])

cat(sprintf("RESULT:sugar_contributions_district_fe=%.6g\n", cf(main$cd, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_district_fe_se=%.6g\n", se(main$cd, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.6g\n", cf(main$ci, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe_se=%.6g\n", se(main$ci, "sugcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6g\n", cf(main$cd, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.6g\n", cf(main$cd, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6g\n", cf(main$ci, "tenure")))
if (!is.null(r1)) {
  cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.6g\n", cf(r1$cd, "sugcont")))
  cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.6g\n", cf(r1$ci, "sugcont")))
}
if (!is.null(r2)) {
  cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.6g\n", cf(r2$cd, "sugcont")))
  cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.6g\n", cf(r2$ci, "sugcont")))
}
cat(sprintf("RESULT:observations_district_fe=%d\n", as.integer(main$nd)))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", as.integer(main$ni)))
if (!is.null(main$md)) cat(sprintf("RESULT:sugar_contributions_district_feglm=%.6g\n", cf(main$md, "sugcont")))
if (!is.null(main$mi)) cat(sprintf("RESULT:sugar_contributions_incumbent_feglm=%.6g\n", cf(main$mi, "sugcont")))