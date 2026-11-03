suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
df <- haven::read_dta(file.path(base, "3 replication package/Replication files/Data/replication_data.dta"))
df <- as.data.frame(haven::zap_labels(df))

cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(df)))

# Drop districts without a 1710-50 population figure (Isles of Scilly)
df <- df %>% filter(!is.na(pcmean) & pcmean > 0)
cat(sprintf("SAMPLE:main:drop_missing_population=%d\n", nrow(df)))

# Restrict to districts covered by the Domesday Book (mill data available)
df <- df %>% filter(!is.na(mills))
cat(sprintf("SAMPLE:main:domesday_coverage=%d\n", nrow(df)))

# Variable construction: per capita using mean 1710-50 population
df <- df %>% mutate(
  wrights_pc = wrights / pcmean,
  mills_pc   = mills / pcmean,
  wheat_suit = as.numeric(wheat_tmean <= 5),
  river_suit = riv_rug26count,
  mill_suit  = riv_rug26count * as.numeric(wheat_tmean <= 5)
)

geo   <- "latitude + longitude + dist_rug_mean + dist_elevation_mean"
agri  <- "suitmean + wheat_suit + dist_grass_mean"
clim  <- "precip_mean_dist + temp_mean_dist"
other <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"

f <- function(s) as.formula(s)
cl <- ~GAZ_CNTY

# Table 2
m1 <- feols(f("wrights_pc ~ mills_pc"), data = df, cluster = cl)
m2 <- feols(f(paste("wrights_pc ~ mills_pc +", geo)), data = df, cluster = cl)
m3 <- feols(f(paste("wrights_pc ~ mills_pc +", geo, "+", agri)), data = df, cluster = cl)
m4 <- feols(f(paste("wrights_pc ~ mills_pc +", geo, "+", agri, "+", clim)), data = df, cluster = cl)
m5 <- feols(f(paste("wrights_pc ~ mills_pc +", geo, "+", agri, "+", clim, "+", other)), data = df, cluster = cl)

# Table 3
o5 <- feols(f(paste("wrights_pc ~ mills_pc + river_suit +", geo, "+", agri, "+", clim, "+", other)),
            data = df, cluster = cl)
iv2 <- feols(f("wrights_pc ~ river_suit + wheat_suit | mills_pc ~ mill_suit"), data = df, cluster = cl)
iv4 <- feols(f(paste("wrights_pc ~ river_suit +", geo, "+", agri, "+", clim, "| mills_pc ~ mill_suit")),
             data = df, cluster = cl)
iv6 <- feols(f(paste("wrights_pc ~ river_suit +", geo, "+", agri, "+", clim, "+", other, "| mills_pc ~ mill_suit")),
             data = df, cluster = cl)

cat(sprintf("SAMPLE:main:estimation=%d\n", nobs(m5)))
cat(sprintf("SAMPLE:table3_iv:estimation=%d\n", nobs(iv6)))

fs_f <- function(m) {
  v <- tryCatch({
    fs <- fitstat(m, ~ivwald1)
    s <- fs[[1]]
    if (is.list(s)) s$stat else as.numeric(s)
  }, error = function(e) NA_real_)
  if (is.null(v) || length(v) == 0 || is.na(v[1])) {
    v <- tryCatch({
      fsm <- summary(m, stage = 1)
      t <- coeftable(fsm)["mill_suit", "t value"]
      t^2
    }, error = function(e) NA_real_)
  }
  as.numeric(v[1])
}

b <- function(m) unname(coef(m)[grep("mills_pc", names(coef(m)))[1]])

cat(sprintf("RESULT:watermills_table2_col1=%.10g\n", b(m1)))
cat(sprintf("RESULT:watermills_table2_col2=%.10g\n", b(m2)))
cat(sprintf("RESULT:watermills_table2_col3=%.10g\n", b(m3)))
cat(sprintf("RESULT:watermills_table2_col4=%.10g\n", b(m4)))
cat(sprintf("RESULT:watermills_table2_col5=%.10g\n", b(m5)))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.10g\n", b(o5)))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.10g\n", b(iv2)))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.10g\n", b(iv4)))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.10g\n", b(iv6)))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.10g\n", fs_f(iv2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.10g\n", fs_f(iv4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.10g\n", fs_f(iv6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(m5)))