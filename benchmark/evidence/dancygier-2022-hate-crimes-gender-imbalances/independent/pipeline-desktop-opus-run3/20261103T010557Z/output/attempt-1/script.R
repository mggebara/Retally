suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    results[[name]] <<- val
  }
}

num <- function(x) {
  x <- suppressWarnings(as.numeric(haven::zap_labels(x)))
  x[!is.na(x) & x < 0] <- NA
  x
}

pick <- function(nms, patterns, exclude = NULL) {
  for (p in patterns) {
    m <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) m <- m[!grepl(exclude, m, ignore.case = TRUE)]
    if (length(m) > 0) return(m[1])
  }
  NULL
}

## ------------------------------------------------------------------
## Part 1: Survey, Table 1
## ------------------------------------------------------------------
tryCatch({
  sv <- haven::read_dta(file.path(base, "survey.dta"))
  nms <- names(sv)
  cat("Survey columns:\n"); print(nms)

  sv <- sv[num(sv$wave) == 4 & !is.na(num(sv$wave)), ]
  cat("Wave 4 rows:", nrow(sv), "\n")

  d <- data.frame(
    y = num(sv$hate_violence_means),
    mate = num(sv[["MateComp.cont"]]),
    job = num(sv[["JobComp.cont"]]),
    life = num(sv[["LifeSatis.cont"]])
  )

  m1 <- lm(y ~ mate, data = d)
  m2 <- lm(y ~ mate + job + life, data = d)
  emit("mate_competition_table1_col1", unname(coef(m1)["mate"]))
  emit("mate_competition_table1_col2", unname(coef(m2)["mate"]))
  emit("job_competition_table1_col2", unname(coef(m2)["job"]))
  emit("n_obs_table1_col1", nobs(m2))

  # sociodemographics
  cat_vars <- c()
  num_vars <- c()
  addv <- function(v, type) {
    if (is.null(v) || !(v %in% nms)) return(invisible())
    if (type == "cat") cat_vars <<- unique(c(cat_vars, v)) else num_vars <<- unique(c(num_vars, v))
  }
  addv(pick(nms, c("^age$")), "num")
  addv(pick(nms, c("^gender$", "^female$", "^sex$")), "cat")
  addv(pick(nms, c("^eduyrs$", "^educ", "^edu")), "num")
  addv(pick(nms, c("^income$")), "num")
  addv(pick(nms, c("^occ", "econ_act", "activity")), "cat")
  addv(pick(nms, c("employ", "emp_stat", "^empl")), "cat")
  addv(pick(nms, c("^citizenship$")), "cat")
  addv(pick(nms, c("^household_size$", "hhsize", "household")), "num")
  addv(pick(nms, c("social_status", "soc_status", "status", "^self_econ$")), "num")
  addv(pick(nms, c("^religion$", "relig")), "cat")
  addv(pick(nms, c("^state$")), "cat")
  socio <- c(num_vars, cat_vars)
  cat("Sociodemographic controls:", socio, "\n")

  national <- grep("^ref_", nms, value = TRUE)
  national <- national[!grepl("^ref_loc", national)]
  if ("women_role" %in% nms) national <- c(national, "women_role")
  local <- grep("^ref_loc|loc_", nms, value = TRUE)
  local <- setdiff(local, national)
  additional <- unique(c(
    intersect(c("contact_ind", "refugee_ind", "muslim_ind", "lrscale"), nms),
    grep("afd", nms, value = TRUE, ignore.case = TRUE),
    grep("shelter|close|dist|num_ref|nref|estim", nms, value = TRUE, ignore.case = TRUE)
  ))
  additional <- setdiff(additional, c(socio, national, local, "MateComp.cont", "JobComp.cont",
                                      "LifeSatis.cont", "hate_violence_means"))
  additional <- additional[!grepl("gendergap|muni|hate_|list", additional)]
  cat("National:", national, "\nLocal:", local, "\nAdditional:", additional, "\n")

  allv <- unique(c(socio, national, local, additional))
  for (v in allv) {
    if (v %in% cat_vars) {
      d[[v]] <- factor(num(sv[[v]]))
    } else {
      d[[v]] <- num(sv[[v]])
    }
  }

  fit <- function(vars) {
    vars <- vars[vars %in% names(d)]
    # drop variables with no variation
    vars <- vars[sapply(vars, function(v) length(unique(na.omit(d[[v]]))) > 1)]
    f <- as.formula(paste("y ~ mate + job + life", if (length(vars)) paste("+", paste(paste0("`", vars, "`"), collapse = " + ")) else ""))
    lm(f, data = d)
  }
  m3 <- fit(socio)
  m4 <- fit(c(socio, national))
  m5 <- fit(c(socio, national, local))
  m6 <- fit(c(socio, national, local, additional))
  emit("mate_competition_table1_col3", unname(coef(m3)["mate"]))
  emit("mate_competition_table1_col4", unname(coef(m4)["mate"]))
  emit("mate_competition_table1_col5", unname(coef(m5)["mate"]))
  emit("mate_competition_table1_col6", unname(coef(m6)["mate"]))
  emit("n_obs_table1_col3", nobs(m3))
  cat("N cols 3-6:", nobs(m3), nobs(m4), nobs(m5), nobs(m6), "\n")
}, error = function(e) cat("Survey part error:", conditionMessage(e), "\n"))

