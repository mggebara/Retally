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

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    results[[name]] <<- val
  }
}

# ---------------------------------------------------------------
# Load main data (only needed columns)
# ---------------------------------------------------------------
hdr <- names(fread(f_main, nrows = 0))
want <- c("peage", "pesex", "peeduc", "peeduca", "race", "prhspnon", "pehspnon",
          "pemlr", "pwsswgt", "v2pwsswgt", "v2hrmonth", "v2hryear", "v2gestfips",
          "v2pemlr", "v2puiodp1", "v2peio1cow", "v2peio1icd", "v2peio1ocd",
          "v2prernwa", "v2prwernal")
sel <- intersect(want, hdr)
dt <- fread(f_main, select = sel, integer64 = "double", showProgress = FALSE)
gc()

if (!("peeduc" %in% names(dt)) && ("peeduca" %in% names(dt))) setnames(dt, "peeduca", "peeduc")
for (v in names(dt)) {
  if (is.character(dt[[v]])) set(dt, j = v, value = suppressWarnings(as.numeric(dt[[v]])))
}
if (!("pehspnon" %in% names(dt))) dt[, pehspnon := NA_real_]
if (!("prhspnon" %in% names(dt))) dt[, prhspnon := NA_real_]

# year fix (as in Stata: only 94-97)
dt[v2hryear %in% 94:97, v2hryear := v2hryear + 1900]

# ---------------------------------------------------------------
# Merge state unemployment rate
# ---------------------------------------------------------------
un <- fread(f_unemp, integer64 = "double")
un[, v2hryear := as.numeric(v2hryear)]
un[v2hryear %in% 94:97, v2hryear := v2hryear + 1900]
un[, `:=`(v2hrmonth = as.numeric(v2hrmonth), v2gestfips = as.numeric(v2gestfips),
          v2unemp_smy = as.numeric(v2unemp_smy))]
un <- unique(un, by = c("v2hryear", "v2hrmonth", "v2gestfips"))
dt[, `:=`(v2hryear = as.numeric(v2hryear), v2hrmonth = as.numeric(v2hrmonth),
          v2gestfips = as.numeric(v2gestfips))]
dt[un, v2unemp := i.v2unemp_smy, on = c("v2hryear", "v2hrmonth", "v2gestfips")]
rm(un); gc()

# ---------------------------------------------------------------
# Variable definitions
# ---------------------------------------------------------------
dt[, age := as.numeric(peage)]
dt[!is.na(age) & age > 79, age := NA_real_]

ys_map <- c(`31` = 1, `32` = 4, `33` = 6, `34` = 8, `35` = 9, `36` = 10, `37` = 11,
            `38` = 11.5, `39` = 12, `40` = 13, `41` = 14, `42` = 14, `43` = 16,
            `44` = 18, `45` = 20, `46` = 22)
dt[, yrsch := unname(ys_map[as.character(peeduc)])]
dt[is.na(yrsch), yrsch := 0]
dt[, exp := age - yrsch - 6]

# sample restriction: non-missing experience and unemployment rate
dt <- dt[!is.na(exp) & !is.na(v2unemp)]
gc()

dt[, educ := NA_integer_]
dt[!is.na(peeduc) & peeduc > 0 & peeduc < 39, educ := 0L]
dt[peeduc == 39, educ := 1L]
dt[!is.na(peeduc) & peeduc > 39 & peeduc < 43, educ := 2L]
dt[peeduc == 43, educ := 3L]
dt[peeduc == 44, educ := 4L]
dt[peeduc == 45, educ := 5L]
dt[peeduc == 46, educ := 6L]

dt[, minority := as.integer(is.na(race) | race > 1)]
dt[, female := as.integer(is.na(pesex) | pesex > 1)]
dt[, hisp := as.integer((!is.na(pehspnon) & pehspnon == 1) | (!is.na(prhspnon) & prhspnon == 1))]
dt[, demo2 := ifelse(is.na(educ), NA_integer_,
                     as.integer(minority * 1000L + female * 100L + hisp * 10L + educ))]

