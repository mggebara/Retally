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

want <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon",
          "pemlr","pwsswgt","v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1",
          "v2peio1cow","v2peio1icd","v2peio1ocd","v2prernwa","v2pwsswgt","v2prwernal")
hdr <- names(fread(f_main, nrows = 0))
sel <- intersect(want, hdr)
dt <- fread(f_main, select = sel, showProgress = FALSE)
for (v in setdiff(want, names(dt))) dt[, (v) := NA]

numify <- function(x) suppressWarnings(as.numeric(x))
for (v in setdiff(want, "race")) {
  if (!is.numeric(dt[[v]])) dt[, (v) := numify(get(v))]
}

cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(dt)))

# Matched consecutive months, Jan 1994 - Sep 2016
dt[, t0 := hryear * 12 + hrmonth]
dt[, t1 := v2hryear * 12 + v2hrmonth]
dt <- dt[!is.na(t0) & !is.na(t1) & (t1 - t0) == 1]
cat(sprintf("SAMPLE:main:consecutive_month_match=%d\n", nrow(dt)))
dt <- dt[t0 >= 1994 * 12 + 1 & t1 <= 2016 * 12 + 9]
cat(sprintf("SAMPLE:main:jan1994_sep2016=%d\n", nrow(dt)))

# Civilians over 16 with non-missing age and education
dt[peage < 0, peage := NA]
dt[!(peeduca %in% 31:46), peeduca := NA]
dt <- dt[!is.na(peage) & peage >= 16]
cat(sprintf("SAMPLE:main:age_16_plus_nonmissing=%d\n", nrow(dt)))
dt <- dt[!is.na(peeduca)]
cat(sprintf("SAMPLE:main:nonmissing_education=%d\n", nrow(dt)))
# civilian: valid labor-force status codes both months (armed forces excluded from CPS LF universe)
dt <- dt[pemlr %in% 1:7 & v2pemlr %in% 1:7]
cat(sprintf("SAMPLE:main:civilian_valid_lf_status=%d\n", nrow(dt)))

# Exclude May-Aug 1995 (no longitudinal link)
bad95 <- (1995 * 12 + 5):(1995 * 12 + 8)
dt <- dt[!(t0 %in% bad95) & !(t1 %in% bad95)]
cat(sprintf("SAMPLE:main:exclude_may_aug_1995=%d\n", nrow(dt)))

# Weights
dt[, w := (pwsswgt + v2pwsswgt) / 2]
dt <- dt[!is.na(w) & w > 0]
cat(sprintf("SAMPLE:main:positive_weight=%d\n", nrow(dt)))

# State unemployment rate (month t)
un <- fread(f_unemp)
un <- un[, .(v2gestfips = as.numeric(v2gestfips), v2hryear = as.numeric(v2hryear),
             v2hrmonth = as.numeric(v2hrmonth), urate = as.numeric(v2unemp_smy))]
un <- unique(un, by = c("v2gestfips","v2hryear","v2hrmonth"))
dt <- merge(dt, un, by = c("v2gestfips","v2hryear","v2hrmonth"), all.x = FALSE)
cat(sprintf("SAMPLE:main:merge_state_unemp=%d\n", nrow(dt)))

# Education years and categories
edu_years <- c(`31`=0, `32`=2.5, `33`=5.5, `34`=7.5, `35`=9, `36`=10, `37`=11, `38`=12,
               `39`=12, `40`=13, `41`=14, `42`=14, `43`=16, `44`=18, `45`=20, `46`=20)
dt[, educyrs := edu_years[as.character(peeduca)]]
dt[, educ7 := fifelse(peeduca <= 38, 1L,
               fifelse(peeduca == 39, 2L,
               fifelse(peeduca <= 42, 3L,
               fifelse(peeduca == 43, 4L,
               fifelse(peeduca == 44, 5L,
               fifelse(peeduca == 45, 6L, 7L))))))]
dt[, pe := peage - educyrs - 6]
dt[, young := as.integer(pe <= 10)]

# Demographics
if (is.numeric(dt$race)) {
  dt[, white := as.integer(!is.na(race) & race == 1)]
} else {
  r <- tolower(trimws(as.character(dt$race)))
  dt[, white := as.integer(r %in% c("1","white","white only") | grepl("^white( only)?$", r))]
  rm(r)
}
dt[, hisp_raw := fifelse(!is.na(prhspnon) & prhspnon > 0, prhspnon, pehspnon)]
dt[, hisp := as.integer(!is.na(hisp_raw) & hisp_raw == 1)]
# integer-coded demographic cell (cheaper than a character key on ~14M rows)
dt[, demo := as.integer(pesex) * 1000L + white * 100L + hisp * 10L + educ7]
dt[, state := as.integer(v2gestfips)]
dt[, ym := as.integer(v2hryear * 100 + v2hrmonth)]

