suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

res <- list(
  mate_competition_table1_col1 = NA, mate_competition_table1_col2 = NA,
  mate_competition_table1_col3 = NA, mate_competition_table1_col4 = NA,
  mate_competition_table1_col5 = NA, mate_competition_table1_col6 = NA,
  job_competition_table1_col2 = NA, n_obs_table1_col1 = NA, n_obs_table1_col3 = NA,
  excess_males_sum_tableC1_col5 = NA, excess_males_annual_tableC1_col6 = NA,
  n_obs_sum_tableC1_col5 = NA, n_obs_annual_tableC1_col6 = NA
)
put <- function(n, v) res[[n]] <<- v

clean_df <- function(d) {
  d <- zap_missing(d)
  d <- zap_labels(d)
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  names(d) <- gsub("[^A-Za-z0-9_]", "_", names(d))
  d
}

# =========================== SURVEY: Table 1 ===========================
tryCatch({
  s <- clean_df(read_dta(file.path(base, "survey.dta")))
  cat("Survey columns:", paste(names(s), collapse = ", "), "\n")
  cat("Wave table:\n"); print(table(s$wave, useNA = "ifany"))

  y <- "hate_violence_means"
  mate <- "MateComp_cont"; job <- "JobComp_cont"; life <- "LifeSatis_cont"

  w4 <- s[!is.na(s$wave) & s$wave == 4, ]
  if (nrow(w4) == 0 || all(is.na(w4[[mate]]))) {
    wv <- max(s$wave[!is.na(s[[mate]])], na.rm = TRUE)
    w4 <- s[!is.na(s$wave) & s$wave == wv, ]
  }
  cat("Wave-4 rows:", nrow(w4), "\n")

  nms <- names(w4)
  low <- tolower(nms)
  pick <- function(pat, excl = NULL) {
    v <- nms[grepl(pat, low)]
    if (!is.null(excl)) v <- v[!grepl(excl, tolower(v))]
    v
  }
  first_exist <- function(cands) { x <- cands[cands %in% nms]; if (length(x)) x[1] else character(0) }

  # Sociodemographics
  age_v  <- first_exist(c("age", "age_group"))
  gen_v  <- first_exist(c("gender", "sex"))
  edu_v  <- first_exist(c("eduyrs", "education", "educ", "edu"))
  inc_v  <- first_exist(c("income"))
  occ_v  <- pick("^oc|occup|activ", "hate|list")
  emp_v  <- pick("^emp|employ", "unemp_|hate|list")
  cit_v  <- first_exist(c("citizenship"))
  hh_v   <- first_exist(c("household_size", "hhsize"))
  stat_v <- unique(c(first_exist(c("self_econ")), pick("status|social_stat|selfstat", "hate|list|marital")))
  rel_v  <- first_exist(c("religion", "relig"))
  st_v   <- first_exist(c("state"))
  socio <- unique(c(age_v, gen_v, edu_v, inc_v, occ_v, emp_v, cit_v, hh_v, stat_v, rel_v, st_v))
  socio_cat <- unique(c(gen_v, occ_v, emp_v, cit_v, rel_v, st_v))

  excl_common <- "hate|list|wave|res_id|women_role|gendergap|matecomp|jobcomp|lifesatis"
  add_pat <- "contact|shelter|close|distance|dist_|afd|lrscale|leftright|left_right|muslim|refugee_ind|num_ref|ref_num|number|howmany"
  addc <- setdiff(pick(add_pat, excl_common), socio)
  natl <- setdiff(pick("^ref_", paste0(excl_common, "|^ref_loc|_loc_|local")), c(addc, socio))
  locl <- setdiff(pick("^ref_loc|_loc_|local", excl_common), c(addc, socio, natl))

  cat("Socio:", paste(socio, collapse = ", "), "\n")
  cat("National:", paste(natl, collapse = ", "), "\n")
  cat("Local:", paste(locl, collapse = ", "), "\n")
  cat("Additional:", paste(addc, collapse = ", "), "\n")

  allv <- unique(c(y, mate, job, life, socio, natl, locl, addc))
  for (v in allv) {
    if (is.numeric(w4[[v]])) w4[[v]][!is.na(w4[[v]]) & w4[[v]] < 0] <- NA
  }

  fit <- function(vars) {
    vars <- unique(vars)
    d <- w4[, c(y, vars), drop = FALSE]
    d <- d[complete.cases(d), , drop = FALSE]
    keep <- c()
    for (v in vars) {
      if (v %in% socio_cat) {
        d[[v]] <- factor(d[[v]])
        if (nlevels(d[[v]]) >= 2) keep <- c(keep, v)
      } else {
        if (length(unique(d[[v]])) >= 2) keep <- c(keep, v)
      }
    }
    f <- as.formula(paste(y, "~", paste(paste0("`", keep, "`"), collapse = " + ")))
    m <- lm(f, data = d)
    list(m = m, n = nobs(m))
  }

  # cols 1-2 share the same sample (non-missing y, mate, job, life)
  d12 <- w4[complete.cases(w4[, c(y, mate, job, life)]), ]
  m1 <- lm(as.formula(paste(y, "~", mate)), data = d12)
  m2 <- lm(as.formula(paste(y, "~", mate, "+", job, "+", life)), data = d12)
  put("mate_competition_table1_col1", unname(coef(m1)[mate]))
  put("mate_competition_table1_col2", unname(coef(m2)[mate]))
  put("job_competition_table1_col2", unname(coef(m2)[job]))
  put("n_obs_table1_col1", nobs(m1))

  v3 <- c(mate, job, life, socio)
  v4 <- c(v3, natl); v5 <- c(v4, locl); v6 <- c(v5, addc)
  f3 <- fit(v3); f4 <- fit(v4); f5 <- fit(v5); f6 <- fit(v6)
  cat("N cols 3-6:", f3$n, f4$n, f5$n, f6$n, "\n")
  put("mate_competition_table1_col3", unname(coef(f3$m)[mate]))
  put("mate_competition_table1_col4", unname(coef(f4$m)[mate]))
  put("mate_competition_table1_col5", unname(coef(f5$m)[mate]))
  put("mate_competition_table1_col6", unname(coef(f6$m)[mate]))
  put("n_obs_table1_col3", f3$n)
}, error = function(e) cat("Survey section error:", conditionMessage(e), "\n"))

