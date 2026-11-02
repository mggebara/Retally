suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

res <- list()
emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v)) v <- NA
  res[[name]] <<- v
}
bt <- function(v) paste0("`", v, "`")
num <- function(x) suppressWarnings(as.numeric(x))

# =====================================================================
# Part 1: Survey (Table 1)
# =====================================================================
tryCatch({
  sv <- haven::read_dta(file.path(base, "survey.dta"))
  sv <- haven::zap_labels(sv)
  sv <- as.data.frame(sv)
  nm <- names(sv)
  cat("Survey columns:\n"); print(nm)

  yvar <- "hate_violence_means"
  mate <- grep("^MateComp", nm, value = TRUE)[1]
  job  <- grep("^JobComp", nm, value = TRUE)[1]
  life <- grep("^LifeSatis", nm, value = TRUE)[1]

  w <- num(sv$wave)
  if (any(w == 4, na.rm = TRUE)) {
    d <- sv[!is.na(w) & w == 4, , drop = FALSE]
  } else {
    d <- sv[!is.na(num(sv[[mate]])), , drop = FALSE]
  }
  for (v in c(yvar, mate, job, life)) d[[v]] <- num(d[[v]])

  pick <- function(pat, exclude = character(0)) {
    out <- grep(pat, nm, value = TRUE, ignore.case = TRUE)
    setdiff(out, exclude)
  }
  core <- c(yvar, mate, job, life, "wave", "res_id")
  outcomes <- c("hate_justified", "hate_pol_message", "hate_prevent_settlement",
                "hate_polcondemn", "list", "treatment_list", "outcome_list")

  # Sociodemographics
  socio_num <- c()
  socio_fac <- c()
  if ("age" %in% nm) socio_num <- c(socio_num, "age") else socio_fac <- c(socio_fac, intersect("age_group", nm))
  socio_fac <- c(socio_fac, intersect("gender", nm))
  edu <- pick("^eduyrs$|^education$|^edu$")
  if (length(edu) == 0) edu <- pick("^edu")
  socio_num <- c(socio_num, edu[1][!is.na(edu[1])])
  socio_num <- c(socio_num, intersect("income", nm))
  occ <- pick("^oc|occup|activ")
  socio_fac <- c(socio_fac, occ)
  emp <- pick("employ|empl_|emp_stat|^work")
  socio_fac <- c(socio_fac, emp)
  socio_fac <- c(socio_fac, intersect("citizenship", nm))
  socio_num <- c(socio_num, intersect("household_size", nm))
  stat <- pick("social_status|soc_status|^status|self_status|^self_econ$|socstat|subj_status")
  socio_num <- c(socio_num, stat)
  socio_fac <- c(socio_fac, intersect("religion", nm))
  socio_fac <- c(socio_fac, intersect("state", nm))
  socio_num <- unique(setdiff(socio_num, c(core, outcomes)))
  socio_fac <- unique(setdiff(socio_fac, c(core, outcomes, socio_num)))
  socio <- c(socio_num, socio_fac)

  # National refugee attitudes
  local_att <- pick("^ref_loc|_loc_|^loc_|local", exclude = c("location"))
  nat_att <- setdiff(pick("^ref_|^nat_|national"), local_att)
  nat_att <- setdiff(nat_att, c(core, outcomes, socio))
  local_att <- setdiff(local_att, c(core, outcomes, socio, nat_att))

  # Additional controls
  add <- c(pick("contact"), pick("shelter|closeness|close_|dist_"),
           intersect("refugee_ind", nm), pick("number_ref|num_ref|ref_num|est_ref"),
           pick("afd"), pick("lrscale|leftright|left_right"), pick("muslim"))
  add <- unique(setdiff(add, c(core, outcomes, socio, nat_att, local_att,
                               "pop_15_44_muni_gendergap_2015")))

  cat("Socio numeric:", socio_num, "\n")
  cat("Socio factor:", socio_fac, "\n")
  cat("National att:", nat_att, "\n")
  cat("Local att:", local_att, "\n")
  cat("Additional:", add, "\n")

  for (v in c(socio_num, nat_att, local_att, add)) d[[v]] <- num(d[[v]])
  for (v in socio_fac) d[[v]] <- factor(d[[v]])

  # sample for columns 1-2
  s12 <- d[complete.cases(d[, c(yvar, mate, job, life)]), , drop = FALSE]

  fit <- function(rhs, dat) {
    f <- reformulate(bt(rhs), response = bt(yvar))
    lm(f, data = dat)
  }
  getc <- function(m, v) {
    cf <- coef(m)
    k <- which(names(cf) %in% c(v, bt(v)))
    if (length(k) == 0) return(NA)
    cf[k[1]]
  }

  m1 <- fit(c(mate), s12)
  m2 <- fit(c(mate, job, life), s12)
  emit("mate_competition_table1_col1", getc(m1, mate))
  emit("mate_competition_table1_col2", getc(m2, mate))
  emit("job_competition_table1_col2", getc(m2, job))
  emit("n_obs_table1_col1", nobs(m2))

  rhs3 <- c(mate, job, life, socio)
  m3 <- fit(rhs3, s12)
  s36 <- s12[complete.cases(s12[, c(yvar, rhs3)]), , drop = FALSE]
  emit("mate_competition_table1_col3", getc(m3, mate))
  emit("n_obs_table1_col3", nobs(m3))

  rhs4 <- c(rhs3, nat_att)
  m4 <- fit(rhs4, s12)
  emit("mate_competition_table1_col4", getc(m4, mate))
  rhs5 <- c(rhs4, local_att)
  m5 <- fit(rhs5, s12)
  emit("mate_competition_table1_col5", getc(m5, mate))
  rhs6 <- c(rhs5, add)
  m6 <- fit(rhs6, s12)
  emit("mate_competition_table1_col6", getc(m6, mate))
  cat("N cols 3-6:", nobs(m3), nobs(m4), nobs(m5), nobs(m6), "\n")
}, error = function(e) cat("Survey part error:", conditionMessage(e), "\n"))

