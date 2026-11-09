suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(0)
options(warn = 1)

say <- function(...) { cat(..., "\n"); flush(stdout()) }

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_ur   <- file.path(base, "v2unemp_smy.csv")
f_cpi  <- file.path(base, "wage_deflation_1994_2016.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")

# results initialised up-front so RESULT lines are always printed
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
fmt <- function(x) format(x, digits = 6, scientific = FALSE)
print_results <- function() {
  for (nm in names(res)) cat(paste0("RESULT:", nm, "=", fmt(res[[nm]]), "\n"))
  flush(stdout())
}

hdr <- names(fread(f_main, nrows = 0))
has <- function(x) x %in% hdr
say("Columns in yh_data:", paste(hdr, collapse = ","))

want <- c("hrmonth","hryear","peage","pesex","peeduca","race","ptdtrace","prhspnon","pehspnon","pemlr",
          "pwsswgt","v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1",
          "v2peio1cow","v2peio1icd","v2peio1ocd","v2pwsswgt",
          "hrmis","v2hrmis","v2unemp_smy")
earn_cands <- hdr[grepl("ernwa|pternwa|prernwa|earnweek|weekly", hdr, ignore.case = TRUE)]
alloc_cands <- hdr[grepl("ernal|prwernal|allocat|ptwk|alloc", hdr, ignore.case = TRUE)]
say("Earnings candidates:", paste(earn_cands, collapse = ","))
say("Allocation candidates:", paste(alloc_cands, collapse = ","))
sel <- unique(c(want[sapply(want, has)], earn_cands, alloc_cands))

dt <- fread(f_main, select = sel, showProgress = FALSE)
say("Rows read:", nrow(dt))

# ---------- normalise years (CPS HRYEAR is 2-digit in early files) ----------
fix_year <- function(y) {
  y <- as.integer(y)
  ifelse(!is.na(y) & y < 100L, ifelse(y >= 50L, y + 1900L, y + 2000L), y)
}
for (k in intersect(c("hryear", "v2hryear"), names(dt))) set(dt, j = k, value = fix_year(dt[[k]]))
say("Year range (v2hryear):", paste(range(dt$v2hryear, na.rm = TRUE), collapse = "-"))

# ---------- weights ----------
if ("v2pwsswgt" %in% names(dt)) {
  dt[, w := (pwsswgt + v2pwsswgt) / 2]
  dt[, c("pwsswgt", "v2pwsswgt") := NULL]
} else {
  setnames(dt, "pwsswgt", "w")
}

# ---------- sample restrictions (single in-place-friendly subset) ----------
edyrs <- c(`31`=0, `32`=3, `33`=6, `34`=8, `35`=9, `36`=10, `37`=11, `38`=12,
           `39`=12, `40`=13, `41`=14, `42`=14, `43`=16, `44`=18, `45`=19, `46`=21)
keep <- with(dt,
  !is.na(peage) & !is.na(peeduca) & peeduca %in% 31:46 & peage >= 16 &
  pemlr >= 1 & pemlr <= 7 & v2pemlr >= 1 & v2pemlr <= 7 &
  !(v2hryear == 1995 & v2hrmonth %in% 5:8) &
  !(hryear == 1995 & hrmonth %in% 5:8) &
  (v2hryear > 1994 | (v2hryear == 1994 & v2hrmonth >= 1)) &
  (v2hryear < 2016 | (v2hryear == 2016 & v2hrmonth <= 9)) &
  !is.na(w) & w > 0)
if (has("hrmis") && has("v2hrmis")) keep <- keep & !(dt$hrmis == 4 & dt$v2hrmis == 5)
keep[is.na(keep)] <- FALSE
dt <- dt[keep]
rm(keep); invisible(gc())
say("Rows after restrictions:", nrow(dt))
cat('DEVIATION: State unemployment-rate file provided only covers 1994 to mid-2014; person-months after that lack the cyclical regressor and are dropped from estimation\n')

