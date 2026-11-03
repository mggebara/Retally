suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free"
ddir <- file.path(base, "3 replication package", "Data")
f_main <- file.path(ddir, "yh_data.csv")
f_unemp <- file.path(ddir, "v2unemp_smy.csv")
f_cpi <- file.path(ddir, "wage_deflation_1994_2016.csv")

hdr <- names(fread(f_main, nrows = 0))
message("Columns: ", paste(hdr, collapse = ","))
hdr_l <- tolower(hdr)
pick <- function(cands) {
  for (cc in tolower(cands)) {
    i <- which(hdr_l == cc)
    if (length(i)) return(hdr[i[1]])
  }
  NA_character_
}
pick_re <- function(re, exclude = NULL) {
  i <- grep(re, hdr_l)
  if (!is.null(exclude)) i <- i[!grepl(exclude, hdr_l[i])]
  if (length(i)) hdr[i[1]] else NA_character_
}

cmap <- list(
  mon0 = pick(c("hrmonth")),
  yr0 = pick(c("hryear4", "hryear")),
  age = pick(c("peage", "prtage")),
  sex = pick(c("pesex")),
  educ = pick(c("peeduca")),
  race = pick(c("race", "ptdtrace", "perace", "prdtrace")),
  hisp = pick(c("prhspnon", "pehspnon")),
  lfs0 = pick(c("pemlr")),
  w0 = pick(c("pwsswgt")),
  mon1 = pick(c("v2hrmonth")),
  yr1 = pick(c("v2hryear4", "v2hryear")),
  st = pick(c("v2gestfips", "gestfips")),
  lfs1 = pick(c("v2pemlr")),
  iodp = pick(c("v2puiodp1")),
  cow = pick(c("v2peio1cow")),
  ind = pick(c("v2peio1icd")),
  occ = pick(c("v2peio1ocd")),
  w1 = pick(c("v2pwsswgt")),
  u = pick(c("v2unemp_smy", "unemp_smy")),
  hire = pick(c("hired", "hire", "d_hired", "dhired")),
  earn = pick(c("v2prernwa", "v2pternwa")),
  alloc = pick_re("^v2(prwernal|pxernwa)"),
  mis1 = pick(c("v2hrmis")),
  mis0 = pick(c("hrmis"))
)
if (is.na(cmap$earn)) cmap$earn <- pick_re("^v2.*ernwa", exclude = "al$|^v2px")
cmap <- cmap[!is.na(unlist(cmap))]
message("Using: ", paste(names(cmap), unlist(cmap), sep = "=", collapse = "; "))

dt <- fread(f_main, select = unname(unlist(cmap)), showProgress = FALSE)
setnames(dt, unname(unlist(cmap)), names(cmap))
gc()

num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(sub("^\\s*(-?[0-9]+(\\.[0-9]+)?).*$", "\\1", as.character(x))))
}
fixyr <- function(y) ifelse(!is.na(y) & y < 100, ifelse(y >= 50, 1900 + y, 2000 + y), y)
monnum <- function(x) {
  y <- num(x)
  if (all(is.na(y)) && !is.numeric(x)) {
    y <- match(substr(tolower(trimws(x)), 1, 3), tolower(month.abb))
  }
  y
}
lfs_code <- function(x) {
  y <- num(x)
  if (!is.numeric(x) && mean(is.na(y)) > 0.5) {
    s <- tolower(as.character(x))
    y <- ifelse(grepl("layoff", s), 3,
         ifelse(grepl("unemployed|looking", s), 4,
         ifelse(grepl("absent", s), 2,
         ifelse(grepl("employed", s), 1,
         ifelse(grepl("retired", s), 5,
         ifelse(grepl("disab", s), 6,
         ifelse(grepl("other|nilf|not in", s), 7, NA_real_)))))))
  }
  y
}

dt[, mon0 := monnum(mon0)]
dt[, mon1 := monnum(mon1)]
dt[, yr0 := fixyr(num(yr0))]
dt[, yr1 := fixyr(num(yr1))]
dt[, age := num(age)]
dt[, educ := num(educ)]
dt[, lfs0 := lfs_code(lfs0)]
dt[, lfs1 := lfs_code(lfs1)]
dt[, st := num(st)]

# sex
if (is.numeric(dt$sex)) dt[, male := as.integer(sex == 1)] else
  dt[, male := as.integer(grepl("^m|^1", tolower(trimws(sex))))]
# race white / non-white
if (is.numeric(dt$race)) dt[, white := as.integer(race == 1)] else
  dt[, white := as.integer(grepl("^white|^1$|^1[^0-9]", tolower(trimws(race))))]
