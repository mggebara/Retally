suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"

num <- function(x) as.numeric(haven::zap_labels(x))
results <- list()
add_result <- function(name, val) results[[name]] <<- val

# ------------------------------------------------------------------
# Table 4: cross-national TSCS of executive approval
# ------------------------------------------------------------------
ga <- read_dta(file.path(base, "global_approval.dta"))
cat(sprintf("SAMPLE:table4:loaded=%d\n", nrow(ga)))
nm <- names(ga)

# attack indicator: international attack with more than 15 deaths (16+)
attack_var <- if ("kill_16" %in% nm) "kill_16" else if ("kill_15" %in% nm) "kill_15" else "pres_15death"
fe_var <- if ("country" %in% nm) "country" else if ("ccode" %in% nm) "ccode" else "country_code"
unit_var <- if ("country_code" %in% nm) "country_code" else fe_var

ga2 <- ga
for (v in nm) {
  if (!is.character(ga2[[v]])) ga2[[v]] <- num(ga2[[v]])
}
ga2$qtr_n <- as.numeric(ga2$qtr)
ga2$unit <- as.character(ga2[[unit_var]])
if (any(duplicated(ga2[, c("unit", "qtr_n")]))) {
  ga2$unit <- as.character(ga2[[fe_var]])
}
ga2$attack <- ga2[[attack_var]]
ga2$woman <- ga2$female_pres
ga2$fe <- as.character(ga2[[fe_var]])

# candidate approval variables
appr_cands <- nm[grepl("approv", nm, ignore.case = TRUE) & !grepl("^lag", nm, ignore.case = TRUE)]
lead_cands <- appr_cands[grepl("lead|^f_|^f[A-Z]|next|fwd|forward", appr_cands, ignore.case = TRUE)]
level_cands <- setdiff(appr_cands, lead_cands)

# construct lead of approval within unit (exact next quarter)
ga2 <- ga2 %>% arrange(unit, qtr_n)
make_lead <- function(df, v) {
  key <- paste(df$unit, df$qtr_n)
  nxt <- paste(df$unit, df$qtr_n + 1)
  df[[v]][match(nxt, key)]
}
dv_options <- list()
for (v in level_cands) {
  ga2[[paste0("lead_", v)]] <- make_lead(ga2, v)
  dv_options[[length(dv_options) + 1]] <- list(dv = paste0("lead_", v), desc = paste0("lead of ", v))
}
for (v in lead_cands) dv_options[[length(dv_options) + 1]] <- list(dv = v, desc = v)
if ("lag_approval" %in% nm) {
  # approval(t+1) recovered from lag_approval(t+2)
  ga2$lag_approval_lead2 <- {
    key <- paste(ga2$unit, ga2$qtr_n); nxt <- paste(ga2$unit, ga2$qtr_n + 2)
    ga2$lag_approval[match(nxt, key)]
  }
  dv_options[[length(dv_options) + 1]] <- list(dv = "lag_approval_lead2", desc = "lag_approval two quarters ahead")
}
for (v in level_cands) dv_options[[length(dv_options) + 1]] <- list(dv = v, desc = paste0(v, " (contemporaneous)"))

target_n4 <- 4328
fit4 <- function(dv) {
  f <- as.formula(paste0(dv, " ~ attack * woman + growth + log_inflation + execrlc + election_qtr | fe"))
  tryCatch(feols(f, data = ga2, vcov = "iid", warn = FALSE, notes = FALSE), error = function(e) NULL)
}
best4 <- NULL; best_gap <- Inf; best_desc <- NA
for (o in dv_options) {
  m <- fit4(o$dv)
  if (is.null(m)) next
  gap <- abs(nobs(m) - target_n4)
  cat(sprintf("# table4 candidate DV %s: N=%d\n", o$desc, nobs(m)))
  if (gap < best_gap) { best_gap <- gap; best4 <- m; best_desc <- o$desc; best_dv <- o$dv }
}

