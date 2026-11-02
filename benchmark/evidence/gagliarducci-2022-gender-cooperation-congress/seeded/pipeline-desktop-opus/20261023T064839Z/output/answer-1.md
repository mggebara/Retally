suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress"
path <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")

d <- read_dta(path)
d <- zap_labels(d)
d <- zap_formats(d)
d <- as.data.table(as.data.frame(d))

# character "" -> NA (Stata missing string)
for (v in names(d)) {
  if (is.character(d[[v]])) {
    x <- d[[v]]
    x[!is.na(x) & trimws(x) == ""] <- NA
    set(d, j = v, value = x)
  }
}

# keep if private==0
d <- d[!is.na(private) & private == 0]

# tot_bills: count of nonmissing v2 by sponsor-Congress (missing keys form their own group, as bysort does)
d[, tot_bills := sum(!is.na(v2)), by = .(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served)]

d[, sponsor_democrat := ifelse(is.na(sponsor_party), NA_real_, as.numeric(sponsor_party == 100))]
d[, NE := ifelse(is.na(sponsor_state_icpsr), NA_real_, as.numeric(sponsor_state_icpsr >= 1 & sponsor_state_icpsr <= 14))]
d[, MW := ifelse(is.na(sponsor_state_icpsr), NA_real_, as.numeric(sponsor_state_icpsr >= 21 & sponsor_state_icpsr <= 37))]
d[, SO := ifelse(is.na(sponsor_state_icpsr), NA_real_, as.numeric(sponsor_state_icpsr >= 40 & sponsor_state_icpsr <= 56))]
d[, WE := ifelse(is.na(sponsor_state_icpsr), NA_real_, as.numeric(sponsor_state_icpsr >= 61 & sponsor_state_icpsr <= 82))]

d[!is.na(sponsor_age) & sponsor_age > 100, sponsor_age := NA]
d[, sponsor_rookie := ifelse(is.na(sponsor_tenure_run), NA_real_, as.numeric(sponsor_tenure_run == 1))]
d[, leader := ifelse(is.na(comc) | is.na(comr), NA_real_, as.numeric((comc == 1) | (comr == 1)))]

d[, lnpden := lnpop - lnarea]
d[, absMV := abs(MV1_democrat)]

# egen tag / group on sponsor-Congress keys (missing keys -> tag 0, group missing)
keyok <- !is.na(d$v2) & !is.na(d$sponsor_state_abbrev) & !is.na(d$sponsor_district) & !is.na(d$sponsor_term_served)
keystr <- paste(d$v2, d$sponsor_state_abbrev, d$sponsor_district, d$sponsor_term_served, sep = "|")
d[, group_sponsor := NA_integer_]
d$group_sponsor[keyok] <- as.integer(factor(keystr[keyok]))
d[, tag_sponsor := as.integer(keyok & !duplicated(ifelse(keyok, keystr, NA_character_), incomparables = NA))]
d$tag_sponsor[!keyok] <- 0L

# outcome
d[, pct_cosponsors_opposite := 100 * numb_cosponsors_opposite / (numb_cosponsors + 1)]
d[!is.na(pct_cosponsors_opposite) & pct_cosponsors_opposite > 100, pct_cosponsors_opposite := NA]

# tag_bill
bok <- !is.na(d$v2) & !is.na(d$HRnumber)
bkey <- paste(d$v2, d$HRnumber, sep = "|")
d[, tag_bill := as.integer(bok & !duplicated(ifelse(bok, bkey, NA_character_), incomparables = NA))]
d$tag_bill[!bok] <- 0L

house_vars <- grep("^house_", names(d), value = TRUE)
indivchars <- c("sponsor_democrat", "sponsor_rookie", "sponsor_tenure_run", "sponsor_age", "leader",
                "ivycoll", "black", "occ0", "occ1", "occ2", "occ3", "occ4", "borninstate", "tot_bills")
districtchars <- c("NE", "MW", "WE", "pct_black", "pct_urban", "pct_for_born", "pct_age_over65", "lninc", "lnpden")
other_x <- c(house_vars, indivchars, districtchars)  # plus i.minor as FE

cond_k <- function(k) {
  if (k == 1) return(d$tag_bill == 1)
  if (k == 2) return(d$tag_bill == 1 & !is.na(d$sponsor_party) & d$sponsor_party == 100)
  return(d$tag_bill == 1 & !is.na(d$sponsor_party) & d$sponsor_party == 200)
}

bt <- function(x) paste0("`", x, "`")

