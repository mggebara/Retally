suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
options(warn = 1)
setDTthreads(0)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_ur   <- file.path(base, "v2unemp_smy.csv")
f_cpi  <- file.path(base, "wage_deflation_1994_2016.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")

say <- function(...) { cat(..., "\n", sep = ""); flush.console() }
emit <- function(nm, v) {
  if (length(v) == 1 && !is.null(v) && !is.na(v)) { cat(sprintf("RESULT:%s=%.6g\n", nm, v)); flush.console() }
}

hdr <- names(fread(f_main, nrows = 0))
lh <- tolower(hdr)
pick <- function(cands) {
  for (cc in cands) {
    i <- which(lh == cc)
    if (length(i)) return(hdr[i[1]])
  }
  NA_character_
}
pick_grep <- function(pattern, prefer_v2 = TRUE) {
  i <- grep(pattern, lh)
  if (!length(i)) return(NA_character_)
  if (prefer_v2) {
    j <- i[grepl("^v2", lh[i])]
    if (length(j)) return(hdr[j[1]])
  }
  hdr[i[1]]
}

cols <- list(
  pm = pick(c("hrmonth")), py = pick(c("hryear", "hryear4")),
  cm = pick(c("v2hrmonth")), cy = pick(c("v2hryear", "v2hryear4")),
  age = pick(c("peage", "v2peage", "prtage", "v2prtage")),
  sex = pick(c("pesex", "v2pesex")),
  educ = pick(c("peeduca", "v2peeduca")),
  race = pick(c("race", "v2race", "ptdtrace", "perace", "v2ptdtrace", "v2perace")),
  hisp = pick(c("prhspnon", "v2prhspnon", "pehspnon", "v2pehspnon")),
  labp = pick(c("pemlr")), labc = pick(c("v2pemlr")),
  st = pick(c("v2gestfips", "gestfips")),
  st1 = pick(c("gestfips")),
  w1 = pick(c("pwsswgt")), w2 = pick(c("v2pwsswgt")),
  iodp = pick(c("v2puiodp1")), cow = pick(c("v2peio1cow")),
  icd = pick(c("v2peio1icd")), ocd = pick(c("v2peio1ocd")),
  indcy = pick(c("v2ind_codeyear")), occcy = pick(c("v2occ_codeyear")),
  earn = pick(c("v2prernwa", "v2pternwa")),
  alloc = pick(c("v2prwernal", "v2prwernal1")),
  mis = pick(c("v2hrmis", "v2hrmmis", "v2hrmis1"))
)
if (is.na(cols$earn)) cols$earn <- pick_grep("ernwa")
if (is.na(cols$alloc)) cols$alloc <- pick_grep("wernal")
if (is.na(cols$mis)) cols$mis <- pick_grep("^v2hrm?mis")
if (!is.na(cols$st1) && !is.na(cols$st) && cols$st1 == cols$st) cols$st1 <- NA_character_
cols <- cols[!is.na(unlist(cols))]
say("Using columns:"); print(unlist(cols))

dt <- fread(f_main, select = unname(unlist(cols)), showProgress = FALSE)
setnames(dt, unname(unlist(cols)), names(cols))
say("Rows read: ", nrow(dt))

num <- function(x) suppressWarnings(as.numeric(x))
for (v in names(dt)) if (!is.numeric(dt[[v]])) set(dt, j = v, value = num(dt[[v]]))
gc()

# ---- normalise survey years (CPS HRYEAR is 2-digit in early files) ----
fixy <- function(y) fifelse(!is.na(y) & y < 50, y + 2000, fifelse(!is.na(y) & y < 100, y + 1900, y))
for (v in intersect(c("cy", "py"), names(dt))) set(dt, j = v, value = fixy(dt[[v]]))
say("Year distribution (current month):"); print(table(dt$cy, useNA = "ifany"))

# ---- state: fall back on t-1 state when t state missing ----
if ("st1" %in% names(dt)) {
  say("Missing v2 state before fallback: ", sum(is.na(dt$st) | dt$st <= 0))
  dt[is.na(st) | st <= 0, st := st1]
  dt[, st1 := NULL]
}

