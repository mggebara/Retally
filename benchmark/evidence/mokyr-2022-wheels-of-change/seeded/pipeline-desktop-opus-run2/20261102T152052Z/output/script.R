suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change"
dta_path <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
csv_path <- file.path(base, "3 replication package/Replication files/Data/replication_data.csv")

df <- tryCatch(as.data.frame(haven::zap_labels(haven::read_dta(dta_path))),
               error = function(e) NULL)
if (is.null(df)) {
  df <- as.data.frame(readr::read_csv(csv_path, show_col_types = FALSE))
}

# ---- Preprocessing (main.do) ----
# county_id = encode GAZ_CNTY (empty string -> missing, dropped in clustered regs)
g <- as.character(df$GAZ_CNTY)
g[!is.na(g) & trimws(g) == ""] <- NA
df$county_id <- as.integer(factor(g, levels = sort(unique(g[!is.na(g)]))))

num <- function(x) suppressWarnings(as.numeric(x))
df$pcmean <- num(df$pcmean)
df$mills_pc <- num(df$mills) / df$pcmean
df$wrights_pc <- num(df$wrights) / df$pcmean

df$wheat_tmean <- num(df$wheat_tmean)
df$wheat_suit <- ifelse(is.na(df$wheat_tmean), NA, as.numeric(df$wheat_tmean <= 5))

rivcols <- grep("^riv_rug.*count$", names(df), value = TRUE)
for (v in rivcols) df[[v]] <- num(df[[v]]) / 1000
df$msuit26mean <- df$wheat_suit * df$riv_rug26count

min_dist_vars <- grep("^min_dist", names(df), value = TRUE)
for (v in c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean", "suitmean",
            "dist_grass_mean", "precip_mean_dist", "temp_mean_dist", "min_harbor",
            "DIST_London", "area", min_dist_vars)) {
  if (v %in% names(df)) df[[v]] <- num(df[[v]])
}

geo   <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agr   <- c("suitmean", "wheat_suit", "dist_grass_mean")
clim  <- c("precip_mean_dist", "temp_mean_dist")
other <- c("pcmean", "min_harbor", "DIST_London", min_dist_vars, "area")

mk <- function(lhs, rhs) as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")))

res <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) res[[name]] <<- val
}

ols <- function(rhs, data) {
  feols(mk("wrights_pc", rhs), data = data, cluster = ~county_id)
}

# ---- Table 2 ----
d1 <- df[!is.na(df$mills_pc) & !is.na(df$wrights_pc) & !is.na(df$county_id), ]
m1 <- tryCatch(ols("mills_pc", df), error = function(e) NULL)
if (!is.null(m1)) {
  emit("watermills_table2_col1", unname(coef(m1)["mills_pc"]))
  emit("watermills_table2_col1_se", unname(se(m1)["mills_pc"]))
  emit("n_districts_tables2_3", nobs(m1))
  samp1 <- obs(m1)
  d_s1 <- df[samp1, ]
} else {
  d_s1 <- d1
}
m2 <- tryCatch(ols(c("mills_pc", geo), d_s1), error = function(e) NULL)
m3 <- tryCatch(ols(c("mills_pc", geo, agr), df), error = function(e) NULL)
m4 <- tryCatch(ols(c("mills_pc", geo, agr, clim), df), error = function(e) NULL)
m5 <- tryCatch(ols(c("mills_pc", geo, agr, clim, other), df), error = function(e) NULL)
for (k in 2:5) {
  m <- get(paste0("m", k))
  if (!is.null(m)) {
    emit(paste0("watermills_table2_col", k), unname(coef(m)["mills_pc"]))
    emit(paste0("watermills_table2_col", k, "_se"), unname(se(m)["mills_pc"]))
    emit(paste0("n_table2_col", k), nobs(m))
  }
}

# ---- Table 3 ----
# col 5 OLS
m3_5 <- tryCatch(ols(c("mills_pc", "wheat_suit", "riv_rug26count",
                       "longitude", "latitude", "dist_rug_mean", "dist_elevation_mean",
                       "suitmean", "dist_grass_mean", "precip_mean_dist", "temp_mean_dist",
                       "min_harbor", "DIST_London", min_dist_vars, "pcmean", "area"), df),
                 error = function(e) NULL)
if (!is.null(m3_5)) {
  emit("watermills_ols_table3_col5", unname(coef(m3_5)["mills_pc"]))
  emit("watermills_ols_table3_col5_se", unname(se(m3_5)["mills_pc"]))
}

iv_run <- function(exog, tag) {
  vars <- c("wrights_pc", "mills_pc", "msuit26mean", exog, "county_id")
  d <- df[complete.cases(df[, vars]), ]
  f <- as.formula(paste("wrights_pc ~", paste(exog, collapse = " + "),
                        "| mills_pc ~ msuit26mean"))
  m <- tryCatch(feols(f, data = d, cluster = ~county_id), error = function(e) NULL)
  if (!is.null(m)) {
    emit(paste0("watermills_iv_table3_", tag), unname(coef(m)["fit_mills_pc"]))
    emit(paste0("watermills_iv_table3_", tag, "_se"), unname(se(m)["fit_mills_pc"]))
    emit(paste0("n_iv_table3_", tag), nobs(m))
  }
  # First-stage F (Kleibergen-Paap Wald F with one instrument) = squared clustered t
  fs <- tryCatch(feols(mk("mills_pc", c("msuit26mean", exog)), data = d,
                       cluster = ~county_id), error = function(e) NULL)
  if (!is.null(fs)) {
    tt <- unname(coef(fs)["msuit26mean"] / se(fs)["msuit26mean"])
    emit(paste0("first_stage_f_table3_", tag), tt^2)
  }
}

iv_run(c("riv_rug26count", "wheat_suit"), "col2")
iv_run(c("wheat_suit", "riv_rug26count", "longitude", "latitude", "dist_rug_mean",
         "dist_elevation_mean", "suitmean", "dist_grass_mean", "precip_mean_dist",
         "temp_mean_dist"), "col4")
iv_run(c("wheat_suit", "riv_rug26count", "longitude", "latitude", "dist_rug_mean",
         "dist_elevation_mean", "suitmean", "dist_grass_mean", "precip_mean_dist",
         "temp_mean_dist", "min_harbor", "DIST_London", min_dist_vars, "pcmean", "area"),
       "col6")

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, res[[nm]]))
}