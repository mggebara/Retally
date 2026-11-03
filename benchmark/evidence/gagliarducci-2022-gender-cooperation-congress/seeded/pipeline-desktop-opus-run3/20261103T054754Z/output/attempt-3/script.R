suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

root <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress"
fpath <- file.path(root, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")

d <- as.data.frame(haven::zap_labels(haven::read_dta(fpath)))

# keep if private==0
d <- d[!is.na(d$private) & d$private == 0, ]

# string missing -> NA
if (is.character(d$sponsor_state_abbrev)) d$sponsor_state_abbrev[d$sponsor_state_abbrev == ""] <- NA
if (is.character(d$HRnumber)) d$HRnumber[d$HRnumber == ""] <- NA

# sponsor identifiers
skey <- paste(d$v2, d$sponsor_state_abbrev, d$sponsor_district, d$sponsor_term_served, sep = "_")
key_ok <- !is.na(d$v2) & !is.na(d$sponsor_state_abbrev) & !is.na(d$sponsor_district) & !is.na(d$sponsor_term_served)

# tot_bills: bysort sponsor: egen count(v2)
d$tot_bills <- ave(as.numeric(!is.na(d$v2)), skey, FUN = sum)

d$sponsor_democrat <- ifelse(is.na(d$sponsor_party), NA, as.numeric(d$sponsor_party == 100))
si <- d$sponsor_state_icpsr
d$NE <- ifelse(is.na(si), NA, as.numeric(si >= 1 & si <= 14))
d$MW <- ifelse(is.na(si), NA, as.numeric(si >= 21 & si <= 37))
d$SO <- ifelse(is.na(si), NA, as.numeric(si >= 40 & si <= 56))
d$WE <- ifelse(is.na(si), NA, as.numeric(si >= 61 & si <= 82))

d$sponsor_age[!is.na(d$sponsor_age) & d$sponsor_age > 100] <- NA
d$sponsor_rookie <- ifelse(is.na(d$sponsor_tenure_run), NA, as.numeric(d$sponsor_tenure_run == 1))
d$leader <- ifelse(is.na(d$comc) | is.na(d$comr), NA, as.numeric(d$comc == 1 | d$comr == 1))

d$lnpden <- d$lnpop - d$lnarea
d$absMV <- abs(d$MV1_democrat)

d$tag_sponsor <- (!duplicated(skey)) & key_ok
d$group_sponsor <- ifelse(key_ok, as.integer(factor(skey)), NA_integer_)

d$pct_cosponsors_opposite <- 100 * d$numb_cosponsors_opposite / (d$numb_cosponsors + 1)
d$pct_cosponsors_opposite[!is.na(d$pct_cosponsors_opposite) & d$pct_cosponsors_opposite > 100] <- NA

bkey <- paste(d$v2, d$HRnumber, sep = "_")
d$tag_bill <- (!duplicated(bkey)) & !is.na(d$v2) & !is.na(d$HRnumber)

house_cols <- grep("^house_", names(d), value = TRUE)
indivchars <- c("sponsor_democrat", "sponsor_rookie", "sponsor_tenure_run", "sponsor_age", "leader",
                "ivycoll", "black", "occ0", "occ1", "occ2", "occ3", "occ4", "borninstate", "tot_bills")
districtchars <- c("NE", "MW", "WE", "pct_black", "pct_urban", "pct_for_born", "pct_age_over65", "lninc", "lnpden")

# ---------------- helpers ----------------
run_reg <- function(sub, y, rhs, fe, wvar = NULL) {
  sub <- sub[!is.na(sub$group_sponsor) & !is.na(sub[[y]]), , drop = FALSE]
  if (!is.null(wvar)) sub <- sub[!is.na(sub[[wvar]]) & is.finite(sub[[wvar]]), , drop = FALSE]
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "|", paste(fe, collapse = " + ")))
  if (is.null(wvar)) {
    m <- feols(fml, data = sub, cluster = ~group_sponsor, fixef.rm = "none", warn = FALSE, notes = FALSE)
  } else {
    sub$.w <- sub[[wvar]]
    m <- feols(fml, data = sub, weights = ~.w, cluster = ~group_sponsor, fixef.rm = "none", warn = FALSE, notes = FALSE)
  }
  used <- tryCatch(fixest::obs(m), error = function(e) seq_len(nobs(m)))
  list(b = unname(coef(m)["sponsor_female"]),
       se = unname(sqrt(diag(vcov(m)))["sponsor_female"]),
       n = nobs(m),
       nclust = length(unique(sub$group_sponsor[used])))
}

