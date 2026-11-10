suppressPackageStartupMessages({
  library(data.table)
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation.script-free/China_Pollution_Monitoring/Data"

rd_dta <- function(f) {
  d <- haven::read_dta(file.path(base, f))
  d <- haven::zap_labels(d)
  d <- as.data.frame(d)
  setDT(d)
  d
}

mkkey <- function(x) {
  if (is.numeric(x)) format(x, scientific = FALSE, trim = TRUE, digits = 15) else trimws(as.character(x))
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(as.Date(x))
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    med <- suppressWarnings(median(x, na.rm = TRUE))
    if (is.na(med)) return(as.Date(rep(NA_real_, length(x)), origin = "1970-01-01"))
    if (med > 19000000 && med < 21000000) return(as.Date(as.character(as.integer(x)), format = "%Y%m%d"))
    if (med > 1e10) return(as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC")))
    return(as.Date(x, origin = "1960-01-01"))
  }
  x <- as.character(x)
  out <- as.Date(x, format = "%Y-%m-%d")
  if (mean(is.na(out[!is.na(x)])) > 0.5) out <- as.Date(x, format = "%d%b%Y")
  if (mean(is.na(out[!is.na(x)])) > 0.5) out <- as.Date(x, format = "%Y%m%d")
  if (mean(is.na(out[!is.na(x)])) > 0.5) out <- as.Date(x, format = "%m/%d/%Y")
  out
}

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
    flush(stdout())
  }
}

safe <- function(expr, label) {
  tryCatch(expr, error = function(e) {
    message("ERROR in ", label, ": ", conditionMessage(e))
    NULL
  })
}

wvars_all <- c("temp", "rain", "rh", "wind_speed")

# ---------------- Station / city info ----------------
st <- rd_dta("station_list.dta")
st[, code_city := mkkey(code_city)]
st[, pm10_n := mkkey(pm10_n)]
st[, auto_date := to_date(auto_date)]
if (!is.numeric(st$phase)) st[, phase := as.numeric(gsub("\\D", "", as.character(phase)))]
st[, phase := as.numeric(phase)]

city <- st[, .(auto_date = suppressWarnings(min(auto_date, na.rm = TRUE)),
               phase = phase[!is.na(phase)][1]), by = code_city]
city <- city[is.finite(as.numeric(auto_date)) & phase %in% c(1, 2)]
city[, deadline := as.integer((phase == 1 & auto_date == as.Date("2013-01-01")) |
                              (phase == 2 & auto_date == as.Date("2014-01-01")))]
city[, auto_mi := as.integer(format(auto_date, "%Y")) * 12L + as.integer(format(auto_date, "%m"))]
message("Cities: ", nrow(city), "; deadline cities: ", sum(city$deadline))

# ---------------- Pollution + weather (daily) ----------------
pol <- rd_dta("pollution_1116.dta")
pol[, station_n := mkkey(station_n)]
pol[, code_city := mkkey(code_city)]
pol[, date := to_date(date)]
pol <- pol[, .(station_n, code_city, date, pm10 = as.numeric(pm10))]

wea <- rd_dta("weather_1116.dta")
wea[, station_n := mkkey(station_n)]
wea[, date := to_date(date)]
for (v in wvars_all) if (v %in% names(wea)) set(wea, j = v, value = as.numeric(wea[[v]]))
wea <- wea[, c("station_n", "date", intersect(wvars_all, names(wea))), with = FALSE]
wea <- unique(wea, by = c("station_n", "date"))

stmap <- unique(pol[, .(station_n, code_city)], by = "station_n")

dat <- merge(pol, wea, by = c("station_n", "date"), all.x = TRUE)
dat <- merge(dat, city[, .(code_city, auto_date, phase, deadline, auto_mi)], by = "code_city")
dat[, year := as.integer(format(date, "%Y"))]
dat[, month := as.integer(format(date, "%m"))]
dat <- dat[year >= 2011 & year <= 2016]
dat[, days := as.numeric(date - auto_date)]
dat[, moy := month]
dat[, ym := year * 100L + month]
dat[, city_id := as.integer(factor(code_city))]
message("Daily obs with PM10: ", sum(!is.na(dat$pm10)))

