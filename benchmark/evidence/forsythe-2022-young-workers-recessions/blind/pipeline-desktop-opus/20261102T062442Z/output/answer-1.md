suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_notes(FALSE)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_ur   <- file.path(base, "v2unemp_smy.csv")
f_cpi  <- file.path(base, "wage_deflation_1994_2016.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")

res <- list(
  young_x_unemp_rate_no_controls = NA_real_,
  experienced_x_unemp_rate_no_controls = NA_real_,
  young_x_unemp_rate_preferred = NA_real_,
  experienced_x_unemp_rate_preferred = NA_real_,
  aggregate_unemp_rate_no_controls = NA_real_,
  aggregate_unemp_rate_month_year_fe = NA_real_,
  young_x_unemp_rate_employed = NA_real_,
  experienced_x_unemp_rate_employed = NA_real_,
  young_x_unemp_rate_unemployed = NA_real_,
  young_x_unemp_rate_nilf = NA_real_,
  wage_young_x_unemp_rate_all_hires = NA_real_,
  wage_experienced_x_unemp_rate_all_hires = NA_real_,
  n_obs_full_sample = NA_real_
)

emit <- function() {
  for (nm in names(res)) {
    v <- res[[nm]]
    cat(sprintf("RESULT:%s=%s\n", nm,
                ifelse(is.na(v), "NA", format(v, digits = 10, scientific = FALSE))))
  }
}

hdr_raw <- names(fread(f_main, nrows = 0))
hdr <- tolower(hdr_raw)
cat("Columns:", paste(hdr, collapse = ","), "\n")

find_col <- function(cands) {
  for (cn in cands) if (cn %in% hdr) return(cn)
  NA_character_
}

need <- c("hrmonth", "hryear", "peage", "pesex", "peeduca", "race", "prhspnon",
          "pemlr", "pwsswgt", "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr",
          "v2puiodp1", "v2peio1cow", "v2peio1icd", "v2peio1ocd")
opt <- c("v2pwsswgt", "v2unemp_smy", "gestfips", "hrmis", "v2hrmis", "v2peage")

# wage and allocation columns
wage_col <- find_col(c("v2prernwa", "v2pternwa", "v2earnwke", "prernwa"))
if (is.na(wage_col)) {
  cand <- hdr[grepl("ernwa|earnwk", hdr)]
  if (length(cand)) wage_col <- cand[1]
}
alloc_col <- find_col(c("v2prwernal", "v2pxernwa", "prwernal", "v2pxernwk"))
if (is.na(alloc_col)) {
  cand <- hdr[grepl("wernal|xernwa|alloc", hdr)]
  if (length(cand)) alloc_col <- cand[1]
}
cat("wage col:", wage_col, " alloc col:", alloc_col, "\n")

sel <- intersect(c(need, opt, wage_col, alloc_col), hdr)
sel <- sel[!is.na(sel)]
sel_raw <- hdr_raw[match(sel, hdr)]

