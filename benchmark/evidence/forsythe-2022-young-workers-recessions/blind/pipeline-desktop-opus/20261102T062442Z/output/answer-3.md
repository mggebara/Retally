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
printed <- setNames(rep(FALSE, length(res)), names(res))

fmt <- function(v) ifelse(is.null(v) || length(v) == 0 || is.na(v), "NA", format(v, digits = 10, scientific = FALSE))

# Print each result as soon as it is computed so a later crash / kill cannot lose it
setres <- function(nm, v) {
  v <- if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v)[1]
  res[[nm]] <<- v
  if (!is.na(v) && !printed[[nm]]) {
    cat(sprintf("RESULT:%s=%s\n", nm, fmt(v)))
    flush.console()
    printed[[nm]] <<- TRUE
  }
}

emit <- function() {
  for (nm in names(res)) {
    if (!printed[[nm]]) {
      cat(sprintf("RESULT:%s=%s\n", nm, fmt(res[[nm]])))
      printed[[nm]] <<- TRUE
    }
  }
}

hw <- NULL
wage_col <- NA_character_
alloc_col <- NA_character_

tryCatch({

hdr_raw <- names(fread(f_main, nrows = 0))
hdr <- tolower(hdr_raw)
cat("Columns:", paste(hdr, collapse = ","), "\n")

find_col <- function(cands) {
  for (cn in cands) if (cn %in% hdr) return(cn)
  NA_character_
}

hisp_col <- find_col(c("prhspnon", "pehspnon"))
cat("hisp col:", hisp_col, "\n")

need <- c("hrmonth", "hryear", "peage", "pesex", "peeduca", "race",
          "pemlr", "pwsswgt", "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr",
          "v2puiodp1", "v2peio1cow", "v2peio1icd", "v2peio1ocd")
opt <- c("v2pwsswgt", "v2unemp_smy")

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

sel <- intersect(c(need, opt, hisp_col, wage_col, alloc_col), hdr)
sel <- unique(sel[!is.na(sel)])
sel_raw <- hdr_raw[match(sel, hdr)]

dt <- fread(f_main, select = sel_raw, showProgress = FALSE)
setnames(dt, tolower(names(dt)))
cat("Raw rows:", nrow(dt), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
for (cn in names(dt)) if (!is.numeric(dt[[cn]])) set(dt, j = cn, value = num(dt[[cn]]))

# ---------------- sample restrictions (single pass to limit copies) ----------------
keep <- with(dt,
  !is.na(hryear) & !is.na(hrmonth) & !is.na(v2hryear) & !is.na(v2hrmonth) &
  ((v2hryear * 12 + v2hrmonth) - (hryear * 12 + hrmonth)) == 1 &
  (v2hryear * 100 + v2hrmonth) >= 199402 & (v2hryear * 100 + v2hrmonth) <= 201609 &
  !(hryear == 1995 & hrmonth %in% 5:8) & !(v2hryear == 1995 & v2hrmonth %in% 5:8) &
  pemlr %in% 1:7 & v2pemlr %in% 1:7 &
  !is.na(peage) & peage >= 16 &
  !is.na(peeduca) & peeduca >= 31 & peeduca <= 46)
keep[is.na(keep)] <- FALSE
dt <- dt[keep]
rm(keep); invisible(gc())
cat("Rows after restrictions:", nrow(dt), "\n"); flush.console()

# ---------------- variables ----------------
educ_lookup <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)  # codes 31..46
dt[, young := as.integer((peage - educ_lookup[peeduca - 30L] - 6) <= 10)]
dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca <= 42, 3L,
                    peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L, default = 7L)]
if (!is.na(hisp_col) && hisp_col %in% names(dt)) {
  dt[, demo := as.integer(pesex) * 1000L + as.integer(!is.na(race) & race == 1) * 100L +
       as.integer(!is.na(get(hisp_col)) & get(hisp_col) == 1) * 10L + educ7]
} else {
  dt[, demo := as.integer(pesex) * 1000L + as.integer(!is.na(race) & race == 1) * 100L + educ7]
}
drop1 <- intersect(c("educ7", "peage", "peeduca", "pesex", "race", "prhspnon", "pehspnon", "hryear", "hrmonth"), names(dt))
dt[, (drop1) := NULL]
invisible(gc())

