suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(max(1, min(4, parallel::detectCores() - 1)))
data.table::setDTthreads(0)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_unemp <- file.path(base, "v2unemp_smy.csv")
f_defl <- file.path(base, "wage_deflation_1994_2016.csv")
f_occ <- file.path(base, "occ_xwalk2002.csv")
f_ind <- file.path(base, "ind_xwalk2002.csv")

results <- list()
# print each result immediately so partial output survives a later crash / OOM kill
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    results[[name]] <<- val
    cat(sprintf("RESULT:%s=%.6g\n", name, val))
    flush(stdout())
  }
}

# ---------------- helpers ----------------
fix_year <- function(y) {
  y <- as.numeric(y)
  ifelse(!is.na(y) & y < 100, ifelse(y >= 50, 1900 + y, 2000 + y), y)
}

to_int_if <- function(x) {
  if (is.integer(x)) return(x)
  if (is.double(x)) {
    ok <- !is.na(x)
    if (!any(ok)) return(as.integer(x))
    if (all(x[ok] == round(x[ok])) && max(abs(x[ok])) < 2e9) return(as.integer(x))
  }
  x
}

to_num <- function(x, nm = "") {
  if (is.numeric(x) || is.logical(x)) return(as.numeric(x))
  x <- trimws(as.character(x))
  x[x == ""] <- NA
  y <- suppressWarnings(as.numeric(x))
  bad <- !is.na(x) & is.na(y)
  if (mean(bad) < 0.001) return(y)
  lead <- suppressWarnings(as.numeric(sub("^\\s*(-?[0-9]+).*$", "\\1", x)))
  lead[!grepl("^\\s*-?[0-9]+", x)] <- NA
  if (mean(!is.na(x) & is.na(lead)) < 0.001) return(lead)
  lx <- tolower(x)
  out <- y
  if (nm %in% c("pemlr", "v2pemlr")) {
    out <- rep(NA_real_, length(x))
    out[grepl("employed", lx) & grepl("at work", lx) & !grepl("unemp", lx)] <- 1
    out[grepl("employed", lx) & grepl("absent", lx) & !grepl("unemp", lx)] <- 2
    out[grepl("unemp", lx) & grepl("layoff", lx)] <- 3
    out[grepl("unemp", lx) & grepl("look", lx)] <- 4
    out[grepl("retired", lx)] <- 5
    out[grepl("disab", lx)] <- 6
    out[grepl("nilf", lx) & grepl("other", lx)] <- 7
  } else if (nm == "v2puiodp1") {
    out <- rep(NA_real_, length(x))
    out[lx == "yes"] <- 1
    out[lx == "no"] <- 2
    out[is.na(out) & !is.na(lx)] <- -1
  } else if (nm == "pesex") {
    out <- ifelse(grepl("female", lx), 2, ifelse(grepl("male", lx), 1, NA))
  } else if (nm == "race") {
    out <- ifelse(grepl("^white$|white only", lx), 1, ifelse(is.na(lx), NA, 2))
  } else if (nm %in% c("prhspnon", "pehspnon")) {
    out <- ifelse(grepl("non", lx), 2, ifelse(grepl("hisp", lx), 1, NA))
  } else if (nm == "v2peio1cow") {
    out <- ifelse(grepl("self|without pay", lx), 6,
                  ifelse(grepl("gov|private", lx), 1, NA))
    out[is.na(out) & !is.na(y)] <- y[is.na(out) & !is.na(y)]
  } else {
    out[is.na(out)] <- lead[is.na(out)]
  }
  as.numeric(out)
}

# ---------------- load main data ----------------
hdr <- names(fread(f_main, nrows = 0))
find_col <- function(pat) {
  m <- hdr[grepl(pat, hdr, ignore.case = TRUE)]
  if (length(m) == 0) NA_character_ else m[1]
}
col_map <- c(
  peage = find_col("^peage$"),
  peeduc = find_col("^peeduc"),
  race = find_col("^race$"),
  pesex = find_col("^pesex$"),
  prhspnon = find_col("^prhspnon$"),
  pehspnon = find_col("^pehspnon$"),
  pemlr = find_col("^pemlr$"),
  pwsswgt = find_col("^pwsswgt$"),
  v2hrmonth = find_col("^v2hrmonth$"),
  v2hryear = find_col("^v2hryear$"),
  v2gestfips = find_col("^v2gestfips$"),
  v2pemlr = find_col("^v2pemlr$"),
  v2puiodp1 = find_col("^v2puiodp1$"),
  v2peio1cow = find_col("^v2peio1cow$"),
  v2peio1icd = find_col("^v2peio1icd$"),
  v2peio1ocd = find_col("^v2peio1ocd$"),
  v2pwsswgt = find_col("^v2pwsswgt$"),
  v2prwernal = find_col("^v2prwernal$"),
  v2prernwa = find_col("^v2prernwa$")
)
cat("Column mapping:\n"); print(col_map)
sel <- unname(col_map[!is.na(col_map)])
dt <- fread(f_main, select = sel, showProgress = FALSE)
setnames(dt, sel, names(col_map)[!is.na(col_map)])
cat("Raw rows:", nrow(dt), "\n"); flush(stdout())
code_cols <- c("peage", "peeduc", "race", "pesex", "prhspnon", "pehspnon", "pemlr",
               "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr", "v2puiodp1",
               "v2peio1cow", "v2peio1icd", "v2peio1ocd", "v2prwernal")
