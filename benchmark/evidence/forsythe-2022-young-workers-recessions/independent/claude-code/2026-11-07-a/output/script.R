## Independent reproduction: Forsythe (2022) "Why Don't Firms Hire Young Workers During Recessions?"
## Hiring LPM (Eq. 1) on matched consecutive-month CPS pairs, Jan 1994 - Sep 2016.
## Because every regressor in the hiring regressions (young indicator, state unemployment rate,
## state / demographic / month-year FE) is constant within state x month-year x demographic x
## young cells, the person-level WLS coefficients are reproduced exactly by WLS on cell means
## with weights equal to the summed person weights.  This keeps the run inside the time limit.
suppressMessages({library(data.table); library(fixest)})
set.seed(42)
setDTthreads(1)
message("start")
t0 <- Sys.time()
P <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
cols <- c("peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
icols <- setdiff(cols, c("pwsswgt", "v2pwsswgt", "v2prernwa"))
d <- fread(paste0(P, "yh_data.csv"), select = cols, nThread = 1, showProgress = FALSE,
           colClasses = list(integer = icols, numeric = c("pwsswgt", "v2pwsswgt", "v2prernwa")))
N_raw <- nrow(d)
message("read done, rows ", N_raw, "; missing state at t: ", sum(is.na(d$v2gestfips)))

## --- years / dates (month t = second month of the pair, "v2") ---
d[, yr2 := fifelse(v2hryear < 100L, v2hryear + 1900L, v2hryear)]

## --- sample restrictions ---
## (the file already holds only matched consecutive-month pairs; the May-Aug 1995 link gap and the
##  8-month rotation break are already absent from it)
d <- d[peage >= 16 & !is.na(peeduca) & peeduca > 0 & pemlr %in% 1:7 & v2pemlr %in% 1:7 & !is.na(v2gestfips)]
d[, v2hryear := NULL]

## --- education years and potential experience ---
edyrs <- c(`31`=0,`32`=2.5,`33`=5.5,`34`=7.5,`35`=9,`36`=10,`37`=11,`38`=12,`39`=12,`40`=13,`41`=14,`42`=14,
           `43`=16,`44`=18,`45`=18,`46`=21)
d <- d[peeduca %in% 31:46]
d[, educ := unname(edyrs)[peeduca - 30L]]
d[, pe := peage - educ - 6]
d[, young := as.integer(pe <= 10)]
d[, ed7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca <= 42, 3L, peeduca == 43, 4L,
                 peeduca == 44, 5L, peeduca == 45, 6L, peeduca == 46, 7L)]
d[, hisp := fifelse(!is.na(prhspnon) & prhspnon > 0, as.integer(prhspnon == 1), as.integer(!is.na(pehspnon) & pehspnon == 1))]
d[, white := as.integer(race == 1)]
d[, c("race", "prhspnon", "pehspnon", "peeduca") := NULL]
d[, demo := ed7 * 1000L + pesex * 100L + white * 10L + hisp]

## --- hires ---
d[, emp1 := pemlr %in% 1:2]
d[, emp2 := v2pemlr %in% 1:2]
d[, selfemp := !is.na(v2peio1cow) & v2peio1cow %in% 6:7]
d[, hired := 100 * as.integer(emp2 & !selfemp & (!emp1 | (emp1 & v2puiodp1 %in% 2L)))]
d[, status := fcase(emp1, 1L, pemlr %in% 3:4, 2L, default = 3L)]
d[, w := (pwsswgt + v2pwsswgt) / 2]
d[, c("pwsswgt", "v2pwsswgt", "pemlr", "v2pemlr", "v2puiodp1", "v2peio1cow", "emp1", "emp2", "selfemp", "pe", "educ", "ed7", "hisp", "white", "pesex", "peage") := NULL]
message("vars built")

## --- state unemployment rate (month t) ---
u <- fread(paste0(P, "v2unemp_smy.csv"))
d[u, ur := i.v2unemp_smy, on = .(v2gestfips, yr2 = v2hryear, v2hrmonth)]
d <- d[!is.na(ur) & !is.na(w) & w > 0]
d[, ym := yr2 * 100L + v2hrmonth]
N_full <- nrow(d)
message("sample: ", N_full)

## --- wage sample (new hires with non-allocated weekly earnings) ---
wg <- d[hired == 100 & !is.na(v2prernwa) & v2prernwa > 0 & !is.na(v2prwernal) & v2prwernal == 0]
wg <- wg[, .(v2gestfips, ym, yr2, v2hrmonth, demo, young, ur, w, status, v2prernwa, v2peio1icd, v2peio1ocd)]