if ("v2pwsswgt" %in% names(dt)) {
  dt[, w := fifelse(!is.na(v2pwsswgt) & v2pwsswgt > 0 & !is.na(pwsswgt) & pwsswgt > 0,
                    (pwsswgt + v2pwsswgt) / 2,
                    fifelse(!is.na(pwsswgt) & pwsswgt > 0, pwsswgt, v2pwsswgt))]
  dt[, v2pwsswgt := NULL]
} else {
  dt[, w := pwsswgt]
}
dt[, pwsswgt := NULL]
dt <- dt[!is.na(w) & w > 0]
invisible(gc())

dt[, hired := 100L * as.integer(
  ((!(pemlr %in% 1:2) & v2pemlr %in% 1:2) |
   (pemlr %in% 1:2 & v2pemlr %in% 1:2 & !is.na(v2puiodp1) & v2puiodp1 == 2)) &
  !(!is.na(v2peio1cow) & v2peio1cow %in% c(6, 7)))]
dt[, origin := fifelse(pemlr %in% 1:2, 1L, fifelse(pemlr %in% 3:4, 2L, 3L))]
dt[, c("pemlr", "v2pemlr", "v2puiodp1", "v2peio1cow") := NULL]
invisible(gc())

# state unemployment rate (join by reference, no copy of dt)
if (!("v2unemp_smy" %in% names(dt))) {
  ur <- fread(f_ur)
  setnames(ur, tolower(names(ur)))
  for (cn in names(ur)) set(ur, j = cn, value = num(ur[[cn]]))
  ur <- unique(ur, by = c("v2gestfips", "v2hryear", "v2hrmonth"))
  dt[, v2unemp_smy := NA_real_]
  dt[ur, v2unemp_smy := i.v2unemp_smy, on = c("v2gestfips", "v2hryear", "v2hrmonth")]
  rm(ur)
}
setnames(dt, "v2unemp_smy", "urate")
if (max(dt$urate, na.rm = TRUE) < 1) dt[, urate := urate * 100]
dt <- dt[!is.na(urate) & !is.na(v2gestfips)]
setnames(dt, "v2gestfips", "state")
dt[, ym := as.integer(v2hryear * 100L + v2hrmonth)]
dt[, ur_y := urate * young]
dt[, ur_e := urate * (1 - young)]
invisible(gc())
cat("Analysis rows:", nrow(dt), " mean hired:", weighted.mean(dt$hired, dt$w), "\n"); flush.console()

# ---------------- set aside hires sample for wage regression, drop wage cols from dt ----------------
wcols <- intersect(c(wage_col, alloc_col, "v2peio1icd", "v2peio1ocd"), names(dt))
if (!is.na(wage_col) && wage_col %in% names(dt)) {
  hw <- dt[hired == 100L, c("young", "ur_y", "ur_e", "w", "state", "demo", "ym",
                            "v2hryear", "v2hrmonth", wcols), with = FALSE]
}
if (length(wcols)) dt[, (wcols) := NULL]
dt[, c("v2hryear", "v2hrmonth") := NULL]
invisible(gc())

getc <- function(m, v) tryCatch(unname(coef(m)[v]), error = function(e) NA_real_)
fe_fit <- function(fml, d) tryCatch(feols(fml, data = d, weights = ~w, cluster = ~state, mem.clean = TRUE),
                                    error = function(e) { print(e); NULL })

# ---------------- Table 1 ----------------
m <- fe_fit(hired ~ young + ur_y + ur_e | state + demo + ym, dt)
if (!is.null(m)) {
  print(summary(m))
  setres("young_x_unemp_rate_preferred", getc(m, "ur_y"))
  setres("experienced_x_unemp_rate_preferred", getc(m, "ur_e"))
}
rm(m); invisible(gc())

