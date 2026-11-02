# Reproduces Table 5 (cols 1-4), following the "original results" block of Replication_file.do.
# Note: the do-file's original real-income measure gives zero weight to years outside its list
# (e.g. 2010). That behaviour is kept here because the paper's numbers were produced with it.
suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "/Users/matthew/dev/Retally/.cache/datasets/montero_2022_cooperative_property_rights"
df <- read_dta(file.path(path, "ehpm_incomemodule_wreform.dta"))
df <- zap_labels(df)
df <- as.data.frame(df)

# Running variable (Stata would resolve the abbreviation norm_dist)
if (!"norm_dist" %in% names(df)) {
  cand <- grep("^norm_dist", names(df), value = TRUE)
  cand <- setdiff(cand, "norm_dist_Above")
  if (length(cand) > 0) df$norm_dist <- df[[cand[1]]]
}
if (!"age2" %in% names(df)) df$age2 <- df$age^2

# Original real income measure
mult <- c(`2000` = 71.57, `2001` = 74.25, `2004` = 80.68, `2005` = 84.47,
          `2006` = 87.88, `2007` = 91.90, `2008` = 98.06, `2009` = 99.10,
          `2011` = 105.13, `2012` = 106.95, `2013` = 107.79)
m <- mult[as.character(df$year)]
m[is.na(m)] <- 0
df$hh_inc_pc_real <- df$hh_income_pc * as.numeric(m) / 100

iyear <- grep("^i_year", names(df), value = TRUE)
df$nd_above <- df$norm_dist * df$Above500

run_reg <- function(data, yvar, extra, bw) {
  rhs <- c("Above500", "norm_dist", "nd_above", iyear, extra)
  vars <- c(yvar, rhs, "Expropretario_ISTA")
  d <- data[!is.na(data$norm_dist) & abs(data$norm_dist) < bw, , drop = FALSE]
  d <- d[complete.cases(d[, vars]), , drop = FALSE]
  fml <- as.formula(paste(yvar, "~", paste(rhs, collapse = " + ")))
  mod <- feols(fml, data = d, cluster = ~Expropretario_ISTA)
  list(b = unname(coef(mod)["Above500"]),
       se = unname(sqrt(diag(vcov(mod)))["Above500"]),
       n = nobs(mod),
       ncl = length(unique(d$Expropretario_ISTA)))
}

# Cols 1-2: worker-level levels
r1 <- run_reg(df, "hh_inc_pc_real", c("sex", "age", "age2"), 300)
r2 <- run_reg(df, "hh_inc_pc_real", c("sex", "age", "age2"), 150)

# Cols 3-4: collapse (iqr) by property-year, casewise deletion
stata_q <- function(x, p) as.numeric(quantile(x, p, type = 2, names = FALSE))
cw_vars <- c("hh_income_pc", "hh_inc_pc_real", "num_members", "norm_dist", "Above500")
dc <- df[complete.cases(df[, cw_vars]), , drop = FALSE]
coll <- dc %>%
  group_by(across(all_of(c("match_id", "Expropretario_ISTA", iyear)))) %>%
  summarise(
    hh_inc_pc_real = stata_q(hh_inc_pc_real, 0.75) - stata_q(hh_inc_pc_real, 0.25),
    num_members = mean(num_members),
    norm_dist = mean(norm_dist),
    Above500 = mean(Above500),
    .groups = "drop"
  ) %>% as.data.frame()
coll$nd_above <- coll$norm_dist * coll$Above500

r3 <- run_reg(coll, "hh_inc_pc_real", character(0), 300)
r4 <- run_reg(coll, "hh_inc_pc_real", character(0), 150)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", r1$b))
cat(sprintf("RESULT:earnings_level_above500_bw300_se=%.4f\n", r1$se))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", r2$b))
cat(sprintf("RESULT:earnings_level_above500_bw150_se=%.4f\n", r2$se))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", r3$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300_se=%.4f\n", r3$se))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", r4$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150_se=%.4f\n", r4$se))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", r1$n))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", r2$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", r3$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", r4$n))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", r1$ncl))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", r2$ncl))
cat(sprintf("RESULT:n_clusters_iqr_bw300=%d\n", r3$ncl))
cat(sprintf("RESULT:n_clusters_iqr_bw150=%d\n", r4$ncl))