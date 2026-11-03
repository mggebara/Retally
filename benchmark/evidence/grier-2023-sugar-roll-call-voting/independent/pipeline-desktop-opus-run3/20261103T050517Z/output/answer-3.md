suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(sandwich)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

# Paper: DV = 1 for an "aye" vote on the reform amendment, 0 otherwise
recode_vote <- function(v) {
  if (inherits(v, "haven_labelled")) {
    labs <- attr(v, "labels")
    vv <- as.numeric(v)
    if (!is.null(labs) && length(labs) > 0) {
      nm <- tolower(names(labs))
      yes_codes <- labs[grepl("aye|yes|yea|^y$|for", nm)]
      if (length(yes_codes) > 0) {
        out <- ifelse(is.na(vv), NA, ifelse(vv %in% yes_codes, 1, 0))
        return(out)
      }
    }
    v <- vv
  }
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    out <- ifelse(is.na(s) | s == "", NA,
                  ifelse(s %in% c("aye", "yes", "yea", "y", "1"), 1, 0))
    return(out)
  }
  v <- as.numeric(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  ifelse(is.na(v), NA, ifelse(v == 1, 1, 0))
}

getnum <- function(d, nm) {
  if (nm %in% names(d)) as.numeric(zap_labels(d[[nm]])) else rep(NA_real_, nrow(d))
}

# Pick the contribution measure: the paper uses REAL (deflated) sugar money over a
# window that differs across the robustness checks. Prefer a real-dollar variable
# and, for the robustness files, a variable named for that window, if present.
pick_contrib <- function(d, window = c("base", "cal", "m12")) {
  window <- match.arg(window)
  nms <- names(d)
  low <- tolower(nms)
  isnum <- vapply(d, function(x) is.numeric(zap_labels(x)), logical(1))
  cand <- nms[isnum & grepl("sug|contrib", low) & !grepl("anti", low)]
  cat(sprintf("NOTE: contribution candidates: %s\n", paste(cand, collapse = ", ")))
  if (length(cand) == 0) return("sugcont")
  cl <- tolower(cand)
  pick <- character(0)
  if (window == "cal") pick <- cand[grepl("cal|cy|year|yr", cl)]
  if (window == "m12") pick <- cand[grepl("12|month|mo|pre", cl)]
  if (length(pick) > 1) {
    rp <- pick[grepl("real|^r|defl|adj", tolower(pick))]
    if (length(rp) > 0) pick <- rp
  }
  if (length(pick) == 0) {
    rp <- cand[grepl("real|^r|defl|adj", cl)]
    if (window == "base") rp <- rp[!grepl("cal|cy|12|month|pre", tolower(rp))]
    pick <- rp
  }
  if (length(pick) == 0) pick <- if ("sugcont" %in% cand) "sugcont" else cand[1]
  pick[1]
}

prep <- function(path, window = "base") {
  d <- read_dta(path)
  acu_name <- if ("acu" %in% names(d)) "acu" else "ncu"
  cvar <- pick_contrib(d, window)
  cat(sprintf("NOTE: using contribution variable '%s' from %s\n", cvar, basename(path)))
  sug <- getnum(d, cvar)
  n_na_sug <- sum(is.na(sug))
  # members with no recorded sugar money: contributions are zero, not missing
  sug[is.na(sug)] <- 0
  df <- data.frame(
    vote = recode_vote(d$vote),
    sugcont = sug,
    acu = getnum(d, acu_name),
    tenure = getnum(d, "tenure"),
    poverty = getnum(d, "poverty"),
    bach = getnum(d, "bach"),
    medincome = getnum(d, "medincome"),
    over65 = getnum(d, "over65"),
    agcom = getnum(d, "agcom"),
    cong = getnum(d, "cong"),
    state = as.character(as_factor(d$state)),
    district = as.character(zap_labels(d$district)),
    cid = as.character(zap_labels(d$cid)),
    stringsAsFactors = FALSE
  )
  df$agcom[is.na(df$agcom)] <- 0
  attr(df, "n_na_sug") <- n_na_sug
  df$distid <- paste(df$state, df$district, sep = "_")
  if (all(table(paste(df$district, df$cong)) <= 1)) df$distid <- df$district
  df
}

fit_fe <- function(df, fe) {
  vars <- c("vote", "sugcont", "acu", "tenure", "poverty", "bach",
            "medincome", "over65", "agcom", fe)
  d <- df[complete.cases(df[, vars]), vars]
  d$fe_id <- d[[fe]]
  d <- d %>% group_by(fe_id) %>%
    filter(n() == 2, length(unique(vote)) == 2) %>% ungroup() %>% as.data.frame()
  fml <- vote ~ sugcont + acu + tenure + poverty + bach + medincome + over65 + agcom | fe_id
  m <- tryCatch(feglm(fml, data = d, family = binomial("logit"), vcov = "hetero"),
                error = function(e) NULL)
  if (!is.null(m)) {
    b <- coef(m)
    return(list(coef = b, n = nobs(m)))
  }
  g <- glm(vote ~ sugcont + acu + tenure + poverty + bach + medincome + over65 +
             agcom + factor(fe_id), data = d, family = binomial("logit"),
           control = glm.control(maxit = 200))
  list(coef = coef(g), n = nobs(g))
}

run_both <- function(path, window = "base") {
  df <- prep(path, window)
  dist <- fit_fe(df, "distid")
  inc_df <- df %>% filter(!is.na(cid), cid != "") %>%
    group_by(cid) %>% filter(n_distinct(cong) == 2) %>% ungroup() %>% as.data.frame()
  inc <- fit_fe(inc_df, "cid")
  list(dist = dist, inc = inc, n_na_sug = attr(df, "n_na_sug"))
}

out <- function(name, val) cat(sprintf("RESULT:%s=%.8g\n", name, as.numeric(val)))

base <- run_both(file.path(base_dir, "SugarReplicate.dta"), "base")
cat(sprintf("DEVIATION: Coded missing sugar contributions (%d rows) as $0 and missing Ag committee as 0, and coded non-aye votes (no / not voting) as 0, following the paper's 'aye = 1, 0 otherwise' DV definition\n", base$n_na_sug))
cat("DEVIATION: Contribution variable chosen by name heuristics (real-dollar / window-specific variable preferred when present, else sugcont)\n")
out("sugar_contributions_district_fe", base$dist$coef["sugcont"])
out("sugar_contributions_incumbent_fe", base$inc$coef["sugcont"])
out("acu_ideology_district_fe", base$dist$coef["acu"])
out("tenure_district_fe", base$dist$coef["tenure"])
out("tenure_incumbent_fe", base$inc$coef["tenure"])

cal <- tryCatch(run_both(file.path(base_dir, "SugarReplicate_iter1.dta"), "cal"), error = function(e) NULL)
if (!is.null(cal)) {
  out("sugar_contributions_calendar_year_district_fe", cal$dist$coef["sugcont"])
  out("sugar_contributions_calendar_year_incumbent_fe", cal$inc$coef["sugcont"])
}
m12 <- tryCatch(run_both(file.path(base_dir, "SugarReplicate_iter2.dta"), "m12"), error = function(e) NULL)
if (!is.null(m12)) {
  out("sugar_contributions_12_months_district_fe", m12$dist$coef["sugcont"])
  out("sugar_contributions_12_months_incumbent_fe", m12$inc$coef["sugcont"])
}

out("observations_district_fe", base$dist$n)
out("observations_incumbent_fe", base$inc$n)
