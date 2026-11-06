suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
df <- readr::read_csv(file.path(base, "3 replication package/Replication files/Data/replication_data.csv"),
                      show_col_types = FALSE)
df <- as.data.frame(df)

num_cols <- c("wrights", "mills", "pcmean", "latitude", "longitude", "dist_rug_mean",
              "dist_elevation_mean", "suitmean", "wheat_tmean", "dist_grass_mean",
              "precip_mean_dist", "temp_mean_dist", "min_harbor", "DIST_London",
              "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area", "riv_rug26count")
for (v in num_cols) df[[v]] <- suppressWarnings(as.numeric(df[[v]]))

cat(sprintf("SAMPLE:table2:loaded=%d\n", nrow(df)))
s <- df %>% filter(!is.na(pcmean) & pcmean > 0)
cat(sprintf("SAMPLE:table2:population_available=%d\n", nrow(s)))
s <- s %>% filter(!is.na(mills))
cat(sprintf("SAMPLE:table2:domesday_mills_available=%d\n", nrow(s)))

# Per-capita variables (apprentices / mills per 10,000 people of mean 1710-50 population)
s <- s %>% mutate(
  wrights_pc = wrights / pcmean * 10000,
  mills_pc   = mills / pcmean * 10000,
  wheat_suit = as.numeric(wheat_tmean <= 5),
  river_suit = riv_rug26count,
  instr      = riv_rug26count * as.numeric(wheat_tmean <= 5)
)

geo   <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agri  <- c("suitmean", "wheat_suit", "dist_grass_mean")
clim  <- c("precip_mean_dist", "temp_mean_dist")
other <- c("pcmean", "min_harbor", "DIST_London", "min_dist_to_roman_rds",
           "min_dist_2nav_rivers", "area")

mk <- function(rhs) if (length(rhs) == 0) "1" else paste(rhs, collapse = " + ")

ols_fit <- function(ctrl) {
  f <- as.formula(paste("wrights_pc ~ mills_pc +", mk(ctrl)))
  feols(f, data = s, cluster = ~GAZ_CNTY)
}

m1 <- feols(wrights_pc ~ mills_pc, data = s, cluster = ~GAZ_CNTY)
m2 <- ols_fit(geo)
m3 <- ols_fit(c(geo, agri))
m4 <- ols_fit(c(geo, agri, clim))
m5 <- ols_fit(c(geo, agri, clim, other))
cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m5)))

# Table 3
ctrl_iv2 <- c("river_suit", "wheat_suit")
ctrl_iv4 <- c("river_suit", geo, agri, clim)
ctrl_iv6 <- c(ctrl_iv4, other)

ols3_5 <- ols_fit(ctrl_iv6)

iv_fit <- function(ctrl) {
  f <- as.formula(paste("wrights_pc ~", mk(unique(ctrl)), "| mills_pc ~ instr"))
  feols(f, data = s, cluster = ~GAZ_CNTY)
}
iv2 <- iv_fit(ctrl_iv2)
iv4 <- iv_fit(ctrl_iv4)
iv6 <- iv_fit(ctrl_iv6)

cat(sprintf("SAMPLE:table3:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:table3:domesday_mills_available=%d\n", nrow(s)))
cat(sprintf("SAMPLE:table3:estimation=%d\n", nobs(iv6)))

fs_F <- function(m) {
  out <- tryCatch({
    w <- fitstat(m, "ivwald1")
    as.numeric(w[[1]]$stat)
  }, error = function(e) NA_real_)
  if (is.na(out)) {
    out <- tryCatch({
      fs <- m$iv_first_stage[[1]]
      t <- coeftable(fs, cluster = ~GAZ_CNTY)["instr", "t value"]
      as.numeric(t^2)
    }, error = function(e) NA_real_)
  }
  out
}

cat(sprintf("RESULT:watermills_table2_col1=%.10g\n", coef(m1)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.10g\n", coef(m2)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.10g\n", coef(m3)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.10g\n", coef(m4)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.10g\n", coef(m5)["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.10g\n", coef(ols3_5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.10g\n", coef(iv2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.10g\n", coef(iv4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.10g\n", coef(iv6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.10g\n", fs_F(iv2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.10g\n", fs_F(iv4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.10g\n", fs_F(iv6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(m5)))