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

emit <- function(nm, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%s\n", nm, format(val, digits = 10, scientific = FALSE)))
    flush.console()
  }
}
safe <- function(label, expr) {
  tryCatch(expr, error = function(e) {
    message(sprintf("[%s] error: %s", label, conditionMessage(e)))
    NULL
  })
}
diag <- function(...) message(sprintf(...))

# ---------------- Load main data (only needed columns) ----------------
hdr <- names(fread(f_main, nrows = 0))
hdr_l <- tolower(hdr)
peeduc_name <- hdr_l[grepl("^peeduc", hdr_l)][1]
needed <- c("peage", "pesex", peeduc_name, "race", "prhspnon", "pehspnon", "pemlr",
            "pwsswgt", "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr", "v2puiodp1",
            "v2peio1cow", "v2peio1icd", "v2peio1ocd", "v2pwsswgt", "v2prernwa",
            "v2prwernal", "hrmonth", "hryear", "hryear4", "v2hryear4", "gestfips")
needed <- unique(needed[!is.na(needed)])
sel <- hdr[hdr_l %in% needed]
sel <- sel[!duplicated(tolower(sel))]
dt <- fread(f_main, select = sel, showProgress = FALSE)
setnames(dt, tolower(names(dt)))
if (!is.na(peeduc_name) && peeduc_name != "peeduc" && peeduc_name %in% names(dt)) setnames(dt, peeduc_name, "peeduc")
if (!"peeduc" %in% names(dt)) dt[, peeduc := NA_real_]
for (v in names(dt)) set(dt, j = v, value = num(dt[[v]]))
for (v in setdiff(needed, names(dt))) dt[, (v) := NA_real_]
diag("main data: %d rows, %d cols", nrow(dt), ncol(dt))

# Fallbacks for time/state keys from wave-1 variables if wave-2 ones are missing
if (all(is.na(dt$v2hryear)) && !all(is.na(dt$v2hryear4))) dt[, v2hryear := v2hryear4]
if (all(is.na(dt$v2hryear)) && !all(is.na(dt$hryear4))) dt[, v2hryear := hryear4]
if (all(is.na(dt$v2hryear)) && !all(is.na(dt$hryear))) dt[, v2hryear := hryear]
if (all(is.na(dt$v2hrmonth)) && !all(is.na(dt$hrmonth))) dt[, v2hrmonth := hrmonth]
if (all(is.na(dt$v2gestfips)) && !all(is.na(dt$gestfips))) dt[, v2gestfips := gestfips]

dt[s_lt(v2hryear, 100), v2hryear := v2hryear + 1900]
dt[s_lt(v2hryear, 1950), v2hryear := v2hryear + 100]  # 2-digit years >= 2000

# ---------------- Crosswalks ----------------
dt[, v2occ_codeyear := fifelse(v2hryear < 2003, 1990, fifelse(v2hryear < 2011, 2002, 2010))]
safe("occ", {
  occ <- fread(f_occ, showProgress = FALSE)
  setnames(occ, tolower(names(occ)))
  for (v in names(occ)) set(occ, j = v, value = num(occ[[v]]))
  occ <- unique(occ, by = c("v2peio1ocd", "v2occ_codeyear"))
  dt <- merge(dt, occ[, .(v2peio1ocd, v2occ_codeyear, v2censusocc_2002recode)],
              by = c("v2peio1ocd", "v2occ_codeyear"), all.x = TRUE, sort = FALSE)
  rm(occ)
  TRUE
})
if (!"v2censusocc_2002recode" %in% names(dt)) dt[, v2censusocc_2002recode := v2peio1ocd]

dt[, v2ind_codeyear := fifelse(v2hryear < 2003, 1990,
                        fifelse(v2hryear < 2009, 2002,
                        fifelse(v2hryear < 2014, 2007, 2012)))]
safe("ind", {
  ind <- fread(f_ind, showProgress = FALSE)
  setnames(ind, tolower(names(ind)))
  for (v in names(ind)) set(ind, j = v, value = num(ind[[v]]))
  ind <- unique(ind, by = c("v2peio1icd", "v2ind_codeyear"))
  ind[, matched_ind := 1L]
  dt <- merge(dt, ind[, .(v2peio1icd, v2ind_codeyear, v2censusind_2002recode, matched_ind)],
              by = c("v2peio1icd", "v2ind_codeyear"), all.x = TRUE, sort = FALSE)
  rm(ind)
  TRUE
})
if (!"v2censusind_2002recode" %in% names(dt)) dt[, v2censusind_2002recode := NA_real_]
if (!"matched_ind" %in% names(dt)) dt[, matched_ind := NA_integer_]
dt[is.na(matched_ind) & s_eq(v2peio1icd, 6692), v2censusind_2002recode := v2peio1icd]
dt[is.na(matched_ind) & s_eq(v2peio1icd, 991), v2censusind_2002recode := 9890]
dt[is.na(matched_ind) & s_eq(v2peio1icd, 9890), v2censusind_2002recode := v2peio1icd]
dt[, matched_ind := NULL]

