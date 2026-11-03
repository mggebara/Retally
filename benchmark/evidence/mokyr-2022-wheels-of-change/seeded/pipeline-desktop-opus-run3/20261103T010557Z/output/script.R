suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change"
dta_path <- file.path(base_dir, "3 replication package", "Replication files", "Data", "replication_data.dta")
df <- haven::read_dta(dta_path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)

# county_id = encode GAZ_CNTY
cnty <- as.character(df$GAZ_CNTY)
cnty[!is.na(cnty) & cnty == ""] <- NA
df$county_id <- as.integer(factor(cnty))

# Per-capita variables (1710-50)
for (v in c("mills", "wrights")) {
  df[[paste0(v, "_pc")]] <- df[[v]] / df$pcmean
}

# Wheat suitability indicator
df$wheat_suit <- ifelse(is.na(df$wheat_tmean), NA_real_, as.numeric(df$wheat_tmean <= 5))

# River suitability variables rescaled by 1000
rivvars <- grep("^riv_rug.*count$", names(df), value = TRUE)
for (v in rivvars) df[[v]] <- df[[v]] / 1000

# Instrument
df$msuit26mean <- df$wheat_suit * df$riv_rug26count

min_dist_vars <- grep("^min_dist", names(df), value = TRUE)

geo   <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agri3 <- c("suitmean", "wheat_suit", "dist_grass_mean")
clim  <- c("precip_mean_dist", "temp_mean_dist")
other <- c("pcmean", "min_harbor", "DIST_London", min_dist_vars, "area")

mk <- function(lhs, rhs) as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")))
cl <- ~county_id

# ---------------- Table 2 ----------------
m1 <- feols(mk("wrights_pc", "mills_pc"), data = df, cluster = cl)
s1 <- df[!is.na(df$wrights_pc) & !is.na(df$mills_pc) & !is.na(df$county_id), ]
m2 <- feols(mk("wrights_pc", c("mills_pc", geo)), data = s1, cluster = cl)
m3 <- feols(mk("wrights_pc", c("mills_pc", geo, agri3)), data = df, cluster = cl)
m4 <- feols(mk("wrights_pc", c("mills_pc", geo, agri3, clim)), data = df, cluster = cl)
m5 <- feols(mk("wrights_pc", c("mills_pc", geo, agri3, clim, other)), data = df, cluster = cl)

# ---------------- Table 3 ----------------
geo3  <- c("longitude", "latitude", "dist_rug_mean", "dist_elevation_mean")
agri2 <- c("suitmean", "dist_grass_mean")
other3 <- c("min_harbor", "DIST_London", min_dist_vars, "pcmean", "area")

ivf <- function(ctrls) {
  as.formula(paste("wrights_pc ~", paste(ctrls, collapse = " + "), "| mills_pc ~ msuit26mean"))
}

ctrl2 <- c("riv_rug26count", "wheat_suit")
ctrl4 <- c("wheat_suit", "riv_rug26count", geo3, agri2, clim)
ctrl6 <- c("wheat_suit", "riv_rug26count", geo3, agri2, clim, other3)

ols5 <- feols(mk("wrights_pc", c("mills_pc", ctrl6)), data = df, cluster = cl)
iv2 <- feols(ivf(ctrl2), data = df, cluster = cl)
iv4 <- feols(ivf(ctrl4), data = df, cluster = cl)
iv6 <- feols(ivf(ctrl6), data = df, cluster = cl)

# Kleibergen-Paap rk Wald F (ivreg2 widstat) for just-identified case with clustering:
# Wald from unadjusted cluster VCE in the first stage, scaled by (N-K)/N * (G-1)/G
kp_f <- function(ctrls) {
  fs_vars <- c("mills_pc", "msuit26mean", ctrls, "wrights_pc", "county_id")
  d <- df[complete.cases(df[, fs_vars]), ]
  fs <- feols(mk("mills_pc", c("msuit26mean", ctrls)), data = d,
              vcov = vcov_cluster("county_id", ssc = ssc(adj = FALSE, cluster.adj = FALSE)))
  b <- coef(fs)["msuit26mean"]
  V <- vcov(fs)["msuit26mean", "msuit26mean"]
  wald <- as.numeric(b^2 / V)
  N <- nobs(fs)
  K <- length(coef(fs))
  G <- length(unique(d$county_id))
  wald * (N - K) / N * (G - 1) / G
}

f2 <- kp_f(ctrl2)
f4 <- kp_f(ctrl4)
f6 <- kp_f(ctrl6)

cf <- function(m) unname(coef(m)["mills_pc"])
se <- function(m) unname(sqrt(diag(vcov(m)))["mills_pc"])
fitb <- function(m) unname(coef(m)["fit_mills_pc"])
fitse <- function(m) unname(sqrt(diag(vcov(m)))["fit_mills_pc"])

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("watermills_table2_col1", cf(m1))
out("watermills_table2_col2", cf(m2))
out("watermills_table2_col3", cf(m3))
out("watermills_table2_col4", cf(m4))
out("watermills_table2_col5", cf(m5))
out("watermills_ols_table3_col5", cf(ols5))
out("watermills_iv_table3_col2", fitb(iv2))
out("watermills_iv_table3_col4", fitb(iv4))
out("watermills_iv_table3_col6", fitb(iv6))
out("first_stage_f_table3_col2", f2)
out("first_stage_f_table3_col4", f4)
out("first_stage_f_table3_col6", f6)
out("n_districts_tables2_3", nobs(m5))

out("watermills_table2_col1_se", se(m1))
out("watermills_table2_col2_se", se(m2))
out("watermills_table2_col3_se", se(m3))
out("watermills_table2_col4_se", se(m4))
out("watermills_table2_col5_se", se(m5))
out("watermills_ols_table3_col5_se", se(ols5))
out("watermills_iv_table3_col2_se", fitse(iv2))
out("watermills_iv_table3_col4_se", fitse(iv4))
out("watermills_iv_table3_col6_se", fitse(iv6))
out("n_districts_table2_col1", nobs(m1))
out("n_districts_table3_col6", nobs(iv6))