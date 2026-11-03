suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free/Replication/Data/Working/"
f_main <- paste0(base, "pisa_full_gps_final.dta")
f_mig  <- paste0(base, "pisa_full_gps_final_imcoo.dta")

res <- list()
emit <- function(name, val) {
  res[[name]] <<- val
}

pick_weight <- function(nm) {
  cands <- c("w_fstuwt", "W_FSTUWT", "wgt", "weight", "stuwt", "w_fstuwt_c", "senwt", "senwgt")
  hit <- intersect(cands, nm)
  if (length(hit)) return(hit[1])
  g <- grep("fstuwt|weight|wgt", nm, value = TRUE, ignore.case = TRUE)
  g <- g[!grepl("^w_fstr", g, ignore.case = TRUE)]
  if (length(g)) return(g[1])
  NA_character_
}

# Prepare controls: fill missing with 0 and use / create imputation dummies
fix_controls <- function(dt, vars) {
  out <- character(0)
  for (v in vars) {
    if (!(v %in% names(dt))) next
    x <- suppressWarnings(as.numeric(dt[[v]]))
    imv <- paste0("im", v)
    if (any(is.na(x))) {
      if (!(imv %in% names(dt))) {
        set(dt, j = imv, value = as.numeric(is.na(x)))
      } else {
        imx <- suppressWarnings(as.numeric(dt[[imv]]))
        imx[is.na(imx)] <- 0
        imx[is.na(x)] <- 1
        set(dt, j = imv, value = imx)
      }
      x[is.na(x)] <- 0
    }
    set(dt, j = v, value = x)
    out <- c(out, v)
    if (imv %in% names(dt)) {
      imx <- suppressWarnings(as.numeric(dt[[imv]]))
      imx[is.na(imx)] <- 0
      set(dt, j = imv, value = imx)
      if (length(unique(imx)) > 1) out <- c(out, imv)
    }
  }
  unique(out)
}

rescale_weights <- function(dt, wvar, grp) {
  if (!is.na(wvar) && wvar %in% names(dt)) {
    w <- suppressWarnings(as.numeric(dt[[wvar]]))
    w[is.na(w) | w < 0] <- 0
  } else {
    w <- rep(1, nrow(dt))
  }
  set(dt, j = "w_raw_", value = w)
  dt[, wr_ := w_raw_ / sum(w_raw_), by = grp]
  dt[!is.finite(wr_), wr_ := 0]
  invisible(dt)
}

