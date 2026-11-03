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
dt <- dt[!is.na(pemlr) & pemlr %in% 1:7 & !is.na(v2pemlr) & v2pemlr %in% 1:7 & !is.na(peage) & peage >= 16]
invisible(gc())
cat(sprintf("SAMPLE:main:civilian_over16=%d\n", nrow(dt)))
dt <- dt[!is.na(peeduca) & peeduca %in% 31:46]
cat(sprintf("SAMPLE:main:nonmissing_age_education=%d\n", nrow(dt)))
dt <- dt[!(v2hryear == 1995 & v2hrmonth %in% 5:8) & !(hryear == 1995 & hrmonth %in% 5:8)]
cat(sprintf("SAMPLE:main:exclude_may_aug_1995=%d\n", nrow(dt)))
dt <- dt[(v2hryear > 1994 | (v2hryear == 1994 & v2hrmonth >= 1)) &
         (v2hryear < 2016 | (v2hryear == 2016 & v2hrmonth <= 9))]
invisible(gc())
cat(sprintf("SAMPLE:main:jan1994_sep2016=%d\n", nrow(dt)))
cat("DEVIATION: no month-in-sample variable in the data; the 8-month MIS 4->5 break and Madrian-Lefgren matching are assumed already applied in the matched file.\n")

# ---------------------------------------------------------------- merge unemployment (join by reference, no copy)
un <- fread(f_unemp)
for (v in names(un)) if (!is.numeric(un[[v]])) set(un, j = v, value = suppressWarnings(as.numeric(un[[v]])))
if (max(un$v2unemp_smy, na.rm = TRUE) < 1) un[, v2unemp_smy := 100 * v2unemp_smy]
un <- unique(un, by = c("v2gestfips","v2hryear","v2hrmonth"))
dt[un, urate := i.v2unemp_smy, on = c("v2gestfips","v2hryear","v2hrmonth")]
rm(un)
dt <- dt[!is.na(urate)]
invisible(gc())
cat(sprintf("SAMPLE:main:merged_state_unemp=%d\n", nrow(dt)))

# ---------------------------------------------------------------- variables (by reference, memory-lean)
dt[, hired := 0]
dt[v2pemlr %in% 1:2 &
     !(v2peio1cow %in% c(6, 7)) &
     (!(pemlr %in% 1:2) | (v2puiodp1 %in% 2)), hired := 100]
dt[, c("v2puiodp1","v2peio1cow") := NULL]
dt[, c("hrmonth","hryear") := NULL]
invisible(gc())

edyrs <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)  # peeduca 31..46
dt[, young := as.numeric((peage - edyrs[peeduca - 30] - 6) <= 10)]
dt[, young_u := young * urate]
dt[, exper_u := (1 - young) * urate]

dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca %in% 40:42, 3L,
                    peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L, peeduca == 46, 7L)]
dt[, hisp := 0L]
if ("prhspnon" %in% names(dt)) dt[prhspnon %in% 1, hisp := 1L]
if ("pehspnon" %in% names(dt)) {
  if ("prhspnon" %in% names(dt)) {
    dt[!(prhspnon %in% 1:2) & pehspnon %in% 1, hisp := 1L]
  } else dt[pehspnon %in% 1, hisp := 1L]
}
dt[, white := as.integer(race %in% 1)]
dt[, demo := as.integer(pesex * 1000 + white * 100 + hisp * 10 + educ7)]
dropc <- intersect(c("prhspnon","pehspnon","race","white","hisp","educ7","peeduca","peage","pesex"), names(dt))
dt[, (dropc) := NULL]
invisible(gc())
setnames(dt, "v2gestfips", "state")
dt[, state := as.integer(state)]
dt[, my := as.integer(v2hryear * 100 + v2hrmonth)]

dt[, wt := {
  w1 <- pwsswgt; w1[is.na(w1) | w1 <= 0] <- NA
  w2 <- v2pwsswgt; w2[is.na(w2) | w2 <= 0] <- NA
  ifelse(is.na(w1), w2, ifelse(is.na(w2), w1, (w1 + w2) / 2))
}]
dt[, c("pwsswgt","v2pwsswgt") := NULL]
dt <- dt[is.finite(wt) & wt > 0 & !is.na(young)]
invisible(gc())
cat(sprintf("SAMPLE:main:positive_weight=%d\n", nrow(dt)))
cat("SAMPLE:main:paper_stated_N=16948516\n")

# ---------------------------------------------------------------- helper: store coef/se, drop model
res <- list()
keep <- function(m, tag, vars) {
  b <- coef(m); s <- sqrt(diag(vcov(m)))
  for (v in vars) {
    res[[paste0(tag, ":", v)]] <<- c(unname(b[v]), unname(s[v]))
  }
  invisible(NULL)
}
fit <- function(fml, data, subset = NULL) {
  if (is.null(subset)) {
    feols(fml, data = data, weights = ~wt, cluster = ~state, lean = TRUE, mem.clean = TRUE)
  } else {
    feols(fml, data = data, weights = ~wt, cluster = ~state, lean = TRUE, mem.clean = TRUE, subset = subset)
  }
}

# ---------------------------------------------------------------- Table 1 Panel A
m <- fit(hired ~ urate, dt)
cat(sprintf("SAMPLE:t1_panelA_col1:estimation=%d\n", nobs(m))); keep(m, "A1", "urate"); rm(m); invisible(gc())
m <- fit(hired ~ urate | state + demo + my, dt)
cat(sprintf("SAMPLE:t1_panelA_col4:estimation=%d\n", nobs(m))); keep(m, "A4", "urate"); rm(m); invisible(gc())

