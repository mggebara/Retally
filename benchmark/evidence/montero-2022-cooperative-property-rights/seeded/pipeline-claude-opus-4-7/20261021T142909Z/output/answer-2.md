#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_path <- "/Users/matthew/dev/Retally/.cache/datasets/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta"
df <- read_dta(data_path)

# Create real income measure - try using existing variable if available, else construct
# The paper likely uses a different deflator base. Try constructing with 2007 as base year.
cpi <- c(`2000`=71.57, `2001`=74.25, `2004`=80.68, `2005`=84.47, `2006`=87.88,
         `2007`=91.90, `2008`=98.06, `2009`=99.10, `2011`=105.13, `2012`=106.95, `2013`=107.79)

# Check for pre-existing real income variable
if ("hh_inc_pc_real" %in% names(df)) {
  # use existing
} else {
  df$hh_inc_pc_real <- NA_real_
  for (y in names(cpi)) {
    yi <- as.integer(y)
    idx <- which(df$year == yi)
    df$hh_inc_pc_real[idx] <- df$hh_income_pc[idx] * cpi[y] / 100
  }
}

# Identify i_year* columns
i_year_vars <- grep("^i_year", names(df), value = TRUE)

# ----- Columns 1 & 2: Levels regressions (workers) -----
# Don't filter on all covariates upfront - let the regression handle it
df_lvl <- df %>% filter(!is.na(hh_inc_pc_real), !is.na(Above500), !is.na(norm_dist),
                        !is.na(Expropretario_ISTA))

make_formula_lvl <- function(iy_vars) {
  rhs <- paste(c("Above500", "norm_dist", "I(norm_dist*Above500)",
                 iy_vars, "sex", "age", "age2"), collapse = " + ")
  as.formula(paste("hh_inc_pc_real ~", rhs))
}

# bw 300
d1 <- df_lvl %>% filter(abs(norm_dist) < 300)
iy1 <- i_year_vars[sapply(i_year_vars, function(v) length(unique(d1[[v]])) > 1)]
m1 <- feols(make_formula_lvl(iy1), data = d1, cluster = ~Expropretario_ISTA)
coef1 <- coef(m1)["Above500"]
n1 <- nobs(m1)

# bw 150
d2 <- df_lvl %>% filter(abs(norm_dist) < 150)
iy2 <- i_year_vars[sapply(i_year_vars, function(v) length(unique(d2[[v]])) > 1)]
m2 <- feols(make_formula_lvl(iy2), data = d2, cluster = ~Expropretario_ISTA)
coef2 <- coef(m2)["Above500"]
n2 <- nobs(m2)

# ----- Columns 3 & 4: IQR by property -----
df_iqr_src <- df %>% filter(!is.na(hh_inc_pc_real), !is.na(norm_dist), !is.na(Above500),
                            !is.na(Expropretario_ISTA))

group_vars <- c("match_id", "Expropretario_ISTA", i_year_vars)

# Use Stata's default IQR (type 2 quantiles)
iqr_fn <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  as.numeric(diff(quantile(x, probs = c(0.25, 0.75), type = 2)))
}

coll <- df_iqr_src %>%
  group_by(across(all_of(group_vars))) %>%
  summarise(hh_inc_pc_real = iqr_fn(hh_inc_pc_real),
            num_members = mean(num_members, na.rm = TRUE),
            norm_dist = mean(norm_dist, na.rm = TRUE),
            Above500 = mean(Above500, na.rm = TRUE),
            .groups = "drop") %>%
  filter(!is.na(hh_inc_pc_real), !is.na(norm_dist), !is.na(Above500))

make_formula_iqr <- function(iy_vars) {
  rhs <- paste(c("Above500", "norm_dist", "I(norm_dist*Above500)", iy_vars), collapse = " + ")
  as.formula(paste("hh_inc_pc_real ~", rhs))
}

# bw 300
d3 <- coll %>% filter(abs(norm_dist) < 300)
iy3 <- i_year_vars[sapply(i_year_vars, function(v) length(unique(d3[[v]])) > 1)]
m3 <- feols(make_formula_iqr(iy3), data = d3, cluster = ~Expropretario_ISTA)
coef3 <- coef(m3)["Above500"]
n3 <- nobs(m3)
cl3 <- length(unique(d3$Expropretario_ISTA))

# bw 150
d4 <- coll %>% filter(abs(norm_dist) < 150)
iy4 <- i_year_vars[sapply(i_year_vars, function(v) length(unique(d4[[v]])) > 1)]
m4 <- feols(make_formula_iqr(iy4), data = d4, cluster = ~Expropretario_ISTA)
coef4 <- coef(m4)["Above500"]
n4 <- nobs(m4)
cl4 <- length(unique(d4$Expropretario_ISTA))

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", coef1))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", coef2))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", coef3))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", coef4))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(n1)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(n2)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(n3)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(n4)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(cl3)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(cl4)))