# Retally reproduction: Forsythe (2022) "Why Don't Firms Hire Young Workers During Recessions?"
# Seeded mode: follows YH_data_init.do and YH_regs.do (Tables 1, 2, 10).
suppressPackageStartupMessages({library(data.table); library(fixest)})
set.seed(42)
setFixest_nthreads(1); setDTthreads(1)
t0 <- Sys.time()
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/seeded/2026-11-02-b/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"

cols <- c("peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt","v2hrmonth","v2hryear",
          "v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd","v2prernwa","v2pwsswgt","v2prwernal")
cc <- setNames(rep("integer", length(cols)), cols); cc[c("pwsswgt","v2pwsswgt","v2prernwa")] <- "double"
x <- fread(file.path(D, "yh_data.csv"), select = cc, nThread = 1, showProgress = FALSE)
cat("DEVIATION: yh_data.csv read with data.table::fread(select=) of only the 19 columns used (memory/time limits of the sandbox)\n")
cat("read secs", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "\n")

# --- data_init ---
x[v2hryear < 100L, v2hryear := v2hryear + 1900L]
un <- fread(file.path(D, "v2unemp_smy.csv"))
setnames(un, "v2unemp_smy", "v2unemp")
x[un, v2unemp := i.v2unemp, on = .(v2hryear, v2hrmonth, v2gestfips)]

x[, age := fifelse(peage > 79L, NA_integer_, peage)]
yrmap <- c(`31`=1,`32`=4,`33`=6,`34`=8,`35`=9,`36`=10,`37`=11,`38`=11.5,`39`=12,`40`=13,`41`=14,`42`=14,`43`=16,`44`=18,`45`=20,`46`=22)
x[, yrsch := unname(yrmap[as.character(peeduca)])]
x[is.na(yrsch), yrsch := 0]
x[, exp := age - yrsch - 6]
# sample restriction: keep if exp<. & v2unemp<.
x <- x[!is.na(exp) & !is.na(v2unemp)]
x[, c("peage", "age", "yrsch") := NULL]

x[, educ := fcase(peeduca > 0L & peeduca < 39L, 0L, peeduca == 39L, 1L, peeduca > 39L & peeduca < 43L, 2L,
                  peeduca == 43L, 3L, peeduca == 44L, 4L, peeduca == 45L, 5L, peeduca == 46L, 6L)]
x[, minority := as.integer(race > 1L)]
x[, female := as.integer(pesex > 1L)]
x[, hisp := as.integer((!is.na(pehspnon) & pehspnon == 1L) | (!is.na(prhspnon) & prhspnon == 1L))]
x[, demo2 := .GRP, by = .(minority, female, hisp, educ)]
x[, c("race", "pesex", "pehspnon", "prhspnon", "minority", "female", "hisp", "educ", "peeduca") := NULL]

x[, hired := 0L]
x[v2pemlr == 1L | v2pemlr == 2L, hired := 1L]
x[v2puiodp1 == 1L, hired := 0L]
x[(pemlr == 1L | pemlr == 2L) & v2puiodp1 < 0L, hired := 0L]
x[v2peio1cow >= 5L, hired := 0L]          # hired2: excludes self-employed / without pay
x[, young := as.integer(exp <= 10)]
x[, date := v2hryear * 12L + v2hrmonth]
x[, weight := (v2pwsswgt + pwsswgt) / 2]
x[, grp := fcase(pemlr == 1L | pemlr == 2L, 1L, pemlr == 3L | pemlr == 4L, 2L, pemlr > 4L, 3L)]
x[, c("v2pemlr", "v2puiodp1", "pwsswgt", "v2pwsswgt") := NULL]

N_full <- nrow(x)
cat("N full sample:", N_full, "\n")

