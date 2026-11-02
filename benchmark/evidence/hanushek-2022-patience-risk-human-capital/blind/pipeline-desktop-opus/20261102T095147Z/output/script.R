suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_full <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

out <- list()
emit <- function(name, val) {
  out[[name]] <<- val
}

pick <- function(nms, cands) {
  hit <- cands[cands %in% nms]
  if (length(hit)) hit[1] else NA_character_
}

prep_controls <- function(dt, vars) {
  # replace missing control values by 0 and add a missing flag (only if needed)
  added <- character(0)
  for (v in vars) {
    x <- as.numeric(dt[[v]])
    if (anyNA(x)) {
      fl <- paste0("na_", v)
      dt[, (fl) := as.numeric(is.na(x))]
      x[is.na(x)] <- 0
      added <- c(added, fl)
    }
    dt[, (v) := x]
  }
  c(vars, added)
}

## ---------------- Table 1: cross-country ----------------
nms <- names(read_dta(f_full, n_max = 1))
lnms <- tolower(nms)
names_map <- setNames(nms, lnms)

wt_cands <- c("senatewgt", "senat_wgt", "senwgt", "senwt", "wgt_senate", "weight", "wgt", "stweight",
              "cntwgt", "w_senate", "senate", "w_fstuwt", "w_fstuwt_orig", "stuwt")
wv <- pick(lnms, wt_cands)
if (is.na(wv)) {
  g <- grep("wt|wgt|weight", lnms, value = TRUE)
  g <- g[!grepl("^w_fstr|^w_fsr|rep", g)]
  wv <- if (length(g)) g[1] else NA_character_
}

ctrl_cands <- c("female", "age", "migra0", "migra1", "migra2", "imfemale", "image", "immigra",
                "immigra0", "immigra1", "immigra2", "immig", "migra")
ctrl_vars <- ctrl_cands[ctrl_cands %in% lnms]
ctrl_vars <- setdiff(ctrl_vars, "migra")
pref_vars <- c("patience", "risktaking", "posrecip", "negrecip", "altruism", "trust")
pref_vars <- pref_vars[pref_vars %in% lnms]

need <- unique(c("country", "wave", "pv1math", "pv1mathorig", pref_vars, ctrl_vars, wv))
need <- need[!is.na(need) & need %in% lnms]
d <- as.data.table(read_dta(f_full, col_select = tidyselect::all_of(unname(names_map[need]))))
setnames(d, tolower(names(d)))
for (v in names(d)) if (inherits(d[[v]], "haven_labelled")) d[[v]] <- as.numeric(zap_labels(d[[v]]))
d[, country := as.character(as_factor(country))]
d[, wave := as.numeric(wave)]

# outcome: PISA math / 100
d[, y := as.numeric(pv1math)]
if (mean(d$y, na.rm = TRUE) > 50) d[, y := y / 100]
if (all(is.na(d$y)) && "pv1mathorig" %in% names(d)) d[, y := as.numeric(pv1mathorig) / 100]

d <- d[!is.na(patience) & !is.na(risktaking) & !is.na(y) & wave >= 2000 & wave <= 2018]

# weights: within-country sampling weights rescaled so each country-wave sums to 1
if (!is.na(wv) && wv %in% names(d)) {
  d[, w0 := as.numeric(get(wv))]
  d[is.na(w0) | w0 <= 0, w0 := NA]
  d[is.na(w0), w0 := 1]
} else {
  d[, w0 := 1]
}
d[, w := w0 / sum(w0), by = .(country, wave)]

cv <- prep_controls(d, ctrl_vars)
# migrant indicator
if (all(c("migra1", "migra2") %in% names(d))) {
  d[, migrant := as.numeric(migra1 == 1 | migra2 == 1)]
} else if ("migra0" %in% names(d)) {
  d[, migrant := as.numeric(migra0 == 0)]
} else d[, migrant := 0]