# Hiring indicator
dt[, emp0 := pemlr %in% 1:2]
dt[, emp1 := v2pemlr %in% 1:2]
dt[, selfemp1 := !is.na(v2peio1cow) & v2peio1cow %in% c(6, 7)]
dt[, newemp := !is.na(v2puiodp1) & v2puiodp1 == 2]
dt[, hired := 100 * as.integer(emp1 & !selfemp1 & ((!emp0) | (emp0 & newemp)))]
dt[, uy := young * urate]
dt[, ue := (1L - young) * urate]
dt[, status0 := fifelse(pemlr %in% 1:2, "E", fifelse(pemlr %in% 3:4, "U", "N"))]

cat(sprintf("SAMPLE:main:estimation_input=%d\n", nrow(dt)))
n_main <- nrow(dt)

# Split off the new-hire wage sample now, then slim the main table to save memory
wd <- dt[hired == 100, .(hired, young, uy, ue, urate, state, ym, demo, w,
                         v2hryear, v2hrmonth, v2prernwa, v2prwernal, v2peio1ocd, v2peio1icd)]
keep <- c("hired","urate","young","uy","ue","state","demo","ym","w","status0")
dt[, setdiff(names(dt), keep) := NULL]
invisible(gc())

# Fit, extract coefficients/SEs immediately, and free the model
fit <- function(fml, data, vars) {
  out <- tryCatch({
    m <- feols(fml, data = data, weights = ~w, cluster = ~state,
               lean = TRUE, mem.clean = TRUE, notes = FALSE)
    cf <- coef(m); s <- se(m)
    r <- list(coef = cf[vars], se = s[vars], n = nobs(m))
    rm(m)
    r
  }, error = function(e) {
    message("Estimation error: ", conditionMessage(e))
    list(coef = setNames(rep(NA_real_, length(vars)), vars),
         se = setNames(rep(NA_real_, length(vars)), vars), n = NA_integer_)
  })
  invisible(gc())
  out
}

# ---------------- Table 1 ----------------
mA1 <- fit(hired ~ urate, dt, "urate")
cat(sprintf("SAMPLE:t1_panelA_col1:loaded=%d\n", n_main))
cat(sprintf("SAMPLE:t1_panelA_col1:estimation=%d\n", as.integer(mA1$n)))

mA4 <- fit(hired ~ urate | state + demo + ym, dt, "urate")
cat(sprintf("SAMPLE:t1_panelA_col4:loaded=%d\n", n_main))
cat(sprintf("SAMPLE:t1_panelA_col4:estimation=%d\n", as.integer(mA4$n)))

mB1 <- fit(hired ~ young + uy + ue, dt, c("uy","ue"))
cat(sprintf("SAMPLE:t1_panelB_col1:loaded=%d\n", n_main))
cat(sprintf("SAMPLE:t1_panelB_col1:estimation=%d\n", as.integer(mB1$n)))

mB4 <- fit(hired ~ young + uy + ue | state + demo + ym, dt, c("uy","ue"))
cat(sprintf("SAMPLE:t1_panelB_col4:loaded=%d\n", n_main))
cat(sprintf("SAMPLE:t1_panelB_col4:estimation=%d\n", as.integer(mB4$n)))

# ---------------- Table 2 ----------------
run_sub <- function(s, nm) {
  d <- dt[status0 == s]
  cat(sprintf("SAMPLE:%s:loaded=%d\n", nm, n_main))
  cat(sprintf("SAMPLE:%s:status_t_minus_1=%d\n", nm, nrow(d)))
  m <- fit(hired ~ young + uy + ue | state + demo + ym, d, c("uy","ue"))
  cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, as.integer(m$n)))
  rm(d); invisible(gc())
  m
}
mE <- run_sub("E", "t2_employed")
mU <- run_sub("U", "t2_unemployed")
mN <- run_sub("N", "t2_nilf")

rm(dt); invisible(gc())

# ---------------- Table 10: wages of new hires ----------------
cpi <- fread(f_cpi)
cpi <- cpi[, .(v2hryear = as.numeric(year), v2hrmonth = as.numeric(month), cpi = as.numeric(cpi))]
cpi94 <- mean(cpi[v2hryear == 1994, cpi], na.rm = TRUE)

occ <- fread(f_occ, colClasses = "character")
ind <- fread(f_ind, colClasses = "character")

map_regime <- function(years, codeyears, starts) {
  cy <- sort(unique(as.numeric(codeyears)))
  cy <- cy[!is.na(cy)]
  if (length(cy) == length(starts)) {
    idx <- findInterval(years, starts)
    idx[idx < 1] <- 1
    return(cy[idx])
  }
  out <- sapply(years, function(y) { k <- cy[cy <= y]; if (length(k)) max(k) else min(cy) })
  out
}

