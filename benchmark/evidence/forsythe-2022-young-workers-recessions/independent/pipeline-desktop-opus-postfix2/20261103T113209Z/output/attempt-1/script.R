suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setDTthreads(0)

root <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free"
ddir <- file.path(root, "3 replication package", "Data")
f_main  <- file.path(ddir, "yh_data.csv")
f_unemp <- file.path(ddir, "v2unemp_smy.csv")
f_cpi   <- file.path(ddir, "wage_deflation_1994_2016.csv")
f_occ   <- file.path(ddir, "occ_xwalk2002.csv")
f_ind   <- file.path(ddir, "ind_xwalk2002.csv")

# ---------------------------------------------------------------------------
# Load main matched-pair file (unprefixed = month t-1, v2 prefix = month t)
# ---------------------------------------------------------------------------
hdr <- names(fread(f_main, nrows = 0))
want <- c("hrmonth", "hryear", "peage", "pesex", "peeduca", "race", "prhspnon", "pehspnon",
          "pemlr", "pwsswgt", "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr", "v2puiodp1",
          "v2peio1cow", "v2peio1icd", "v2peio1ocd", "v2prernwa", "v2prwernal", "v2pwsswgt")
sel <- intersect(want, hdr)
dt <- fread(f_main, select = sel, showProgress = FALSE)
for (v in names(dt)) {
  if (!is.numeric(dt[[v]])) set(dt, j = v, value = suppressWarnings(as.numeric(dt[[v]])))
}
cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(dt)))

# ---------------------------------------------------------------------------
# Sample restrictions
# ---------------------------------------------------------------------------
dt[, ym0 := hryear * 12L + hrmonth]
dt[, ym1 := v2hryear * 12L + v2hrmonth]

# Period: January 1994 to September 2016
dt <- dt[ym0 >= 1994 * 12 + 1 & ym1 <= 2016 * 12 + 9]
cat(sprintf("SAMPLE:main:period_jan1994_sep2016=%d\n", nrow(dt)))

# Drop May-August 1995 (no longitudinal link)
dt <- dt[!((hryear == 1995 & hrmonth %in% 5:8) | (v2hryear == 1995 & v2hrmonth %in% 5:8))]
cat(sprintf("SAMPLE:main:drop_may_aug_1995=%d\n", nrow(dt)))

# Consecutive months only (drops pairs spanning the MIS 4-5 sampling break)
dt <- dt[ym1 - ym0 == 1]
cat(sprintf("SAMPLE:main:consecutive_months=%d\n", nrow(dt)))

# Civilians aged 16+ (valid labor force status both months; armed forces have no LF status)
dt <- dt[!is.na(peage) & peage >= 16 & pemlr %in% 1:7 & v2pemlr %in% 1:7]
cat(sprintf("SAMPLE:main:civilian_age16plus=%d\n", nrow(dt)))

# Non-missing age and education
dt <- dt[!is.na(peage) & peeduca %in% 31:46]
cat(sprintf("SAMPLE:main:nonmissing_age_education=%d\n", nrow(dt)))

# ---------------------------------------------------------------------------
# State unemployment rate (month t)
# ---------------------------------------------------------------------------
um <- fread(f_unemp)
for (v in names(um)) um[, (v) := as.numeric(get(v))]
um <- unique(um, by = c("v2gestfips", "v2hryear", "v2hrmonth"))
if (max(um$v2unemp_smy, na.rm = TRUE) <= 1) um[, v2unemp_smy := 100 * v2unemp_smy]
dt <- merge(dt, um, by = c("v2gestfips", "v2hryear", "v2hrmonth"), all.x = FALSE)
setnames(dt, "v2unemp_smy", "U")
dt <- dt[!is.na(U)]
cat(sprintf("SAMPLE:main:merged_state_unemp=%d\n", nrow(dt)))

# Weights: average of the two months' CPS weights
dt[, w := (pwsswgt + v2pwsswgt) / 2]
dt <- dt[!is.na(w) & w > 0]
cat(sprintf("SAMPLE:main:positive_weight=%d\n", nrow(dt)))

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
educ_years <- c(`31` = 0, `32` = 2.5, `33` = 5.5, `34` = 7.5, `35` = 9, `36` = 10, `37` = 11,
                `38` = 12, `39` = 12, `40` = 13, `41` = 14, `42` = 14, `43` = 16, `44` = 18,
                `45` = 20, `46` = 20)
dt[, eyrs := educ_years[as.character(peeduca)]]
dt[, pe := peage - eyrs - 6]
dt[, young := as.integer(pe <= 10)]
dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca %in% 40:42, 3L,
                    peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L, peeduca == 46, 7L)]