# =========================== ECOLOGICAL: Table C1 ===========================
tryCatch({
  ctx <- clean_df(read_dta(file.path(base, "context.dta")))
  cat("Context columns:", paste(names(ctx), collapse = ", "), "\n")
  nms <- names(ctx); low <- tolower(nms)

  idc <- nms[grepl("ags_muni|ags_gem|^ags$|gemeinde|ags_mun|^muni_id|^gkz", low)]
  if (length(idc) == 0) {
    ctx <- ctx %>% group_by(year) %>% mutate(.muni_id = row_number()) %>% ungroup() %>% as.data.frame()
    idv <- ".muni_id"
  } else idv <- idc[1]
  cat("Muni id:", idv, "\n")

  out <- nms[grepl("^hate_all", low)][1]
  if (is.na(out)) out <- nms[grepl("hate", low)][1]
  cat("Outcome:", out, "\n"); print(summary(ctx[[out]]))
  if (mean(is.na(ctx[[out]])) > 0.5 && !any(ctx[[out]] == 0, na.rm = TRUE)) ctx[[out]][is.na(ctx[[out]])] <- 0

  emc <- nms[grepl("gendergap", low) & grepl("15_44", low)]
  if (length(emc) > 0) {
    emv <- emc[1]
  } else {
    pop <- clean_df(read_dta(file.path(base, "pop_gemeinde_2008_2018.dta")))
    pop <- pop[pop$year == 2015, ]
    mc <- paste0("pop_m_", c("15_17", "18_19", "20_24", "25_29", "30_34", "35_39", "40_44"))
    fc <- sub("pop_m_", "pop_f_", mc)
    pop$em_calc <- rowSums(pop[, mc]) / rowSums(pop[, fc])
    pop <- pop[, c("ags_muni", "em_calc")]
    names(pop)[1] <- idv
    pop <- pop[!duplicated(pop[[idv]]), ]
    ctx <- left_join(ctx, pop, by = idv)
    emv <- "em_calc"
  }
  cat("Excess males var:", emv, "\n"); print(summary(ctx[[emv]]))

  excl <- c("year", "east", idv, out, emv)
  ctrl <- nms[!(nms %in% excl) &
                !grepl("^ags|hate|physical|arson|attack|placebo|pc_ref_male|count", low) &
                !(grepl("gendergap", low) & grepl("pop", low))]
  ctrl <- ctrl[sapply(ctx[ctrl], is.numeric)]
  ctrl <- ctrl[sapply(ctrl, function(v) mean(is.na(ctx[[v]])) < 0.5)]
  cat("Controls:", paste(ctrl, collapse = ", "), "\n")

  # Municipality-level (Sum) data: controls from 2015 row
  ctx <- ctx[order(ctx[[idv]], ctx$year), ]
  agg <- ctx %>% group_by(.data[[idv]]) %>%
    summarise(hate_sum = if (all(is.na(.data[[out]]))) NA_integer_ else as.integer(any(.data[[out]] > 0, na.rm = TRUE)),
              .groups = "drop")
  c15 <- ctx[ctx$year == 2015, ]
  if (nrow(c15) == 0) c15 <- ctx[!duplicated(ctx[[idv]]), ]
  c15 <- c15[!duplicated(c15[[idv]]), ]
  sumd <- inner_join(as.data.frame(agg), c15[, c(idv, "ags_state", "ags_county", emv, ctrl)], by = idv)

  qs <- quantile(sumd[[emv]], c(0.025, 0.975), na.rm = TRUE)
  cat("EM cutoffs:", qs, "\n")
  keep_ids <- sumd[[idv]][!is.na(sumd[[emv]]) & sumd[[emv]] >= qs[1] & sumd[[emv]] <= qs[2]]
  sumd <- sumd[sumd[[idv]] %in% keep_ids, ]
  sumd <- sumd[complete.cases(sumd[, c("hate_sum", emv, ctrl, "ags_state", "ags_county")]), ]

  rhs <- paste(c(emv, ctrl), collapse = " + ")
  m5 <- feglm(as.formula(paste("hate_sum ~", rhs, "| ags_state")), data = sumd,
              family = binomial(), cluster = ~ags_county)
  print(summary(m5))
  put("excess_males_sum_tableC1_col5", unname(coef(m5)[emv]))
  put("n_obs_sum_tableC1_col5", nobs(m5))

  # Annual panel
  ann <- ctx[ctx[[idv]] %in% keep_ids & ctx$year %in% 2015:2017, ]
  ann$hate_any <- as.integer(ann[[out]] > 0)
  ann <- ann[complete.cases(ann[, c("hate_any", emv, ctrl, "ags_state", "ags_county", "year")]), ]
  m6 <- feglm(as.formula(paste("hate_any ~", rhs, "| ags_state + year")), data = ann,
              family = binomial(), cluster = ~ags_county)
  print(summary(m6))
  put("excess_males_annual_tableC1_col6", unname(coef(m6)[emv]))
  put("n_obs_annual_tableC1_col6", nobs(m6))
}, error = function(e) cat("Ecological section error:", conditionMessage(e), "\n"))

for (n in names(res)) {
  v <- res[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
}