# Probit emulating Stata: i.v2 with lowest level as base; non-base levels that
# perfectly predict the outcome are omitted (obs dropped, coefficient = 0).
probit_pscore <- function(fitdat, preddat, xvars) {
  vars <- c("sponsor_female", "v2", xvars)
  f <- fitdat[complete.cases(fitdat[, vars, drop = FALSE]), , drop = FALSE]
  lev <- sort(unique(f$v2))
  base <- lev[1]
  nb <- lev[-1]
  bad <- nb[sapply(nb, function(l) length(unique(f$sponsor_female[f$v2 == l])) < 2)]
  if (length(bad) > 0) f <- f[!(f$v2 %in% bad), , drop = FALSE]
  keep_lev <- setdiff(nb, bad)
  mk <- function(dd) {
    X <- matrix(1, nrow(dd), 1, dimnames = list(NULL, "(Intercept)"))
    for (l in keep_lev) {
      X <- cbind(X, as.numeric(dd$v2 == l))
      colnames(X)[ncol(X)] <- paste0("v2_", l)
    }
    for (v in xvars) {
      X <- cbind(X, as.numeric(dd[[v]]))
      colnames(X)[ncol(X)] <- v
    }
    X
  }
  Xf <- mk(f)
  g <- suppressWarnings(glm.fit(Xf, f$sponsor_female, family = binomial(link = "probit")))
  beta <- g$coefficients
  beta[is.na(beta)] <- 0
  Xp <- mk(preddat)
  as.vector(pnorm(Xp %*% beta))
}

get_bw <- function(y, x) {
  h <- NA_real_
  if (exists("rdbwselect_2014", envir = asNamespace("rdrobust"), inherits = FALSE)) {
    r <- tryCatch(rdrobust::rdbwselect_2014(y = y, x = x, c = 0, kernel = "uniform", bwselect = "CCT"),
                  error = function(e) NULL)
    if (!is.null(r)) h <- tryCatch(as.numeric(r$bws[1, 1]), error = function(e) NA_real_)
  }
  if (is.na(h)) {
    r <- tryCatch(rdrobust::rdbwselect(y = y, x = x, c = 0, kernel = "uniform", p = 1, bwselect = "mserd"),
                  error = function(e) NULL)
    if (!is.null(r)) h <- tryCatch(as.numeric(r$bws[1, 1]), error = function(e) NA_real_)
  }
  h
}

# ---------------- Table 5 ----------------
ksets <- list(
  all = d$tag_bill,
  dem = d$tag_bill & (d$sponsor_party %in% 100),
  rep = d$tag_bill & (d$sponsor_party %in% 200)
)
depvars <- c(numb = "numb_cosponsors", pct = "pct_cosponsors_opposite")

res <- list()
bws <- list()
for (dn in names(depvars)) {
  y <- depvars[[dn]]
  for (kn in names(ksets)) {
    dk <- d[ksets[[kn]], , drop = FALSE]

    # e(sample) of the mixed-gender regression with controls2 + other_controls
    svars <- c(y, "sponsor_female", "v2", "MV1_female", "femaleXMV1_female", "minor", house_cols,
               indivchars, districtchars, "group_sponsor")
    dk$sample <- (dk$mixed_gender_election %in% 1) & complete.cases(dk[, svars, drop = FALSE])

    # bandwidth selected on the RD estimation sample (mixed-gender races, complete cases)
    okbw <- dk$sample & !is.na(dk[[y]]) & !is.na(dk$MV1_female)
    h <- get_bw(dk[[y]][okbw], dk$MV1_female[okbw])
    bws[[paste(dn, kn, sep = "_")]] <- h
    inbw <- !is.na(dk$MV1_female) & abs(dk$MV1_female) <= h

    # bandwidth for the plain RD: selected on all bills of the party subsample
    okbw2 <- !is.na(dk[[y]]) & !is.na(dk$MV1_female)
    h2 <- get_bw(dk[[y]][okbw2], dk$MV1_female[okbw2])
    bws[[paste(dn, kn, "rd", sep = "_")]] <- h2
    inbw2 <- !is.na(dk$MV1_female) & abs(dk$MV1_female) <= h2

    # j=1 OLS full controls
    res[[paste(dn, kn, 1, sep = "_")]] <- tryCatch(
      run_reg(dk, y, c("sponsor_female", house_cols, indivchars, districtchars), c("v2", "minor")),
      error = function(e) NULL)

    # j=2 RD
    res[[paste(dn, kn, 2, sep = "_")]] <- tryCatch(
      run_reg(dk[dk$sample & inbw2, , drop = FALSE], y,
              c("sponsor_female", "MV1_female", "femaleXMV1_female"), c("v2")),
      error = function(e) NULL)

    # j=3 RD + IPW (pscore = f(district), sponsors within bandwidth)
    res[[paste(dn, kn, 3, sep = "_")]] <- tryCatch({
      fitd <- dk[dk$tag_sponsor & inbw, , drop = FALSE]
      dk$wt <- NA_real_
      ps <- probit_pscore(fitd, dk[dk$sample, , drop = FALSE], districtchars)
      wt <- ifelse(dk$sponsor_female[dk$sample] == 1, 1 / ps, 1 / (1 - ps))
      dk$wt[dk$sample] <- wt
      run_reg(dk[dk$sample & inbw, , drop = FALSE], y,
              c("sponsor_female", "MV1_female", "femaleXMV1_female", house_cols), c("v2", "minor"), "wt")
    }, error = function(e) NULL)

    # j=4 IPW full sample (district + absMV)
    res[[paste(dn, kn, 4, sep = "_")]] <- tryCatch({
      fitd <- dk[dk$tag_sponsor, , drop = FALSE]
      ps <- probit_pscore(fitd, dk, c(districtchars, "absMV"))
      dk$wt <- ifelse(dk$sponsor_female == 1, 1 / ps, 1 / (1 - ps))
      run_reg(dk, y, c("sponsor_female", house_cols), c("v2", "minor"), "wt")
    }, error = function(e) NULL)

    # j=5 IPW full sample (district + indiv + absMV)
    res[[paste(dn, kn, 5, sep = "_")]] <- tryCatch({
      sk_k <- paste(dk$v2, dk$sponsor_state_abbrev, dk$sponsor_district, dk$sponsor_term_served, sep = "_")
      tag_k <- (!duplicated(sk_k)) & !is.na(dk$group_sponsor)
      fitd <- dk[tag_k, , drop = FALSE]
      ps <- probit_pscore(fitd, dk, c(districtchars, indivchars, "absMV"))
      dk$wt <- ifelse(dk$sponsor_female == 1, 1 / ps, 1 / (1 - ps))
      run_reg(dk, y, c("sponsor_female", house_cols), c("v2", "minor"), "wt")
    }, error = function(e) NULL)
  }
}