wv <- intersect(wvars_all, names(dat))

run_rd <- function(y, x, cl) {
  ok <- is.finite(y) & is.finite(x) & !is.na(cl)
  fit <- rdrobust(y[ok], x[ok], c = 0, kernel = "triangular", bwselect = "mserd",
                  cluster = as.integer(factor(cl[ok])), masspoints = "off")
  message("RD: coef=", round(fit$coef[1, 1], 4), " se=", round(fit$se[1, 1], 4),
          " h=", round(fit$bws[1, 1], 3), " N=", sum(fit$N_h))
  fit$coef[1, 1]
}

residualize <- function(d, y, fe, wvars) {
  wvars <- wvars[sapply(wvars, function(v) v %in% names(d) && mean(!is.na(d[[v]])) > 0.3)]
  cols <- unique(c(y, fe, wvars))
  ok <- complete.cases(d[, cols, with = FALSE]) & is.finite(d[[y]])
  dd <- d[ok]
  rhs <- if (length(wvars) > 0) paste(wvars, collapse = " + ") else "1"
  f <- as.formula(paste(y, "~", rhs, "|", paste(fe, collapse = " + ")))
  m <- feols(f, data = dd)
  r <- rep(NA_real_, nrow(dd))
  r[obs(m)] <- resid(m)
  dd[, res__ := r]
  dd[!is.na(res__)]
}

# ---------------- Table 1 Panel A col 1: no controls ----------------
safe({
  d1 <- dat[!is.na(pm10) & !is.na(days)]
  emit("rd_pm_daily_no_controls_table1_panelA_col1", run_rd(d1$pm10, d1$days, d1$code_city))
  rm(d1); gc()
}, "col1")

# ---------------- Cols 2-5: residualized ----------------
dres <- safe(residualize(dat[!is.na(pm10) & !is.na(days)], "pm10", c("station_n", "moy"), wv), "residualize")
if (!is.null(dres)) {
  safe(emit("rd_pm_daily_controls_table1_panelA_col2",
            run_rd(dres$res__, dres$days, dres$code_city)), "col2")
  safe({ s <- dres[phase == 1]
    emit("rd_pm_daily_wave1_table1_panelA_col3", run_rd(s$res__, s$days, s$code_city)) }, "col3")
  safe({ s <- dres[phase == 2]
    emit("rd_pm_daily_wave2_table1_panelA_col4", run_rd(s$res__, s$days, s$code_city)) }, "col4")
  safe({ s <- dres[deadline == 1]
    emit("rd_pm_daily_deadline_table1_panelA_col5", run_rd(s$res__, s$days, s$code_city)) }, "col5")
  rm(dres); gc()
}

# ---------------- Monthly weather aggregates ----------------
wea[, year := as.integer(format(date, "%Y"))]
wea[, month := as.integer(format(date, "%m"))]
wea_st_m <- wea[, lapply(.SD, function(z) mean(z, na.rm = TRUE)), by = .(station_n, year, month), .SDcols = wv]
wea_city_m <- merge(wea, stmap, by = "station_n")[
  , lapply(.SD, function(z) mean(z, na.rm = TRUE)), by = .(code_city, year, month), .SDcols = wv]
for (v in wv) {
  set(wea_st_m, which(is.nan(wea_st_m[[v]])), v, NA_real_)
  set(wea_city_m, which(is.nan(wea_city_m[[v]])), v, NA_real_)
}

