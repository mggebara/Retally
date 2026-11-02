suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/seeded/2026-11-02-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
# hh_inc_pc_real as in the do-file's "original real income measure" (0 for years not listed, e.g. 2010)
defl <- c(`2000`=71.57,`2001`=74.25,`2004`=80.68,`2005`=84.47,`2006`=87.88,`2007`=91.90,
          `2008`=98.06,`2009`=99.10,`2011`=105.13,`2012`=106.95,`2013`=107.79)
f <- defl[as.character(d$year)]; f[is.na(f)] <- 0
d$hh_inc_pc_real <- d$hh_income_pc * f / 100
iy <- grep("^i_year", names(d), value = TRUE)
fml_lvl <- as.formula(paste("hh_inc_pc_real ~ Above500 + norm_dist + norm_dist:Above500 +",
                            paste(iy, collapse = "+"), "+ sex + age + age2"))
fml_iqr <- as.formula(paste("hh_inc_pc_real ~ Above500 + norm_dist + norm_dist:Above500 +",
                            paste(iy, collapse = "+")))
run <- function(fml, dat, bw) {
  s <- dat[!is.na(dat$norm_dist) & abs(dat$norm_dist) < bw, ]
  m <- feols(fml, data = s, cluster = ~Expropretario_ISTA)
  list(b = unname(coef(m)["Above500"]), n = nobs(m),
       g = length(unique(s$Expropretario_ISTA[obs(m)])))
}
# Table 5 cols 1-2 (T3c1, T3c2)
l300 <- run(fml_lvl, d, 300); l150 <- run(fml_lvl, d, 150)
# Table 5 cols 3-4 (T1c1, T1c2): collapse (iqr) ... (mean) ..., by(match_id Expropretario_ISTA i_year*) cw
iqr2 <- function(x) unname(quantile(x, .75, type = 2) - quantile(x, .25, type = 2))  # Stata centile definition
cw <- d[complete.cases(d[, c("hh_income_pc","hh_inc_pc_real","num_members","norm_dist","Above500")]), ]
col <- cw %>% group_by(across(all_of(c("match_id","Expropretario_ISTA", iy)))) %>%
  summarise(hh_inc_pc_real = iqr2(hh_inc_pc_real), num_members = mean(num_members),
            norm_dist = mean(norm_dist), Above500 = mean(Above500), .groups = "drop") %>% as.data.frame()
q300 <- run(fml_iqr, col, 300); q150 <- run(fml_iqr, col, 150)
cat("clusters lvl:", l300$g, l150$g, " iqr:", q300$g, q150$g, "\n")
cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", q300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", q150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", l300$n))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", l150$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", q300$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", q150$n))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", l300$g))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", l150$g))
