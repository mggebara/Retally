suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital"
f_full_dta <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_full_csv <- file.path(base, "Replication/Data/CSV/pisa_full_gps_final.csv")
f_mig_dta  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")
f_mig_csv  <- file.path(base, "Replication/Data/CSV/pisa_full_gps_final_imcoo.csv")

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

to_plain <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled") || inherits(x, "labelled")) x <- zap_labels(x)
    attributes(x) <- attributes(x)[intersect(names(attributes(x)), c("names", "levels", "class"))]
    if (is.character(x) && !(v %in% c("country", "coo", "isocode", "coo_isocode", "countrywave"))) {
      suppressWarnings(xn <- as.numeric(x))
      if (sum(!is.na(xn)) >= 0.9 * sum(!is.na(x) & x != "")) x <- xn
    }
    df[[v]] <- x
  }
  df
}

safe_coef <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

# =========================== TABLE 1 ===========================
need1 <- c("pv1math", "patience", "risktaking", "posrecip", "negrecip", "altruism", "trust",
           "female", "age", "migra0", "migra1", "migra2", "image", "imfemale", "immigra1",
           "wave", "wgtc", "country", "isocode")

d1 <- tryCatch({
  read_dta(f_full_dta, col_select = tidyselect::any_of(need1))
}, error = function(e) {
  message("DTA read failed: ", conditionMessage(e), " -- trying CSV")
  hdr <- names(fread(f_full_csv, nrows = 0))
  fread(f_full_csv, select = intersect(need1, hdr), showProgress = FALSE)
})
d1 <- to_plain(d1)
gc()

if (mean(d1$pv1math, na.rm = TRUE) > 50) d1$pv1math <- d1$pv1math / 100

clvar <- if ("country" %in% names(d1)) "country" else "isocode"
d1$clid <- d1[[clvar]]

ctrl_full <- "female + age + migra1 + migra2 + image + imfemale + immigra1"
run1 <- function(rhs, data) {
  tryCatch(
    feols(as.formula(paste0("pv1math ~ ", rhs, " | wave")), data = data,
          weights = ~wgtc, cluster = ~clid, fixef.rm = "none"),
    error = function(e) { message("T1 model failed: ", conditionMessage(e)); NULL })
}

m1c1 <- run1(paste("patience +", ctrl_full), d1)
m1c2 <- run1(paste("risktaking +", ctrl_full), d1)
m1c3 <- run1(paste("patience + risktaking +", ctrl_full), d1)
nat <- d1[!is.na(d1$migra0) & d1$migra0 == 1, ]
m1c5 <- run1("patience + risktaking + female + age + image + imfemale", nat)
rm(nat); gc()

if (!is.null(m1c3)) print(summary(m1c3))
if (!is.null(m1c5)) print(summary(m1c5))

emit("table1_col3_patience", safe_coef(m1c3, "patience"))
emit("table1_col3_risk_taking", safe_coef(m1c3, "risktaking"))
emit("table1_col1_patience", safe_coef(m1c1, "patience"))
emit("table1_col2_risk_taking", safe_coef(m1c2, "risktaking"))
emit("table1_col5_natives_patience", safe_coef(m1c5, "patience"))
emit("table1_col5_natives_risk_taking", safe_coef(m1c5, "risktaking"))
emit("table1_col3_observations", if (!is.null(m1c3)) nobs(m1c3) else NA)

rm(d1, m1c1, m1c2, m1c3, m1c5); gc()

# =========================== TABLE 2 ===========================
d2 <- tryCatch(read_dta(f_mig_dta), error = function(e) {
  message("DTA read failed: ", conditionMessage(e), " -- trying CSV")
  fread(f_mig_csv, showProgress = FALSE)
})
d2 <- to_plain(d2)

if (mean(d2$pv1math, na.rm = TRUE) > 50) d2$pv1math <- d2$pv1math / 100

# Ensure standardized coo preference variables exist (standardized across origin countries)
for (p in c("patience", "risktaking", "posrecip", "negrecip", "altruism", "trust")) {
  v <- paste0("coo_", p)
  vo <- paste0("coo_", p, "_orig")
  if (!(v %in% names(d2)) && (vo %in% names(d2)) && ("coo_isocode" %in% names(d2))) {
    cl <- unique(d2[!is.na(d2[[vo]]), c("coo_isocode", vo)])
    cl <- cl[!duplicated(cl$coo_isocode), ]
    mu <- mean(cl[[vo]]); s <- sd(cl[[vo]])
    d2[[v]] <- (d2[[vo]] - mu) / s
  }
}

if (!("countrywave" %in% names(d2))) {
  d2$countrywave <- paste(d2$country, d2$wave, sep = "_")
}
cl2 <- if ("coo" %in% names(d2)) "coo" else "coo_isocode"
d2$clid <- d2[[cl2]]

ctrl_mig <- "female + age + imfemale + image + coo_oecd"
run2 <- function(rhs, data) {
  tryCatch(
    feols(as.formula(paste0("pv1math ~ ", rhs, " | countrywave")), data = data,
          cluster = ~clid, fixef.rm = "none"),
    error = function(e) { message("T2 model failed: ", conditionMessage(e)); NULL })
}

m2c1 <- run2(paste("coo_patience +", ctrl_mig), d2)
m2c3 <- run2(paste("coo_patience + coo_risktaking +", ctrl_mig), d2)
m2c4 <- run2(paste("coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +", ctrl_mig), d2)

if (!is.null(m2c3)) print(summary(m2c3))
if (!is.null(m2c4)) print(summary(m2c4))

emit("table2_col3_patience", safe_coef(m2c3, "coo_patience"))
emit("table2_col3_risk_taking", safe_coef(m2c3, "coo_risktaking"))
emit("table2_col1_patience", safe_coef(m2c1, "coo_patience"))
emit("table2_col4_patience", safe_coef(m2c4, "coo_patience"))
emit("table2_col4_risk_taking", safe_coef(m2c4, "coo_risktaking"))
emit("table2_col3_observations", if (!is.null(m2c3)) nobs(m2c3) else NA)