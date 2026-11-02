suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
options(warn = 1)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_ur   <- file.path(base, "v2unemp_smy.csv")
f_cpi  <- file.path(base, "wage_deflation_1994_2016.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")

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
cols <- cols[!is.na(unlist(cols))]
cat("Using columns:\n"); print(unlist(cols))

dt <- fread(f_main, select = unname(unlist(cols)), showProgress = FALSE)
setnames(dt, unname(unlist(cols)), names(cols))
cat("Rows read:", nrow(dt), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
for (v in names(dt)) if (!is.numeric(dt[[v]])) set(dt, j = v, value = num(dt[[v]]))

# ---- basic sample restrictions ----
dt <- dt[!is.na(age) & !is.na(educ) & age >= 16 & educ > 0]
dt <- dt[labp %in% 1:7 & labc %in% 1:7]

if (all(c("pm", "py", "cm", "cy") %in% names(dt))) {
  dt[, tc := cy * 12 + cm]
  dt[, tp := py * 12 + pm]
  share1 <- mean(dt$tc - dt$tp == 1, na.rm = TRUE)
  cat("Share consecutive:", share1, "\n")
  if (share1 > 0.5) dt <- dt[tc - tp == 1]
  dt <- dt[!((cy == 1995 & cm %in% 5:8) | (py == 1995 & pm %in% 5:8))]
  dt[, c("tp") := NULL]
} else {
  dt[, tc := cy * 12 + cm]
}
dt <- dt[tc >= 1994 * 12 + 1 & tc <= 2016 * 12 + 9]

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
dt[, pe := age - yrs - 6]
dt[, young := as.integer(pe <= 10)]

# ---- demographic cells ----
if (!"race" %in% names(dt)) dt[, race := 1]
if (!"hisp" %in% names(dt)) dt[, hisp := 2]
if (!"sex" %in% names(dt)) dt[, sex := 1]
dt[, white := as.integer(!is.na(race) & race == 1)]
dt[, hispan := as.integer(!is.na(hisp) & hisp == 1)]
dt[, demo := as.integer((as.integer(sex == 1) * 2 + white) * 2 + hispan) * 10L + ed7]

# ---- hire ----
dt[, empp := labp %in% 1:2]
dt[, empc := labc %in% 1:2]
if (!"cow" %in% names(dt)) dt[, cow := NA_real_]
if (!"iodp" %in% names(dt)) dt[, iodp := NA_real_]
dt[, selfemp := !is.na(cow) & cow %in% c(6, 7)]
dt[, newemp := !is.na(iodp) & iodp == 2]
dt[, hire := 100 * as.integer(empc & !selfemp & ((!empp) | (empp & newemp)))]
dt[, orig := fifelse(labp %in% 1:2, 1L, fifelse(labp %in% 3:4, 2L, 3L))]

# ---- weights ----
if ("w2" %in% names(dt)) {
  dt[, w := rowMeans(cbind(w1, w2), na.rm = TRUE)]
} else {
  dt[, w := w1]
}
dt <- dt[!is.na(w) & w > 0]

# ---- state unemployment rate ----
ur <- fread(f_ur)
setnames(ur, tolower(names(ur)))
setnames(ur, c("v2gestfips", "v2unemp_smy", "v2hryear", "v2hrmonth"), c("st", "ur", "cy", "cm"))
ur <- ur[, .(st = as.numeric(st), cy = as.numeric(cy), cm = as.numeric(cm), ur = as.numeric(ur))]
ur <- unique(ur, by = c("st", "cy", "cm"))
if (max(ur$ur, na.rm = TRUE) < 1) ur[, ur := ur * 100]
dt <- merge(dt, ur, by = c("st", "cy", "cm"), all.x = FALSE)
dt <- dt[!is.na(ur)]
dt[, ym := as.integer(cy * 100 + cm)]
dt[, yu := young * ur]
dt[, ou := (1 - young) * ur]
cat("Analysis N:", nrow(dt), "\n")
cat("Mean hire young:", dt[young == 1, weighted.mean(hire, w)],
    " experienced:", dt[young == 0, weighted.mean(hire, w)], "\n")

res <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { message("Error: ", conditionMessage(e)); NULL })
getc <- function(m, v) if (is.null(m)) NA else unname(coef(m)[v])

m_a1 <- safe(feols(hire ~ ur, data = dt, weights = ~w, cluster = ~st, lean = TRUE))
res$aggregate_unemp_rate_no_controls <- getc(m_a1, "ur"); rm(m_a1); gc()

m_a4 <- safe(feols(hire ~ ur | st + ym + demo, data = dt, weights = ~w, cluster = ~st, lean = TRUE))
res$aggregate_unemp_rate_month_year_fe <- getc(m_a4, "ur"); rm(m_a4); gc()

