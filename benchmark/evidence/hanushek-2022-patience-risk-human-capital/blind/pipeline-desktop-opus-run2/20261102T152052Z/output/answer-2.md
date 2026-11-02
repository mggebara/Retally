suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_main <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, format(val, digits = 10)))
}

find_weight <- function(nms) {
  low <- tolower(nms)
  cands <- c("w_fstuwt", "w_fstuwt_c", "wgt", "weight", "stweight", "studweight", "sweight", "w_fstuwt_std")
  for (cc in cands) if (cc %in% low) return(nms[match(cc, low)])
  hit <- nms[grepl("^w_fstuwt", low)]
  if (length(hit)) return(hit[1])
  hit <- nms[grepl("(senat|cntw|weight|wgt)", low) & !grepl("^w_fstr", low)]
  if (length(hit)) return(hit[1])
  NA_character_
}

num <- function(x) as.numeric(zap_labels(x))

# Convert a (possibly labelled) column to character labels
to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) {
    as.character(haven::as_factor(x, levels = "default"))
  } else if (is.factor(x)) {
    as.character(x)
  } else {
    as.character(x)
  }
}

# Build equal-country weights: sampling weights normalised within country-wave,
# each wave of a country equally weighted, each country total weight = 1
make_weights <- function(dt, wvar, cvar = "country") {
  if (!is.na(wvar)) {
    dt[, w0 := num(get(wvar))]
    dt[is.na(w0) | w0 <= 0, w0 := NA_real_]
  } else {
    dt[, w0 := 1]
  }
  dt[, cw := paste(get(cvar), wave)]
  dt[, w1 := w0 / sum(w0, na.rm = TRUE), by = cw]
  dt[, nw := uniqueN(wave[!is.na(w1)]), by = c(cvar)]
  dt[, wt := w1 / nw]
  dt[, wt := wt * .N / sum(wt, na.rm = TRUE)]
  invisible(dt)
}

impute_controls <- function(dt, vars) {
  out <- vars
  for (v in vars) {
    if (any(is.na(dt[[v]]))) {
      flag <- paste0("imp_", v)
      m <- mean(dt[[v]], na.rm = TRUE)
      dt[, (flag) := as.numeric(is.na(get(v)))]
      dt[is.na(get(v)), (v) := m]
      out <- c(out, flag)
    }
  }
  out
}

# ------------------------------------------------------------------
# Table 1: cross-country analysis
# ------------------------------------------------------------------
hdr <- names(read_dta(f_main, n_max = 0))
wvar <- find_weight(hdr)
mig_vars <- intersect(c("migra0", "migra1", "migra2"), hdr)
im_vars <- hdr[grepl("^im", tolower(hdr)) &
               grepl("(female|age|mig|sex|gender|immig)", tolower(hdr))]
im_vars <- setdiff(im_vars, c("immig", "immigrant"))
want <- unique(c("country", "wave", "pv1math", "patience", "risktaking",
                 "female", "age", mig_vars, im_vars, if (!is.na(wvar)) wvar))
want <- intersect(want, hdr)
d <- as.data.table(read_dta(f_main, col_select = tidyselect::all_of(want)))
d[["country"]] <- to_chr(d[["country"]])
for (v in names(d)) if (v != "country") d[[v]] <- num(d[[v]])
if (median(d$pv1math, na.rm = TRUE) > 50) d[, pv1math := pv1math / 100]
d <- d[!is.na(pv1math) & !is.na(patience) & !is.na(risktaking)]

# migration status
for (v in mig_vars) d[is.na(get(v)), (v) := 0]
if (all(c("migra1", "migra2") %in% names(d))) {
  d[, migrant := as.numeric(migra1 == 1 | migra2 == 1)]
  mig_ctrl <- c("migra1", "migra2")
} else if (length(mig_vars)) {
  d[, migrant := as.numeric(get(mig_vars[length(mig_vars)]) == 1)]
  mig_ctrl <- mig_vars[-1]
} else {
  d[, migrant := 0]
  mig_ctrl <- character(0)
}
# drop collinear/constant controls
mig_ctrl <- mig_ctrl[sapply(mig_ctrl, function(v) isTRUE(sd(d[[v]], na.rm = TRUE) > 0))]

ctrl <- intersect(c("female", "age"), names(d))
ctrl <- impute_controls(d, ctrl)
imd <- intersect(im_vars, names(d))
for (v in imd) d[is.na(get(v)), (v) := 0]
imd <- imd[sapply(imd, function(v) isTRUE(sd(d[[v]]) > 0))]
ctrl_all <- unique(c(ctrl, mig_ctrl, imd))

make_weights(d, wvar, "country")
d <- d[!is.na(wt)]

