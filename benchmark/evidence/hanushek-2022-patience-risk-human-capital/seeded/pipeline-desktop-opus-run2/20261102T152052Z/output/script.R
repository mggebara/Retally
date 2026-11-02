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

results <- list()
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) {
    results[[name]] <<- value
  }
}

to_plain <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled") || inherits(x, "labelled")) {
      x <- zap_labels(x)
    }
    attributes(x)[c("label", "format.stata", "labels")] <- NULL
    df[[v]] <- x
  }
  df
}

load_data <- function(dta, csv, cols) {
  df <- tryCatch({
    d <- read_dta(dta, col_select = tidyselect::any_of(cols))
    to_plain(d)
  }, error = function(e) {
    message("read_dta failed: ", conditionMessage(e))
    NULL
  })
  if (is.null(df)) {
    df <- tryCatch({
      hdr <- names(fread(csv, nrows = 0))
      sel <- intersect(cols, hdr)
      as.data.frame(fread(csv, select = sel, showProgress = FALSE))
    }, error = function(e) {
      message("fread failed: ", conditionMessage(e))
      NULL
    })
  }
  df
}

safe_coef <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

# ---------------------------------------------------------------------------
# TABLE 1: cross-country (full sample)
# ---------------------------------------------------------------------------
cols_full <- c("pv1math", "patience", "risktaking", "posrecip", "negrecip",
               "altruism", "trust", "female", "age", "migra0", "migra1",
               "migra2", "image", "imfemale", "immigra1", "wave", "wgtc",
               "country")

full <- load_data(f_full_dta, f_full_csv, cols_full)
gc()

if (!is.null(full)) {
  full$wave <- factor(full$wave)

  run_t1 <- function(fml, data) {
    tryCatch(
      feols(fml, data = data, weights = ~wgtc, cluster = ~country,
            fixef.rm = "none", warn = FALSE, notes = FALSE),
      error = function(e) { message("feols error: ", conditionMessage(e)); NULL }
    )
  }

  ctrl <- "female + age + migra1 + migra2 + image + imfemale + immigra1"

  m1 <- run_t1(as.formula(paste("pv1math ~ patience +", ctrl, "| wave")), full)
  emit("table1_col1_patience", safe_coef(m1, "patience"))
  rm(m1); gc()

  m2 <- run_t1(as.formula(paste("pv1math ~ risktaking +", ctrl, "| wave")), full)
  emit("table1_col2_risk_taking", safe_coef(m2, "risktaking"))
  rm(m2); gc()

  m3 <- run_t1(as.formula(paste("pv1math ~ patience + risktaking +", ctrl, "| wave")), full)
  emit("table1_col3_patience", safe_coef(m3, "patience"))
  emit("table1_col3_risk_taking", safe_coef(m3, "risktaking"))
  if (!is.null(m3)) emit("table1_col3_observations", as.numeric(nobs(m3)))
  rm(m3); gc()

  nat <- full[!is.na(full$migra0) & full$migra0 == 1, ]
  m5 <- run_t1(pv1math ~ patience + risktaking + female + age + image + imfemale | wave, nat)
  emit("table1_col5_natives_patience", safe_coef(m5, "patience"))
  emit("table1_col5_natives_risk_taking", safe_coef(m5, "risktaking"))
  rm(m5, nat); gc()
}
rm(full); gc()

# ---------------------------------------------------------------------------
# TABLE 2: migrant analysis (country-of-origin preferences)
# ---------------------------------------------------------------------------
cols_mig <- c("pv1math", "coo_patience", "coo_risktaking", "coo_posrecip",
              "coo_negrecip", "coo_altruism", "coo_trust", "female", "age",
              "imfemale", "image", "coo_oecd", "countrywave", "coo")

mig <- load_data(f_mig_dta, f_mig_csv, cols_mig)

if (!is.null(mig)) {
  mig$countrywave <- factor(mig$countrywave)

  run_t2 <- function(fml) {
    tryCatch(
      feols(fml, data = mig, cluster = ~coo, fixef.rm = "none",
            warn = FALSE, notes = FALSE),
      error = function(e) { message("feols error: ", conditionMessage(e)); NULL }
    )
  }

  ctrl2 <- "female + age + imfemale + image + coo_oecd"

  t1 <- run_t2(as.formula(paste("pv1math ~ coo_patience +", ctrl2, "| countrywave")))
  emit("table2_col1_patience", safe_coef(t1, "coo_patience"))

  t3 <- run_t2(as.formula(paste("pv1math ~ coo_patience + coo_risktaking +", ctrl2, "| countrywave")))
  emit("table2_col3_patience", safe_coef(t3, "coo_patience"))
  emit("table2_col3_risk_taking", safe_coef(t3, "coo_risktaking"))
  if (!is.null(t3)) emit("table2_col3_observations", as.numeric(nobs(t3)))

  t4 <- run_t2(as.formula(paste(
    "pv1math ~ coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +",
    ctrl2, "| countrywave")))
  emit("table2_col4_patience", safe_coef(t4, "coo_patience"))
  emit("table2_col4_risk_taking", safe_coef(t4, "coo_risktaking"))
}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
order_names <- c("table1_col3_patience", "table1_col3_risk_taking",
                 "table1_col1_patience", "table1_col2_risk_taking",
                 "table1_col5_natives_patience", "table1_col5_natives_risk_taking",
                 "table1_col3_observations",
                 "table2_col3_patience", "table2_col3_risk_taking",
                 "table2_col1_patience", "table2_col4_patience",
                 "table2_col4_risk_taking", "table2_col3_observations")

for (nm in order_names) {
  if (!is.null(results[[nm]])) {
    val <- results[[nm]]
    if (grepl("observations", nm)) {
      cat(sprintf("RESULT:%s=%d\n", nm, as.integer(round(val))))
    } else {
      cat(sprintf("RESULT:%s=%.6f\n", nm, val))
    }
  }
}