suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
f <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
raw <- haven::read_dta(f)
raw <- haven::zap_labels(raw)
df <- as.data.frame(raw)

num <- function(x) suppressWarnings(as.numeric(x))
needed <- c("wrights", "mills", "pcmean", "latitude", "longitude", "dist_rug_mean",
            "dist_elevation_mean", "suitmean", "wheat_tmean", "dist_grass_mean",
            "precip_mean_dist", "temp_mean_dist", "min_harbor", "DIST_London",
            "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area", "riv_rug26count")
for (v in needed) {
  if (!v %in% names(df)) stop(paste("Missing column:", v))
  df[[v]] <- num(df[[v]])
}

cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(df)))

# Drop districts with missing 1710-50 population (Isles of Scilly)
df <- df[!is.na(df$pcmean) & df$pcmean > 0, ]
cat(sprintf("SAMPLE:main:drop_missing_population=%d\n", nrow(df)))

# Restrict to districts covered by the Domesday Book (non-missing mills)
df <- df[!is.na(df$mills), ]
cat(sprintf("SAMPLE:main:domesday_coverage=%d\n", nrow(df)))
if (nrow(df) != 298) {
  cat(sprintf("DEVIATION: Domesday-covered sample has %d districts, paper states 298\n", nrow(df)))
}

# Per 10,000 people using mean 1710-50 population
df$wrights_pc <- df$wrights / df$pcmean * 10000
df$mills_pc   <- df$mills / df$pcmean * 10000
df$wheat_high <- as.numeric(df$wheat_tmean <= 5)
df$river_suit <- df$riv_rug26count
df$river_suit[is.na(df$river_suit)] <- 0
df$suit_iv    <- df$river_suit * df$wheat_high
df$cluster    <- as.character(df$GAZ_CNTY)

geo   <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agri  <- c("suitmean", "wheat_high", "dist_grass_mean")
clim  <- c("precip_mean_dist", "temp_mean_dist")
other <- c("pcmean", "min_harbor", "DIST_London", "min_dist_to_roman_rds",
           "min_dist_2nav_rivers", "area")

mkf <- function(ctrls) {
  rhs <- c("mills_pc", ctrls)
  as.formula(paste("wrights_pc ~", paste(rhs, collapse = " + ")))
}

specs2 <- list(
  c(),
  geo,
  c(geo, agri),
  c(geo, agri, clim),
  c(geo, agri, clim, other)
)

res <- list()
t2_models <- list()
for (i in seq_along(specs2)) {
  m <- feols(mkf(specs2[[i]]), data = df, cluster = ~cluster)
  t2_models[[i]] <- m
  res[[sprintf("watermills_table2_col%d", i)]] <- unname(coef(m)["mills_pc"])
}
cat(sprintf("SAMPLE:main:estimation=%d\n", nobs(t2_models[[5]])))

# Table 3
cat(sprintf("SAMPLE:table3:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:table3:domesday_coverage=%d\n", nrow(df)))

ols5 <- feols(mkf(unique(c(geo, agri, clim, other, "river_suit"))), data = df, cluster = ~cluster)
res[["watermills_ols_table3_col5"]] <- unname(coef(ols5)["mills_pc"])

ivspecs <- list(
  c("river_suit", "wheat_high"),
  unique(c("river_suit", "wheat_high", geo, agri, clim)),
  unique(c("river_suit", "wheat_high", geo, agri, clim, other))
)
ivcols <- c(2, 4, 6)
fsF <- list()
ivmods <- list()
for (k in seq_along(ivspecs)) {
  fml <- as.formula(paste("wrights_pc ~", paste(ivspecs[[k]], collapse = " + "),
                          "| mills_pc ~ suit_iv"))
  m <- feols(fml, data = df, cluster = ~cluster)
  ivmods[[k]] <- m
  res[[sprintf("watermills_iv_table3_col%d", ivcols[k])]] <- unname(coef(m)["fit_mills_pc"])
  Fv <- tryCatch({
    fs <- fitstat(m, "ivwald1")
    unname(fs[[1]]$stat)
  }, error = function(e) NA_real_)
  if (is.na(Fv)) {
    Fv <- tryCatch({
      fsm <- feols(as.formula(paste("mills_pc ~ suit_iv +", paste(ivspecs[[k]], collapse = " + "))),
                   data = df, cluster = ~cluster)
      unname((coef(fsm)["suit_iv"] / se(fsm)["suit_iv"])^2)
    }, error = function(e) NA_real_)
  }
  res[[sprintf("first_stage_f_table3_col%d", ivcols[k])]] <- Fv
}
cat(sprintf("SAMPLE:table3:estimation=%d\n", nobs(ivmods[[3]])))

res[["n_districts_tables2_3"]] <- nobs(t2_models[[1]])

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(res[[nm]])))
}