# Forsythe (2022) "Why Don't Firms Hire Young Workers During Recessions?"
# Independent, blind reproduction of Table 1 (A,B), Table 2, Table 10 Panel B col 1.
suppressMessages({library(data.table); library(fixest)})
setDTthreads(1); setFixest_nthreads(1)
set.seed(42)
T0 <- Sys.time(); el <- function() round(as.numeric(difftime(Sys.time(), T0, units = "secs")), 1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"

# ---- read only needed columns of the 2 GB matched-pair file ----
cc <- c(peage="integer", pesex="integer", peeduca="integer", race="integer", prhspnon="integer",
        pehspnon="integer", pemlr="integer", pwsswgt="numeric", v2hrmonth="integer", v2hryear="integer",
        v2gestfips="integer", v2pemlr="integer", v2puiodp1="integer", v2peio1cow="integer",
        v2peio1icd="integer", v2peio1ocd="integer", v2prernwa="numeric", v2prwernal="integer",
        v2pwsswgt="numeric")
x <- fread(file.path(D, "yh_data.csv"), select = cc, showProgress = FALSE)
cat("read done", el(), "s; rows", nrow(x), "\n")

# ---- dates (month t = second month of the pair) ----
x[v2hryear < 100L, v2hryear := v2hryear + 1900L]
x[, ym := v2hryear * 12L + v2hrmonth]
# sample: interviews Jan 1994 - Sep 2016 (t-1 >= Jan 1994 holds by construction), civilians 16+,
# non-missing age & education & labour force status in both months
keep <- x$ym <= 2016L * 12L + 9L & x$peage >= 16L & x$peeduca >= 31L & x$peeduca <= 46L &
        x$pemlr >= 1L & x$v2pemlr >= 1L & !is.na(x$v2gestfips)
x <- x[keep]; rm(keep); gc(verbose = FALSE)

# ---- variables ----
edyrs <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)  # peeduca 31..46
x[, young := as.integer((peage - edyrs[peeduca - 30L] - 6) <= 10)]
ed7 <- c(rep(1L, 8), 2L, 3L, 3L, 3L, 4L, 5L, 6L, 7L)
x[, hisp := as.integer(fcoalesce(prhspnon, pehspnon) == 1L)]
x[is.na(hisp), hisp := 0L]
x[, demo := ((pesex - 1L) * 2L + as.integer(race == 1L)) * 2L * 7L + hisp * 7L + ed7[peeduca - 30L]]
x[, prev := fifelse(pemlr <= 2L, 1L, fifelse(pemlr <= 4L, 2L, 3L))]   # 1 E, 2 U, 3 NILF in t-1
x[, hired := as.integer(v2pemlr <= 2L & (pemlr > 2L | v2puiodp1 == 2L) & !(v2peio1cow %in% c(6L, 7L)))]
x[, w := (pwsswgt + v2pwsswgt) / 2]
x[, c("prhspnon", "pehspnon", "race", "pesex", "pwsswgt", "v2pwsswgt", "v2puiodp1", "v2peio1cow") := NULL]

u <- fread(file.path(D, "v2unemp_smy.csv"))
u[v2hryear < 100L, v2hryear := v2hryear + 1900L]
u[, ym := v2hryear * 12L + v2hrmonth]
x[u, U := i.v2unemp_smy, on = .(v2gestfips, ym)]
cat("missing U:", sum(is.na(x$U)), "\n")
x <- x[!is.na(U)]

# ---- wage sample (new hires, non-allocated weekly wage) ----
wg <- x[hired == 1L & !is.na(v2prernwa) & v2prernwa > 0 & v2prwernal == 0L,
        .(v2hryear, v2hrmonth, ym, v2gestfips, demo, young, U, w, v2prernwa, v2peio1icd, v2peio1ocd)]
x[, c("v2prernwa", "v2prwernal", "v2peio1icd", "v2peio1ocd", "peage", "peeduca", "pemlr", "v2pemlr",
      "v2hryear", "v2hrmonth") := NULL]
gc(verbose = FALSE)

N_full <- nrow(x)
cat("full sample N", N_full, "; prep done", el(), "s\n")

# ---- collapse to cells: coefficients from weighted OLS on cell means with cell weight sums are
#      identical to person-level WLS because every regressor is constant within a cell ----
cl <- x[, .(W = sum(w), yb = 100 * sum(w * hired) / sum(w), n = .N),
        by = .(v2gestfips, ym, demo, young, prev, U)]
rm(x); gc(verbose = FALSE)
cl[, old := 1L - young]
cat("cells", nrow(cl), "; collapse done", el(), "s\n")

