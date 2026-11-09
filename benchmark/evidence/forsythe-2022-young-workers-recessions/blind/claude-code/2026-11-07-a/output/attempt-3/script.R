# Independent, blind reproduction: Forsythe (2022), "Why Don't Firms Hire Young Workers During Recessions?"
# Built from the paper text and the data's column names only.
suppressPackageStartupMessages({library(data.table); library(fixest)})
setDTthreads(1); setFixest_nthreads(1)
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
t0 <- proc.time()
cols <- c("hrmonth","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2prwernal","v2pwsswgt")
x <- fread(paste0(D, "yh_data.csv"), select = cols, nThread = 1, showProgress = FALSE)
cat("read cpu", (proc.time() - t0)[1], "rows", nrow(x), "\n")

fy <- function(y) fifelse(y < 100L, fifelse(y >= 90L, 1900L + y, 2000L + y), y)
x[, yr := fy(v2hryear)][, v2hryear := NULL]

# ---- sample restrictions ----
# consecutive months (pairs across the 8-month rotation break are not consecutive);
# interviews Jan 1994 - Sep 2016 (month t <= Sep 2016); May-Aug 1995 unmatched by construction;
# civilians 16+ with non-missing age/education, in the labour-force universe in both months
keep <- with(x, ((v2hrmonth == hrmonth + 1L) | (v2hrmonth == 1L & hrmonth == 12L)) &
               yr >= 1994L & (yr < 2016L | v2hrmonth <= 9L) & !(yr == 1995L & hrmonth %in% 5:8) &
               peage >= 16L & pemlr %in% 1:7 & v2pemlr %in% 1:7 & peeduca %in% 31:46 & !is.na(v2gestfips))
cat("N pairs kept", sum(keep), "\n")
# column-by-column subset (top level) to keep peak memory low
out <- list()
for (nm in names(x)) { out[[nm]] <- x[[nm]][keep]; x[, (nm) := NULL] }
rm(x, keep); x <- setDT(out); rm(out); gc()

# ---- variables ----
# years of schooling from PEEDUCA (31..46)
ed_years <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)
x[, young := as.integer(peage - ed_years[peeduca - 30L] - 6 <= 10)]
# demographic cells: sex x white x Hispanic x 7 education levels
x[, educ7 := fifelse(peeduca <= 38L, 1L, fifelse(peeduca == 39L, 2L, fifelse(peeduca <= 42L, 3L, peeduca - 39L)))]
x[, hisp := as.integer(fcoalesce(pehspnon, prhspnon) == 1L)]
x[is.na(hisp), hisp := 0L]
x[, demo := pesex * 1000L + as.integer(race == 1L) * 100L + hisp * 10L + educ7]
x[, w := (pwsswgt + v2pwsswgt) / 2]
x[, ym := yr * 100L + v2hrmonth]
# hired (x100): employed at t (not self-employed) and either non-employed at t-1, or employed at t-1
# and reporting no longer working for last month's employer
x[, hired := 100L * as.integer(v2pemlr %in% 1:2 & !(v2peio1cow %in% 6:7) &
                                 (!(pemlr %in% 1:2) | v2puiodp1 == 2L))]
x[, status0 := fifelse(pemlr %in% 1:2, 1L, fifelse(pemlr %in% 3:4, 2L, 3L))]
x[, c("hrmonth","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","v2pemlr","v2puiodp1",
      "v2peio1cow","educ7","hisp","pwsswgt","v2pwsswgt") := NULL]

# state unemployment rate in month t
u <- fread(paste0(D, "v2unemp_smy.csv"))
u[, yr := fy(v2hryear)]
x[u, urate := i.v2unemp_smy, on = c("v2gestfips", "yr", "v2hrmonth")]
cat("missing urate", sum(is.na(x$urate)), " nonpositive weight", sum(!(x$w > 0)), "\n")
if (any(is.na(x$urate)) || any(!(x$w > 0))) x <- x[!is.na(urate) & w > 0]
x[, old := 1L - young]
x[, u_y := urate * young]; x[, u_o := urate * old]
gc()
cat("N analysis", nrow(x), " hire rate", x[, weighted.mean(hired, w)],
    " young", x[young == 1L, weighted.mean(hired, w)], " exp", x[young == 0L, weighted.mean(hired, w)], "\n")
hs <- x[hired > 0, .(s = sum(w)), by = status0][, s := s / sum(s)][order(status0)]
cat("hire shares by t-1 status (1=E,2=U,3=N):", hs$s, "\n")