# ---- basic sample restrictions (single subset to limit memory) ----
keep <- !is.na(dt$age) & !is.na(dt$educ) & dt$age >= 16 & dt$educ > 0 &
  dt$labp %in% 1:7 & dt$labc %in% 1:7
tcv <- dt$cy * 12 + dt$cm
if (all(c("pm", "py") %in% names(dt))) {
  tpv <- dt$py * 12 + dt$pm
  cons <- (tcv - tpv) == 1
  share1 <- mean(cons[keep], na.rm = TRUE)
  say("Share consecutive: ", share1)
  if (share1 > 0.5) keep <- keep & !is.na(cons) & cons
  keep <- keep & !((dt$cy == 1995 & dt$cm %in% 5:8) | (dt$py == 1995 & dt$pm %in% 5:8))
  rm(tpv, cons)
}
keep <- keep & !is.na(tcv) & tcv >= 1994 * 12 + 1 & tcv <= 2016 * 12 + 9
keep[is.na(keep)] <- FALSE
rm(tcv); gc()
dt <- dt[keep]
rm(keep); gc()
for (v in intersect(c("pm", "py"), names(dt))) set(dt, j = v, value = NULL)
gc()
say("Rows after restrictions: ", nrow(dt))

# ---- education ----
if (median(dt$educ, na.rm = TRUE) > 30) {
  yrs_map <- c(`31` = 0, `32` = 2.5, `33` = 5.5, `34` = 7.5, `35` = 9, `36` = 10, `37` = 11,
               `38` = 12, `39` = 12, `40` = 13, `41` = 14, `42` = 14, `43` = 16, `44` = 18,
               `45` = 18, `46` = 20)
  dt[, yrs := unname(yrs_map[as.character(educ)])]
  dt[, ed7 := fifelse(educ <= 38, 1L, fifelse(educ == 39, 2L, fifelse(educ <= 42, 3L,
               fifelse(educ == 43, 4L, fifelse(educ == 44, 5L, fifelse(educ == 45, 6L, 7L))))))]
} else {
  dt[, yrs := educ]
  dt[, ed7 := cut(educ, c(-Inf, 11.5, 12.5, 15.5, 16.5, 18.5, 19.5, Inf), labels = FALSE)]
}
dt <- dt[!is.na(yrs)]
dt[, young := as.integer((age - yrs - 6) <= 10)]
dt[, c("yrs") := NULL]
gc()

# ---- demographic cells ----
if (!"race" %in% names(dt)) dt[, race := 1]
if (!"hisp" %in% names(dt)) dt[, hisp := 2]
if (!"sex" %in% names(dt)) dt[, sex := 1]
dt[, demo := as.integer(((as.integer(!is.na(sex) & sex == 1) * 2L + as.integer(!is.na(race) & race == 1)) * 2L +
                          as.integer(!is.na(hisp) & hisp == 1)) * 10L + ed7)]
dt[, c("race", "hisp", "sex", "educ", "ed7") := NULL]

# ---- hire ----
if (!"cow" %in% names(dt)) dt[, cow := NA_real_]
if (!"iodp" %in% names(dt)) dt[, iodp := NA_real_]
dt[, hire := 100L * as.integer((labc %in% 1:2) & !(!is.na(cow) & cow %in% c(6, 7)) &
                                 ((!(labp %in% 1:2)) | ((labp %in% 1:2) & !is.na(iodp) & iodp == 2)))]
dt[, orig := fifelse(labp %in% 1:2, 1L, fifelse(labp %in% 3:4, 2L, 3L))]
dt[, c("cow", "iodp", "labp", "labc") := NULL]

# ---- weights ----
if ("w2" %in% names(dt)) {
  dt[, w := fifelse(is.na(w1), as.numeric(w2), fifelse(is.na(w2), as.numeric(w1), (w1 + w2) / 2))]
  dt[, c("w1", "w2") := NULL]
} else {
  setnames(dt, "w1", "w")
}
dt <- dt[!is.na(w) & w > 0]
gc()

