# Independent, blind reproduction: Forsythe (2022), "Why Don't Firms Hire Young Workers During Recessions?"
# Built from the paper text and the data's column names only.
#
# Computational note: reading the 2 GB CSV through the sandbox's file sharing takes most of the 300 s limit,
# so the hiring regressions (Tables 1-2) are estimated on cells (state x month-year x demographic cell x
# young x labour-force status in t-1) using the CPS-weighted mean of the hired indicator with the cell's summed
# weight as the regression weight. All regressors and fixed effects are constant within a cell, so the WLS point
# estimates are identical to the person-level regression, and the state-clustered score sums are identical too
# (only the CR1 small-sample factor uses the cell count). The wage regression (Table 10) is person-level.
suppressPackageStartupMessages({library(data.table); library(fixest)})
setDTthreads(1); setFixest_nthreads(1)
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
NROWS <- 3e6   # CODE TEST on the first 3M rows only: prints no estimates and no RESULT lines
t0 <- proc.time()
cols <- c("hrmonth","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2prwernal","v2pwsswgt")
x <- fread(paste0(D, "yh_data.csv"), select = cols, nThread = 1, showProgress = FALSE, nrows = NROWS)
cat("read", (proc.time() - t0)[c(1, 3)], "rows", nrow(x), "\n"); flush(stdout())

fy <- function(y) fifelse(y < 100L, fifelse(y >= 90L, 1900L + y, 2000L + y), y)
x[, yr := fy(v2hryear)]

# ---- sample restrictions ----
# consecutive months (pairs across the 8-month rotation break are not consecutive);
# interviews Jan 1994 - Sep 2016 (month t <= Sep 2016); May-Aug 1995 have no longitudinal link;
# civilians age 16+ with non-missing age/education, in the labour-force universe in both months
keep <- with(x, ((v2hrmonth == hrmonth + 1L) | (v2hrmonth == 1L & hrmonth == 12L)) &
               yr >= 1994L & (yr < 2016L | v2hrmonth <= 9L) & !(yr == 1995L & hrmonth %in% 5:8) &
               peage >= 16L & pemlr %in% 1:7 & v2pemlr %in% 1:7 & peeduca %in% 31:46 & !is.na(v2gestfips))

# ---- variables ----
# potential experience = age - years of schooling (from PEEDUCA) - 6; young = PE <= 10
ed_years <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)
x[, young := as.integer(peage - ed_years[peeduca - 30L] - 6 <= 10)]
# demographic cells: sex x white x Hispanic x 7 education levels
x[, demo := pesex * 1000L + as.integer(race == 1L) * 100L +
      as.integer(!is.na(fcoalesce(pehspnon, prhspnon)) & fcoalesce(pehspnon, prhspnon) == 1L) * 10L +
      fifelse(peeduca <= 38L, 1L, fifelse(peeduca == 39L, 2L, fifelse(peeduca <= 42L, 3L, peeduca - 39L)))]
# weight: average of the CPS weights in the two months
x[, w := (pwsswgt + v2pwsswgt) / 2]
# hired (x100): employed at t, not self-employed, and either non-employed at t-1, or employed at t-1 and
# reporting no longer working for last month's employer
x[, hired := 100 * as.integer(v2pemlr %in% 1:2 & !(v2peio1cow %in% 6:7) & (!(pemlr %in% 1:2) | v2puiodp1 == 2L))]
# labour-force status at t-1: 1 employed, 2 unemployed, 3 NILF
x[, status0 := fifelse(pemlr %in% 1:2, 1L, fifelse(pemlr %in% 3:4, 2L, 3L))]

cells <- x[keep, .(n = .N, W = sum(w), yw = sum(hired * w)), by = .(v2gestfips, yr, v2hrmonth, demo, young, status0)]
h <- x[keep & hired > 0 & !is.na(v2prernwa) & v2prernwa > 0 & !is.na(v2prwernal) & v2prwernal == 0L,
       .(v2gestfips, yr, v2hrmonth, demo, young, w, v2prernwa, v2peio1icd, v2peio1ocd)]
rm(x, keep); gc()
cat("collapsed", (proc.time() - t0)[c(1, 3)], " cells", nrow(cells), " persons", sum(cells$n), " wage hires", nrow(h), "\n")
flush(stdout())

# state unemployment rate, month t
u <- fread(paste0(D, "v2unemp_smy.csv"))
u[, yr := fy(v2hryear)]
cells[u, urate := i.v2unemp_smy, on = c("v2gestfips", "yr", "v2hrmonth")]
h[u, urate := i.v2unemp_smy, on = c("v2gestfips", "yr", "v2hrmonth")]
cat("missing urate: cells", sum(is.na(cells$urate)), " wage", sum(is.na(h$urate)), "\n")
cells <- cells[!is.na(urate) & W > 0]
cells[, ym := yr * 100L + v2hrmonth]
cells[, `:=`(ybar = yw / W, u_y = urate * young, u_o = urate * (1L - young))]
c1 <- cells[, .(n = sum(n), W = sum(W), yw = sum(yw)), by = .(v2gestfips, ym, demo, young, urate, u_y, u_o)]
c1[, ybar := yw / W]
cat("N full sample", sum(c1$n), " hire rate", c1[, sum(yw) / sum(W)],
    " young", c1[young == 1L, sum(yw) / sum(W)], " exp", c1[young == 0L, sum(yw) / sum(W)], "\n")
