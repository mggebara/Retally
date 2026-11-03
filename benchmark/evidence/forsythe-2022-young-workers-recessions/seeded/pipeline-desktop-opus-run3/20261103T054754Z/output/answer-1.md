suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_unemp <- file.path(base, "v2unemp_smy.csv")
f_occ <- file.path(base, "occ_xwalk2002.csv")
f_ind <- file.path(base, "ind_xwalk2002.csv")
f_cpi <- file.path(base, "wage_deflation_1994_2016.csv")

num <- function(x) suppressWarnings(as.numeric(x))
# Stata semantics helpers: missing is +infinity
s_gt <- function(x, v) is.na(x) | x > v
s_ge <- function(x, v) is.na(x) | x >= v
s_eq <- function(x, v) !is.na(x) & x == v
s_lt <- function(x, v) !is.na(x) & x < v

# ---------------- Load main data (only needed columns) ----------------
hdr <- names(fread(f_main, nrows = 0))
hdr_l <- tolower(hdr)
peeduc_name <- hdr_l[grepl("^peeduc", hdr_l)][1]
needed <- c("peage", "pesex", peeduc_name, "race", "prhspnon", "pehspnon", "pemlr",
            "pwsswgt", "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr", "v2puiodp1",
            "v2peio1cow", "v2peio1icd", "v2peio1ocd", "v2pwsswgt", "v2prernwa",
            "v2prwernal")
sel <- hdr[hdr_l %in% needed]
dt <- fread(f_main, select = sel, showProgress = FALSE)
setnames(dt, tolower(names(dt)))
if (peeduc_name != "peeduc") setnames(dt, peeduc_name, "peeduc")
for (v in names(dt)) set(dt, j = v, value = num(dt[[v]]))
if (!"pehspnon" %in% names(dt)) dt[, pehspnon := NA_real_]
if (!"prhspnon" %in% names(dt)) dt[, prhspnon := NA_real_]

dt[v2hryear < 100, v2hryear := v2hryear + 1900]

# ---------------- Crosswalks ----------------
dt[, v2occ_codeyear := fifelse(v2hryear < 2003, 1990, fifelse(v2hryear < 2011, 2002, 2010))]
occ <- fread(f_occ, showProgress = FALSE)
setnames(occ, tolower(names(occ)))
for (v in names(occ)) set(occ, j = v, value = num(occ[[v]]))
occ <- unique(occ, by = c("v2peio1ocd", "v2occ_codeyear"))
dt <- merge(dt, occ[, .(v2peio1ocd, v2occ_codeyear, v2censusocc_2002recode)],
            by = c("v2peio1ocd", "v2occ_codeyear"), all.x = TRUE, sort = FALSE)

dt[, v2ind_codeyear := fifelse(v2hryear < 2003, 1990,
                        fifelse(v2hryear < 2009, 2002,
                        fifelse(v2hryear < 2014, 2007, 2012)))]
ind <- fread(f_ind, showProgress = FALSE)
setnames(ind, tolower(names(ind)))
for (v in names(ind)) set(ind, j = v, value = num(ind[[v]]))
ind <- unique(ind, by = c("v2peio1icd", "v2ind_codeyear"))
ind[, matched_ind := 1L]
dt <- merge(dt, ind[, .(v2peio1icd, v2ind_codeyear, v2censusind_2002recode, matched_ind)],
            by = c("v2peio1icd", "v2ind_codeyear"), all.x = TRUE, sort = FALSE)
dt[is.na(matched_ind) & s_eq(v2peio1icd, 6692), v2censusind_2002recode := v2peio1icd]
dt[is.na(matched_ind) & s_eq(v2peio1icd, 991), v2censusind_2002recode := 9890]
dt[is.na(matched_ind) & s_eq(v2peio1icd, 9890), v2censusind_2002recode := v2peio1icd]
dt[, matched_ind := NULL]

dt[, date := v2hryear * 12 + (v2hrmonth - 1)]

