suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(0)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_un   <- file.path(base, "v2unemp_smy.csv")
f_def  <- file.path(base, "wage_deflation_1994_2016.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")

hdr <- names(fread(f_main, nrows = 0))
cat("Columns in yh_data.csv:\n"); print(hdr)

cand <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pemlr",
          "pwsswgt","v2pwsswgt","v2hrmonth","v2hryear","v2gestfips","gestfips",
          "v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "hrmis","v2hrmis","v2peage","v2pesex","v2peeduca","v2unemp_smy",
          "v2prernwa","v2prwernal","v2pternwa","v2prernhly","v2peernper",
          "v2pehruslt","prpertyp","v2prpertyp","peafnow","v2peafnow")
sel <- intersect(cand, hdr)
dt <- fread(f_main, select = sel, showProgress = FALSE)
for (v in names(dt)) if (!is.numeric(dt[[v]])) suppressWarnings(set(dt, j = v, value = as.numeric(dt[[v]])))
cat("Rows read:", nrow(dt), "\n")

## ---- sample restrictions ----
dt <- dt[!is.na(peage) & peage >= 16 & !is.na(peeduca) & peeduca > 0]
dt <- dt[pemlr %in% 1:7 & v2pemlr %in% 1:7]          # civilians, valid LF status both months
if ("peafnow" %in% names(dt)) dt <- dt[is.na(peafnow) | peafnow != 1]
if ("prpertyp" %in% names(dt)) dt <- dt[is.na(prpertyp) | prpertyp == 2]
# drop months lacking longitudinal link (May-Aug 1995)
dt <- dt[!(v2hryear == 1995 & v2hrmonth %in% 5:8)]
if (all(c("hryear","hrmonth") %in% names(dt))) dt <- dt[!(hryear == 1995 & hrmonth %in% 5:8)]
# drop pairs spanning the MIS 4 -> 5 break
if ("hrmis" %in% names(dt)) dt <- dt[is.na(hrmis) | hrmis != 4]
if ("v2hrmis" %in% names(dt)) dt <- dt[is.na(v2hrmis) | v2hrmis != 5]
# Jan 1994 - Sep 2016
dt <- dt[(v2hryear * 100 + v2hrmonth) >= 199401 & (v2hryear * 100 + v2hrmonth) <= 201609]

## ---- state unemployment rate ----
if (!("v2unemp_smy" %in% names(dt))) {
  un <- fread(f_un)
  for (v in names(un)) if (!is.numeric(un[[v]])) suppressWarnings(set(un, j = v, value = as.numeric(un[[v]])))
  un <- unique(un, by = c("v2gestfips","v2hryear","v2hrmonth"))
  dt <- merge(dt, un, by = c("v2gestfips","v2hryear","v2hrmonth"), all.x = FALSE)
}
if (max(dt$v2unemp_smy, na.rm = TRUE) < 1) dt[, v2unemp_smy := 100 * v2unemp_smy]
dt <- dt[!is.na(v2unemp_smy) & !is.na(v2gestfips)]
setnames(dt, "v2unemp_smy", "urate")

## ---- potential experience ----
educ_years <- c(`31`=0, `32`=2.5, `33`=5.5, `34`=7.5, `35`=9, `36`=10, `37`=11, `38`=12,
                `39`=12, `40`=13, `41`=14, `42`=14, `43`=16, `44`=18, `45`=18, `46`=20)
dt[, eyrs := unname(educ_years[as.character(peeduca)])]
dt <- dt[!is.na(eyrs)]
dt[, pe := peage - eyrs - 6]
dt[, young := as.integer(pe <= 10)]
dt[, young_U := young * urate]
dt[, exp_U := (1 - young) * urate]

## ---- demographic FE ----
dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca %in% 40:42, 3L,
                    peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L, peeduca == 46, 7L)]
dt[, white := as.integer(race == 1)]
dt[, hisp := as.integer(prhspnon == 1)]
dt[, demo := pesex * 1000 + white * 100 + hisp * 10 + educ7]
dt[, ym := v2hryear * 100 + v2hrmonth]
dt[, state := v2gestfips]

## ---- weights ----
if ("v2pwsswgt" %in% names(dt)) {
  dt[, w := rowMeans(cbind(pwsswgt, v2pwsswgt), na.rm = TRUE)]
} else dt[, w := pwsswgt]
dt <- dt[!is.na(w) & w > 0]

## ---- hire indicator ----
emp_prev <- dt$pemlr %in% 1:2
emp_now  <- dt$v2pemlr %in% 1:2
selfemp  <- if ("v2peio1cow" %in% names(dt)) (dt$v2peio1cow %in% 6:7) else rep(FALSE, nrow(dt))
changed  <- if ("v2puiodp1" %in% names(dt)) (!is.na(dt$v2puiodp1) & dt$v2puiodp1 == 2) else rep(FALSE, nrow(dt))
dt[, hired := 100 * as.numeric(emp_now & !selfemp & (!emp_prev | changed))]
dt[, lfs_prev := fcase(pemlr %in% 1:2, "E", pemlr %in% 3:4, "U", pemlr %in% 5:7, "N")]
rm(emp_prev, emp_now, selfemp, changed); gc()

cat("Analysis sample:", nrow(dt), " mean hired:", weighted.mean(dt$hired, dt$w), "\n")

getc <- function(m, nm) { v <- tryCatch(coef(m)[nm], error = function(e) NA); if (is.null(v)) NA else unname(v) }

