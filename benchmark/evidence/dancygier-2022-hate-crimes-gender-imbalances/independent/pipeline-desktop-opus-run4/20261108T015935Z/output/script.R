suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}
zap <- function(df) {
  df <- haven::zap_labels(df)
  df <- haven::zap_formats(df)
  as.data.frame(df)
}

# ------------------------------------------------------------------
# Part 1: individual-level survey (Table 1)
# ------------------------------------------------------------------
tryCatch({
  sv <- zap(read_dta(file.path(base, "survey.dta")))
  cat("Survey columns:\n"); print(names(sv))
  cat("Wave table:\n"); print(table(sv$wave, useNA = "ifany"))
  w4 <- if (4 %in% sv$wave) sv[sv$wave == 4, ] else sv[sv$wave == max(sv$wave, na.rm = TRUE), ]
  w4 <- w4[!is.na(w4$MateComp.cont), , drop = FALSE]
  cat("Wave 4 rows with MateComp:", nrow(w4), "\n")

  has <- function(v) v[v %in% names(w4)]
  y <- "hate_violence_means"

  socio_cand <- c("age", "gender", "eduyrs", "education", "income", "occupation", "occup",
                  "main_activity", "employment", "employed", "emp_status", "citizenship",
                  "household_size", "self_econ", "social_status", "religion", "state")
  socio <- has(socio_cand)
  # catch truncated names like "oc..."
  extra_socio <- grep("^(oc|empl|emp_|activity|status)", names(w4), value = TRUE)
  socio <- unique(c(socio, setdiff(extra_socio, c(y))))
  factor_vars <- intersect(c("state", "religion", "occupation", "occup", "main_activity",
                             "employment", "emp_status", "citizenship", grep("^oc", names(w4), value = TRUE)),
                           socio)

  ref_all <- grep("^ref_", names(w4), value = TRUE)
  local <- grep("^ref_loc", ref_all, value = TRUE)
  national <- setdiff(ref_all, c(local, "ref_citizenship"))
  national <- unique(c(national, has("ref_citizenship")))

  addl <- has(c("contact_ind", "refugee_ind", "muslim_ind", "lrscale",
                "shelter_dist", "closeness_shelter", "ref_number", "num_refugees_town",
                "afd", "afd_view", "afd_close", "afd_ind", "closeness_afd"))
  addl <- unique(c(addl, grep("afd|shelter|contact|closeness|ref_num|nref|muslim",
                              names(w4), value = TRUE, ignore.case = TRUE)))
  addl <- setdiff(addl, c(y, national, local, socio))
  cat("Socio:", socio, "\nNational:", national, "\nLocal:", local, "\nAdditional:", addl, "\n")

  for (fv in factor_vars) w4[[fv]] <- factor(w4[[fv]])

  mk <- function(rhs) as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
  c1 <- "MateComp.cont"
  c2 <- c(c1, "JobComp.cont", "LifeSatis.cont")
  c3 <- c(c2, socio)
  c4 <- c(c3, national)
  c5 <- c(c4, local)
  c6 <- c(c5, addl)
  specs <- list(c1, c2, c3, c4, c5, c6)
  for (i in seq_along(specs)) {
    m <- tryCatch(lm(mk(specs[[i]]), data = w4), error = function(e) { print(e); NULL })
    if (is.null(m)) next
    cat(sprintf("Col %d: coef=%.4f se=%.4f N=%d R2=%.3f\n", i, coef(m)[c1],
                sqrt(diag(vcov(m)))[c1], nobs(m), summary(m)$r.squared))
    emit(paste0("mate_competition_table1_col", i), unname(coef(m)[c1]))
    if (i == 2) emit("job_competition_table1_col2", unname(coef(m)["JobComp.cont"]))
    if (i == 1) emit("n_obs_table1_col1", nobs(m))
    if (i == 3) emit("n_obs_table1_col3", nobs(m))
  }
}, error = function(e) { cat("Survey part failed:\n"); print(e) })