# hiring
dt[, hired := as.integer(!is.na(v2pemlr) & v2pemlr %in% c(1, 2))]
dt[!is.na(v2puiodp1) & v2puiodp1 == 1, hired := 0L]
dt[!is.na(pemlr) & pemlr %in% c(1, 2) & !is.na(v2puiodp1) & v2puiodp1 < 0, hired := 0L]
dt[, hired2 := hired]
dt[is.na(v2peio1cow) | v2peio1cow >= 5, hired2 := 0L]
dt[, hired100 := hired2 * 100]

dt[, young := as.integer(exp <= 10)]
dt[, youngurate := ifelse(young == 1, v2unemp, 0)]
dt[, oldurate := ifelse(young == 0 & exp > 10, v2unemp, 0)]

dt[, date := v2hryear * 12 + v2hrmonth]
dt[, weight := (as.numeric(v2pwsswgt) + as.numeric(pwsswgt)) / 2]

dt[, s_emp := !is.na(pemlr) & pemlr %in% c(1, 2)]
dt[, s_unemp := !is.na(pemlr) & pemlr %in% c(3, 4)]
dt[, s_nilf := is.na(pemlr) | pemlr > 4]
gc()

# ---------------------------------------------------------------
# Table 1
# ---------------------------------------------------------------
cl <- ~v2gestfips

m_a1 <- tryCatch(feols(hired100 ~ v2unemp, data = dt, weights = ~weight, cluster = cl),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_a1)) {
  emit("aggregate_unemp_rate_no_controls", unname(coef(m_a1)["v2unemp"]))
  emit("n_obs_full_sample", nobs(m_a1))
}
rm(m_a1); gc()

m_a4 <- tryCatch(feols(hired100 ~ v2unemp | date + v2gestfips + demo2, data = dt,
                       weights = ~weight, cluster = cl, fixef.rm = "none"),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_a4)) emit("aggregate_unemp_rate_month_year_fe", unname(coef(m_a4)["v2unemp"]))
rm(m_a4); gc()

m_b1 <- tryCatch(feols(hired100 ~ young + youngurate + oldurate, data = dt,
                       weights = ~weight, cluster = cl),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_b1)) {
  emit("young_x_unemp_rate_no_controls", unname(coef(m_b1)["youngurate"]))
  emit("experienced_x_unemp_rate_no_controls", unname(coef(m_b1)["oldurate"]))
}
rm(m_b1); gc()

m_b4 <- tryCatch(feols(hired100 ~ young + youngurate + oldurate | date + v2gestfips + demo2,
                       data = dt, weights = ~weight, cluster = cl, fixef.rm = "none"),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_b4)) {
  emit("young_x_unemp_rate_preferred", unname(coef(m_b4)["youngurate"]))
  emit("experienced_x_unemp_rate_preferred", unname(coef(m_b4)["oldurate"]))
}
rm(m_b4); gc()

# ---------------------------------------------------------------
# Table 2 columns 2-4
# ---------------------------------------------------------------
fml_pref <- hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date

m_e <- tryCatch(feols(fml_pref, data = dt[s_emp == TRUE], weights = ~weight, cluster = cl,
                      fixef.rm = "none"),
                error = function(e) { message(e$message); NULL })
if (!is.null(m_e)) {
  emit("young_x_unemp_rate_employed", unname(coef(m_e)["youngurate"]))
  emit("experienced_x_unemp_rate_employed", unname(coef(m_e)["oldurate"]))
}
rm(m_e); gc()

m_u <- tryCatch(feols(fml_pref, data = dt[s_unemp == TRUE], weights = ~weight, cluster = cl,
                      fixef.rm = "none"),
                error = function(e) { message(e$message); NULL })
if (!is.null(m_u)) emit("young_x_unemp_rate_unemployed", unname(coef(m_u)["youngurate"]))
rm(m_u); gc()

m_n <- tryCatch(feols(fml_pref, data = dt[s_nilf == TRUE], weights = ~weight, cluster = cl,
                      fixef.rm = "none"),
                error = function(e) { message(e$message); NULL })