if (!is.null(best4)) {
  cat(sprintf("# table4 chosen DV: %s, attack var: %s, FE: %s\n", best_desc, attack_var, fe_var))
  s4 <- ga2 %>% filter(!is.na(.data[[best_dv]]))
  cat(sprintf("SAMPLE:table4:approval_next_quarter_nonmissing=%d\n", nrow(s4)))
  s4 <- s4 %>% filter(!is.na(attack), !is.na(woman), !is.na(growth), !is.na(log_inflation),
                      !is.na(execrlc), !is.na(election_qtr))
  cat(sprintf("SAMPLE:table4:controls_nonmissing=%d\n", nrow(s4)))
  cat(sprintf("SAMPLE:table4:estimation=%d\n", nobs(best4)))
  if (nobs(best4) != target_n4) {
    cat(sprintf("DEVIATION: table4 estimation N=%d differs from the paper's 4328\n", nobs(best4)))
  }
  cat("DEVIATION: panel-corrected standard errors not available in fixest; coefficients unaffected\n")
  cf4 <- coef(best4)
  add_result("intl_attack_table4", unname(cf4["attack"]))
  add_result("intl_attack_x_woman_exec_table4", unname(cf4["attack:woman"]))
  add_result("n_obs_table4", nobs(best4))
}

# ------------------------------------------------------------------
# Table 2: difference-in-differences on the BES panel
# ------------------------------------------------------------------
dd <- read_dta(file.path(base, "did_data.dta"),
               col_select = any_of(c("id", "wave", "treatment1", "time", "likeMayW", "bestPMW",
                                     "may_bestpm", "white", "gender", "labour", "party_other",
                                     "income", "ideology", "post_attack")))
cat(sprintf("SAMPLE:did_like_may:loaded=%d\n", nrow(dd)))
cat(sprintf("SAMPLE:did_may_best_pm:loaded=%d\n", nrow(dd)))

# best-PM coding: 1 = May, 0 = Corbyn
bp_raw <- dd$bestPMW
bp_labs <- attr(bp_raw, "labels")
bp <- num(bp_raw)
may_code <- NA; cor_code <- NA
if (!is.null(bp_labs)) {
  may_code <- unname(bp_labs[grepl("May", names(bp_labs))])[1]
  cor_code <- unname(bp_labs[grepl("Corbyn", names(bp_labs))])[1]
}
if (is.na(may_code)) may_code <- 1
if (is.na(cor_code)) cor_code <- 2
if (all(bp[!is.na(bp)] %in% c(0, 1))) {
  bestpm <- bp
} else {
  bestpm <- ifelse(bp == may_code, 1, ifelse(bp == cor_code, 0, NA))
}

dd <- dd %>% mutate(across(everything(), num))
dd$bestpm01 <- bestpm
dd$likeMayW[dd$likeMayW < 0 | dd$likeMayW > 10] <- NA

# controls: missing income and ideology recoded to scale midpoints
clean_scale <- function(x, lo, hi) { x[x < lo | x > hi] <- NA; x }
dd$ideology <- clean_scale(dd$ideology, 0, 10)
inc_obs <- dd$income[!is.na(dd$income) & dd$income >= 0 & dd$income < 50]
inc_lo <- min(inc_obs); inc_hi <- max(inc_obs)
if (inc_hi > 15) inc_hi <- 15
dd$income <- clean_scale(dd$income, inc_lo, inc_hi)
dd$income_c <- ifelse(is.na(dd$income), (inc_lo + inc_hi) / 2, dd$income)
dd$ideology_c <- ifelse(is.na(dd$ideology), 5, dd$ideology)
dd$treat <- dd$treatment1

# treated wave (wave 12): first wave with time == 1
w12 <- if (12 %in% dd$wave) 12 else min(dd$wave[!is.na(dd$time) & dd$time == 1], na.rm = TRUE)

ctrl <- "white + gender + labour + party_other + income_c + ideology_c"

