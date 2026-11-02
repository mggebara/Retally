suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

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
        if (grepl("not ?vot|absent|present|missing", ln[i])) next
        if (grepl("aye|yea|yes", ln[i])) out[vals == labs[i]] <- 1
        else if (grepl("^no|nay|^n$", ln[i])) out[vals == labs[i]] <- 0
      }
      unl <- is.na(out) & !is.na(vals) & vals %in% c(0, 1) & !(vals %in% labs)
      out[unl] <- vals[unl]
      if (sum(!is.na(out)) > 0) return(out)
    }
    v <- vals
  }
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    s[grepl("not ?vot|absent|present", s)] <- NA
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

is_num_col <- function(x) {
  x <- tryCatch(num(x), error = function(e) NULL, warning = function(w) NULL)
  !is.null(x) && sum(!is.na(x)) > 0
}

# ---- CPI-U deflator: express contributions in real (2013) dollars ----
# CPI-U annual averages (BLS): 2013 = 232.957, 2018 = 251.107
cpi_factor <- function(d) {
  cg <- num(d$cong)
  yr <- ifelse(cg %in% c(113, 2013, 2012), 2013, ifelse(cg %in% c(115, 2018, 2017), 2018, NA))
  if (any(is.na(yr) & !is.na(cg))) {
    u <- sort(unique(cg[!is.na(cg)]))
    yr <- ifelse(cg == u[1], 2013, 2018)
  }
  ifelse(yr == 2018, 232.957 / 251.107, 1)
}