if (!is.null(m_n)) emit("young_x_unemp_rate_nilf", unname(coef(m_n)["youngurate"]))
rm(m_n); gc()

# ---------------------------------------------------------------
# Table 10 Panel B col 1: log weekly wages of new hires
# ---------------------------------------------------------------
wage_res <- tryCatch({
  if (!all(c("v2prernwa", "v2prwernal") %in% names(dt))) stop("wage columns missing")
  w <- dt[hired2 == 1 & !is.na(v2prwernal) & v2prwernal == 0,
          .(v2hryear, v2hrmonth, v2gestfips, date, demo2, young, youngurate, oldurate,
            weight, v2prernwa, v2peio1ocd, v2peio1icd)]

  # occupation crosswalk
  w[, v2occ_codeyear := ifelse(v2hryear < 2003, 1990, ifelse(v2hryear < 2011, 2002, 2010))]
  ox <- fread(f_occ, integer64 = "double")
  ox[, `:=`(v2peio1ocd = as.numeric(v2peio1ocd), v2occ_codeyear = as.numeric(v2occ_codeyear),
            v2censusocc_2002recode = as.numeric(v2censusocc_2002recode))]
  ox <- unique(ox, by = c("v2peio1ocd", "v2occ_codeyear"))
  w[, v2peio1ocd := as.numeric(v2peio1ocd)]
  w[ox, occ := i.v2censusocc_2002recode, on = c("v2peio1ocd", "v2occ_codeyear")]

  # industry crosswalk
  w[, v2ind_codeyear := ifelse(v2hryear < 2003, 1990,
                        ifelse(v2hryear < 2009, 2002,
                        ifelse(v2hryear < 2014, 2007, 2012)))]
  ix <- fread(f_ind, integer64 = "double")
  ix[, `:=`(v2peio1icd = as.numeric(v2peio1icd), v2ind_codeyear = as.numeric(v2ind_codeyear),
            v2censusind_2002recode = as.numeric(v2censusind_2002recode))]
  ix <- unique(ix, by = c("v2peio1icd", "v2ind_codeyear"))
  w[, v2peio1icd := as.numeric(v2peio1icd)]
  w[, ind_matched := FALSE]
  w[ix, `:=`(ind = i.v2censusind_2002recode, ind_matched = TRUE),
    on = c("v2peio1icd", "v2ind_codeyear")]
  w[ind_matched == FALSE & v2peio1icd == 6692, ind := 6692]
  w[ind_matched == FALSE & v2peio1icd == 991, ind := 9890]
  w[ind_matched == FALSE & v2peio1icd == 9890, ind := 9890]

  # deflate
  cp <- fread(f_cpi, integer64 = "double")
  cp[, `:=`(year = as.numeric(year), month = as.numeric(month), cpi = as.numeric(cpi))]
  cp <- unique(cp, by = c("year", "month"))
  w[cp, v2cpi := i.cpi, on = c(v2hryear = "year", v2hrmonth = "month")]
  w[, ratio := as.numeric(v2prernwa) / v2cpi]
  w[, lw := ifelse(!is.na(ratio) & ratio > 0, log(ratio), NA_real_)]
  w <- w[!is.na(lw) & !is.na(occ) & !is.na(ind) & !is.na(demo2)]

  mw <- feols(lw ~ young + youngurate + oldurate | v2gestfips + date + demo2 + occ + ind,
              data = w, weights = ~weight, cluster = cl, fixef.rm = "none")
  c(unname(coef(mw)["youngurate"]), unname(coef(mw)["oldurate"]))
}, error = function(e) { message(e$message); NULL })
if (!is.null(wage_res)) {
  emit("wage_young_x_unemp_rate_all_hires", wage_res[1])
  emit("wage_experienced_x_unemp_rate_all_hires", wage_res[2])
}

# ---------------------------------------------------------------
# Output
# ---------------------------------------------------------------
for (nm in names(results)) {
  v <- results[[nm]]
  if (nm == "n_obs_full_sample") {
    cat(sprintf("RESULT:%s=%d\n", nm, as.integer(v)))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", nm, v))
  }
}