# ---------------------------------------------------------------- Table 1 Panel B
m <- fit(hired ~ young + young_u + exper_u, dt)
cat(sprintf("SAMPLE:t1_panelB_col1:estimation=%d\n", nobs(m))); keep(m, "B1", c("young_u","exper_u")); rm(m); invisible(gc())
m <- fit(hired ~ young + young_u + exper_u | state + demo + my, dt)
n_full <- nobs(m)
cat(sprintf("SAMPLE:t1_panelB_col4:estimation=%d\n", nobs(m))); keep(m, "B4", c("young_u","exper_u")); rm(m); invisible(gc())

# ---------------------------------------------------------------- Table 2 by origin (subset arg, no data copy)
run_origin <- function(codes, nm) {
  idx <- dt$pemlr %in% codes
  cat(sprintf("SAMPLE:t2_%s:loaded=%d\n", nm, nrow(dt)))
  cat(sprintf("SAMPLE:t2_%s:origin_status_t_minus_1=%d\n", nm, sum(idx)))
  m <- fit(hired ~ young + young_u + exper_u | state + demo + my, dt, subset = idx)
  cat(sprintf("SAMPLE:t2_%s:estimation=%d\n", nm, nobs(m)))
  keep(m, nm, c("young_u","exper_u")); rm(m); invisible(gc())
}
run_origin(1:2, "employed")
run_origin(3:4, "unemployed")
run_origin(5:7, "nilf")

# ---------------------------------------------------------------- Table 10 wages
wage_done <- FALSE
wage_ok <- all(c("v2prernwa","v2peio1ocd","v2peio1icd") %in% names(dt))
if (wage_ok) {
  cat(sprintf("SAMPLE:t10_wage:loaded=%d\n", nrow(dt)))
  wd <- dt[hired == 100]
  rm(dt); invisible(gc())
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

  map_codes <- function(wd, xw, codecol, yrcol, recol, breaks_mid, breaks_hi) {
    xw <- copy(xw)
    for (v in names(xw)) if (!is.numeric(xw[[v]])) set(xw, j = v, value = suppressWarnings(as.numeric(xw[[v]])))
    cy <- sort(unique(xw[[yrcol]]))
    yr <- wd$v2hryear
    if (length(cy) == 3) {
      sch <- ifelse(yr < breaks_mid, cy[1], ifelse(yr < breaks_hi, cy[2], cy[3]))
    } else {
      sch <- vapply(yr, function(y) { k <- cy[cy <= y]; if (length(k)) max(k) else min(cy) }, numeric(1))
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
  m <- fit(logw ~ young + young_u + exper_u | state + demo + my + occ + ind, wd)
  cat(sprintf("SAMPLE:t10_wage:estimation=%d\n", nobs(m)))
  keep(m, "W", c("young_u","exper_u")); rm(m)
  wage_done <- TRUE
} else {
  cat("DEVIATION: wage / occupation / industry columns missing; Table 10 not estimated.\n")
}

# ---------------------------------------------------------------- results
out <- function(nm, key, k) cat(sprintf("RESULT:%s=%.6g\n", nm, res[[key]][k]))
out("young_x_unemp_rate_no_controls", "B1:young_u", 1)
out("young_x_unemp_rate_no_controls_se", "B1:young_u", 2)
out("experienced_x_unemp_rate_no_controls", "B1:exper_u", 1)
out("experienced_x_unemp_rate_no_controls_se", "B1:exper_u", 2)
out("young_x_unemp_rate_preferred", "B4:young_u", 1)
out("young_x_unemp_rate_preferred_se", "B4:young_u", 2)
out("experienced_x_unemp_rate_preferred", "B4:exper_u", 1)
out("experienced_x_unemp_rate_preferred_se", "B4:exper_u", 2)
out("aggregate_unemp_rate_no_controls", "A1:urate", 1)
out("aggregate_unemp_rate_no_controls_se", "A1:urate", 2)
out("aggregate_unemp_rate_month_year_fe", "A4:urate", 1)
out("aggregate_unemp_rate_month_year_fe_se", "A4:urate", 2)
out("young_x_unemp_rate_employed", "employed:young_u", 1)
out("young_x_unemp_rate_employed_se", "employed:young_u", 2)
out("experienced_x_unemp_rate_employed", "employed:exper_u", 1)
out("experienced_x_unemp_rate_employed_se", "employed:exper_u", 2)
out("young_x_unemp_rate_unemployed", "unemployed:young_u", 1)
out("young_x_unemp_rate_unemployed_se", "unemployed:young_u", 2)
out("young_x_unemp_rate_nilf", "nilf:young_u", 1)
out("young_x_unemp_rate_nilf_se", "nilf:young_u", 2)
if (wage_done) {
  out("wage_young_x_unemp_rate_all_hires", "W:young_u", 1)
  out("wage_young_x_unemp_rate_all_hires_se", "W:young_u", 2)
  out("wage_experienced_x_unemp_rate_all_hires", "W:exper_u", 1)
  out("wage_experienced_x_unemp_rate_all_hires_se", "W:exper_u", 2)
}
cat(sprintf("RESULT:n_obs_full_sample=%d\n", n_full))