dt[, date := v2hryear * 12 + (v2hrmonth - 1)]

# ---------------- State unemployment ----------------
safe("unemp", {
  un <- fread(f_unemp, showProgress = FALSE)
  setnames(un, tolower(names(un)))
  for (v in names(un)) set(un, j = v, value = num(un[[v]]))
  diag("unemp file columns: %s", paste(names(un), collapse = ","))
  if (!"v2hryear" %in% names(un)) {
    yc <- grep("year", names(un), value = TRUE)[1]; if (!is.na(yc)) setnames(un, yc, "v2hryear")
  }
  if (!"v2hrmonth" %in% names(un)) {
    mc <- grep("month", names(un), value = TRUE)[1]; if (!is.na(mc)) setnames(un, mc, "v2hrmonth")
  }
  if (!"v2gestfips" %in% names(un)) {
    sc <- setdiff(grep("fips|state", names(un), value = TRUE), grep("unemp", names(un), value = TRUE))[1]
    if (!is.na(sc)) setnames(un, sc, "v2gestfips")
  }
  uc <- if ("v2unemp_smy" %in% names(un)) "v2unemp_smy" else
    setdiff(grep("unemp|urate", names(un), value = TRUE), c("v2hryear", "v2hrmonth", "v2gestfips"))[1]
  un <- un[, c("v2hryear", "v2hrmonth", "v2gestfips", uc), with = FALSE]
  setnames(un, uc, "v2unemp")
  un[s_lt(v2hryear, 100), v2hryear := v2hryear + 1900]
  un[s_lt(v2hryear, 1950), v2hryear := v2hryear + 100]
  un <- un[!is.na(v2unemp)]
  un <- unique(un, by = c("v2hryear", "v2hrmonth", "v2gestfips"))
  dt <- merge(dt, un, by = c("v2hryear", "v2hrmonth", "v2gestfips"), all.x = TRUE, sort = FALSE)
  rm(un)
  TRUE
})
if (!"v2unemp" %in% names(dt)) dt[, v2unemp := NA_real_]
diag("unemp matched: %d of %d", sum(!is.na(dt$v2unemp)), nrow(dt))
invisible(gc())

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
safe("cpi", {
  cpi <- fread(f_cpi, showProgress = FALSE)
  setnames(cpi, tolower(names(cpi)))
  for (v in names(cpi)) set(cpi, j = v, value = num(cpi[[v]]))
  yc <- if ("year" %in% names(cpi)) "year" else grep("year", names(cpi), value = TRUE)[1]
  mc <- if ("month" %in% names(cpi)) "month" else grep("month", names(cpi), value = TRUE)[1]
  cc <- if ("cpi" %in% names(cpi)) "cpi" else {
    cand <- grep("cpi|defl|index", names(cpi), value = TRUE)
    cand <- setdiff(cand, c(yc, mc))
    if (length(cand) == 0) cand <- setdiff(names(cpi), c(yc, mc))
    cand[1]
  }
  cpi <- cpi[, c(yc, mc, cc), with = FALSE]
  setnames(cpi, c("v2hryear", "v2hrmonth", "v2cpi"))
  cpi[s_lt(v2hryear, 100), v2hryear := v2hryear + 1900]
  cpi <- unique(cpi, by = c("v2hryear", "v2hrmonth"))
  dt <- merge(dt, cpi, by = c("v2hryear", "v2hrmonth"), all.x = TRUE, sort = FALSE)
  TRUE
})
if (!"v2cpi" %in% names(dt)) dt[, v2cpi := 1]
dt[, v2logwagewkly_r := suppressWarnings(log(v2prernwa / v2cpi))]
dt[!is.finite(v2logwagewkly_r), v2logwagewkly_r := NA_real_]

# Weights: average of the two waves; fall back to whichever is available
dt[, weight := (v2pwsswgt + pwsswgt) / 2]
dt[is.na(weight) & !is.na(pwsswgt), weight := pwsswgt]
dt[is.na(weight) & !is.na(v2pwsswgt), weight := v2pwsswgt]
if (all(is.na(dt$weight) | dt$weight <= 0)) {
  diag("no usable weights; using unit weights")
  dt[, weight := 1]
}

diag("before restriction: %d rows; exp nonmissing %d; unemp nonmissing %d; weight>0 %d",
     nrow(dt), sum(!is.na(dt$exp)), sum(!is.na(dt$v2unemp)), sum(!is.na(dt$weight) & dt$weight > 0))

# Sample restriction
dt <- dt[!is.na(exp) & !is.na(v2unemp)]
dt <- dt[!is.na(weight) & weight > 0]
diag("analysis sample: %d rows", nrow(dt))
invisible(gc())

