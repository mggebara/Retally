suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_full  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_imcoo <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

get_label <- function(x) { l <- attr(x, "label"); if (is.null(l)) "" else as.character(l) }

pick_weight <- function(nm) {
  cand <- nm[grepl("wgt|weight|fstuwt|senat", nm, ignore.case = TRUE) & !grepl("^w_fstr", nm)]
  if (length(cand) == 0) return(NA_character_)
  pri <- cand[grepl("senat|resc|_rs|cnt|equal", cand, ignore.case = TRUE)]
  if (length(pri)) return(pri[1])
  pri <- cand[grepl("fstuwt", cand, ignore.case = TRUE)]
  if (length(pri)) return(pri[1])
  cand[1]
}

# rescale weights: sampling weights within country, each country gets equal total weight
rescale_w <- function(dt, wcol, ctry = "country") {
  if (is.na(wcol)) { dt[, w_eq := 1]; return(dt) }
  dt[, w_raw := as.numeric(get(wcol))]
  dt[is.na(w_raw) | w_raw <= 0, w_raw := NA_real_]
  dt[, w_eq := w_raw / sum(w_raw, na.rm = TRUE), by = ctry]
  dt[, w_eq := w_eq * 1000]
  dt
}

to_num <- function(dt, cols) { for (v in cols) if (v %in% names(dt)) set(dt, j = v, value = as.numeric(zap_labels(dt[[v]]))); dt }

# ------------------------------------------------------------------
# Table 1: cross-country analysis
# ------------------------------------------------------------------
hdr_full <- read_dta(f_full, n_max = 1)
nm_full <- names(hdr_full)
w_full <- pick_weight(nm_full)
mig_cols <- intersect(c("migra0", "migra1", "migra2"), nm_full)
im_mig <- nm_full[grepl("^im(migra|mig|immig)", nm_full)]
im_cols1 <- unique(c(intersect(c("imfemale", "image"), nm_full), im_mig))
ctrl1 <- intersect(c("female", "age"), nm_full)
need_full <- unique(c("wave", "country", "pv1math", "patience", "risktaking",
                      ctrl1, mig_cols, im_cols1, if (!is.na(w_full)) w_full))
need_full <- intersect(need_full, nm_full)

full <- as.data.table(read_dta(f_full, col_select = all_of(need_full)))
mig_labels <- sapply(mig_cols, function(v) get_label(full[[v]]))
full <- to_num(full, setdiff(need_full, "country"))
full[, country := as.character(as_factor(country))]
cat(sprintf("SAMPLE:table1_full:loaded=%d\n", nrow(full)))

# outcome in units of 100 PISA points
if (mean(full$pv1math, na.rm = TRUE) > 50) full[, pv1math := pv1math / 100]

full <- full[!is.na(patience) & !is.na(risktaking)]
cat(sprintf("SAMPLE:table1_full:gps_countries=%d\n", nrow(full)))
full <- full[wave %in% c(2000, 2003, 2006, 2009, 2012, 2015, 2018)]
cat(sprintf("SAMPLE:table1_full:waves_2000_2018=%d\n", nrow(full)))
full <- full[!is.na(pv1math)]
cat(sprintf("SAMPLE:table1_full:nonmissing_math=%d\n", nrow(full)))

full <- rescale_w(full, w_full)
full <- full[!is.na(w_eq)]

# native indicator: migrant = both parents born abroad
nat_col <- NA_character_
if (length(mig_cols)) {
  hit <- names(mig_labels)[grepl("native|non-mig|nonmig", mig_labels, ignore.case = TRUE)]
  nat_col <- if (length(hit)) hit[1] else if ("migra0" %in% mig_cols) "migra0" else NA_character_
}

ctrl_full <- c(ctrl1, mig_cols, im_cols1)
fml <- function(prefs, ctrls, fe) {
  as.formula(paste("pv1math ~", paste(c(prefs, ctrls), collapse = " + "), "|", fe))
}

m1 <- feols(fml("patience", ctrl_full, "wave"), data = full, weights = ~w_eq, cluster = ~country)
m2 <- feols(fml("risktaking", ctrl_full, "wave"), data = full, weights = ~w_eq, cluster = ~country)
m3 <- feols(fml(c("patience", "risktaking"), ctrl_full, "wave"), data = full, weights = ~w_eq, cluster = ~country)
cat(sprintf("SAMPLE:table1_full:estimation=%d\n", nobs(m3)))

nat <- if (!is.na(nat_col)) full[get(nat_col) == 1] else full
cat(sprintf("SAMPLE:table1_natives:loaded=%d\n", nrow(full)))
cat(sprintf("SAMPLE:table1_natives:natives_only=%d\n", nrow(nat)))
ctrl_nat <- c(ctrl1, intersect(c("imfemale", "image"), names(nat)))
m5 <- feols(fml(c("patience", "risktaking"), ctrl_nat, "wave"), data = nat, weights = ~w_eq, cluster = ~country)
cat(sprintf("SAMPLE:table1_natives:estimation=%d\n", nobs(m5)))

