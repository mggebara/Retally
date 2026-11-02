suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(0)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_un   <- file.path(base, "v2unemp_smy.csv")
f_cpi  <- file.path(base, "wage_deflation_1994_2016.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")

hdr <- names(fread(f_main, nrows = 0))
lc <- tolower(hdr)
pick <- function(pats) {
  for (p in pats) {
    i <- which(grepl(p, lc))
    if (length(i) > 0) return(hdr[i[1]])
  }
  NA_character_
}

need <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow",
          "v2peio1icd","v2peio1ocd")
need <- hdr[match(need, lc)]
need <- need[!is.na(need)]
c_w2    <- pick(c("^v2pwsswgt$"))
c_mis1  <- pick(c("^hrmis$"))
c_mis2  <- pick(c("^v2hrmis$"))
c_earn  <- pick(c("^v2prernwa$", "^v2pternwa$", "^v2.*ernwa", "^v2peernwkp$"))
c_alloc <- pick(c("^v2prwernal$", "^v2.*wernal", "^v2.*ernal"))
c_age2  <- pick(c("^v2peage$"))
opt <- c(c_w2, c_mis1, c_mis2, c_earn, c_alloc)
opt <- opt[!is.na(opt)]
sel <- unique(c(need, opt))

dt <- fread(f_main, select = sel, showProgress = FALSE)
setnames(dt, tolower(names(dt)))
c_w2 <- tolower(c_w2); c_mis1 <- tolower(c_mis1); c_mis2 <- tolower(c_mis2)
c_earn <- tolower(c_earn); c_alloc <- tolower(c_alloc)

num <- function(x) suppressWarnings(as.numeric(x))
for (v in names(dt)) if (!is.numeric(dt[[v]])) set(dt, j = v, value = num(dt[[v]]))

# ---- sample restrictions ----
dt <- dt[!is.na(peage) & peage >= 16]
dt <- dt[!is.na(peeduca) & peeduca >= 31 & peeduca <= 46]
dt <- dt[!is.na(pemlr) & pemlr %in% 1:7 & !is.na(v2pemlr) & v2pemlr %in% 1:7]
dt[, m1 := hryear * 12 + hrmonth]
dt[, m2 := v2hryear * 12 + v2hrmonth]
dt <- dt[m2 - m1 == 1]
if (!is.na(c_mis1) && c_mis1 %in% names(dt)) dt <- dt[!(get(c_mis1) %in% 4)]
dt <- dt[!((hryear == 1995 & hrmonth %in% 5:8) | (v2hryear == 1995 & v2hrmonth %in% 5:8))]
dt <- dt[m1 >= 1994 * 12 + 1 & m2 <= 2016 * 12 + 9]

# ---- weights ----
if (!is.na(c_w2) && c_w2 %in% names(dt)) {
  dt[, w := rowMeans(cbind(pwsswgt, get(c_w2)), na.rm = TRUE)]
} else {
  dt[, w := pwsswgt]
}
dt <- dt[!is.na(w) & w >= 0]

# ---- education, PE, demographics ----
edyrs <- c(`31`=0, `32`=2.5, `33`=5.5, `34`=7.5, `35`=9, `36`=10, `37`=11, `38`=12,
           `39`=12, `40`=13, `41`=14, `42`=14, `43`=16, `44`=18, `45`=19, `46`=20)
