# Independent reproduction: Forsythe (2022) "Why Don't Firms Hire Young Workers During Recessions?"
# Tables 1, 2 (hiring LPMs) and Table 10 Panel B col 1 (log wages of new hires).
suppressMessages({library(data.table); library(fixest)})
set.seed(42)
setDTthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-c/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
t0 <- Sys.time()
cols <- c("peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2pwsswgt",
          "v2prernwa","v2prwernal","v2peio1icd","v2peio1ocd")
x <- fread(file.path(D,"yh_data.csv"), select=cols, showProgress=FALSE)
cat("DEVIATION: yh_data.csv (2 GB) read with data.table::fread(select=) for only the needed columns, to fit the sandbox memory/time limits\n")
cat("read secs", round(as.numeric(Sys.time()-t0, units="secs")), "rows", nrow(x), "\n")

# survey year of month t (v2 = second month of pair); early years are 2-digit
x[, yr := v2hryear + ifelse(v2hryear < 100L, 1900L, 0L)]
x[, v2hryear := NULL]
u <- fread(file.path(D,"v2unemp_smy.csv"))
setnames(u, c("v2gestfips","urate","yr","v2hrmonth"))
x[u, urate := i.urate, on=c("v2gestfips","yr","v2hrmonth")]
# Sample: matched pairs with a state unemployment rate (LAUS file ends May 2014) and age < 80
# (CPS age top-code); this reproduces the paper's N = 16,948,516 exactly.
x[, keep := !is.na(urate) & peage < 80L]
cat("N sample", sum(x$keep), "\n")

# potential experience = age - years of education - 6
# peeduca 31..46 -> years: <1st grade 0, 1-4th 2.5, 5-6th 5.5, 7-8th 7.5, 9th 9, 10th 10, 11th 11,
# 12th no diploma 12, HS 12, some college 13, associate 14, BA 16, MA 18, professional 20, PhD 20
edyrs <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)
x[, young := as.integer((peage - edyrs[peeduca - 30L] - 6) <= 10)]
# demographic cells: gender x white x Hispanic x 7 education levels
x[, educ7 := fifelse(peeduca <= 38L, 1L, fifelse(peeduca == 39L, 2L, fifelse(peeduca <= 42L, 3L,
             fifelse(peeduca == 43L, 4L, fifelse(peeduca == 44L, 5L, fifelse(peeduca == 45L, 6L, 7L))))))]
x[, hisp := as.integer(fcoalesce(prhspnon, pehspnon) == 1L)]
x[, demo := pesex * 1000L + as.integer(race == 1L) * 100L + hisp * 10L + educ7]
x[, c("pesex","race","prhspnon","pehspnon","educ7","hisp","peeduca") := NULL]
# status in t-1: 1 employed, 2 unemployed, 3 NILF
x[, status := fifelse(pemlr <= 2L, 1L, fifelse(pemlr <= 4L, 2L, 3L))]
# hired: employed at t, not self-employed (class of worker 6/7), and either non-employed at t-1
# or employed at t-1 and reports no longer working for last month's employer
x[, hired := 100 * as.integer(v2pemlr %in% 1:2 & !(v2peio1cow %in% 6:7) &
                               (status != 1L | v2puiodp1 == 2L))]
x[, w := (pwsswgt + v2pwsswgt) / 2]
x[, ym := yr * 100L + v2hrmonth]
cat("weighted hire rate", x[keep == TRUE, weighted.mean(hired, w)], " by status 1/2/3:", x[keep == TRUE, weighted.mean(hired, w), by=status][order(status)]$V1, "\n")

# ---- wage sample: new hires with a non-allocated weekly wage (outgoing rotation months)
wg <- x[keep & hired == 100 & !is.na(v2prernwa) & v2prernwa > 0 & v2prwernal == 0L,
        .(v2gestfips, ym, yr, v2hrmonth, demo, young, status, urate, w, v2prernwa, v2peio1icd, v2peio1ocd)]
cat("hires with any wage", x[keep & hired == 100 & !is.na(v2prernwa) & v2prernwa > 0, .N],
    " non-allocated", nrow(wg), "\n")

# ---- collapse hiring data to regression cells (identical WLS point estimates)
cells <- x[keep == TRUE, .(hired = sum(hired * w) / sum(w), w = sum(w), n = .N),
           by = .(v2gestfips, ym, demo, young, status, urate)]
