suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

fmt <- function(x) if (is.null(x) || length(x) == 0 || is.na(x)) "NA" else format(as.numeric(x), digits = 10)

find1 <- function(nms, pats, exclude = character(0)) {
  cand <- setdiff(nms, exclude)
  for (p in pats) {
    hit <- grep(p, cand, ignore.case = TRUE, value = TRUE, perl = TRUE)
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
findall <- function(nms, pat, exclude = character(0)) {
  setdiff(grep(pat, nms, ignore.case = TRUE, value = TRUE, perl = TRUE), exclude)
}
has_var <- function(d, v) {
  x <- d[[v]]
  x <- x[!is.na(x)]
  length(unique(x)) > 1
}

res <- list()

## =================== Survey: Table 1 ===================
s <- tryCatch(read_dta(file.path(base_dir, "survey.dta")), error = function(e) NULL)
if (!is.null(s)) {
  s <- as.data.frame(zap_labels(s))
  names(s) <- make.names(names(s), unique = TRUE)
  nms <- names(s)
  cat("Survey columns:", paste(nms, collapse = ", "), "\n")

  wv <- if ("wave" %in% nms) s$wave else rep(4, nrow(s))
  target_wave <- if (any(wv == 4, na.rm = TRUE)) 4 else max(wv, na.rm = TRUE)
  w4 <- s[!is.na(wv) & wv == target_wave, , drop = FALSE]

  y    <- find1(nms, c("^hate_violence_means$", "violence_means", "only_?means"))
  mate <- find1(nms, c("^MateComp\\.cont$", "MateComp", "mate"))
  job  <- find1(nms, c("^JobComp\\.cont$", "JobComp", "job_?comp"))
  life <- find1(nms, c("^LifeSatis\\.cont$", "LifeSatis", "life"))

  used <- c(y, mate, job, life, "wave", "res_id", "east", "list", "treatment_list",
            "outcome_list", "hate_justified", "hate_pol_message", "hate_prevent_settlement",
            "hate_polcondemn", "women_role", "pop_15_44_muni_gendergap_2015", "marital",
            "singdivsep", "age_group")

  # Sociodemographics
  socio_num <- c(
    find1(nms, c("^age$")),
    find1(nms, c("^eduyrs$", "educ")),
    find1(nms, c("^income$", "income")),
    find1(nms, c("^household_size$", "household")),
    find1(nms, c("^self_econ$", "self_stat", "social_status", "status_self", "^self_"))
  )
  socio_fac <- c(
    find1(nms, c("^gender$", "^sex$", "gender")),
    find1(nms, c("^citizenship$")),
    find1(nms, c("^religion$", "relig")),
    find1(nms, c("^state$")),
    find1(nms, c("^occ", "^oc", "activity", "main_econ")),
    find1(nms, c("employ", "empstat", "emp_status", "^work"))
  )
  socio_num <- unique(socio_num[!is.na(socio_num)])
  socio_fac <- unique(setdiff(socio_fac[!is.na(socio_fac)], socio_num))

  # Attitudes toward refugees
  ref_local <- findall(nms, "^ref_loc", exclude = used)
  ref_nat   <- setdiff(findall(nms, "^ref_", exclude = used), ref_local)

  # Additional controls
  add <- c(
    findall(nms, "contact"),
    findall(nms, "shelter|close_ref|closeness|distance|dist_"),
    findall(nms, "^refugee_ind$|ref_number|num_ref|refugees_town|est_ref"),
    findall(nms, "afd"),
    findall(nms, "^lrscale$|lr_scale|leftright|left_right"),
    findall(nms, "muslim")
  )
  add <- unique(setdiff(add, c(used, socio_num, socio_fac, ref_nat, ref_local)))

  cat("Socio numeric:", paste(socio_num, collapse = ", "), "\n")
  cat("Socio factor:", paste(socio_fac, collapse = ", "), "\n")
  cat("Ref national:", paste(ref_nat, collapse = ", "), "\n")
  cat("Ref local:", paste(ref_local, collapse = ", "), "\n")
  cat("Additional:", paste(add, collapse = ", "), "\n")

  term <- function(v, fac = FALSE) if (fac) paste0("factor(", v, ")") else v

  run_ols <- function(vars_num, vars_fac) {
    allv <- c(y, vars_num, vars_fac)
    d <- w4[complete.cases(w4[, allv, drop = FALSE]), allv, drop = FALSE]
    vars_num <- vars_num[sapply(vars_num, function(v) has_var(d, v))]
    vars_fac <- vars_fac[sapply(vars_fac, function(v) has_var(d, v))]
    rhs <- c(sapply(vars_num, term), sapply(vars_fac, term, fac = TRUE))
    f <- as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
    m <- lm(f, data = d)
    m
  }

  if (!any(is.na(c(y, mate, job, life)))) {
    # Columns 1-2 on the common sample with all four variables non-missing
    base12 <- w4[complete.cases(w4[, c(y, mate, job, life)]), ]
    m1 <- lm(as.formula(paste(y, "~", mate)), data = base12)
    m2 <- lm(as.formula(paste(y, "~", mate, "+", job, "+", life)), data = base12)
    res$mate_competition_table1_col1 <- coef(m1)[mate]
    res$mate_competition_table1_col2 <- coef(m2)[mate]
    res$job_competition_table1_col2  <- coef(m2)[job]
    res$n_obs_table1_col1 <- nobs(m1)

    nums3 <- c(mate, job, life, socio_num)
    m3 <- tryCatch(run_ols(nums3, socio_fac), error = function(e) NULL)
    nums4 <- c(nums3, ref_nat)
    m4 <- tryCatch(run_ols(nums4, socio_fac), error = function(e) NULL)
    nums5 <- c(nums4, ref_local)
    m5 <- tryCatch(run_ols(nums5, socio_fac), error = function(e) NULL)
    nums6 <- c(nums5, add)
    m6 <- tryCatch(run_ols(nums6, socio_fac), error = function(e) NULL)

    getc <- function(m) if (is.null(m)) NA else coef(m)[mate]
    res$mate_competition_table1_col3 <- getc(m3)
    res$mate_competition_table1_col4 <- getc(m4)
    res$mate_competition_table1_col5 <- getc(m5)
    res$mate_competition_table1_col6 <- getc(m6)
    res$n_obs_table1_col3 <- if (is.null(m3)) NA else nobs(m3)
    for (m in list(m3, m4, m5, m6)) if (!is.null(m)) cat("N:", nobs(m), "\n")
  }
}

## =================== Ecological: SI Table C1 ===================
ctx <- tryCatch(read_dta(file.path(base_dir, "context.dta")), error = function(e) NULL)
if (!is.null(ctx)) {
  ctx <- as.data.frame(zap_labels(ctx))
  names(ctx) <- make.names(names(ctx), unique = TRUE)
  cn <- names(ctx)
  cat("Context columns:", paste(cn, collapse = ", "), "\n")

  outc <- find1(cn, c("^Hate_all_muni$", "^Hate_all", "hate"))
  em   <- find1(cn, c("15_44.*gendergap", "gendergap.*15_44", "excess.*15_44", "15_44"))
  muni <- find1(cn, c("^ags_muni$", "^ags_gem", "^ags$", "^ags_(?!county|state|dist)", "muni_id", "gemeinde"))
  cty  <- find1(cn, c("^ags_county$", "county"))
  st   <- find1(cn, c("^ags_state$", "state"))

  excl <- c(outc, em, muni, cty, st, "year", "east",
            findall(cn, "^Hate|^Physical|gendergap_\\d|placebo"))
  ctrl_pats <- list(
    c("^population_muni", "^log_pop", "^population"),
    c("dens"),
    c("pop.*(chg|change|growth|diff)", "^d_pop", "popchange"),
    c("^log_unemp_all", "unemp_all"),
    c("^unemp_gendergap", "unemp.*gap"),
    c("ref_stock", "stock", "^log_ref(?!_inflow)", "^refugees", "^log_refugee"),
    c("inflow", "ref_flow", "flow"),
    c("high", "educ"),
    c("^pc_manufacturing", "manufact"),
    c("^d_manuf", "d_.*manuf", "chg.*manuf"),
    c("afd"),
    c("violen", "crime")
  )
  ctrls <- character(0)
  for (p in ctrl_pats) {
    v <- find1(cn, p, exclude = c(excl, ctrls))
    if (!is.na(v) && v != em) ctrls <- c(ctrls, v)
  }
  ctrls <- unique(ctrls)
  cat("Outcome:", outc, " ExcessMales:", em, " Muni:", muni, "\n")
  cat("Controls:", paste(ctrls, collapse = ", "), "\n")

  if (!is.na(outc) && !is.na(em)) {
    if (is.na(muni)) {
      # fallback: identify municipality by county + excess males + population
      ctx$muni_tmp <- as.integer(factor(paste(ctx[[cty]], ctx[[em]],
                                              if ("population_muni_2015" %in% cn) ctx$population_muni_2015 else "")))
      muni <- "muni_tmp"
    }
    ctx$hate_bin <- as.integer(!is.na(ctx[[outc]]) & ctx[[outc]] > 0)
    ctx$hate_bin[is.na(ctx[[outc]])] <- NA

    # Trimming on municipality-level Excess Males distribution
    mlev <- ctx %>% group_by(across(all_of(muni))) %>%
      summarise(emv = first(.data[[em]][!is.na(.data[[em]])]), .groups = "drop")
    qs <- quantile(mlev$emv, c(0.025, 0.975), na.rm = TRUE)
    keep_ids <- mlev[[muni]][!is.na(mlev$emv) & mlev$emv >= qs[1] & mlev$emv <= qs[2]]
    ctx_t <- ctx[ctx[[muni]] %in% keep_ids, ]

    # Sum model: one row per municipality; covariates from 2015 (or first available)
    ctx_t <- ctx_t[order(ctx_t[[muni]], ctx_t$year), ]
    sumd <- ctx_t %>% group_by(across(all_of(muni))) %>%
      summarise(hate_any = if (all(is.na(hate_bin))) NA_integer_ else as.integer(max(hate_bin, na.rm = TRUE) > 0),
                across(all_of(unique(c(em, ctrls, cty, st))),
                       ~ { z <- .x[year == 2015]; z <- z[!is.na(z)]
                           if (length(z) == 0) { z <- .x[!is.na(.x)] }
                           if (length(z) == 0) NA else z[1] }),
                .groups = "drop")
    sumd <- as.data.frame(sumd)

    rhs <- paste(c(em, ctrls), collapse = " + ")
    fe_sum <- if (!is.na(st)) st else cty
    f_sum <- as.formula(paste("hate_any ~", rhs, "|", fe_sum))
    vars_sum <- c("hate_any", em, ctrls, fe_sum, cty)
    sumd_cc <- sumd[complete.cases(sumd[, unique(vars_sum)]), ]
    m_sum <- tryCatch(feglm(f_sum, data = sumd_cc, family = binomial("logit"),
                            cluster = as.formula(paste("~", cty))),
                      error = function(e) { cat("Sum error:", conditionMessage(e), "\n"); NULL })
    if (!is.null(m_sum)) {
      res$excess_males_sum_tableC1_col5 <- coef(m_sum)[em]
      res$n_obs_sum_tableC1_col5 <- nobs(m_sum)
    }

    # Annual model: municipality-years with state and year FE
    ann <- ctx_t[ctx_t$year %in% 2015:2017, ]
    vars_ann <- unique(c("hate_bin", em, ctrls, fe_sum, cty, "year"))
    ann_cc <- ann[complete.cases(ann[, vars_ann]), ]
    f_ann <- as.formula(paste("hate_bin ~", rhs, "|", fe_sum, "+ year"))
    m_ann <- tryCatch(feglm(f_ann, data = ann_cc, family = binomial("logit"),
                            cluster = as.formula(paste("~", cty))),
                      error = function(e) { cat("Annual error:", conditionMessage(e), "\n"); NULL })
    if (!is.null(m_ann)) {
      res$excess_males_annual_tableC1_col6 <- coef(m_ann)[em]
      res$n_obs_annual_tableC1_col6 <- nobs(m_ann)
    }
  }
}

out_names <- c("mate_competition_table1_col1", "mate_competition_table1_col2",
               "mate_competition_table1_col3", "mate_competition_table1_col4",
               "mate_competition_table1_col5", "mate_competition_table1_col6",
               "job_competition_table1_col2", "n_obs_table1_col1", "n_obs_table1_col3",
               "excess_males_sum_tableC1_col5", "excess_males_annual_tableC1_col6",
               "n_obs_sum_tableC1_col5", "n_obs_annual_tableC1_col6")
for (nm in out_names) cat(paste0("RESULT:", nm, "=", fmt(res[[nm]]), "\n"))