dt[, educ_yrs := edyrs[as.character(peeduca)]]
dt[, pe := peage - educ_yrs - 6]
dt[, young := as.integer(pe <= 10)]
dt[, edcat := fifelse(peeduca <= 38, 1L, fifelse(peeduca == 39, 2L, fifelse(peeduca <= 42, 3L,
               fifelse(peeduca == 43, 4L, fifelse(peeduca == 44, 5L, fifelse(peeduca == 45, 6L, 7L)))))]
dt[, white := as.integer(race == 1)]
dt[, hisp := as.integer(prhspnon == 1)]
dt[, demog := paste(pesex, white, hisp, edcat, sep = "_")]
dt[, ym := m2]
dt[, state := v2gestfips]

# ---- hired indicator ----
dt[, emp1 := pemlr %in% 1:2]
dt[, emp2 := v2pemlr %in% 1:2]
dt[, selfemp := !is.na(v2peio1cow) & v2peio1cow %in% c(6, 7)]
dt[, newfirm := !is.na(v2puiodp1) & v2puiodp1 == 2]
dt[, hired := 100 * as.numeric(emp2 & !selfemp & ((!emp1) | (emp1 & newfirm)))]
dt[, status1 := fifelse(pemlr %in% 1:2, "E", fifelse(pemlr %in% 3:4, "U", "N"))]

# ---- unemployment rate ----
un <- fread(f_un)
setnames(un, tolower(names(un)))
un <- un[, .(v2gestfips = as.numeric(v2gestfips), v2hryear = as.numeric(v2hryear),
             v2hrmonth = as.numeric(v2hrmonth), urate = as.numeric(v2unemp_smy))]
un <- unique(un, by = c("v2gestfips", "v2hryear", "v2hrmonth"))
if (max(un$urate, na.rm = TRUE) < 1) un[, urate := urate * 100]
dt <- merge(dt, un, by = c("v2gestfips", "v2hryear", "v2hrmonth"), all.x = FALSE)
dt <- dt[!is.na(urate)]
dt[, yU := young * urate]
dt[, eU := (1 - young) * urate]

gc()

getc <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NULL })

# Table 1 Panel A
mA1 <- safe(feols(hired ~ urate, data = dt, weights = ~w, cluster = ~state, lean = TRUE))
mA4 <- safe(feols(hired ~ urate | state + demog + ym, data = dt, weights = ~w, cluster = ~state, lean = TRUE))
# Table 1 Panel B
mB1 <- safe(feols(hired ~ young + yU + eU, data = dt, weights = ~w, cluster = ~state, lean = TRUE))
mB4 <- safe(feols(hired ~ young + yU + eU | state + demog + ym, data = dt, weights = ~w, cluster = ~state, lean = TRUE))
n_full <- if (!is.null(mB1)) nobs(mB1) else nrow(dt)

# Table 2 by status
mE <- safe(feols(hired ~ young + yU + eU | state + demog + ym, data = dt[status1 == "E"], weights = ~w, cluster = ~state, lean = TRUE))
mU <- safe(feols(hired ~ young + yU + eU | state + demog + ym, data = dt[status1 == "U"], weights = ~w, cluster = ~state, lean = TRUE))
mN <- safe(feols(hired ~ young + yU + eU | state + demog + ym, data = dt[status1 == "N"], weights = ~w, cluster = ~state, lean = TRUE))

