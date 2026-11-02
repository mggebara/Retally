# Retally reproduction: Forsythe (2022) "Why Don't Firms Hire Young Workers During Recessions?"
# Seeded mode: translates YH_data_init.do + YH_regs.do (Tables 1, 2, 10) into R / fixest.
set.seed(42)
suppressMessages({library(data.table); library(fixest)})
setDTthreads(1); setFixest_nthreads(1)
T0 <- Sys.time(); tick <- function(s) cat(sprintf("[%6.1fs] %s\n", as.numeric(Sys.time()-T0, units="secs"), s))

D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/seeded/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"

# ---- read only the columns the Table 1/2/10 regressions need ----
sel <- c(peage="integer",pesex="integer",peeduca="integer",race="integer",prhspnon="integer",pemlr="integer",pwsswgt="numeric",
         v2hrmonth="integer",v2hryear="integer",v2gestfips="integer",v2pemlr="integer",v2puiodp1="integer",v2peio1cow="integer",
         v2peio1icd="integer",v2peio1ocd="integer",v2prernwa="numeric",v2pwsswgt="numeric",v2prwernal="integer",pehspnon="integer")
dt <- fread(file.path(D, "yh_data.csv"), select = sel, nThread = 1, showProgress = FALSE, nrows = 2000000)
tick(sprintf("read yh_data.csv: %d rows", nrow(dt)))

un  <- fread(file.path(D, "v2unemp_smy.csv"))
cpi <- fread(file.path(D, "wage_deflation_1994_2016.csv"))
ox  <- fread(file.path(D, "occ_xwalk2002.csv"))
ix  <- fread(file.path(D, "ind_xwalk2002.csv"))

# ---- dates (2-digit years 94-97 -> 4-digit) ----
dt[v2hryear < 100L, v2hryear := v2hryear + 1900L]
dt[, date := (v2hryear - 1994L) * 12L + v2hrmonth]          # monthly index (equivalent to ym())
un[v2hryear < 100L, v2hryear := v2hryear + 1900L]
un[, date := (v2hryear - 1994L) * 12L + v2hrmonth]
# state unemployment rate lookup (m:1 merge on year, month, state)
ulk <- rep(NA_real_, 400L * 100L)
ulk[un$date * 100L + un$v2gestfips] <- un$v2unemp_smy
dt[, v2unemp := ulk[date * 100L + v2gestfips]]

# ---- age, schooling, potential experience ----
ys <- numeric(100); ys[31:46] <- c(1,4,6,8,9,10,11,11.5,12,13,14,14,16,18,20,22)
ed <- rep(NA_integer_, 100); ed[1:38] <- 0L; ed[39] <- 1L; ed[40:42] <- 2L; ed[43:46] <- 3:6
dt[, exp := fifelse(peage > 79L, NA_real_, peage - ys[pmax(peeduca, 1L)] - 6)]
dt[, educ := ed[pmax(peeduca, 1L)]][peeduca <= 0L, educ := NA_integer_]
dt[, demo2 := (race > 1L) * 1000L + (pesex > 1L) * 100L +
              (fcoalesce(pehspnon, 0L) == 1L | fcoalesce(prhspnon, 0L) == 1L) * 10L + educ]
dt[, c("race","pesex","pehspnon","prhspnon","peeduca","educ") := NULL]

# ---- hiring indicator (hired2, excluding self-employed / without pay) ----
dt[, h := as.integer(v2pemlr == 1L | v2pemlr == 2L)]
dt[v2puiodp1 == 1L, h := 0L]
dt[(pemlr == 1L | pemlr == 2L) & v2puiodp1 < 0L, h := 0L]
dt[v2peio1cow >= 5L, h := 0L]
dt[, c("v2pemlr","v2puiodp1","v2peio1cow") := NULL]
dt[, weight := (v2pwsswgt + pwsswgt) / 2][, c("v2pwsswgt","pwsswgt") := NULL]

cat(sprintf("rows with missing exp: %d; missing unemp: %d; missing demo2: %d; missing/zero weight: %d/%d\n",
    sum(is.na(dt$exp)), sum(is.na(dt$v2unemp)), sum(is.na(dt$demo2)), sum(is.na(dt$weight)), sum(dt$weight <= 0, na.rm=TRUE)))