# ---- state unemployment rate (robust column detection) ----
ur <- fread(f_ur)
setnames(ur, tolower(names(ur)))
say("UR file columns: ", paste(names(ur), collapse = ", "))
fcol <- function(d, pats, exclude = character(0)) {
  nm <- setdiff(names(d), exclude)
  for (p in pats) { i <- grep(p, nm); if (length(i)) return(nm[i[1]]) }
  NA_character_
}
c_st <- fcol(ur, c("gestfips", "fips", "^state$", "state", "^st$", "stat"))
c_ur <- fcol(ur, c("unemp", "^ur$", "urate", "rate", "ur"), exclude = c_st)
c_yr <- fcol(ur, c("hryear", "year", "^yr$", "^y$"), exclude = c(c_st, c_ur))
c_mo <- fcol(ur, c("hrmonth", "month", "^mo$", "^m$"), exclude = c(c_st, c_ur, c_yr))
say("UR mapping: st=", c_st, " ur=", c_ur, " year=", c_yr, " month=", c_mo)
fips_abb <- c(AL=1,AK=2,AZ=4,AR=5,CA=6,CO=8,CT=9,DE=10,DC=11,FL=12,GA=13,HI=15,ID=16,IL=17,IN=18,IA=19,
              KS=20,KY=21,LA=22,ME=23,MD=24,MA=25,MI=26,MN=27,MS=28,MO=29,MT=30,NE=31,NV=32,NH=33,NJ=34,
              NM=35,NY=36,NC=37,ND=38,OH=39,OK=40,OR=41,PA=42,RI=44,SC=45,SD=46,TN=47,TX=48,UT=49,VT=50,
              VA=51,WA=53,WV=54,WI=55,WY=56)
stv <- ur[[c_st]]
stn <- num(stv)
if (mean(is.na(stn)) > 0.5) stn <- unname(fips_abb[toupper(trimws(as.character(stv)))])
if (!is.na(c_yr) && !is.na(c_mo)) {
  yv <- num(ur[[c_yr]]); mv <- num(ur[[c_mo]])
} else {
  c_dt <- fcol(ur, c("date", "ym", "time", "period"), exclude = c(c_st, c_ur))
  dv <- num(ur[[c_dt]])
  yv <- dv %/% 100; mv <- dv %% 100
}
yv <- fixy(yv)
ur2 <- data.table(st = as.integer(stn), cy = as.integer(yv), cm = as.integer(mv), ur = num(ur[[c_ur]]))
ur2 <- unique(ur2[!is.na(st) & !is.na(cy) & !is.na(cm) & !is.na(ur)], by = c("st", "cy", "cm"))
if (max(ur2$ur, na.rm = TRUE) < 1) ur2[, ur := ur * 100]
rm(ur); gc()
say("UR rows: ", nrow(ur2), " range: ", min(ur2$ur), "-", max(ur2$ur))
say("UR year coverage:"); print(table(ur2$cy))

# fill interior gaps in the state-month series (e.g. missing months) by linear interpolation
grid <- CJ(st = sort(unique(ur2$st)), cy = 1994:2016, cm = 1:12)[cy * 12L + cm <= 2016L * 12L + 9L]
ur2 <- merge(grid, ur2, by = c("st", "cy", "cm"), all.x = TRUE)
setorder(ur2, st, cy, cm)
n_miss0 <- sum(is.na(ur2$ur))
ur2[, ur := if (sum(!is.na(ur)) >= 2) zoo::na.approx(ur, na.rm = FALSE) else ur, by = st]
n_filled <- n_miss0 - sum(is.na(ur2$ur))
say("UR state-months missing on grid: ", n_miss0, "; filled by interpolation: ", n_filled)
if (n_filled > 0) cat(sprintf("DEVIATION: Linearly interpolated %d missing interior state-month unemployment rates so matched observations in those months are not dropped\n", n_filled))
ur2 <- ur2[!is.na(ur)]