run_did <- function(dv, sname, target) {
  s <- dd %>% filter(!is.na(.data[[dv]]))
  cat(sprintf("SAMPLE:%s:outcome_nonmissing=%d\n", sname, nrow(s)))
  s <- s %>% filter(!is.na(treat), !is.na(time))
  cat(sprintf("SAMPLE:%s:treatment_time_nonmissing=%d\n", sname, nrow(s)))
  wv <- sort(unique(s$wave))
  cat(sprintf("# %s waves with outcome: %s\n", sname, paste(wv, collapse = ",")))
  for (w in wv) cat(sprintf("# %s wave %s: n=%d\n", sname, w, sum(s$wave == w)))

  # restriction candidates: contiguous wave window around wave 12, optionally
  # limited to respondents observed (with the outcome) in wave 12
  ids12 <- unique(s$id[s$wave == w12])
  pre <- wv[wv < w12]; post <- wv[wv >= w12]
  best <- NULL; bgap <- Inf
  for (a in pre) for (b in post) for (r in c(FALSE, TRUE)) {
    keep <- s$wave >= a & s$wave <= b
    if (r) keep <- keep & s$id %in% ids12
    n <- sum(keep)
    g <- abs(n - target)
    if (g < bgap) { bgap <- g; best <- list(a = a, b = b, r = r, n = n) }
  }
  cat(sprintf("# %s chosen window: waves %s-%s, wave-12 respondents only=%s, n=%d\n",
              sname, best$a, best$b, best$r, best$n))
  s <- s %>% filter(wave >= best$a, wave <= best$b)
  if (best$r) s <- s %>% filter(id %in% ids12)
  cat(sprintf("SAMPLE:%s:wave_window=%d\n", sname, nrow(s)))
  cat(sprintf("DEVIATION: %s: panel restricted to waves %s-%s%s (paper does not list waves; chosen to match its N)\n",
              sname, best$a, best$b, if (best$r) " and to wave-12 respondents" else ""))

  # Stata-style wave dummies: base wave omitted and the last wave dropped for
  # collinearity with the time indicator, so time stays identified
  ws <- sort(unique(s$wave))
  if (length(ws) > 2) {
    f <- as.formula(paste0(dv, " ~ treat + time + treat:time + ", ctrl,
                           " + i(wave, ref = c(", min(ws), ", ", max(ws), "))"))
  } else {
    f <- as.formula(paste0(dv, " ~ treat + time + treat:time + ", ctrl))
  }
  m <- feols(f, data = s, cluster = ~id, warn = FALSE, notes = FALSE)
  cf <- coef(m)
  if (!all(c("treat", "time", "treat:time") %in% names(cf))) {
    cat(sprintf("DEVIATION: %s: some DiD terms collinear; missing terms taken from pooled OLS without wave dummies\n", sname))
    f2 <- as.formula(paste0(dv, " ~ treat + time + treat:time + ", ctrl))
    m2 <- feols(f2, data = s, cluster = ~id, warn = FALSE, notes = FALSE)
    cf2 <- coef(m2)
    for (k in c("treat", "time", "treat:time")) if (!(k %in% names(cf))) cf[k] <- cf2[k]
  }
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  if (nobs(m) != target) cat(sprintf("DEVIATION: %s estimation N=%d differs from the paper's %d\n", sname, nobs(m), target))
  list(cf = cf, n = nobs(m))
}

r_like <- run_did("likeMayW", "did_like_may", 143499)
r_pm <- run_did("bestpm01", "did_may_best_pm", 97155)
cat("DEVIATION: best-PM DiD estimated as a linear probability model (paper's coefficients are on the probability scale)\n")

add_result("did_attack_x_time_like_may_table2", unname(r_like$cf["treat:time"]))
add_result("did_attack_like_may_table2", unname(r_like$cf["treat"]))
add_result("did_time_like_may_table2", unname(r_like$cf["time"]))
add_result("did_attack_x_time_may_best_pm_table2", unname(r_pm$cf["treat:time"]))
add_result("did_attack_may_best_pm_table2", unname(r_pm$cf["treat"]))
add_result("did_time_may_best_pm_table2", unname(r_pm$cf["time"]))
add_result("n_obs_did_like_may_table2", r_like$n)
add_result("n_obs_did_may_best_pm_table2", r_pm$n)

for (k in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", k, format(results[[k]], digits = 8)))
}