t1 <- list(
  c3p = unname(coef(m3)["patience"]), c3r = unname(coef(m3)["risktaking"]),
  c1p = unname(coef(m1)["patience"]), c2r = unname(coef(m2)["risktaking"]),
  c5p = unname(coef(m5)["patience"]), c5r = unname(coef(m5)["risktaking"]),
  n3 = nobs(m3)
)
rm(full, nat); invisible(gc())

# ------------------------------------------------------------------
# Table 2: migrant (epidemiological) analysis
# ------------------------------------------------------------------
hdr_im <- read_dta(f_imcoo, n_max = 1)
nm_im <- names(hdr_im)
w_im <- pick_weight(nm_im)
other_prefs_cand <- list(
  posrecip = c("coo_posrecip", "coo_posrecip_orig"),
  negrecip = c("coo_negrecip", "coo_negrecip_orig"),
  altruism = c("coo_altruism", "coo_altruism_orig"),
  trust    = c("coo_trust", "coo_trust_orig")
)
other_prefs <- unlist(lapply(other_prefs_cand, function(v) { h <- intersect(v, nm_im); if (length(h)) h[1] else NULL }))
im_cols2 <- intersect(c("imfemale", "image"), nm_im)
ctrl2 <- c(intersect(c("female", "age", "coo_oecd"), nm_im), im_cols2)
need_im <- unique(c("country", "wave", "countrywave", "coo", "pv1math", "coo_patience", "coo_risktaking",
                    ctrl2, other_prefs, if (!is.na(w_im)) w_im))
need_im <- intersect(need_im, nm_im)

mig <- as.data.table(read_dta(f_imcoo, col_select = all_of(need_im)))
mig <- to_num(mig, setdiff(need_im, c("country", "coo", "countrywave")))
mig[, country := as.character(as_factor(country))]
mig[, coo := as.character(as_factor(coo))]
if (!"countrywave" %in% names(mig)) mig[, countrywave := paste(country, wave, sep = "_")]
mig[, countrywave := as.character(countrywave)]
cat(sprintf("SAMPLE:table2_migrants:loaded=%d\n", nrow(mig)))

if (mean(mig$pv1math, na.rm = TRUE) > 50) mig[, pv1math := pv1math / 100]

mig <- mig[wave >= 2003 & wave <= 2018]
cat(sprintf("SAMPLE:table2_migrants:waves_2003_2018=%d\n", nrow(mig)))
mig <- mig[!is.na(coo) & coo != "" & !is.na(coo_patience) & !is.na(coo_risktaking)]
cat(sprintf("SAMPLE:table2_migrants:origin_with_gps=%d\n", nrow(mig)))
mig <- mig[!is.na(pv1math)]
cat(sprintf("SAMPLE:table2_migrants:nonmissing_math=%d\n", nrow(mig)))

mig <- rescale_w(mig, w_im)
mig <- mig[!is.na(w_eq)]

n1 <- feols(fml("coo_patience", ctrl2, "countrywave"), data = mig, weights = ~w_eq, cluster = ~coo)
n3 <- feols(fml(c("coo_patience", "coo_risktaking"), ctrl2, "countrywave"), data = mig, weights = ~w_eq, cluster = ~coo)
cat(sprintf("SAMPLE:table2_migrants:estimation=%d\n", nobs(n3)))
n4 <- feols(fml(c("coo_patience", "coo_risktaking"), c(other_prefs, ctrl2), "countrywave"),
            data = mig, weights = ~w_eq, cluster = ~coo)

cat(sprintf("RESULT:table1_col3_patience=%.6f\n", t1$c3p))
cat(sprintf("RESULT:table1_col3_risk_taking=%.6f\n", t1$c3r))
cat(sprintf("RESULT:table1_col1_patience=%.6f\n", t1$c1p))
cat(sprintf("RESULT:table1_col2_risk_taking=%.6f\n", t1$c2r))
cat(sprintf("RESULT:table1_col5_natives_patience=%.6f\n", t1$c5p))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.6f\n", t1$c5r))
cat(sprintf("RESULT:table1_col3_observations=%d\n", as.integer(t1$n3)))
cat(sprintf("RESULT:table2_col3_patience=%.6f\n", unname(coef(n3)["coo_patience"])))
cat(sprintf("RESULT:table2_col3_risk_taking=%.6f\n", unname(coef(n3)["coo_risktaking"])))
cat(sprintf("RESULT:table2_col1_patience=%.6f\n", unname(coef(n1)["coo_patience"])))
cat(sprintf("RESULT:table2_col4_patience=%.6f\n", unname(coef(n4)["coo_patience"])))
cat(sprintf("RESULT:table2_col4_risk_taking=%.6f\n", unname(coef(n4)["coo_risktaking"])))
cat(sprintf("RESULT:table2_col3_observations=%d\n", as.integer(nobs(n3))))