cat(sprintf("SAMPLE:t10_all_hires:loaded=%d\n", n_main))
cat(sprintf("SAMPLE:t10_all_hires:new_hires=%d\n", nrow(wd)))
wd <- wd[!is.na(v2prernwa) & v2prernwa > 0]
cat(sprintf("SAMPLE:t10_all_hires:outgoing_rotation_wage_reported=%d\n", nrow(wd)))
wd <- wd[is.na(v2prwernal) | v2prwernal != 1]
cat(sprintf("SAMPLE:t10_all_hires:non_allocated_wage=%d\n", nrow(wd)))
wd <- merge(wd, cpi, by = c("v2hryear","v2hrmonth"))
wd[, lwage := log(v2prernwa / cpi * cpi94)]

uy_years <- sort(unique(wd$v2hryear))
occ_reg <- map_regime(uy_years, occ$v2occ_codeyear, c(1994, 2003, 2011))
ind_reg <- map_regime(uy_years, ind$v2ind_codeyear, c(1994, 2003, 2009, 2014))
wd[, occ_cy := occ_reg[match(v2hryear, uy_years)]]
wd[, ind_cy := ind_reg[match(v2hryear, uy_years)]]

occx <- unique(occ[, .(occ_cy = as.numeric(v2occ_codeyear), v2peio1ocd = as.numeric(v2peio1ocd),
                       occ02 = v2censusocc_2002recode)], by = c("occ_cy","v2peio1ocd"))
indx <- unique(ind[, .(ind_cy = as.numeric(v2ind_codeyear), v2peio1icd = as.numeric(v2peio1icd),
                       ind02 = v2censusind_2002recode)], by = c("ind_cy","v2peio1icd"))
wd <- merge(wd, occx, by = c("occ_cy","v2peio1ocd"), all.x = TRUE)
wd <- merge(wd, indx, by = c("ind_cy","v2peio1icd"), all.x = TRUE)
wd[is.na(occ02) | occ02 == "", occ02 := paste0("raw", occ_cy, "_", v2peio1ocd)]
wd[is.na(ind02) | ind02 == "", ind02 := paste0("raw", ind_cy, "_", v2peio1icd)]
wd <- wd[!is.na(v2peio1ocd) & !is.na(v2peio1icd) & v2peio1ocd >= 0 & v2peio1icd >= 0]
cat(sprintf("SAMPLE:t10_all_hires:valid_occ_ind=%d\n", nrow(wd)))

mW <- fit(lwage ~ young + uy + ue | state + ym + occ02 + ind02 + demo, wd, c("uy","ue"))
cat(sprintf("SAMPLE:t10_all_hires:estimation=%d\n", as.integer(mW$n)))

g  <- function(m, v) unname(m$coef[v])
sg <- function(m, v) unname(m$se[v])

res <- list(
  young_x_unemp_rate_no_controls = g(mB1, "uy"),
  experienced_x_unemp_rate_no_controls = g(mB1, "ue"),
  young_x_unemp_rate_preferred = g(mB4, "uy"),
  experienced_x_unemp_rate_preferred = g(mB4, "ue"),
  aggregate_unemp_rate_no_controls = g(mA1, "urate"),
  aggregate_unemp_rate_month_year_fe = g(mA4, "urate"),
  young_x_unemp_rate_employed = g(mE, "uy"),
  experienced_x_unemp_rate_employed = g(mE, "ue"),
  young_x_unemp_rate_unemployed = g(mU, "uy"),
  young_x_unemp_rate_nilf = g(mN, "uy"),
  wage_young_x_unemp_rate_all_hires = g(mW, "uy"),
  wage_experienced_x_unemp_rate_all_hires = g(mW, "ue"),
  n_obs_full_sample = mB4$n
)
ses <- list(
  young_x_unemp_rate_no_controls_se = sg(mB1, "uy"),
  experienced_x_unemp_rate_no_controls_se = sg(mB1, "ue"),
  young_x_unemp_rate_preferred_se = sg(mB4, "uy"),
  experienced_x_unemp_rate_preferred_se = sg(mB4, "ue"),
  aggregate_unemp_rate_no_controls_se = sg(mA1, "urate"),
  aggregate_unemp_rate_month_year_fe_se = sg(mA4, "urate"),
  young_x_unemp_rate_employed_se = sg(mE, "uy"),
  experienced_x_unemp_rate_employed_se = sg(mE, "ue"),
  young_x_unemp_rate_unemployed_se = sg(mU, "uy"),
  young_x_unemp_rate_nilf_se = sg(mN, "uy"),
  wage_young_x_unemp_rate_all_hires_se = sg(mW, "uy"),
  wage_experienced_x_unemp_rate_all_hires_se = sg(mW, "ue")
)
for (nm in names(res)) {
  val <- res[[nm]]
  if (is.null(val) || length(val) == 0 || is.na(val)) next
  if (nm == "n_obs_full_sample") cat(sprintf("RESULT:%s=%d\n", nm, as.integer(val)))
  else cat(sprintf("RESULT:%s=%.6f\n", nm, val))
}
for (nm in names(ses)) {
  val <- ses[[nm]]
  if (is.null(val) || length(val) == 0 || is.na(val)) next
  cat(sprintf("RESULT:%s=%.6f\n", nm, val))
}