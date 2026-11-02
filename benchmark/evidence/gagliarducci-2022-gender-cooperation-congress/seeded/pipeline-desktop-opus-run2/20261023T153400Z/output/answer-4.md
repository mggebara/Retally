suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress"
path <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")
d <- as.data.frame(zap_labels(read_dta(path)))

blank <- function(x) {
  if (is.character(x)) is.na(x) | x == "" else is.na(x)
}

# keep if private==0
d <- d[!is.na(d$private) & d$private == 0, , drop = FALSE]
n <- nrow(d)

# tot_bills: count of non-missing v2 within (v2 state district term) groups (missing values form groups)
key_all <- paste(d$v2, d$sponsor_state_abbrev, d$sponsor_district, d$sponsor_term_served, sep = "|")
d$tot_bills <- ave(as.numeric(!is.na(d$v2)), key_all, FUN = sum)

num <- function(x) as.numeric(x)
d$sponsor_party <- num(d$sponsor_party)
d$sponsor_female <- num(d$sponsor_female)
d$sponsor_democrat <- ifelse(is.na(d$sponsor_party), NA, as.numeric(d$sponsor_party == 100))
icp <- num(d$sponsor_state_icpsr)
d$NE <- ifelse(is.na(icp), NA, as.numeric(icp >= 1 & icp <= 14))
d$MW <- ifelse(is.na(icp), NA, as.numeric(icp >= 21 & icp <= 37))
d$SO <- ifelse(is.na(icp), NA, as.numeric(icp >= 40 & icp <= 56))
d$WE <- ifelse(is.na(icp), NA, as.numeric(icp >= 61 & icp <= 82))
d$sponsor_age <- num(d$sponsor_age)
d$sponsor_age[!is.na(d$sponsor_age) & d$sponsor_age > 100] <- NA
d$sponsor_rookie <- ifelse(is.na(d$sponsor_tenure_run), NA, as.numeric(d$sponsor_tenure_run == 1))
d$leader <- ifelse(is.na(d$comc) | is.na(d$comr), NA,
                   as.numeric((d$comc == 1) | (d$comr == 1)))
d$lnpden <- d$lnpop - d$lnarea
d$absMV <- abs(d$MV1_democrat)

# sponsor-Congress group (missing if any key component missing)
ok_s <- !is.na(d$v2) & !blank(d$sponsor_state_abbrev) & !is.na(d$sponsor_district) & !is.na(d$sponsor_term_served)
d$group_sponsor <- ifelse(ok_s, key_all, NA)
d$tag_sponsor <- FALSE
idx <- which(ok_s)
d$tag_sponsor[idx] <- !duplicated(key_all[idx])

# percent cosponsors of opposite party
d$pct_cosponsors_opposite <- 100 * d$numb_cosponsors_opposite / (d$numb_cosponsors + 1)
d$pct_cosponsors_opposite[!is.na(d$pct_cosponsors_opposite) & d$pct_cosponsors_opposite > 100] <- NA

# tag_bill
ok_b <- !is.na(d$v2) & !blank(d$HRnumber)
keyb <- paste(d$v2, d$HRnumber, sep = "|")
d$tag_bill <- FALSE
idx <- which(ok_b)
d$tag_bill[idx] <- !duplicated(keyb[idx])

house_vars <- grep("^house_", names(d), value = TRUE)
for (v in house_vars) d[[v]] <- num(d[[v]])
indiv <- c("sponsor_democrat", "sponsor_rookie", "sponsor_tenure_run", "sponsor_age", "leader",
           "ivycoll", "black", "occ0", "occ1", "occ2", "occ3", "occ4", "borninstate", "tot_bills")
distr <- c("NE", "MW", "WE", "pct_black", "pct_urban", "pct_for_born", "pct_age_over65", "lninc", "lnpden")

# ---------- helpers ----------
fit_ols <- function(df, y, rhs, fe, weighted = FALSE) {
  fml <- as.formula(paste(y, "~", paste(c("sponsor_female", rhs), collapse = " + "), "|", fe))
  if (weighted) {
    m <- feols(fml, data = df, weights = ~wt, cluster = ~group_sponsor,
               fixef.rm = "none", warn = FALSE, notes = FALSE)
  } else {
    m <- feols(fml, data = df, cluster = ~group_sponsor,
               fixef.rm = "none", warn = FALSE, notes = FALSE)
  }
  used <- obs(m)
  list(b = unname(coef(m)["sponsor_female"]),
       se = unname(sqrt(diag(vcov(m)))["sponsor_female"]),
       n = nobs(m),
       nc = length(unique(df$group_sponsor[used])))
}