# ---------- labor market status ----------
dt[, emp_prev := pemlr %in% 1:2]
dt[, unemp_prev := pemlr %in% 3:4]
dt[, nilf_prev := pemlr %in% 5:7]
if ("v2peio1cow" %in% names(dt)) {
  dt[, selfemp_now := !is.na(v2peio1cow) & v2peio1cow %in% c(6, 7)]
} else dt[, selfemp_now := FALSE]
dt[, changed_emp := !is.na(v2puiodp1) & v2puiodp1 == 2]
dt[, hired := 100 * as.numeric((v2pemlr %in% 1:2) & !selfemp_now & ((!emp_prev) | (emp_prev & changed_emp)))]
dt[, c("selfemp_now", "changed_emp") := NULL]

# ---------- potential experience ----------
dt[, pe := peage - unname(edyrs[as.character(peeduca)]) - 6]
dt[, young := as.numeric(pe <= 10)]
dt[, pe := NULL]

dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca %in% 40:42, 3L,
                    peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L,
                    peeduca == 46, 7L)]
race_var <- intersect(c("race", "ptdtrace"), names(dt))
if (length(race_var)) {
  dt[, white := as.integer(!is.na(get(race_var[1])) & get(race_var[1]) == 1)]
} else dt[, white := 0L]
hisp_var <- intersect(c("prhspnon", "pehspnon"), names(dt))
if (length(hisp_var)) {
  dt[, hisp := as.integer(!is.na(get(hisp_var[1])) & get(hisp_var[1]) == 1)]
} else dt[, hisp := 0L]
dt[, demo := .GRP, by = .(pesex, white, hisp, educ7)]

keep_cols <- intersect(c("hired","young","demo","w","v2gestfips","v2hryear","v2hrmonth",
                         "emp_prev","unemp_prev","nilf_prev","v2peio1icd","v2peio1ocd",
                         "v2unemp_smy", earn_cands, alloc_cands), names(dt))
drop_cols <- setdiff(names(dt), keep_cols)
if (length(drop_cols)) dt[, (drop_cols) := NULL]
invisible(gc())
say("Columns kept:", paste(names(dt), collapse = ","))

# ---------- unemployment rate ----------
for (k in c("v2gestfips","v2hryear","v2hrmonth")) set(dt, j = k, value = as.integer(dt[[k]]))
if (!("v2unemp_smy" %in% names(dt))) {
  urdt <- fread(f_ur)
  setnames(urdt, tolower(names(urdt)))
  say("UR file columns:", paste(names(urdt), collapse = ","))
  ren <- c(gestfips = "v2gestfips", hryear = "v2hryear", hrmonth = "v2hrmonth",
           statefip = "v2gestfips", state = "v2gestfips", year = "v2hryear", month = "v2hrmonth")
  for (o in names(ren)) {
    if (o %in% names(urdt) && !(ren[[o]] %in% names(urdt))) setnames(urdt, o, ren[[o]])
  }
  if (!("v2unemp_smy" %in% names(urdt))) {
    uc <- setdiff(names(urdt)[grepl("unemp|ur", names(urdt))], c("v2gestfips","v2hryear","v2hrmonth"))
    setnames(urdt, uc[1], "v2unemp_smy")
  }
  urdt <- urdt[, .(v2gestfips = as.integer(v2gestfips), v2hryear = fix_year(v2hryear),
                   v2hrmonth = as.integer(v2hrmonth),
                   v2unemp_smy = suppressWarnings(as.numeric(v2unemp_smy)))]
  urdt <- urdt[!is.na(v2unemp_smy) & !is.na(v2gestfips) & !is.na(v2hryear) & !is.na(v2hrmonth)]
  urdt <- urdt[, .(v2unemp_smy = mean(v2unemp_smy)), by = .(v2gestfips, v2hryear, v2hrmonth)]
  say("UR file rows:", nrow(urdt), "years:", paste(range(urdt$v2hryear), collapse = "-"))
  dt[urdt, v2unemp_smy := i.v2unemp_smy, on = .(v2gestfips, v2hryear, v2hrmonth)]
  rm(urdt)
}
say("Rows missing UR before drop:", sum(is.na(dt$v2unemp_smy)))
if (any(is.na(dt$v2unemp_smy))) print(dt[is.na(v2unemp_smy), .N, by = v2hryear][order(v2hryear)])
dt <- dt[!is.na(v2unemp_smy)]
invisible(gc())
if (max(dt$v2unemp_smy, na.rm = TRUE) < 1) dt[, v2unemp_smy := 100 * v2unemp_smy]
setnames(dt, c("v2unemp_smy", "v2gestfips"), c("ur", "state"))
dt[, ur_y := ur * young]
dt[, ur_o := ur * (1 - young)]
dt[, ym := v2hryear * 100L + v2hrmonth]

