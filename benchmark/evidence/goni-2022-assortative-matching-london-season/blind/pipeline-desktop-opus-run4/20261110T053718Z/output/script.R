suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
})
set.seed(42)

root <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season.script-free"
fpath <- file.path(root, "data/final-data.dta")

all_names <- names(haven::read_dta(fpath, n_max = 0))
cat("Number of columns:", length(all_names), "\n")
cat("Sample-like vars:", paste(grep("sample|never|spinst|celib|female|sex|gender|death|dyear|ddate|dage|byear|bdate|age18|pr4|hengpee|prank|peerage|royal|foreign", all_names, value = TRUE, ignore.case = TRUE), collapse = ", "), "\n")
cat("Landholding-like vars:", paste(grep("match|down|acre|atot|land|pct|perc|rank", all_names, value = TRUE, ignore.case = TRUE), collapse = ", "), "\n")

pick <- function(cands) {
  for (c in cands) if (c %in% all_names) return(c)
  low <- tolower(all_names)
  for (c in cands) { i <- which(low == tolower(c)); if (length(i)) return(all_names[i[1]]) }
  NA_character_
}

v_T      <- pick(c("syntheticT"))
v_comm   <- pick(c("cOut"))
v_heir   <- pick(c("mheir"))
v_down   <- pick(c("fdown"))
v_abs    <- pick(c("fmissmatch"))
v_sgn    <- pick(c("fmissmatch2"))
v_dist   <- pick(c("distlondon"))
v_bio    <- pick(c("biorder"))
v_base   <- pick(c("base_sample"))
v_byear  <- pick(c("byear", "birthyear", "yearbirth"))
v_bdate  <- pick(c("bdate"))
v_pr4    <- pick(c("pr4"))
v_prank  <- pick(c("prank"))
v_eng    <- pick(c("hengpee", "engpeerage", "english"))
v_peer   <- pick(c("peerage"))
v_nmarr  <- pick(c("nmarriages"))
v_nthis  <- pick(c("nthismarriage"))
v_myear  <- pick(c("myear"))
v_age61  <- pick(c("age1861"))
v_female <- pick(c("female", "sex", "gender"))
v_dyear  <- pick(c("dyear", "deathyear", "yeardeath", "ddate", "ddeath"))
v_dage   <- pick(c("dage", "agedeath", "deathage", "age_death"))
v_never  <- pick(c("nevermarried", "never_married", "nevermarr", "nmarried", "spinster", "celibacy", "single"))
v_nmsamp <- pick(c("nevermarried_sample", "never_sample", "sample_never", "celibacy_sample", "nm_sample"))

need <- unique(na.omit(c(v_T, v_comm, v_heir, v_down, v_abs, v_sgn, v_dist, v_bio, v_base,
                         v_byear, v_bdate, v_pr4, v_prank, v_eng, v_peer, v_nmarr, v_nthis,
                         v_myear, v_age61, v_female, v_dyear, v_dage, v_never, v_nmsamp,
                         pick(c("marital_rates_sample")))))
cat("Loading columns:", paste(need, collapse = ", "), "\n")
d <- haven::read_dta(fpath, col_select = all_of(need))
cat("Rows loaded:", nrow(d), "\n")

num <- function(x) {
  if (is.null(x)) return(NULL)
  as.numeric(haven::zap_labels(x))
}

dd <- data.frame(row = seq_len(nrow(d)))
dd$T <- num(d[[v_T]])
if (max(dd$T, na.rm = TRUE) <= 1.5) { cat("Rescaling T to percent\n"); dd$T <- 100 * dd$T }

# birth year
if (!is.na(v_byear)) {
  dd$byear <- num(d[[v_byear]])
} else if (!is.na(v_bdate)) {
  b <- num(d[[v_bdate]])
  dd$byear <- if (median(b, na.rm = TRUE) > 3000 || median(b, na.rm = TRUE) < 0) floor(1960 + b / 365.25) else b
} else stop("No birth year variable")

dd$age1861 <- if (!is.na(v_age61)) num(d[[v_age61]]) else 1861 - dd$byear