dt[, white := as.integer(race == 1)]
if ("prhspnon" %in% names(dt) && "pehspnon" %in% names(dt)) {
  dt[, hisp := fifelse(prhspnon %in% 1:2, as.integer(prhspnon == 1),
                       fifelse(pehspnon %in% 1:2, as.integer(pehspnon == 1), 0L))]
} else if ("prhspnon" %in% names(dt)) {
  dt[, hisp := as.integer(prhspnon == 1)]
} else {
  dt[, hisp := as.integer(pehspnon == 1)]
}
dt[, demo := as.integer(pesex) * 1000L + white * 100L + hisp * 10L + educ7]
dt[, state := as.integer(v2gestfips)]
dt[, ym := as.integer(ym1)]

emp0 <- dt$pemlr %in% 1:2
emp1 <- dt$v2pemlr %in% 1:2
selfemp1 <- dt$v2peio1cow %in% c(6, 7)
newfirm <- dt$v2puiodp1 %in% 2
dt[, hired := as.integer(emp1 & (!emp0 | (emp0 & newfirm)) & !selfemp1)]
dt[, hired100 := 100 * hired]
dt[, status := fcase(pemlr %in% 1:2, 1L, pemlr %in% 3:4, 2L, pemlr %in% 5:7, 3L)]
dt[, uy := U * young]
dt[, uo := U * (1L - young)]
rm(emp0, emp1, selfemp1, newfirm); invisible(gc())

cat(sprintf("SAMPLE:main:final=%d\n", nrow(dt)))
if (abs(nrow(dt) - 16948516) / 16948516 > 0.01) {
  cat(sprintf("DEVIATION: full sample has %d rows vs 16948516 stated in the paper (Table 1 N).\n", nrow(dt)))
}

# ---------------------------------------------------------------------------
# Wage sample (new hires with non-allocated weekly earnings; outgoing rotation months)
# ---------------------------------------------------------------------------
hw <- NULL
if (all(c("v2prernwa", "v2prwernal") %in% names(dt))) {
  hw <- dt[hired == 1, .(v2hryear, v2hrmonth, v2prernwa, v2prwernal, v2peio1icd, v2peio1ocd,
                         young, uy, uo, U, state, demo, ym, w)]
  cat(sprintf("SAMPLE:wage:loaded=%d\n", nrow(hw)))
  hw <- hw[!is.na(v2prernwa) & v2prernwa > 0]
  cat(sprintf("SAMPLE:wage:outgoing_rotation_positive_earnings=%d\n", nrow(hw)))
  if (any(hw$v2prwernal == 0, na.rm = TRUE)) {
    hw <- hw[v2prwernal == 0]
  } else {
    hw <- hw[is.na(v2prwernal) | v2prwernal != 1]
  }
  cat(sprintf("SAMPLE:wage:non_allocated_earnings=%d\n", nrow(hw)))
  cpi <- fread(f_cpi)
  for (v in names(cpi)) cpi[, (v) := as.numeric(get(v))]
  cpi_base <- mean(cpi[year == 1994, cpi], na.rm = TRUE)
  hw <- merge(hw, cpi, by.x = c("v2hryear", "v2hrmonth"), by.y = c("year", "month"), all.x = FALSE)
  hw[, lw := log(v2prernwa * cpi_base / cpi)]
  hw <- hw[is.finite(lw)]
  cat(sprintf("SAMPLE:wage:deflated=%d\n", nrow(hw)))

  # Crosswalk occupation / industry codes to consistent 2002 Census codes
  map_codes <- function(codes, years, xw, codecol, yearcol, recodecol, scheme_fun, nsch) {
    xw <- copy(xw)
    xw[, (codecol) := as.numeric(get(codecol))]
    cy <- sort(unique(xw[[yearcol]]))
    sch <- scheme_fun(years)
    if (length(cy) == nsch) {
      cyobs <- cy[sch]
    } else {
      cyn <- suppressWarnings(as.numeric(cy))
      idx <- findInterval(years, cyn)
      idx[idx == 0] <- 1
      cyobs <- cy[idx]
    }
    key <- data.table(code = as.numeric(codes), cyr = cyobs, ord = seq_along(codes))
    xw2 <- unique(xw[, .(code = get(codecol), cyr = get(yearcol), rec = get(recodecol))],
                  by = c("code", "cyr"))
    out <- merge(key, xw2, by = c("code", "cyr"), all.x = TRUE)
    setorder(out, ord)
    rec <- suppressWarnings(as.numeric(out$rec))
    cat(sprintf("NOTE: %s crosswalk match rate = %.3f\n", codecol, mean(!is.na(rec))))
    # Fallback for unmatched codes: keep raw code within scheme
    fb <- 1e6 + sch * 1e5 + as.numeric(codes)
    rec[is.na(rec)] <- fb[is.na(rec)]
    rec
  }
  occ_scheme <- function(y) fifelse(y <= 2002, 1L, fifelse(y <= 2010, 2L, 3L))
  ind_scheme <- function(y) fifelse(y <= 2002, 1L, fifelse(y <= 2008, 2L, fifelse(y <= 2013, 3L, 4L)))
  oxw <- fread(f_occ)
  ixw <- fread(f_ind)
  hw[, occ := map_codes(v2peio1ocd, v2hryear, oxw, "v2peio1ocd", "v2occ_codeyear",
                        "v2censusocc_2002recode", occ_scheme, 3)]
  hw[, ind := map_codes(v2peio1icd, v2hryear, ixw, "v2peio1icd", "v2ind_codeyear",
                        "v2censusind_2002recode", ind_scheme, 4)]
  cat("DEVIATION: month-in-sample is not in the data; outgoing-rotation months are identified by non-missing weekly earnings.\n")
} else {
  cat("DEVIATION: weekly earnings variables not available; wage regressions skipped.\n")
}