getcoef <- function(m, v) {
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

# ---------------------------------------------------------------
# Table 1: cross-country student-level regressions
# ---------------------------------------------------------------
tryCatch({
  nm1 <- names(read_dta(f_main, n_max = 0))
  wv1 <- pick_weight(nm1)
  im_mig <- grep("^im(migra|mig|immig)", nm1, value = TRUE)
  want <- unique(c("pv1math", "patience", "risktaking", "wave", "country",
                   "female", "imfemale", "age", "image",
                   "migra0", "migra1", "migra2", im_mig,
                   if (!is.na(wv1)) wv1))
  want <- intersect(want, nm1)
  dt <- as.data.table(zap_labels(read_dta(f_main, col_select = all_of(want))))
  cat("Main file rows:", nrow(dt), " weight var:", wv1, "\n")

  dt[, pv1math := as.numeric(pv1math)]
  if (median(dt$pv1math, na.rm = TRUE) > 20) dt[, pv1math := pv1math / 100]
  dt[, patience := as.numeric(patience)]
  dt[, risktaking := as.numeric(risktaking)]
  dt[, wave := as.numeric(wave)]

  # migration status
  migvars <- intersect(c("migra1", "migra2"), names(dt))
  if (length(migvars) == 0) migvars <- intersect("migra0", names(dt))
  for (v in intersect(c("migra0", "migra1", "migra2"), names(dt))) {
    set(dt, j = v, value = suppressWarnings(as.numeric(dt[[v]])))
  }
  if (all(c("migra1", "migra2") %in% names(dt))) {
    dt[, migrant_ := as.numeric((!is.na(migra1) & migra1 == 1) | (!is.na(migra2) & migra2 == 1))]
  } else if ("migra0" %in% names(dt)) {
    dt[, migrant_ := as.numeric(!is.na(migra0) & migra0 == 0)]
  } else {
    dt[, migrant_ := 0]
  }

  base_ctl <- fix_controls(dt, c("female", "age"))
  mig_ctl <- fix_controls(dt, migvars)
  for (v in im_mig) {
    if (v %in% names(dt) && !(v %in% mig_ctl)) {
      x <- suppressWarnings(as.numeric(dt[[v]])); x[is.na(x)] <- 0
      set(dt, j = v, value = x)
      if (length(unique(x)) > 1) mig_ctl <- c(mig_ctl, v)
    }
  }
  ctl_all <- unique(c(base_ctl, mig_ctl))

  dt <- dt[!is.na(pv1math) & !is.na(patience) & !is.na(risktaking)]
  rescale_weights(dt, wv1, "country")

  fml <- function(prefs, ctl) {
    as.formula(paste("pv1math ~", paste(c(prefs, ctl), collapse = " + "), "| wave"))
  }

  m1 <- feols(fml("patience", ctl_all), data = dt, weights = ~wr_, cluster = ~country)
  m2 <- feols(fml("risktaking", ctl_all), data = dt, weights = ~wr_, cluster = ~country)
  m3 <- feols(fml(c("patience", "risktaking"), ctl_all), data = dt, weights = ~wr_, cluster = ~country)
  print(summary(m3))

  emit("table1_col3_patience", getcoef(m3, "patience"))
  emit("table1_col3_risk_taking", getcoef(m3, "risktaking"))
  emit("table1_col1_patience", getcoef(m1, "patience"))
  emit("table1_col2_risk_taking", getcoef(m2, "risktaking"))
  emit("table1_col3_observations", nobs(m3))

  dn <- dt[migrant_ == 0]
  nat_ctl <- setdiff(ctl_all, mig_ctl)
  m5 <- feols(fml(c("patience", "risktaking"), nat_ctl), data = dn, weights = ~wr_, cluster = ~country)
  print(summary(m5))
  emit("table1_col5_natives_patience", getcoef(m5, "patience"))
  emit("table1_col5_natives_risk_taking", getcoef(m5, "risktaking"))
  rm(dt, dn); gc()
}, error = function(e) cat("Table 1 error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------
# Table 2: migrant (epidemiological) regressions
# ---------------------------------------------------------------
tryCatch({
  dm <- as.data.table(zap_labels(read_dta(f_mig)))
  nm2 <- names(dm)
  wv2 <- pick_weight(nm2)
  cat("Migrant file rows:", nrow(dm), " weight var:", wv2, "\n")

  dm[, pv1math := as.numeric(pv1math)]
  if (median(dm$pv1math, na.rm = TRUE) > 20) dm[, pv1math := pv1math / 100]

  pref_name <- function(stem) {
    a <- paste0("coo_", stem)
    if (a %in% nm2) return(a)
    b <- paste0("coo_", stem, "_orig")
    if (b %in% nm2) return(b)
    NA_character_
  }
  p_pat <- pref_name("patience")
  p_risk <- pref_name("risktaking")
  others <- na.omit(c(pref_name("posrecip"), pref_name("negrecip"),
                      pref_name("altruism"), pref_name("trust")))
  for (v in c(p_pat, p_risk, others)) set(dm, j = v, value = as.numeric(dm[[v]]))
  setnames(dm, c(p_pat, p_risk), c("coo_pat_", "coo_risk_"))

  if (!("countrywave" %in% nm2)) dm[, countrywave := paste(country, wave, sep = "_")]

  ctl2 <- fix_controls(dm, c("female", "age", "coo_oecd"))

  dm <- dm[!is.na(pv1math) & !is.na(coo_pat_) & !is.na(coo_risk_) & !is.na(coo)]
  rescale_weights(dm, wv2, "country")

  fml2 <- function(prefs) {
    as.formula(paste("pv1math ~", paste(c(prefs, ctl2), collapse = " + "), "| countrywave"))
  }
  t1 <- feols(fml2("coo_pat_"), data = dm, weights = ~wr_, cluster = ~coo)
  t3 <- feols(fml2(c("coo_pat_", "coo_risk_")), data = dm, weights = ~wr_, cluster = ~coo)
  print(summary(t3))
  emit("table2_col3_patience", getcoef(t3, "coo_pat_"))
  emit("table2_col3_risk_taking", getcoef(t3, "coo_risk_"))
  emit("table2_col1_patience", getcoef(t1, "coo_pat_"))
  emit("table2_col3_observations", nobs(t3))

  if (length(others) > 0) {
    t4 <- feols(fml2(c("coo_pat_", "coo_risk_", others)), data = dm, weights = ~wr_, cluster = ~coo)
    print(summary(t4))
    emit("table2_col4_patience", getcoef(t4, "coo_pat_"))
    emit("table2_col4_risk_taking", getcoef(t4, "coo_risk_"))
  }
}, error = function(e) cat("Table 2 error:", conditionMessage(e), "\n"))

names_out <- c("table1_col3_patience", "table1_col3_risk_taking", "table1_col1_patience",
               "table1_col2_risk_taking", "table1_col5_natives_patience",
               "table1_col5_natives_risk_taking", "table1_col3_observations",
               "table2_col3_patience", "table2_col3_risk_taking", "table2_col1_patience",
               "table2_col4_patience", "table2_col4_risk_taking", "table2_col3_observations")
for (n in names_out) {
  v <- if (!is.null(res[[n]])) res[[n]] else NA_real_
  if (grepl("observations", n) && !is.na(v)) {
    cat(sprintf("RESULT:%s=%d\n", n, as.integer(v)))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(v)))
  }
}
