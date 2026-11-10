suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation.script-free/China_Pollution_Monitoring/Data"

rd_read <- function(f) {
  d <- haven::read_dta(file.path(base, f))
  d <- haven::zap_labels(haven::zap_formats(d))
  as.data.table(d)
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    med <- median(x, na.rm = TRUE)
    if (is.finite(med) && med > 1e7) return(as.Date(as.character(as.integer(x)), "%Y%m%d"))
    if (is.finite(med) && med > 1e9) return(as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC")))
    return(as.Date(x, origin = "1960-01-01"))
  }
  as.Date(lubridate::parse_date_time(as.character(x), c("Ymd", "dmY", "mdY", "dbY")))
}

results <- list()
setres <- function(name, val) {
  results[[name]] <<- if (is.null(val) || length(val) == 0) NA_real_ else as.numeric(val)[1]
}

wvars <- c("temp", "rh", "rain", "wind_speed")

rd_est <- function(y, x, cl, label = "") {
  ok <- is.finite(y) & is.finite(x) & !is.na(cl)
  r <- rdrobust(y = y[ok], x = x[ok], c = 0, kernel = "triangular", p = 1,
                bwselect = "mserd", vce = "hc1", cluster = cl[ok])
  cat(sprintf("[%s] N=%d  h=%.3f  coef=%.4f  se=%.4f\n", label, sum(ok),
              r$bws[1, 1], r$coef[1], r$se[1]))
  r$coef[1]
}

resid_fe <- function(d, yvar, fe) {
  keep <- complete.cases(d[, c(yvar, wvars), with = FALSE])
  d <- d[keep]
  fml <- as.formula(paste(yvar, "~", paste(wvars, collapse = " + "), "|", fe))
  m <- feols(fml, data = d, warn = FALSE, notes = FALSE)
  idx <- obs(m)
  d <- d[idx]
  d[, res := as.numeric(resid(m))]
  d
}

# ---------------- Station list / city automation dates ----------------
st <- rd_read("station_list.dta")
if ("pm10_n" %in% names(st)) setnames(st, "pm10_n", "station_n")
st[, auto_date := to_date(auto_date)]
st[, phase := as.numeric(phase)]
phases <- sort(unique(st$phase))
st[, wave := ifelse(phase == phases[1], 1L, 2L)]
d13 <- as.Date("2013-01-01"); d14 <- as.Date("2014-01-01")
st[, deadline := (wave == 1L & auto_date == d13) | (wave == 2L & auto_date == d14)]
if (sum(st$deadline, na.rm = TRUE) == 0) st[, deadline := auto_date %in% c(d13, d14)]

city <- st[, .(auto_date = min(auto_date, na.rm = TRUE), wave = wave[1],
               deadline = deadline[1]), by = code_city]
cat("Cities:", nrow(city), " wave1:", sum(city$wave == 1), " deadline:", sum(city$deadline), "\n")

# ---------------- Daily pollution + weather ----------------
pol <- rd_read("pollution_1116.dta")
pol[, date := to_date(date)]
pol[, pm10 := as.numeric(pm10)]
pol <- pol[, .(station_n, code_city, date, pm10)]

wea <- rd_read("weather_1116.dta")
wea[, date := to_date(date)]
wea <- wea[, c("station_n", "date", wvars), with = FALSE]

pol <- merge(pol, wea, by = c("station_n", "date"), all.x = TRUE)
pol <- merge(pol, city, by = "code_city", all.x = FALSE)
pol[, run := as.numeric(date - auto_date)]
pol[, month := as.integer(format(date, "%m"))]
pol[, year := as.integer(format(date, "%Y"))]
pol[, ym := year * 100L + month]

dpm <- pol[!is.na(pm10) & !is.na(run)]
cat("Daily PM10 obs:", nrow(dpm), "\n")

# Col 1: no controls
setres("rd_pm_daily_no_controls_table1_panelA_col1",
       tryCatch(rd_est(dpm$pm10, dpm$run, dpm$code_city, "col1"), error = function(e) {message(e$message); NA}))