# ---------------- State unemployment ----------------
un <- fread(f_unemp, showProgress = FALSE)
setnames(un, tolower(names(un)))
for (v in names(un)) set(un, j = v, value = num(un[[v]]))
un[v2hryear < 100, v2hryear := v2hryear + 1900]
un <- unique(un, by = c("v2hryear", "v2hrmonth", "v2gestfips"))
setnames(un, "v2unemp_smy", "v2unemp")
dt <- merge(dt, un, by = c("v2hryear", "v2hrmonth", "v2gestfips"), all.x = TRUE, sort = FALSE)
rm(un, occ, ind); gc()

# ---------------- Variable definitions ----------------
dt[, age := peage]
dt[s_gt(age, 79), age := NA_real_]

ymap <- c(`31` = 1, `32` = 4, `33` = 6, `34` = 8, `35` = 9, `36` = 10, `37` = 11,
          `38` = 11.5, `39` = 12, `40` = 13, `41` = 14, `42` = 14, `43` = 16,
          `44` = 18, `45` = 20, `46` = 22)
dt[, yrsch := unname(ymap[as.character(peeduc)])]
dt[is.na(yrsch), yrsch := 0]
dt[, exp := age - yrsch - 6]

dt[, educ := NA_real_]
dt[!is.na(peeduc) & peeduc > 0 & peeduc < 39, educ := 0]
dt[s_eq(peeduc, 39), educ := 1]
dt[!is.na(peeduc) & peeduc > 39 & peeduc < 43, educ := 2]
dt[s_eq(peeduc, 43), educ := 3]
dt[s_eq(peeduc, 44), educ := 4]
dt[s_eq(peeduc, 45), educ := 5]
dt[s_eq(peeduc, 46), educ := 6]

dt[, minority := as.integer(s_gt(race, 1))]
dt[, female := as.integer(s_gt(pesex, 1))]
dt[, hisp := as.integer(s_eq(pehspnon, 1) | s_eq(prhspnon, 1))]

dt[, hired := 0L]
dt[s_eq(v2pemlr, 1) | s_eq(v2pemlr, 2), hired := 1L]
dt[s_eq(v2puiodp1, 1), hired := 0L]
dt[(s_eq(pemlr, 1) | s_eq(pemlr, 2)) & s_lt(v2puiodp1, 0), hired := 0L]
dt[, hired2 := hired]
dt[s_ge(v2peio1cow, 5), hired2 := 0L]
dt[, hired100 := hired2 * 100]

dt[, young := as.integer(s_lt(exp, 10) | s_eq(exp, 10))]
dt[, oldurate := fifelse(young == 0 & s_gt(exp, 10), v2unemp, 0)]
dt[, youngurate := fifelse(young == 1, v2unemp, 0)]

dt[, demo2 := NA_integer_]
dt[!is.na(educ), demo2 := .GRP, by = .(minority, female, hisp, educ)]

# Wages
cpi <- fread(f_cpi, showProgress = FALSE)
setnames(cpi, tolower(names(cpi)))
for (v in names(cpi)) set(cpi, j = v, value = num(cpi[[v]]))
cpi[year < 100, year := year + 1900]
cpi <- unique(cpi, by = c("year", "month"))
setnames(cpi, c("year", "month", "cpi"), c("v2hryear", "v2hrmonth", "v2cpi"))
dt <- merge(dt, cpi[, .(v2hryear, v2hrmonth, v2cpi)], by = c("v2hryear", "v2hrmonth"),
            all.x = TRUE, sort = FALSE)
dt[, v2logwagewkly_r := suppressWarnings(log(v2prernwa / v2cpi))]
dt[!is.finite(v2logwagewkly_r), v2logwagewkly_r := NA_real_]

dt[, weight := (v2pwsswgt + pwsswgt) / 2]

# Sample restriction
dt <- dt[!is.na(exp) & !is.na(v2unemp)]
gc()

dt[, emp_prev := s_eq(pemlr, 1) | s_eq(pemlr, 2)]
dt[, unemp_prev := s_eq(pemlr, 3) | s_eq(pemlr, 4)]
dt[, nilf_prev := s_gt(pemlr, 4)]
dt[, wage_samp := hired2 == 1 & s_eq(v2prwernal, 0)]