dt[, emp_prev := s_eq(pemlr, 1) | s_eq(pemlr, 2)]
dt[, unemp_prev := s_eq(pemlr, 3) | s_eq(pemlr, 4)]
dt[, nilf_prev := s_gt(pemlr, 4)]
dt[, wage_samp := hired2 == 1 & s_eq(v2prwernal, 0)]

keep_cols <- c("hired100", "v2unemp", "young", "youngurate", "oldurate", "v2gestfips",
               "date", "demo2", "weight", "emp_prev", "unemp_prev", "nilf_prev",
               "wage_samp", "v2logwagewkly_r", "v2censusocc_2002recode",
               "v2censusind_2002recode")
dt <- dt[, ..keep_cols]
invisible(gc())

# ---------------- Regressions ----------------
run <- function(fml, data) {
  feols(fml, data = data, weights = ~weight, cluster = ~v2gestfips,
        notes = FALSE)
}
cf <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(fixest::se(m)[v])

res <- list()
put <- function(nm, val) { res[[nm]] <<- val; emit(nm, val) }

# Table 1 Panel A
safe("A1", {
  m <- run(hired100 ~ v2unemp, dt)
  put("aggregate_unemp_rate_no_controls", cf(m, "v2unemp"))
  put("aggregate_unemp_rate_no_controls_se", se(m, "v2unemp"))
  rm(m); invisible(gc())
})

safe("A4", {
  m <- run(hired100 ~ v2unemp | date + v2gestfips + demo2, dt)
  put("aggregate_unemp_rate_month_year_fe", cf(m, "v2unemp"))
  put("aggregate_unemp_rate_month_year_fe_se", se(m, "v2unemp"))
  rm(m); invisible(gc())
})

# Table 1 Panel B
safe("B1", {
  m <- run(hired100 ~ young + youngurate + oldurate, dt)
  put("young_x_unemp_rate_no_controls", cf(m, "youngurate"))
  put("young_x_unemp_rate_no_controls_se", se(m, "youngurate"))
  put("experienced_x_unemp_rate_no_controls", cf(m, "oldurate"))
  put("experienced_x_unemp_rate_no_controls_se", se(m, "oldurate"))
  put("n_obs_full_sample", nobs(m))
  rm(m); invisible(gc())
})

safe("B4", {
  m <- run(hired100 ~ young + youngurate + oldurate | date + v2gestfips + demo2, dt)
  put("young_x_unemp_rate_preferred", cf(m, "youngurate"))
  put("young_x_unemp_rate_preferred_se", se(m, "youngurate"))
  put("experienced_x_unemp_rate_preferred", cf(m, "oldurate"))
  put("experienced_x_unemp_rate_preferred_se", se(m, "oldurate"))
  put("n_obs_preferred", nobs(m))
  rm(m); invisible(gc())
})

# Table 2
safe("T2emp", {
  m <- run(hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date, dt[emp_prev == TRUE])
  put("young_x_unemp_rate_employed", cf(m, "youngurate"))
  put("young_x_unemp_rate_employed_se", se(m, "youngurate"))
  put("experienced_x_unemp_rate_employed", cf(m, "oldurate"))
  put("experienced_x_unemp_rate_employed_se", se(m, "oldurate"))
  rm(m); invisible(gc())
})

safe("T2unemp", {
  m <- run(hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date, dt[unemp_prev == TRUE])
  put("young_x_unemp_rate_unemployed", cf(m, "youngurate"))
  put("young_x_unemp_rate_unemployed_se", se(m, "youngurate"))
  rm(m); invisible(gc())
})

safe("T2nilf", {
  m <- run(hired100 ~ young + youngurate + oldurate | demo2 + v2gestfips + date, dt[nilf_prev == TRUE])
  put("young_x_unemp_rate_nilf", cf(m, "youngurate"))
  put("young_x_unemp_rate_nilf_se", se(m, "youngurate"))
  rm(m); invisible(gc())
})

# Table 10 Panel B col 1
safe("wage", {
  wd <- dt[wage_samp == TRUE & !is.na(v2logwagewkly_r)]
  m <- run(v2logwagewkly_r ~ young + youngurate + oldurate |
             v2gestfips + date + demo2 + v2censusocc_2002recode + v2censusind_2002recode, wd)
  put("wage_young_x_unemp_rate_all_hires", cf(m, "youngurate"))
  put("wage_young_x_unemp_rate_all_hires_se", se(m, "youngurate"))
  put("wage_experienced_x_unemp_rate_all_hires", cf(m, "oldurate"))
  put("wage_experienced_x_unemp_rate_all_hires_se", se(m, "oldurate"))
  put("n_obs_wage_all_hires", nobs(m))
})

cat("DONE\n")