hs <- cells[, .(s = sum(yw)), by = status0][, s := s / sum(s)][order(status0)]
cat("hire shares by t-1 status (1=E,2=U,3=N):", hs$s, "\n"); flush(stdout())

cl <- ~v2gestfips
show <- function(m) { if (is.finite(NROWS)) return(invisible()); print(coeftable(m)); flush(stdout()) }
res <- function(name, val, fmt = "%.6f") {
  if (is.finite(NROWS)) return(invisible())   # code test on a row subset: no RESULT lines
  cat(sprintf(paste0("RESULT:%s=", fmt, "\n"), name, val)); flush(stdout())
}
r <- function(m, v) unname(coef(m)[v])

# ---- Table 1 ----
res("n_obs_full_sample", sum(c1$n), "%d")
a1 <- feols(ybar ~ urate, c1, weights = ~W, cluster = cl); show(a1)
b1 <- feols(ybar ~ young + u_y + u_o, c1, weights = ~W, cluster = cl); show(b1)
m4 <- feols(ybar ~ sw(young + u_y + u_o, urate) | v2gestfips + demo + ym, c1, weights = ~W, cluster = cl)
b4 <- m4[[1]]; a4 <- m4[[2]]; show(b4); show(a4)
res("aggregate_unemp_rate_no_controls", r(a1, "urate"))
res("young_x_unemp_rate_no_controls", r(b1, "u_y"))
res("experienced_x_unemp_rate_no_controls", r(b1, "u_o"))
res("young_x_unemp_rate_preferred", r(b4, "u_y"))
res("experienced_x_unemp_rate_preferred", r(b4, "u_o"))
res("aggregate_unemp_rate_month_year_fe", r(a4, "urate"))
# ---- Table 2: by labour-force status in t-1 ----
t2 <- feols(ybar ~ young + u_y + u_o | v2gestfips + demo + ym, cells, weights = ~W, cluster = cl, split = ~status0)
t2e <- t2[[1]]; t2u <- t2[[2]]; t2n <- t2[[3]]; show(t2e); show(t2u); show(t2n)
cat("N by status:", cells[, sum(n), by = status0][order(status0)]$V1, "\n")
res("young_x_unemp_rate_employed", r(t2e, "u_y"))
res("experienced_x_unemp_rate_employed", r(t2e, "u_o"))
res("young_x_unemp_rate_unemployed", r(t2u, "u_y"))
res("young_x_unemp_rate_nilf", r(t2n, "u_y"))
cat("time after T2", (proc.time() - t0)[c(1, 3)], "\n"); flush(stdout())

# ---- Table 10: log real weekly wage (non-allocated, 1994 dollars) of new hires ----
cpi <- fread(paste0(D, "wage_deflation_1994_2016.csv"))
h[cpi, cpi := i.cpi, on = c(yr = "year", v2hrmonth = "month")]
h <- h[!is.na(urate)]
h[, `:=`(lnw = log(v2prernwa / cpi), ym = yr * 100L + v2hrmonth, u_y = urate * young, u_o = urate * (1L - young))]
# consistent 2002 Census industry/occupation codes; code vintage by survey date
ix <- unique(fread(paste0(D, "ind_xwalk2002.csv")), by = c("v2peio1icd", "v2ind_codeyear"))
ox <- unique(fread(paste0(D, "occ_xwalk2002.csv")), by = c("v2peio1ocd", "v2occ_codeyear"))
h[, ind_cy := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2008L, 2002L, fifelse(yr <= 2013L, 2007L, 2012L)))]
h[, occ_cy := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2010L, 2002L, 2010L))]
h[ix, ind02 := i.v2censusind_2002recode, on = c(v2peio1icd = "v2peio1icd", ind_cy = "v2ind_codeyear")]
h[ox, occ02 := i.v2censusocc_2002recode, on = c(v2peio1ocd = "v2peio1ocd", occ_cy = "v2occ_codeyear")]
cat("wage hires", nrow(h), " missing ind", sum(is.na(h$ind02)), " missing occ", sum(is.na(h$occ02)), "\n")
wg <- feols(lnw ~ young + u_y + u_o | v2gestfips + demo + ym + occ02 + ind02, h, weights = ~w, cluster = cl); show(wg)
cat("wage N", nobs(wg), "\n")
res("wage_young_x_unemp_rate_all_hires", r(wg, "u_y"))
res("wage_experienced_x_unemp_rate_all_hires", r(wg, "u_o"))
cat("total", (proc.time() - t0)[1:3], "\n")
