suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"
results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

to_num <- function(x) {
  x <- zap_missing(x)
  as.numeric(zap_labels(x))
}
to_fac <- function(x) {
  x <- zap_missing(x)
  if (is.labelled(x)) x <- as_factor(x, levels = "default")
  f <- factor(x)
  f
}

# ======================= SURVEY: TABLE 1 =======================
tryCatch({
  sv <- read_dta(file.path(base, "survey.dta"))
  nm <- names(sv)
  cat("Survey columns:", paste(nm, collapse = ", "), "\n")
  w <- to_num(sv$wave)
  if (!any(w == 4, na.rm = TRUE)) w4 <- w == max(w, na.rm = TRUE) else w4 <- w == 4
  d <- sv[which(w4), ]
  cat("Wave 4 rows:", nrow(d), "\n")

  pick <- function(pattern, exclude = character(0)) {
    out <- grep(pattern, names(d), value = TRUE, ignore.case = TRUE)
    setdiff(out, exclude)
  }

  df <- data.frame(y = to_num(d$hate_violence_means),
                   mate = to_num(d[["MateComp.cont"]]),
                   job = to_num(d[["JobComp.cont"]]),
                   life = to_num(d[["LifeSatis.cont"]]))

  used <- c("wave", "hate_violence_means", "MateComp.cont", "JobComp.cont", "LifeSatis.cont",
            "res_id", "list", "treatment_list", "outcome_list")

  # Sociodemographics
  num_soc <- c()
  fac_soc <- c()
  first_match <- function(pats) {
    for (p in pats) {
      m <- grep(p, names(d), value = TRUE, ignore.case = TRUE)
      m <- setdiff(m, used)
      if (length(m) > 0) return(m[1])
    }
    NA_character_
  }
  v_age <- first_match(c("^age$"))
  v_gender <- first_match(c("^gender$", "^sex$"))
  v_edu <- first_match(c("^eduyrs$", "^edu", "educ"))
  v_inc <- first_match(c("^income$", "income"))
  v_occ <- first_match(c("^occ", "activity"))
  v_emp <- first_match(c("employ", "^empl", "emp_status", "^work"))
  v_cit <- first_match(c("^citizenship$", "^citizen"))
  v_hh <- first_match(c("^household_size$", "household", "hhsize"))
  v_stat <- first_match(c("social_status", "^status", "self_status", "^self_econ$", "^self_"))
  v_rel <- first_match(c("^religion$", "relig"))
  v_state <- first_match(c("^state$", "bundesland"))
  num_soc <- na.omit(c(v_age, v_edu, v_inc, v_hh, v_stat))
  fac_soc <- na.omit(c(v_gender, v_occ, v_emp, v_cit, v_rel, v_state))
  num_soc <- unique(as.character(num_soc)); fac_soc <- unique(as.character(fac_soc))
  cat("Socio numeric:", paste(num_soc, collapse = ","), " factor:", paste(fac_soc, collapse = ","), "\n")
  used <- c(used, num_soc, fac_soc)

  # National and local refugee attitudes
  loc <- setdiff(grep("^ref_loc", names(d), value = TRUE), used)
  nat <- setdiff(grep("^ref_", names(d), value = TRUE), c(used, loc))
  used <- c(used, loc, nat)
  # Additional controls
  addl <- setdiff(grep("contact|shelter|clos|refugee_ind|num_ref|afd|lrscale|muslim",
                       names(d), value = TRUE, ignore.case = TRUE), used)
  cat("National:", paste(nat, collapse = ","), "\n")
  cat("Local:", paste(loc, collapse = ","), "\n")
  cat("Additional:", paste(addl, collapse = ","), "\n")

  safe <- function(v) paste0("v_", gsub("[^A-Za-z0-9_]", "_", v))
  for (v in num_soc) df[[safe(v)]] <- to_num(d[[v]])
  for (v in fac_soc) df[[safe(v)]] <- to_fac(d[[v]])
  for (v in c(nat, loc)) df[[safe(v)]] <- to_num(d[[v]])
  for (v in addl) {
    x <- d[[v]]
    xn <- to_num(x)
    nun <- length(unique(na.omit(xn)))
    if (is.labelled(x) && nun > 2 && nun <= 6 && grepl("afd|clos", v, ignore.case = TRUE)) {
      df[[safe(v)]] <- xn
    } else df[[safe(v)]] <- xn
  }

  soc_t <- c(safe(num_soc), safe(fac_soc))
  nat_t <- safe(nat); loc_t <- safe(loc); add_t <- safe(addl)

  f1 <- "y ~ mate"
  f2 <- "y ~ mate + job + life"
  rhs3 <- c("mate", "job", "life", soc_t)
  rhs4 <- c(rhs3, nat_t)
  rhs5 <- c(rhs4, loc_t)
  rhs6 <- c(rhs5, add_t)

  d12 <- df[complete.cases(df[, c("y", "mate", "job", "life")]), ]
  m1 <- lm(as.formula(f1), data = d12)
  m2 <- lm(as.formula(f2), data = d12)
  cat("Col1 N =", nobs(m1), "\n"); print(summary(m1)$coefficients)
  print(summary(m2)$coefficients)

  # Columns 3-6: keep the col-3 sample fixed if possible; otherwise use complete cases per model
  fit_cc <- function(rhs) {
    dd <- df[complete.cases(df[, c("y", rhs)]), ]
    # drop single-level factors
    keep <- sapply(rhs, function(r) {
      x <- dd[[r]]
      if (is.factor(x)) length(unique(droplevels(x))) > 1 else length(unique(x)) > 1
    })
    rhs <- rhs[keep]
    for (r in rhs) if (is.factor(dd[[r]])) dd[[r]] <- droplevels(dd[[r]])
    lm(as.formula(paste("y ~", paste(rhs, collapse = " + "))), data = dd)
  }
  m3 <- fit_cc(rhs3); m4 <- fit_cc(rhs4); m5 <- fit_cc(rhs5); m6 <- fit_cc(rhs6)
  for (m in list(m3, m4, m5, m6)) cat("N =", nobs(m), " mate =", coef(m)["mate"],
                                      " R2 =", summary(m)$r.squared, "\n")

  emit("mate_competition_table1_col1", unname(coef(m1)["mate"]))
  emit("mate_competition_table1_col2", unname(coef(m2)["mate"]))
  emit("mate_competition_table1_col3", unname(coef(m3)["mate"]))
  emit("mate_competition_table1_col4", unname(coef(m4)["mate"]))
  emit("mate_competition_table1_col5", unname(coef(m5)["mate"]))
  emit("mate_competition_table1_col6", unname(coef(m6)["mate"]))
  emit("job_competition_table1_col2", unname(coef(m2)["job"]))
  emit("n_obs_table1_col1", nobs(m1))
  emit("n_obs_table1_col3", nobs(m3))
}, error = function(e) cat("Survey section error:", conditionMessage(e), "\n"))