# ---- Table 10 wages ----
wy <- NA_real_; we <- NA_real_
hires <- dt[hired == 100]
rm(dt); gc()
mW <- NULL
if (!is.na(c_earn) && c_earn %in% names(hires)) {
  if (!is.na(c_mis2) && c_mis2 %in% names(hires)) hires <- hires[get(c_mis2) %in% c(4, 8)]
  hires[, earn := get(c_earn)]
  hires <- hires[!is.na(earn) & earn > 0]
  if (!is.na(c_alloc) && c_alloc %in% names(hires)) {
    av <- hires[[c_alloc]]
    hires <- hires[!(av %in% 1) | is.na(av)]
    hires <- hires[get(c_alloc) %in% c(0, -1) | is.na(get(c_alloc))]
  }
  cpi <- fread(f_cpi)
  setnames(cpi, tolower(names(cpi)))
  cpi <- cpi[, .(v2hryear = as.numeric(year), v2hrmonth = as.numeric(month), cpi = as.numeric(cpi))]
  cpi <- unique(cpi, by = c("v2hryear", "v2hrmonth"))
  hires <- merge(hires, cpi, by = c("v2hryear", "v2hrmonth"), all.x = TRUE)
  b94 <- mean(cpi[v2hryear == 1994]$cpi, na.rm = TRUE)
  if (!is.finite(b94)) b94 <- 1
  hires <- hires[!is.na(cpi) & cpi > 0]
  hires[, logw := log(earn / cpi * b94)]

  # code eras
  hires[, ind_era := fifelse(v2hryear < 2003, 1990, fifelse(v2hryear <= 2008, 2002, fifelse(v2hryear <= 2013, 2007, 2012)))]
  hires[, occ_era := fifelse(v2hryear < 2003, 1990, fifelse(v2hryear <= 2010, 2000, 2010))]

  map_x <- function(xw, codecol, yrcol, reccol, raw, era, eras_all) {
    xw <- copy(xw)
    setnames(xw, tolower(names(xw)))
    xw <- xw[, .(code = num(get(codecol)), cy = num(get(yrcol)), rec = as.character(get(reccol)))]
    xw <- xw[!is.na(code) & !is.na(cy)]
    ucy <- sort(unique(xw$cy))
    if (length(ucy) == 0) return(rep(NA_character_, length(raw)))
    if (all(ucy > 1900)) {
      uera <- sort(unique(era))
      lut <- setNames(sapply(uera, function(e) ucy[which.min(abs(ucy - e))]), uera)
      cy_obs <- lut[as.character(era)]
    } else if (length(ucy) == length(eras_all)) {
      lut <- setNames(ucy, eras_all)
      cy_obs <- lut[as.character(era)]
    } else {
      return(rep(NA_character_, length(raw)))
    }
    xw <- unique(xw, by = c("code", "cy"))
    key_x <- paste(xw$code, xw$cy)
    key_o <- paste(raw, cy_obs)
    xw$rec[match(key_o, key_x)]
  }
  ind_rec <- tryCatch(map_x(fread(f_ind), "v2peio1icd", "v2ind_codeyear", "v2censusind_2002recode",
                            hires$v2peio1icd, hires$ind_era, c(1990, 2002, 2007, 2012)),
                      error = function(e) rep(NA_character_, nrow(hires)))
  occ_rec <- tryCatch(map_x(fread(f_occ), "v2peio1ocd", "v2occ_codeyear", "v2censusocc_2002recode",
                            hires$v2peio1ocd, hires$occ_era, c(1990, 2000, 2010)),
                      error = function(e) rep(NA_character_, nrow(hires)))
  hires[, indfe := fifelse(!is.na(ind_rec) & ind_rec != "" & ind_rec != "NA", paste0("x", ind_rec),
                           paste0("r", ind_era, "_", v2peio1icd))]
  hires[, occfe := fifelse(!is.na(occ_rec) & occ_rec != "" & occ_rec != "NA", paste0("x", occ_rec),
                           paste0("r", occ_era, "_", v2peio1ocd))]
  hires <- hires[is.finite(logw)]
  mW <- safe(feols(logw ~ young + yU + eU | state + demog + ym + occfe + indfe,
                   data = hires, weights = ~w, cluster = ~state, lean = TRUE))
}

out <- list(
  young_x_unemp_rate_no_controls        = getc(mB1, "yU"),
  experienced_x_unemp_rate_no_controls  = getc(mB1, "eU"),
  young_x_unemp_rate_preferred          = getc(mB4, "yU"),
  experienced_x_unemp_rate_preferred    = getc(mB4, "eU"),
  aggregate_unemp_rate_no_controls      = getc(mA1, "urate"),
  aggregate_unemp_rate_month_year_fe    = getc(mA4, "urate"),
  young_x_unemp_rate_employed           = getc(mE, "yU"),
  experienced_x_unemp_rate_employed     = getc(mE, "eU"),
  young_x_unemp_rate_unemployed         = getc(mU, "yU"),
  young_x_unemp_rate_nilf               = getc(mN, "yU"),
  wage_young_x_unemp_rate_all_hires     = getc(mW, "yU"),
  wage_experienced_x_unemp_rate_all_hires = getc(mW, "eU"),
  n_obs_full_sample                     = n_full
)
for (nm in names(out)) {
  v <- out[[nm]]
  cat(sprintf("RESULT:%s=%s\n", nm, if (is.na(v)) "NA" else format(v, digits = 10, scientific = FALSE)))
}
