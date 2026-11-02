## Independent reproduction: Forsythe (2022) "Why Don't Firms Hire Young Workers During Recessions?"
suppressMessages({library(data.table); library(fixest)})
set.seed(42)
setFixest_nthreads(1)
t0 <- Sys.time()
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-b/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
cols <- c("hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
x <- fread(file.path(D, "yh_data.csv"), select = cols, showProgress = FALSE)
cat("DEVIATION: yh_data.csv (2 GB) read with data.table::fread(select=) restricted to the 20 columns needed, to fit the sandbox's 4 GB / 300 s limits\n")
cat("read secs", round(as.numeric(Sys.time() - t0, units = "secs")), "\n")

## Matched pairs: unprefixed vars = month t-1, v2 vars = month t
x[, yr := ifelse(v2hryear < 100L, 1900L + v2hryear + ifelse(v2hryear < 50L, 100L, 0L), v2hryear)]
x[, mo := v2hrmonth]
x[, c("hryear", "v2hryear", "v2hrmonth") := NULL]
## Sample: civilians with employment data (pemlr valid), non-missing age/education, state observed, age < 80 (CPS topcode)
x <- x[!is.na(v2gestfips) & pemlr >= 1L & peeduca > 0L & !is.na(peage) & peage < 80L]
## State monthly unemployment rate in month t
u <- fread(file.path(D, "v2unemp_smy.csv"))
setnames(u, c("v2gestfips", "urate", "yr", "mo"))
x <- merge(x, u, by = c("v2gestfips", "yr", "mo"), all.x = FALSE)
x[, ym := yr * 100L + mo]

## Potential experience = age - years of education - 6
ed <- c(`31`=0,`32`=2.5,`33`=5.5,`34`=7.5,`35`=9,`36`=10,`37`=11,`38`=12,`39`=12,`40`=13,`41`=14,`42`=14,`43`=16,`44`=18,`45`=20,`46`=20)
x[, pe := peage - ed[as.character(peeduca)] - 6]
x[, young := as.integer(pe <= 10)]
## Demographic cells: sex x white x Hispanic x 7 education groups
x[, educ7 := fcase(peeduca <= 38L, 1L, peeduca == 39L, 2L, peeduca <= 42L, 3L, peeduca == 43L, 4L,
                   peeduca == 44L, 5L, peeduca == 45L, 6L, peeduca == 46L, 7L)]
x[, hisp := as.integer(fifelse(!is.na(prhspnon), prhspnon == 1L, !is.na(pehspnon) & pehspnon == 1L))]
x[, demo := pesex * 1000L + as.integer(race == 1L) * 100L + hisp * 10L + educ7]
x[, c("pesex", "race", "prhspnon", "pehspnon", "peeduca") := NULL]
## Labour-market status in t-1
x[, st := fifelse(pemlr <= 2L, 1L, fifelse(pemlr <= 4L, 2L, 3L))]
## Hired in t: non-employed -> employed, or employed and changed employer; self-employment excluded
x[, hired := 100 * as.integer(!(v2peio1cow %in% 6:7) & v2pemlr %in% 1:2 &
                              (pemlr >= 3L | (pemlr <= 2L & v2puiodp1 == 2L)))]
x[, w := (pwsswgt + v2pwsswgt) / 2]
x[, c("pwsswgt", "v2pwsswgt", "v2pemlr", "v2puiodp1") := NULL]
N_full <- nrow(x)
cat("N full sample", N_full, " by status:", tabulate(x$st, 3), "\n")
cat("weighted hire rate all", x[, weighted.mean(hired, w)], "young", x[young == 1, weighted.mean(hired, w)],
    "exp", x[young == 0, weighted.mean(hired, w)], "\n")

## Wage sample (new hires, non-allocated weekly wage, real 1994 dollars)
wg <- x[hired > 0 & !is.na(v2prernwa) & v2prernwa > 0 & !is.na(v2prwernal) & v2prwernal == 0L]
x[, c("v2prernwa", "v2prwernal", "v2peio1icd", "v2peio1ocd", "v2peio1cow", "peage", "pe", "pemlr", "educ7", "hisp") := NULL]

## Hiring regressions: all regressors are constant within state x month x demo x PE-group (x status) cells,
## so WLS on cell means weighted by summed weights gives identical point estimates.
cl <- x[, .(hired = sum(hired * w) / sum(w), w = sum(w), n = .N), by = .(v2gestfips, ym, demo, young, st, urate)]
rm(x); invisible(gc())
cl[, old := 1L - young]
cat("cells", nrow(cl), "\n")
cla <- cl[, .(hired = sum(hired * w) / sum(w), w = sum(w)), by = .(v2gestfips, ym, demo, young, old, urate)]

a1 <- feols(hired ~ urate, cla, weights = ~w, cluster = ~v2gestfips)
a4 <- feols(hired ~ urate | v2gestfips + demo + ym, cla, weights = ~w, cluster = ~v2gestfips)
b1 <- feols(hired ~ young + young:urate + old:urate, cla, weights = ~w, cluster = ~v2gestfips)
b2 <- feols(hired ~ young + young:urate + old:urate | v2gestfips, cla, weights = ~w, cluster = ~v2gestfips)
b3 <- feols(hired ~ young + young:urate + old:urate | v2gestfips + demo, cla, weights = ~w, cluster = ~v2gestfips)
b4 <- feols(hired ~ young + young:urate + old:urate | v2gestfips + demo + ym, cla, weights = ~w, cluster = ~v2gestfips)
sub <- lapply(1:3, function(s) feols(hired ~ young + young:urate + old:urate | v2gestfips + demo + ym,
                                     cl[st == s], weights = ~w, cluster = ~v2gestfips))
for (m in list(a1, a4, b1, b2, b3, b4)) print(coeftable(m))
for (m in sub) print(coeftable(m))
cat("subsample N:", sapply(1:3, function(s) cl[st == s, sum(n)]), "\n")
cat("NOTE: hiring-regression SEs are from cell-collapsed data and are not identical to the person-level clustered SEs\n")

## Wage regression
cpi <- fread(file.path(D, "wage_deflation_1994_2016.csv"))
wg[, `:=`(yr = ym %/% 100L, mo = ym %% 100L)]
wg <- merge(wg, cpi, by.x = c("yr", "mo"), by.y = c("year", "month"))
wg[, lw := log(v2prernwa / cpi)]
ox <- fread(file.path(D, "occ_xwalk2002.csv")); ix <- fread(file.path(D, "ind_xwalk2002.csv"))
ox <- unique(ox, by = c("v2peio1ocd", "v2occ_codeyear")); ix <- unique(ix, by = c("v2peio1icd", "v2ind_codeyear"))
wg[, v2occ_codeyear := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2010L, 2002L, 2010L))]
wg[, v2ind_codeyear := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2008L, 2002L, fifelse(yr <= 2013L, 2007L, 2012L)))]
wg <- merge(wg, ox, by = c("v2peio1ocd", "v2occ_codeyear"), all.x = TRUE)
wg <- merge(wg, ix, by = c("v2peio1icd", "v2ind_codeyear"), all.x = TRUE)
cat("wage hires", nrow(wg), " missing occ", sum(is.na(wg$v2censusocc_2002recode)), " missing ind", sum(is.na(wg$v2censusind_2002recode)), "\n")
wg[, old := 1L - young]
wB <- feols(lw ~ young + young:urate + old:urate | v2gestfips + demo + ym + v2censusocc_2002recode + v2censusind_2002recode,
            wg, weights = ~w, cluster = ~v2gestfips)
