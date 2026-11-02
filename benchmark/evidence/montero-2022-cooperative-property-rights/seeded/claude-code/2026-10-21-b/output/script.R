## Montero (2022) Table 5 replication, following Replication_file.do ("Replicating original results")
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/seeded/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)

## Original real income measure (as in the .do file: year 2010 gets 0 because it has no term)
defl <- c(`2000`=71.57, `2001`=74.25, `2004`=80.68, `2005`=84.47, `2006`=87.88,
          `2007`=91.90, `2008`=98.06, `2009`=99.10, `2011`=105.13, `2012`=106.95, `2013`=107.79)
f <- defl[as.character(d$year)]; f[is.na(f)] <- 0
d$hh_inc_pc_real <- d$hh_income_pc * f / 100

yr <- paste0("i_year", 1:12)
d$nd_above <- d$norm_dist * d$Above500

## Cols 1-2: worker-level levels
lvl_fml <- as.formula(paste("hh_inc_pc_real ~ Above500 + norm_dist + nd_above +",
                            paste(yr, collapse = " + "), "+ sex + age + age2"))
run_lvl <- function(bw) {
  s <- d %>% filter(abs(norm_dist) < bw)
  feols(lvl_fml, data = s, cluster = ~Expropretario_ISTA, warn = FALSE, notes = FALSE)
}
m1 <- run_lvl(300); m2 <- run_lvl(150)

## Cols 3-4: collapse (iqr) by match_id Expropretario_ISTA i_year*, cw
## Stata percentiles = R quantile type 2
iqr2 <- function(x) unname(quantile(x, 0.75, type = 2) - quantile(x, 0.25, type = 2))
cw <- d %>% filter(!is.na(hh_income_pc), !is.na(hh_inc_pc_real), !is.na(num_members),
                   !is.na(norm_dist), !is.na(Above500))
col <- cw %>% group_by(across(all_of(c("match_id", "Expropretario_ISTA", yr)))) %>%
  summarise(hh_inc_pc_real = iqr2(hh_inc_pc_real), num_members = mean(num_members),
            norm_dist = mean(norm_dist), Above500 = mean(Above500), .groups = "drop")
col$nd_above <- col$norm_dist * col$Above500
iqr_fml <- as.formula(paste("hh_inc_pc_real ~ Above500 + norm_dist + nd_above +",
                            paste(yr, collapse = " + ")))
run_iqr <- function(bw) {
  s <- col %>% filter(abs(norm_dist) < bw)
  feols(iqr_fml, data = s, cluster = ~Expropretario_ISTA, warn = FALSE, notes = FALSE)
}
m3 <- run_iqr(300); m4 <- run_iqr(150)

for (nm in c("m1","m2","m3","m4")) { m <- get(nm); cat(nm, "\n"); print(coeftable(m)[1:4, ]) }
cat("mean dv:", mean(fitted(m1) + resid(m1)), mean(fitted(m2) + resid(m2)),
    mean(fitted(m3) + resid(m3)), mean(fitted(m4) + resid(m4)), "\n")
s300 <- d %>% filter(abs(norm_dist) < 300); s150 <- d %>% filter(abs(norm_dist) < 150)
cl300 <- length(unique(s300$Expropretario_ISTA[obs(m1)]))
cl150 <- length(unique(s150$Expropretario_ISTA[obs(m2)]))
c3 <- col %>% filter(abs(norm_dist) < 300); c4 <- col %>% filter(abs(norm_dist) < 150)
cat("clusters iqr:", length(unique(c3$Expropretario_ISTA[obs(m3)])), length(unique(c4$Expropretario_ISTA[obs(m4)])), "\n")
cat("properties lvl:", length(unique(s300$match_id[obs(m1)])), length(unique(s150$match_id[obs(m2)])), "\n")

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", coef(m1)[["Above500"]]))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", coef(m2)[["Above500"]]))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", coef(m3)[["Above500"]]))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", coef(m4)[["Above500"]]))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", cl300))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", cl150))