cl <- ~v2gestfips
# ---- Table 1, column (1): no fixed effects ----
a1 <- feols(hired ~ urate, x, weights = ~w, cluster = cl, lean = TRUE)
b1 <- feols(hired ~ young + u_y + u_o, x, weights = ~w, cluster = cl, lean = TRUE)
cat("cpu after col1", (proc.time() - t0)[1], "\n")
# ---- Table 1, column (4): state, demographic, month-year FE (one demeaning for both panels) ----
m4 <- feols(hired ~ sw(urate, young + u_y + u_o) | v2gestfips + demo + ym, x, weights = ~w, cluster = cl, lean = TRUE)
a4 <- m4[[1]]; b4 <- m4[[2]]
print(etable(a1, a4, b1, b4))
cat("cpu after T1", (proc.time() - t0)[1], "\n")
# ---- Table 2: by labour-force status in t-1 ----
t2 <- feols(hired ~ young + u_y + u_o | v2gestfips + demo + ym, x, weights = ~w, cluster = cl,
            split = ~status0, lean = TRUE)
print(etable(t2))
t2e <- t2[[1]]; t2u <- t2[[2]]; t2n <- t2[[3]]
cat("cpu after T2", (proc.time() - t0)[1], "\n")

# ---- Table 10: log real weekly wages of new hires (non-allocated) ----
h <- x[hired > 0L & !is.na(v2prernwa) & v2prernwa > 0 & !is.na(v2prwernal) & v2prwernal == 0L]
n_full <- nobs(b1)
rm(x); gc()
cpi <- fread(paste0(D, "wage_deflation_1994_2016.csv"))
h[cpi, cpi := i.cpi, on = c(yr = "year", v2hrmonth = "month")]
h[, lnw := log(v2prernwa / cpi)]
# consistent 2002 Census industry/occupation codes; code vintage by survey date
ix <- unique(fread(paste0(D, "ind_xwalk2002.csv")), by = c("v2peio1icd", "v2ind_codeyear"))
ox <- unique(fread(paste0(D, "occ_xwalk2002.csv")), by = c("v2peio1ocd", "v2occ_codeyear"))
h[, ind_cy := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2008L, 2002L, fifelse(yr <= 2013L, 2007L, 2012L)))]
h[, occ_cy := fifelse(yr <= 2002L, 1990L, fifelse(yr <= 2010L, 2002L, 2010L))]
h[ix, ind02 := i.v2censusind_2002recode, on = c(v2peio1icd = "v2peio1icd", ind_cy = "v2ind_codeyear")]
h[ox, occ02 := i.v2censusocc_2002recode, on = c(v2peio1ocd = "v2peio1ocd", occ_cy = "v2occ_codeyear")]
cat("wage hires", nrow(h), " missing ind", sum(is.na(h$ind02)), " missing occ", sum(is.na(h$occ02)), "\n")
wg <- feols(lnw ~ young + u_y + u_o | v2gestfips + demo + ym + occ02 + ind02, h, weights = ~w, cluster = cl)
wa <- feols(lnw ~ urate | v2gestfips + demo + ym + occ02 + ind02, h, weights = ~w, cluster = cl)
print(etable(wa, wg))
cat("total cpu", (proc.time() - t0)[1:3], "\n")

r <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:young_x_unemp_rate_no_controls=%.6f\n", r(b1, "u_y")))
cat(sprintf("RESULT:experienced_x_unemp_rate_no_controls=%.6f\n", r(b1, "u_o")))
cat(sprintf("RESULT:young_x_unemp_rate_preferred=%.6f\n", r(b4, "u_y")))
cat(sprintf("RESULT:experienced_x_unemp_rate_preferred=%.6f\n", r(b4, "u_o")))
cat(sprintf("RESULT:aggregate_unemp_rate_no_controls=%.6f\n", r(a1, "urate")))
cat(sprintf("RESULT:aggregate_unemp_rate_month_year_fe=%.6f\n", r(a4, "urate")))
cat(sprintf("RESULT:young_x_unemp_rate_employed=%.6f\n", r(t2e, "u_y")))
cat(sprintf("RESULT:experienced_x_unemp_rate_employed=%.6f\n", r(t2e, "u_o")))
cat(sprintf("RESULT:young_x_unemp_rate_unemployed=%.6f\n", r(t2u, "u_y")))
cat(sprintf("RESULT:young_x_unemp_rate_nilf=%.6f\n", r(t2n, "u_y")))
cat(sprintf("RESULT:wage_young_x_unemp_rate_all_hires=%.6f\n", r(wg, "u_y")))
cat(sprintf("RESULT:wage_experienced_x_unemp_rate_all_hires=%.6f\n", r(wg, "u_o")))
cat(sprintf("RESULT:n_obs_full_sample=%d\n", n_full))
