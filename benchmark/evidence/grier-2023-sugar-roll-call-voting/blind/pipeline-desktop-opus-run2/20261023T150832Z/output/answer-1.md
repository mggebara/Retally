suppressPackageStartupMessages({
  library(haven)
  library(survival)
  library(sandwich)
})
set.seed(42)

base_dir <- '/Users/matthew/dev/Retally/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free'

load_data <- function(fname) {
  d <- haven::read_dta(file.path(base_dir, fname))
  d <- as.data.frame(haven::zap_labels(d))
  names(d) <- tolower(names(d))
  d
}

recode_vote <- function(v) {
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    out <- ifelse(grepl("^(y|aye|yes|yea)", s), 1,
                  ifelse(grepl("^(n|no|nay)", s) & !grepl("^not", s), 0, NA))
    return(as.numeric(out))
  }
  v <- as.numeric(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(v == 1, 1, 0))
  v[!(v %in% c(0, 1))] <- NA
  v
}

make_keys <- function(d) {
  # district key: pick an identifier unique within congress
  cands <- list()
  if ("id" %in% names(d)) cands[["id"]] <- as.character(d$id)
  if (all(c("state", "district") %in% names(d)))
    cands[["state_district"]] <- paste(d$state, d$district, sep = "_")
  if (all(c("state_no", "district") %in% names(d)))
    cands[["stateno_district"]] <- paste(d$state_no, d$district, sep = "_")
  if ("district" %in% names(d)) cands[["district"]] <- as.character(d$district)
  best <- NULL; bestscore <- -Inf
  for (nm in names(cands)) {
    k <- cands[[nm]]
    dup <- sum(duplicated(paste(k, d$cong)))
    ng <- length(unique(k))
    # good key: no duplicates within congress, about 2 obs per key
    score <- -dup * 10 - abs(ng - 435)
    if (score > bestscore) { bestscore <- score; best <- nm }
  }
  d$dkey <- cands[[best]]
  if ("cid" %in% names(d) && any(!is.na(d$cid) & as.character(d$cid) != "")) {
    d$ikey <- as.character(d$cid)
    d$ikey[is.na(d$cid) | d$ikey == ""] <- NA
  } else {
    d$ikey <- as.character(d$name)
  }
  d
}

acu_var <- function(d) {
  if ("acu" %in% names(d)) return("acu")
  "ncu"
}

fit_clogit <- function(d, key, restrict_inc = FALSE) {
  acu <- acu_var(d)
  ctrls <- c(acu, "tenure", "poverty", "bach", "medincome", "over65", "agcom")
  vars <- c("y", "sugcont", ctrls, key)
  dd <- d
  if (restrict_inc) {
    # same member in both congresses (same district)
    dd <- dd[!is.na(dd$ikey), ]
    tab <- table(dd$ikey)
    dd <- dd[dd$ikey %in% names(tab)[tab == 2], ]
  }
  dd <- dd[complete.cases(dd[, vars]), ]
  dd$grp <- dd[[key]]
  # keep groups with exactly two obs and outcome variation
  g_n <- tapply(dd$y, dd$grp, length)
  g_v <- tapply(dd$y, dd$grp, function(z) length(unique(z)) > 1)
  keep <- names(g_v)[g_v & g_n >= 2]
  dd <- dd[dd$grp %in% keep, ]
  fml <- as.formula(paste("y ~ sugcont +", paste(ctrls, collapse = " + "), "+ strata(grp)"))
  m <- survival::clogit(fml, data = dd, method = "exact")
  list(model = m, n = nrow(dd), ngroups = length(unique(dd$grp)))
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("Error: ", conditionMessage(e)); NULL })

prep <- function(fname) {
  d <- load_data(fname)
  d$y <- recode_vote(d$vote)
  d <- make_keys(d)
  d
}

d0 <- prep("SugarReplicate.dta")
res_d <- safe(fit_clogit(d0, "dkey"))
res_i <- safe(fit_clogit(d0, "ikey", restrict_inc = TRUE))
if (!is.null(res_d)) print(summary(res_d$model))
if (!is.null(res_i)) print(summary(res_i$model))

d1 <- safe(prep("SugarReplicate_iter1.dta"))
d2 <- safe(prep("SugarReplicate_iter2.dta"))
res1_d <- if (!is.null(d1)) safe(fit_clogit(d1, "dkey")) else NULL
res1_i <- if (!is.null(d1)) safe(fit_clogit(d1, "ikey", restrict_inc = TRUE)) else NULL
res2_d <- if (!is.null(d2)) safe(fit_clogit(d2, "dkey")) else NULL
res2_i <- if (!is.null(d2)) safe(fit_clogit(d2, "ikey", restrict_inc = TRUE)) else NULL

getc <- function(r, v) {
  if (is.null(r)) return(NA)
  cf <- coef(r$model)
  if (v %in% names(cf)) unname(cf[v]) else NA
}

acu0 <- acu_var(d0)
fmt <- function(x) format(x, digits = 10, scientific = FALSE)

cat('RESULT:sugar_contributions_district_fe=', fmt(getc(res_d, "sugcont")), '\n', sep = '')
cat('RESULT:sugar_contributions_incumbent_fe=', fmt(getc(res_i, "sugcont")), '\n', sep = '')
cat('RESULT:acu_ideology_district_fe=', fmt(getc(res_d, acu0)), '\n', sep = '')
cat('RESULT:tenure_district_fe=', fmt(getc(res_d, "tenure")), '\n', sep = '')
cat('RESULT:tenure_incumbent_fe=', fmt(getc(res_i, "tenure")), '\n', sep = '')
cat('RESULT:sugar_contributions_calendar_year_district_fe=', fmt(getc(res1_d, "sugcont")), '\n', sep = '')
cat('RESULT:sugar_contributions_calendar_year_incumbent_fe=', fmt(getc(res1_i, "sugcont")), '\n', sep = '')
cat('RESULT:sugar_contributions_12_months_district_fe=', fmt(getc(res2_d, "sugcont")), '\n', sep = '')
cat('RESULT:sugar_contributions_12_months_incumbent_fe=', fmt(getc(res2_i, "sugcont")), '\n', sep = '')
cat('RESULT:observations_district_fe=', if (is.null(res_d)) NA else res_d$n, '\n', sep = '')
cat('RESULT:observations_incumbent_fe=', if (is.null(res_i)) NA else res_i$n, '\n', sep = '')
