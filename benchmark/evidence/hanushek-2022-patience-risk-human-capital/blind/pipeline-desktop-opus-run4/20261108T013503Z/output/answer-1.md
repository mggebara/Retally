suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_full <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

pick_first <- function(cands, nms) { x <- cands[cands %in% nms]; if (length(x)) x[1] else NA_character_ }

zap <- function(dt) {
  for (v in names(dt)) {
    x <- zap_formats(zap_label(zap_labels(dt[[v]])))
    set(dt, j = v, value = x)
  }
  dt
}

find_weight <- function(nms) {
  w <- pick_first(c("w_fstuwt", "W_FSTUWT", "stuwt", "studwt", "weight", "wgt", "w_fstuwt_orig"), nms)
  if (is.na(w)) {
    cand <- grep("wt|weight", nms, value = TRUE, ignore.case = TRUE)
    cand <- cand[!grepl("^w_fstr", cand)]
    if (length(cand)) w <- cand[1]
  }
  w
}

find_imp <- function(nms, base_vars) {
  im <- paste0("im", base_vars)
  im <- im[im %in% nms]
  extra <- grep("^im(female|age|migra|male|sex)", nms, value = TRUE)
  unique(c(im, extra))
}

## ---------------- Table 1: cross-country, full sample ----------------
nms_full <- names(read_dta(f_full, n_max = 1))
female_v <- pick_first(c("female", "girl"), nms_full)
age_v    <- pick_first(c("age"), nms_full)
mig_vars <- intersect(c("migra1", "migra2"), nms_full)
if (!length(mig_vars)) mig_vars <- intersect(c("migra", "immig", "migrant"), nms_full)[1]
imp_full <- find_imp(nms_full, c(female_v, age_v, "migra", mig_vars))
w_full   <- find_weight(nms_full)

sel <- unique(na.omit(c("country", "wave", "pv1math", "patience", "risktaking",
                        female_v, age_v, "migra0", mig_vars, imp_full, w_full)))
sel <- intersect(sel, nms_full)
d1 <- as.data.table(read_dta(f_full, col_select = all_of(sel)))
d1 <- zap(d1)

# rescale sampling weights so that each country carries equal total weight
if (!is.na(w_full)) {
  d1[, wt := get(w_full)]
  d1[is.na(wt), wt := 0]
  d1[, wt := wt / sum(wt), by = country]
} else {
  d1[, wt := 1 / .N, by = country]
}
d1[, math := pv1math / 100]

ctrl1 <- c(female_v, age_v, mig_vars, imp_full)
ctrl1 <- unique(ctrl1[!is.na(ctrl1)])
# missing controls: set to 0 (imputation dummies flag them)
for (v in ctrl1) { x <- d1[[v]]; if (anyNA(x)) set(d1, which(is.na(x)), v, 0) }

rhs_c <- paste(ctrl1, collapse = " + ")
mk <- function(prefs) as.formula(paste("math ~", paste(c(prefs, ctrl1), collapse = " + "), "| wave"))

m1 <- feols(mk("patience"), data = d1, weights = ~wt, cluster = ~country)
m2 <- feols(mk("risktaking"), data = d1, weights = ~wt, cluster = ~country)
m3 <- feols(mk(c("patience", "risktaking")), data = d1, weights = ~wt, cluster = ~country)

# natives: not (both parents born abroad)
if (all(c("migra1", "migra2") %in% names(d1))) {
  d1[, migrant := as.integer(migra1 == 1 | migra2 == 1)]
} else if ("migra0" %in% names(d1)) {
  d1[, migrant := as.integer(migra0 == 0)]
} else {
  d1[, migrant := as.integer(get(mig_vars[1]) != 0)]
}
d1[is.na(migrant), migrant := 0L]
dn <- d1[migrant == 0]
ctrl_n <- setdiff(ctrl1, c(mig_vars, grep("migra", ctrl1, value = TRUE)))
m5 <- feols(as.formula(paste("math ~ patience + risktaking +", paste(ctrl_n, collapse = " + "), "| wave")),
            data = dn, weights = ~wt, cluster = ~country)

t1 <- list(
  table1_col3_patience = coef(m3)["patience"],
  table1_col3_risk_taking = coef(m3)["risktaking"],
  table1_col1_patience = coef(m1)["patience"],
  table1_col2_risk_taking = coef(m2)["risktaking"],
  table1_col5_natives_patience = coef(m5)["patience"],
  table1_col5_natives_risk_taking = coef(m5)["risktaking"],
  table1_col3_observations = nobs(m3)
)
rm(d1, dn); invisible(gc())

## ---------------- Table 2: migrant analysis ----------------
d2 <- as.data.table(read_dta(f_mig))
d2 <- zap(d2)
nms2 <- names(d2)
d2 <- d2[wave >= 2003]
d2[, math := pv1math / 100]

fem2 <- pick_first(c("female"), nms2)
age2 <- pick_first(c("age"), nms2)
imp2 <- find_imp(nms2, c(fem2, age2))
ctrl2 <- unique(na.omit(c(fem2, age2, "coo_oecd", imp2)))
ctrl2 <- intersect(ctrl2, nms2)
for (v in ctrl2) { x <- d2[[v]]; if (anyNA(x)) set(d2, which(is.na(x)), v, 0) }

if (!"countrywave" %in% nms2) d2[, countrywave := paste(country, wave)]

# other preferences of origin country (standardised versions; build if absent)
zstd <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
others <- c("posrecip", "negrecip", "altruism", "trust")
oth_vars <- character(0)
for (p in others) {
  v <- paste0("coo_", p)
  if (!v %in% names(d2)) {
    vo <- paste0(v, "_orig")
    if (vo %in% names(d2)) d2[, (v) := zstd(get(vo))]
  }
  if (v %in% names(d2)) oth_vars <- c(oth_vars, v)
}
d2 <- d2[!is.na(coo_patience) & !is.na(coo_risktaking) & !is.na(math)]

mk2 <- function(prefs) as.formula(paste("math ~", paste(c(prefs, ctrl2), collapse = " + "), "| countrywave"))
n1 <- feols(mk2("coo_patience"), data = d2, cluster = ~coo)
n3 <- feols(mk2(c("coo_patience", "coo_risktaking")), data = d2, cluster = ~coo)
n4 <- feols(mk2(c("coo_patience", "coo_risktaking", oth_vars)), data = d2, cluster = ~coo)

res <- c(t1, list(
  table2_col3_patience = coef(n3)["coo_patience"],
  table2_col3_risk_taking = coef(n3)["coo_risktaking"],
  table2_col1_patience = coef(n1)["coo_patience"],
  table2_col4_patience = coef(n4)["coo_patience"],
  table2_col4_risk_taking = coef(n4)["coo_risktaking"],
  table2_col3_observations = nobs(n3)
))

for (nm in names(res)) {
  val <- unname(as.numeric(res[[nm]]))
  if (grepl("observations", nm)) cat(sprintf("RESULT:%s=%d\n", nm, as.integer(val)))
  else cat(sprintf("RESULT:%s=%.6f\n", nm, val))
}
