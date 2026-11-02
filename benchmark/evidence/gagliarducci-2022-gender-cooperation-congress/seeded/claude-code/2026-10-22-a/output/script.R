suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/seeded/2026-10-22-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta"
d <- read_dta(D)
d <- zap_labels(zap_formats(d))
d <- d[which(d$private == 0), ]
d <- as.data.frame(d)
d$sponsor_state_abbrev[is.na(d$sponsor_state_abbrev)] <- ""
d$gkey <- paste(d$v2, d$sponsor_state_abbrev, d$sponsor_district, d$sponsor_term_served, sep = "|")
d$tot_bills <- ave(as.numeric(!is.na(d$v2)), d$gkey, FUN = sum)
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
d$group_sponsor <- as.integer(factor(d$gkey))
d$tag_sponsor <- as.numeric(!duplicated(d$gkey))
d$pct_cosponsors_opposite <- 100 * d$numb_cosponsors_opposite / (d$numb_cosponsors + 1)
d$pct_cosponsors_opposite[!is.na(d$pct_cosponsors_opposite) & d$pct_cosponsors_opposite > 100] <- NA
d$tag_bill <- as.numeric(!duplicated(d[, c("v2", "HRnumber")]))

house <- grep("^house_", names(d), value = TRUE)
indivchars <- c("sponsor_democrat","sponsor_rookie","sponsor_tenure_run","sponsor_age","leader","ivycoll","black","occ0","occ1","occ2","occ3","occ4","borninstate","tot_bills")
districtchars <- c("NE","MW","WE","pct_black","pct_urban","pct_for_born","pct_age_over65","lninc","lnpden")
other_controls <- c(house, indivchars, districtchars)  # plus i.minor (absorbed as FE)

## ---- CCT (2014) bandwidth selector, translated from rdbwselect_2014.ado
## (p=1, q=2, deriv=0, uniform kernel, default nn variance with 3 matches, scaleregul=1)
kw_uni <- function(X, c, h) 0.5 * (abs((X - c) / h) <= 1) / h
nn_sigma <- function(X, Y, matches = 3, semantics = "distinct") {
  m <- matches + 1
  n <- length(X)
  if (semantics == "count") {
    sig <- numeric(n)
    for (k in seq_len(n)) {
      dx <- abs(X - X[k]); thr <- sort(dx, partial = m)[m]
      ind <- which(dx <= thr); Ji <- length(ind) - 1
      ym <- (sum(Y[ind]) - Y[k]) / Ji
      sig[k] <- Ji / (Ji + 1) * (Y[k] - ym)^2
    }
    return(sig)
  }
  u <- sort(unique(X)); U <- length(u); id <- match(X, u)
  sY <- as.numeric(tapply(Y, factor(id, levels = 1:U), sum)); cn <- tabulate(id, U)
  S <- C <- numeric(U)
  for (i in 1:U) {
    j <- max(1, i - m + 1):min(U, i + m - 1)
    dd <- abs(u[j] - u[i]); du <- sort(unique(dd)); thr <- du[min(m, length(du))]
    jj <- j[dd <= thr]; S[i] <- sum(sY[jj]); C[i] <- sum(cn[jj])
  }
  Ji <- C[id] - 1; ym <- (S[id] - Y) / Ji
  Ji / (Ji + 1) * (Y - ym)^2
}
stata_pct <- function(x, p) { x <- sort(x); n <- length(x); np <- n * p
  if (abs(np - round(np)) < 1e-12) { i <- round(np); (x[i] + x[min(i + 1, n)]) / 2 } else x[ceiling(np)] }
