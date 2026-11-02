suppressPackageStartupMessages({library(data.table); library(fixest)})
set.seed(42)
t0 <- Sys.time(); el <- function() round(as.numeric(difftime(Sys.time(), t0, units="secs")), 1)
base <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-02-b/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
cat("DEVIATION: yh_data.csv read with data.table::fread(select=) of the 20 needed columns only (2 GB file, 300 s / 4 GB sandbox)\n")
cols <- c("peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
d <- fread(paste0(base, "yh_data.csv"), select=cols, nThread=1, showProgress=FALSE)
cat("read done", el(), "rows", nrow(d), "\n")

# --- sample restrictions: civilians aged 16+, non-missing age/education (pemlr valid => employment data collected)
d <- d[!is.na(peage) & peage >= 16 & !is.na(peeduca) & peeduca >= 31 & pemlr %in% 1:7 & v2pemlr %in% 1:7]
d[, year := fifelse(v2hryear < 100L, v2hryear + 1900L, v2hryear)]; d[, v2hryear := NULL]
d[, ym := year * 100L + v2hrmonth]
# years of schooling from PEEDUCA
edyrs <- c(`31`=0,`32`=2.5,`33`=5.5,`34`=7.5,`35`=9,`36`=10,`37`=11,`38`=12,`39`=12,`40`=13,`41`=14,`42`=14,`43`=16,`44`=18,`45`=20,`46`=20)
d[, pe := peage - edyrs[as.character(peeduca)] - 6]
d[, young := as.integer(pe <= 10)]
d[, educ7 := fcase(peeduca <= 38L, 1L, peeduca == 39L, 2L, peeduca <= 42L, 3L, peeduca == 43L, 4L,
                   peeduca == 44L, 5L, peeduca == 45L, 6L, peeduca == 46L, 7L)]
d[, hisp := as.integer(fcoalesce(prhspnon, pehspnon) == 1L)]; d[is.na(hisp), hisp := 0L]
d[, demo := ((pesex - 1L) * 2L + as.integer(race == 1L)) * 2L * 7L + hisp * 7L + educ7]
d[, c("pe","peage","peeduca","pesex","race","prhspnon","pehspnon","educ7","hisp") := NULL]
# --- hire definition
d[, emp_t := v2pemlr %in% 1:2]
d[, notself := !(v2peio1cow %in% 6:7)]
d[, status := fcase(pemlr %in% 1:2, 1L, pemlr %in% 3:4, 2L, default = 3L)]  # 1 Emp, 2 Unemp, 3 NILF in t-1
d[, hired := 100 * as.integer(emp_t & notself & (status != 1L | (status == 1L & v2puiodp1 %in% 2L)))]
d[, w := (pwsswgt + v2pwsswgt) / 2]
d[, c("pwsswgt","v2pwsswgt","v2pemlr","pemlr","emp_t","notself","v2puiodp1","v2peio1cow") := NULL]
# --- state unemployment rate in month t
ur <- fread(paste0(base, "v2unemp_smy.csv"))
setnames(ur, c("v2gestfips","v2unemp_smy","v2hryear","v2hrmonth"), c("st","ur","year","mo"))
ur[, ym := year * 100L + mo]
d[ur, urate := i.ur, on = .(v2gestfips = st, ym = ym)]
cat("missing urate", sum(is.na(d$urate)), "\n")
d <- d[!is.na(urate) & !is.na(w) & w > 0]
cat("prep done", el(), "\n")
n_full <- nrow(d)
cat("weighted mean hired", d[, weighted.mean(hired, w)], " young", d[young==1, weighted.mean(hired, w)], " exp", d[young==0, weighted.mean(hired, w)], "\n")
cat("share of hires by t-1 status:\n"); print(d[hired > 0, .(sw = sum(w)), by=status][, .(status, share = sw/sum(sw))])

# --- wage sample (new hires, non-allocated weekly earnings)
wg <- d[hired > 0 & v2prwernal %in% 0L & !is.na(v2prernwa) & v2prernwa > 0]
d[, c("v2prernwa","v2prwernal","v2peio1icd","v2peio1ocd") := NULL]

# --- collapse to cells: all regressors are constant within state x month x PE group x demo x status
cells <- d[, .(ybar = sum(w * hired) / sum(w), sw = sum(w), n = .N), by = .(v2gestfips, ym, young, demo, status, urate)]
rm(d); invisible(gc())
cat("cells", nrow(cells), "collapse done", el(), "\n")
cells[, `:=`(ur_y = urate * young, ur_o = urate * (1L - young))]

run <- function(fml, dat) feols(fml, data = dat, weights = ~sw, cluster = ~v2gestfips, notes = FALSE)
cA <- cells[, .(ybar = sum(sw * ybar) / sum(sw), sw = sum(sw)), by = .(v2gestfips, ym, demo, urate)]
mA1 <- run(ybar ~ urate, cA)
mA4 <- run(ybar ~ urate | v2gestfips + demo + ym, cA)
cB <- cells[, .(ybar = sum(sw * ybar) / sum(sw), sw = sum(sw)), by = .(v2gestfips, ym, demo, young, urate, ur_y, ur_o)]
mB1 <- run(ybar ~ young + ur_y + ur_o, cB)
mB4 <- run(ybar ~ young + ur_y + ur_o | v2gestfips + demo + ym, cB)
mE <- run(ybar ~ young + ur_y + ur_o | v2gestfips + demo + ym, cells[status == 1L])
mU <- run(ybar ~ young + ur_y + ur_o | v2gestfips + demo + ym, cells[status == 2L])
mN <- run(ybar ~ young + ur_y + ur_o | v2gestfips + demo + ym, cells[status == 3L])
cat("regs done", el(), "\n")
cat("NOTE: hiring regressions estimated on cell means with summed weights (identical WLS point estimates; SEs below are cell-level, not individual-level)\n")
for (m in list(mA1, mA4, mB1, mB4, mE, mU, mN)) print(coeftable(m))

# --- wage regression
cpi <- fread(paste0(base, "wage_deflation_1994_2016.csv"))
wg[cpi, cpi := i.cpi, on = .(year = year, v2hrmonth = month)]
wg[, lw := log(v2prernwa / cpi)]
ox <- unique(fread(paste0(base, "occ_xwalk2002.csv")), by = c("v2peio1ocd","v2occ_codeyear"))
ix <- unique(fread(paste0(base, "ind_xwalk2002.csv")), by = c("v2peio1icd","v2ind_codeyear"))
wg[, occyr := fifelse(year <= 2002L, 1990L, fifelse(year <= 2010L, 2002L, 2010L))]
wg[, indyr := fifelse(year <= 2002L, 1990L, fifelse(year <= 2008L, 2002L, fifelse(year <= 2013L, 2007L, 2012L)))]
wg[ox, occ := i.v2censusocc_2002recode, on = .(v2peio1ocd = v2peio1ocd, occyr = v2occ_codeyear)]
wg[ix, ind := i.v2censusind_2002recode, on = .(v2peio1icd = v2peio1icd, indyr = v2ind_codeyear)]
cat("wage sample", nrow(wg), "missing occ", sum(is.na(wg$occ)), "missing ind", sum(is.na(wg$ind)), "missing cpi", sum(is.na(wg$cpi)), "\n")
wg[, `:=`(ur_y = urate * young, ur_o = urate * (1L - young))]
mW <- feols(lw ~ young + ur_y + ur_o | v2gestfips + demo + ym + occ + ind, data = wg, weights = ~w, cluster = ~v2gestfips, notes = FALSE)
print(coeftable(mW)); cat("wage nobs", nobs(mW), "\n")

cat("young base", cB[young==1, weighted.mean(ybar, sw)], "\n")
out <- c(
  young_x_unemp_rate_no_controls = coef(mB1)[["ur_y"]],
  experienced_x_unemp_rate_no_controls = coef(mB1)[["ur_o"]],
  young_x_unemp_rate_preferred = coef(mB4)[["ur_y"]],
  experienced_x_unemp_rate_preferred = coef(mB4)[["ur_o"]],
  aggregate_unemp_rate_no_controls = coef(mA1)[["urate"]],
  aggregate_unemp_rate_month_year_fe = coef(mA4)[["urate"]],
  young_x_unemp_rate_employed = coef(mE)[["ur_y"]],
  experienced_x_unemp_rate_employed = coef(mE)[["ur_o"]],
  young_x_unemp_rate_unemployed = coef(mU)[["ur_y"]],
  young_x_unemp_rate_nilf = coef(mN)[["ur_y"]],
  wage_young_x_unemp_rate_all_hires = coef(mW)[["ur_y"]],
  wage_experienced_x_unemp_rate_all_hires = coef(mW)[["ur_o"]])
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
cat(sprintf("RESULT:n_obs_full_sample=%d\n", n_full))
cat("total secs", el(), "\n")