# controls
if (!is.na(v_pr4)) {
  dd$pr4 <- num(d[[v_pr4]])
} else if (!is.na(v_prank)) {
  pr <- num(d[[v_prank]]); dd$pr4 <- as.numeric(pr == max(pr, na.rm = TRUE))
} else dd$pr4 <- 0
if (!is.na(v_eng)) {
  dd$eng <- num(d[[v_eng]])
} else if (!is.na(v_peer)) {
  p <- d[[v_peer]]
  pf <- tolower(as.character(haven::as_factor(p)))
  dd$eng <- as.numeric(grepl("eng", pf))
} else dd$eng <- 0
dd$biorder <- if (!is.na(v_bio)) num(d[[v_bio]]) else 0
dd$dist <- if (!is.na(v_dist)) num(d[[v_dist]]) else NA

# outcomes
dd$comm <- num(d[[v_comm]])
dd$heir <- num(d[[v_heir]])
dd$down <- num(d[[v_down]])
dd$labs <- if (!is.na(v_abs)) num(d[[v_abs]]) else NA
dd$lsgn <- if (!is.na(v_sgn)) num(d[[v_sgn]]) else NA

# Identify absolute vs signed landholding difference
if (all(!is.na(c(v_abs, v_sgn)))) {
  a1 <- dd$labs; a2 <- dd$lsgn
  if (any(a1 < 0, na.rm = TRUE) && all(a2 >= 0, na.rm = TRUE)) { dd$labs <- a2; dd$lsgn <- a1 }
  if (all(!is.na(dd$lsgn)) || TRUE) {
    if (any(dd$labs < 0, na.rm = TRUE)) dd$labs <- abs(dd$labs)
  }
}
# signed orientation: husband - wife, marrying down => negative
ok <- !is.na(dd$down) & !is.na(dd$lsgn)
if (sum(ok) > 10) {
  m_down <- mean(dd$lsgn[ok & dd$down == 1])
  cat("Mean signed diff among married-down:", m_down, "\n")
  if (is.finite(m_down) && m_down > 0) { cat("Flipping sign of signed difference\n"); dd$lsgn <- -dd$lsgn }
}
if (max(abs(c(dd$labs, dd$lsgn)), na.rm = TRUE) <= 1.0001) {
  cat("Rescaling landholding percentiles to 0-100\n")
  dd$labs <- 100 * dd$labs; dd$lsgn <- 100 * dd$lsgn
}

# samples
dd$base <- num(d[[v_base]])
dd$base[is.na(dd$base)] <- 0
base <- dd[dd$base == 1 & !is.na(dd$T) & !is.na(dd$comm), ]
cat("Base sample rows:", nrow(base), "\n")

# never married sample
female_ok <- rep(TRUE, nrow(dd))
if (!is.na(v_female)) {
  fv <- d[[v_female]]
  if (tolower(v_female) == "female") {
    female_ok <- num(fv) == 1
  } else {
    lab <- tolower(as.character(haven::as_factor(fv)))
    if (any(grepl("^f|female|woman|daughter", lab), na.rm = TRUE)) female_ok <- grepl("^f|female|woman|daughter", lab)
    else female_ok <- num(fv) == 2
  }
  female_ok[is.na(female_ok)] <- FALSE
}
cat("Female rows:", sum(female_ok), "\n")

if (!is.na(v_never)) {
  dd$never <- num(d[[v_never]])
} else if (!is.na(v_nmarr)) {
  nm <- num(d[[v_nmarr]]); dd$never <- as.numeric(!is.na(nm) & nm == 0)
} else {
  dd$never <- as.numeric(is.na(num(d[[v_myear]])))
}
# death age
dd$dage <- NA_real_
if (!is.na(v_dage)) dd$dage <- num(d[[v_dage]])
if (all(is.na(dd$dage)) && !is.na(v_dyear)) {
  dy <- num(d[[v_dyear]])
  if (median(dy, na.rm = TRUE) > 3000 || median(dy, na.rm = TRUE) < 0) dy <- floor(1960 + dy / 365.25)
  dd$dage <- dy - dd$byear
}
alive35 <- is.na(dd$dage) | dd$dage >= 35

if (!is.na(v_nmsamp)) {
  nmsel <- num(d[[v_nmsamp]]) == 1
  nmsel[is.na(nmsel)] <- FALSE
} else {
  first_or_none <- rep(TRUE, nrow(dd))
  if (!is.na(v_nthis)) {
    nt <- num(d[[v_nthis]])
    first_or_none <- is.na(nt) | nt <= 1
  }
  # married women: those in the baseline sample; never-married: same age window, women, peers' daughters
  peer_dau <- !is.na(dd$pr4) & !is.na(dd$eng) & !is.na(dd$biorder)
  nmsel <- (dd$base == 1 | (dd$never == 1 & female_ok & first_or_none & peer_dau)) &
    dd$age1861 >= 15 & dd$age1861 <= 35 & alive35 & !is.na(dd$T)
  nmsel[is.na(nmsel)] <- FALSE
}
nmdat <- dd[nmsel, ]
nmdat$never[nmdat$base == 1] <- 0
cat("Never-married sample rows:", nrow(nmdat), " never married:", sum(nmdat$never == 1), "\n")