N <- nrow(dt)
res$n_obs_full_sample <- N
say("N full sample:", N)

safe <- function(expr) tryCatch(expr, error = function(e) { message("Model error: ", conditionMessage(e)); NULL })
cf <- function(m, nm) if (is.null(m)) NA_real_ else unname(coef(m)[nm])
est <- function(fml, data, subset = NULL) {
  m <- safe(if (is.null(subset)) {
    feols(fml, data = data, weights = ~w, cluster = ~state, lean = TRUE, mem.clean = TRUE)
  } else {
    feols(fml, data = data, weights = ~w, cluster = ~state, subset = subset, lean = TRUE, mem.clean = TRUE)
  })
  if (!is.null(m)) print(coeftable(m))
  m
}

# ---------- Table 1 ----------
m <- est(hired ~ ur, dt)
res$aggregate_unemp_rate_no_controls <- cf(m, "ur"); rm(m); invisible(gc())
m <- est(hired ~ ur | state + demo + ym, dt)
res$aggregate_unemp_rate_month_year_fe <- cf(m, "ur"); rm(m); invisible(gc())
m <- est(hired ~ young + ur_y + ur_o, dt)
res$young_x_unemp_rate_no_controls <- cf(m, "ur_y")
res$experienced_x_unemp_rate_no_controls <- cf(m, "ur_o"); rm(m); invisible(gc())
m <- est(hired ~ young + ur_y + ur_o | state + demo + ym, dt)
res$young_x_unemp_rate_preferred <- cf(m, "ur_y")
res$experienced_x_unemp_rate_preferred <- cf(m, "ur_o"); rm(m); invisible(gc())
say("Table 1 done")

# ---------- Table 2 by origin ----------
m <- est(hired ~ young + ur_y + ur_o | state + demo + ym, dt, subset = dt$emp_prev)
res$young_x_unemp_rate_employed <- cf(m, "ur_y")
res$experienced_x_unemp_rate_employed <- cf(m, "ur_o"); rm(m); invisible(gc())
m <- est(hired ~ young + ur_y + ur_o | state + demo + ym, dt, subset = dt$unemp_prev)
res$young_x_unemp_rate_unemployed <- cf(m, "ur_y"); rm(m); invisible(gc())
m <- est(hired ~ young + ur_y + ur_o | state + demo + ym, dt, subset = dt$nilf_prev)
res$young_x_unemp_rate_nilf <- cf(m, "ur_y"); rm(m); invisible(gc())
say("Table 2 done")

