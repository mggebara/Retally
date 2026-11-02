suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(sandwich)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change"
f <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(haven::zap_labels(haven::read_dta(f)))

# county id (Stata encode: empty string -> missing)
cn <- as.character(d$GAZ_CNTY)
cn[!is.na(cn) & trimws(cn) == ""] <- NA
d$county_id <- as.integer(factor(cn))

# per-capita variables
d$mills_pc   <- d$mills / d$pcmean
d$wrights_pc <- d$wrights / d$pcmean

# wheat suitability and river suitability
d$wheat_suit <- ifelse(is.na(d$wheat_tmean), NA, as.numeric(d$wheat_tmean <= 5))
d$riv_rug26count <- d$riv_rug26count / 1000
d$msuit26mean <- d$wheat_suit * d$riv_rug26count

mind <- grep("^min_dist", names(d), value = TRUE)

geo  <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agr  <- c("suitmean", "wheat_suit", "dist_grass_mean")
clim <- c("precip_mean_dist", "temp_mean_dist")
oth  <- c("pcmean", "min_harbor", "DIST_London", mind, "area")

out <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) out[[name]] <<- val
}

ols <- function(ctrls) {
  fml <- as.formula(paste("wrights_pc ~", paste(c("mills_pc", ctrls), collapse = " + ")))
  feols(fml, data = d, cluster = ~county_id)
}

# Table 2
t2c <- list(
  character(0),
  geo,
  c(geo, agr),
  c(geo, agr, clim),
  c(geo, agr, clim, oth)
)
nobs5 <- NA
for (i in seq_along(t2c)) {
  m <- tryCatch(ols(t2c[[i]]), error = function(e) NULL)
  if (!is.null(m)) {
    emit(sprintf("watermills_table2_col%d", i), unname(coef(m)["mills_pc"]))
    if (i == 5) nobs5 <- nobs(m)
  }
}

# Table 3 col 5 OLS
t3_full <- c("wheat_suit", "riv_rug26count", "longitude", "latitude", "dist_rug_mean",
             "dist_elevation_mean", "suitmean", "dist_grass_mean", "precip_mean_dist",
             "temp_mean_dist", "min_harbor", "DIST_London", mind, "pcmean", "area")
m35 <- tryCatch(ols(t3_full), error = function(e) NULL)
if (!is.null(m35)) emit("watermills_ols_table3_col5", unname(coef(m35)["mills_pc"]))

# IV specs
iv_ctrls <- list(
  col2 = c("riv_rug26count", "wheat_suit"),
  col4 = c("wheat_suit", "riv_rug26count", "longitude", "latitude", "dist_rug_mean",
           "dist_elevation_mean", "suitmean", "dist_grass_mean", "precip_mean_dist",
           "temp_mean_dist"),
  col6 = t3_full
)

# ivreg2 Kleibergen-Paap Wald F (single endogenous, single instrument, clustered):
# chi2 from unadjusted cluster VCV, then F = chi2/N*(N-K)/L*(G-1)/G
kp_f <- function(ctrls) {
  vars <- c("wrights_pc", "mills_pc", "msuit26mean", ctrls, "county_id")
  s <- d[complete.cases(d[, vars]), ]
  fs <- lm(as.formula(paste("mills_pc ~", paste(c("msuit26mean", ctrls), collapse = " + "))), data = s)
  V0 <- sandwich::vcovCL(fs, cluster = ~county_id, type = "HC0", cadjust = FALSE)
  b <- coef(fs)["msuit26mean"]
  chi2 <- b^2 / V0["msuit26mean", "msuit26mean"]
  N <- nrow(s); K <- length(coef(fs)); G <- length(unique(s$county_id)); L <- 1
  unname(chi2 / N * (N - K) / L * (G - 1) / G)
}

for (nm in names(iv_ctrls)) {
  ctrls <- iv_ctrls[[nm]]
  fml <- as.formula(paste("wrights_pc ~", paste(ctrls, collapse = " + "),
                          "| mills_pc ~ msuit26mean"))
  m <- tryCatch(feols(fml, data = d, cluster = ~county_id), error = function(e) NULL)
  if (!is.null(m)) emit(paste0("watermills_iv_table3_", nm), unname(coef(m)["fit_mills_pc"]))
  fv <- tryCatch(kp_f(ctrls), error = function(e) NA)
  emit(paste0("first_stage_f_table3_", nm), fv)
}

emit("n_districts_tables2_3", nobs5)

for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))