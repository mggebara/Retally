suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_main <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

pick_first <- function(cands, nms) {
  hit <- cands[tolower(cands) %in% tolower(nms)]
  if (length(hit) == 0) return(NA_character_)
  nms[match(tolower(hit[1]), tolower(nms))]
}

find_weight <- function(nms) {
  w <- pick_first(c("w_fstuwt", "stweight", "stuweight", "weight", "wgt", "w_fstuwt_std",
                    "senwgt", "senat_wgt", "cntwgt", "studwgt", "w_student"), nms)
  if (!is.na(w)) return(w)
  cand <- nms[grepl("wt$|weight|wgt", nms, ignore.case = TRUE) & !grepl("^w_fstr", nms, ignore.case = TRUE)]
  if (length(cand) > 0) return(cand[1])
  NA_character_
}

clean_num <- function(x) as.numeric(zap_labels(x))

# =====================================================================
# Table 1: cross-country analysis
# =====================================================================
nm_main <- names(read_dta(f_main, n_max = 0))
w_main <- find_weight(nm_main)
cat(sprintf("INFO: main weight variable=%s\n", w_main))
mig_vars <- intersect(c("migra0", "migra1", "migra2"), nm_main)
imp_main <- intersect(c("imfemale", "image", "immig", "immigra", "immigrant", "immigr", "imimmig", "immigstat"), nm_main)
other_prefs <- intersect(c("posrecip", "negrecip", "altruism", "trust"), nm_main)
keep_main <- unique(na.omit(c("pv1math", "pv1mathorig", "patience", "risktaking", "female", "age",
                              "wave", "country", "isocode", mig_vars, imp_main, w_main, other_prefs)))
keep_main <- intersect(keep_main, nm_main)

d <- read_dta(f_main, col_select = all_of(keep_main))
d <- as.data.frame(lapply(d, function(x) if (is.character(x)) x else clean_num(x)), stringsAsFactors = FALSE)
cat(sprintf("SAMPLE:table1_full:loaded=%d\n", nrow(d)))

if (mean(d$pv1math, na.rm = TRUE) > 50) d$pv1math <- d$pv1math / 100

d <- d[!is.na(d$patience) & !is.na(d$risktaking), ]
cat(sprintf("SAMPLE:table1_full:gps_countries=%d\n", nrow(d)))
d <- d[!is.na(d$pv1math), ]
cat(sprintf("SAMPLE:table1_full:nonmissing_math=%d\n", nrow(d)))
cat(sprintf("INFO: countries=%d\n", length(unique(d$country))))

if (is.na(w_main)) {
  cat("DEVIATION: no sampling weight variable found in main file; using equal weights per country\n")
  d$w_raw <- 1
} else {
  d$w_raw <- d[[w_main]]
  d$w_raw[is.na(d$w_raw)] <- 0
}
d <- d %>% group_by(country) %>% mutate(w_eq = w_raw / sum(w_raw) * 1000) %>% ungroup() %>% as.data.frame()
d <- d[d$w_eq > 0, ]

# Migration-status controls: first and second generation dummies (natives = base)
mig_ctrl <- setdiff(mig_vars, "migra0")
if (length(mig_ctrl) == 0) cat("DEVIATION: migration status variables not found\n")
for (v in c("female", "age", mig_ctrl)) {
  if (any(is.na(d[[v]]))) {
    cat(sprintf("INFO: %s has %d NAs; imputing 0 with flag\n", v, sum(is.na(d[[v]]))))
    fl <- paste0("imx_", v)
    d[[fl]] <- as.numeric(is.na(d[[v]]))
    d[[v]][is.na(d[[v]])] <- 0
    imp_main <- c(imp_main, fl)
  }
}
imp_main <- imp_main[sapply(imp_main, function(v) length(unique(d[[v]][!is.na(d[[v]])])) > 1)]
ctrl <- c("female", "age", mig_ctrl, imp_main)
ctrl_str <- paste(ctrl, collapse = " + ")

fit1 <- function(prefs, data, ctrls = ctrl) {
  fml <- as.formula(paste("pv1math ~", paste(c(prefs, ctrls), collapse = " + "), "| wave"))
  feols(fml, data = data, weights = ~w_eq, cluster = ~country)
}

m1 <- fit1("patience", d)
m2 <- fit1("risktaking", d)
m3 <- fit1(c("patience", "risktaking"), d)
cat(sprintf("SAMPLE:table1_full:estimation=%d\n", nobs(m3)))

# Natives: students without both parents born abroad
if ("migra0" %in% names(d)) {
  dn <- d[!is.na(d$migra0) & d$migra0 == 1, ]
} else if (length(mig_ctrl) > 0) {
  dn <- d[rowSums(d[, mig_ctrl, drop = FALSE] == 1, na.rm = TRUE) == 0, ]
} else {
  dn <- d
}
cat(sprintf("SAMPLE:table1_natives:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:table1_natives:natives_only=%d\n", nrow(dn)))
ctrl_n <- setdiff(ctrl, c(mig_ctrl, intersect(imp_main, c("immig", "immigra", "immigrant", "immigr", "imimmig", "immigstat"))))
ctrl_n <- ctrl_n[sapply(ctrl_n, function(v) length(unique(dn[[v]])) > 1)]
m5 <- fit1(c("patience", "risktaking"), dn, ctrl_n)
cat(sprintf("SAMPLE:table1_natives:estimation=%d\n", nobs(m5)))

rm(d, dn); invisible(gc())