# ---------------- AOD RD (monthly, station level) ----------------
safe({
  aod <- rd_dta("aod_month.dta")
  aod[, pm10_n := mkkey(pm10_n)]
  aod[, year := as.integer(year)]
  aod[, month := as.integer(month)]
  aod[, aod := as.numeric(aod)]
  aod <- merge(aod, unique(st[, .(pm10_n, code_city)], by = "pm10_n"), by = "pm10_n")
  aod <- merge(aod, city[, .(code_city, auto_mi, phase)], by = "code_city")
  aod <- aod[year >= 2011 & year <= 2016]
  overlap <- mean(unique(aod$pm10_n) %in% unique(wea_st_m$station_n))
  if (overlap > 0.8) {
    w <- copy(wea_st_m); setnames(w, "station_n", "pm10_n")
    aod <- merge(aod, w, by = c("pm10_n", "year", "month"), all.x = TRUE)
  } else {
    aod <- merge(aod, wea_city_m, by = c("code_city", "year", "month"), all.x = TRUE)
  }
  aod[, rel := (year * 12L + month) - auto_mi]
  aod[, moy := month]
  ar <- residualize(aod[!is.na(aod)], "aod", c("pm10_n", "moy"), wv)
  emit("rd_aod_monthly_controls_table1_panelA_col2", run_rd(ar$res__, ar$rel, ar$code_city))
}, "aod")

# ---------------- Event study (Panel B) ----------------
safe({
  # Deadline status defined at the STATION level (paper: Wave-1 deadline stations treated,
  # Wave-2 deadline stations as controls); station automation date falls back to city date.
  stdl <- unique(st[!is.na(pm10_n) & pm10_n != "", .(station_n = pm10_n, st_auto = auto_date, st_phase = phase)],
                 by = "station_n")
  es0 <- dat[date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31") & !is.na(pm10)]
  ovs <- mean(unique(es0$station_n) %in% stdl$station_n)
  message("Station-list overlap with pollution stations: ", round(ovs, 3))
  if (ovs > 0.8) {
    es0 <- merge(es0, stdl, by = "station_n", all.x = TRUE)
    es0[is.na(st_auto), st_auto := auto_date]
    es0[is.na(st_phase), st_phase := phase]
    es0[, st_deadline := as.integer((st_phase == 1 & st_auto == as.Date("2013-01-01")) |
                                    (st_phase == 2 & st_auto == as.Date("2014-01-01")))]
    es <- es0[st_deadline == 1 & st_phase %in% c(1, 2)]
    es[, treated := as.integer(st_phase == 1)]
  } else {
    es <- es0[deadline == 1]
    es[, treated := as.integer(phase == 1)]
  }
  rm(es0)
  message("ES stations treated: ", uniqueN(es[treated == 1]$station_n),
          "; control: ", uniqueN(es[treated == 0]$station_n), "; obs: ", nrow(es))
  es[, relm := (year - 2013L) * 12L + (month - 1L)]
  es[, b712 := treated * as.integer(relm >= -12 & relm <= -7)]
  es[, b56  := treated * as.integer(relm >= -6 & relm <= -5)]
  es[, b34  := treated * as.integer(relm >= -4 & relm <= -3)]
  es[, a12  := treated * as.integer(relm >= 0 & relm <= 1)]
  es[, a34  := treated * as.integer(relm >= 2 & relm <= 3)]
  es[, a56  := treated * as.integer(relm >= 4 & relm <= 5)]
  es[, a712 := treated * as.integer(relm >= 6 & relm <= 11)]
  es[, lpm := ifelse(pm10 > 0, log(pm10), NA_real_)]
  wvx <- wv[sapply(wv, function(v) mean(!is.na(es[[v]])) > 0.3)]
  per <- "b712 + b56 + b34 + a12 + a34 + a56 + a712"
  rhs <- paste(c(per, wvx), collapse = " + ")

  m1 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = es, cluster = ~code_city)
  emit("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1", coef(m1)["a12"])
  emit("n_obs_table1_panelB_deadline_cols1_2", nobs(m1))

  m2 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = es, cluster = ~code_city)
  emit("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2", coef(m2)["a12"])

  # Matching: each Wave-1 deadline station to nearest Wave-2 deadline station, with replacement
  hav <- function(lon1, lat1, lon2, lat2) {
    rad <- pi / 180
    dlat <- (lat2 - lat1) * rad; dlon <- (lon2 - lon1) * rad
    a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
    2 * 6371 * asin(pmin(1, sqrt(a)))
  }
  stc <- merge(st[, .(pm10_n, code_city, lon = as.numeric(station_lon), lat = as.numeric(station_lat))],
               city[, .(code_city, phase, deadline)], by = "code_city")
  stc <- unique(stc[is.finite(lon) & is.finite(lat)], by = "pm10_n")
  es_st <- unique(es$station_n)
  overlap <- mean(es_st %in% stc$pm10_n)
  if (overlap > 0.8) {
    tr <- stc[pm10_n %in% unique(es[treated == 1]$station_n)]
    co <- stc[pm10_n %in% unique(es[treated == 0]$station_n)]
    match_to <- sapply(seq_len(nrow(tr)), function(i) co$pm10_n[which.min(hav(tr$lon[i], tr$lat[i], co$lon, co$lat))])
    cnt <- as.data.table(table(match_to)); setnames(cnt, c("station_n", "w"))
    cnt[, w := as.numeric(w)]
    esm <- es[treated == 1 | station_n %in% cnt$station_n]
    esm <- merge(esm, cnt, by = "station_n", all.x = TRUE)
    esm[treated == 1, w := 1]
  } else {
    cc <- stc[, .(lon = mean(lon), lat = mean(lat), phase = phase[1]), by = code_city]
    trs <- unique(es[treated == 1, .(station_n, code_city)])
    trs <- merge(trs, cc[, .(code_city, lon, lat)], by = "code_city")
    co <- cc[code_city %in% es[treated == 0]$code_city]
    trs[, mcity := sapply(seq_len(.N), function(i) co$code_city[which.min(hav(lon[i], lat[i], co$lon, co$lat))])]
    cnt <- trs[, .(w = as.numeric(.N)), by = .(code_city = mcity)]
    nst <- es[treated == 0, .(ns = uniqueN(station_n)), by = code_city]
    cnt <- merge(cnt, nst, by = "code_city"); cnt[, w := w / ns]
    esm <- es[treated == 1 | code_city %in% cnt$code_city]
    esm <- merge(esm, cnt[, .(code_city, w)], by = "code_city", all.x = TRUE)
    esm[treated == 1, w := 1]
  }
  m3 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = esm, weights = ~w, cluster = ~code_city)
  emit("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3", coef(m3)["a12"])
  m5 <- feols(as.formula(paste("lpm ~", rhs, "| station_n + ym")), data = esm, weights = ~w, cluster = ~code_city)
  emit("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5", coef(m5)["a12"])
}, "event_study")