# ======================= CONTEXT: SI TABLE C1 =======================
tryCatch({
  cx <- read_dta(file.path(base, "context.dta"))
  nm <- names(cx)
  cat("Context columns:", paste(nm, collapse = ", "), "\n")

  # Excess males (15-44)
  em_c <- grep("15_44.*gendergap|gendergap.*15_44", nm, value = TRUE, ignore.case = TRUE)
  if (length(em_c) == 0) em_c <- grep("15_44", nm, value = TRUE)
  if (length(em_c) == 0) em_c <- grep("excess|sexratio|sex_ratio|mf_ratio", nm, value = TRUE, ignore.case = TRUE)
  em_c <- em_c[1]
  cat("Excess males var:", em_c, "\n")

  out_c <- grep("^Hate_all_muni$", nm, value = TRUE)
  if (length(out_c) == 0) out_c <- grep("^hate_all", nm, value = TRUE, ignore.case = TRUE)
  out_c <- out_c[1]

  id_c <- grep("^ags_muni$|^ags_gem|gemeinde|^ags$|^muni_id$|^ags_mun|^id_muni|^ags8|^gkz", nm,
               value = TRUE, ignore.case = TRUE)
  id_c <- if (length(id_c)) id_c[1] else NA

  cx$year_n <- to_num(cx$year)
  cx$county <- to_num(cx$ags_county)
  cx$state <- to_num(cx$ags_state)
  cx$em <- to_num(cx[[em_c]])
  cx$hate <- to_num(cx[[out_c]])

  # controls: all remaining numeric variables except ids/outcomes/alternative measures
  excl_pat <- "^year|^east$|^ags|hate|physical|arson|attack|gendergap.*(_[0-9]+_[0-9]+)|^pop_.*_[0-9]+_[0-9]+|placebo|^pc_ref_male$|location|name"
  ctrl <- setdiff(nm, c(em_c, out_c, id_c))
  ctrl <- ctrl[!grepl(excl_pat, ctrl, ignore.case = TRUE)]
  # but keep the unemployment gender gap (male disadvantage)
  ctrl <- unique(c(ctrl, grep("^unemp_gendergap", nm, value = TRUE)))
  ctrl <- ctrl[sapply(ctrl, function(v) {
    x <- suppressWarnings(to_num(cx[[v]])); is.numeric(x) && length(unique(na.omit(x))) > 2
  })]
  cat("Controls:", paste(ctrl, collapse = ", "), "\n")
  cs <- paste0("c_", gsub("[^A-Za-z0-9_]", "_", ctrl))
  for (i in seq_along(ctrl)) cx[[cs[i]]] <- to_num(cx[[ctrl[i]]])

  if (is.na(id_c)) {
    cx <- cx %>% group_by(year_n) %>% mutate(mid = row_number()) %>% ungroup()
  } else {
    cx$mid <- as.character(cx[[id_c]])
  }
  cx <- cx[cx$year_n %in% 2015:2017, ]

  # trimming: top and bottom 2.5% of excess males across municipalities
  mu <- cx %>% group_by(mid) %>% summarise(em = first(em[!is.na(em)]), .groups = "drop")
  q <- quantile(mu$em, c(0.025, 0.975), na.rm = TRUE)
  cat("Trim cutoffs:", q, "\n")
  keep_ids <- mu$mid[!is.na(mu$em) & mu$em >= q[1] & mu$em <= q[2]]
  cxt <- cx[cx$mid %in% keep_ids, ]

  # Annual panel
  cxt$y_ann <- as.integer(cxt$hate > 0)
  fa <- as.formula(paste("y_ann ~ em +", paste(cs, collapse = " + "), "| state + year_n"))
  ma <- feglm(fa, data = cxt, family = binomial("logit"), cluster = ~county)
  print(summary(ma))

  # Sum (cross-section)
  sm <- cxt %>% group_by(mid) %>%
    summarise(hsum = sum(hate, na.rm = TRUE), hany = any(!is.na(hate)),
              em = first(em), state = first(state), county = first(county),
              across(all_of(cs), ~ first(.x[!is.na(.x)])), .groups = "drop")
  sm$y_sum <- ifelse(sm$hany, as.integer(sm$hsum > 0), NA_integer_)
  fs <- as.formula(paste("y_sum ~ em +", paste(cs, collapse = " + "), "| state"))
  ms <- feglm(fs, data = sm, family = binomial("logit"), cluster = ~county)
  print(summary(ms))

  emit("excess_males_sum_tableC1_col5", unname(coef(ms)["em"]))
  emit("excess_males_annual_tableC1_col6", unname(coef(ma)["em"]))
  emit("n_obs_sum_tableC1_col5", nobs(ms))
  emit("n_obs_annual_tableC1_col6", nobs(ma))
}, error = function(e) cat("Context section error:", conditionMessage(e), "\n"))

for (n in names(results)) cat(sprintf("RESULT:%s=%.6f\n", n, results[[n]]))