suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
options(warn = 1)
setFixest_nthreads(2)

base_dir <- file.path("<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free",
                      "3 replication package", "Data")
f_main  <- file.path(base_dir, "yh_data.csv")
f_unemp <- file.path(base_dir, "v2unemp_smy.csv")
f_cpi   <- file.path(base_dir, "wage_deflation_1994_2016.csv")
f_ind   <- file.path(base_dir, "ind_xwalk2002.csv")
f_occ   <- file.path(base_dir, "occ_xwalk2002.csv")

results <- list()
# Print each result immediately so partial output survives a later crash;
# all results are printed again at the end.
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) {
    results[[name]] <<- value
    cat(sprintf("RESULT:%s=%s\n", name, format(value, digits = 10, scientific = FALSE)))
    flush.console()
  }
}

getc <- function(m, v) tryCatch(unname(coef(m)[v]), error = function(e) NA_real_)
gets <- function(m, v) tryCatch(unname(sqrt(diag(vcov(m)))[v]), error = function(e) NA_real_)
run <- function(expr) tryCatch(expr, error = function(e) { message("Model error: ", conditionMessage(e)); NULL })
fix_year <- function(y) ifelse(!is.na(y) & y < 100, ifelse(y >= 50, 1900 + y, 2000 + y), y)
find_col <- function(nms, pref, pat) {
  for (p in pref) if (p %in% nms) return(p)
  g <- grep(pat, nms, value = TRUE)
  if (length(g)) g[1] else NA_character_
}

