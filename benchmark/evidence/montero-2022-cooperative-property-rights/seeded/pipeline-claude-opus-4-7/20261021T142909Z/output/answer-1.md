#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta"
df <- read_dta(data_path)

# Create real income measure (original from paper's Table 5)
df <- df %>%
  mutate(hh_inc_pc_real = case_when(
    year == 2000 ~ hh_income_pc * 71.57/100,
    year == 2001 ~ hh_income_pc * 74.25/100,
    year == 2004 ~ hh_income_pc * 80.68/100,
    year == 2005 ~ hh_income_pc * 84.47/100,
    year == 2006 ~ hh_income_pc * 87.88/100,
    year == 2007 ~ hh_income_pc * 91.90/100,
    year == 2008 ~ hh_income_pc * 98.06/100,
    year == 2009 ~ hh_income_pc * 99.10/100,
    year == 2011 ~ hh_income_pc * 105.13/100,
    year == 2012 ~ hh_income_pc * 106.95/100,
    year == 2013 ~ hh_income_pc * 107.79/100,
    TRUE ~ NA_real_
  ))

# Identify i_year* columns
i_year_vars <- grep("^i_year", names(df), value = TRUE)

# ----- Columns 1 & 2: Levels regressions (workers) -----
df_lvl <- df %>% filter(!is.na(hh_inc_pc_real), !is.na(Above500),
                        !is.na(norm_dist), !is.na(sex), !is.na(age), !is.na(age2),
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
cl1 <- length(unique(d1$Expropretario_ISTA[complete.cases(d1[,c("hh_inc_pc_real","Above500","norm_dist","sex","age","age2")])]))

# bw 150
d2 <- df_lvl %>% filter(abs(norm_dist) < 150)
iy2 <- i_year_vars[sapply(i_year_vars, function(v) length(unique(d2[[v]])) > 1)]
m2 <- feols(make_formula_lvl(iy2), data = d2, cluster = ~Expropretario_ISTA)
coef2 <- coef(m2)["Above500"]
n2 <- nobs(m2)
cl2 <- length(unique(d2$Expropretario_ISTA[complete.cases(d2[,c("hh_inc_pc_real","Above500","norm_dist","sex","age","age2")])]))

# ----- Columns 3 & 4: IQR by property -----
# collapse by (match_id, Expropretario_ISTA, i_year*): IQR of hh_inc_pc_real; mean of num_members, norm_dist, Above500
# With cw (casewise) in Stata collapse: drops obs with missing on the aggregated vars.

df_iqr_src <- df %>% filter(!is.na(hh_inc_pc_real), !is.na(norm_dist), !is.na(Above500))

group_vars <- c("match_id", "Expropretario_ISTA", i_year_vars)

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