# hispanic
if ("hisp" %in% names(dt)) {
  if (is.numeric(dt$hisp)) dt[, hispanic := as.integer(hisp == 1)] else
    dt[, hispanic := as.integer(grepl("^hisp|^1$|^1[^0-9]", tolower(trimws(hisp))))]
} else dt[, hispanic := 0L]

# weights: average across the two matched months
dt[, w0 := num(w0)]
if ("w1" %in% names(dt)) {
  dt[, w1 := num(w1)]
  dt[, wt := ifelse(!is.na(w1) & w1 > 0, (w0 + w1) / 2, w0)]
} else dt[, wt := w0]

# unemployment rate
if (!("u" %in% names(dt))) {
  un <- fread(f_unemp, showProgress = FALSE)
  setnames(un, tolower(names(un)))
  un[, `:=`(st = num(v2gestfips), yr1 = fixyr(num(v2hryear)), mon1 = monnum(v2hrmonth), u = num(v2unemp_smy))]
  un <- unique(un[, .(st, yr1, mon1, u)], by = c("st", "yr1", "mon1"))
  dt <- merge(dt, un, by = c("st", "yr1", "mon1"), all.x = TRUE, sort = FALSE)
} else dt[, u := num(u)]
if (max(dt$u, na.rm = TRUE) < 1) dt[, u := 100 * u]

# hire indicator
if ("hire" %in% names(dt)) {
  dt[, hired := num(hire)]
  if (max(dt$hired, na.rm = TRUE) <= 1) dt[, hired := 100 * hired]
} else {
  if ("cow" %in% names(dt)) {
    if (is.numeric(dt$cow)) dt[, selfemp := cow %in% c(6, 7)] else
      dt[, selfemp := grepl("self", tolower(cow)) | num(cow) %in% c(6, 7)]
  } else dt[, selfemp := FALSE]
  if (is.numeric(dt$iodp)) dt[, newfirm := !is.na(iodp) & iodp == 2] else
    dt[, newfirm := grepl("^\\s*no|^\\s*2", tolower(as.character(iodp)))]
  dt[, emp0 := lfs0 %in% c(1, 2)]
  dt[, emp1 := lfs1 %in% c(1, 2)]
  dt[, hired := 100 * as.numeric(((!emp0 & emp1) | (emp0 & emp1 & newfirm)) & !selfemp)]
}

# education
dt[, yrs_educ := c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 20, 20)[educ - 30]]
dt[, educ7 := fifelse(educ <= 38, 1L, fifelse(educ == 39, 2L, fifelse(educ <= 42, 3L,
               fifelse(educ == 43, 4L, fifelse(educ == 44, 5L, fifelse(educ == 45, 6L, 7L))))))]
dt[, pe := age - yrs_educ - 6]

# sample restrictions
dt <- dt[!is.na(age) & age >= 16 & !is.na(educ) & educ >= 31 & educ <= 46 &
         lfs0 %in% 1:7 & lfs1 %in% 1:7 & !is.na(u) & !is.na(st) &
         !is.na(wt) & wt > 0 & !is.na(hired)]
dt <- dt[!(yr1 == 1995 & mon1 %in% 5:8) & !(yr0 == 1995 & mon0 %in% 5:8)]
dt <- dt[(yr1 * 12 + mon1) <= (2016 * 12 + 9) & (yr0 * 12 + mon0) >= (1994 * 12 + 1)]
if ("mis1" %in% names(dt)) {
  dt[, mis1 := num(mis1)]
  dt <- dt[is.na(mis1) | mis1 != 5]
}

dt[, young := as.numeric(pe <= 10)]
dt[, yU := young * u]
dt[, oU := (1 - young) * u]
dt[, demo := paste(male, white, hispanic, educ7, sep = "_")]
dt[, my := yr1 * 100 + mon1]
dt[, state := st]
gc()
message("N sample: ", nrow(dt))

res <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NULL })

m1 <- safe(feols(hired ~ young + yU + oU, data = dt, weights = ~wt, cluster = ~state, lean = TRUE))
if (!is.null(m1)) {
  res$young_x_unemp_rate_no_controls <- coef(m1)["yU"]
  res$experienced_x_unemp_rate_no_controls <- coef(m1)["oU"]
  res$n_obs_full_sample <- nobs(m1)
  message("SE col1: ", paste(round(sqrt(diag(vcov(m1)))[c("yU", "oU")], 4), collapse = ", "))
}
rm(m1); gc()