getv <- function(key, what) {
  r <- res[[key]]
  if (is.null(r)) return(NA_real_)
  r[[what]]
}
emit <- function(name, val) cat(sprintf("RESULT:%s=%s\n", name, format(val, digits = 10)))

emit("female_sponsor_ncosponsors_all_ols", getv("numb_all_1", "b"))
emit("female_sponsor_ncosponsors_rep_ols", getv("numb_rep_1", "b"))
emit("female_sponsor_ncosponsors_rep_rd_ipw", getv("numb_rep_3", "b"))
emit("female_sponsor_ncosponsors_rep_ipw_sponsor", getv("numb_rep_5", "b"))
emit("female_sponsor_pct_opposite_dem_ols", getv("pct_dem_1", "b"))
emit("female_sponsor_pct_opposite_dem_rd", getv("pct_dem_2", "b"))
emit("female_sponsor_pct_opposite_dem_ipw_sponsor", getv("pct_dem_5", "b"))
emit("female_sponsor_pct_opposite_rep_ols", getv("pct_rep_1", "b"))
emit("female_sponsor_pct_opposite_rep_ipw_district", getv("pct_rep_4", "b"))
emit("n_bills_ncosponsors_all_ols", getv("numb_all_1", "n"))
emit("n_sponsor_terms_ncosponsors_all_ols", getv("numb_all_1", "nclust"))
emit("n_bills_pct_opposite_dem_ols", getv("pct_dem_1", "n"))
emit("n_bills_pct_opposite_rep_ols", getv("pct_rep_1", "n"))

# standard errors and bandwidths (diagnostics)
emit("female_sponsor_ncosponsors_all_ols_se", getv("numb_all_1", "se"))
emit("female_sponsor_ncosponsors_rep_ols_se", getv("numb_rep_1", "se"))
emit("female_sponsor_ncosponsors_rep_rd_ipw_se", getv("numb_rep_3", "se"))
emit("female_sponsor_ncosponsors_rep_ipw_sponsor_se", getv("numb_rep_5", "se"))
emit("female_sponsor_pct_opposite_dem_ols_se", getv("pct_dem_1", "se"))
emit("female_sponsor_pct_opposite_dem_rd_se", getv("pct_dem_2", "se"))
emit("female_sponsor_pct_opposite_dem_ipw_sponsor_se", getv("pct_dem_5", "se"))
emit("female_sponsor_pct_opposite_rep_ols_se", getv("pct_rep_1", "se"))
emit("female_sponsor_pct_opposite_rep_ipw_district_se", getv("pct_rep_4", "se"))
emit("bandwidth_ncosponsors_rep", bws[["numb_rep"]])
emit("bandwidth_pct_opposite_dem", bws[["pct_dem"]])
emit("bandwidth_rd_pct_opposite_dem", bws[["pct_dem_rd"]])
cat('DEVIATION: plain RD (col 2) uses a CCT/MSE bandwidth selected on all bills of the party subsample; RD+IPW keeps the bandwidth selected on the mixed-gender complete-case sample. Sponsor-level pscore sample for IPW (indiv) re-tagged within the party subsample; the paper does not state either choice\n')
cat('DEVIATION: RD bandwidth (CCT/MSE) selected on the mixed-gender complete-case RD sample rather than on all bills of the party subsample; the paper does not state the bandwidth selection sample\n')