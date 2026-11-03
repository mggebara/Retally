suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(0)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main  <- file.path(base, "yh_data.csv")
f_unemp <- file.path(base, "v2unemp_smy.csv")
f_cpi   <- file.path(base, "wage_deflation_1994_2016.csv")
f_occ   <- file.path(base, "occ_xwalk2002.csv")
f_ind   <- file.path(base, "ind_xwalk2002.csv")

# ---------------------------------------------------------------- load
hdr <- names(fread(f_main, nrows = 0))
want <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon",
          "pemlr","pwsswgt","v2hrmonth","v2hryear","v2gestfips","v2pemlr",
          "v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd","v2prernwa",
          "v2pwsswgt","v2prwernal")
sel <- intersect(want, hdr)
dt <- fread(f_main, select = sel, showProgress = FALSE)
for (v in sel) if (!is.numeric(dt[[v]])) set(dt, j = v, value = suppressWarnings(as.numeric(dt[[v]])))
cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(dt)))

# ---------------------------------------------------------------- restrictions
# civilians (valid labour-force status in both months, i.e. not armed forces / out of universe) aged 16+
dt <- dt[!is.na(pemlr) & pemlr %in% 1:7 & !is.na(v2pemlr) & v2pemlr %in% 1:7]
dt <- dt[!is.na(peage) & peage >= 16]
cat(sprintf("SAMPLE:main:civilian_over16=%d\n", nrow(dt)))
dt <- dt[!is.na(peeduca) & peeduca %in% 31:46]
cat(sprintf("SAMPLE:main:nonmissing_age_education=%d\n", nrow(dt)))
dt <- dt[!(v2hryear == 1995 & v2hrmonth %in% 5:8) & !(hryear == 1995 & hrmonth %in% 5:8)]
cat(sprintf("SAMPLE:main:exclude_may_aug_1995=%d\n", nrow(dt)))
dt <- dt[(v2hryear > 1994 | (v2hryear == 1994 & v2hrmonth >= 1)) &
         (v2hryear < 2016 | (v2hryear == 2016 & v2hrmonth <= 9))]
cat(sprintf("SAMPLE:main:jan1994_sep2016=%d\n", nrow(dt)))
cat("DEVIATION: no month-in-sample variable in the data; the 8-month MIS 4->5 break and Madrian-Lefgren matching are assumed already applied in the matched file.\n")

# ---------------------------------------------------------------- merge unemployment
un <- fread(f_unemp)
for (v in names(un)) if (!is.numeric(un[[v]])) set(un, j = v, value = suppressWarnings(as.numeric(un[[v]])))
if (max(un$v2unemp_smy, na.rm = TRUE) < 1) un[, v2unemp_smy := 100 * v2unemp_smy]
un <- unique(un, by = c("v2gestfips","v2hryear","v2hrmonth"))
dt <- merge(dt, un, by = c("v2gestfips","v2hryear","v2hrmonth"), all.x = FALSE)
setnames(dt, "v2unemp_smy", "urate")
dt <- dt[!is.na(urate)]
cat(sprintf("SAMPLE:main:merged_state_unemp=%d\n", nrow(dt)))

# ---------------------------------------------------------------- variables
emp_prev <- dt$pemlr %in% 1:2
emp_now  <- dt$v2pemlr %in% 1:2
selfemp  <- !is.na(dt$v2peio1cow) & dt$v2peio1cow %in% c(6, 7)
newfirm  <- !is.na(dt$v2puiodp1) & dt$v2puiodp1 == 2
dt[, hired := 100 * as.numeric(emp_now & !selfemp & ((!emp_prev) | (emp_prev & newfirm)))]
rm(emp_prev, emp_now, selfemp, newfirm); invisible(gc())

edyrs <- c(`31`=0, `32`=2.5, `33`=5.5, `34`=7.5, `35`=9, `36`=10, `37`=11, `38`=12,
           `39`=12, `40`=13, `41`=14, `42`=14, `43`=16, `44`=18, `45`=20, `46`=20)
dt[, educ_years := edyrs[as.character(peeduca)]]
dt[, pexp := peage - educ_years - 6]
dt[, young := as.numeric(pexp <= 10)]
dt[, exper := 1 - young]
dt[, young_u := young * urate]
dt[, exper_u := exper * urate]

dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca %in% 40:42, 3L,
                    peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L, peeduca == 46, 7L)]