for (v in c("st", "cy", "cm")) if (!is.integer(dt[[v]])) set(dt, j = v, value = as.integer(dt[[v]]))
dt[ur2, on = .(st, cy, cm), ur := i.ur]
say("Rows without UR match by year:"); print(dt[is.na(ur), .N, by = cy][order(cy)])
dt <- dt[!is.na(ur)]
gc()
dt[, ym := as.integer(cy * 100L + cm)]
dt[, yu := young * ur]
dt[, ou := (1 - young) * ur]
say("Analysis N: ", nrow(dt))
say("Mean hire young: ", dt[young == 1, weighted.mean(hire, w)],
    " experienced: ", dt[young == 0, weighted.mean(hire, w)])

# ---- split off hires for wage regressions; drop wage-only columns from main data ----
wcols <- intersect(c("icd", "ocd", "indcy", "occcy", "earn", "alloc", "mis"), names(dt))
h0 <- dt[hire == 100]
if (length(wcols)) dt[, (wcols) := NULL]
gc()

safe <- function(expr) tryCatch(expr, error = function(e) { message("Error: ", conditionMessage(e)); NULL })
getc <- function(m, v) if (is.null(m)) NA else unname(coef(m)[v])

m_b4 <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt, weights = ~w, cluster = ~st,
                   lean = TRUE, mem.clean = TRUE))
emit("young_x_unemp_rate_preferred", getc(m_b4, "yu"))
emit("experienced_x_unemp_rate_preferred", getc(m_b4, "ou"))
if (!is.null(m_b4)) print(coeftable(m_b4))
n_full <- if (!is.null(m_b4)) nobs(m_b4) else nrow(dt)
emit("n_obs_full_sample", n_full)
rm(m_b4); gc()

m_a1 <- safe(feols(hire ~ ur, data = dt, weights = ~w, cluster = ~st, lean = TRUE, mem.clean = TRUE))
emit("aggregate_unemp_rate_no_controls", getc(m_a1, "ur")); rm(m_a1); gc()

m_a4 <- safe(feols(hire ~ ur | st + ym + demo, data = dt, weights = ~w, cluster = ~st, lean = TRUE, mem.clean = TRUE))
emit("aggregate_unemp_rate_month_year_fe", getc(m_a4, "ur")); rm(m_a4); gc()

m_b1 <- safe(feols(hire ~ young + yu + ou, data = dt, weights = ~w, cluster = ~st, lean = TRUE, mem.clean = TRUE))
emit("young_x_unemp_rate_no_controls", getc(m_b1, "yu"))
emit("experienced_x_unemp_rate_no_controls", getc(m_b1, "ou")); rm(m_b1); gc()

m_e <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt[orig == 1], weights = ~w, cluster = ~st, lean = TRUE, mem.clean = TRUE))
emit("young_x_unemp_rate_employed", getc(m_e, "yu"))
emit("experienced_x_unemp_rate_employed", getc(m_e, "ou")); rm(m_e); gc()

m_u <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt[orig == 2], weights = ~w, cluster = ~st, lean = TRUE, mem.clean = TRUE))
emit("young_x_unemp_rate_unemployed", getc(m_u, "yu")); rm(m_u); gc()

m_n <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt[orig == 3], weights = ~w, cluster = ~st, lean = TRUE, mem.clean = TRUE))
emit("young_x_unemp_rate_nilf", getc(m_n, "yu")); rm(m_n); gc()

rm(dt); gc()