for (v in names(dt)) {
  if (!is.numeric(dt[[v]])) set(dt, j = v, value = to_num(dt[[v]], v))
  if (v %in% code_cols) set(dt, j = v, value = to_int_if(dt[[v]]))
}
if (!"pehspnon" %in% names(dt)) dt[, pehspnon := NA_integer_]
if (!"prhspnon" %in% names(dt)) dt[, prhspnon := NA_integer_]

dt[, v2hryear := as.integer(fix_year(v2hryear))]
dt[, v2hrmonth := as.integer(v2hrmonth)]
dt[, v2gestfips := as.integer(v2gestfips)]
gc()

# ---------------- state unemployment merge ----------------
un <- fread(f_unemp)
for (v in names(un)) if (!is.numeric(un[[v]])) set(un, j = v, value = to_num(un[[v]], v))
un[, v2hryear := as.integer(fix_year(v2hryear))]
un[, v2hrmonth := as.integer(v2hrmonth)]
un[, v2gestfips := as.integer(v2gestfips)]
un <- unique(un, by = c("v2hryear", "v2hrmonth", "v2gestfips"))
setnames(un, "v2unemp_smy", "v2unemp")
un[, v2unemp := as.numeric(v2unemp)]
dt[un, v2unemp := i.v2unemp, on = .(v2hryear, v2hrmonth, v2gestfips)]
rm(un)

# ---------------- variable construction ----------------
yrs_map <- c(`31` = 1, `32` = 4, `33` = 6, `34` = 8, `35` = 9, `36` = 10, `37` = 11,
             `38` = 11.5, `39` = 12, `40` = 13, `41` = 14, `42` = 14, `43` = 16,
             `44` = 18, `45` = 20, `46` = 22)
yrsch <- unname(yrs_map[as.character(dt$peeduc)])
yrsch[is.na(yrsch)] <- 0
age <- as.numeric(dt$peage)
age[!is.na(age) & age > 79] <- NA
expv <- age - yrsch - 6
rm(age, yrsch)
keep <- !is.na(expv) & !is.na(dt$v2unemp)
dt[, exp := expv]
rm(expv)
dt <- dt[keep]
rm(keep); gc()

dt[, educ := NA_integer_]
dt[!is.na(peeduc) & peeduc > 0 & peeduc < 39, educ := 0L]
dt[peeduc == 39, educ := 1L]
dt[peeduc > 39 & peeduc < 43, educ := 2L]
dt[peeduc == 43, educ := 3L]
dt[peeduc == 44, educ := 4L]
dt[peeduc == 45, educ := 5L]
dt[peeduc == 46, educ := 6L]

# Stata: missing > any number
dt[, minority := as.integer(is.na(race) | race > 1)]
dt[, female := as.integer(is.na(pesex) | pesex > 1)]
dt[, hisp := as.integer((!is.na(pehspnon) & pehspnon == 1) | (!is.na(prhspnon) & prhspnon == 1))]

# hired
dt[, hired2 := as.integer(!is.na(v2pemlr) & v2pemlr %in% c(1L, 2L))]
dt[!is.na(v2puiodp1) & v2puiodp1 == 1, hired2 := 0L]
dt[!is.na(pemlr) & pemlr %in% c(1L, 2L) & !is.na(v2puiodp1) & v2puiodp1 < 0, hired2 := 0L]
dt[is.na(v2peio1cow) | v2peio1cow >= 5, hired2 := 0L]
dt[, hired100 := hired2 * 100]

dt[, young := as.integer(exp <= 10)]
dt[, youngurate := fifelse(young == 1L, v2unemp, 0)]
dt[, oldurate := fifelse(young == 0L & exp > 10, v2unemp, 0)]

