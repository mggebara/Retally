# Retally independent/blind reproduction: Forsythe (2022), "Why Don't Firms Hire Young Workers During Recessions?"
# Tables 1, 2 (hiring LPMs) and Table 10 Panel B col (1) (log weekly wages of new hires).
suppressPackageStartupMessages({ library(data.table); library(fixest) })
set.seed(42)
setFixest_nthreads(1)
t0 <- Sys.time()
el <- function() round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)

D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-02-c/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"

# ---- auxiliary files ----
un  <- fread(file.path(D, "v2unemp_smy.csv"))
setnames(un, c("v2gestfips", "v2unemp_smy", "v2hryear", "v2hrmonth"), c("st", "urate", "yr", "mo"))
cpi <- fread(file.path(D, "wage_deflation_1994_2016.csv"))
setnames(cpi, c("year", "month"), c("yr", "mo"))
ixw <- unique(fread(file.path(D, "ind_xwalk2002.csv")), by = c("v2peio1icd", "v2ind_codeyear"))
oxw <- unique(fread(file.path(D, "occ_xwalk2002.csv")), by = c("v2peio1ocd", "v2occ_codeyear"))

# ---- main matched-pair file (unprefixed = month t-1, v2 prefix = month t) ----
# DEVIATION: only the needed columns are read (fread select=) because of the 4 GB memory / 300 s sandbox limits.
cols <- c("peage", "pesex", "peeduca", "race", "prhspnon", "pehspnon", "pemlr", "pwsswgt",
          "v2hrmonth", "v2hryear", "v2gestfips", "v2pemlr", "v2puiodp1", "v2peio1cow",
          "v2peio1icd", "v2peio1ocd", "v2prernwa", "v2prwernal", "v2pwsswgt")
x <- fread(file.path(D, "yh_data.csv"), select = cols, showProgress = FALSE)
cat("read done, rows:", nrow(x), " secs:", el(), "\n")

x[, yr := fifelse(v2hryear < 100L, 1900L + v2hryear, v2hryear)]
x[, mo := v2hrmonth]
x[, c("v2hryear", "v2hrmonth") := NULL]
setnames(x, "v2gestfips", "st")

# (all work is done in place to stay within the 4 GB memory cap; the sample filter is a flag)
# state unemployment rate in month t
x[un, urate := i.urate, on = .(st, yr, mo)]
x[, ym := yr * 100L + mo]
# sample: month t up to Sep 2016; civilians 16+ with employment data, non-missing age / education,
# and a state unemployment rate
x[, keep := ym <= 201609L & peage >= 16L & peeduca >= 31L & peeduca <= 46L & pemlr >= 1L & v2pemlr >= 1L]
cat("rows after age/educ filter:", sum(x$keep), " missing state:", sum(x$keep & is.na(x$st)),
    " missing urate:", sum(x$keep & is.na(x$urate)), "\n")
x[, keep := keep & !is.na(urate)]

# ---- variables ----
educyrs <- rep(NA_real_, 46)
educyrs[31:46] <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)
x[, pe := peage - educyrs[pmin(pmax(peeduca, 1L), 46L)] - 6]
x[, young := as.integer(pe <= 10)]
x[, ed7 := fcase(peeduca <= 38L, 1L, peeduca == 39L, 2L, peeduca <= 42L, 3L, peeduca == 43L, 4L,
                 peeduca == 44L, 5L, peeduca == 45L, 6L, peeduca == 46L, 7L)]
x[, hisp := as.integer(fcoalesce(prhspnon, pehspnon) == 1L)]
x[, white := as.integer(race == 1L)]
x[, demo := ((pesex * 10L + white) * 10L + hisp) * 10L + ed7]
x[, origin := fcase(pemlr <= 2L, 1L, pemlr <= 4L, 2L, default = 3L)]   # 1 employed, 2 unemployed, 3 NILF
emp_t <- x$v2pemlr <= 2L
selfemp_t <- x$v2peio1cow %in% c(6L, 7L)
# hire: employed in t, not self-employed in t, and either non-employed in t-1 or employed in t-1 and
# reports no longer working for last month's employer (PUIODP1 == 2)
x[, hired := 100 * as.integer(emp_t & !selfemp_t & (origin > 1L | (origin == 1L & v2puiodp1 == 2L)))]
x[, w := (pwsswgt + v2pwsswgt) / 2]
rm(emp_t, selfemp_t)
x[, c("pwsswgt", "v2pwsswgt", "prhspnon", "pehspnon", "race", "v2puiodp1", "v2peio1cow", "pemlr", "v2pemlr") := NULL]
invisible(gc())

N_full <- sum(x$keep)
cat("N full:", N_full, " months:", uniqueN(x$ym[x$keep]), " last ym:", max(x$ym[x$keep]),
    " states:", uniqueN(x$st[x$keep]), " secs:", el(), "\n")
cat("weighted hire rate all/young/old:", x[keep == TRUE, weighted.mean(hired, w)],
    x[keep == TRUE & young == 1L, weighted.mean(hired, w)], x[keep == TRUE & young == 0L, weighted.mean(hired, w)], "\n")
cat("share young:", x[keep == TRUE, mean(young)], "\n")

# ---- wage sample (new hires with non-allocated weekly earnings) ----
wg <- x[keep == TRUE & hired > 0 & !is.na(v2prernwa) & v2prernwa > 0 & !is.na(v2prwernal) & v2prwernal == 0L,
        .(st, yr, mo, ym, demo, young, urate, w, origin, v2prernwa, v2peio1icd, v2peio1ocd)]
