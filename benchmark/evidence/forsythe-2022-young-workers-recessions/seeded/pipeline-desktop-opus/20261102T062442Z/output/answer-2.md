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
# print each result as soon as it is available (robust to later memory failures)
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    results[[name]] <<- val
    if (name == "n_obs_full_sample") {
      cat(sprintf("RESULT:%s=%d\n", name, as.integer(val)))
    } else {
      cat(sprintf("RESULT:%s=%.6f\n", name, val))
    }
    flush.console()
  }
}
qgc <- function() invisible(gc(verbose = FALSE))

to_int <- function(x) {
  if (is.integer(x)) return(x)
  as.integer(round(suppressWarnings(as.numeric(x))))
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
qgc()

if (!("peeduc" %in% names(dt)) && ("peeduca" %in% names(dt))) setnames(dt, "peeduca", "peeduc")
for (v in names(dt)) {
  if (is.character(dt[[v]])) set(dt, j = v, value = suppressWarnings(as.numeric(dt[[v]])))
}
if (!("pehspnon" %in% names(dt))) dt[, pehspnon := NA_integer_]
if (!("prhspnon" %in% names(dt))) dt[, prhspnon := NA_integer_]

for (v in c("v2hryear", "v2hrmonth", "v2gestfips")) set(dt, j = v, value = to_int(dt[[v]]))
# year fix (as in Stata: only 94-97)
dt[v2hryear %in% 94:97, v2hryear := v2hryear + 1900L]

# ---------------------------------------------------------------
# Merge state unemployment rate
# ---------------------------------------------------------------
un <- fread(f_unemp, integer64 = "double")
un[, `:=`(v2hryear = to_int(v2hryear), v2hrmonth = to_int(v2hrmonth),
          v2gestfips = to_int(v2gestfips),
          v2unemp_smy = as.numeric(v2unemp_smy))]
un[v2hryear %in% 94:97, v2hryear := v2hryear + 1900L]
un <- unique(un[, .(v2hryear, v2hrmonth, v2gestfips, v2unemp_smy)],
             by = c("v2hryear", "v2hrmonth", "v2gestfips"))
dt[un, v2unemp := i.v2unemp_smy, on = c("v2hryear", "v2hrmonth", "v2gestfips")]
rm(un); qgc()

# ---------------------------------------------------------------
# Experience and sample restriction (done early to save memory)
# ---------------------------------------------------------------
ys_vec <- rep(NA_real_, 46)
ys_vec[31:46] <- c(1, 4, 6, 8, 9, 10, 11, 11.5, 12, 13, 14, 14, 16, 18, 20, 22)
pe <- to_int(dt$peeduc)
idx <- ifelse(!is.na(pe) & pe >= 1L & pe <= 46L, pe, NA_integer_)
yrsch <- ys_vec[idx]
yrsch[is.na(yrsch)] <- 0
age <- as.numeric(dt$peage)
age[!is.na(age) & age > 79] <- NA_real_
dt[, exp := age - yrsch - 6]
rm(pe, idx, yrsch, age); dt[, peage := NULL]; qgc()

keep_rows <- which(!is.na(dt$exp) & !is.na(dt$v2unemp))
if (length(keep_rows) < nrow(dt)) {
  dt <- dt[keep_rows]
}
rm(keep_rows); qgc()

# ---------------------------------------------------------------
# Variable definitions
# ---------------------------------------------------------------
pe <- to_int(dt$peeduc)
educ <- rep(NA_integer_, length(pe))
educ[!is.na(pe) & pe > 0L & pe < 39L] <- 0L
educ[!is.na(pe) & pe == 39L] <- 1L
educ[!is.na(pe) & pe > 39L & pe < 43L] <- 2L
educ[!is.na(pe) & pe == 43L] <- 3L
educ[!is.na(pe) & pe == 44L] <- 4L
educ[!is.na(pe) & pe == 45L] <- 5L
educ[!is.na(pe) & pe == 46L] <- 6L
rm(pe)

minority <- as.integer(is.na(dt$race) | dt$race > 1)
female <- as.integer(is.na(dt$pesex) | dt$pesex > 1)
hisp <- as.integer((!is.na(dt$pehspnon) & dt$pehspnon == 1) |
                   (!is.na(dt$prhspnon) & dt$prhspnon == 1))
dt[, demo2 := minority * 1000L + female * 100L + hisp * 10L + educ]
rm(educ, minority, female, hisp)
dt[, c("race", "pesex", "pehspnon", "prhspnon", "peeduc") := NULL]
qgc()

# hiring
dt[, hired := as.integer(!is.na(v2pemlr) & v2pemlr %in% c(1, 2))]
dt[!is.na(v2puiodp1) & v2puiodp1 == 1, hired := 0L]
dt[!is.na(pemlr) & pemlr %in% c(1, 2) & !is.na(v2puiodp1) & v2puiodp1 < 0, hired := 0L]
dt[is.na(v2peio1cow) | v2peio1cow >= 5, hired := 0L]   # hired2
setnames(dt, "hired", "hired2")
dt[, hired100 := hired2 * 100L]
dt[, c("v2pemlr", "v2puiodp1", "v2peio1cow") := NULL]

dt[, young := as.integer(exp <= 10)]
dt[, youngurate := fifelse(young == 1L, v2unemp, 0)]
dt[, oldurate := fifelse(young == 0L & exp > 10, v2unemp, 0)]
dt[, exp := NULL]

dt[, date := v2hryear * 12L + v2hrmonth]
dt[, weight := (as.numeric(v2pwsswgt) + as.numeric(pwsswgt)) / 2]
dt[, c("v2pwsswgt", "pwsswgt") := NULL]

# labor-force status: 1 employed, 2 unemployed, 3 NILF
dt[, lfs := fifelse(!is.na(pemlr) & pemlr %in% c(1, 2), 1L,
                    fifelse(!is.na(pemlr) & pemlr %in% c(3, 4), 2L, 3L))]
dt[, pemlr := NULL]
qgc()

# ---------------------------------------------------------------
# Extract wage sample now, then drop wage columns from main data
# ---------------------------------------------------------------
has_wage <- all(c("v2prernwa", "v2prwernal", "v2peio1ocd", "v2peio1icd") %in% names(dt))
w <- NULL
if (has_wage) {
  w <- dt[hired2 == 1L & !is.na(v2prwernal) & v2prwernal == 0,
          .(v2hryear, v2hrmonth, v2gestfips, date, demo2, young, youngurate, oldurate,
            weight, v2prernwa, v2peio1ocd, v2peio1icd)]
}
dropc <- intersect(c("v2prernwa", "v2prwernal", "v2peio1ocd", "v2peio1icd", "hired2",
                     "v2hryear", "v2hrmonth"), names(dt))
if (length(dropc)) dt[, (dropc) := NULL]
qgc()

# ---------------------------------------------------------------
# Table 1
# ---------------------------------------------------------------
cl <- ~v2gestfips

m_a1 <- tryCatch(feols(hired100 ~ v2unemp, data = dt, weights = ~weight, cluster = cl,
                       mem.clean = TRUE),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_a1)) {
  emit("aggregate_unemp_rate_no_controls", unname(coef(m_a1)["v2unemp"]))
  emit("n_obs_full_sample", nobs(m_a1))
}
rm(m_a1); qgc()

