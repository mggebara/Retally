suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

dir <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights"
raw <- haven::read_dta(file.path(dir, "ehpm_incomemodule_wreform.dta"))
raw <- haven::zap_labels(raw)
dt <- as.data.table(raw)

num <- function(x) suppressWarnings(as.numeric(x))
for (v in c("hh_income_pc", "year", "norm_dist", "Above500", "sex", "age", "num_members")) {
  if (v %in% names(dt)) dt[[v]] <- num(dt[[v]])
}
if (!("age2" %in% names(dt))) dt[, age2 := age^2] else dt[, age2 := num(age2)]

# Original real income measure (years not listed get factor 0, as in Stata)
yr <- dt$year
fac <- rep(0, nrow(dt))
fac[!is.na(yr) & yr == 2000] <- 71.57/100
fac[!is.na(yr) & yr == 2001] <- 74.25/100
fac[!is.na(yr) & yr == 2004] <- 80.68/100
fac[!is.na(yr) & yr == 2005] <- 84.47/100
fac[!is.na(yr) & yr == 2006] <- 87.88/100
fac[!is.na(yr) & yr == 2007] <- 91.90/100
fac[!is.na(yr) & yr == 2008] <- 98.06/100
fac[!is.na(yr) & yr == 2009] <- 99.10/100
fac[!is.na(yr) & yr == 2011] <- 105.13/100
fac[!is.na(yr) & yr == 2012] <- 106.95/100
fac[!is.na(yr) & yr == 2013] <- 107.79/100
dt[, hh_inc_pc_real := hh_income_pc * fac]

dt[, ndA := norm_dist * Above500]
dt[, cl := as.character(Expropretario_ISTA)]

iyear <- grep("^i_year", names(dt), value = TRUE)
if (length(iyear) > 0) {
  for (v in iyear) dt[[v]] <- num(dt[[v]])
  yr_terms <- paste(sprintf("`%s`", iyear), collapse = " + ")
} else {
  dt[, yr_f := factor(year)]
  iyear <- character(0)
  yr_terms <- "yr_f"
}

run_reg <- function(d, fml) {
  feols(as.formula(fml), data = d, cluster = ~cl)
}

# ---- Columns 1 and 2: worker-level earnings ----
fml_lvl <- paste("hh_inc_pc_real ~ Above500 + norm_dist + ndA +", yr_terms, "+ sex + age + age2")
d300 <- dt[!is.na(norm_dist) & abs(norm_dist) < 300]
d150 <- dt[!is.na(norm_dist) & abs(norm_dist) < 150]
m1 <- run_reg(d300, fml_lvl)
m2 <- run_reg(d150, fml_lvl)

ncl <- function(m, d) {
  idx <- obs(m)
  length(unique(d$cl[idx]))
}

# ---- Columns 3 and 4: property-year IQR ----
iqr_stata <- function(x) {
  as.numeric(quantile(x, 0.75, type = 2) - quantile(x, 0.25, type = 2))
}
cw <- dt[!is.na(hh_income_pc) & !is.na(hh_inc_pc_real) & !is.na(norm_dist) & !is.na(Above500)]
if ("num_members" %in% names(cw)) cw <- cw[!is.na(num_members)]
bycols <- c("match_id", "Expropretario_ISTA", if (length(iyear) > 0) iyear else "year")
col <- cw[, .(hh_inc_pc_real = iqr_stata(hh_inc_pc_real),
              norm_dist = mean(norm_dist),
              Above500 = mean(Above500)),
          by = bycols]
col[, ndA := norm_dist * Above500]
col[, cl := as.character(Expropretario_ISTA)]
if (length(iyear) == 0) col[, yr_f := factor(year)]

fml_iqr <- paste("hh_inc_pc_real ~ Above500 + norm_dist + ndA +", yr_terms)
c300 <- col[abs(norm_dist) < 300]
c150 <- col[abs(norm_dist) < 150]
m3 <- run_reg(c300, fml_iqr)
m4 <- run_reg(c150, fml_iqr)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", coef(m1)["Above500"]))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", coef(m2)["Above500"]))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", coef(m3)["Above500"]))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", coef(m4)["Above500"]))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", ncl(m1, d300)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", ncl(m2, d150)))