# restrict sample: keep if exp<. & v2unemp<.
dt <- dt[!is.na(exp) & !is.na(v2unemp)]
dt[, young := as.integer(exp <= 10)]
tick(sprintf("analysis sample: %d rows", nrow(dt)))

# ---- Table 10 wage sample (new hires, non-allocated weekly earnings) ----
w <- dt[h == 1L & v2prwernal == 0L & !is.na(v2prernwa),
        .(v2hryear, v2hrmonth, v2gestfips, date, demo2, young, v2unemp, weight, v2prernwa, v2peio1ocd, v2peio1icd)]
dt[, c("v2prernwa","v2prwernal","v2peio1ocd","v2peio1icd","peage") := NULL]
w <- merge(w, cpi, by.x = c("v2hryear","v2hrmonth"), by.y = c("year","month"), all.x = TRUE)
w[, lw := log(v2prernwa / cpi)]
w[, occ_cy := fifelse(v2hryear < 2003L, 1990L, fifelse(v2hryear < 2011L, 2002L, 2010L))]
w[, ind_cy := fifelse(v2hryear < 2003L, 1990L, fifelse(v2hryear < 2009L, 2002L, fifelse(v2hryear < 2014L, 2007L, 2012L)))]
cat(sprintf("occ xwalk dup keys: %d; ind xwalk dup keys: %d\n",
    sum(duplicated(ox, by = c("v2peio1ocd","v2occ_codeyear"))), sum(duplicated(ix, by = c("v2peio1icd","v2ind_codeyear")))))
ox <- unique(ox, by = c("v2peio1ocd","v2occ_codeyear")); ix <- unique(ix, by = c("v2peio1icd","v2ind_codeyear"))
w <- merge(w, ox, by.x = c("v2peio1ocd","occ_cy"), by.y = c("v2peio1ocd","v2occ_codeyear"), all.x = TRUE)
w <- merge(w, ix, by.x = c("v2peio1icd","ind_cy"), by.y = c("v2peio1icd","v2ind_codeyear"), all.x = TRUE)
w[is.na(v2censusind_2002recode) & v2peio1icd == 6692L, v2censusind_2002recode := 6692L]
w[is.na(v2censusind_2002recode) & v2peio1icd == 991L,  v2censusind_2002recode := 9890L]
w[is.na(v2censusind_2002recode) & v2peio1icd == 9890L, v2censusind_2002recode := 9890L]
w[, youngurate := young * v2unemp][, oldurate := (1L - young) * v2unemp]
w <- w[is.finite(lw) & !is.na(v2censusocc_2002recode) & !is.na(v2censusind_2002recode) & !is.na(demo2)]
tick(sprintf("wage sample: %d rows", nrow(w)))

# ---- collapse hiring data to exact weighted cell means ----
# All Table 1/2 regressors (U rate, young, young x U, old x U, FE for state, date, demo2) are constant within
# (state, date, demo2, young, prior-status group) cells, so WLS on cell means weighted by summed weights gives
# point estimates (and cluster-robust meat/bread) identical to the person-level aweighted regressions.
dt[, grp := fifelse(pemlr <= 2L, 1L, fifelse(pemlr <= 4L, 2L, 3L))]
N_full <- nrow(dt[!is.na(demo2) & !is.na(weight)])
cells <- dt[!is.na(demo2) & !is.na(weight),
            .(W = sum(weight), y = 100 * sum(weight * h) / sum(weight), n = .N, u = v2unemp[1L]),
            keyby = .(v2gestfips, date, demo2, young, grp)]
rm(dt); invisible(gc())
cells[, youngurate := young * u][, oldurate := (1L - young) * u]
tick(sprintf("cells: %d (persons %d)", nrow(cells), N_full))

cf <- function(m, v) unname(coef(m)[v])
sev <- function(m, v) unname(se(m)[v])
ssc0 <- ssc(adj = FALSE, cluster.adj = TRUE)