m_b1 <- safe(feols(hire ~ young + yu + ou, data = dt, weights = ~w, cluster = ~st, lean = TRUE))
res$young_x_unemp_rate_no_controls <- getc(m_b1, "yu")
res$experienced_x_unemp_rate_no_controls <- getc(m_b1, "ou"); rm(m_b1); gc()

m_b4 <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt, weights = ~w, cluster = ~st, lean = TRUE))
res$young_x_unemp_rate_preferred <- getc(m_b4, "yu")
res$experienced_x_unemp_rate_preferred <- getc(m_b4, "ou")
if (!is.null(m_b4)) print(coeftable(m_b4))
n_full <- if (!is.null(m_b4)) nobs(m_b4) else nrow(dt)
rm(m_b4); gc()

m_e <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt[orig == 1], weights = ~w, cluster = ~st, lean = TRUE))
res$young_x_unemp_rate_employed <- getc(m_e, "yu")
res$experienced_x_unemp_rate_employed <- getc(m_e, "ou"); rm(m_e); gc()

m_u <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt[orig == 2], weights = ~w, cluster = ~st, lean = TRUE))
res$young_x_unemp_rate_unemployed <- getc(m_u, "yu"); rm(m_u); gc()

m_n <- safe(feols(hire ~ young + yu + ou | st + ym + demo, data = dt[orig == 3], weights = ~w, cluster = ~st, lean = TRUE))
res$young_x_unemp_rate_nilf <- getc(m_n, "yu"); rm(m_n); gc()

# ---- wage regressions for new hires ----
wage_res <- safe({
  if (!"earn" %in% names(dt)) stop("no weekly earnings column")
  h <- dt[hire == 100 & !is.na(earn) & earn > 0]
  if ("mis" %in% names(h)) {
    hh <- h[mis %in% c(4, 8)]
    if (nrow(hh) > 1000) h <- hh
  }
  if ("alloc" %in% names(h)) {
    av <- unique(h$alloc)
    if (0 %in% av) h <- h[is.na(alloc) | alloc <= 0]
  }
  cpi <- fread(f_cpi)
  setnames(cpi, tolower(names(cpi)))
  cpi <- cpi[, .(cy = as.numeric(year), cm = as.numeric(month), cpi = as.numeric(cpi))]
  cpi <- unique(cpi, by = c("cy", "cm"))
  h <- merge(h, cpi, by = c("cy", "cm"), all.x = TRUE)
  h <- h[!is.na(cpi) & cpi > 0]
  base_cpi <- cpi[cy == 1994 & cm == 1, cpi]
  if (!length(base_cpi)) base_cpi <- 1
  h[, lw := log(earn / cpi * base_cpi)]

  # industry / occupation codes (2002 Census recodes)
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
      h[, icy := indcy]
    } else {
      av <- sort(unique(ix$icy))
      uv <- unique(h$ind_v)
      mp <- setNames(closest(uv, av), uv)
      h[, icy := unname(mp[as.character(ind_v)])]
    }
    h <- merge(h, ix, by = c("icd", "icy"), all.x = TRUE)
    cat("Industry crosswalk match rate:", mean(!is.na(h$irec)), "\n")
    h[!is.na(irec) & irec != "", indfe := paste0("x", irec)]
  }, silent = FALSE)
  try({
    ox <- fread(f_occ); setnames(ox, tolower(names(ox)))
    ox <- ox[, .(ocd = num(v2peio1ocd), ocy = num(v2occ_codeyear), orec = as.character(v2censusocc_2002recode))]
    ox <- unique(ox[!is.na(ocd) & !is.na(ocy)], by = c("ocd", "ocy"))
    if ("occcy" %in% names(h) && mean(h$occcy %in% ox$ocy) > 0.5) {
      h[, ocy := occcy]
    } else {
      av <- sort(unique(ox$ocy))
      uv <- unique(h$occ_v)
      mp <- setNames(closest(uv, av), uv)
      h[, ocy := unname(mp[as.character(occ_v)])]
    }
    h <- merge(h, ox, by = c("ocd", "ocy"), all.x = TRUE)
    cat("Occupation crosswalk match rate:", mean(!is.na(h$orec)), "\n")
    h[!is.na(orec) & orec != "", occfe := paste0("x", orec)]
  }, silent = FALSE)

  cat("Wage sample N:", nrow(h), "\n")
  mw <- feols(lw ~ young + yu + ou | st + ym + demo + occfe + indfe, data = h,
              weights = ~w, cluster = ~st)
  print(coeftable(mw))
  list(y = unname(coef(mw)["yu"]), o = unname(coef(mw)["ou"]))
})
if (!is.null(wage_res)) {
  res$wage_young_x_unemp_rate_all_hires <- wage_res$y
  res$wage_experienced_x_unemp_rate_all_hires <- wage_res$o
}

res$n_obs_full_sample <- n_full

for (nm in names(res)) {
  v <- res[[nm]]
  if (length(v) == 1 && !is.na(v)) cat(sprintf("RESULT:%s=%.6g\n", nm, v))
}
