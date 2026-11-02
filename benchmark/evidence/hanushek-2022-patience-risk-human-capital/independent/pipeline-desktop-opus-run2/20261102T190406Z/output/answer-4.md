suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free/Replication/Data/Working"
f_full <- file.path(base, "pisa_full_gps_final.dta")
f_mig  <- file.path(base, "pisa_full_gps_final_imcoo.dta")

get_names <- function(f) {
  nm <- tryCatch(names(read_dta(f, n_max = 0)), error = function(e) NULL)
  if (is.null(nm) || length(nm) == 0) nm <- names(read_dta(f, n_max = 1))
  nm
}

find_weight <- function(nm) {
  cands <- c("w_fstuwt", "W_FSTUWT", "stweight", "weight", "wgt", "w_fstuwt_orig")
  hit <- cands[cands %in% nm]
  if (length(hit)) return(hit[1])
  pat <- nm[grepl("fstuwt", nm, ignore.case = TRUE)]
  if (length(pat)) return(pat[1])
  pat <- nm[grepl("weight|wgt|^wt", nm, ignore.case = TRUE) & !grepl("^w_fstr", nm, ignore.case = TRUE)]
  if (length(pat)) return(pat[1])
  NA_character_
}

# Country keys: raw code and value label (if any), both normalised
mkkeys <- function(x) {
  code <- trimws(tolower(as.character(zap_labels(x))))
  lab <- code
  if (!is.null(attr(x, "labels"))) {
    lab <- tryCatch(trimws(tolower(as.character(as_factor(x, levels = "labels")))),
                    error = function(e) code)
  }
  list(code = code, lab = lab)
}

clean <- function(dt) {
  for (v in names(dt)) {
    x <- dt[[v]]
    if (inherits(x, "haven_labelled") || !is.null(attr(x, "labels"))) x <- zap_labels(x)
    attr(x, "label") <- NULL; attr(x, "format.stata") <- NULL
    set(dt, j = v, value = x)
  }
  dt
}

fill_na0 <- function(dt, vars) {
  for (v in vars) {
    x <- as.numeric(dt[[v]]); x[is.na(x)] <- 0
    set(dt, j = v, value = x)
  }
  dt
}

g <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }
out <- list()

## ---------------- Table 1: cross-country ----------------
nm <- get_names(f_full)
wv <- find_weight(nm)
migvars <- intersect(c("migra1", "migra2"), nm)
if (length(migvars) == 0) migvars <- intersect(c("migra0"), nm)
imvars <- nm[grepl("^im", nm) & grepl("female|age|migr|sex|gender", nm, ignore.case = TRUE)]
imvars <- setdiff(imvars, c("immig"))
ctrl_base <- intersect(c("female", "age"), nm)
keep <- unique(c("country", "wave", "pv1math", "patience", "risktaking", "posrecip", "negrecip",
                 "altruism", "trust", ctrl_base, migvars, "migra0", imvars, wv))
keep <- intersect(keep[!is.na(keep)], nm)
d <- as.data.table(read_dta(f_full, col_select = all_of(keep)))
k1 <- mkkeys(d$country)
d[, key_code := k1$code]
d[, key_lab := k1$lab]
rm(k1)
d <- clean(d)
if (mean(d$pv1math, na.rm = TRUE) > 50) d[, pv1math := pv1math / 100]
d <- d[!is.na(pv1math) & !is.na(patience) & !is.na(risktaking)]
d <- fill_na0(d, c(ctrl_base, migvars, imvars))
if (!is.na(wv)) {
  d[, w0 := as.numeric(get(wv))]
  d[is.na(w0) | w0 < 0, w0 := 0]
} else d[, w0 := 1]
# Country totals of sampling weights in the full PISA sample (used to give each
# country equal weight; reused for the migrant regressions below)
tot_code <- d[, .(S_full = sum(w0)), by = .(key = key_code)]
tot_lab  <- d[, .(S_full = sum(w0)), by = .(key = key_lab)]
d[, wt := w0 / sum(w0), by = country]
d[, wt := wt * .N / sum(wt)]

ctrl1 <- c(ctrl_base, migvars, imvars)
mk <- function(pref, ctrl) as.formula(paste("pv1math ~", paste(c(pref, ctrl), collapse = " + "), "| wave"))

m1 <- feols(mk("patience", ctrl1), data = d, weights = ~wt, cluster = ~country)
m2 <- feols(mk("risktaking", ctrl1), data = d, weights = ~wt, cluster = ~country)
m3 <- feols(mk(c("patience", "risktaking"), ctrl1), data = d, weights = ~wt, cluster = ~country)

# natives: not migrants (migra0==1), excluding imputed migration status
imm <- imvars[grepl("migr", imvars, ignore.case = TRUE)]
dn <- d
if ("migra0" %in% names(d)) {
  dn <- d[!is.na(migra0) & migra0 == 1]
} else if (all(c("migra1", "migra2") %in% names(d))) {
  dn <- d[migra1 == 0 & migra2 == 0]
}
if (length(imm)) for (v in imm) dn <- dn[get(v) == 0]
ctrl_n <- c(ctrl_base, setdiff(imvars, imm))
ctrl_n <- ctrl_n[sapply(ctrl_n, function(v) length(unique(dn[[v]])) > 1)]
m5 <- feols(mk(c("patience", "risktaking"), ctrl_n), data = dn, weights = ~wt, cluster = ~country)