# =====================================================================
# Part 2: Ecological analysis (SI Table C1, cols 5 and 6)
# =====================================================================
tryCatch({
  cx <- haven::read_dta(file.path(base, "context.dta"))
  cx <- as.data.frame(haven::zap_labels(cx))
  nm <- names(cx)
  cat("Context columns:\n"); print(nm)

  # Excess males (15-44)
  em <- grep("15_44.*gendergap|gendergap.*15_44", nm, value = TRUE)
  if (length(em) == 0) em <- grep("gendergap", setdiff(nm, "unemp_gendergap_2015"), value = TRUE)
  em <- em[1]
  cx[[em]] <- num(cx[[em]])
  cat("Excess males var:", em, " summary:\n"); print(summary(cx[[em]]))

  hatev <- grep("^Hate_all", nm, value = TRUE)[1]
  if (is.na(hatev)) hatev <- grep("hate", nm, value = TRUE, ignore.case = TRUE)[1]
  cx[[hatev]] <- num(cx[[hatev]])
  if (!any(cx[[hatev]] == 0, na.rm = TRUE)) cx[[hatev]][is.na(cx[[hatev]])] <- 0

  idv <- grep("^ags_muni$|^ags$|^ags_gem|^gkz|muni_id|^id_muni|^ags_gemeinde|^gemeinde", nm, value = TRUE)[1]
  if (is.na(idv)) {
    cx$muni_id_tmp <- as.integer(factor(paste(cx$ags_county, cx[[em]],
                                              cx[[grep("population", nm, value = TRUE)[1]]])))
    idv <- "muni_id_tmp"
  }
  cat("Muni id:", idv, "\n")

  excl_pat <- paste0("^year$|^east$|^ags|_id$|^id|name|^lat|^lon|gendergap.*15_44|^pop_.*gendergap|",
                     "^Hate|^Physical|arson|attack|^Other|other_|^hate|pc_ref_male|^muni_id_tmp$|",
                     "^gen$|^krs|^land|^bula")
  cands <- nm[!grepl(excl_pat, nm, ignore.case = TRUE)]
  cands <- setdiff(cands, c(em, idv, hatev))
  # keep only numeric-coercible columns with variation
  ctrl <- c()
  for (v in cands) {
    x <- num(cx[[v]])
    if (sum(!is.na(x)) > 0.5 * nrow(cx) && length(unique(na.omit(x))) > 2) {
      cx[[v]] <- x
      ctrl <- c(ctrl, v)
    }
  }
  # drop other age-range sex-ratio variables (robustness only)
  ctrl <- ctrl[!grepl("gendergap", ctrl) | ctrl == "unemp_gendergap_2015" |
                 grepl("unemp", ctrl)]
  cat("Controls:", ctrl, "\n")

  cx$year <- num(cx$year)
  # trimming on municipality cross-section
  mu <- cx %>% group_by(.data[[idv]]) %>% summarise(emv = first(na.omit(.data[[em]])), .groups = "drop")
  qs <- quantile(mu$emv, c(0.025, 0.975), na.rm = TRUE)
  cat("Trim bounds:", qs, "\n")
  keep_ids <- mu[[idv]][!is.na(mu$emv) & mu$emv >= qs[1] & mu$emv <= qs[2]]
  cx2 <- cx[cx[[idv]] %in% keep_ids, , drop = FALSE]

  # Annual panel
  cx2$y_annual <- as.integer(cx2[[hatev]] > 0)
  fa <- as.formula(paste("y_annual ~", paste(bt(c(em, ctrl)), collapse = " + "),
                         "| ags_state + year"))
  ma <- feglm(fa, data = cx2, family = binomial("logit"), cluster = ~ags_county)
  print(summary(ma))
  ca <- coef(ma); k <- which(names(ca) %in% c(em, bt(em)))
  emit("excess_males_annual_tableC1_col6", ca[k[1]])
  emit("n_obs_annual_tableC1_col6", nobs(ma))

  # Sum cross-section
  agg <- cx2 %>% group_by(.data[[idv]]) %>%
    summarise(hate_sum = sum(.data[[hatev]], na.rm = TRUE), .groups = "drop")
  base15 <- cx2 %>% arrange(.data[[idv]], year)
  if (any(base15$year == 2015, na.rm = TRUE)) base15 <- base15[!is.na(base15$year) & base15$year == 2015, ]
  base15 <- base15[!duplicated(base15[[idv]]), c(idv, em, ctrl, "ags_state", "ags_county")]
  sdat <- merge(base15, agg, by = idv)
  sdat$y_sum <- as.integer(sdat$hate_sum > 0)
  fs <- as.formula(paste("y_sum ~", paste(bt(c(em, ctrl)), collapse = " + "),
                         "| ags_state"))
  ms <- feglm(fs, data = sdat, family = binomial("logit"), cluster = ~ags_county)
  print(summary(ms))
  cs <- coef(ms); k <- which(names(cs) %in% c(em, bt(em)))
  emit("excess_males_sum_tableC1_col5", cs[k[1]])
  emit("n_obs_sum_tableC1_col5", nobs(ms))
}, error = function(e) cat("Context part error:", conditionMessage(e), "\n"))

# =====================================================================
# Output
# =====================================================================
names_all <- c("mate_competition_table1_col1", "mate_competition_table1_col2",
               "mate_competition_table1_col3", "mate_competition_table1_col4",
               "mate_competition_table1_col5", "mate_competition_table1_col6",
               "job_competition_table1_col2", "n_obs_table1_col1", "n_obs_table1_col3",
               "excess_males_sum_tableC1_col5", "excess_males_annual_tableC1_col6",
               "n_obs_sum_tableC1_col5", "n_obs_annual_tableC1_col6")
for (n in names_all) {
  v <- if (!is.null(res[[n]])) res[[n]] else NA
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 8))))
}
