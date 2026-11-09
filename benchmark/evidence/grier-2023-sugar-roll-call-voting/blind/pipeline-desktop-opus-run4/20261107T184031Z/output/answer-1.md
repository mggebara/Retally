suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survival)
  library(sandwich)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

load_data <- function(fname) {
  d <- haven::read_dta(file.path(base_dir, fname))
  d <- haven::zap_labels(d)
  as.data.frame(d)
}

# ---- outcome coding --------------------------------------------------------
code_vote <- function(v) {
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    out <- ifelse(grepl("^(aye|yes|yea|y)", s), 1,
           ifelse(grepl("^(no|nay|n$)", s), 0, NA))
    return(out)
  }
  v <- as.numeric(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(v == 1, 1, 0))  # assume 1 = aye, 2 = no
  # otherwise treat 1 as aye, 0 as no, anything else as missing
  ifelse(v == 1, 1, ifelse(v == 0, 0, NA))
}

# ---- district key ----------------------------------------------------------
make_district_key <- function(d) {
  # Prefer a variable that identifies a district uniquely within each Congress
  cand <- list()
  if ("id" %in% names(d)) cand[["id"]] <- as.character(d$id)
  if ("district" %in% names(d)) {
    cand[["district"]] <- as.character(d$district)
    if ("state" %in% names(d))
      cand[["state_district"]] <- paste(as.character(d$state), as.character(d$district), sep = "_")
    if ("state_no" %in% names(d))
      cand[["stateno_district"]] <- paste(as.character(d$state_no), as.character(d$district), sep = "_")
  }
  for (nm in names(cand)) {
    k <- cand[[nm]]
    uniq_within <- all(tapply(k, d$cong, function(x) !any(duplicated(x))))
    tab <- table(k)
    if (uniq_within && mean(tab == 2) > 0.9) {
      cat("District key used:", nm, "\n")
      return(k)
    }
  }
  # fallback
  k <- if ("state" %in% names(d)) paste(d$state, d$district, sep = "_") else as.character(d$district)
  cat("District key used: fallback state_district\n")
  k
}

controls <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

prep <- function(d) {
  d$aye <- code_vote(d$vote)
  d$dkey <- make_district_key(d)
  d$ikey <- as.character(d$cid)
  d$sugcont <- as.numeric(d$sugcont)
  d
}

fit_clogit <- function(d, group_var) {
  vars <- c("aye", "sugcont", controls, group_var)
  dd <- d[complete.cases(d[, vars]), vars]
  dd$g <- dd[[group_var]]
  # keep groups with exactly two obs and a switching outcome
  dd <- dd %>% group_by(g) %>%
    filter(n() == 2, length(unique(aye)) == 2) %>% ungroup() %>% as.data.frame()
  fml <- as.formula(paste("aye ~ sugcont +", paste(controls, collapse = " + "), "+ strata(g)"))
  m <- survival::clogit(fml, data = dd, method = "exact")
  list(model = m, nobs = nrow(dd), ngroups = length(unique(dd$g)))
}

safe_coef <- function(fit, v) {
  cf <- coef(fit$model)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

run_all <- function(d) {
  d <- prep(d)
  # district FE
  fd <- fit_clogit(d, "dkey")
  # incumbent FE: same incumbent in both years
  di <- d
  if ("both" %in% names(di)) {
    di_both <- di[!is.na(di$both) & di$both == 1, ]
    # sanity check: ensure each cid appears in both congresses
    if (nrow(di_both) > 0) di <- di_both
  }
  di <- di %>% group_by(ikey) %>% filter(length(unique(cong)) == 2) %>% ungroup() %>% as.data.frame()
  # incumbent must sit in the same district both times
  di <- di %>% group_by(ikey) %>% filter(length(unique(dkey)) == 1) %>% ungroup() %>% as.data.frame()
  fi <- fit_clogit(di, "ikey")
  list(d = fd, i = fi)
}

# ---- baseline --------------------------------------------------------------
main <- load_data("SugarReplicate.dta")
cat("Main data:", nrow(main), "rows\n")
print(table(main$vote, main$cong, useNA = "ifany"))
res_main <- run_all(main)
cat("\n--- District FE (Table 1 col 1) ---\n")
print(summary(res_main$d$model))
cat("Obs:", res_main$d$nobs, " groups:", res_main$d$ngroups, "\n")
cat("\n--- Incumbent FE (Table 1 col 2) ---\n")
print(summary(res_main$i$model))
cat("Obs:", res_main$i$nobs, " groups:", res_main$i$ngroups, "\n")

# ---- alternative windows (Table 3) -----------------------------------------
# iter1: calendar-year window; iter2: 12 months up to the vote date
it1 <- load_data("SugarReplicate_iter1.dta")
it2 <- load_data("SugarReplicate_iter2.dta")
res_it1 <- run_all(it1)
res_it2 <- run_all(it2)
cat("\n--- iter1 window ---\n")
print(coef(res_it1$d$model)); print(coef(res_it1$i$model))
cat("Obs:", res_it1$d$nobs, res_it1$i$nobs, "\n")
cat("\n--- iter2 window ---\n")
print(coef(res_it2$d$model)); print(coef(res_it2$i$model))
cat("Obs:", res_it2$d$nobs, res_it2$i$nobs, "\n")

fmt <- function(x) format(x, digits = 10, scientific = FALSE)

cat(sprintf("RESULT:sugar_contributions_district_fe=%s\n", fmt(safe_coef(res_main$d, "sugcont"))))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%s\n", fmt(safe_coef(res_main$i, "sugcont"))))
cat(sprintf("RESULT:acu_ideology_district_fe=%s\n", fmt(safe_coef(res_main$d, "ncu"))))
cat(sprintf("RESULT:tenure_district_fe=%s\n", fmt(safe_coef(res_main$d, "tenure"))))
cat(sprintf("RESULT:tenure_incumbent_fe=%s\n", fmt(safe_coef(res_main$i, "tenure"))))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%s\n", fmt(safe_coef(res_it1$d, "sugcont"))))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%s\n", fmt(safe_coef(res_it1$i, "sugcont"))))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%s\n", fmt(safe_coef(res_it2$d, "sugcont"))))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%s\n", fmt(safe_coef(res_it2$i, "sugcont"))))
cat(sprintf("RESULT:observations_district_fe=%d\n", as.integer(res_main$d$nobs)))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", as.integer(res_main$i$nobs)))