rm(dat, pol); gc()

# ---------------- Baidu search RD (monthly, city level) ----------------
safe({
  ms <- rd_dta("mask_filter_search.dta")
  ms[, code_city := mkkey(code_city)]
  ms[, date := to_date(date)]
  ms[, year := as.integer(format(date, "%Y"))]
  ms[, month := as.integer(format(date, "%m"))]
  ms[, pmmask := as.numeric(pmmask)]
  ms[, filter := as.numeric(filter)]
  ms <- ms[year >= 2011 & year <= 2016 & code_city %in% city$code_city]
  mm <- ms[, .(mask = mean(pmmask, na.rm = TRUE), filt = mean(filter, na.rm = TRUE)),
           by = .(code_city, year, month)]
  mm[is.nan(mask), mask := NA_real_]
  mm[is.nan(filt), filt := NA_real_]
  mm <- merge(mm, city[, .(code_city, auto_mi)], by = "code_city")
  mm <- merge(mm, wea_city_m, by = c("code_city", "year", "month"), all.x = TRUE)
  mm[, rel := (year * 12L + month) - auto_mi]
  mm[, moy := month]
  safe({
    r <- residualize(mm[!is.na(mask)], "mask", c("code_city", "moy"), wv)
    emit("rd_face_mask_searches_controls_table2_panelA_col2", run_rd(r$res__, r$rel, r$code_city))
  }, "mask")
  safe({
    r <- residualize(mm[!is.na(filt)], "filt", c("code_city", "moy"), wv)
    emit("rd_air_filter_searches_controls_table2_panelA_col2", run_rd(r$res__, r$rel, r$code_city))
  }, "filter")
}, "search")