fit_ols <- function(depvar, sub, xvars, fe, wvar = NULL) {
  vars <- unique(c(depvar, "sponsor_female", xvars, fe, "group_sponsor", wvar))
  dd <- sub[complete.cases(sub[, ..vars])]
  rhs <- paste(bt(c("sponsor_female", xvars)), collapse = " + ")
  fml <- as.formula(paste(bt(depvar), "~", rhs, "|", paste(fe, collapse = " + ")))
  if (is.null(wvar)) {
    m <- feols(fml, data = dd, cluster = ~group_sponsor, fixef.rm = "none", notes = FALSE, warn = FALSE)
  } else {
    dd[, .wt := get(wvar)]
    m <- feols(fml, data = dd, cluster = ~group_sponsor, weights = ~.wt, fixef.rm = "none", notes = FALSE, warn = FALSE)
  }
  b <- unname(coef(m)["sponsor_female"])
  se <- unname(sqrt(diag(vcov(m)))["sponsor_female"])
  list(b = b, se = se, n = nobs(m), ncl = uniqueN(dd$group_sponsor))
}

# Stata-like probit: drops regressors where x!=0 predicts outcome perfectly (and those obs),
# collinear regressors get coefficient 0, and predict (default 'rules') is missing for obs excluded by rules.
stata_probit_predict <- function(est, pred, xvars) {
  vars <- c("sponsor_female", "v2", xvars)
  e <- as.data.frame(est[complete.cases(est[, ..vars]), ..vars])
  levs <- sort(unique(e$v2))
  baselev <- levs[1]
  dumnames <- paste0("v2_", levs[-1])
  X <- as.data.frame(lapply(levs[-1], function(l) as.numeric(e$v2 == l)))
  if (length(dumnames) > 0) names(X) <- dumnames
  X <- cbind(X, e[, xvars, drop = FALSE])
  y <- e$sponsor_female
  keep_rows <- rep(TRUE, nrow(e))
  dropped_vars <- character(0)
  repeat {
    changed <- FALSE
    for (v in setdiff(names(X), dropped_vars)) {
      nz <- keep_rows & X[[v]] != 0
      if (sum(nz) > 0) {
        yy <- y[nz]
        if (all(yy == 0) || all(yy == 1)) {
          dropped_vars <- c(dropped_vars, v)
          keep_rows <- keep_rows & !(X[[v]] != 0)
          changed <- TRUE
        }
      }
    }
    if (!changed) break
  }
  usevars <- setdiff(names(X), dropped_vars)
  Xm <- as.matrix(cbind(`(Intercept)` = 1, X[keep_rows, usevars, drop = FALSE]))
  fit <- suppressWarnings(glm.fit(Xm, y[keep_rows], family = binomial(link = "probit"),
                                   control = glm.control(maxit = 200, epsilon = 1e-10)))
  cf <- fit$coefficients
  cf[is.na(cf)] <- 0
  names(cf) <- colnames(Xm)
  # prediction
  P <- as.data.frame(pred)
  xb <- rep(cf["(Intercept)"], nrow(P))
  for (v in usevars) {
    if (startsWith(v, "v2_")) {
      l <- as.numeric(sub("^v2_", "", v))
      xb <- xb + cf[v] * as.numeric(P$v2 == l)
    } else {
      xb <- xb + cf[v] * P[[v]]
    }
  }
  ps <- pnorm(xb)
  ps[is.na(P$v2)] <- NA
  for (v in xvars) ps[is.na(P[[v]])] <- NA
  for (v in dropped_vars) {
    if (startsWith(v, "v2_")) {
      l <- as.numeric(sub("^v2_", "", v))
      ps[!is.na(P$v2) & P$v2 == l] <- NA
    } else {
      ps[!is.na(P[[v]]) & P[[v]] != 0] <- NA
    }
  }
  as.numeric(ps)
}

get_band <- function(y, x) {
  ok <- !is.na(y) & !is.na(x)
  y <- y[ok]; x <- x[ok]
  h <- NA_real_
  f <- tryCatch(get("rdbwselect_2014", envir = asNamespace("rdrobust")), error = function(e) NULL)
  extract_h <- function(r) {
    bw <- r$bws
    if (is.matrix(bw) || is.data.frame(bw)) return(as.numeric(as.matrix(bw)[1, 1]))
    as.numeric(unlist(bw))[1]
  }
  if (!is.null(f)) {
    for (kn in c("uniform", "uni")) {
      if (!is.na(h)) break
      h <- tryCatch(extract_h(f(y = y, x = x, c = 0, kernel = kn, bwselect = "CCT")),
                    error = function(e) NA_real_)
    }
  }
  if (is.na(h)) {
    h <- tryCatch(as.numeric(rdbwselect(y = y, x = x, c = 0, kernel = "uniform", bwselect = "mserd")$bws[1, 1]),
                  error = function(e) NA_real_)
  }
  h
}