# --- wage sample (Table 10): new hires, non-allocated weekly earnings ---
w <- x[hired == 1L & !is.na(v2prwernal) & v2prwernal == 0L]
x[, c("v2prernwa", "v2prwernal", "v2peio1icd", "v2peio1ocd", "v2peio1cow") := NULL]
cpi <- fread(file.path(D, "wage_deflation_1994_2016.csv"))
w[cpi, cpi := i.cpi, on = .(v2hryear = year, v2hrmonth = month)]
w[, lw := suppressWarnings(log(v2prernwa / cpi))]
w[!is.finite(lw), lw := NA_real_]
w[, v2occ_codeyear := fifelse(v2hryear < 2003L, 1990L, fifelse(v2hryear < 2011L, 2002L, 2010L))]
w[, v2ind_codeyear := fifelse(v2hryear < 2003L, 1990L, fifelse(v2hryear < 2009L, 2002L, fifelse(v2hryear < 2014L, 2007L, 2012L)))]
ox <- unique(fread(file.path(D, "occ_xwalk2002.csv")), by = c("v2peio1ocd", "v2occ_codeyear"))
ix <- unique(fread(file.path(D, "ind_xwalk2002.csv")), by = c("v2peio1icd", "v2ind_codeyear"))
w[ox, occ := i.v2censusocc_2002recode, on = .(v2peio1ocd, v2occ_codeyear)]
w[ix, ind := i.v2censusind_2002recode, on = .(v2peio1icd, v2ind_codeyear)]
w[is.na(ind) & v2peio1icd == 6692L, ind := 6692L]
w[is.na(ind) & v2peio1icd == 991L, ind := 9890L]
w[is.na(ind) & v2peio1icd == 9890L, ind := 9890L]
w[, youngurate := fifelse(young == 1L, v2unemp, 0)]
w[, oldurate := fifelse(young == 0L & exp > 10, v2unemp, 0)]
w[, hired100 := 100L * hired]

# --- collapse the hiring sample to cells (exact for WLS point estimates: all regressors/FEs constant within cell) ---
cells <- x[, .(h = sum(weight * hired * 100) / sum(weight), W = sum(weight), n = .N),
           by = .(v2gestfips, date, demo2, young, grp, v2unemp)]
rm(x); invisible(gc())
cells[, youngurate := fifelse(young == 1L, v2unemp, 0)]
cells[, oldurate := fifelse(young == 0L, v2unemp, 0)]
cat("DEVIATION: hiring regressions (Tables 1-2) estimated by WLS on state x month x demo2 x young x prior-status cells with summed CPS weights; identical point estimates to the person-level aweighted regression, clustered SE small-sample factor uses cell count\n")
cat("cells:", nrow(cells), " secs", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "\n")

est <- function(fml, d, wt = ~W) feols(fml, data = d, weights = wt, cluster = ~v2gestfips, fixef.rm = "none", lean = TRUE)

a1 <- est(h ~ v2unemp, cells)
a4 <- est(h ~ v2unemp | date + v2gestfips + demo2, cells)
b1 <- est(h ~ young + youngurate + oldurate, cells)
b4 <- est(h ~ young + youngurate + oldurate | date + v2gestfips + demo2, cells)
t2e <- est(h ~ young + youngurate + oldurate | date + v2gestfips + demo2, cells[grp == 1L])
t2u <- est(h ~ young + youngurate + oldurate | date + v2gestfips + demo2, cells[grp == 2L])
t2n <- est(h ~ young + youngurate + oldurate | date + v2gestfips + demo2, cells[grp == 3L])
cat("secs after hiring regs", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "\n")

wg <- feols(lw ~ young + youngurate + oldurate | v2gestfips + date + demo2 + occ + ind, data = w,
            weights = ~weight, cluster = ~v2gestfips, fixef.rm = "none", lean = TRUE)
cat("wage N:", nobs(wg), "\n")

for (m in list(a1, a4, b1, b4, t2e, t2u, t2n, wg)) print(coeftable(m))
cat("total secs", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "\n")

r <- function(nm, v) cat(sprintf("RESULT:%s=%.6g\n", nm, v))
r("young_x_unemp_rate_no_controls", coef(b1)["youngurate"])
r("experienced_x_unemp_rate_no_controls", coef(b1)["oldurate"])
r("young_x_unemp_rate_preferred", coef(b4)["youngurate"])
r("experienced_x_unemp_rate_preferred", coef(b4)["oldurate"])
r("aggregate_unemp_rate_no_controls", coef(a1)["v2unemp"])
r("aggregate_unemp_rate_month_year_fe", coef(a4)["v2unemp"])
r("young_x_unemp_rate_employed", coef(t2e)["youngurate"])
r("experienced_x_unemp_rate_employed", coef(t2e)["oldurate"])
r("young_x_unemp_rate_unemployed", coef(t2u)["youngurate"])
r("young_x_unemp_rate_nilf", coef(t2n)["youngurate"])
r("wage_young_x_unemp_rate_all_hires", coef(wg)["youngurate"])
r("wage_experienced_x_unemp_rate_all_hires", coef(wg)["oldurate"])
cat(sprintf("RESULT:n_obs_full_sample=%d\n", as.integer(N_full)))