hsp <- rep(NA_real_, nrow(dt))
if ("prhspnon" %in% names(dt)) hsp <- ifelse(!is.na(dt$prhspnon) & dt$prhspnon %in% 1:2, dt$prhspnon, hsp)
if ("pehspnon" %in% names(dt)) hsp <- ifelse(is.na(hsp) & !is.na(dt$pehspnon) & dt$pehspnon %in% 1:2, dt$pehspnon, hsp)
dt[, hisp := as.integer(!is.na(hsp) & hsp == 1)]
rm(hsp)
dt[, white := as.integer(!is.na(race) & race == 1)]
dt[, demo := pesex * 1000 + white * 100 + hisp * 10 + educ7]
dt[, state := v2gestfips]
dt[, my := v2hryear * 100 + v2hrmonth]
w1 <- ifelse(is.na(dt$pwsswgt) | dt$pwsswgt <= 0, NA, dt$pwsswgt)
w2 <- ifelse(is.na(dt$v2pwsswgt) | dt$v2pwsswgt <= 0, NA, dt$v2pwsswgt)
dt[, wt := rowMeans(cbind(w1, w2), na.rm = TRUE)]
rm(w1, w2)
dt <- dt[is.finite(wt) & wt > 0 & !is.na(pexp)]
cat(sprintf("SAMPLE:main:positive_weight=%d\n", nrow(dt)))
cat("SAMPLE:main:paper_stated_N=16948516\n")

# ---------------------------------------------------------------- helper
gc_coef <- function(m, v) unname(coef(m)[v])
gc_se   <- function(m, v) unname(sqrt(diag(vcov(m)))[v])
res <- list()

# ---------------------------------------------------------------- Table 1 Panel A
mA1 <- feols(hired ~ urate, data = dt, weights = ~wt, cluster = ~state)
mA4 <- feols(hired ~ urate | state + demo + my, data = dt, weights = ~wt, cluster = ~state)
cat(sprintf("SAMPLE:t1_panelA_col1:estimation=%d\n", nobs(mA1)))
cat(sprintf("SAMPLE:t1_panelA_col4:estimation=%d\n", nobs(mA4)))

# ---------------------------------------------------------------- Table 1 Panel B
mB1 <- feols(hired ~ young + young_u + exper_u, data = dt, weights = ~wt, cluster = ~state)
mB4 <- feols(hired ~ young + young_u + exper_u | state + demo + my, data = dt, weights = ~wt, cluster = ~state)
cat(sprintf("SAMPLE:t1_panelB_col1:estimation=%d\n", nobs(mB1)))
cat(sprintf("SAMPLE:t1_panelB_col4:estimation=%d\n", nobs(mB4)))

# ---------------------------------------------------------------- Table 2 by origin
run_origin <- function(codes, nm) {
  sub <- dt[pemlr %in% codes]
  cat(sprintf("SAMPLE:t2_%s:loaded=%d\n", nm, nrow(dt)))
  cat(sprintf("SAMPLE:t2_%s:origin_status_t_minus_1=%d\n", nm, nrow(sub)))
  m <- feols(hired ~ young + young_u + exper_u | state + demo + my, data = sub, weights = ~wt, cluster = ~state)
  cat(sprintf("SAMPLE:t2_%s:estimation=%d\n", nm, nobs(m)))
  m
}
mE <- run_origin(1:2, "employed")
mU <- run_origin(3:4, "unemployed")
mN <- run_origin(5:7, "nilf")

