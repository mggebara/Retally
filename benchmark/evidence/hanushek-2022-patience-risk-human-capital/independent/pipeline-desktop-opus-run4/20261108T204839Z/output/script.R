suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_full <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, format(unname(val), digits = 10)))
}

pick_weight <- function(nms) {
  nms_l <- tolower(nms)
  cand <- nms[grepl("wgt|weight|wt", nms_l) & !grepl("^w_fstr|^w_fsturwt|^w_fstr", nms_l)]
  # prefer senate / country-equalised weights
  pref <- cand[grepl("sen|cnt|std|equal|stud", tolower(cand)) & !grepl("^w_fstuwt$", tolower(cand))]
  if (length(pref) > 0) return(list(name = pref[1], rescale = FALSE))
  if ("w_fstuwt" %in% nms_l) return(list(name = nms[nms_l == "w_fstuwt"][1], rescale = TRUE))
  if (length(cand) > 0) return(list(name = cand[1], rescale = TRUE))
  NULL
}

zap <- function(dt) {
  for (v in names(dt)) {
    x <- dt[[v]]
    if (inherits(x, "haven_labelled")) x <- zap_labels(x)
    if (is.factor(x)) x <- as.character(x)
    set(dt, j = v, value = x)
  }
  dt
}

# Fill missing controls with 0 and make sure an imputation dummy exists
prep_controls <- function(dt, vars) {
  out <- character(0)
  for (v in vars) {
    if (!v %in% names(dt)) next
    x <- suppressWarnings(as.numeric(dt[[v]]))
    imv <- paste0("im", v)
    if (any(is.na(x))) {
      if (!imv %in% names(dt)) {
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

safe_coef <- function(m, v) {
  if (is.null(m)) return(NA)
  cf <- coef(m)
  if (v %in% names(cf)) cf[[v]] else NA
}

# ------------------------------------------------------------------
# Cross-country analysis (Table 1)
# ------------------------------------------------------------------
hdr <- names(read_dta(f_full, n_max = 0))
w_full <- pick_weight(hdr)
want <- c("country", "wave", "pv1math", "pv1mathorig", "patience", "risktaking",
          "female", "imfemale", "age", "image",
          "migra0", "migra1", "migra2", "immigra", "immig", "migra", "immigrant",
          w_full$name, "w_fstuwt")
want <- intersect(unique(want[!is.na(want)]), hdr)
want <- unique(c(want, hdr[grepl("^immig", hdr)]))
full <- as.data.table(read_dta(f_full, col_select = tidyselect::all_of(want)))
full <- zap(full)

full[, pv1math := as.numeric(pv1math)]
if (mean(full$pv1math, na.rm = TRUE) > 50) full[, pv1math := pv1math / 100]

# weights: give each country equal weight
if (!is.null(w_full)) {
  full[, w := as.numeric(get(w_full$name))]
  full[is.na(w), w := 0]
  if (w_full$rescale) full[, w := w / sum(w), by = country]
} else {
  full[, w := 1 / .N, by = country]
}

ctrl_basic <- prep_controls(full, c("female", "age"))
mig_vars <- intersect(c("migra1", "migra2"), names(full))
for (v in mig_vars) { x <- as.numeric(full[[v]]); set(full, j = v, value = x) }
mig_missing <- if (length(mig_vars) > 0) {
  Reduce(`|`, lapply(c(mig_vars, intersect("migra0", names(full))), function(v) is.na(full[[v]])))
} else rep(FALSE, nrow(full))
for (v in mig_vars) { x <- full[[v]]; x[is.na(x)] <- 0; set(full, j = v, value = x) }
imm_cands <- names(full)[grepl("^immig", names(full))]
if (length(imm_cands) > 0) {
  imm <- imm_cands[1]
  x <- suppressWarnings(as.numeric(full[[imm]])); x[is.na(x)] <- 0
  x[mig_missing] <- 1
  full[, immig_dum := x]
} else {
  full[, immig_dum := as.numeric(mig_missing)]
}
mig_ctrl <- mig_vars
if (length(unique(full$immig_dum)) > 1) mig_ctrl <- c(mig_ctrl, "immig_dum")

full[, wave := as.integer(wave)]
ctrls_all <- c(ctrl_basic, mig_ctrl)

fit_t1 <- function(prefs, ctrls, data) {
  fml <- as.formula(paste("pv1math ~", paste(c(prefs, ctrls), collapse = " + "), "| wave"))
  tryCatch(feols(fml, data = data, weights = ~w, cluster = ~country),
           error = function(e) { message("T1 error: ", conditionMessage(e)); NULL })
}

m1 <- fit_t1("patience", ctrls_all, full)
m2 <- fit_t1("risktaking", ctrls_all, full)
m3 <- fit_t1(c("patience", "risktaking"), ctrls_all, full)

if ("migra0" %in% names(full)) {
  nat <- full[!is.na(migra0) & as.numeric(migra0) == 1]
} else {
  nat <- full[!mig_missing & rowSums(as.matrix(full[, ..mig_vars])) == 0]
}
m5 <- fit_t1(c("patience", "risktaking"), ctrl_basic, nat)

emit("table1_col3_patience", safe_coef(m3, "patience"))
emit("table1_col3_risk_taking", safe_coef(m3, "risktaking"))
emit("table1_col1_patience", safe_coef(m1, "patience"))
emit("table1_col2_risk_taking", safe_coef(m2, "risktaking"))
emit("table1_col5_natives_patience", safe_coef(m5, "patience"))
emit("table1_col5_natives_risk_taking", safe_coef(m5, "risktaking"))
emit("table1_col3_observations", if (is.null(m3)) NA else nobs(m3))

rm(full, nat); invisible(gc())

# ------------------------------------------------------------------
# Migrant analysis (Table 2)
# ------------------------------------------------------------------
mig <- as.data.table(read_dta(f_mig))
mig <- zap(mig)
nm <- names(mig)
mig[, pv1math := as.numeric(pv1math)]
if (mean(mig$pv1math, na.rm = TRUE) > 50) mig[, pv1math := pv1math / 100]

w_mig <- pick_weight(nm)
if (!is.null(w_mig)) {
  mig[, w := as.numeric(get(w_mig$name))]
  mig[is.na(w), w := 0]
  if (w_mig$rescale) mig[, w := w / sum(w), by = country]
} else {
  mig[, w := 1 / .N, by = country]
}

if (!"countrywave" %in% nm) mig[, countrywave := paste(country, wave, sep = "_")]
ctrl_m <- prep_controls(mig, c("female", "age", "coo_oecd"))

find_pref <- function(key) {
  exact <- paste0("coo_", key)
  if (exact %in% nm) return(exact)
  c2 <- nm[grepl(paste0("^coo_", key), nm) & !grepl("_orig$|_sd$", nm)]
  if (length(c2) > 0) c2[1] else NA
}
others <- na.omit(c(find_pref("posrecip"), find_pref("negrecip"),
                    find_pref("altruism"), find_pref("trust")))

fit_t2 <- function(prefs) {
  fml <- as.formula(paste("pv1math ~", paste(c(prefs, ctrl_m), collapse = " + "), "| countrywave"))
  tryCatch(feols(fml, data = mig, weights = ~w, cluster = ~coo),
           error = function(e) { message("T2 error: ", conditionMessage(e)); NULL })
}

# z-standardise origin-country preferences within the migrant analytical sample
# (student level, sampling weights), as the paper standardises each preference
# domain within the relevant analytical sample
pref_all <- c("coo_patience", "coo_risktaking", others)
for (v in pref_all) set(mig, j = v, value = suppressWarnings(as.numeric(mig[[v]])))
in_s <- !is.na(mig$pv1math) & !is.na(mig$coo_patience) & !is.na(mig$coo_risktaking) & mig$w > 0
for (v in pref_all) {
  x <- mig[[v]]
  ok <- in_s & !is.na(x)
  ww <- mig$w[ok]
  mu <- sum(ww * x[ok]) / sum(ww)
  s <- sqrt(sum(ww * (x[ok] - mu)^2) / sum(ww))
  message(sprintf("pref %s: wmean=%.4f wsd=%.4f", v, mu, s))
  if (is.finite(s) && s > 0) set(mig, j = v, value = (x - mu) / s)
}
cat("DEVIATION: origin-country preferences re-standardised (weighted z-score) within the migrant estimation sample at the student level\n")

n1 <- fit_t2("coo_patience")
n3 <- fit_t2(c("coo_patience", "coo_risktaking"))
n4 <- fit_t2(c("coo_patience", "coo_risktaking", others))

emit("table2_col3_patience", safe_coef(n3, "coo_patience"))
emit("table2_col3_risk_taking", safe_coef(n3, "coo_risktaking"))
emit("table2_col1_patience", safe_coef(n1, "coo_patience"))
emit("table2_col4_patience", safe_coef(n4, "coo_patience"))
emit("table2_col4_risk_taking", safe_coef(n4, "coo_risktaking"))
emit("table2_col3_observations", if (is.null(n3)) NA else nobs(n3))