main_ok <- tryCatch({

# ------------------------------------------------------------------
# Column selection from header
# ------------------------------------------------------------------
hdr <- names(fread(f_main, nrows = 0))
hdr_l <- tolower(hdr)

pick_first <- function(cands) {
  for (cc in cands) if (cc %in% hdr_l) return(cc)
  NA_character_
}

core <- c("hrmonth", "hryear", "peage", "pesex", "peeduca", "race", "prhspnon",
          "pemlr", "pwsswgt", "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr",
          "v2puiodp1", "v2peio1cow", "v2peio1icd", "v2peio1ocd")
opt_w2   <- pick_first(c("v2pwsswgt"))
opt_mis1 <- pick_first(c("hrmis"))
opt_mis2 <- pick_first(c("v2hrmis"))

earn_col <- pick_first(c("v2prernwa", "v2pternwa"))
if (is.na(earn_col)) {
  g <- grep("^v2.*ernwa", hdr_l, value = TRUE)
  if (length(g)) earn_col <- g[1]
}
alloc_col <- pick_first(c("v2prwernal", "v2ptwernal"))
if (is.na(alloc_col)) {
  g <- grep("^v2.*ernal", hdr_l, value = TRUE)
  if (length(g)) alloc_col <- g[1]
}

sel <- unique(c(core, opt_w2, opt_mis1, opt_mis2, earn_col, alloc_col))
sel <- sel[!is.na(sel) & sel %in% hdr_l]
sel_orig <- hdr[match(sel, hdr_l)]

dt <- fread(f_main, select = sel_orig, showProgress = FALSE)
setnames(dt, tolower(names(dt)))
for (cc in names(dt)) {
  if (is.character(dt[[cc]]) || is.logical(dt[[cc]])) set(dt, j = cc, value = suppressWarnings(as.numeric(dt[[cc]])))
}
cat("Rows read:", nrow(dt), "\n"); flush.console()

dt[, hryear := fix_year(hryear)]
dt[, v2hryear := fix_year(v2hryear)]

# ------------------------------------------------------------------
# Sample restrictions
# ------------------------------------------------------------------
keep <- with(dt,
  !is.na(peage) & peage >= 16 & !is.na(peeduca) & peeduca %in% 31:46 &
  pemlr %in% 1:7 & v2pemlr %in% 1:7 &
  !(hryear == 1995 & hrmonth %in% 5:8) & !(v2hryear == 1995 & v2hrmonth %in% 5:8) &
  ((v2hryear * 12 + v2hrmonth) - (hryear * 12 + hrmonth)) %in% 1 &
  v2hryear >= 1994 & (v2hryear < 2016 | (v2hryear == 2016 & v2hrmonth <= 9)))
keep[is.na(keep)] <- FALSE
if ("hrmis" %in% names(dt)) keep <- keep & (is.na(dt$hrmis) | dt$hrmis != 4)
if ("v2hrmis" %in% names(dt)) keep <- keep & (is.na(dt$v2hrmis) | dt$v2hrmis != 5)
dt <- dt[which(keep)]
rm(keep); gc(verbose = FALSE)
cat("Rows after restrictions:", nrow(dt), "\n"); flush.console()

# ------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------
educ_years <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)
dt[, young := as.integer((peage - educ_years[peeduca - 30] - 6) <= 10)]

dt[, educ7 := fifelse(peeduca <= 38, 1L,
               fifelse(peeduca == 39, 2L,
               fifelse(peeduca <= 42, 3L,
               fifelse(peeduca == 43, 4L,
               fifelse(peeduca == 44, 5L,
               fifelse(peeduca == 45, 6L, 7L))))))]
dt[, demo := as.integer(as.integer(!is.na(pesex) & pesex == 2) * 1000L +
                        as.integer(!is.na(race) & race == 1) * 100L +
                        as.integer(!is.na(prhspnon) & prhspnon == 1) * 10L + educ7)]

dt[, emp_prev := pemlr %in% 1:2]
dt[, emp_now := v2pemlr %in% 1:2]
dt[, prev := fifelse(emp_prev, 1L, fifelse(pemlr %in% 3:4, 2L, 3L))]
dt[, hire01 := ((!emp_prev) & emp_now) |
               (emp_prev & emp_now & !is.na(v2puiodp1) & v2puiodp1 == 2)]
dt[!is.na(v2peio1cow) & v2peio1cow %in% 6:7, hire01 := FALSE]
dt[, hired := 100 * as.numeric(hire01)]

if ("v2pwsswgt" %in% names(dt)) {
  dt[, w := rowMeans(cbind(pwsswgt, v2pwsswgt), na.rm = TRUE)]
} else {
  dt[, w := as.numeric(pwsswgt)]
}

drop_cols <- intersect(c("peage", "pesex", "peeduca", "race", "prhspnon", "pemlr", "v2pemlr",
                         "v2puiodp1", "v2peio1cow", "pwsswgt", "v2pwsswgt", "hrmonth", "hryear",
                         "hrmis", "educ7", "emp_prev"), names(dt))
dt[, (drop_cols) := NULL]
dt <- dt[!is.na(w) & w > 0]
gc(verbose = FALSE)

# ------------------------------------------------------------------
# State unemployment rate
# ------------------------------------------------------------------
u <- fread(f_unemp, showProgress = FALSE)
setnames(u, tolower(names(u)))
uc_year  <- find_col(names(u), c("v2hryear", "hryear", "year"), "year")
uc_month <- find_col(names(u), c("v2hrmonth", "hrmonth", "month"), "month")
uc_fips  <- find_col(names(u), c("v2gestfips", "gestfips", "statefip", "fips", "state"), "fips|state")
uc_val   <- find_col(names(u), c("v2unemp_smy", "unemp_smy", "unemp"), "unemp|urate|rate")
u2 <- data.table(k_year  = fix_year(suppressWarnings(as.numeric(u[[uc_year]]))),
                 k_month = suppressWarnings(as.numeric(u[[uc_month]])),
                 k_fips  = suppressWarnings(as.numeric(u[[uc_fips]])),
                 uval    = suppressWarnings(as.numeric(u[[uc_val]])))
u2 <- u2[!is.na(k_year) & !is.na(k_month) & !is.na(k_fips)]
u2 <- unique(u2, by = c("k_fips", "k_year", "k_month"))
rm(u)

dt[, k_year := as.numeric(v2hryear)]
dt[, k_month := as.numeric(v2hrmonth)]
dt[, k_fips := as.numeric(v2gestfips)]
dt[u2, unemp := i.uval, on = c("k_fips", "k_year", "k_month")]
dt[, c("k_year", "k_month", "k_fips") := NULL]
cat("Unemp match rate:", mean(!is.na(dt$unemp)), "\n"); flush.console()
med_u <- suppressWarnings(median(dt$unemp, na.rm = TRUE))
if (isTRUE(is.finite(med_u)) && med_u < 1) dt[, unemp := unemp * 100]
dt <- dt[!is.na(unemp) & !is.na(v2gestfips)]
gc(verbose = FALSE)

dt[, state := as.integer(v2gestfips)]
dt[, ym := as.integer(v2hryear * 100 + v2hrmonth)]
dt[, uy := unemp * young]
dt[, ue := unemp * (1 - young)]
cat("Regression sample:", nrow(dt), "\n"); flush.console()
if (nrow(dt) == 0) stop("empty regression sample")

# ------------------------------------------------------------------
# Extract the (small) new-hire wage sample now, then drop wage-only
# columns from the big table to save memory.
# ------------------------------------------------------------------
wage_cols <- intersect(c("young", "uy", "ue", "state", "demo", "ym", "w", "v2hryear", "v2hrmonth",
                         "v2hrmis", "v2peio1icd", "v2peio1ocd", earn_col, alloc_col), names(dt))
wd <- dt[hire01 == TRUE & emp_now == TRUE, ..wage_cols]
dropc <- intersect(c("v2hrmis", "v2peio1icd", "v2peio1ocd", earn_col, alloc_col, "hire01", "emp_now",
                     "v2gestfips", "v2hryear", "v2hrmonth"), names(dt))
dt[, (dropc) := NULL]
gc(verbose = FALSE)

# ------------------------------------------------------------------
# Table 1 Panel A
# ------------------------------------------------------------------
pa1 <- run(feols(hired ~ unemp, data = dt, weights = ~w, cluster = ~state, lean = TRUE, mem.clean = TRUE))
if (!is.null(pa1)) {
  emit("aggregate_unemp_rate_no_controls", getc(pa1, "unemp"))
  emit("aggregate_unemp_rate_no_controls_se", gets(pa1, "unemp"))
}
rm(pa1); gc(verbose = FALSE)
pa4 <- run(feols(hired ~ unemp | state + demo + ym, data = dt, weights = ~w, cluster = ~state, lean = TRUE, mem.clean = TRUE))
if (!is.null(pa4)) {
  emit("aggregate_unemp_rate_month_year_fe", getc(pa4, "unemp"))
  emit("aggregate_unemp_rate_month_year_fe_se", gets(pa4, "unemp"))
}
rm(pa4); gc(verbose = FALSE)

# ------------------------------------------------------------------
# Table 1 Panel B
# ------------------------------------------------------------------
pb1 <- run(feols(hired ~ young + uy + ue, data = dt, weights = ~w, cluster = ~state, lean = TRUE, mem.clean = TRUE))
if (!is.null(pb1)) {
  emit("young_x_unemp_rate_no_controls", getc(pb1, "uy"))
  emit("young_x_unemp_rate_no_controls_se", gets(pb1, "uy"))
  emit("experienced_x_unemp_rate_no_controls", getc(pb1, "ue"))
  emit("experienced_x_unemp_rate_no_controls_se", gets(pb1, "ue"))
}
rm(pb1); gc(verbose = FALSE)
pb4 <- run(feols(hired ~ young + uy + ue | state + demo + ym, data = dt, weights = ~w, cluster = ~state, lean = TRUE, mem.clean = TRUE))
if (!is.null(pb4)) {
  emit("young_x_unemp_rate_preferred", getc(pb4, "uy"))
  emit("young_x_unemp_rate_preferred_se", gets(pb4, "uy"))
  emit("experienced_x_unemp_rate_preferred", getc(pb4, "ue"))
  emit("experienced_x_unemp_rate_preferred_se", gets(pb4, "ue"))
  emit("n_obs_full_sample", as.numeric(nobs(pb4)))
}
rm(pb4); gc(verbose = FALSE)

# ------------------------------------------------------------------
# Table 10: log real weekly wages of new hires (small sample; run before
# the origin-status splits so it is not lost if those run long)
# ------------------------------------------------------------------
wage_res <- tryCatch({
  if (is.na(earn_col) || !(earn_col %in% names(wd))) stop("no earnings column")
  wd[, earn := as.numeric(get(earn_col))]
  wd <- wd[!is.na(earn) & earn > 0]
  if (!is.na(alloc_col) && alloc_col %in% names(wd)) {
    wd <- wd[is.na(get(alloc_col)) | get(alloc_col) != 1]
  }
  if ("v2hrmis" %in% names(wd)) wd <- wd[v2hrmis %in% c(4, 8)]
  cpi <- fread(f_cpi, showProgress = FALSE)
  setnames(cpi, tolower(names(cpi)))
  cy_c <- find_col(names(cpi), c("year", "v2hryear", "hryear"), "year")
  cm_c <- find_col(names(cpi), c("month", "v2hrmonth", "hrmonth"), "month")
  cv_c <- find_col(names(cpi), c("cpi", "cpi_u", "cpiu"), "cpi|defl|index")
  cpi2 <- data.table(year = fix_year(as.numeric(cpi[[cy_c]])),
                     month = as.numeric(cpi[[cm_c]]),
                     cpi = as.numeric(cpi[[cv_c]]))
  cpi2 <- unique(cpi2[!is.na(year) & !is.na(month)], by = c("year", "month"))
  cpi_base <- mean(cpi2[year == 1994, cpi], na.rm = TRUE)
  if (!is.finite(cpi_base)) cpi_base <- mean(cpi2$cpi, na.rm = TRUE)
  wd[, k_year := as.numeric(v2hryear)]
  wd[, k_month := as.numeric(v2hrmonth)]
  wd[cpi2, cpiv := i.cpi, on = c(k_year = "year", k_month = "month")]
  wd[is.na(cpiv), cpiv := cpi_base]
  wd[, lw := log(earn) - log(cpiv / cpi_base)]

  map_codes <- function(wd, xw, code_col, cy_col, rec_col, out) {
    xw <- copy(xw)
    setnames(xw, tolower(names(xw)))
    xw[, (code_col) := as.numeric(get(code_col))]
    xw[, (cy_col) := as.numeric(get(cy_col))]
    cys <- sort(unique(xw[[cy_col]]))
    cys <- cys[!is.na(cys)]
    yrs <- wd$v2hryear
    if (length(cys) && all(cys > 1900 & cys < 2100)) {
      idx <- findInterval(yrs, cys)
      idx[idx == 0] <- 1
      wd[, cy_tmp := cys[idx]]
    } else {
      wd[, cy_tmp := NA_real_]
    }
    xw <- unique(xw, by = c(code_col, cy_col))
    wd[, code_tmp := as.numeric(get(code_col))]
    wd[xw, rec_tmp := get(paste0("i.", rec_col)), on = setNames(c(code_col, cy_col), c("code_tmp", "cy_tmp"))]
    era <- fifelse(wd$v2hryear < 2003, 1L, fifelse(wd$v2hryear < 2009, 2L, fifelse(wd$v2hryear < 2014, 3L, 4L)))
    cat(out, "crosswalk match rate:", mean(!is.na(wd$rec_tmp)), "\n")
    wd[, (out) := fifelse(!is.na(rec_tmp), paste0("x", rec_tmp), paste0("r", code_tmp, "_", era))]
    wd[, c("cy_tmp", "code_tmp", "rec_tmp") := NULL]
    wd
  }
  xi <- fread(f_ind, showProgress = FALSE)
  xo <- fread(f_occ, showProgress = FALSE)
  wd <- tryCatch(map_codes(wd, xi, "v2peio1icd", "v2ind_codeyear", "v2censusind_2002recode", "ind"),
                 error = function(e) { message("ind xwalk failed: ", conditionMessage(e))
                   wd[, ind := paste0(v2peio1icd, "_", v2hryear < 2003)]; wd })
  wd <- tryCatch(map_codes(wd, xo, "v2peio1ocd", "v2occ_codeyear", "v2censusocc_2002recode", "occ"),
                 error = function(e) { message("occ xwalk failed: ", conditionMessage(e))
                   wd[, occ := paste0(v2peio1ocd, "_", v2hryear < 2003)]; wd })
  cat("Wage sample:", nrow(wd), "\n")
  mw <- feols(lw ~ young + uy + ue | state + demo + ym + occ + ind, data = wd,
              weights = ~w, cluster = ~state, lean = TRUE)
  list(cy = getc(mw, "uy"), sy = gets(mw, "uy"), ce = getc(mw, "ue"), se = gets(mw, "ue"))
}, error = function(e) { message("Wage regression skipped: ", conditionMessage(e)); NULL })

if (!is.null(wage_res)) {
  emit("wage_young_x_unemp_rate_all_hires", wage_res$cy)
  emit("wage_young_x_unemp_rate_all_hires_se", wage_res$sy)
  emit("wage_experienced_x_unemp_rate_all_hires", wage_res$ce)
  emit("wage_experienced_x_unemp_rate_all_hires_se", wage_res$se)
}
rm(wd); gc(verbose = FALSE)

# ------------------------------------------------------------------
# Table 2 by origin status: subset one group at a time, freeing memory
# ------------------------------------------------------------------
keep_cols <- c("hired", "young", "uy", "ue", "state", "demo", "ym", "w")
for (s in 1:3) {
  lab <- c("employed", "unemployed", "nilf")[s]
  sub <- dt[prev == s, ..keep_cols]
  gc(verbose = FALSE)
  m <- run(feols(hired ~ young + uy + ue | state + demo + ym, data = sub,
                 weights = ~w, cluster = ~state, lean = TRUE, mem.clean = TRUE))
  rm(sub)
  if (!is.null(m)) {
    emit(paste0("young_x_unemp_rate_", lab), getc(m, "uy"))
    emit(paste0("young_x_unemp_rate_", lab, "_se"), gets(m, "uy"))
    if (lab == "employed") {
      emit("experienced_x_unemp_rate_employed", getc(m, "ue"))
      emit("experienced_x_unemp_rate_employed_se", gets(m, "ue"))
    }
  }
  rm(m); gc(verbose = FALSE)
}
TRUE
}, error = function(e) {
  cat("Fatal error in main block:", conditionMessage(e), "\n")
  FALSE
})

# ------------------------------------------------------------------
# Output
# ------------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10, scientific = FALSE)))
}
flush.console()
