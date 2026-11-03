suppressPackageStartupMessages({
  library(haven)
  library(survival)
  library(sandwich)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

load_data <- function(f) {
  d <- haven::read_dta(file.path(base_dir, f))
  d <- as.data.frame(d)
  for (v in names(d)) {
    if (inherits(d[[v]], "haven_labelled")) {
      lab <- attr(d[[v]], "labels")
      if (is.character(d[[v]])) d[[v]] <- as.character(haven::zap_labels(d[[v]]))
      else d[[v]] <- as.numeric(haven::zap_labels(d[[v]]))
    }
  }
  d
}

code_vote <- function(v) {
  if (is.numeric(v)) {
    u <- sort(unique(v[!is.na(v)]))
    if (all(u %in% c(0, 1))) return(v)
    # numeric with other codes: 1 = aye, everything else 0
    return(ifelse(is.na(v), NA, as.numeric(v == 1)))
  }
  s <- tolower(trimws(as.character(v)))
  out <- ifelse(s == "" | is.na(s), NA,
                as.numeric(grepl("^(aye|yea|yes|y|1)", s)))
  out
}

prep <- function(d) {
  d$y <- code_vote(d$vote)
  acu_var <- if ("acu" %in% names(d)) "acu" else "ncu"
  d$acu_x <- as.numeric(d[[acu_var]])
  d$sugcont <- as.numeric(d$sugcont)
  st <- if ("state_no" %in% names(d)) as.character(d$state_no) else as.character(d$state)
  d$dkey <- paste(st, as.character(d$district), sep = "_")
  cidc <- trimws(as.character(d$cid))
  nm <- trimws(as.character(d$name))
  cidc[is.na(cidc) | cidc == "" | cidc == "NA"] <- paste0("NM_", nm[is.na(cidc) | cidc == "" | cidc == "NA"])
  d$ikey <- cidc
  d
}

xvars <- c("sugcont", "acu_x", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

fit_clogit <- function(d, grp) {
  d$g <- d[[grp]]
  dd <- d[complete.cases(d[, c("y", xvars, "g")]), ]
  # keep groups with exactly one observation per congress? keep groups with variation
  tab <- tapply(dd$y, dd$g, function(z) length(unique(z)))
  keep <- names(tab)[tab > 1]
  dd <- dd[dd$g %in% keep, ]
  f <- as.formula(paste("y ~", paste(xvars, collapse = " + "), "+ strata(g)"))
  m <- tryCatch(
    survival::clogit(f, data = dd, method = "exact"),
    error = function(e) survival::clogit(f, data = dd, method = "efron")
  )
  list(model = m, n = nrow(dd), groups = length(unique(dd$g)))
}

incumbent_sample <- function(d) {
  cnt <- tapply(d$cong, d$ikey, function(z) length(unique(z)))
  n_obs <- table(d$ikey)
  ok <- names(cnt)[cnt == 2 & as.numeric(n_obs[names(cnt)]) == 2]
  s <- d[d$ikey %in% ok, ]
  s
}

run_all <- function(f) {
  d <- prep(load_data(f))
  dist <- fit_clogit(d, "dkey")
  inc <- fit_clogit(incumbent_sample(d), "ikey")
  list(dist = dist, inc = inc)
}

getc <- function(fit, v) {
  cf <- coef(fit$model)
  if (v %in% names(cf)) unname(cf[v]) else NA
}

base <- run_all("SugarReplicate.dta")
cal <- tryCatch(run_all("SugarReplicate_iter1.dta"), error = function(e) NULL)
m12 <- tryCatch(run_all("SugarReplicate_iter2.dta"), error = function(e) NULL)

cat("District FE model:\n"); print(summary(base$dist$model))
cat("Incumbent FE model:\n"); print(summary(base$inc$model))

fmt <- function(x) format(x, digits = 10, scientific = FALSE)

cat(paste0("RESULT:sugar_contributions_district_fe=", fmt(getc(base$dist, "sugcont")), "\n"))
cat(paste0("RESULT:sugar_contributions_incumbent_fe=", fmt(getc(base$inc, "sugcont")), "\n"))
cat(paste0("RESULT:acu_ideology_district_fe=", fmt(getc(base$dist, "acu_x")), "\n"))
cat(paste0("RESULT:tenure_district_fe=", fmt(getc(base$dist, "tenure")), "\n"))
cat(paste0("RESULT:tenure_incumbent_fe=", fmt(getc(base$inc, "tenure")), "\n"))
cat(paste0("RESULT:sugar_contributions_calendar_year_district_fe=",
           fmt(if (is.null(cal)) NA else getc(cal$dist, "sugcont")), "\n"))
cat(paste0("RESULT:sugar_contributions_calendar_year_incumbent_fe=",
           fmt(if (is.null(cal)) NA else getc(cal$inc, "sugcont")), "\n"))
cat(paste0("RESULT:sugar_contributions_12_months_district_fe=",
           fmt(if (is.null(m12)) NA else getc(m12$dist, "sugcont")), "\n"))
cat(paste0("RESULT:sugar_contributions_12_months_incumbent_fe=",
           fmt(if (is.null(m12)) NA else getc(m12$inc, "sugcont")), "\n"))
cat(paste0("RESULT:observations_district_fe=", base$dist$n, "\n"))
cat(paste0("RESULT:observations_incumbent_fe=", base$inc$n, "\n"))