# =====================================================================
# Table 2: migrant analysis
# =====================================================================
g <- read_dta(f_mig)
g <- as.data.frame(lapply(g, function(x) if (is.character(x)) x else clean_num(x)), stringsAsFactors = FALSE)
cat(sprintf("SAMPLE:table2_migrants:loaded=%d\n", nrow(g)))
cat(sprintf("INFO: migrant file preference-related vars: %s\n",
            paste(names(g)[grepl("patience|risk|coo|weight|wt|wgt", names(g), ignore.case = TRUE)], collapse = ", ")))
if (mean(g$pv1math, na.rm = TRUE) > 50) g$pv1math <- g$pv1math / 100

g <- g[g$wave >= 2003, ]
cat(sprintf("SAMPLE:table2_migrants:waves_2003_2018=%d\n", nrow(g)))
g <- g[!is.na(g$coo_patience) & !is.na(g$coo_risktaking), ]
cat(sprintf("SAMPLE:table2_migrants:origin_with_gps=%d\n", nrow(g)))
g <- g[!is.na(g$pv1math), ]

# Use the same student sampling weight as in the cross-country analysis
# (the generic name search can pick up an unrelated *wt/*wgt column in the migrant file)
if (!is.na(w_main) && w_main %in% names(g)) {
  w_mig <- w_main
} else {
  w_mig <- find_weight(names(g))
}
cat(sprintf("INFO: migrant weight variable=%s\n", w_mig))
if (is.na(w_mig)) {
  cat("DEVIATION: no sampling weight variable found in migrant file; using equal weights per country\n")
  g$w_raw <- 1
} else {
  g$w_raw <- g[[w_mig]]
  g$w_raw[is.na(g$w_raw)] <- 0
}
# Residence-country identifier: ensure FE use residence country, not origin
res_id <- if ("country" %in% names(g)) "country" else pick_first(c("isocode", "cnt"), names(g))
g$res_cty <- g[[res_id]]
g <- g %>% group_by(res_cty) %>% mutate(w_eq = w_raw / sum(w_raw) * 1000) %>% ungroup() %>% as.data.frame()
g <- g[g$w_eq > 0, ]

imp_mig <- intersect(c("imfemale", "image", "imcoo_oecd"), names(g))
for (v in c("female", "age", "coo_oecd")) {
  if (any(is.na(g[[v]]))) {
    fl <- paste0("imx_", v)
    g[[fl]] <- as.numeric(is.na(g[[v]]))
    g[[v]][is.na(g[[v]])] <- 0
    imp_mig <- c(imp_mig, fl)
  }
}
imp_mig <- imp_mig[sapply(imp_mig, function(v) length(unique(g[[v]])) > 1)]
ctrl_m <- c("female", "age", "coo_oecd", imp_mig)

op <- sapply(c("posrecip", "negrecip", "altruism", "trust"), function(p) {
  a <- paste0("coo_", p)
  if (a %in% names(g)) a else if (paste0(a, "_orig") %in% names(g)) paste0(a, "_orig") else NA_character_
})
op <- op[!is.na(op)]

fit2 <- function(prefs, data) {
  fml <- as.formula(paste("pv1math ~", paste(c(prefs, ctrl_m), collapse = " + "), "| res_cty^wave"))
  feols(fml, data = data, weights = ~w_eq, cluster = ~coo)
}
t1 <- fit2("coo_patience", g)
t3 <- fit2(c("coo_patience", "coo_risktaking"), g)
t4 <- fit2(c("coo_patience", "coo_risktaking", op), g)
cat(sprintf("SAMPLE:table2_migrants:estimation=%d\n", nobs(t3)))

# =====================================================================
# Results
# =====================================================================
co <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

cat(sprintf("RESULT:table1_col3_patience=%.6f\n", co(m3, "patience")))
cat(sprintf("RESULT:table1_col3_patience_se=%.6f\n", se(m3, "patience")))
cat(sprintf("RESULT:table1_col3_risk_taking=%.6f\n", co(m3, "risktaking")))
cat(sprintf("RESULT:table1_col3_risk_taking_se=%.6f\n", se(m3, "risktaking")))
cat(sprintf("RESULT:table1_col1_patience=%.6f\n", co(m1, "patience")))
cat(sprintf("RESULT:table1_col2_risk_taking=%.6f\n", co(m2, "risktaking")))
cat(sprintf("RESULT:table1_col5_natives_patience=%.6f\n", co(m5, "patience")))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.6f\n", co(m5, "risktaking")))
cat(sprintf("RESULT:table1_col3_observations=%d\n", nobs(m3)))
cat(sprintf("RESULT:table2_col3_patience=%.6f\n", co(t3, "coo_patience")))
cat(sprintf("RESULT:table2_col3_patience_se=%.6f\n", se(t3, "coo_patience")))
cat(sprintf("RESULT:table2_col3_risk_taking=%.6f\n", co(t3, "coo_risktaking")))
cat(sprintf("RESULT:table2_col3_risk_taking_se=%.6f\n", se(t3, "coo_risktaking")))
cat(sprintf("RESULT:table2_col1_patience=%.6f\n", co(t1, "coo_patience")))
cat(sprintf("RESULT:table2_col4_patience=%.6f\n", co(t4, "coo_patience")))
cat(sprintf("RESULT:table2_col4_risk_taking=%.6f\n", co(t4, "coo_risktaking")))
cat(sprintf("RESULT:table2_col3_observations=%d\n", nobs(t3)))