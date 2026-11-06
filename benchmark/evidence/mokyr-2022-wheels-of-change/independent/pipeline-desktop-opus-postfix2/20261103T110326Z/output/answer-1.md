suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
path <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
df <- as.data.frame(haven::zap_labels(haven::read_dta(path)))

cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(df)))

# Isles of Scilly (missing HYDE population) should already be absent (325 rows)
df <- df[!is.na(df$pcmean) & df$pcmean > 0, ]
cat(sprintf("SAMPLE:main:drop_missing_population_1710_50=%d\n", nrow(df)))

# Districts not covered by Domesday Book (missing mills)
df <- df[!is.na(df$mills), ]
cat(sprintf("SAMPLE:main:domesday_coverage=%d\n", nrow(df)))
if (nrow(df) != 298) {
  cat(sprintf("DEVIATION: Domesday-covered sample has %d districts, paper reports 298\n", nrow(df)))
}

# Per 10,000 people using mean population 1710-50
df$wrights_pc <- df$wrights / df$pcmean * 10000
df$mills_pc   <- df$mills   / df$pcmean * 10000

# High wheat suitability indicator: mean category <= 5 (lower = more suitable)
df$wheat_suit <- as.numeric(df$wheat_tmean <= 5)
# River suitability: length of rivers through ruggedness 2-6
df$river_suit <- df$riv_rug26count
df$grind_iv   <- df$river_suit * df$wheat_suit

geo   <- "latitude + longitude + dist_rug_mean + dist_elevation_mean"
agri  <- "suitmean + wheat_suit + dist_grass_mean"
clim  <- "precip_mean_dist + temp_mean_dist"
other <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"

f2 <- list(
  c1 = "wrights_pc ~ mills_pc",
  c2 = paste("wrights_pc ~ mills_pc +", geo),
  c3 = paste("wrights_pc ~ mills_pc +", geo, "+", agri),
  c4 = paste("wrights_pc ~ mills_pc +", geo, "+", agri, "+", clim),
  c5 = paste("wrights_pc ~ mills_pc +", geo, "+", agri, "+", clim, "+", other)
)

t2 <- lapply(f2, function(f) feols(as.formula(f), data = df, cluster = ~GAZ_CNTY))
for (nm in names(t2)) {
  cat(sprintf("SAMPLE:table2_%s:estimation=%d\n", nm, nobs(t2[[nm]])))
}

# Table 3
ctrl_iv2 <- "river_suit + wheat_suit"
ctrl_iv4 <- paste("river_suit + wheat_suit + latitude + longitude + dist_rug_mean + dist_elevation_mean + suitmean + dist_grass_mean +", clim)
ctrl_iv6 <- paste(ctrl_iv4, "+", other)

ols5_t3 <- feols(as.formula(paste("wrights_pc ~ mills_pc +", ctrl_iv6)), data = df, cluster = ~GAZ_CNTY)
iv2 <- feols(as.formula(paste("wrights_pc ~", ctrl_iv2, "| mills_pc ~ grind_iv")), data = df, cluster = ~GAZ_CNTY)
iv4 <- feols(as.formula(paste("wrights_pc ~", ctrl_iv4, "| mills_pc ~ grind_iv")), data = df, cluster = ~GAZ_CNTY)
iv6 <- feols(as.formula(paste("wrights_pc ~", ctrl_iv6, "| mills_pc ~ grind_iv")), data = df, cluster = ~GAZ_CNTY)

cat(sprintf("SAMPLE:table3_ols5:estimation=%d\n", nobs(ols5_t3)))
cat(sprintf("SAMPLE:table3_iv2:estimation=%d\n", nobs(iv2)))
cat(sprintf("SAMPLE:table3_iv4:estimation=%d\n", nobs(iv4)))
cat(sprintf("SAMPLE:table3_iv6:estimation=%d\n", nobs(iv6)))

fs_f <- function(m) {
  out <- tryCatch({
    w <- fitstat(m, "ivwald1", cluster = ~GAZ_CNTY)
    v <- w[[1]]
    if (is.list(v)) v$stat else as.numeric(v)
  }, error = function(e) NA_real_)
  if (is.na(out)) {
    out <- tryCatch({
      fs <- m$iv_first_stage[[1]]
      tval <- coef(fs)["grind_iv"] / se(fs, cluster = ~GAZ_CNTY)["grind_iv"]
      as.numeric(tval^2)
    }, error = function(e) NA_real_)
  }
  out
}

g <- function(m) unname(coef(m)["mills_pc"])
giv <- function(m) unname(coef(m)["fit_mills_pc"])

for (i in 1:5) {
  m <- t2[[i]]
  cat(sprintf("RESULT:watermills_table2_col%d=%.6f\n", i, g(m)))
  cat(sprintf("RESULT:watermills_table2_col%d_se=%.6f\n", i, unname(se(m)["mills_pc"])))
}
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", g(ols5_t3)))
cat(sprintf("RESULT:watermills_ols_table3_col5_se=%.6f\n", unname(se(ols5_t3)["mills_pc"])))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", giv(iv2)))
cat(sprintf("RESULT:watermills_iv_table3_col2_se=%.6f\n", unname(se(iv2)["fit_mills_pc"])))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", giv(iv4)))
cat(sprintf("RESULT:watermills_iv_table3_col4_se=%.6f\n", unname(se(iv4)["fit_mills_pc"])))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", giv(iv6)))
cat(sprintf("RESULT:watermills_iv_table3_col6_se=%.6f\n", unname(se(iv6)["fit_mills_pc"])))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", fs_f(iv2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", fs_f(iv4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", fs_f(iv6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(t2[[5]])))