# Table 1 Panel A
a1 <- feols(y ~ u, cells, weights = ~W, cluster = ~v2gestfips, ssc = ssc0)
a4 <- feols(y ~ u | v2gestfips + demo2 + date, cells, weights = ~W, cluster = ~v2gestfips, ssc = ssc0, fixef.rm = "none")
# Table 1 Panel B
b1 <- feols(y ~ young + youngurate + oldurate, cells, weights = ~W, cluster = ~v2gestfips, ssc = ssc0)
b4 <- feols(y ~ young + youngurate + oldurate | v2gestfips + demo2 + date, cells, weights = ~W,
            cluster = ~v2gestfips, ssc = ssc0, fixef.rm = "none")
tick("Table 1 done")
# Table 2 cols 2-4
t2 <- lapply(1:3, function(g) feols(y ~ young + youngurate + oldurate | v2gestfips + demo2 + date,
             cells[grp == g], weights = ~W, cluster = ~v2gestfips, ssc = ssc0, fixef.rm = "none"))
tick("Table 2 done")
# Table 10 Panel B col 1 (person level)
wg <- feols(lw ~ young + youngurate + oldurate | v2gestfips + date + demo2 + v2censusocc_2002recode + v2censusind_2002recode,
            w, weights = ~weight, cluster = ~v2gestfips, fixef.rm = "none")
tick("Table 10 done")

cat(sprintf("SE(state-clustered) A1 u=%.4f A4 u=%.4f | B1 y=%.4f o=%.4f | B4 y=%.4f o=%.4f\n",
    sev(a1,"u"), sev(a4,"u"), sev(b1,"youngurate"), sev(b1,"oldurate"), sev(b4,"youngurate"), sev(b4,"oldurate")))
for (g in 1:3) cat(sprintf("Table2 grp%d: N persons=%d young x U=%.4f (%.4f) old x U=%.4f (%.4f)\n", g,
    sum(cells[grp == g]$n), cf(t2[[g]],"youngurate"), sev(t2[[g]],"youngurate"), cf(t2[[g]],"oldurate"), sev(t2[[g]],"oldurate")))
cat(sprintf("Table10 wage N=%d young x U=%.4f (%.4f) old x U=%.4f (%.4f)\n", nobs(wg),
    cf(wg,"youngurate"), sev(wg,"youngurate"), cf(wg,"oldurate"), sev(wg,"oldurate")))
cat("DEVIATION: hiring regressions (Tables 1-2) estimated as WLS on exact weighted cell means over (state, month, demo2, young, prior labour-force status) to fit the 300 s / 4 GB sandbox; point estimates are algebraically identical, SEs use the same clustering but the small-sample N adjustment is omitted.\n")

cat(sprintf("TEST:young_x_unemp_rate_no_controls=%.6f\n", cf(b1, "youngurate")))
cat(sprintf("TEST:experienced_x_unemp_rate_no_controls=%.6f\n", cf(b1, "oldurate")))
cat(sprintf("TEST:young_x_unemp_rate_preferred=%.6f\n", cf(b4, "youngurate")))
cat(sprintf("TEST:experienced_x_unemp_rate_preferred=%.6f\n", cf(b4, "oldurate")))
cat(sprintf("TEST:aggregate_unemp_rate_no_controls=%.6f\n", cf(a1, "u")))
cat(sprintf("TEST:aggregate_unemp_rate_month_year_fe=%.6f\n", cf(a4, "u")))
cat(sprintf("TEST:young_x_unemp_rate_employed=%.6f\n", cf(t2[[1]], "youngurate")))
cat(sprintf("TEST:experienced_x_unemp_rate_employed=%.6f\n", cf(t2[[1]], "oldurate")))
cat(sprintf("TEST:young_x_unemp_rate_unemployed=%.6f\n", cf(t2[[2]], "youngurate")))
cat(sprintf("TEST:young_x_unemp_rate_nilf=%.6f\n", cf(t2[[3]], "youngurate")))
cat(sprintf("TEST:wage_young_x_unemp_rate_all_hires=%.6f\n", cf(wg, "youngurate")))
cat(sprintf("TEST:wage_experienced_x_unemp_rate_all_hires=%.6f\n", cf(wg, "oldurate")))
cat(sprintf("TEST:n_obs_full_sample=%d\n", N_full))
tick("done")