dt[, demo2 := fifelse(is.na(educ), NA_integer_,
                      as.integer(minority * 1000L + female * 100L + hisp * 10L + educ))]
dt[, date := as.integer(v2hryear * 12L + v2hrmonth)]
dt[, weight := (v2pwsswgt + pwsswgt) / 2]
dt[, state := v2gestfips]

dt[, c("peage", "race", "pesex", "prhspnon", "pehspnon", "peeduc", "educ",
       "minority", "female", "hisp", "v2pemlr", "v2puiodp1",
       "v2pwsswgt", "pwsswgt", "v2gestfips") := NULL]
gc()

# ---------------- extract wage sample early, then drop wage columns ----------------
wcols <- c("hired2", "v2prwernal", "v2prernwa", "v2peio1icd", "v2peio1ocd",
           "v2hryear", "v2hrmonth", "young", "youngurate", "oldurate",
           "state", "date", "demo2", "weight")
wcols <- intersect(wcols, names(dt))
w_raw <- tryCatch(dt[hired2 == 1L & !is.na(v2prwernal) & v2prwernal == 0, ..wcols],
                  error = function(e) { cat("ERROR wage subset:", conditionMessage(e), "\n"); NULL })
dropc <- intersect(c("v2prwernal", "v2prernwa", "v2peio1icd", "v2peio1ocd",
                     "v2peio1cow", "hired2", "exp", "v2hryear", "v2hrmonth"), names(dt))
dt[, (dropc) := NULL]
gc()

cat("Analysis sample N:", nrow(dt), "\n")
cat("Mean hired100 (weighted):", weighted.mean(dt$hired100, dt$weight, na.rm = TRUE), "\n")
flush(stdout())

getc <- function(m, v) {
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}
run <- function(expr, label) {
  tryCatch(expr, error = function(e) {
    cat("ERROR in", label, ":", conditionMessage(e), "\n"); NULL
  })
}

# ---------------- Table 1 Panel A ----------------
mA1 <- run(feols(hired100 ~ v2unemp, data = dt, weights = ~weight,
                 cluster = ~state, lean = TRUE, mem.clean = TRUE), "A1")
if (!is.null(mA1)) {
  emit("aggregate_unemp_rate_no_controls", getc(mA1, "v2unemp"))
  emit("n_obs_full_sample", nobs(mA1))
}
rm(mA1); gc()

mA4 <- run(feols(hired100 ~ v2unemp | date + state + demo2, data = dt,
                 weights = ~weight, cluster = ~state, fixef.rm = "none",
                 lean = TRUE, mem.clean = TRUE), "A4")
if (!is.null(mA4)) {
  emit("aggregate_unemp_rate_month_year_fe", getc(mA4, "v2unemp"))
  cat("A4 N:", nobs(mA4), "\n")
}
rm(mA4); gc()

# ---------------- Table 1 Panel B ----------------
mB1 <- run(feols(hired100 ~ young + youngurate + oldurate, data = dt,
                 weights = ~weight, cluster = ~state, lean = TRUE, mem.clean = TRUE), "B1")
if (!is.null(mB1)) {
  emit("young_x_unemp_rate_no_controls", getc(mB1, "youngurate"))
  emit("experienced_x_unemp_rate_no_controls", getc(mB1, "oldurate"))
}
rm(mB1); gc()

mB4 <- run(feols(hired100 ~ young + youngurate + oldurate | date + state + demo2,
                 data = dt, weights = ~weight, cluster = ~state,
                 fixef.rm = "none", lean = TRUE, mem.clean = TRUE), "B4")
if (!is.null(mB4)) {
  emit("young_x_unemp_rate_preferred", getc(mB4, "youngurate"))
  emit("experienced_x_unemp_rate_preferred", getc(mB4, "oldurate"))
  cat("B4 N:", nobs(mB4), "\n")
}
rm(mB4); gc()

# ---------------- Table 2 by origin state ----------------
fml2 <- hired100 ~ young + youngurate + oldurate | demo2 + state + date
pm <- dt$pemlr
dt[, pemlr := NULL]

sub_e <- dt[!is.na(pm) & pm %in% c(1L, 2L)]
m2 <- run(feols(fml2, data = sub_e, weights = ~weight, cluster = ~state,
                fixef.rm = "none", lean = TRUE, mem.clean = TRUE), "T2 emp")
rm(sub_e); gc()
if (!is.null(m2)) {
  emit("young_x_unemp_rate_employed", getc(m2, "youngurate"))
  emit("experienced_x_unemp_rate_employed", getc(m2, "oldurate"))
}
rm(m2); gc()