# ---- wage regressions for new hires ----
wage_res <- safe({
  if (!"earn" %in% names(h0)) stop("no weekly earnings column")
  h <- h0[!is.na(earn) & earn > 0]
  if ("mis" %in% names(h)) {
    hh <- h[mis %in% c(4, 8)]
    if (nrow(hh) > 1000) h <- hh
  }
  if ("alloc" %in% names(h)) {
    av <- unique(h$alloc)
    if (0 %in% av) h <- h[is.na(alloc) | alloc <= 0]
  }
  h[, lw := log(earn)]
  try({
    cpi <- fread(f_cpi)
    setnames(cpi, tolower(names(cpi)))
    say("CPI file columns: ", paste(names(cpi), collapse = ", "))
    cy_c <- fcol(cpi, c("hryear", "year"))
    cm_c <- fcol(cpi, c("hrmonth", "month"), exclude = cy_c)
    cp_c <- fcol(cpi, c("cpi", "deflat", "index", "price"), exclude = c(cy_c, cm_c))
    if (!is.na(cy_c) && !is.na(cm_c) && !is.na(cp_c)) {
      cpi <- cpi[, .(cy = as.integer(fixy(num(get(cy_c)))), cm = as.integer(num(get(cm_c))), cpi = num(get(cp_c)))]
      cpi <- unique(cpi[!is.na(cy) & !is.na(cm) & !is.na(cpi) & cpi > 0], by = c("cy", "cm"))
      h[cpi, on = .(cy, cm), cpiv := i.cpi]
      h[!is.na(cpiv), lw := log(earn / cpiv)]
      h[, cpiv := NULL]
    }
  }, silent = FALSE)

  h[, ind_v := fifelse(cy <= 2002, 1990, fifelse(cy <= 2008, 2002, fifelse(cy <= 2013, 2007, 2012)))]
  h[, occ_v := fifelse(cy <= 2002, 1990, fifelse(cy <= 2010, 2000, 2010))]
  closest <- function(x, avail) avail[vapply(x, function(z) which.min(abs(avail - z)), integer(1))]

  h[, indfe := paste0("r", ind_v, "_", icd)]
  h[, occfe := paste0("r", occ_v, "_", ocd)]
  try({
    ix <- fread(f_ind); setnames(ix, tolower(names(ix)))
    ix <- ix[, .(icd = num(v2peio1icd), icy = num(v2ind_codeyear), irec = as.character(v2censusind_2002recode))]
    ix <- unique(ix[!is.na(icd) & !is.na(icy)], by = c("icd", "icy"))
    if ("indcy" %in% names(h) && mean(h$indcy %in% ix$icy) > 0.5) {
      h[, icy := as.numeric(indcy)]
    } else {
      av <- sort(unique(ix$icy))
      uv <- unique(h$ind_v)
      mp <- setNames(closest(uv, av), uv)
      h[, icy := unname(mp[as.character(ind_v)])]
    }
    h[, icd := as.numeric(icd)]
    h <- merge(h, ix, by = c("icd", "icy"), all.x = TRUE)
    say("Industry crosswalk match rate: ", mean(!is.na(h$irec)))
    h[!is.na(irec) & irec != "", indfe := paste0("x", irec)]
  }, silent = FALSE)
  try({
    ox <- fread(f_occ); setnames(ox, tolower(names(ox)))
    ox <- ox[, .(ocd = num(v2peio1ocd), ocy = num(v2occ_codeyear), orec = as.character(v2censusocc_2002recode))]
    ox <- unique(ox[!is.na(ocd) & !is.na(ocy)], by = c("ocd", "ocy"))
    if ("occcy" %in% names(h) && mean(h$occcy %in% ox$ocy) > 0.5) {
      h[, ocy := as.numeric(occcy)]
    } else {
      av <- sort(unique(ox$ocy))
      uv <- unique(h$occ_v)
      mp <- setNames(closest(uv, av), uv)
      h[, ocy := unname(mp[as.character(occ_v)])]
    }
    h[, ocd := as.numeric(ocd)]
    h <- merge(h, ox, by = c("ocd", "ocy"), all.x = TRUE)
    say("Occupation crosswalk match rate: ", mean(!is.na(h$orec)))
    h[!is.na(orec) & orec != "", occfe := paste0("x", orec)]
  }, silent = FALSE)

  h <- h[is.finite(lw)]
  say("Wage sample N: ", nrow(h))
  mw <- feols(lw ~ young + yu + ou | st + ym + demo + occfe + indfe, data = h,
              weights = ~w, cluster = ~st)
  print(coeftable(mw))
  list(y = unname(coef(mw)["yu"]), o = unname(coef(mw)["ou"]))
})
if (!is.null(wage_res)) {
  emit("wage_young_x_unemp_rate_all_hires", wage_res$y)
  emit("wage_experienced_x_unemp_rate_all_hires", wage_res$o)
}