## ---- Table 1 ----
m_a1 <- feols(hired ~ urate, data = dt, weights = ~w, cluster = ~state)
m_a4 <- feols(hired ~ urate | state + demo + ym, data = dt, weights = ~w, cluster = ~state)
m_b1 <- feols(hired ~ young + young_U + exp_U, data = dt, weights = ~w, cluster = ~state)
m_b4 <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt, weights = ~w, cluster = ~state)
print(summary(m_b1)); print(summary(m_b4))
n_full <- nobs(m_b4)

## ---- Table 2 ----
m_E <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt[lfs_prev == "E"], weights = ~w, cluster = ~state)
m_U <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt[lfs_prev == "U"], weights = ~w, cluster = ~state)
m_N <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt[lfs_prev == "N"], weights = ~w, cluster = ~state)
print(summary(m_E)); print(summary(m_U)); print(summary(m_N))

## ---- Table 10: wages of new hires ----
wage_y <- NA; wage_e <- NA
tryCatch({
  wcol <- if ("v2prernwa" %in% names(dt)) "v2prernwa" else if ("v2pternwa" %in% names(dt)) "v2pternwa" else NA
  if (is.na(wcol)) stop("no weekly wage column")
  h <- dt[hired == 100]
  h[, wage := get(wcol)]
  if ("v2hrmis" %in% names(h)) h <- h[v2hrmis %in% c(4, 8)]
  h <- h[!is.na(wage) & wage > 0]
  if ("v2prwernal" %in% names(h)) h <- h[is.na(v2prwernal) | v2prwernal == 0]
  def <- fread(f_def)
  def <- def[, .(year = as.numeric(year), month = as.numeric(month), cpi = as.numeric(cpi))]
  base_cpi <- mean(def[year == 1994, cpi])
  h <- merge(h, def, by.x = c("v2hryear","v2hrmonth"), by.y = c("year","month"), all.x = TRUE)
  h[, lw := log(wage / (cpi / base_cpi))]
  h <- h[is.finite(lw)]
  # crosswalk industry / occupation to consistent 2002 codes
  ix <- fread(f_ind); ox <- fread(f_occ)
  ix <- unique(ix[, .(code = as.numeric(v2peio1icd), cy = as.numeric(v2ind_codeyear), ind02 = v2censusind_2002recode)], by = c("code","cy"))
  ox <- unique(ox[, .(code = as.numeric(v2peio1ocd), cy = as.numeric(v2occ_codeyear), occ02 = v2censusocc_2002recode)], by = c("code","cy"))
  pick_cy <- function(yr, cys) { cys <- sort(unique(cys)); sapply(yr, function(y) { s <- cys[cys <= y]; if (length(s)) max(s) else min(cys) }) }
  yrs <- sort(unique(h$v2hryear))
  im <- data.table(v2hryear = yrs, icy = pick_cy(yrs, ix$cy), ocy = pick_cy(yrs, ox$cy))
  h <- merge(h, im, by = "v2hryear")
  h <- merge(h, ix, by.x = c("v2peio1icd","icy"), by.y = c("code","cy"), all.x = TRUE)
  h <- merge(h, ox, by.x = c("v2peio1ocd","ocy"), by.y = c("code","cy"), all.x = TRUE)
  h[, ind_fe := ifelse(is.na(ind02), paste0("raw", icy, "_", v2peio1icd), as.character(ind02))]
  h[, occ_fe := ifelse(is.na(occ02), paste0("raw", ocy, "_", v2peio1ocd), as.character(occ02))]
  cat("Wage sample:", nrow(h), "\n")
  m_w <- feols(lw ~ young + young_U + exp_U | state + demo + ym + occ_fe + ind_fe,
               data = h, weights = ~w, cluster = ~state)
  print(summary(m_w))
  wage_y <<- getc(m_w, "young_U"); wage_e <<- getc(m_w, "exp_U")
}, error = function(e) cat("Wage regression failed:", conditionMessage(e), "\n"))

cat(sprintf("RESULT:young_x_unemp_rate_no_controls=%.6f\n", getc(m_b1, "young_U")))
cat(sprintf("RESULT:experienced_x_unemp_rate_no_controls=%.6f\n", getc(m_b1, "exp_U")))
cat(sprintf("RESULT:young_x_unemp_rate_preferred=%.6f\n", getc(m_b4, "young_U")))
cat(sprintf("RESULT:experienced_x_unemp_rate_preferred=%.6f\n", getc(m_b4, "exp_U")))
cat(sprintf("RESULT:aggregate_unemp_rate_no_controls=%.6f\n", getc(m_a1, "urate")))
cat(sprintf("RESULT:aggregate_unemp_rate_month_year_fe=%.6f\n", getc(m_a4, "urate")))
cat(sprintf("RESULT:young_x_unemp_rate_employed=%.6f\n", getc(m_E, "young_U")))
cat(sprintf("RESULT:experienced_x_unemp_rate_employed=%.6f\n", getc(m_E, "exp_U")))
cat(sprintf("RESULT:young_x_unemp_rate_unemployed=%.6f\n", getc(m_U, "young_U")))
cat(sprintf("RESULT:young_x_unemp_rate_nilf=%.6f\n", getc(m_N, "young_U")))
cat(sprintf("RESULT:wage_young_x_unemp_rate_all_hires=%.6f\n", wage_y))
cat(sprintf("RESULT:wage_experienced_x_unemp_rate_all_hires=%.6f\n", wage_e))
cat(sprintf("RESULT:n_obs_full_sample=%d\n", as.integer(n_full)))