cat("wage hires:", nrow(wg), " (hires with wage but allocation flag NA:",
    x[keep == TRUE & hired > 0 & !is.na(v2prernwa) & v2prernwa > 0 & is.na(v2prwernal), .N], ")\n")

# ---- collapse hiring data to cells (all regressors are constant within cells, so weighted OLS on
#      cell means with summed weights gives identical coefficients) ----
cells <- x[keep == TRUE, .(sw = sum(w), swh = sum(w * hired), n = .N),
           by = .(st, ym, demo, young, origin, urate)]
rm(x); invisible(gc())
cells[, hr := swh / sw]
cells[, `:=`(uy = urate * young, uo = urate * (1 - young))]
cat("cells:", nrow(cells), " secs:", el(), "\n")

# pool over origin for the full-sample regressions
call <- cells[, .(sw = sum(sw), swh = sum(swh), n = sum(n)), by = .(st, ym, demo, young, urate)]
call[, hr := swh / sw]
call[, `:=`(uy = urate * young, uo = urate * (1 - young))]

a1 <- feols(hr ~ urate, data = call, weights = ~sw, cluster = ~st)
a4 <- feols(hr ~ urate | st + demo + ym, data = call, weights = ~sw, cluster = ~st)
b1 <- feols(hr ~ young + uy + uo, data = call, weights = ~sw, cluster = ~st)
b4 <- feols(hr ~ young + uy + uo | st + demo + ym, data = call, weights = ~sw, cluster = ~st)
e2 <- feols(hr ~ young + uy + uo | st + demo + ym, data = cells[origin == 1L], weights = ~sw, cluster = ~st)
e3 <- feols(hr ~ young + uy + uo | st + demo + ym, data = cells[origin == 2L], weights = ~sw, cluster = ~st)
e4 <- feols(hr ~ young + uy + uo | st + demo + ym, data = cells[origin == 3L], weights = ~sw, cluster = ~st)
cat("hiring regressions done, secs:", el(), "\n")
cat("N by origin:", cells[, sum(n), by = origin][order(origin)]$V1, "\n")

# ---- wage regression ----
wg <- cpi[wg, on = .(yr, mo)]
wg[, lw := log(v2prernwa / cpi)]
wg[, icy := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2008L, 2002L, fifelse(yr <= 2013L, 2007L, 2012L)))]
wg[, ocy := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2010L, 2002L, 2010L))]
wg <- ixw[wg, on = .(v2peio1icd, v2ind_codeyear = icy)]
wg <- oxw[wg, on = .(v2peio1ocd, v2occ_codeyear = ocy)]
cat("ind xwalk unmatched:", sum(is.na(wg$v2censusind_2002recode)), " occ xwalk unmatched:",
    sum(is.na(wg$v2censusocc_2002recode)), "\n")
wg[, ind := fifelse(is.na(v2censusind_2002recode), -v2ind_codeyear * 10000L - v2peio1icd, v2censusind_2002recode)]
wg[, occ := fifelse(is.na(v2censusocc_2002recode), -v2occ_codeyear * 10000L - v2peio1ocd, v2censusocc_2002recode)]
wg[, `:=`(uy = urate * young, uo = urate * (1 - young))]
w1 <- feols(lw ~ young + uy + uo | st + demo + ym + occ + ind, data = wg, weights = ~w, cluster = ~st)
cat("wage N:", nobs(w1), "\n")

# ---- results ----
cat("DEVIATION: yh_data.csv read with data.table::fread(select=) of the 19 needed columns only (4 GB memory / 300 s sandbox limits).\n")
cat("DEVIATION: state identifiers are missing in the data after mid-2014 and the state unemployment file ends May 2014, so the estimation sample ends May 2014 rather than September 2016.\n")
cat("DEVIATION: hiring regressions estimated on weighted cell means (state x month x demographic cell x PE group x prior status); coefficients are identical to the individual-level weighted LPM.\n")
cat("DEVIATION: years of education imputed from PEEDUCA categories (31:0, 32:2.5, 33:5.5, 34:7.5, 35:9, 36:10, 37:11, 38-39:12, 40:13, 41-42:14, 43:16, 44:18, 45-46:20).\n")
p <- function(nm, v) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
p("young_x_unemp_rate_no_controls", coef(b1)[["uy"]])
p("experienced_x_unemp_rate_no_controls", coef(b1)[["uo"]])
p("young_x_unemp_rate_preferred", coef(b4)[["uy"]])
p("experienced_x_unemp_rate_preferred", coef(b4)[["uo"]])
p("aggregate_unemp_rate_no_controls", coef(a1)[["urate"]])
p("aggregate_unemp_rate_month_year_fe", coef(a4)[["urate"]])
p("young_x_unemp_rate_employed", coef(e2)[["uy"]])
p("experienced_x_unemp_rate_employed", coef(e2)[["uo"]])
p("young_x_unemp_rate_unemployed", coef(e3)[["uy"]])
p("young_x_unemp_rate_nilf", coef(e4)[["uy"]])
p("wage_young_x_unemp_rate_all_hires", coef(w1)[["uy"]])
p("wage_experienced_x_unemp_rate_all_hires", coef(w1)[["uo"]])
cat(sprintf("RESULT:n_obs_full_sample=%d\n", N_full))
cat("total secs:", el(), "\n")