# probit mimicking Stata: iteratively drop v2 levels and covariates whose nonzero values
# perfectly predict the outcome (dropping those observations and the variable),
# omit collinear covariates, then predict on newdata with the reduced model
pscore_probit <- function(train, newdata, covs) {
  vars <- c("sponsor_female", "v2", covs)
  train <- train[complete.cases(train[, vars, drop = FALSE]), , drop = FALSE]
  dropped_lv <- c()
  dropped_cv <- c()
  repeat {
    changed <- FALSE
    lv <- sort(unique(train$v2))
    perfect <- lv[sapply(lv, function(l) {
      yy <- train$sponsor_female[train$v2 == l]
      all(yy == 0) || all(yy == 1)
    })]
    if (length(perfect) > 0 && length(perfect) < length(lv)) {
      train <- train[!(train$v2 %in% perfect), , drop = FALSE]
      dropped_lv <- c(dropped_lv, perfect)
      changed <- TRUE
    }
    for (cv in covs) {
      x <- as.numeric(train[[cv]])
      nz <- x != 0
      if (any(nz) && any(!nz)) {
        yy <- train$sponsor_female[nz]
        if (all(yy == 0) || all(yy == 1)) {
          train <- train[!nz, , drop = FALSE]
          covs <- setdiff(covs, cv)
          dropped_cv <- c(dropped_cv, cv)
          changed <- TRUE
          break
        }
      }
    }
    if (!changed) break
  }
  keep_lv <- sort(unique(train$v2))
  dum_lv <- if (length(keep_lv) > 1) keep_lv[-1] else numeric(0)
  mk <- function(D) {
    X <- matrix(1, nrow(D), 1)
    colnames(X) <- "cons"
    for (l in dum_lv) {
      X <- cbind(X, as.numeric(D$v2 == l))
      colnames(X)[ncol(X)] <- paste0("v2_", l)
    }
    for (cv in covs) {
      X <- cbind(X, as.numeric(D[[cv]]))
      colnames(X)[ncol(X)] <- cv
    }
    X
  }
  Xt <- mk(train)
  fit <- suppressWarnings(glm(train$sponsor_female ~ Xt - 1, family = binomial(link = "probit")))
  b <- coef(fit)
  b[is.na(b)] <- 0
  Xn <- mk(newdata)
  xb <- as.vector(Xn %*% b)
  p <- pnorm(xb)
  # Stata's predict after probit (default, no 'rules'/'asif') returns missing for
  # observations excluded by the perfect-prediction rules
  excl <- rep(FALSE, nrow(newdata))
  if (length(dropped_lv) > 0) excl <- excl | (!is.na(newdata$v2) & newdata$v2 %in% dropped_lv)
  for (cv in dropped_cv) {
    x <- as.numeric(newdata[[cv]])
    excl <- excl | (!is.na(x) & x != 0)
  }
  p[excl] <- NA
  p
}

make_wt <- function(p, f) {
  w <- ifelse(f == 1, 1 / p, 1 / (1 - p))
  w[!is.finite(w)] <- NA
  w
}

get_band <- function(df, y) {
  s <- df[!is.na(df[[y]]) & !is.na(df$MV1_female), , drop = FALSE]
  h <- tryCatch({
    f <- get("rdbwselect_2014", envir = asNamespace("rdrobust"))
    out <- f(y = s[[y]], x = s$MV1_female, c = 0, kernel = "uniform")
    bw <- out$bws
    if (is.matrix(bw)) bw[1, 1] else as.numeric(bw)[1]
  }, error = function(e) {
    message("rdbwselect_2014 failed: ", conditionMessage(e))
    NA
  })
  if (is.na(h)) {
    h <- tryCatch({
      out <- rdbwselect(y = s[[y]], x = s$MV1_female, c = 0, kernel = "uniform", bwselect = "mserd")
      out$bws[1, 1]
    }, error = function(e) { message("rdbwselect failed: ", conditionMessage(e)); NA })
  }
  h
}

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && !is.na(val)) results[[name]] <<- val
}

dv_names <- c(numb_cosponsors = "ncosponsors", pct_cosponsors_opposite = "pct_opposite")
party_names <- c("all", "dem", "rep")
j_names <- c("ols", "rd", "rd_ipw", "ipw_district", "ipw_sponsor")

