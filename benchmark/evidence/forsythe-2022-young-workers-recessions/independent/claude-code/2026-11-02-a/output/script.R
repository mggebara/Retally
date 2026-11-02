# Independent reproduction: Forsythe (2022), "Why Don't Firms Hire Young Workers During Recessions?"
# Equation 1 linear probability model of hiring (x100) on PE<=10 indicator and PE-group x state
# unemployment rate interactions; Table 1 (A,B cols 1 & 4), Table 2 (cols 1-4), Table 10 Panel B col 1.
suppressPackageStartupMessages({library(data.table); library(fixest)})
set.seed(42)
setDTthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
t0 <- Sys.time(); el <- function() round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)

# ---- load (only needed columns; the 2 GB file is read through a slow mount) ----
# Unprefixed variables refer to month t-1, "v2" variables to month t of each matched pair.
cols <- c("peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
x <- fread(paste0(D, "yh_data.csv"), select = cols, nThread = 1, showProgress = FALSE)
message("read ", el(), "s rows ", nrow(x))
unemp <- fread(paste0(D, "v2unemp_smy.csv"))
cpi   <- fread(paste0(D, "wage_deflation_1994_2016.csv"))
indx  <- fread(paste0(D, "ind_xwalk2002.csv"))
occx  <- fread(paste0(D, "occ_xwalk2002.csv"))

# ---- construct variables ----
x[v2hryear < 100L, v2hryear := v2hryear + 1900L]
# years of schooling by CPS PEEDUCA code 31..46 (assumed mapping)
edyrs <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 18, 18)
# seven education levels: <HS, HS, some college, BA, MA, professional, PhD
ed7m  <- c(1L,1L,1L,1L,1L,1L,1L,1L, 2L, 3L,3L,3L, 4L, 5L, 6L, 7L)
x[, young := (peage - edyrs[peeduca - 30L] - 6) <= 10]
x[, hisp := fcoalesce(prhspnon, pehspnon)]
x[, c("prhspnon","pehspnon") := NULL]
# sample: civilians aged 16-80 (age top-codes above 80 vary over time) with non-missing age, education,
# Hispanic origin and state (state is needed for the unemployment rate; it is missing from mid-2014 on)
x[, keep := peage >= 16L & peage <= 80L & !is.na(v2gestfips) & !is.na(hisp)]
x[, demog := ((pesex - 1L) * 2L + (race != 1L)) * 14L + (hisp %in% 1L) * 7L + ed7m[peeduca - 30L]]
x[, c("pesex","peeduca","race","hisp") := NULL]
x[, status := fifelse(pemlr %in% 1:2, 1L, fifelse(pemlr %in% 3:4, 2L, 3L))]
x[, hired := 100L * (v2pemlr %in% 1:2 & !(v2peio1cow %in% 6:7) & (status != 1L | v2puiodp1 %in% 2L))]
x[, w := (pwsswgt + v2pwsswgt) / 2]
x[, c("pemlr","pwsswgt","v2pemlr","v2puiodp1","v2pwsswgt","v2peio1cow","peage") := NULL]
invisible(gc())
message("constructed ", el(), "s")
N <- sum(x$keep)
message("N all rows ", nrow(x), " kept ", N, " state ok ", sum(!is.na(x$v2gestfips)))
# new-hire wage sample (small), extracted before collapsing
wg <- x[keep & hired > 0L & !is.na(v2prernwa) & v2prernwa > 0 & v2prwernal %in% 0L]
x[, c("v2prernwa","v2prwernal","v2peio1icd","v2peio1ocd") := NULL]
invisible(gc())

setnames(unemp, c("v2gestfips","u","v2hryear","v2hrmonth"))
unemp[v2hryear < 100L, v2hryear := v2hryear + 1900L]

# ---- hiring regressions on weighted cell means (identical WLS point estimates) ----
cells <- x[, .(y = sum(hired * w) / sum(w), sw = sum(w)),
           by = .(keep, v2gestfips, v2hryear, v2hrmonth, demog, young, status)]
rm(x); invisible(gc())
cells <- cells[keep == TRUE][, keep := NULL]
cells <- merge(cells, unemp, by = c("v2gestfips","v2hryear","v2hrmonth"), all.x = TRUE)
cells[, ym := v2hryear * 100L + v2hrmonth]
cells[, `:=`(yu = young * u, ou = (!young) * u)]
message("cells ", nrow(cells), " missing u ", sum(is.na(cells$u)), " ", el(), "s")