m_b4 <- tryCatch(feols(hired100 ~ young + youngurate + oldurate | date + v2gestfips + demo2,
                       data = dt, weights = ~weight, cluster = cl, fixef.rm = "none",
                       mem.clean = TRUE),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_b4)) {
  emit("young_x_unemp_rate_preferred", unname(coef(m_b4)["youngurate"]))
  emit("experienced_x_unemp_rate_preferred", unname(coef(m_b4)["oldurate"]))
}
rm(m_b4); qgc()

m_a4 <- tryCatch(feols(hired100 ~ v2unemp | date + v2gestfips + demo2, data = dt,
                       weights = ~weight, cluster = cl, fixef.rm = "none",
                       mem.clean = TRUE),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_a4)) emit("aggregate_unemp_rate_month_year_fe", unname(coef(m_a4)["v2unemp"]))
rm(m_a4); qgc()

m_b1 <- tryCatch(feols(hired100 ~ young + youngurate + oldurate, data = dt,
                       weights = ~weight, cluster = cl, mem.clean = TRUE),
                 error = function(e) { message(e$message); NULL })
if (!is.null(m_b1)) {
  emit("young_x_unemp_rate_no_controls", unname(coef(m_b1)["youngurate"]))
  emit("experienced_x_unemp_rate_no_controls", unname(coef(m_b1)["oldurate"]))
}
rm(m_b1); qgc()