# ---------- Table 10: wages of new hires ----------
earn_var <- NULL
for (cand in c("v2prernwa","v2pternwa","v2earnweek","prernwa","pternwa")) if (cand %in% names(dt)) { earn_var <- cand; break }
if (is.null(earn_var) && length(earn_cands) > 0) {
  v2c <- earn_cands[grepl("^v2", earn_cands)]
  earn_var <- if (length(v2c)) v2c[1] else earn_cands[1]
}
h <- dt[hired == 100]
rm(dt); invisible(gc())
tryCatch({
  if (!is.null(earn_var)) {
    h[, earn := as.numeric(get(earn_var))]
    h <- h[!is.na(earn) & earn > 0]
    if (median(h$earn) > 20000) h[, earn := earn / 100]
    al <- alloc_cands[grepl("^v2", alloc_cands) & grepl("ernwa|wernal", alloc_cands)]
    if (length(al)) {
      a <- al[1]
      h <- h[is.na(get(a)) | get(a) %in% c(-1, 0)]
    }
    cpi <- fread(f_cpi)
    setnames(cpi, tolower(names(cpi)))
    say("CPI file columns:", paste(names(cpi), collapse = ","))
    if (!("year" %in% names(cpi))) { yc <- names(cpi)[grepl("year", names(cpi))][1]; setnames(cpi, yc, "year") }
    if (!("month" %in% names(cpi))) { mc <- names(cpi)[grepl("month", names(cpi))][1]; setnames(cpi, mc, "month") }
    if (!("cpi" %in% names(cpi))) { cc <- setdiff(names(cpi), c("year","month"))[1]; setnames(cpi, cc, "cpi") }
    cpi <- unique(cpi[, .(year = fix_year(year), month = as.integer(month), cpi = as.numeric(cpi))], by = c("year","month"))
    base_cpi <- cpi[year == 1994 & month == 1, cpi][1]
    if (is.na(base_cpi)) base_cpi <- cpi$cpi[1]
    h <- merge(h, cpi, by.x = c("v2hryear","v2hrmonth"), by.y = c("year","month"), all.x = TRUE)
    h[, lw := log(earn * base_cpi / cpi)]

    start_of <- function(v) {
      s <- c(`1990`=1994, `2000`=2003, `2002`=2003, `2007`=2009, `2010`=2011, `2012`=2014, `2013`=2014)
      out <- s[as.character(v)]; out[is.na(out)] <- v[is.na(out)] + 1; as.numeric(out)
    }
    assign_cy <- function(years, cys) {
      cys <- sort(unique(cys)); st <- start_of(cys)
      sapply(years, function(y) { ok <- which(st <= y); if (length(ok)) cys[max(ok)] else cys[1] })
    }
    ix <- fread(f_ind); ox <- fread(f_occ)
    say("Ind xwalk columns:", paste(names(ix), collapse = ","))
    say("Occ xwalk columns:", paste(names(ox), collapse = ","))
    yrs <- sort(unique(h$v2hryear))
    imap <- data.table(v2hryear = yrs, v2ind_codeyear = assign_cy(yrs, ix$v2ind_codeyear))
    omap <- data.table(v2hryear = yrs, v2occ_codeyear = assign_cy(yrs, ox$v2occ_codeyear))
    h <- merge(h, imap, by = "v2hryear", all.x = TRUE)
    h <- merge(h, omap, by = "v2hryear", all.x = TRUE)
    ix <- unique(ix, by = c("v2peio1icd","v2ind_codeyear"))
    ox <- unique(ox, by = c("v2peio1ocd","v2occ_codeyear"))
    h <- merge(h, ix, by = c("v2peio1icd","v2ind_codeyear"), all.x = TRUE)
    h <- merge(h, ox, by = c("v2peio1ocd","v2occ_codeyear"), all.x = TRUE)
    h[, ind := ifelse(is.na(v2censusind_2002recode), paste0("r", v2ind_codeyear, "_", v2peio1icd), as.character(v2censusind_2002recode))]
    h[, occ := ifelse(is.na(v2censusocc_2002recode), paste0("r", v2occ_codeyear, "_", v2peio1ocd), as.character(v2censusocc_2002recode))]
    h <- h[is.finite(lw)]
    fw <- feols(lw ~ young + ur_y + ur_o | state + demo + ym + ind + occ, data = h, weights = ~w, cluster = ~state)
    print(coeftable(fw))
    res$wage_young_x_unemp_rate_all_hires <- unname(coef(fw)["ur_y"])
    res$wage_experienced_x_unemp_rate_all_hires <- unname(coef(fw)["ur_o"])
  }
}, error = function(e) message("Wage regression error: ", conditionMessage(e)))

print_results()
