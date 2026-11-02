suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base_dir <- "/Users/matthew/dev/Retally/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

load_data <- function(f) {
  d <- haven::read_dta(file.path(base_dir, f))
  d <- as.data.frame(d)
  d
}

# ---- recode the vote into 1 = aye (reform), 0 = no ----
recode_vote <- function(v) {
  if (inherits(v, "haven_labelled")) {
    labs <- attr(v, "labels")
    vals <- as.numeric(v)
    if (!is.null(labs) && length(labs) > 0) {
      ln <- tolower(names(labs))
      out <- rep(NA_real_, length(vals))
      for (i in seq_along(labs)) {
        if (grepl("aye|yea|yes", ln[i])) out[vals == labs[i]] <- 1
        else if (grepl("^no|nay|^n$", ln[i])) out[vals == labs[i]] <- 0
      }
      # values not labelled but already 0/1
      unl <- is.na(out) & !is.na(vals) & vals %in% c(0, 1) & !(vals %in% labs)
      out[unl] <- vals[unl]
      if (sum(!is.na(out)) > 0) return(out)
    }
    v <- vals
  }
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    out <- ifelse(grepl("aye|yea|yes", s), 1, ifelse(grepl("^no|nay", s) | s == "n", 0,
                  suppressWarnings(as.numeric(s))))
    out[!(out %in% c(0, 1))] <- NA
    return(out)
  }
  v <- as.numeric(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(v == 1, 1, ifelse(v == 2, 0, NA)))
  out <- v
  out[!(out %in% c(0, 1))] <- NA
  out
}

num <- function(x) as.numeric(haven::zap_labels(x))

prep <- function(d) {
  d$y <- recode_vote(d$vote)
  for (v in c("sugcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")) {
    d[[v]] <- num(d[[v]])
  }
  st <- if ("state" %in% names(d)) as.character(haven::zap_labels(d$state)) else as.character(num(d$state_no))
  d$dist_id <- paste(st, as.character(haven::zap_labels(d$district)), sep = "_")
  # person identifier
  pid <- NULL
  for (cand in c("cid", "name", "id")) {
    if (cand %in% names(d)) {
      x <- as.character(haven::zap_labels(d[[cand]]))
      x[!is.na(x) & trimws(x) == ""] <- NA
      nu <- length(unique(x[!is.na(x)]))
      if (sum(!is.na(x)) > 0 && nu < sum(!is.na(x))) { pid <- x; break }
    }
  }
  if (is.null(pid)) pid <- as.character(haven::zap_labels(d$name))
  d$pid <- pid
  d
}

xvars <- c("sugcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

build_samples <- function(d) {
  cc <- d[complete.cases(d[, c("y", xvars)]), ]
  # district units with two votes that switched
  tab_n <- tapply(cc$y, cc$dist_id, length)
  tab_v <- tapply(cc$y, cc$dist_id, function(z) length(unique(z)))
  sw <- names(tab_n)[tab_n == 2 & tab_v == 2]
  ds <- cc[cc$dist_id %in% sw, ]
  # incumbent sample: same person in both votes in a switching district
  same <- tapply(ds$pid, ds$dist_id, function(z) length(unique(z)) == 1 && !any(is.na(z)))
  inc_d <- names(same)[same]
  is <- ds[ds$dist_id %in% inc_d, ]
  if (nrow(is) == 0 && "both" %in% names(ds)) {
    is <- ds[num(ds$both) == 1, ]
    tn <- table(is$dist_id); is <- is[is$dist_id %in% names(tn)[tn == 2], ]
  }
  is$inc_id <- if (all(!is.na(is$pid))) is$pid else is$dist_id
  list(dist = ds, inc = is)
}

fit_logit <- function(dat, fe) {
  dat$fe_f <- factor(dat[[fe]])
  f <- as.formula(paste("y ~", paste(xvars, collapse = " + "), "+ fe_f"))
  m <- suppressWarnings(glm(f, data = dat, family = binomial(link = "logit"),
                            control = glm.control(maxit = 200, epsilon = 1e-10)))
  vc <- tryCatch(sandwich::vcovHC(m, type = "HC0"), error = function(e) vcov(m))
  se <- sqrt(pmax(diag(vc), 0))
  m0 <- suppressWarnings(glm(y ~ 1, data = dat, family = binomial))
  pr2 <- 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0))
  list(model = m, coef = coef(m), se = se, n = nobs(m), pr2 = pr2)
}

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, format(signif(val, 8), scientific = FALSE)))
}

run_file <- function(f) {
  d <- prep(load_data(f))
  s <- build_samples(d)
  rd <- tryCatch(fit_logit(s$dist, "dist_id"), error = function(e) NULL)
  ri <- tryCatch(fit_logit(s$inc, "inc_id"), error = function(e) NULL)
  list(d = rd, i = ri, nd = nrow(s$dist), ni = nrow(s$inc))
}

# ---- Table 1 (baseline window) ----
main <- run_file("SugarReplicate.dta")
if (!is.null(main$d)) {
  cat("District FE logit:\n"); print(coeftest(main$d$model, vcov. = sandwich::vcovHC(main$d$model, type = "HC0"))[xvars, ])
  cat("Pseudo R2 (district):", main$d$pr2, "\n")
}
if (!is.null(main$i)) {
  cat("Incumbent FE logit:\n"); print(coeftest(main$i$model, vcov. = sandwich::vcovHC(main$i$model, type = "HC0"))[xvars, ])
  cat("Pseudo R2 (incumbent):", main$i$pr2, "\n")
}

# ---- Table 3 alternative windows ----
# DEVIATION: the alternative contribution windows are assumed to be stored in the
# iteration files: SugarReplicate_iter1.dta = calendar-year window,
# SugarReplicate_iter2.dta = 12 months before each vote.
cal <- tryCatch(run_file("SugarReplicate_iter1.dta"), error = function(e) NULL)
m12 <- tryCatch(run_file("SugarReplicate_iter2.dta"), error = function(e) NULL)

g <- function(r, v) if (is.null(r)) NA else unname(r$coef[v])

emit("sugar_contributions_district_fe", g(main$d, "sugcont"))
emit("sugar_contributions_incumbent_fe", g(main$i, "sugcont"))
emit("acu_ideology_district_fe", g(main$d, "ncu"))
emit("tenure_district_fe", g(main$d, "tenure"))
emit("tenure_incumbent_fe", g(main$i, "tenure"))
emit("sugar_contributions_calendar_year_district_fe", if (is.null(cal)) NA else g(cal$d, "sugcont"))
emit("sugar_contributions_calendar_year_incumbent_fe", if (is.null(cal)) NA else g(cal$i, "sugcont"))
emit("sugar_contributions_12_months_district_fe", if (is.null(m12)) NA else g(m12$d, "sugcont"))
emit("sugar_contributions_12_months_incumbent_fe", if (is.null(m12)) NA else g(m12$i, "sugcont"))
emit("observations_district_fe", if (is.null(main$d)) main$nd else main$d$n)
emit("observations_incumbent_fe", if (is.null(main$i)) main$ni else main$i$n)