est <- function(fml, d) feols(fml, data = d, weights = ~W, cluster = ~v2gestfips, lean = TRUE, notes = FALSE)
a1 <- est(yb ~ U, cl)
a4 <- est(yb ~ U | v2gestfips + demo + ym, cl)
b1 <- est(yb ~ young + young:U + old:U, cl)
b4 <- est(yb ~ young + young:U + old:U | v2gestfips + demo + ym, cl)
cE <- est(yb ~ young + young:U + old:U | v2gestfips + demo + ym, cl[prev == 1L])
cU <- est(yb ~ young + young:U + old:U | v2gestfips + demo + ym, cl[prev == 2L])
cN <- est(yb ~ young + young:U + old:U | v2gestfips + demo + ym, cl[prev == 3L])
cat("hiring regressions done", el(), "s\n")
for (m in list(a1, a4, b1, b4, cE, cU, cN)) print(coeftable(m))
cat("N check (sum of cell counts):", sum(cl$n), "\n")

# ---- wage regression: Table 10 Panel B col 1 ----
cpi <- fread(file.path(D, "wage_deflation_1994_2016.csv"))
wg[cpi, cpi := i.cpi, on = .(v2hryear = year, v2hrmonth = month)]
wg[, lw := log(v2prernwa / cpi)]
ox <- unique(fread(file.path(D, "occ_xwalk2002.csv")), by = c("v2peio1ocd", "v2occ_codeyear"))
ix <- unique(fread(file.path(D, "ind_xwalk2002.csv")), by = c("v2peio1icd", "v2ind_codeyear"))
wg[, occyr := fifelse(v2hryear <= 2002L, 1990L, fifelse(v2hryear <= 2010L, 2002L, 2010L))]
wg[, indyr := fifelse(v2hryear <= 2002L, 1990L, fifelse(v2hryear <= 2008L, 2002L, fifelse(v2hryear <= 2013L, 2007L, 2012L)))]
wg[ox, occ := i.v2censusocc_2002recode, on = .(v2peio1ocd, occyr = v2occ_codeyear)]
wg[ix, ind := i.v2censusind_2002recode, on = .(v2peio1icd, indyr = v2ind_codeyear)]
cat("wage sample", nrow(wg), "; missing occ", sum(is.na(wg$occ)), "; missing ind", sum(is.na(wg$ind)),
    "; missing cpi", sum(is.na(wg$cpi)), "\n")
wg[, old := 1L - young]
wv <- feols(lw ~ young + young:U + old:U | v2gestfips + demo + ym + occ + ind, data = wg,
            weights = ~w, cluster = ~v2gestfips, notes = FALSE)
print(coeftable(wv)); cat("wage N", nobs(wv), "\n")
cat("all done", el(), "s\n")

g <- function(m, nm) {
  cf <- coef(m); p <- strsplit(nm, ":")[[1]]
  k <- if (nm %in% names(cf)) nm else paste(rev(p), collapse = ":")
  unname(cf[k])
}
cat(sprintf("RESULT:young_x_unemp_rate_no_controls=%.6f\n", g(b1, "young:U")))
cat(sprintf("RESULT:experienced_x_unemp_rate_no_controls=%.6f\n", g(b1, "U:old")))
cat(sprintf("RESULT:young_x_unemp_rate_preferred=%.6f\n", g(b4, "young:U")))
cat(sprintf("RESULT:experienced_x_unemp_rate_preferred=%.6f\n", g(b4, "U:old")))
cat(sprintf("RESULT:aggregate_unemp_rate_no_controls=%.6f\n", g(a1, "U")))
cat(sprintf("RESULT:aggregate_unemp_rate_month_year_fe=%.6f\n", g(a4, "U")))
cat(sprintf("RESULT:young_x_unemp_rate_employed=%.6f\n", g(cE, "young:U")))
cat(sprintf("RESULT:experienced_x_unemp_rate_employed=%.6f\n", g(cE, "U:old")))
cat(sprintf("RESULT:young_x_unemp_rate_unemployed=%.6f\n", g(cU, "young:U")))
cat(sprintf("RESULT:young_x_unemp_rate_nilf=%.6f\n", g(cN, "young:U")))
cat(sprintf("RESULT:wage_young_x_unemp_rate_all_hires=%.6f\n", g(wv, "young:U")))
cat(sprintf("RESULT:wage_experienced_x_unemp_rate_all_hires=%.6f\n", g(wv, "U:old")))
cat(sprintf("RESULT:n_obs_full_sample=%d\n", N_full))