# ---------------------------------------------------------------- Table 10 wages
mW <- NULL
wage_ok <- all(c("v2prernwa","v2peio1ocd","v2peio1icd") %in% names(dt))
if (wage_ok) {
  wd <- dt[hired == 100]
  cat(sprintf("SAMPLE:t10_wage:loaded=%d\n", nrow(dt)))
  cat(sprintf("SAMPLE:t10_wage:new_hires=%d\n", nrow(wd)))
  wd <- wd[!is.na(v2prernwa) & v2prernwa > 0]
  cat(sprintf("SAMPLE:t10_wage:outgoing_rotation_with_earnings=%d\n", nrow(wd)))
  if ("v2prwernal" %in% names(wd)) {
    wd <- wd[is.na(v2prwernal) | v2prwernal == 0]
  } else cat("DEVIATION: no weekly-earnings allocation flag; allocated wages not dropped.\n")
  cat(sprintf("SAMPLE:t10_wage:non_allocated=%d\n", nrow(wd)))
  cpi <- fread(f_cpi)
  cpi <- unique(cpi, by = c("year","month"))
  wd <- merge(wd, cpi, by.x = c("v2hryear","v2hrmonth"), by.y = c("year","month"), all.x = TRUE)
  cpi94 <- mean(cpi[year == 1994]$cpi, na.rm = TRUE)
  wd[, logw := log(v2prernwa / (cpi / cpi94))]
  wd <- wd[is.finite(logw)]
  cat(sprintf("SAMPLE:t10_wage:deflated=%d\n", nrow(wd)))

  # crosswalks to consistent 2002 codes
  map_codes <- function(wd, xw, codecol, yrcol, recol, breaks_mid, breaks_hi) {
    xw <- copy(xw)
    for (v in names(xw)) if (!is.numeric(xw[[v]])) set(xw, j = v, value = suppressWarnings(as.numeric(xw[[v]])))
    cy <- sort(unique(xw[[yrcol]]))
    yr <- wd$v2hryear
    if (length(cy) == 3) {
      sch <- ifelse(yr < breaks_mid, cy[1], ifelse(yr < breaks_hi, cy[2], cy[3]))
    } else {
      sch <- sapply(yr, function(y) { k <- cy[cy <= y]; if (length(k)) max(k) else min(cy) })
    }
    key <- data.table(code = wd[[codecol]], sch = sch)
    xw2 <- unique(xw[, .(code = get(codecol), sch = get(yrcol), rec = get(recol))], by = c("code","sch"))
    key[, idx := .I]
    key <- merge(key, xw2, by = c("code","sch"), all.x = TRUE)
    setorder(key, idx)
    out <- ifelse(is.na(key$rec), paste0("raw_", key$sch, "_", key$code), as.character(key$rec))
    out[is.na(key$code) | key$code < 0] <- NA
    out
  }
  occx <- fread(f_occ); indx <- fread(f_ind)
  wd[, occ := map_codes(wd, occx, "v2peio1ocd", "v2occ_codeyear", "v2censusocc_2002recode", 2003, 2011)]
  wd[, ind := map_codes(wd, indx, "v2peio1icd", "v2ind_codeyear", "v2censusind_2002recode", 2003, 2009)]
  wd <- wd[!is.na(occ) & !is.na(ind)]
  cat(sprintf("SAMPLE:t10_wage:nonmissing_occ_ind=%d\n", nrow(wd)))
  mW <- feols(logw ~ young + young_u + exper_u | state + demo + my + occ + ind,
              data = wd, weights = ~wt, cluster = ~state)
  cat(sprintf("SAMPLE:t10_wage:estimation=%d\n", nobs(mW)))
} else {
  cat("DEVIATION: wage / occupation / industry columns missing; Table 10 not estimated.\n")
}

# ---------------------------------------------------------------- results
out <- function(nm, val) cat(sprintf("RESULT:%s=%.6g\n", nm, val))
out("young_x_unemp_rate_no_controls", gc_coef(mB1, "young_u"))
out("young_x_unemp_rate_no_controls_se", gc_se(mB1, "young_u"))
out("experienced_x_unemp_rate_no_controls", gc_coef(mB1, "exper_u"))
out("experienced_x_unemp_rate_no_controls_se", gc_se(mB1, "exper_u"))
out("young_x_unemp_rate_preferred", gc_coef(mB4, "young_u"))
out("young_x_unemp_rate_preferred_se", gc_se(mB4, "young_u"))
out("experienced_x_unemp_rate_preferred", gc_coef(mB4, "exper_u"))
out("experienced_x_unemp_rate_preferred_se", gc_se(mB4, "exper_u"))
out("aggregate_unemp_rate_no_controls", gc_coef(mA1, "urate"))
out("aggregate_unemp_rate_no_controls_se", gc_se(mA1, "urate"))
out("aggregate_unemp_rate_month_year_fe", gc_coef(mA4, "urate"))
out("aggregate_unemp_rate_month_year_fe_se", gc_se(mA4, "urate"))
out("young_x_unemp_rate_employed", gc_coef(mE, "young_u"))
out("young_x_unemp_rate_employed_se", gc_se(mE, "young_u"))
out("experienced_x_unemp_rate_employed", gc_coef(mE, "exper_u"))
out("experienced_x_unemp_rate_employed_se", gc_se(mE, "exper_u"))
out("young_x_unemp_rate_unemployed", gc_coef(mU, "young_u"))
out("young_x_unemp_rate_unemployed_se", gc_se(mU, "young_u"))
out("young_x_unemp_rate_nilf", gc_coef(mN, "young_u"))
out("young_x_unemp_rate_nilf_se", gc_se(mN, "young_u"))
if (!is.null(mW)) {
  out("wage_young_x_unemp_rate_all_hires", gc_coef(mW, "young_u"))
  out("wage_young_x_unemp_rate_all_hires_se", gc_se(mW, "young_u"))
  out("wage_experienced_x_unemp_rate_all_hires", gc_coef(mW, "exper_u"))
  out("wage_experienced_x_unemp_rate_all_hires_se", gc_se(mW, "exper_u"))
}
cat(sprintf("RESULT:n_obs_full_sample=%d\n", nobs(mB4)))