m4 <- safe(feols(hired ~ young + yU + oU | state + demo + my, data = dt, weights = ~wt, cluster = ~state, lean = TRUE))
if (!is.null(m4)) {
  res$young_x_unemp_rate_preferred <- coef(m4)["yU"]
  res$experienced_x_unemp_rate_preferred <- coef(m4)["oU"]
  message("SE col4: ", paste(round(sqrt(diag(vcov(m4)))[c("yU", "oU")], 4), collapse = ", "))
}
rm(m4); gc()

a1 <- safe(feols(hired ~ u, data = dt, weights = ~wt, cluster = ~state, lean = TRUE))
if (!is.null(a1)) res$aggregate_unemp_rate_no_controls <- coef(a1)["u"]
rm(a1); gc()

a4 <- safe(feols(hired ~ u | state + demo + my, data = dt, weights = ~wt, cluster = ~state, lean = TRUE))
if (!is.null(a4)) res$aggregate_unemp_rate_month_year_fe <- coef(a4)["u"]
rm(a4); gc()

me <- safe(feols(hired ~ young + yU + oU | state + demo + my, data = dt[lfs0 %in% 1:2],
                 weights = ~wt, cluster = ~state, lean = TRUE))
if (!is.null(me)) {
  res$young_x_unemp_rate_employed <- coef(me)["yU"]
  res$experienced_x_unemp_rate_employed <- coef(me)["oU"]
}
rm(me); gc()

mu <- safe(feols(hired ~ young + yU + oU | state + demo + my, data = dt[lfs0 %in% 3:4],
                 weights = ~wt, cluster = ~state, lean = TRUE))
if (!is.null(mu)) res$young_x_unemp_rate_unemployed <- coef(mu)["yU"]
rm(mu); gc()

mn <- safe(feols(hired ~ young + yU + oU | state + demo + my, data = dt[lfs0 %in% 5:7],
                 weights = ~wt, cluster = ~state, lean = TRUE))
if (!is.null(mn)) res$young_x_unemp_rate_nilf <- coef(mn)["yU"]
rm(mn); gc()

# wage regression for new hires (outgoing rotation months)
if ("earn" %in% names(dt)) {
  safe({
    wd <- dt[hired == 100]
    wd[, earn := num(earn)]
    wd <- wd[!is.na(earn) & earn > 0]
    if ("mis1" %in% names(wd)) {
      if (any(wd$mis1 %in% c(4, 8))) wd <- wd[mis1 %in% c(4, 8)]
    } else if ("mis0" %in% names(wd)) {
      wd[, mis0 := num(mis0)]
      if (any(wd$mis0 %in% c(3, 7))) wd <- wd[mis0 %in% c(3, 7)]
    }
    if ("alloc" %in% names(wd)) {
      wd[, alloc := num(alloc)]
      an <- tolower(cmap$alloc)
      if (grepl("wernal", an)) wd <- wd[is.na(alloc) | alloc != 1]
      else wd <- wd[is.na(alloc) | alloc < 10]
    }
    cpi <- fread(f_cpi, showProgress = FALSE)
    setnames(cpi, tolower(names(cpi)))
    cpi[, `:=`(yr1 = fixyr(num(year)), mon1 = monnum(month), cpi = num(cpi))]
    cpi <- unique(cpi[, .(yr1, mon1, cpi)], by = c("yr1", "mon1"))
    wd <- merge(wd, cpi, by = c("yr1", "mon1"), all.x = TRUE, sort = FALSE)
    wd <- wd[!is.na(cpi) & cpi > 0]
    wd[, logw := log(earn) - log(cpi)]
    wd[, period := fifelse(yr1 <= 2002, 1L, fifelse(yr1 <= 2008, 2L, fifelse(yr1 <= 2010, 3L,
                    fifelse(yr1 <= 2013, 4L, 5L))))]
    fes <- "state + demo + my"
    if ("occ" %in% names(wd)) { wd[, occfe := paste(num(occ), period)]; fes <- paste(fes, "+ occfe") }
    if ("ind" %in% names(wd)) { wd[, indfe := paste(num(ind), period)]; fes <- paste(fes, "+ indfe") }
    message("Wage N: ", nrow(wd))
    mw <- feols(as.formula(paste("logw ~ young + yU + oU |", fes)), data = wd,
                weights = ~wt, cluster = ~state)
    res$wage_young_x_unemp_rate_all_hires <- coef(mw)["yU"]
    res$wage_experienced_x_unemp_rate_all_hires <- coef(mw)["oU"]
    NULL
  })
}

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(unname(as.numeric(res[[nm]])), digits = 8, scientific = FALSE)))
}