for (y in names(dv_names)) {
  for (k in 1:3) {
    if (k == 1) {
      subk <- d[d$tag_bill, , drop = FALSE]
    } else if (k == 2) {
      subk <- d[d$tag_bill & !is.na(d$sponsor_party) & d$sponsor_party == 100, , drop = FALSE]
    } else {
      subk <- d[d$tag_bill & !is.na(d$sponsor_party) & d$sponsor_party == 200, , drop = FALSE]
    }
    band <- get_band(subk, y)
    sub <- subk[!is.na(subk$group_sponsor), , drop = FALSE]

    # e(sample) of the RD-sample regression
    svars <- c(y, "sponsor_female", "v2", "MV1_female", "femaleXMV1_female", "minor",
               house_vars, indiv, distr, "group_sponsor")
    sub$sample <- !is.na(sub$mixed_gender_election) & sub$mixed_gender_election == 1 &
      complete.cases(sub[, svars, drop = FALSE])
    inband <- !is.na(sub$MV1_female) & !is.na(band) & abs(sub$MV1_female) <= band

    tag <- paste0(dv_names[[y]], "_", party_names[k])
    emit(paste0("rd_bandwidth_", tag), band)

    for (j in 1:5) {
      r <- tryCatch({
        if (j == 1) {
          fit_ols(sub, y, c(indiv, distr, house_vars), "v2 + minor")
        } else if (j == 2) {
          fit_ols(sub[sub$sample & inband, , drop = FALSE], y,
                  c("MV1_female", "femaleXMV1_female"), "v2")
        } else if (j == 3) {
          rdsel <- sub$sample & inband
          rdidx <- which(rdsel)
          rdidx <- rdidx[!duplicated(sub$group_sponsor[rdidx])]
          train <- sub[rdidx, , drop = FALSE]
          p <- rep(NA_real_, nrow(sub))
          ps <- pscore_probit(train, sub, distr)
          p[sub$sample] <- ps[sub$sample]
          sub$wt <- make_wt(p, sub$sponsor_female)
          dd <- sub[sub$sample & inband & !is.na(sub$wt), , drop = FALSE]
          fit_ols(dd, y, c("MV1_female", "femaleXMV1_female", house_vars), "v2 + minor", weighted = TRUE)
        } else if (j == 4) {
          train <- sub[sub$tag_sponsor, , drop = FALSE]
          p <- pscore_probit(train, sub, c(distr, "absMV"))
          sub$wt <- make_wt(p, sub$sponsor_female)
          dd <- sub[!is.na(sub$wt), , drop = FALSE]
          fit_ols(dd, y, house_vars, "v2 + minor", weighted = TRUE)
        } else {
          train <- sub[sub$tag_sponsor, , drop = FALSE]
          p <- pscore_probit(train, sub, c(distr, indiv, "absMV"))
          sub$wt <- make_wt(p, sub$sponsor_female)
          dd <- sub[!is.na(sub$wt), , drop = FALSE]
          fit_ols(dd, y, house_vars, "v2 + minor", weighted = TRUE)
        }
      }, error = function(e) {
        message(sprintf("Error %s k=%d j=%d: %s", y, k, j, conditionMessage(e)))
        NULL
      })
      if (!is.null(r)) {
        nm <- paste0(tag, "_", j_names[j])
        emit(paste0("female_sponsor_", nm), r$b)
        emit(paste0("female_sponsor_", nm, "_se"), r$se)
        emit(paste0("n_bills_", nm), r$n)
        emit(paste0("n_sponsor_terms_", nm), r$nc)
      }
    }
  }
}

cat("DEVIATION: Propensity scores are set to missing (as Stata's default predict after probit does) for observations excluded by perfect-prediction rules (dropped Congress levels or dropped covariates' nonzero values), so they get no IPW weight\n")
cat("DEVIATION: RD-IPW propensity probit is estimated on one row per sponsor-Congress drawn from the RD estimation sample (mixed-gender races with complete data, within the bandwidth), rather than on the first row of each sponsor-Congress in the party subsample\n")
cat("DEVIATION: Propensity-score probit now mimics Stata's perfect-prediction handling for covariates (a regressor whose nonzero values perfectly predict sponsor gender is dropped along with those observations before fitting), not only for Congress dummies\n")

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10, scientific = FALSE)))
}