cA <- cells[, .(y = sum(y * sw) / sum(sw), sw = sum(sw)), by = .(v2gestfips, ym, demog, u)]
mA1 <- feols(y ~ u, data = cA, weights = ~sw, notes = FALSE)
mA4 <- feols(y ~ u | v2gestfips + demog + ym, data = cA, weights = ~sw, notes = FALSE)
cB <- cells[, .(y = sum(y * sw) / sum(sw), sw = sum(sw)), by = .(v2gestfips, ym, demog, young, yu, ou)]
mB1 <- feols(y ~ young + yu + ou, data = cB, weights = ~sw, notes = FALSE)
mB4 <- feols(y ~ young + yu + ou | v2gestfips + demog + ym, data = cB, weights = ~sw, notes = FALSE)
mE  <- feols(y ~ young + yu + ou | v2gestfips + demog + ym, data = cells[status == 1L], weights = ~sw, notes = FALSE)
mU  <- feols(y ~ young + yu + ou | v2gestfips + demog + ym, data = cells[status == 2L], weights = ~sw, notes = FALSE)
mN  <- feols(y ~ young + yu + ou | v2gestfips + demog + ym, data = cells[status == 3L], weights = ~sw, notes = FALSE)
message("hiring regs ", el(), "s")

# ---- new-hire log weekly wage regression (Table 10, Panel B, col 1) ----
rm(cells); invisible(gc())
wg <- merge(wg, unemp, by = c("v2gestfips","v2hryear","v2hrmonth"), all.x = TRUE)
wg <- merge(wg, cpi, by.x = c("v2hryear","v2hrmonth"), by.y = c("year","month"), all.x = TRUE)
wg[, lw := log(v2prernwa / cpi)]
wg[, ind_cy := fifelse(v2hryear <= 2002L, 1990L, fifelse(v2hryear <= 2008L, 2002L, fifelse(v2hryear <= 2013L, 2007L, 2012L)))]
wg[, occ_cy := fifelse(v2hryear <= 2002L, 1990L, fifelse(v2hryear <= 2010L, 2002L, 2010L))]
indx <- unique(indx, by = c("v2peio1icd","v2ind_codeyear"))
occx <- unique(occx, by = c("v2peio1ocd","v2occ_codeyear"))
wg <- merge(wg, indx, by.x = c("v2peio1icd","ind_cy"), by.y = c("v2peio1icd","v2ind_codeyear"), all.x = TRUE)
wg <- merge(wg, occx, by.x = c("v2peio1ocd","occ_cy"), by.y = c("v2peio1ocd","v2occ_codeyear"), all.x = TRUE)
message("wage obs ", nrow(wg), " ind NA ", sum(is.na(wg$v2censusind_2002recode)), " occ NA ", sum(is.na(wg$v2censusocc_2002recode)))
wg[, ym := v2hryear * 100L + v2hrmonth]
wg[, `:=`(yu = young * u, ou = (!young) * u)]
mW <- feols(lw ~ young + yu + ou | v2gestfips + demog + ym + v2censusocc_2002recode + v2censusind_2002recode,
            data = wg, weights = ~w, cluster = ~v2gestfips, notes = FALSE)
message("wage reg N ", nobs(mW), " ", el(), "s")

g <- function(m, v) unname(coef(m)[v])
out <- c(
  young_x_unemp_rate_no_controls        = g(mB1, "yu"),
  experienced_x_unemp_rate_no_controls  = g(mB1, "ou"),
  young_x_unemp_rate_preferred          = g(mB4, "yu"),
  experienced_x_unemp_rate_preferred    = g(mB4, "ou"),
  aggregate_unemp_rate_no_controls      = g(mA1, "u"),
  aggregate_unemp_rate_month_year_fe    = g(mA4, "u"),
  young_x_unemp_rate_employed           = g(mE, "yu"),
  experienced_x_unemp_rate_employed     = g(mE, "ou"),
  young_x_unemp_rate_unemployed         = g(mU, "yu"),
  young_x_unemp_rate_nilf               = g(mN, "yu"),
  wage_young_x_unemp_rate_all_hires     = g(mW, "yu"),
  wage_experienced_x_unemp_rate_all_hires = g(mW, "ou"),
  n_obs_full_sample                     = N)
cat("DEVIATION: hiring LPMs estimated by WLS on weighted cell means (state x month x demographic x PE-group x prior-status); point estimates identical to person-level WLS, clustered SEs not reported\n")
cat("DEVIATION: v2gestfips (state) is missing in the data from mid-2014 onward; those person-months cannot be matched to a state unemployment rate and are dropped; sample further restricted to ages 16-80 with non-missing Hispanic origin\n")
cat("DEVIATION: years of schooling imputed from CPS education categories (assumed mapping; master's/professional/PhD = 18 years)\n")
for (nm in names(out)) cat(sprintf("RESULT:%s=%s\n", nm, format(out[[nm]], digits = 8, scientific = FALSE)))
message("done ", el(), "s")