# Trim main data to regression variables
keep <- c("hired100", "U", "young", "uy", "uo", "state", "demo", "ym", "w", "status")
dt <- dt[, ..keep]
invisible(gc())

# ---------------------------------------------------------------------------
# Table 1 / Table 2 hiring regressions
# ---------------------------------------------------------------------------
mA1 <- feols(hired100 ~ U, data = dt, weights = ~w, cluster = ~state, lean = TRUE)
cat(sprintf("SAMPLE:t1_panelA_col1:estimation=%d\n", nobs(mA1)))
mA4 <- feols(hired100 ~ U | state + demo + ym, data = dt, weights = ~w, cluster = ~state, lean = TRUE)
cat(sprintf("SAMPLE:t1_panelA_col4:estimation=%d\n", nobs(mA4)))
mB1 <- feols(hired100 ~ young + uy + uo, data = dt, weights = ~w, cluster = ~state, lean = TRUE)
cat(sprintf("SAMPLE:t1_panelB_col1:estimation=%d\n", nobs(mB1)))
mB4 <- feols(hired100 ~ young + uy + uo | state + demo + ym, data = dt, weights = ~w,
             cluster = ~state, lean = TRUE)
cat(sprintf("SAMPLE:t2_col1_all:estimation=%d\n", nobs(mB4)))

res_sub <- list()
labs <- c(`1` = "employed", `2` = "unemployed", `3` = "nilf")
for (s in 1:3) {
  nm <- paste0("t2_", labs[as.character(s)])
  cat(sprintf("SAMPLE:%s:loaded=%d\n", nm, nrow(dt)))
  cat(sprintf("SAMPLE:%s:status_t_minus_1=%d\n", nm, sum(dt$status == s, na.rm = TRUE)))
  m <- feols(hired100 ~ young + uy + uo | state + demo + ym, data = dt[status == s],
             weights = ~w, cluster = ~state, lean = TRUE)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, nobs(m)))
  res_sub[[labs[as.character(s)]]] <- m
}

mW <- NULL
if (!is.null(hw)) {
  mW <- feols(lw ~ young + uy + uo | state + demo + ym + occ + ind, data = hw, weights = ~w,
              cluster = ~state, lean = TRUE)
  cat(sprintf("SAMPLE:wage:estimation=%d\n", nobs(mW)))
}

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
out <- function(name, m, v) {
  b <- unname(coef(m)[v]); se <- unname(sqrt(diag(vcov(m)))[v])
  cat(sprintf("RESULT:%s=%.6f\n", name, b))
  cat(sprintf("RESULT:%s_se=%.6f\n", name, se))
}
out("young_x_unemp_rate_no_controls", mB1, "uy")
out("experienced_x_unemp_rate_no_controls", mB1, "uo")
out("young_x_unemp_rate_preferred", mB4, "uy")
out("experienced_x_unemp_rate_preferred", mB4, "uo")
out("aggregate_unemp_rate_no_controls", mA1, "U")
out("aggregate_unemp_rate_month_year_fe", mA4, "U")
out("young_x_unemp_rate_employed", res_sub[["employed"]], "uy")
out("experienced_x_unemp_rate_employed", res_sub[["employed"]], "uo")
out("young_x_unemp_rate_unemployed", res_sub[["unemployed"]], "uy")
out("young_x_unemp_rate_nilf", res_sub[["nilf"]], "uy")
if (!is.null(mW)) {
  out("wage_young_x_unemp_rate_all_hires", mW, "uy")
  out("wage_experienced_x_unemp_rate_all_hires", mW, "uo")
}
cat(sprintf("RESULT:n_obs_full_sample=%d\n", nobs(mA1)))