pw <- function(x, k) outer(x, 0:k, "^")
Vdiag <- function(Xm, w, sig, j) { G <- solve(crossprod(Xm, w * Xm)); P <- crossprod(Xm, (w * sig * w) * Xm); (G %*% P %*% G)[j, j] }
coefw <- function(Xm, w, Y, j) solve(crossprod(Xm, w * Xm), crossprod(Xm, w * Y))[j, 1]
cct_h <- function(y, x, c = 0, semantics = "distinct") {
  ok <- !is.na(y) & !is.na(x); y <- y[ok]; x <- x[ok]
  p <- 1; q <- 2; C1_h <- -0.166666666666666; C1_b <- 1.49999999999998; C1_q <- 1.99999999999972
  N <- length(x)
  h_pilot <- 1.84 * min(sd(x), (stata_pct(x, .75) - stata_pct(x, .25)) / 1.349) * N^(-1/5)
  L <- x < c; R <- x >= c
  Xl <- x[L] - c; Xr <- x[R] - c; Yl <- y[L]; Yr <- y[R]
  sl <- nn_sigma(x[L], Yl, 3, semantics); sr <- nn_sigma(x[R], Yr, 3, semantics)
  wl <- kw_uni(Xl, 0, h_pilot); wr <- kw_uni(Xr, 0, h_pilot)
  V_m3 <- Vdiag(pw(Xl, 3), wl, sl, 4) + Vdiag(pw(Xr, 3), wr, sr, 4)
  V_m2 <- Vdiag(pw(Xl, 2), wl, sl, 3) + Vdiag(pw(Xr, 2), wr, sr, 3)
  V_m0 <- Vdiag(pw(Xl, 1), wl, sl, 1) + Vdiag(pw(Xr, 1), wr, sr, 1)
  N_q <- (2*q+3) * N * h_pilot^(2*q+3) * V_m3
  m4l <- coefw(pw(Xl, 4), rep(1, length(Xl)), Yl, 5); m4r <- coefw(pw(Xr, 4), rep(1, length(Xr)), Yr, 5)
  D_q <- 2 * (C1_q * (m4r - m4l))^2
  q_CCT <- (N_q / (N * D_q))^(1/(2*q+5))
  N_b <- (2*p+3) * N * h_pilot^(2*p+3) * V_m2
  wql <- kw_uni(Xl, 0, q_CCT); wqr <- kw_uni(Xr, 0, q_CCT)
  m3l <- coefw(pw(Xl, 3), wql, Yl, 4); m3r <- coefw(pw(Xr, 3), wqr, Yr, 4)
  D_b <- 2 * (q-p) * (C1_b * (m3r + m3l))^2
  V_m3q <- Vdiag(pw(Xl, 3), wql, sl, 4) + Vdiag(pw(Xr, 3), wqr, sr, 4)
  R_b <- 2 * (q-p) * C1_b^2 * 3 * V_m3q
  b_CCT <- (N_b / (N * (D_b + R_b)))^(1/(2*q+3))
  N_h <- N * h_pilot * V_m0
  wbl <- kw_uni(Xl, 0, b_CCT); wbr <- kw_uni(Xr, 0, b_CCT)
  m2l <- coefw(pw(Xl, 2), wbl, Yl, 3); m2r <- coefw(pw(Xr, 2), wbr, Yr, 3)
  D_h <- 2 * (p+1) * (C1_h * (m2r - m2l))^2
  V_m2b <- Vdiag(pw(Xl, 2), wbl, sl, 3) + Vdiag(pw(Xr, 2), wbr, sr, 3)
  R_h <- 2 * (p+1) * C1_h^2 * 3 * V_m2b
  (N_h / (N * (D_h + R_h)))^(1/(2*p+3))
}
ifk <- list(all = function(d) d$tag_bill == 1,
            dem = function(d) !is.na(d$sponsor_party) & d$sponsor_party == 100 & d$tag_bill == 1,
            rep = function(d) !is.na(d$sponsor_party) & d$sponsor_party == 200 & d$tag_bill == 1)
## ---- Table 5 (Table5.do) translated to R
nonmiss <- function(vars, rows) { ok <- rows; for (v in vars) ok <- ok & !is.na(d[[v]]); ok }
fml <- function(dv, rhs, fe) as.formula(paste(dv, "~", paste(rhs, collapse = " + "), "|", paste(fe, collapse = " + ")))

## Stata-like probit: drop levels of v2 that predict the outcome perfectly (and their obs),
## drop constant/collinear regressors; predicted values for dropped-level obs use a zero dummy.
## Mimics Stata's probit + default predict: i.v2 base = lowest level (no indicator, never checked);
## any regressor x for which "x != 0 predicts success/failure perfectly" is dropped together with
## those observations (iterated), and predict returns missing for observations excluded by these
## rules (Stata's default without the `rules`/`asif` options).
stata_probit_pred <- function(rows_fit, rows_pred, xvars) {
  df <- d[rows_fit, c("sponsor_female", "v2", xvars)]
  df <- df[complete.cases(df), ]
  dum <- sort(unique(df$v2))[-1]
  mk <- function(dd) {
    M <- sapply(dum, function(l) as.numeric(dd$v2 == l))
    if (is.null(dim(M))) M <- matrix(M, nrow = nrow(dd))
    colnames(M) <- paste0("v2_", dum)
    cbind(M, as.matrix(dd[, xvars, drop = FALSE]))
  }
  X <- mk(df); y <- df$sponsor_female
  dropped <- character(0)
  repeat {
    hit <- FALSE
    for (cn in colnames(X)) {
      nz <- X[, cn] != 0
      if (any(nz) && !all(nz) && length(unique(y[nz])) == 1) {
        dropped <- c(dropped, cn); keep <- !nz
        X <- X[keep, setdiff(colnames(X), cn), drop = FALSE]; y <- y[keep]; hit <- TRUE; break
      }
    }
    if (!hit) break
  }
  if (length(dropped)) cat("  probit: perfect predictors dropped (with their obs):", dropped, "\n")
  X <- X[, apply(X, 2, function(z) length(unique(z)) > 1), drop = FALSE]
  fit <- glm.fit(cbind(1, X), y, family = binomial(link = "probit"))
  b <- fit$coefficients; b[is.na(b)] <- 0
  cat(sprintf("  probit N=%d, converged=%s\n", length(y), fit$converged))
  dp <- d[rows_pred, c("v2", xvars)]
  Xall <- mk(dp)
  p <- pnorm(as.vector(cbind(1, Xall[, colnames(X), drop = FALSE]) %*% b))
  for (cn in dropped) p[Xall[, cn] != 0] <- NA
  out <- rep(NA_real_, nrow(d))
  out[which(rows_pred)] <- p
  out
}