print(coeftable(wB)); cat("wage N", nobs(wB), "\n")

g <- function(m, nm) unname(coef(m)[nm])
cat("secs", round(as.numeric(Sys.time() - t0, units = "secs")), "\n")
cat(sprintf("RESULT:young_x_unemp_rate_no_controls=%.6f\n", g(b1, "young:urate")))
cat(sprintf("RESULT:experienced_x_unemp_rate_no_controls=%.6f\n", g(b1, "urate:old")))
cat(sprintf("RESULT:young_x_unemp_rate_preferred=%.6f\n", g(b4, "young:urate")))
cat(sprintf("RESULT:experienced_x_unemp_rate_preferred=%.6f\n", g(b4, "urate:old")))
cat(sprintf("RESULT:aggregate_unemp_rate_no_controls=%.6f\n", g(a1, "urate")))
cat(sprintf("RESULT:aggregate_unemp_rate_month_year_fe=%.6f\n", g(a4, "urate")))
cat(sprintf("RESULT:young_x_unemp_rate_employed=%.6f\n", g(sub[[1]], "young:urate")))
cat(sprintf("RESULT:experienced_x_unemp_rate_employed=%.6f\n", g(sub[[1]], "urate:old")))
cat(sprintf("RESULT:young_x_unemp_rate_unemployed=%.6f\n", g(sub[[2]], "young:urate")))
cat(sprintf("RESULT:young_x_unemp_rate_nilf=%.6f\n", g(sub[[3]], "young:urate")))
cat(sprintf("RESULT:wage_young_x_unemp_rate_all_hires=%.6f\n", g(wB, "young:urate")))
cat(sprintf("RESULT:wage_experienced_x_unemp_rate_all_hires=%.6f\n", g(wB, "urate:old")))
cat(sprintf("RESULT:n_obs_full_sample=%d\n", N_full))
