suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
f_dta <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
f_csv <- file.path(base, "3 replication package/Replication files/Data/replication_data.csv")
if (file.exists(f_dta)) {
  df <- as.data.frame(haven::zap_labels(haven::read_dta(f_dta)))
} else {
  df <- as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE))
}
cat("Rows:", nrow(df), "Cols:", ncol(df), "\n")
cat("Columns:", paste(names(df), collapse = ", "), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
for (v in c("wrights", "mills", "pcmean", "area", "latitude", "longitude",
            "min_dist_to_roman_rds", "wheat_tmean", "min_dist_2nav_rivers",
            "min_harbor", "dist_grass_mean", "dist_rug_mean", "suitmean",
            "DIST_London", "precip_mean_dist", "dist_elevation_mean",
            "temp_mean_dist")) {
  if (v %in% names(df)) df[[v]] <- num(df[[v]])
}

print(summary(df[, intersect(c("wrights", "mills", "pcmean", "wheat_tmean"), names(df))]))

# ---- Per capita conversion (per 10,000 people, mean 1710-50 population) ----
is_count <- function(x) {
  x <- x[!is.na(x)]
  length(x) > 0 && all(abs(x - round(x)) < 1e-8)
}
pop <- df$pcmean
if (is_count(df$wrights)) {
  df$wrights_pc <- df$wrights / pop * 10000
  cat("wrights treated as counts -> per 10,000\n")
} else {
  df$wrights_pc <- df$wrights
  cat("wrights appear already per capita\n")
}
if (is_count(df$mills)) {
  df$mills_pc <- df$mills / pop * 10000
  cat("mills treated as counts -> per 10,000\n")
} else {
  df$mills_pc <- df$mills
  cat("mills appear already per capita\n")
}

# ---- Wheat suitability indicator: mean GAEZ category <= 5 ----
df$wheat_suit <- as.numeric(df$wheat_tmean <= 5)

# ---- River suitability: river length in terrain with ruggedness 2-6 ----
rivcols <- grep("riv", names(df), value = TRUE, ignore.case = TRUE)
cat("River-related columns:", paste(rivcols, collapse = ", "), "\n")
riv_var <- NULL
cand <- rivcols[grepl("26", rivcols) & !grepl("wheat|inter|_x_", rivcols, ignore.case = TRUE)]
if (length(cand) == 0) cand <- rivcols[grepl("2_6|2to6|2_to_6", rivcols, ignore.case = TRUE)]
if (length(cand) > 0) {
  cand_count <- cand[grepl("count", cand)]
  riv_var <- if (length(cand_count) > 0) cand_count[1] else cand[1]
  df$river_suit <- num(df[[riv_var]])
} else {
  # try to build from finer bins: sum bins lying within [2,6]
  bins <- c("riv_rug23count", "riv_rug34count", "riv_rug45count", "riv_rug56count")
  if (all(bins %in% names(df))) {
    df$river_suit <- rowSums(sapply(bins, function(b) num(df[[b]])))
    riv_var <- paste(bins, collapse = "+")
  } else if (all(c("riv_rug06count", "riv_rug02count") %in% names(df))) {
    df$river_suit <- num(df$riv_rug06count) - num(df$riv_rug02count)
    riv_var <- "riv_rug06count - riv_rug02count"
  } else {
    stop("Could not identify river suitability (ruggedness 2-6) column")
  }
}
cat("River suitability variable:", riv_var, "\n")
df$iv_grind <- df$river_suit * df$wheat_suit

# ---- Control sets ----
geo   <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agri  <- c("suitmean", "wheat_suit", "dist_grass_mean")
clim  <- c("precip_mean_dist", "temp_mean_dist")
other <- c("pcmean", "min_harbor", "DIST_London", "min_dist_to_roman_rds",
           "min_dist_2nav_rivers", "area")

allvars <- unique(c("wrights_pc", "mills_pc", geo, agri, clim, other,
                    "river_suit", "iv_grind", "GAZ_CNTY"))
missing_vars <- setdiff(allvars, names(df))
if (length(missing_vars) > 0) stop(paste("Missing variables:", paste(missing_vars, collapse = ", ")))

# Sample: districts with Domesday mill data and complete covariates
samp <- df[complete.cases(df[, allvars]) & is.finite(df$mills_pc) & is.finite(df$wrights_pc), ]
cat("Estimation sample N =", nrow(samp), "\n")

cl <- ~GAZ_CNTY
fml <- function(ctrls) {
  rhs <- c("mills_pc", ctrls)
  as.formula(paste("wrights_pc ~", paste(rhs, collapse = " + ")))
}

# ---- Table 2 ----
t2 <- list(
  c1 = character(0),
  c2 = geo,
  c3 = c(geo, agri),
  c4 = c(geo, agri, clim),
  c5 = c(geo, agri, clim, other)
)
t2m <- lapply(t2, function(ct) feols(fml(ct), data = samp, cluster = cl))
for (nm in names(t2m)) {
  m <- t2m[[nm]]
  cat(sprintf("Table2 %s: b=%.4f se=%.4f N=%d adjR2=%.3f\n", nm,
              coef(m)["mills_pc"], se(m)["mills_pc"], nobs(m),
              fitstat(m, "ar2")[[1]]))
}

# ---- Table 3 ----
ctrl_full <- c(geo, agri, clim, other)
m_ols5 <- feols(fml(c(ctrl_full, "river_suit")), data = samp, cluster = cl)

ivf <- function(ctrls) {
  ctrls <- unique(c("river_suit", "wheat_suit", ctrls))
  as.formula(paste("wrights_pc ~", paste(ctrls, collapse = " + "),
                   "| mills_pc ~ iv_grind"))
}
iv2 <- feols(ivf(character(0)), data = samp, cluster = cl)
iv4 <- feols(ivf(c(geo, agri, clim)), data = samp, cluster = cl)
iv6 <- feols(ivf(ctrl_full), data = samp, cluster = cl)

fs_F <- function(m) {
  out <- tryCatch({
    w <- fitstat(m, "ivwald1")
    v <- w[[1]]
    if (is.list(v)) v$stat else as.numeric(v)
  }, error = function(e) NA_real_)
  if (is.na(out)) {
    out <- tryCatch({
      fs <- m$iv_first_stage[[1]]
      (coef(fs)["iv_grind"] / se(fs)["iv_grind"])^2
    }, error = function(e) NA_real_)
  }
  as.numeric(out)
}

for (nm in c("iv2", "iv4", "iv6")) {
  m <- get(nm)
  cat(sprintf("Table3 %s: b=%.4f se=%.4f N=%d F=%.2f\n", nm,
              coef(m)["fit_mills_pc"], se(m)["fit_mills_pc"], nobs(m), fs_F(m)))
}
cat(sprintf("Table3 OLS5: b=%.4f se=%.4f\n", coef(m_ols5)["mills_pc"], se(m_ols5)["mills_pc"]))

# ---- Results ----
cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(t2m$c1)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(t2m$c2)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(t2m$c3)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(t2m$c4)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(t2m$c5)["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(m_ols5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(iv2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(iv4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(iv6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.6f\n", fs_F(iv2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.6f\n", fs_F(iv4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.6f\n", fs_F(iv6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", as.integer(nobs(t2m$c5))))