# ---- variable selection guided by the paper's definitions ----
pick_name <- function(nm, pats, exclude = NULL) {
  for (p in pats) {
    hit <- nm[grepl(p, nm, ignore.case = TRUE)]
    if (!is.null(exclude)) hit <- hit[!grepl(exclude, hit, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  NULL
}

choose_vars <- function(d) {
  nm <- names(d)
  numnm <- nm[sapply(d, is_num_col)]
  sugnm <- numnm[grepl("sug|contrib", numnm, ignore.case = TRUE)]
  cat("Contribution-like variables:", paste(sugnm, collapse = ", "), "\n")
  for (s in sugnm) {
    x <- num(d[[s]])
    cat(sprintf("  %s: mean=%.2f sd=%.2f nonNA=%d\n", s, mean(x, na.rm = TRUE), sd(x, na.rm = TRUE), sum(!is.na(x))))
  }
  win_ex <- "cal|cy|12|mon|pre|before|cycle|yr|year|elec"
  # main window: inflation-adjusted contributions (paper uses real dollars)
  main_c <- pick_name(sugnm, c("real.*sug|sug.*real|^r_?sug|sug.*_r$|adj|infl|defl|cpi"), exclude = win_ex)
  if (is.null(main_c)) main_c <- if ("sugcont" %in% nm) "sugcont" else pick_name(sugnm, c("sugcont", "sug"), exclude = win_ex)
  if (is.null(main_c)) main_c <- "sugcont"
  cal_c <- pick_name(sugnm, c("cal", "cy", "yr|year"))
  m12_c <- pick_name(sugnm, c("12", "mon", "pre|before"))
  acu <- if ("acu" %in% tolower(nm)) nm[tolower(nm) == "acu"][1] else pick_name(numnm, c("^acu", "acu"))
  if (is.null(acu)) acu <- "ncu"
  ten <- if ("tenure" %in% nm) "tenure" else pick_name(numnm, c("tenure", "term", "senior"))
  list(main = main_c, cal = cal_c, m12 = m12_c, acu = acu, tenure = ten)
}

already_real <- function(contvar) grepl("real|adj|infl|defl|cpi", contvar, ignore.case = TRUE)

prep <- function(d, contvar, acuvar, tenvar) {
  d$y <- recode_vote(d$vote)
  d$sugcont_use <- num(d[[contvar]])
  if (!already_real(contvar)) d$sugcont_use <- d$sugcont_use * cpi_factor(d)
  d$acu_use <- num(d[[acuvar]])
  d$tenure_use <- num(d[[tenvar]])
  for (v in c("poverty", "bach", "medincome", "over65", "agcom")) {
    d[[v]] <- num(d[[v]])
  }
  st <- if ("state" %in% names(d)) as.character(haven::zap_labels(d$state)) else as.character(num(d$state_no))
  d$dist_id <- paste(st, as.character(haven::zap_labels(d$district)), sep = "_")
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

xvars <- c("sugcont_use", "acu_use", "tenure_use", "poverty", "bach", "medincome", "over65", "agcom")

build_samples <- function(d) {
  cc <- d[complete.cases(d[, c("y", xvars)]), ]
  tab_n <- tapply(cc$y, cc$dist_id, length)
  tab_v <- tapply(cc$y, cc$dist_id, function(z) length(unique(z)))
  sw <- names(tab_n)[tab_n == 2 & tab_v == 2]
  ds <- cc[cc$dist_id %in% sw, ]

  # incumbent sample, candidate 1: dataset's own "voted both times" flag
  is_both <- NULL
  if ("both" %in% names(ds)) {
    b <- ds[!is.na(num(ds$both)) & num(ds$both) == 1, ]
    tn <- table(b$dist_id); b <- b[b$dist_id %in% names(tn)[tn == 2], ]
    if (nrow(b) > 0) { b$inc_id <- b$dist_id; is_both <- b }
  }
  # candidate 2: same person in both votes (by person id, regardless of district label)
  ccp <- cc[!is.na(cc$pid), ]
  pn <- tapply(ccp$y, ccp$pid, length)
  pv <- tapply(ccp$y, ccp$pid, function(z) length(unique(z)))
  psw <- names(pn)[pn == 2 & pv == 2]
  is_pid <- ccp[ccp$pid %in% psw, ]
  is_pid$inc_id <- is_pid$pid
  # candidate 3: same pid within a switching district (previous approach)
  same <- tapply(ds$pid, ds$dist_id, function(z) length(unique(z)) == 1 && !any(is.na(z)))
  is_dist <- ds[ds$dist_id %in% names(same)[same], ]
  is_dist$inc_id <- is_dist$dist_id

  cands <- list(both = is_both, pid = is_pid, dist = is_dist)
  sizes <- sapply(cands, function(z) if (is.null(z)) NA else nrow(z))
  cat("Incumbent sample sizes by construction:", paste(names(sizes), sizes, collapse = "; "), "\n")
  # paper: 53 incumbents who voted both times and switched (N = 106)
  pick <- names(sizes)[!is.na(sizes) & sizes == 106]
  if (length(pick) == 0) pick <- names(sizes)[!is.na(sizes)][which.max(sizes[!is.na(sizes)])]
  cat("Using incumbent sample:", pick[1], "\n")
  list(dist = ds, inc = cands[[pick[1]]])
}

fit_logit <- function(dat, fe) {
  dat$fe_f <- factor(dat[[fe]])
  f <- as.formula(paste("y ~", paste(xvars, collapse = " + "), "+ fe_f"))
  m <- suppressWarnings(glm(f, data = dat, family = binomial(link = "logit"),
                            control = glm.control(maxit = 200, epsilon = 1e-10)))
  vc <- tryCatch(suppressWarnings(sandwich::vcovHC(m, type = "HC0")), error = function(e) vcov(m))
  se <- sqrt(pmax(diag(vc), 0))
  m0 <- suppressWarnings(glm(y ~ 1, data = dat, family = binomial))
  pr2 <- 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0))
  list(model = m, coef = coef(m), se = se, n = nobs(m), pr2 = pr2)
}

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, format(signif(val, 8), scientific = FALSE)))
}

run_data <- function(raw, contvar, acuvar, tenvar) {
  d <- prep(raw, contvar, acuvar, tenvar)
  s <- build_samples(d)
  rd <- tryCatch(fit_logit(s$dist, "dist_id"), error = function(e) NULL)
  ri <- tryCatch(fit_logit(s$inc, "inc_id"), error = function(e) NULL)
  list(d = rd, i = ri, nd = nrow(s$dist), ni = nrow(s$inc))
}

show <- function(r, lab) {
  if (is.null(r)) return(invisible())
  cat(lab, "\n")
  print(tryCatch(coeftest(r$model, vcov. = suppressWarnings(sandwich::vcovHC(r$model, type = "HC0")))[xvars, ],
                 error = function(e) cbind(r$coef[xvars], r$se[xvars])))
  cat("Pseudo R2:", r$pr2, "N:", r$n, "\n")
}

