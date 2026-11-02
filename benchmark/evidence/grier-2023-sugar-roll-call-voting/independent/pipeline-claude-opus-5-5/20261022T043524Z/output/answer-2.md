library(haven)
library(fixest)
library(survival)
set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

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
    # ICPSR-style coding: 1-3 yea, 4-6 nay, 7-9 not voting
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
  # incumbent key
  if (!is.null(d$cid) && any(!is.na(d$cid) & as.character(d$cid) != "")) {
    d$ikey <- as.character(d$cid)
  } else if (!is.null(d$name)) {
    d$ikey <- as.character(d$name)
  } else {
    d$ikey <- as.character(d$id)
  }
  d
}

# usable covariates: present and not mostly missing
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

# choose a district key that yields a non-empty switcher sample
choose_dkey <- function(d, covs) {
  cands <- list()
  for (nm in c("id", "stcd", "cd", "district_id", "distid")) {
    if (!is.null(d[[nm]])) cands[[nm]] <- as.character(d[[nm]])
  }
  if (!is.null(d$state) && !is.null(d$district))
    cands[["state_district"]] <- paste(d$state, d$district, sep = "_")
  best <- NULL; bestn <- -1
  for (nm in names(cands)) {
    d$dkey <- cands[[nm]]
    tab <- table(d$dkey)
    if (length(tab) < 50) next
    n <- nrow(switchers(d, "dkey", covs))
    cat("dkey candidate", nm, ": groups", length(tab), " max size", max(tab), " switcher obs", n, "\n")
    # prefer keys that look like districts (<= 2 obs per group per sample)
    score <- n + ifelse(max(tab) <= 2, 1e6, 0) * (n > 0)
    if (score > bestn) { bestn <- score; best <- nm }
  }
  if (is.null(best)) stop("No valid district key found")
  cat("Using dkey:", best, "\n")
  cands[[best]]
}

run_models <- function(file) {
  d <- prep(file)
  covs <- get_covs(d)
  cat("Covariates used:", paste(covs, collapse = ", "), "\n")
  fml_d <- as.formula(paste("y ~", paste(covs, collapse = " + "), "| dkey"))
  fml_i <- as.formula(paste("y ~", paste(covs, collapse = " + "), "| ikey"))
  d$dkey <- choose_dkey(d, covs)
  dd <- switchers(d, "dkey", covs)
  # incumbent sample: same incumbent in both votes
  if (!is.null(d$both)) {
    di <- d[!is.na(d$both) & d$both == 1, ]
    if (nrow(switchers(di, "ikey", covs)) == 0) di <- d
  } else {
    di <- d
  }
  di <- switchers(di, "ikey", covs)
  cat("District switcher obs:", nrow(dd), " Incumbent switcher obs:", nrow(di), "\n")
  md <- feglm(fml_d, data = dd, family = binomial("logit"), vcov = "hetero")
  mi <- feglm(fml_i, data = di, family = binomial("logit"), vcov = "hetero")
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

r1 <- tryCatch(run_models("SugarReplicate_iter1.dta"), error = function(e) { message(e$message); NULL })
r2 <- tryCatch(run_models("SugarReplicate_iter2.dta"), error = function(e) { message(e$message); NULL })

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
cat(sprintf("RESULT:observations_district_fe=%d\n", as.integer(nobs(main$md))))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", as.integer(nobs(main$mi))))
if (!is.null(main$cd)) cat(sprintf("RESULT:sugar_contributions_district_clogit=%.6g\n", unname(coef(main$cd)["sugcont"])))
if (!is.null(main$ci)) cat(sprintf("RESULT:sugar_contributions_incumbent_clogit=%.6g\n", unname(coef(main$ci)["sugcont"])))