res <- list()
for (dv in c("numb_cosponsors", "pct_cosponsors_opposite")) {
  for (k in names(ifk)) {
    sk <- ifk[[k]](d)
    sample <- nonmiss(c(dv, "sponsor_female", "v2", "MV1_female", "femaleXMV1_female", "minor", other_controls),
                      sk & !is.na(d$mixed_gender_election) & d$mixed_gender_election == 1)
    band <- cct_h(d[[dv]][sk], d$MV1_female[sk], 0, "distinct")
    inband <- !is.na(d$MV1_female) & abs(d$MV1_female) <= band
    for (j in 1:5) {
      if (j == 1) {
        rows <- sk; f <- fml(dv, c("sponsor_female", other_controls), c("v2", "minor")); w <- NULL
      } else if (j == 2) {
        rows <- sk & sample & inband; f <- fml(dv, c("sponsor_female", "MV1_female", "femaleXMV1_female"), "v2"); w <- NULL
      } else if (j == 3) {
        ps <- stata_probit_pred(sk & d$tag_sponsor == 1 & inband, sample, districtchars)
        wt <- ifelse(d$sponsor_female == 1, 1 / ps, 1 / (1 - ps))
        rows <- sk & sample & inband & !is.na(wt)
        f <- fml(dv, c("sponsor_female", "MV1_female", "femaleXMV1_female", house), c("v2", "minor")); w <- wt
      } else {
        xv <- if (j == 4) c(districtchars, "absMV") else c(districtchars, indivchars, "absMV")
        ps <- stata_probit_pred(sk & d$tag_sponsor == 1, rep(TRUE, nrow(d)), xv)
        wt <- ifelse(d$sponsor_female == 1, 1 / ps, 1 / (1 - ps))
        rows <- sk & !is.na(wt)
        f <- fml(dv, c("sponsor_female", house), c("v2", "minor")); w <- wt
      }
      dd <- d[which(rows), ]
      if (!is.null(w)) dd$wt_ <- w[which(rows)]
      fit <- if (is.null(w)) feols(f, data = dd, cluster = ~group_sponsor, fixef.rm = "none", notes = FALSE) else
                             feols(f, data = dd, weights = ~wt_, cluster = ~group_sponsor, fixef.rm = "none", notes = FALSE)
      used <- obs(fit)
      b <- unname(coef(fit)["sponsor_female"]); se <- unname(se(fit)["sponsor_female"])
      nb <- nobs(fit); ns <- length(unique(dd$group_sponsor[used]))
      cat(sprintf("%-24s %-3s col%d: b=%8.3f se=%7.3f N=%6d n.spons=%5d band=%s\n", dv, k, j, b, se, nb, ns,
                  if (j %in% 2:3) sprintf("%.3f", band) else "-"))
      res[[paste(dv, k, j, sep = "_")]] <- c(b = b, n = nb, ns = ns)
    }
  }
}

g <- function(dv, k, j, what = "b") unname(res[[paste(dv, k, j, sep = "_")]][what])
cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.6f\n", g("numb_cosponsors", "all", 1)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.6f\n", g("numb_cosponsors", "rep", 1)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.6f\n", g("numb_cosponsors", "rep", 3)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.6f\n", g("numb_cosponsors", "rep", 5)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.6f\n", g("pct_cosponsors_opposite", "dem", 1)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.6f\n", g("pct_cosponsors_opposite", "dem", 2)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.6f\n", g("pct_cosponsors_opposite", "dem", 5)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.6f\n", g("pct_cosponsors_opposite", "rep", 1)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.6f\n", g("pct_cosponsors_opposite", "rep", 4)))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", as.integer(g("numb_cosponsors", "all", 1, "n"))))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", as.integer(g("numb_cosponsors", "all", 1, "ns"))))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", as.integer(g("pct_cosponsors_opposite", "dem", 1, "n"))))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", as.integer(g("pct_cosponsors_opposite", "rep", 1, "n"))))
