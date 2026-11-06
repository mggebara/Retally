suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_main <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

strip <- function(d) { d[] <- lapply(d, function(x) { if (inherits(x, "haven_labelled")) as.numeric(x) else { attributes(x) <- attributes(x)[intersect(names(attributes(x)), c("names","class","levels"))]; if (inherits(x, "haven_labelled")) as.numeric(x) else x } }); d }

find_weight <- function(nm) {
  cands <- c("w_fstuwt", "stweight", "studweight", "weight", "wgt", "stuwgt", "w_fsturwt", "totwgt", "senwgt")
  w <- intersect(cands, nm)
  if (length(w) > 0) return(w[1])
  g <- nm[grepl("wt$|weight|wgt", nm, ignore.case = TRUE) & !grepl("^w_fstr", nm)]
  if (length(g) > 0) return(g[1])
  NA_character_
}

rescale_w <- function(d, wcol, by = "country") {
  if (is.na(wcol)) { d$w_eq <- 1; return(d) }
  d$w_raw <- as.numeric(d[[wcol]])
  d <- d %>% group_by(.data[[by]]) %>% mutate(w_eq = w_raw / sum(w_raw, na.rm = TRUE)) %>% ungroup()
  d
}

emit <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

## ---------------- Cross-country sample (Table 1) ----------------
nm_main <- names(read_dta(f_main, n_max = 0))
w_main <- find_weight(nm_main)
mig_vars <- intersect(c("migra1", "migra2"), nm_main)
im_main <- intersect(c("imfemale", "image", "immigra", "immig", "immigr"), nm_main)
want_main <- unique(c("wave", "country", "pv1math", "patience", "risktaking", "posrecip", "negrecip",
                      "altruism", "trust", "female", "age", "migra0", mig_vars, im_main, w_main))
want_main <- intersect(want_main[!is.na(want_main)], nm_main)

d <- read_dta(f_main, col_select = all_of(want_main))
d <- strip(d)
d <- as.data.frame(d)
cat(sprintf("SAMPLE:t1_full:loaded=%d\n", nrow(d)))

if (mean(d$pv1math, na.rm = TRUE) > 50) d$pv1math <- d$pv1math / 100

d <- d %>% filter(!is.na(patience), !is.na(risktaking))
cat(sprintf("SAMPLE:t1_full:gps_countries=%d\n", nrow(d)))
d <- d %>% filter(wave %in% c(2000, 2003, 2006, 2009, 2012, 2015, 2018))
cat(sprintf("SAMPLE:t1_full:pisa_waves_2000_2018=%d\n", nrow(d)))
d <- d %>% filter(!is.na(pv1math))
cat(sprintf("SAMPLE:t1_full:nonmissing_math=%d\n", nrow(d)))

d <- rescale_w(d, w_main, "country")

# migrant indicator: both parents born abroad (first or second generation)
if (length(mig_vars) > 0) {
  d$migrant <- as.integer(rowSums(d[, mig_vars, drop = FALSE] == 1, na.rm = TRUE) > 0)
} else if ("migra0" %in% names(d)) {
  d$migrant <- as.integer(!is.na(d$migra0) & d$migra0 == 0)
} else d$migrant <- 0L

ctrl_main <- intersect(c("female", "age", mig_vars, im_main), names(d))
if (length(mig_vars) == 0 && "migra0" %in% names(d)) ctrl_main <- c(ctrl_main, "migrant")
ctrl_str <- paste(ctrl_main, collapse = " + ")

fm <- function(prefs) as.formula(paste("pv1math ~", paste(c(prefs, ctrl_main), collapse = " + "), "| wave"))

m1 <- feols(fm("patience"), data = d, weights = ~w_eq, cluster = ~country)
m2 <- feols(fm("risktaking"), data = d, weights = ~w_eq, cluster = ~country)
m3 <- feols(fm(c("patience", "risktaking")), data = d, weights = ~w_eq, cluster = ~country)
cat(sprintf("SAMPLE:t1_full:estimation=%d\n", nobs(m3)))