# estimation helpers
probit_me <- function(y, dat, ctrls) {
  f <- as.formula(paste(y, "~ T +", paste(ctrls, collapse = " + ")))
  dat <- dat[complete.cases(dat[, c(y, "T", ctrls, "byear")]), ]
  m <- glm(f, data = dat, family = binomial(link = "probit"))
  xb <- predict(m, type = "link")
  me <- mean(dnorm(xb)) * coef(m)["T"]
  V <- tryCatch(sandwich::vcovCL(m, cluster = dat$byear), error = function(e) vcov(m))
  cat(sprintf("Probit %s: N=%d, coef=%.5f, SE(cl)=%.5f, AME=%.5f\n", y, nrow(dat), coef(m)["T"], sqrt(V["T", "T"]), me))
  list(me = unname(me), n = nrow(dat))
}
ols_b <- function(y, dat, ctrls) {
  f <- as.formula(paste(y, "~ T +", paste(ctrls, collapse = " + ")))
  dat <- dat[complete.cases(dat[, c(y, "T", ctrls, "byear")]), ]
  m <- lm(f, data = dat)
  V <- sandwich::vcovCL(m, cluster = dat$byear)
  cat(sprintf("OLS %s: N=%d, coef=%.5f, SE(cl)=%.5f\n", y, nrow(dat), coef(m)["T"], sqrt(V["T", "T"])))
  list(b = unname(coef(m)["T"]), n = nrow(dat))
}
safe <- function(expr) tryCatch(expr, error = function(e) { cat("Error:", conditionMessage(e), "\n"); list(me = NA, b = NA, n = NA) })

ctrlA <- c("pr4", "eng", "biorder")
ctrlB <- c(ctrlA, "dist")

land <- base[!is.na(base$labs) & !is.na(base$lsgn) & !is.na(base$down), ]
cat("Landholdings sample rows:", nrow(land), "\n")

r1 <- safe(probit_me("comm", base, ctrlA))
r2 <- safe(probit_me("heir", base, ctrlA))
r3 <- safe(ols_b("labs", land, ctrlA))
r4 <- safe(ols_b("lsgn", land, ctrlA))
r5 <- safe(probit_me("down", land, ctrlA))
r6 <- safe(probit_me("never", nmdat, ctrlA))

b1 <- safe(probit_me("comm", base, ctrlB))
b2 <- safe(probit_me("heir", base, ctrlB))
b3 <- safe(ols_b("labs", land, ctrlB))
b4 <- safe(ols_b("lsgn", land, ctrlB))

fmt <- function(x) if (is.null(x) || is.na(x)) "NA" else format(x, digits = 8)
cat(paste0("RESULT:treatment_married_commoner_table2_panelA_col1=", fmt(r1$me), "\n"))
cat(paste0("RESULT:treatment_married_heir_table2_panelA_col2=", fmt(r2$me), "\n"))
cat(paste0("RESULT:treatment_landholdings_diff_abs_table2_panelA_col3=", fmt(r3$b), "\n"))
cat(paste0("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4=", fmt(r4$b), "\n"))
cat(paste0("RESULT:treatment_married_down_table2_panelA_col5=", fmt(r5$me), "\n"))
cat(paste0("RESULT:treatment_never_married_table2_panelA_col6=", fmt(r6$me), "\n"))
cat(paste0("RESULT:treatment_married_commoner_table2_panelB_col1=", fmt(b1$me), "\n"))
cat(paste0("RESULT:treatment_married_heir_table2_panelB_col2=", fmt(b2$me), "\n"))
cat(paste0("RESULT:treatment_landholdings_diff_abs_table2_panelB_col3=", fmt(b3$b), "\n"))
cat(paste0("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4=", fmt(b4$b), "\n"))
cat(paste0("RESULT:n_obs_table2_panelA_baseline=", fmt(r1$n), "\n"))
cat(paste0("RESULT:n_obs_table2_panelA_landholdings=", fmt(r3$n), "\n"))
cat(paste0("RESULT:n_obs_table2_panelA_never_married=", fmt(r6$n), "\n"))