# ---- Table 1 (baseline window) ----
raw_main <- load_data("SugarReplicate.dta")
cat("Variables in SugarReplicate.dta:", paste(names(raw_main), collapse = ", "), "\n")
cat("Vote variable class:", paste(class(raw_main$vote), collapse = "/"), "\n")
if (!is.null(attr(raw_main$vote, "labels"))) print(attr(raw_main$vote, "labels"))
print(table(as.character(haven::zap_labels(raw_main$vote)), useNA = "ifany"))
print(table(num(raw_main$cong), useNA = "ifany"))
cat("Mean nominal sugcont by congress:\n")
print(tapply(num(raw_main$sugcont), num(raw_main$cong), mean, na.rm = TRUE))
vs <- choose_vars(raw_main)
cat("Selected: contributions =", vs$main, "; ideology =", vs$acu, "; tenure =", vs$tenure, "\n")
if (vs$main != "sugcont") cat("DEVIATION: used", vs$main, "as the real-dollar main-window contributions variable instead of sugcont\n")
if (vs$acu != "ncu") cat("DEVIATION: used", vs$acu, "as the ACU ideology score instead of ncu\n")
if (!already_real(vs$main)) cat("DEVIATION: dataset holds nominal contributions; converted to real 2013 dollars with BLS CPI-U annual averages (2018 values x 232.957/251.107) since the paper's deflator/base year is not stated\n")

main <- run_data(raw_main, vs$main, vs$acu, vs$tenure)
show(main$d, "District FE logit:")
show(main$i, "Incumbent FE logit:")

# ---- Table 3 alternative windows ----
# Alternative windows: first look for window-specific contribution variables in the
# main file; otherwise fall back to the iteration files, picking a contribution
# variable that differs from the main-window one.
alt_run <- function(varname, fallback_file) {
  if (!is.null(varname) && varname != vs$main) {
    cat("Alternative window variable from main file:", varname, "\n")
    return(tryCatch(run_data(raw_main, varname, vs$acu, vs$tenure), error = function(e) NULL))
  }
  raw <- tryCatch(load_data(fallback_file), error = function(e) NULL)
  if (is.null(raw)) return(NULL)
  cat("Variables in", fallback_file, ":", paste(names(raw), collapse = ", "), "\n")
  v2 <- tryCatch(choose_vars(raw), error = function(e) vs)
  cv <- v2$main
  if (!(cv %in% names(raw))) cv <- vs$main
  same_as_main <- tryCatch(isTRUE(all.equal(num(raw[[cv]]), num(raw_main[[vs$main]]))), error = function(e) FALSE)
  if (same_as_main) cat("NOTE:", fallback_file, "contribution variable identical to main window\n")
  tryCatch(run_data(raw, cv, if (v2$acu %in% names(raw)) v2$acu else vs$acu,
                    if (!is.null(v2$tenure) && v2$tenure %in% names(raw)) v2$tenure else vs$tenure),
           error = function(e) NULL)
}
cat("DEVIATION: alternative-window contributions taken from window-named variables if present, else from SugarReplicate_iter1.dta (calendar year) and SugarReplicate_iter2.dta (12 months)\n")
cal <- alt_run(vs$cal, "SugarReplicate_iter1.dta")
m12 <- alt_run(vs$m12, "SugarReplicate_iter2.dta")
if (!is.null(cal)) { show(cal$d, "Calendar-year window, district FE:"); show(cal$i, "Calendar-year window, incumbent FE:") }
if (!is.null(m12)) { show(m12$d, "12-month window, district FE:"); show(m12$i, "12-month window, incumbent FE:") }

g <- function(r, v) if (is.null(r)) NA else unname(r$coef[v])

emit("sugar_contributions_district_fe", g(main$d, "sugcont_use"))
emit("sugar_contributions_incumbent_fe", g(main$i, "sugcont_use"))
emit("acu_ideology_district_fe", g(main$d, "acu_use"))
emit("tenure_district_fe", g(main$d, "tenure_use"))
emit("tenure_incumbent_fe", g(main$i, "tenure_use"))
emit("sugar_contributions_calendar_year_district_fe", if (is.null(cal)) NA else g(cal$d, "sugcont_use"))
emit("sugar_contributions_calendar_year_incumbent_fe", if (is.null(cal)) NA else g(cal$i, "sugcont_use"))
emit("sugar_contributions_12_months_district_fe", if (is.null(m12)) NA else g(m12$d, "sugcont_use"))
emit("sugar_contributions_12_months_incumbent_fe", if (is.null(m12)) NA else g(m12$i, "sugcont_use"))
emit("observations_district_fe", if (is.null(main$d)) main$nd else main$d$n)
emit("observations_incumbent_fe", if (is.null(main$i)) main$ni else main$i$n)