## ------------------------------------------------------------------
## Part 2: Ecological, Table C1 cols 5-6
## ------------------------------------------------------------------
tryCatch({
  cx <- haven::read_dta(file.path(base, "context.dta"))
  nms <- names(cx)
  cat("Context columns:\n"); print(nms)

  idv <- pick(nms, c("^ags_muni$", "^ags_gem", "^ags$", "^ags_mun", "gemeinde", "^muni_id", "^id$"))
  exv <- pick(nms, c("15_44.*gendergap", "gendergap.*15_44", "excess", "sexratio", "sex_ratio", "gendergap_muni"),
              exclude = "unemp")
  yv <- pick(nms, c("^Hate_all_muni$", "hate_all"))
  cat("ID:", idv, " Excess:", exv, " Outcome:", yv, "\n")

  ctrl <- c(
    pick(nms, c("^log_pop.*muni", "^log_pop", "^population_muni_2015$", "^population_muni")),
    pick(nms, c("dens")),
    pick(nms, c("pop.*change", "change.*pop", "^d_pop", "pop_chg", "popchange", "pop_growth")),
    pick(nms, c("^log_unemp_all_muni", "unemp_all_muni", "^unemp_all")),
    pick(nms, c("^unemp_gendergap")),
    pick(nms, c("^log_ref", "log_refugee", "ref_stock", "^log_ref$", "^refugees"), exclude = "inflow|male"),
    pick(nms, c("log_ref_inflow", "inflow")),
    pick(nms, c("high_degree", "highedu", "high_educ", "educ", "abitur", "degree")),
    pick(nms, c("^pc_manufacturing")),
    pick(nms, c("^d_manuf")),
    pick(nms, c("afd")),
    pick(nms, c("violence_percap", "violen", "crime"))
  )
  # PCRE lookahead fallback (grep default doesn't support it)
  ctrl <- unique(ctrl[!is.na(ctrl)])
  if (!any(grepl("^log_ref", ctrl) & !grepl("inflow", ctrl))) {
    alt <- grep("^log_ref", nms, value = TRUE)
    alt <- alt[!grepl("inflow", alt)]
    if (length(alt)) ctrl <- unique(c(ctrl, alt[1]))
  }
  ctrl <- setdiff(ctrl, c(exv, yv, idv, "year", "ags_county", "ags_state"))
  cat("Controls:", ctrl, "\n")

  dd <- as.data.frame(lapply(cx[, unique(c("year", "ags_county", "ags_state", idv, exv, yv, ctrl))], num))
  if (is.null(idv)) {
    dd <- dd %>% group_by(year) %>% mutate(.mid = row_number()) %>% ungroup() %>% as.data.frame()
    idv <- ".mid"
  }
  dd <- dd[dd$year %in% c(2015, 2016, 2017), ]
  dd$ex <- dd[[exv]]
  dd$hate <- dd[[yv]]

  # trim extreme excess males (top/bottom 2.5%) at municipality level
  mu <- dd %>% group_by(.data[[idv]]) %>% summarise(ex = first(ex[!is.na(ex)]), .groups = "drop")
  q <- quantile(mu$ex, c(0.025, 0.975), na.rm = TRUE)
  cat("Trim bounds:", q, "\n")
  keep_ids <- mu[[idv]][!is.na(mu$ex) & mu$ex >= q[1] & mu$ex <= q[2]]
  dd <- dd[dd[[idv]] %in% keep_ids, ]

  rhs <- paste(c("ex", ctrl), collapse = " + ")

  # Annual
  dd$y_any <- as.integer(dd$hate > 0)
  fa <- as.formula(paste("y_any ~", rhs, "| ags_state + year"))
  ma <- feglm(fa, data = dd, family = binomial("logit"), cluster = ~ags_county)
  print(summary(ma))
  emit("excess_males_annual_tableC1_col6", unname(coef(ma)["ex"]))
  emit("n_obs_annual_tableC1_col6", nobs(ma))

  # Sum
  ds <- dd %>% group_by(.data[[idv]]) %>%
    summarise(hate_sum = sum(hate, na.rm = TRUE),
              hate_nonmiss = sum(!is.na(hate)),
              across(all_of(c("ex", ctrl, "ags_county", "ags_state")), ~ {
                v <- .x[dd$year[cur_group_rows()] == 2015]
                v <- v[!is.na(v)]
                if (length(v)) v[1] else { w <- .x[!is.na(.x)]; if (length(w)) w[1] else NA_real_ }
              }), .groups = "drop") %>% as.data.frame()
  ds$y_sum <- ifelse(ds$hate_nonmiss > 0, as.integer(ds$hate_sum > 0), NA_integer_)
  fs <- as.formula(paste("y_sum ~", rhs, "| ags_state"))
  ms <- feglm(fs, data = ds, family = binomial("logit"), cluster = ~ags_county)
  print(summary(ms))
  emit("excess_males_sum_tableC1_col5", unname(coef(ms)["ex"]))
  emit("n_obs_sum_tableC1_col5", nobs(ms))
}, error = function(e) cat("Ecological part error:", conditionMessage(e), "\n"))

for (n in names(results)) cat(sprintf("RESULT:%s=%.6f\n", n, results[[n]]))