sub_u <- dt[!is.na(pm) & pm %in% c(3L, 4L)]
m3 <- run(feols(fml2, data = sub_u, weights = ~weight, cluster = ~state,
                fixef.rm = "none", lean = TRUE, mem.clean = TRUE), "T2 unemp")
rm(sub_u); gc()
if (!is.null(m3)) emit("young_x_unemp_rate_unemployed", getc(m3, "youngurate"))
rm(m3); gc()

sub_n <- dt[is.na(pm) | pm > 4]
m4 <- run(feols(fml2, data = sub_n, weights = ~weight, cluster = ~state,
                fixef.rm = "none", lean = TRUE, mem.clean = TRUE), "T2 nilf")
rm(sub_n); gc()
if (!is.null(m4)) emit("young_x_unemp_rate_nilf", getc(m4, "youngurate"))
rm(m4); gc()

rm(dt, pm); gc()

# ---------------- Table 10 Panel B: wages of new hires ----------------
wg <- NULL
if (!is.null(w_raw)) {
  wg <- run({
    w <- w_raw
    defl <- fread(f_defl)
    for (v in names(defl)) if (!is.numeric(defl[[v]])) set(defl, j = v, value = to_num(defl[[v]], v))
    defl[, year := as.integer(fix_year(year))]
    defl[, month := as.integer(month)]
    defl <- unique(defl, by = c("year", "month"))
    w[defl, v2cpi := i.cpi, on = .(v2hryear = year, v2hrmonth = month)]
    w[, lw := fifelse(!is.na(v2prernwa) & v2prernwa > 0 & !is.na(v2cpi) & v2cpi > 0,
                      log(v2prernwa / v2cpi), NA_real_)]

    # occupation crosswalk
    w[, v2occ_codeyear := fifelse(v2hryear < 2003L, 1990L, fifelse(v2hryear < 2011L, 2002L, 2010L))]
    w[, v2peio1ocd := as.integer(v2peio1ocd)]
    occ <- fread(f_occ)
    for (v in names(occ)) if (!is.numeric(occ[[v]])) set(occ, j = v, value = to_num(occ[[v]], v))
    occ[, v2peio1ocd := as.integer(v2peio1ocd)]
    occ[, v2occ_codeyear := as.integer(v2occ_codeyear)]
    occ <- unique(occ, by = c("v2peio1ocd", "v2occ_codeyear"))
    w[occ, occ02 := i.v2censusocc_2002recode, on = .(v2peio1ocd, v2occ_codeyear)]
    if (!"occ02" %in% names(w)) w[, occ02 := NA_real_]

    # industry crosswalk
    w[, v2ind_codeyear := fifelse(v2hryear < 2003L, 1990L,
                           fifelse(v2hryear < 2009L, 2002L,
                           fifelse(v2hryear < 2014L, 2007L, 2012L)))]
    w[, v2peio1icd := as.integer(v2peio1icd)]
    ind <- fread(f_ind)
    for (v in names(ind)) if (!is.numeric(ind[[v]])) set(ind, j = v, value = to_num(ind[[v]], v))
    ind[, v2peio1icd := as.integer(v2peio1icd)]
    ind[, v2ind_codeyear := as.integer(v2ind_codeyear)]
    ind[, v2censusind_2002recode := as.numeric(v2censusind_2002recode)]
    ind <- unique(ind, by = c("v2peio1icd", "v2ind_codeyear"))
    w[, ind_matched := FALSE]
    w[, ind02 := NA_real_]
    w[ind, `:=`(ind02 = i.v2censusind_2002recode, ind_matched = TRUE),
      on = .(v2peio1icd, v2ind_codeyear)]
    w[ind_matched == FALSE & v2peio1icd == 6692L, ind02 := 6692]
    w[ind_matched == FALSE & v2peio1icd == 991L, ind02 := 9890]
    w[ind_matched == FALSE & v2peio1icd == 9890L, ind02 := 9890]
    w
  }, "wage prep")
}

if (!is.null(wg)) {
  mw <- run(feols(lw ~ young + youngurate + oldurate | state + date + demo2 + occ02 + ind02,
                  data = wg, weights = ~weight, cluster = ~state,
                  fixef.rm = "none", lean = TRUE), "T10 B1")
  if (!is.null(mw)) {
    emit("wage_young_x_unemp_rate_all_hires", getc(mw, "youngurate"))
    emit("wage_experienced_x_unemp_rate_all_hires", getc(mw, "oldurate"))
    cat("Wage N:", nobs(mw), "\n")
  }
}

# ---------------- output ----------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6g\n", nm, results[[nm]]))
}