# Col 2-5: residualized on station FE, month FE, weather
run_resid_rd <- function(d, label) {
  tryCatch({
    r <- resid_fe(d, "pm10", "station_n + month")
    rd_est(r$res, r$run, r$code_city, label)
  }, error = function(e) {message(label, ": ", e$message); NA})
}
setres("rd_pm_daily_controls_table1_panelA_col2", run_resid_rd(dpm, "col2"))
setres("rd_pm_daily_wave1_table1_panelA_col3", run_resid_rd(dpm[wave == 1L], "col3"))
setres("rd_pm_daily_wave2_table1_panelA_col4", run_resid_rd(dpm[wave == 2L], "col4"))
setres("rd_pm_daily_deadline_table1_panelA_col5", run_resid_rd(dpm[deadline == TRUE], "col5"))
rm(dpm); gc()

# ---------------- Monthly station weather ----------------
wea[, year := as.integer(format(date, "%Y"))]
wea[, month := as.integer(format(date, "%m"))]
wm <- wea[, lapply(.SD, function(v) mean(v, na.rm = TRUE)), by = .(station_n, year, month), .SDcols = wvars]
for (v in wvars) set(wm, which(is.nan(wm[[v]])), v, NA_real_)
rm(wea); gc()

# ---------------- AOD RD ----------------
setres("rd_aod_monthly_controls_table1_panelA_col2", tryCatch({
  aod <- rd_read("aod_month.dta")
  if ("pm10_n" %in% names(aod)) setnames(aod, "pm10_n", "station_n")
  aod[, `:=`(year = as.integer(year), month = as.integer(month), aod = as.numeric(aod))]
  aod <- merge(aod, st[, .(station_n, code_city, auto_date)], by = "station_n")
  aod[, run := (year * 12 + month) - (as.integer(format(auto_date, "%Y")) * 12 + as.integer(format(auto_date, "%m")))]
  aod <- merge(aod, wm, by = c("station_n", "year", "month"), all.x = TRUE)
  aod <- aod[!is.na(aod) & !is.na(run)]
  r <- resid_fe(aod, "aod", "station_n + month")
  rd_est(r$res, r$run, r$code_city, "aod col2")
}, error = function(e) {message("aod: ", e$message); NA}))

# ---------------- Event study (Panel B) ----------------
es <- pol[deadline == TRUE & date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31") & !is.na(pm10)]
rm(pol); gc()
es[, treat := as.integer(wave == 1L)]
es[, m := (year - 2013L) * 12L + month - 1L]
es[, `:=`(
  b7_12 = treat * as.integer(m >= -12 & m <= -7),
  b5_6  = treat * as.integer(m >= -6 & m <= -5),
  b3_4  = treat * as.integer(m >= -4 & m <= -3),
  a1_2  = treat * as.integer(m >= 0 & m <= 1),
  a3_4  = treat * as.integer(m >= 2 & m <= 3),
  a5_6  = treat * as.integer(m >= 4 & m <= 5),
  a7_12 = treat * as.integer(m >= 6 & m <= 11)
)]
es[, lpm10 := ifelse(pm10 > 0, log(pm10), NA_real_)]
rhs <- paste(c("b7_12", "b5_6", "b3_4", "a1_2", "a3_4", "a5_6", "a7_12", wvars), collapse = " + ")

es1 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + month")), data = es,
                      cluster = ~code_city), error = function(e) {message(e$message); NULL})
es2 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = es,
                      cluster = ~code_city), error = function(e) {message(e$message); NULL})
setres("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1",
       if (!is.null(es1)) coef(es1)["a1_2"] else NA)
setres("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2",
       if (!is.null(es2)) coef(es2)["a1_2"] else NA)
setres("n_obs_table1_panelB_deadline_cols1_2", if (!is.null(es1)) nobs(es1) else NA)