m <- fe_fit(hired ~ young + ur_y + ur_e, dt)
if (!is.null(m)) {
  setres("young_x_unemp_rate_no_controls", getc(m, "ur_y"))
  setres("experienced_x_unemp_rate_no_controls", getc(m, "ur_e"))
  setres("n_obs_full_sample", nobs(m))
}
rm(m); invisible(gc())
if (is.na(res$n_obs_full_sample)) setres("n_obs_full_sample", nrow(dt))

m <- fe_fit(hired ~ urate, dt)
if (!is.null(m)) setres("aggregate_unemp_rate_no_controls", getc(m, "urate"))
rm(m); invisible(gc())

m <- fe_fit(hired ~ urate | state + demo + ym, dt)
if (!is.null(m)) setres("aggregate_unemp_rate_month_year_fe", getc(m, "urate"))
rm(m); invisible(gc())

# ---------------- Table 2 by origin ----------------
for (o in 1:3) {
  m <- fe_fit(hired ~ young + ur_y + ur_e | state + demo + ym, dt[origin == o])
  if (!is.null(m)) {
    if (o == 1L) {
      setres("young_x_unemp_rate_employed", getc(m, "ur_y"))
      setres("experienced_x_unemp_rate_employed", getc(m, "ur_e"))
    } else if (o == 2L) {
      setres("young_x_unemp_rate_unemployed", getc(m, "ur_y"))
    } else {
      setres("young_x_unemp_rate_nilf", getc(m, "ur_y"))
    }
  }
  rm(m); invisible(gc())
}
rm(dt); invisible(gc())

}, error = function(e) { cat("Pipeline error:", conditionMessage(e), "\n") })

# ---------------- Table 10 wages ----------------
tryCatch({
  if (is.null(hw)) stop("no wage sample")
  hw[, wage := get(wage_col)]
  hw <- hw[!is.na(wage) & wage > 0]
  if (!is.na(alloc_col) && alloc_col %in% names(hw)) {
    a <- hw[[alloc_col]]
    hw <- hw[is.na(a) | a <= 0]
  }
  cat("Wage sample rows:", nrow(hw), "\n")
  num <- function(x) suppressWarnings(as.numeric(x))
  cpi <- fread(f_cpi); setnames(cpi, tolower(names(cpi)))
  cpi[, year := num(year)][, month := num(month)][, cpi := num(cpi)]
  cpi <- unique(cpi[, .(year, month, cpi)], by = c("year", "month"))
  hw <- merge(hw, cpi, by.x = c("v2hryear", "v2hrmonth"), by.y = c("year", "month"), all.x = TRUE)
  hw[is.na(cpi), cpi := 1]
  hw[, lw := log(wage / cpi)]

  map_xwalk <- function(hw, xw, codecol, cycol, recol, eras_fun) {
    xw <- copy(xw); setnames(xw, tolower(names(xw)))
    xw[, code := num(get(codecol))][, cy := num(get(cycol))][, rc := as.character(get(recol))]
    xw <- unique(xw[!is.na(code) & !is.na(cy)], by = c("code", "cy"))
    cys <- sort(unique(xw$cy))
    obs_code <- hw[[codecol]]
    yr <- hw$v2hryear; mo <- hw$v2hrmonth
    era <- eras_fun(yr, mo)
    cands <- list()
    if (length(cys) == max(era)) cands$era <- cys[era]
    uy <- sort(unique(yr))
    le_map <- sapply(uy, function(y) { z <- cys[cys <= y]; if (length(z)) max(z) else min(cys) })
    cands$le <- le_map[match(yr, uy)]
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
    ifelse(is.na(best), paste0("raw", era, "_", obs_code), best)
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
  setres("wage_young_x_unemp_rate_all_hires", getc2 <- tryCatch(unname(coef(m)["ur_y"]), error = function(e) NA_real_))
  setres("wage_experienced_x_unemp_rate_all_hires", tryCatch(unname(coef(m)["ur_e"]), error = function(e) NA_real_))
}, error = function(e) { cat("Wage regression failed:", conditionMessage(e), "\n") })

emit()