fml <- function(prefs, ctr) as.formula(paste("pv1math ~", paste(c(prefs, ctr), collapse = " + "), "| wave"))

m1 <- feols(fml("patience", ctrl_all), data = d, weights = ~wt, cluster = ~country)
m2 <- feols(fml("risktaking", ctrl_all), data = d, weights = ~wt, cluster = ~country)
m3 <- feols(fml(c("patience", "risktaking"), ctrl_all), data = d, weights = ~wt, cluster = ~country)

dn <- d[migrant == 0]
ctrl_nat <- setdiff(ctrl_all, c(mig_ctrl, imd[grepl("mig", imd)]))
ctrl_nat <- ctrl_nat[sapply(ctrl_nat, function(v) isTRUE(sd(dn[[v]]) > 0))]
m5 <- feols(fml(c("patience", "risktaking"), ctrl_nat), data = dn, weights = ~wt, cluster = ~country)

t1 <- list(
  c3p = coef(m3)["patience"], c3r = coef(m3)["risktaking"],
  c1p = coef(m1)["patience"], c2r = coef(m2)["risktaking"],
  c5p = coef(m5)["patience"], c5r = coef(m5)["risktaking"],
  n3 = nobs(m3)
)
rm(d, dn, m1, m2, m3, m5); gc()

# ------------------------------------------------------------------
# Table 2: migrant analysis
# ------------------------------------------------------------------
g <- as.data.table(read_dta(f_mig))
gn <- names(g)
wvar2 <- find_weight(gn)
g[["country"]] <- to_chr(g[["country"]])
g[["coo"]] <- to_chr(g[["coo"]])
for (v in gn) {
  if (!(v %in% c("country", "coo", "countrywave", "isocode", "coo_isocode", "coo_continent"))) {
    if (is.numeric(g[[v]]) || inherits(g[[v]], "haven_labelled")) g[[v]] <- num(g[[v]])
  }
}
if (median(g$pv1math, na.rm = TRUE) > 50) g[, pv1math := pv1math / 100]
g <- g[!is.na(pv1math) & !is.na(coo_patience) & !is.na(coo_risktaking) & wave >= 2003]
g[, cwfe := paste(country, wave)]

# other origin preferences: use standardized versions if present, else standardize originals
other <- c("posrecip", "negrecip", "altruism", "trust")
oth_vars <- character(0)
for (p in other) {
  v <- paste0("coo_", p)
  if (!(v %in% names(g))) {
    vo <- paste0("coo_", p, "_orig")
    if (vo %in% names(g)) {
      x <- g[[vo]]
      g[, (v) := (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)]
    }
  }
  if (v %in% names(g)) oth_vars <- c(oth_vars, v)
}

ctrl2 <- intersect(c("female", "age", "coo_oecd"), names(g))
ctrl2 <- impute_controls(g, ctrl2)
imd2 <- intersect(c("imfemale", "image", "imcoo_oecd"), names(g))
for (v in imd2) g[is.na(get(v)), (v) := 0]
imd2 <- imd2[sapply(imd2, function(v) isTRUE(sd(g[[v]]) > 0))]
ctrl2_all <- unique(c(ctrl2, imd2))

make_weights(g, wvar2, "country")
g <- g[!is.na(wt)]

fml2 <- function(prefs, ctr) as.formula(paste("pv1math ~", paste(c(prefs, ctr), collapse = " + "), "| cwfe"))
k1 <- feols(fml2("coo_patience", ctrl2_all), data = g, weights = ~wt, cluster = ~coo)
k3 <- feols(fml2(c("coo_patience", "coo_risktaking"), ctrl2_all), data = g, weights = ~wt, cluster = ~coo)
k4 <- tryCatch(
  feols(fml2(c("coo_patience", "coo_risktaking", oth_vars), ctrl2_all), data = g, weights = ~wt, cluster = ~coo),
  error = function(e) NULL)

emit("table1_col3_patience", t1$c3p)
emit("table1_col3_risk_taking", t1$c3r)
emit("table1_col1_patience", t1$c1p)
emit("table1_col2_risk_taking", t1$c2r)
emit("table1_col5_natives_patience", t1$c5p)
emit("table1_col5_natives_risk_taking", t1$c5r)
emit("table1_col3_observations", t1$n3)
emit("table2_col3_patience", coef(k3)["coo_patience"])
emit("table2_col3_risk_taking", coef(k3)["coo_risktaking"])
emit("table2_col1_patience", coef(k1)["coo_patience"])
emit("table2_col4_patience", if (is.null(k4)) NA else coef(k4)["coo_patience"])
emit("table2_col4_risk_taking", if (is.null(k4)) NA else coef(k4)["coo_risktaking"])
emit("table2_col3_observations", nobs(k3))