keep_cols <- c("hired100", "v2unemp", "young", "youngurate", "oldurate", "v2gestfips",
               "date", "demo2", "weight", "emp_prev", "unemp_prev", "nilf_prev",
               "wage_samp", "v2logwagewkly_r", "v2censusocc_2002recode",
               "v2censusind_2002recode")
dt <- dt[, ..keep_cols]
gc()

# ---------------- Regressions ----------------
run <- function(fml, data) {
  feols(fml, data = data, weights = ~weight, cluster = ~v2gestfips,
        fixef.rm = "none", lean = TRUE, notes = FALSE)
}
cf <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

res <- list()

# Table 1 Panel A
mA1 <- run(hired100 ~ v2unemp, dt)
res$aggregate_unemp_rate_no_controls <- cf(mA1, "v2unemp")
res$aggregate_unemp_rate_no_controls_se <- se(mA1, "v2unemp")
rm(mA1); gc()

mA4 <- run(hired100 ~ v2unemp | date + v2gestfips + demo2, dt)
res$aggregate_unemp_rate_month_year_fe <- cf(mA4, "v2unemp")
res$aggregate_unemp_rate_month_year_fe_se <- se(mA4, "v2unemp")
rm(mA4); gc()

# Table 1 Panel B
mB1 <- run(hired100 ~ young + youngurate + oldurate, dt)
res$young_x_unemp_rate_no_controls <- cf(mB1, "youngurate")
res$young_x_unemp_rate_no_controls_se <- se(mB1, "youngurate")
res$experienced_x_unemp_rate_no_controls <- cf(mB1, "oldurate")
res$experienced_x_unemp_rate_no_controls_se <- se(mB1, "oldurate")
res$n_obs_full_sample <- nobs(mB1)
rm(mB1); gc()

mB4 <- run(hired100 ~ young + youngurate + oldurate | date + v2gestfips + demo2, dt)
res$young_x_unemp_rate_preferred <- cf(mB4, "youngurate")
res$young_x_unemp_rate_preferred_se <- se(mB4, "youngurate")
res$experienced_x_unemp_rate_preferred <- cf(mB4, "oldurate")
res$experienced_x_unemp_rate_preferred_se <- se(mB4, "oldurate")
res$n_obs_preferred <- nobs(mB4)
rm(mB4); gc()

# Table 2
m2 <- run(hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date, dt[emp_prev == TRUE])
res$young_x_unemp_rate_employed <- cf(m2, "youngurate")
res$young_x_unemp_rate_employed_se <- se(m2, "youngurate")
res$experienced_x_unemp_rate_employed <- cf(m2, "oldurate")
res$experienced_x_unemp_rate_employed_se <- se(m2, "oldurate")
rm(m2); gc()

m3 <- run(hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date, dt[unemp_prev == TRUE])
res$young_x_unemp_rate_unemployed <- cf(m3, "youngurate")
res$young_x_unemp_rate_unemployed_se <- se(m3, "youngurate")
rm(m3); gc()

m4 <- run(hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date, dt[nilf_prev == TRUE])
res$young_x_unemp_rate_nilf <- cf(m4, "youngurate")
res$young_x_unemp_rate_nilf_se <- se(m4, "youngurate")
rm(m4); gc()

# Table 10 Panel B col 1
wd <- dt[wage_samp == TRUE & !is.na(v2logwagewkly_r)]
mw <- run(v2logwagewkly_r ~ young + youngurate + oldurate |
            v2gestfips + date + demo2 + v2censusocc_2002recode + v2censusind_2002recode, wd)
res$wage_young_x_unemp_rate_all_hires <- cf(mw, "youngurate")
res$wage_young_x_unemp_rate_all_hires_se <- se(mw, "youngurate")
res$wage_experienced_x_unemp_rate_all_hires <- cf(mw, "oldurate")
res$wage_experienced_x_unemp_rate_all_hires_se <- se(mw, "oldurate")
res$n_obs_wage_all_hires <- nobs(mw)

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(res[[nm]], digits = 10, scientific = FALSE)))
}