# ---------------------------------------------------------------
# Table 2 columns 2-4
# ---------------------------------------------------------------
fml_pref <- hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date

m_e <- tryCatch(feols(fml_pref, data = dt, subset = dt$lfs == 1L, weights = ~weight,
                      cluster = cl, fixef.rm = "none", mem.clean = TRUE),
                error = function(e) { message(e$message); NULL })
if (!is.null(m_e)) {
  emit("young_x_unemp_rate_employed", unname(coef(m_e)["youngurate"]))
  emit("experienced_x_unemp_rate_employed", unname(coef(m_e)["oldurate"]))
}
rm(m_e); qgc()

m_u <- tryCatch(feols(fml_pref, data = dt, subset = dt$lfs == 2L, weights = ~weight,
                      cluster = cl, fixef.rm = "none", mem.clean = TRUE),
                error = function(e) { message(e$message); NULL })
if (!is.null(m_u)) emit("young_x_unemp_rate_unemployed", unname(coef(m_u)["youngurate"]))
rm(m_u); qgc()

m_n <- tryCatch(feols(fml_pref, data = dt, subset = dt$lfs == 3L, weights = ~weight,
                      cluster = cl, fixef.rm = "none", mem.clean = TRUE),
                error = function(e) { message(e$message); NULL })
if (!is.null(m_n)) emit("young_x_unemp_rate_nilf", unname(coef(m_n)["youngurate"]))
rm(m_n); qgc()

rm(dt); qgc()

# ---------------------------------------------------------------
# Table 10 Panel B col 1: log weekly wages of new hires
# ---------------------------------------------------------------
wage_res <- tryCatch({
  if (is.null(w)) stop("wage columns missing")

  # occupation crosswalk
  w[, v2occ_codeyear := fifelse(v2hryear < 2003, 1990, fifelse(v2hryear < 2011, 2002, 2010))]
  ox <- fread(f_occ, integer64 = "double")
  ox[, `:=`(v2peio1ocd = as.numeric(v2peio1ocd), v2occ_codeyear = as.numeric(v2occ_codeyear),
            v2censusocc_2002recode = as.numeric(v2censusocc_2002recode))]
  ox <- unique(ox, by = c("v2peio1ocd", "v2occ_codeyear"))
  w[, v2peio1ocd := as.numeric(v2peio1ocd)]
  w[ox, occ := i.v2censusocc_2002recode, on = c("v2peio1ocd", "v2occ_codeyear")]

  # industry crosswalk
  w[, v2ind_codeyear := fifelse(v2hryear < 2003, 1990,
                        fifelse(v2hryear < 2009, 2002,
                        fifelse(v2hryear < 2014, 2007, 2012)))]
  ix <- fread(f_ind, integer64 = "double")
  ix[, `:=`(v2peio1icd = as.numeric(v2peio1icd), v2ind_codeyear = as.numeric(v2ind_codeyear),
            v2censusind_2002recode = as.numeric(v2censusind_2002recode))]
  ix <- unique(ix, by = c("v2peio1icd", "v2ind_codeyear"))
  w[, v2peio1icd := as.numeric(v2peio1icd)]
  w[, ind := NA_real_]
  w[, ind_matched := FALSE]
  w[ix, `:=`(ind = i.v2censusind_2002recode, ind_matched = TRUE),
    on = c("v2peio1icd", "v2ind_codeyear")]
  w[ind_matched == FALSE & v2peio1icd == 6692, ind := 6692]
  w[ind_matched == FALSE & v2peio1icd == 991, ind := 9890]
  w[ind_matched == FALSE & v2peio1icd == 9890, ind := 9890]

  # deflate
  cp <- fread(f_cpi, integer64 = "double")
  cp[, `:=`(year = as.integer(year), month = as.integer(month), cpi = as.numeric(cpi))]
  cp <- unique(cp, by = c("year", "month"))
  w[cp, v2cpi := i.cpi, on = c(v2hryear = "year", v2hrmonth = "month")]
  w[, ratio := as.numeric(v2prernwa) / v2cpi]
  w[, lw := fifelse(!is.na(ratio) & ratio > 0, log(pmax(ratio, 1e-300)), NA_real_)]
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
# Output: all RESULT lines were printed via cat() as each was computed above.
# ---------------------------------------------------------------