## --- collapse hiring data to cells ---
cl <- d[, .(n = .N, sw = sum(w), hm = sum(w * hired)), by = .(v2gestfips, ym, demo, young, status, ur)]
cl[, hm := hm / sw]
rm(d); invisible(gc())

cs <- function(sub) {
  x <- sub[, .(n = sum(n), hm = sum(sw * hm) / sum(sw), sw = sum(sw)), by = .(v2gestfips, ym, demo, young, ur)]
  x[, `:=`(yur = young * ur, our = (1 - young) * ur)]
  x
}
all <- cs(cl)
co <- function(m, nm) unname(coef(m)[nm])

a1 <- feols(hm ~ ur, data = all, weights = ~sw)
a4 <- feols(hm ~ ur | v2gestfips + demo + ym, data = all, weights = ~sw)
b1 <- feols(hm ~ young + yur + our, data = all, weights = ~sw)
b4 <- feols(hm ~ young + yur + our | v2gestfips + demo + ym, data = all, weights = ~sw)
e  <- feols(hm ~ young + yur + our | v2gestfips + demo + ym, data = cs(cl[status == 1]), weights = ~sw)
un <- feols(hm ~ young + yur + our | v2gestfips + demo + ym, data = cs(cl[status == 2]), weights = ~sw)
nf <- feols(hm ~ young + yur + our | v2gestfips + demo + ym, data = cs(cl[status == 3]), weights = ~sw)
message("N emp/unemp/nilf: ", sum(cl[status==1]$n), " ", sum(cl[status==2]$n), " ", sum(cl[status==3]$n))

## --- wages ---
cpi <- fread(paste0(P, "wage_deflation_1994_2016.csv"))
wg[cpi, cpi := i.cpi, on = .(yr2 = year, v2hrmonth = month)]
wg[, lw := log(v2prernwa / cpi)]
## occupation / industry recoded to 2002 Census codes via the supplied crosswalks
wg[, occyr := fcase(yr2 <= 2002, 1990L, yr2 <= 2010, 2002L, default = 2010L)]
wg[, indyr := fcase(yr2 <= 2002, 1990L, yr2 <= 2008, 2002L, yr2 <= 2013, 2007L, default = 2012L)]
ox <- unique(fread(paste0(P, "occ_xwalk2002.csv")), by = c("v2peio1ocd", "v2occ_codeyear"))
ix <- unique(fread(paste0(P, "ind_xwalk2002.csv")), by = c("v2peio1icd", "v2ind_codeyear"))
wg[ox, occ := i.v2censusocc_2002recode, on = .(v2peio1ocd, occyr = v2occ_codeyear)]
wg[ix, ind := i.v2censusind_2002recode, on = .(v2peio1icd, indyr = v2ind_codeyear)]
wg[is.na(occ), occ := -v2peio1ocd]
wg[is.na(ind), ind := -v2peio1icd]
wg[, `:=`(yur = young * ur, our = (1 - young) * ur)]
wm <- feols(lw ~ young + yur + our | v2gestfips + demo + ym + occ + ind, data = wg, weights = ~w, cluster = ~v2gestfips)
message("wage N: ", nobs(wm))

out <- c(
  young_x_unemp_rate_no_controls = co(b1, "yur"),
  experienced_x_unemp_rate_no_controls = co(b1, "our"),
  young_x_unemp_rate_preferred = co(b4, "yur"),
  experienced_x_unemp_rate_preferred = co(b4, "our"),
  aggregate_unemp_rate_no_controls = co(a1, "ur"),
  aggregate_unemp_rate_month_year_fe = co(a4, "ur"),
  young_x_unemp_rate_employed = co(e, "yur"),
  experienced_x_unemp_rate_employed = co(e, "our"),
  young_x_unemp_rate_unemployed = co(un, "yur"),
  young_x_unemp_rate_nilf = co(nf, "yur"),
  wage_young_x_unemp_rate_all_hires = co(wm, "yur"),
  wage_experienced_x_unemp_rate_all_hires = co(wm, "our"),
  n_obs_full_sample = N_full)
message("N raw ", N_raw, " N used ", N_full)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6g\n", k, out[[k]]))
message("total: ", round(as.numeric(Sys.time() - t0, units = "secs")), "s")