dt <- fread(f_main, select = sel_raw, showProgress = FALSE)
setnames(dt, tolower(names(dt)))
cat("Raw rows:", nrow(dt), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
for (cn in names(dt)) if (!is.numeric(dt[[cn]])) set(dt, j = cn, value = num(dt[[cn]]))

# ---------------- sample restrictions ----------------
dt[, t1 := hryear * 12 + hrmonth]
dt[, t2 := v2hryear * 12 + v2hrmonth]
dt <- dt[!is.na(t1) & !is.na(t2) & (t2 - t1) == 1]
dt <- dt[v2hryear * 100 + v2hrmonth >= 199402 & v2hryear * 100 + v2hrmonth <= 201609]
# drop months without longitudinal link (May-Aug 1995)
dt <- dt[!(hryear == 1995 & hrmonth %in% 5:8) & !(v2hryear == 1995 & v2hrmonth %in% 5:8)]
# civilians, valid labor-force status both months
dt <- dt[pemlr %in% 1:7 & v2pemlr %in% 1:7]
dt <- dt[!is.na(peage) & peage >= 16]
dt <- dt[!is.na(peeduca) & peeduca >= 31 & peeduca <= 46]
cat("Rows after restrictions:", nrow(dt), "\n")

# ---------------- variables ----------------
educ_years <- c(`31` = 0, `32` = 2.5, `33` = 5.5, `34` = 7.5, `35` = 9, `36` = 10,
                `37` = 11, `38` = 12, `39` = 12, `40` = 13, `41` = 14, `42` = 14,
                `43` = 16, `44` = 18, `45` = 20, `46` = 20)
dt[, yrs := educ_years[as.character(peeduca)]]
dt[, pe := peage - yrs - 6]
dt[, young := as.integer(pe <= 10)]
dt[, educ7 := fifelse(peeduca <= 38, 1L,
               fifelse(peeduca == 39, 2L,
               fifelse(peeduca <= 42, 3L,
               fifelse(peeduca == 43, 4L,
               fifelse(peeduca == 44, 5L,
               fifelse(peeduca == 45, 6L, 7L))))))]
dt[, white := as.integer(!is.na(race) & race == 1)]
dt[, hisp := as.integer(!is.na(prhspnon) & prhspnon == 1)]
dt[, demo := (pesex * 1000L + white * 100L + hisp * 10L + educ7)]

if ("v2pwsswgt" %in% names(dt)) {
  dt[, w := fifelse(!is.na(v2pwsswgt) & v2pwsswgt > 0 & !is.na(pwsswgt) & pwsswgt > 0,
                    (pwsswgt + v2pwsswgt) / 2,
                    fifelse(!is.na(pwsswgt) & pwsswgt > 0, pwsswgt, v2pwsswgt))]
} else {
  dt[, w := pwsswgt]
}
dt <- dt[!is.na(w) & w > 0]

emp_prev <- dt$pemlr %in% 1:2
emp_now  <- dt$v2pemlr %in% 1:2
selfemp  <- !is.na(dt$v2peio1cow) & dt$v2peio1cow %in% c(6, 7)
switched <- !is.na(dt$v2puiodp1) & dt$v2puiodp1 == 2
dt[, hired := 100 * as.integer(((!emp_prev & emp_now) | (emp_prev & emp_now & switched)) & !selfemp)]
dt[, origin := fifelse(pemlr %in% 1:2, "E", fifelse(pemlr %in% 3:4, "U", "N"))]

# state unemployment rate (month t)
if (!("v2unemp_smy" %in% names(dt))) {
  ur <- fread(f_ur)
  setnames(ur, tolower(names(ur)))
  for (cn in names(ur)) set(ur, j = cn, value = num(ur[[cn]]))
  ur <- unique(ur, by = c("v2gestfips", "v2hryear", "v2hrmonth"))
  dt <- merge(dt, ur[, .(v2gestfips, v2hryear, v2hrmonth, v2unemp_smy)],
              by = c("v2gestfips", "v2hryear", "v2hrmonth"), all.x = TRUE)
}
dt[, urate := v2unemp_smy]
if (max(dt$urate, na.rm = TRUE) < 1) dt[, urate := urate * 100]
dt <- dt[!is.na(urate) & !is.na(v2gestfips)]
dt[, state := v2gestfips]
dt[, ym := v2hryear * 100L + v2hrmonth]
dt[, ur_y := urate * young]
dt[, ur_e := urate * (1 - young)]
cat("Analysis rows:", nrow(dt), " mean hired:", weighted.mean(dt$hired, dt$w), "\n")

getc <- function(m, v) tryCatch(unname(coef(m)[v]), error = function(e) NA_real_)

# ---------------- Table 1 ----------------
m <- tryCatch(feols(hired ~ urate, data = dt, weights = ~w, cluster = ~state), error = function(e) {print(e); NULL})
if (!is.null(m)) { res$aggregate_unemp_rate_no_controls <- getc(m, "urate") }
rm(m); gc()

m <- tryCatch(feols(hired ~ urate | state + demo + ym, data = dt, weights = ~w, cluster = ~state),
              error = function(e) {print(e); NULL})
if (!is.null(m)) res$aggregate_unemp_rate_month_year_fe <- getc(m, "urate")
rm(m); gc()

m <- tryCatch(feols(hired ~ young + ur_y + ur_e, data = dt, weights = ~w, cluster = ~state),
              error = function(e) {print(e); NULL})
if (!is.null(m)) {
  res$young_x_unemp_rate_no_controls <- getc(m, "ur_y")
  res$experienced_x_unemp_rate_no_controls <- getc(m, "ur_e")
  res$n_obs_full_sample <- nobs(m)
}
rm(m); gc()
if (is.na(res$n_obs_full_sample)) res$n_obs_full_sample <- nrow(dt)

m <- tryCatch(feols(hired ~ young + ur_y + ur_e | state + demo + ym, data = dt, weights = ~w, cluster = ~state),
              error = function(e) {print(e); NULL})
if (!is.null(m)) {
  print(summary(m))
  res$young_x_unemp_rate_preferred <- getc(m, "ur_y")
  res$experienced_x_unemp_rate_preferred <- getc(m, "ur_e")
}
rm(m); gc()

# ---------------- Table 2 by origin ----------------
for (o in c("E", "U", "N")) {
  m <- tryCatch(feols(hired ~ young + ur_y + ur_e | state + demo + ym, data = dt[origin == o],
                      weights = ~w, cluster = ~state), error = function(e) {print(e); NULL})
  if (!is.null(m)) {
    if (o == "E") {
      res$young_x_unemp_rate_employed <- getc(m, "ur_y")
      res$experienced_x_unemp_rate_employed <- getc(m, "ur_e")
    } else if (o == "U") {
      res$young_x_unemp_rate_unemployed <- getc(m, "ur_y")
    } else {
      res$young_x_unemp_rate_nilf <- getc(m, "ur_y")
    }
  }
  rm(m); gc()
}

# ---------------- Table 10 wages ----------------
tryCatch({
  if (is.na(wage_col)) stop("no wage column")
  hw <- dt[hired == 100]
  hw[, wage := get(wage_col)]
  hw <- hw[!is.na(wage) & wage > 0]
  if (!is.na(alloc_col) && alloc_col %in% names(hw)) {
    a <- hw[[alloc_col]]
    hw <- hw[is.na(a) | a <= 0]
  }
  cat("Wage sample rows:", nrow(hw), "\n")
  cpi <- fread(f_cpi); setnames(cpi, tolower(names(cpi)))
  cpi[, year := num(year)][, month := num(month)][, cpi := num(cpi)]
  cpi <- unique(cpi, by = c("year", "month"))
  hw <- merge(hw, cpi, by.x = c("v2hryear", "v2hrmonth"), by.y = c("year", "month"), all.x = TRUE)
  hw[is.na(cpi), cpi := 1]
  hw[, lw := log(wage / cpi)]

  map_xwalk <- function(hw, xw, codecol, cycol, recol, eras_fun) {
    xw <- copy(xw); setnames(xw, tolower(names(xw)))
    xw[, code := num(get(codecol))][, cy := num(get(cycol))][, rc := as.character(get(recol))]
    xw <- unique(xw[!is.na(code) & !is.na(cy)], by = c("code", "cy"))
    cys <- sort(unique(xw$cy))
    obs_code <- hw[[sub("^", "", codecol)]]
    yr <- hw$v2hryear; mo <- hw$v2hrmonth
    era <- eras_fun(yr, mo)
    cands <- list()
    if (length(cys) == max(era)) cands$era <- cys[era]
    cands$le <- sapply(yr, function(y) { z <- cys[cys <= y]; if (length(z)) max(z) else min(cys) })
    cands$eq <- yr
    best <- NULL; bestrate <- -1
    for (nm in names(cands)) {
      key <- data.table(code = obs_code, cy = cands[[nm]], idx = seq_along(obs_code))
      mm <- merge(key, xw[, .(code, cy, rc)], by = c("code", "cy"), all.x = TRUE)
      setorder(mm, idx)
      rate <- mean(!is.na(mm$rc))
      if (rate > bestrate) { bestrate <- rate; best <- mm$rc }
    }
    cat("crosswalk", codecol, "match rate:", bestrate, "\n")
    out <- ifelse(is.na(best), paste0("raw", era, "_", obs_code), best)
    out
  }
  occ_era <- function(y, m) ifelse(y < 2003, 1L, ifelse(y < 2011, 2L, 3L))
  ind_era <- function(y, m) ifelse(y < 2003, 1L, ifelse(y < 2009, 2L, ifelse(y < 2014, 3L, 4L)))

  occx <- fread(f_occ); indx <- fread(f_ind)
  hw[, occ := tryCatch(map_xwalk(hw, occx, "v2peio1ocd", "v2occ_codeyear", "v2censusocc_2002recode", occ_era),
                       error = function(e) paste0(occ_era(v2hryear, v2hrmonth), "_", v2peio1ocd))]
  hw[, ind := tryCatch(map_xwalk(hw, indx, "v2peio1icd", "v2ind_codeyear", "v2censusind_2002recode", ind_era),
                       error = function(e) paste0(ind_era(v2hryear, v2hrmonth), "_", v2peio1icd))]
  hw <- hw[is.finite(lw)]
  m <- feols(lw ~ young + ur_y + ur_e | state + demo + ym + occ + ind, data = hw,
             weights = ~w, cluster = ~state)
  print(summary(m))
  res$wage_young_x_unemp_rate_all_hires <- getc(m, "ur_y")
  res$wage_experienced_x_unemp_rate_all_hires <- getc(m, "ur_e")
}, error = function(e) { cat("Wage regression failed:", conditionMessage(e), "\n") })

emit()