# Matched sample: nearest Wave-2 deadline station for each Wave-1 deadline station (with replacement)
hav <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  dlat <- (lat2 - lat1) * rad; dlon <- (lon2 - lon1) * rad
  a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(a)))
}
es_st <- unique(es$station_n)
tr_st <- st[deadline == TRUE & wave == 1L & station_n %in% es_st & !is.na(station_lon)]
co_st <- st[deadline == TRUE & wave == 2L & station_n %in% es_st & !is.na(station_lon)]
pairs <- rbindlist(lapply(seq_len(nrow(tr_st)), function(i) {
  dd <- hav(tr_st$station_lon[i], tr_st$station_lat[i], co_st$station_lon, co_st$station_lat)
  data.table(pair = i, tr = tr_st$station_n[i], co = co_st$station_n[which.min(dd)])
}))
cat("Matched pairs:", nrow(pairs), " unique controls:", length(unique(pairs$co)), "\n")
setkey(es, station_n)
msamp <- rbindlist(list(
  es[J(pairs$tr), nomatch = 0L, allow.cartesian = TRUE][, pair := pairs$pair[match(station_n, pairs$tr)]],
  rbindlist(lapply(seq_len(nrow(pairs)), function(i) {
    x <- es[J(pairs$co[i]), nomatch = 0L]; x[, pair := pairs$pair[i]]; x
  }))
), use.names = TRUE)

es3 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + month")), data = msamp,
                      cluster = ~code_city), error = function(e) {message(e$message); NULL})
es5 <- tryCatch(feols(as.formula(paste("lpm10 ~", rhs, "| station_n + ym")), data = msamp,
                      cluster = ~code_city), error = function(e) {message(e$message); NULL})
setres("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3",
       if (!is.null(es3)) coef(es3)["a1_2"] else NA)
setres("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5",
       if (!is.null(es5)) coef(es5)["a1_2"] else NA)
rm(es, msamp); gc()

# ---------------- Search RDs (Baidu masks / filters) ----------------
srch_res <- tryCatch({
  s <- rd_read("mask_filter_search.dta")
  s[, date := to_date(date)]
  s[, `:=`(year = as.integer(format(date, "%Y")), month = as.integer(format(date, "%m")))]
  s[, `:=`(pmmask = as.numeric(pmmask), filter = as.numeric(filter))]
  sm <- s[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)),
          by = .(code_city, year, month)]
  for (v in c("mask", "filter")) set(sm, which(is.nan(sm[[v]])), v, NA_real_)
  wcm <- merge(wm, st[, .(station_n, code_city)], by = "station_n")
  wcm <- wcm[, lapply(.SD, function(v) mean(v, na.rm = TRUE)), by = .(code_city, year, month), .SDcols = wvars]
  for (v in wvars) set(wcm, which(is.nan(wcm[[v]])), v, NA_real_)
  sm <- merge(sm, wcm, by = c("code_city", "year", "month"), all.x = TRUE)
  sm <- merge(sm, city[, .(code_city, auto_date)], by = "code_city")
  sm[, run := (year * 12 + month) - (as.integer(format(auto_date, "%Y")) * 12 + as.integer(format(auto_date, "%m")))]
  out <- list()
  rm1 <- resid_fe(sm[!is.na(mask)], "mask", "code_city + month")
  out$mask <- rd_est(rm1$res, rm1$run, rm1$code_city, "mask col2")
  rf1 <- resid_fe(sm[!is.na(filter)], "filter", "code_city + month")
  out$filter <- rd_est(rf1$res, rf1$run, rf1$code_city, "filter col2")
  out
}, error = function(e) {message("search: ", e$message); list(mask = NA, filter = NA)})
setres("rd_face_mask_searches_controls_table2_panelA_col2", srch_res$mask)
setres("rd_air_filter_searches_controls_table2_panelA_col2", srch_res$filter)

# ---------------- Output ----------------
nms <- c("rd_pm_daily_no_controls_table1_panelA_col1",
         "rd_pm_daily_controls_table1_panelA_col2",
         "rd_pm_daily_wave1_table1_panelA_col3",
         "rd_pm_daily_wave2_table1_panelA_col4",
         "rd_pm_daily_deadline_table1_panelA_col5",
         "rd_aod_monthly_controls_table1_panelA_col2",
         "event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1",
         "event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2",
         "event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3",
         "event_study_log_pm_1_2_months_after_matched_table1_panelB_col5",
         "n_obs_table1_panelB_deadline_cols1_2",
         "rd_face_mask_searches_controls_table2_panelA_col2",
         "rd_air_filter_searches_controls_table2_panelA_col2")
for (n in nms) {
  v <- results[[n]]
  if (is.null(v)) v <- NA_real_
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
}