out$table1_col3_patience <- g(m3, "patience")
out$table1_col3_risk_taking <- g(m3, "risktaking")
out$table1_col1_patience <- g(m1, "patience")
out$table1_col2_risk_taking <- g(m2, "risktaking")
out$table1_col5_natives_patience <- g(m5, "patience")
out$table1_col5_natives_risk_taking <- g(m5, "risktaking")
out$table1_col3_observations <- nobs(m3)
rm(d, dn); invisible(gc())

## ---------------- Table 2: migrants ----------------
nm2 <- get_names(f_mig)
wv2 <- find_weight(nm2)
im2 <- nm2[grepl("^im", nm2) & grepl("female|age|sex|gender", nm2, ignore.case = TRUE)]
ctrl2b <- intersect(c("female", "age", "coo_oecd"), nm2)
other4 <- intersect(c("coo_posrecip", "coo_negrecip", "coo_altruism", "coo_trust"), nm2)
keep2 <- unique(c("country", "wave", "countrywave", "coo", "pv1math", "coo_patience", "coo_risktaking",
                  other4, ctrl2b, im2, wv2))
keep2 <- intersect(keep2[!is.na(keep2)], nm2)
m <- as.data.table(read_dta(f_mig, col_select = all_of(keep2)))
k2 <- mkkeys(m$country)
m[, key_code := k2$code]
m[, key_lab := k2$lab]
rm(k2)
m <- clean(m)
if (mean(m$pv1math, na.rm = TRUE) > 50) m[, pv1math := pv1math / 100]
m <- m[!is.na(pv1math) & !is.na(coo_patience) & !is.na(coo_risktaking)]
m <- fill_na0(m, c(ctrl2b, im2))
# Residence-country-by-wave fixed effects built explicitly from country and wave
m[, cw := paste(key_code, wave, sep = "_")]
cat(sprintf("NOTE: residence-country-by-wave cells = %d\n", uniqueN(m$cw)))
if ("countrywave" %in% names(m)) cat(sprintf("NOTE: file countrywave cells = %d\n", uniqueN(m$countrywave)))

prefs2 <- c("coo_patience", "coo_risktaking", other4)
for (v in prefs2) {
  cm <- m[!is.na(get(v)), .(val = mean(as.numeric(get(v)))), by = coo]
  cat(sprintf("NOTE: %s origin-country SD = %.4f (%d countries)\n", v, sd(cm$val), nrow(cm)))
}

if (!is.na(wv2)) {
  m[, w0 := as.numeric(get(wv2))]
  m[is.na(w0) | w0 < 0, w0 := 0]
} else m[, w0 := 1]

# Match residence countries to full-sample weight totals, trying code and label keys
combos <- list(c("key_code", "code"), c("key_code", "lab"), c("key_lab", "code"), c("key_lab", "lab"))
best <- NULL; best_rate <- -1
for (cb in combos) {
  tt <- if (cb[2] == "code") tot_code else tot_lab
  rate <- mean(m[[cb[1]]] %in% tt$key)
  cat(sprintf("NOTE: match rate %s vs full %s = %.4f\n", cb[1], cb[2], rate))
  if (rate > best_rate) { best_rate <- rate; best <- cb }
}

ctrl2 <- c(ctrl2b, im2)
mk2 <- function(pref, ctrl) as.formula(paste("pv1math ~", paste(c(pref, ctrl), collapse = " + "), "| cw"))

# alternative weights for diagnostics
m[, wt_within := w0 / sum(w0), by = key_code]
m[, wt_within := wt_within * .N / sum(wt_within)]

if (best_rate > 0.95) {
  tt <- if (best[2] == "code") tot_code else tot_lab
  m[, mkey := get(best[1])]
  m <- merge(m, tt[, .(mkey = key, S_full)], by = "mkey", all.x = TRUE)
  m <- m[!is.na(S_full)]
  m[, wt := w0 / S_full]
  m[, wt := wt * .N / sum(wt)]
  cat("DEVIATION: Migrant regressions use sampling weights rescaled to equal residence-country weight in the full PISA sample (not re-equalised within the migrant subsample)\n")
} else {
  cat("NOTE: country codes did not match; falling back to within-migrant-sample country rescaling\n")
  m[, wt := wt_within]
}

for (wn in c("wt_within", "unweighted")) {
  tt3 <- if (wn == "unweighted") feols(mk2(c("coo_patience", "coo_risktaking"), ctrl2), data = m, cluster = ~coo)
         else feols(mk2(c("coo_patience", "coo_risktaking"), ctrl2), data = m, weights = ~wt_within, cluster = ~coo)
  cat(sprintf("NOTE: col3 with %s: patience=%.4f risk=%.4f\n", wn, g(tt3, "coo_patience"), g(tt3, "coo_risktaking")))
}

t1 <- feols(mk2("coo_patience", ctrl2), data = m, weights = ~wt, cluster = ~coo)
t3 <- feols(mk2(c("coo_patience", "coo_risktaking"), ctrl2), data = m, weights = ~wt, cluster = ~coo)
t4 <- tryCatch(feols(mk2(c("coo_patience", "coo_risktaking", other4), ctrl2), data = m, weights = ~wt, cluster = ~coo),
               error = function(e) NULL)

out$table2_col3_patience <- g(t3, "coo_patience")
out$table2_col3_risk_taking <- g(t3, "coo_risktaking")
out$table2_col1_patience <- g(t1, "coo_patience")
out$table2_col4_patience <- if (!is.null(t4)) g(t4, "coo_patience") else NA_real_
out$table2_col4_risk_taking <- if (!is.null(t4)) g(t4, "coo_risktaking") else NA_real_
out$table2_col3_observations <- nobs(t3)

for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