dn <- d %>% filter(migrant == 0)
cat(sprintf("SAMPLE:t1_natives:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:t1_natives:natives_only=%d\n", nrow(dn)))
m5 <- feols(fm(c("patience", "risktaking")), data = dn, weights = ~w_eq, cluster = ~country)
cat(sprintf("SAMPLE:t1_natives:estimation=%d\n", nobs(m5)))

t1 <- list(
  c3p = coef(m3)["patience"], c3r = coef(m3)["risktaking"],
  c1p = coef(m1)["patience"], c2r = coef(m2)["risktaking"],
  c5p = coef(m5)["patience"], c5r = coef(m5)["risktaking"],
  n3 = nobs(m3)
)
rm(d, dn); invisible(gc())

## ---------------- Migrant sample (Table 2) ----------------
dm <- read_dta(f_mig)
dm <- strip(dm)
dm <- as.data.frame(dm)
nm_mig <- names(dm)
cat(sprintf("SAMPLE:t2_migrants:loaded=%d\n", nrow(dm)))
if (mean(dm$pv1math, na.rm = TRUE) > 50) dm$pv1math <- dm$pv1math / 100

dm <- dm %>% filter(wave %in% c(2003, 2006, 2009, 2012, 2015, 2018))
cat(sprintf("SAMPLE:t2_migrants:waves_2003_2018=%d\n", nrow(dm)))
dm <- dm %>% filter(!is.na(coo_patience), !is.na(coo_risktaking))
cat(sprintf("SAMPLE:t2_migrants:origin_with_gps=%d\n", nrow(dm)))
dm <- dm %>% filter(!is.na(pv1math))
cat(sprintf("SAMPLE:t2_migrants:nonmissing_math=%d\n", nrow(dm)))

w_mig <- find_weight(nm_mig)
dm <- rescale_w(dm, w_mig, "country")
if (!"countrywave" %in% names(dm)) dm$countrywave <- paste(dm$country, dm$wave)

im_mig <- intersect(c("imfemale", "image", "imcoo_oecd"), nm_mig)
ctrl_mig <- intersect(c("female", "age", "coo_oecd", im_mig), nm_mig)

pick <- function(a, b) if (a %in% nm_mig) a else if (b %in% nm_mig) b else NA_character_
other <- c(pick("coo_posrecip", "coo_posrecip_orig"), pick("coo_negrecip", "coo_negrecip_orig"),
           pick("coo_altruism", "coo_altruism_orig"), pick("coo_trust", "coo_trust_orig"))
other <- other[!is.na(other)]

fmm <- function(prefs) as.formula(paste("pv1math ~", paste(c(prefs, ctrl_mig), collapse = " + "), "| countrywave"))

n1 <- feols(fmm("coo_patience"), data = dm, weights = ~w_eq, cluster = ~coo)
n3 <- feols(fmm(c("coo_patience", "coo_risktaking")), data = dm, weights = ~w_eq, cluster = ~coo)
cat(sprintf("SAMPLE:t2_migrants:estimation=%d\n", nobs(n3)))
n4 <- feols(fmm(c("coo_patience", "coo_risktaking", other)), data = dm, weights = ~w_eq, cluster = ~coo)

emit("table1_col3_patience", t1$c3p)
emit("table1_col3_risk_taking", t1$c3r)
emit("table1_col1_patience", t1$c1p)
emit("table1_col2_risk_taking", t1$c2r)
emit("table1_col5_natives_patience", t1$c5p)
emit("table1_col5_natives_risk_taking", t1$c5r)
cat(sprintf("RESULT:table1_col3_observations=%d\n", as.integer(t1$n3)))
emit("table2_col3_patience", coef(n3)["coo_patience"])
emit("table2_col3_risk_taking", coef(n3)["coo_risktaking"])
emit("table2_col1_patience", coef(n1)["coo_patience"])
emit("table2_col4_patience", coef(n4)["coo_patience"])
emit("table2_col4_risk_taking", coef(n4)["coo_risktaking"])
cat(sprintf("RESULT:table2_col3_observations=%d\n", as.integer(nobs(n3))))