# sample from the mixed-gender full-control regression (Stata e(sample))
rd_sample <- function(depvar, k) {
  vars <- unique(c(depvar, "sponsor_female", "MV1_female", "femaleXMV1_female", "v2", "minor", other_x, "group_sponsor"))
  ck <- cond_k(k) & !is.na(d$mixed_gender_election) & d$mixed_gender_election == 1
  ck & complete.cases(d[, ..vars])
}

absle <- function(band) !is.na(d$MV1_female) & abs(d$MV1_female) <= band

est_col <- function(depvar, j, k) {
  ck <- cond_k(k)
  if (j == 1) {
    return(fit_ols(depvar, d[ck], other_x, c("v2", "minor")))
  }
  if (j == 2 || j == 3) {
    smp <- rd_sample(depvar, k)
    band <- get_band(d[[depvar]][ck], d$MV1_female[ck])
    cat(sprintf("# bandwidth %s k=%d j=%d: %.4f\n", depvar, k, j, band))
    inb <- absle(band)
    if (j == 2) {
      r <- fit_ols(depvar, d[ck & smp & inb], c("MV1_female", "femaleXMV1_female"), "v2")
    } else {
      est <- d[ck & d$tag_sponsor == 1 & inb]
      prd_idx <- which(ck & smp & inb)
      ps <- stata_probit_predict(est, d[prd_idx], districtchars)
      sub <- d[prd_idx]
      sub[, wt := ifelse(sponsor_female == 1, 1 / ps, 1 / (1 - ps))]
      sub <- sub[!is.na(wt)]
      r <- fit_ols(depvar, sub, c("MV1_female", "femaleXMV1_female", house_vars), c("v2", "minor"), wvar = "wt")
    }
    r$band <- band
    return(r)
  }
  if (j == 4 || j == 5) {
    pv <- if (j == 4) c(districtchars, "absMV") else c(districtchars, indivchars, "absMV")
    est <- d[ck & d$tag_sponsor == 1]
    prd_idx <- which(ck)
    ps <- stata_probit_predict(est, d[prd_idx], pv)
    sub <- d[prd_idx]
    sub[, wt := ifelse(sponsor_female == 1, 1 / ps, 1 / (1 - ps))]
    sub <- sub[!is.na(wt)]
    return(fit_ols(depvar, sub, house_vars, c("v2", "minor"), wvar = "wt"))
  }
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("# error:", conditionMessage(e), "\n"); NULL })

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && !is.na(val)) results[[name]] <<- val
}

r1 <- safe(est_col("numb_cosponsors", 1, 1))
if (!is.null(r1)) {
  emit("female_sponsor_ncosponsors_all_ols", r1$b)
  emit("n_bills_ncosponsors_all_ols", r1$n)
  emit("n_sponsor_terms_ncosponsors_all_ols", r1$ncl)
}
r2 <- safe(est_col("numb_cosponsors", 1, 3))
if (!is.null(r2)) emit("female_sponsor_ncosponsors_rep_ols", r2$b)
r3 <- safe(est_col("numb_cosponsors", 3, 3))
if (!is.null(r3)) emit("female_sponsor_ncosponsors_rep_rd_ipw", r3$b)
r4 <- safe(est_col("numb_cosponsors", 5, 3))
if (!is.null(r4)) emit("female_sponsor_ncosponsors_rep_ipw_sponsor", r4$b)

r5 <- safe(est_col("pct_cosponsors_opposite", 1, 2))
if (!is.null(r5)) {
  emit("female_sponsor_pct_opposite_dem_ols", r5$b)
  emit("n_bills_pct_opposite_dem_ols", r5$n)
}
r6 <- safe(est_col("pct_cosponsors_opposite", 2, 2))
if (!is.null(r6)) emit("female_sponsor_pct_opposite_dem_rd", r6$b)
r7 <- safe(est_col("pct_cosponsors_opposite", 5, 2))
if (!is.null(r7)) emit("female_sponsor_pct_opposite_dem_ipw_sponsor", r7$b)
r8 <- safe(est_col("pct_cosponsors_opposite", 1, 3))
if (!is.null(r8)) {
  emit("female_sponsor_pct_opposite_rep_ols", r8$b)
  emit("n_bills_pct_opposite_rep_ols", r8$n)
}
r9 <- safe(est_col("pct_cosponsors_opposite", 4, 3))
if (!is.null(r9)) emit("female_sponsor_pct_opposite_rep_ipw_district", r9$b)

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10)))
}