# ------------------------------------------------------------------
# Part 2: ecological logit (SI Table C1 cols 5-6)
# ------------------------------------------------------------------
tryCatch({
  cx <- zap(read_dta(file.path(base, "context.dta")))
  cat("Context columns:\n"); print(names(cx))
  print(summary(cx))

  nm <- names(cx)
  idm <- intersect(c("ags_muni", "ags", "ags_gemeinde", "muni_id", "gkz"), nm)[1]
  if (is.na(idm)) idm <- grep("ags", nm, value = TRUE)[!grepl("county|state", grep("ags", nm, value = TRUE))][1]
  em <- grep("gendergap", nm, value = TRUE)
  em <- em[grepl("15_44", em)]
  if (length(em) == 0) em <- grep("excess|sexratio|sex_ratio", nm, value = TRUE, ignore.case = TRUE)
  em <- em[1]
  cat("Muni id:", idm, " Excess males:", em, "\n")

  cx$hate_any <- as.integer(!is.na(cx$Hate_all_muni) & cx$Hate_all_muni > 0)
  cx$EM <- cx[[em]]

  excl <- c("year", "east", "ags_county", "ags_state", idm, "Hate_all_muni", "Physical_muni",
            em, "EM", "hate_any", "location", "name")
  excl <- c(excl, grep("hate|physical|arson|attack", nm, value = TRUE, ignore.case = TRUE))
  ctrls <- setdiff(nm, excl)
  ctrls <- ctrls[sapply(cx[ctrls], is.numeric)]
  # avoid other sex-ratio age ranges & placebo-like vars
  ctrls <- ctrls[!grepl("gendergap", ctrls) | ctrls == "unemp_gendergap_2015"]
  ctrls <- ctrls[sapply(cx[ctrls], function(v) length(unique(na.omit(v))) > 1)]
  cat("Controls:", ctrls, "\n")

  # Diagnose missingness of controls by year
  cat("NA counts of controls by year:\n")
  for (yy in sort(unique(cx$year))) {
    nas <- sapply(cx[cx$year == yy, c("EM", ctrls)], function(v) sum(is.na(v)))
    cat("Year", yy, ":\n"); print(nas[nas > 0])
  }

  # Controls are baseline (pre-period) municipality/county values that are constant
  # over years; some years carry them only as NA. Fill NA within municipality with
  # the municipality's non-missing baseline value so all three panel years enter.
  fillmuni <- function(v) {
    nn <- v[!is.na(v)]
    if (length(nn) == 0) return(v)
    v[is.na(v)] <- nn[1]
    v
  }
  cx <- cx %>% group_by(.data[[idm]]) %>%
    mutate(across(all_of(c("EM", ctrls)), fillmuni)) %>% ungroup() %>% as.data.frame()
  cat("DEVIATION: Filled year-specific NAs in time-invariant baseline controls (and Excess Males) with the municipality's non-missing baseline value so all 2015-2017 municipality-years enter the annual panel\n")

  # trim extreme Excess Males (municipality-level 2.5/97.5 percentiles)
  mu <- cx %>% group_by(.data[[idm]]) %>% summarise(EMm = first(EM), .groups = "drop")
  q <- quantile(mu$EMm, c(0.025, 0.975), na.rm = TRUE)
  cat("EM trim bounds:", q, "\n")
  cxt <- cx[!is.na(cx$EM) & cx$EM >= q[1] & cx$EM <= q[2], ]
  cat("Trimmed rows by year:\n"); print(table(cxt$year))

  rhs <- paste(c("EM", ctrls), collapse = " + ")
  fe_var <- if ("ags_state" %in% nm) "ags_state" else "ags_county"

  # Annual
  fa <- as.formula(paste("hate_any ~", rhs, "|", fe_var, "+ year"))
  ma <- feglm(fa, data = cxt, family = binomial("logit"), cluster = ~ags_county)
  print(summary(ma))
  emit("excess_males_annual_tableC1_col6", unname(coef(ma)["EM"]))
  emit("n_obs_annual_tableC1_col6", nobs(ma))

  # Sum: one row per municipality; time-varying controls taken from 2015 (or first year)
  yrs <- sort(unique(cxt$year))
  sumdv <- cxt %>% group_by(.data[[idm]]) %>%
    summarise(hate_sum = as.integer(any(hate_any == 1)), .groups = "drop")
  first_year <- if (2015 %in% yrs) 2015 else yrs[1]
  cs <- cxt[cxt$year == first_year, ]
  cs <- merge(cs, sumdv, by = idm)
  fs <- as.formula(paste("hate_sum ~", rhs, "|", fe_var))
  ms <- feglm(fs, data = cs, family = binomial("logit"), cluster = ~ags_county)
  print(summary(ms))
  emit("excess_males_sum_tableC1_col5", unname(coef(ms)["EM"]))
  emit("n_obs_sum_tableC1_col5", nobs(ms))
}, error = function(e) { cat("Context part failed:\n"); print(e) })