rm(x); gc(verbose=FALSE)
cells[, `:=`(yu = young * urate, ou = (1L - young) * urate)]
cat("cells", nrow(cells), " N", sum(cells$n), "\n")

est <- function(f, d) feols(f, data = d, weights = ~w, cluster = ~v2gestfips, notes = FALSE)
a1 <- est(hired ~ urate, cells)
a4 <- est(hired ~ urate | v2gestfips + demo + ym, cells)
b1 <- est(hired ~ young + yu + ou, cells)
b4 <- est(hired ~ young + yu + ou | v2gestfips + demo + ym, cells)
s1 <- est(hired ~ young + yu + ou | v2gestfips + demo + ym, cells[status == 1L])
s2 <- est(hired ~ young + yu + ou | v2gestfips + demo + ym, cells[status == 2L])
s3 <- est(hired ~ young + yu + ou | v2gestfips + demo + ym, cells[status == 3L])
for (m in list(a1, a4, b1, b4, s1, s2, s3)) print(coeftable(m))
cat("N by status", cells[, sum(n), by = status][order(status)]$V1, "\n")

# ---- wages: deflate to 1994 dollars, crosswalk industry/occupation to 2002 Census codes
cpi <- fread(file.path(D,"wage_deflation_1994_2016.csv"))
wg[cpi, cpi := i.cpi, on = c(yr = "year", v2hrmonth = "month")]
wg[, lwage := log(v2prernwa / cpi)]
wg[, indyr := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2008L, 2002L, fifelse(yr <= 2013L, 2007L, 2012L)))]
wg[, occyr := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2010L, 2002L, 2010L))]
ix <- unique(fread(file.path(D,"ind_xwalk2002.csv")), by = c("v2peio1icd","v2ind_codeyear"))
ox <- unique(fread(file.path(D,"occ_xwalk2002.csv")), by = c("v2peio1ocd","v2occ_codeyear"))
wg[ix, ind := i.v2censusind_2002recode, on = c(v2peio1icd = "v2peio1icd", indyr = "v2ind_codeyear")]
wg[ox, occ := i.v2censusocc_2002recode, on = c(v2peio1ocd = "v2peio1ocd", occyr = "v2occ_codeyear")]
cat("unmatched ind", sum(is.na(wg$ind)), " occ", sum(is.na(wg$occ)), "\n")
wg[is.na(ind), ind := -indyr * 10000L - v2peio1icd]
wg[is.na(occ), occ := -occyr * 10000L - v2peio1ocd]
wg[, `:=`(yu = young * urate, ou = (1L - young) * urate)]
wr <- feols(lwage ~ young + yu + ou | v2gestfips + demo + ym + occ + ind,
            data = wg, weights = ~w, cluster = ~v2gestfips, notes = FALSE)
print(coeftable(wr)); cat("wage N", nobs(wr), "\n")

cat(sprintf("RESULT:young_x_unemp_rate_no_controls=%.6f\n", coef(b1)["yu"]))
cat(sprintf("RESULT:experienced_x_unemp_rate_no_controls=%.6f\n", coef(b1)["ou"]))
cat(sprintf("RESULT:young_x_unemp_rate_preferred=%.6f\n", coef(b4)["yu"]))
cat(sprintf("RESULT:experienced_x_unemp_rate_preferred=%.6f\n", coef(b4)["ou"]))
cat(sprintf("RESULT:aggregate_unemp_rate_no_controls=%.6f\n", coef(a1)["urate"]))
cat(sprintf("RESULT:aggregate_unemp_rate_month_year_fe=%.6f\n", coef(a4)["urate"]))
cat(sprintf("RESULT:young_x_unemp_rate_employed=%.6f\n", coef(s1)["yu"]))
cat(sprintf("RESULT:experienced_x_unemp_rate_employed=%.6f\n", coef(s1)["ou"]))
cat(sprintf("RESULT:young_x_unemp_rate_unemployed=%.6f\n", coef(s2)["yu"]))
cat(sprintf("RESULT:young_x_unemp_rate_nilf=%.6f\n", coef(s3)["yu"]))
cat(sprintf("RESULT:wage_young_x_unemp_rate_all_hires=%.6f\n", coef(wr)["yu"]))
cat(sprintf("RESULT:wage_experienced_x_unemp_rate_all_hires=%.6f\n", coef(wr)["ou"]))
cat(sprintf("RESULT:n_obs_full_sample=%d\n", as.integer(sum(cells$n))))
cat("total secs", round(as.numeric(Sys.time()-t0, units="secs")), "\n")