ctrl_str <- paste(cv, collapse = " + ")
fit1 <- function(prefs, data, controls = ctrl_str) {
  fml <- as.formula(paste("y ~", paste(prefs, collapse = " + "),
                          if (nchar(controls)) paste("+", controls) else "", "| wave"))
  feols(fml, data = data, weights = ~w, cluster = ~country)
}

m1 <- fit1("patience", d)
m2 <- fit1("risktaking", d)
m3 <- fit1(c("patience", "risktaking"), d)
nat <- d[migrant == 0]
nat_ctrls <- cv[!grepl("migra", cv)]
nat_ctrls <- nat_ctrls[sapply(nat_ctrls, function(v) length(unique(nat[[v]])) > 1)]
m5 <- fit1(c("patience", "risktaking"), nat, paste(nat_ctrls, collapse = " + "))

emit("table1_col3_patience", coef(m3)["patience"])
emit("table1_col3_risk_taking", coef(m3)["risktaking"])
emit("table1_col1_patience", coef(m1)["patience"])
emit("table1_col2_risk_taking", coef(m2)["risktaking"])
emit("table1_col5_natives_patience", coef(m5)["patience"])
emit("table1_col5_natives_risk_taking", coef(m5)["risktaking"])
emit("table1_col3_observations", nobs(m3))
cat("Table1 col3 SEs:", sqrt(diag(vcov(m3)))[c("patience", "risktaking")], "\n")
rm(d, nat); invisible(gc())

## ---------------- Table 2: migrants ----------------
mg <- as.data.table(read_dta(f_mig))
setnames(mg, tolower(names(mg)))
for (v in names(mg)) if (inherits(mg[[v]], "haven_labelled")) mg[[v]] <- as.numeric(zap_labels(mg[[v]]))
mg[, y := as.numeric(pv1math)]
if (mean(mg$y, na.rm = TRUE) > 50) mg[, y := y / 100]
mg[, wave := as.numeric(wave)]
mg <- mg[wave >= 2003 & wave <= 2018]
if (!"countrywave" %in% names(mg)) mg[, countrywave := paste(country, wave)]
mg[, cw := as.character(countrywave)]
mg[, coo_c := as.character(coo)]

cpref <- c(pat = "coo_patience", risk = "coo_risktaking", pr = "coo_posrecip", nr = "coo_negrecip",
           alt = "coo_altruism", tr = "coo_trust")
for (k in names(cpref)) {
  if (!cpref[k] %in% names(mg)) {
    alt <- grep(paste0("^", cpref[k]), names(mg), value = TRUE)
    alt <- alt[!grepl("_sd$", alt)]
    if (length(alt)) cpref[k] <- alt[1]
  }
}
mctrl <- c("female", "age", "coo_oecd", "imfemale", "image")
mctrl <- mctrl[mctrl %in% names(mg)]
mg <- mg[!is.na(y) & !is.na(get(cpref["pat"])) & !is.na(get(cpref["risk"]))]
mcv <- prep_controls(mg, mctrl)
mctrl_str <- paste(mcv, collapse = " + ")
fit2 <- function(prefs) {
  fml <- as.formula(paste("y ~", paste(prefs, collapse = " + "), "+", mctrl_str, "| cw"))
  feols(fml, data = mg, cluster = ~coo_c)
}
t1 <- fit2(cpref["pat"])
t3 <- fit2(cpref[c("pat", "risk")])
oth <- cpref[c("pr", "nr", "alt", "tr")]
oth <- oth[oth %in% names(mg)]
t4 <- fit2(c(cpref[c("pat", "risk")], oth))

emit("table2_col3_patience", coef(t3)[cpref["pat"]])
emit("table2_col3_risk_taking", coef(t3)[cpref["risk"]])
emit("table2_col1_patience", coef(t1)[cpref["pat"]])
emit("table2_col4_patience", coef(t4)[cpref["pat"]])
emit("table2_col4_risk_taking", coef(t4)[cpref["risk"]])
emit("table2_col3_observations", nobs(t3))

for (nm in names(out)) cat(sprintf("RESULT:%s=%s\n", nm, format(unname(out[[nm]]), digits = 8)))