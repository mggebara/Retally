# Retally reproduction: Gagliarducci & Paserman (2022), Table 5 (selected cells)
# Follows "3 replication package/Dofiles/Table5.do".
suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)

base <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/seeded/2026-11-02-b/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package"
d <- read_dta(file.path(base, "Data/AnalysisData/bills_analysis_101-111_replication.dta"))
d <- zap_labels(d)
d <- as.data.frame(d)
d$sponsor_state_abbrev[d$sponsor_state_abbrev == ""] <- NA

# keep if private==0  (Stata drops missing)
d <- d[!is.na(d$private) & d$private == 0, ]

# sponsor (individual-Congress) key; Stata egen group/tag ignore rows with missing keys
keyvars <- c("v2", "sponsor_state_abbrev", "sponsor_district", "sponsor_term_served")
keymiss <- apply(is.na(d[, keyvars]), 1, any)
key <- do.call(paste, c(d[, keyvars], sep = "|"))
# tot_bills: bysort key: count(v2)  (computed even for rows with missing keys in Stata's bysort; groups by values)
d$tot_bills <- ave(as.numeric(!is.na(d$v2)), key, FUN = sum)
d$group_sponsor <- ifelse(keymiss, NA, key)
# tag_sponsor: first row of each sponsor group in sorted order
ord <- order(d$v2, d$sponsor_state_abbrev, d$sponsor_district, d$sponsor_term_served, seq_len(nrow(d)))
first <- rep(0L, nrow(d))
ko <- key[ord]
isfirst <- !duplicated(ko)
first[ord[isfirst]] <- 1L
d$tag_sponsor <- ifelse(keymiss, 0L, first)
# tag_bill
bmiss <- is.na(d$v2) | is.na(d$HRnumber)
d$tag_bill <- ifelse(bmiss, 0L, as.integer(!duplicated(paste(d$v2, d$HRnumber))))

d$sponsor_democrat <- ifelse(is.na(d$sponsor_party), NA, as.numeric(d$sponsor_party == 100))
si <- d$sponsor_state_icpsr
d$NE <- ifelse(is.na(si), NA, as.numeric(si >= 1 & si <= 14))
d$MW <- ifelse(is.na(si), NA, as.numeric(si >= 21 & si <= 37))
d$WE <- ifelse(is.na(si), NA, as.numeric(si >= 61 & si <= 82))
d$sponsor_age[!is.na(d$sponsor_age) & d$sponsor_age > 100] <- NA
d$sponsor_rookie <- ifelse(is.na(d$sponsor_tenure_run), NA, as.numeric(d$sponsor_tenure_run == 1))
d$leader <- ifelse(is.na(d$comc) | is.na(d$comr), NA, as.numeric(d$comc == 1 | d$comr == 1))
d$lnpden <- d$lnpop - d$lnarea
d$absMV <- abs(d$MV1_democrat)
d$pct_cosponsors_opposite <- 100 * d$numb_cosponsors_opposite / (d$numb_cosponsors + 1)
d$pct_cosponsors_opposite[!is.na(d$pct_cosponsors_opposite) & d$pct_cosponsors_opposite > 100] <- NA

house <- grep("^house_", names(d), value = TRUE)
billchars <- house                      # plus i.minor (as FE)
indivchars <- c("sponsor_democrat", "sponsor_rookie", "sponsor_tenure_run", "sponsor_age", "leader",
                "ivycoll", "black", "occ0", "occ1", "occ2", "occ3", "occ4", "borninstate", "tot_bills")
districtchars <- c("NE", "MW", "WE", "pct_black", "pct_urban", "pct_for_born", "pct_age_over65", "lninc", "lnpden")
other_controls <- c(billchars, indivchars, districtchars)

ifk <- list(
  all = d$tag_bill == 1,
  dem = !is.na(d$sponsor_party) & d$sponsor_party == 100 & d$tag_bill == 1,
  rep = !is.na(d$sponsor_party) & d$sponsor_party == 200 & d$tag_bill == 1)

# ---------------- regression helper (Stata reg ..., robust cluster(group_sponsor)) ----------------
run_reg <- function(y, rhs, fe, sub, w = NULL) {
  dd <- d[sub, , drop = FALSE]
  if (!is.null(w)) dd$wt__ <- w[sub]
  vars <- c(y, "sponsor_female", rhs, fe, "group_sponsor", if (!is.null(w)) "wt__")
  ok <- complete.cases(dd[, vars])
  dd <- dd[ok, , drop = FALSE]
  fml <- as.formula(paste(y, "~", paste(c("sponsor_female", rhs), collapse = " + "),
                          "|", paste(fe, collapse = " + ")))
  m <- if (is.null(w)) feols(fml, data = dd, cluster = ~group_sponsor, fixef.rm = "none")
       else feols(fml, data = dd, weights = ~wt__, cluster = ~group_sponsor, fixef.rm = "none")
  list(b = unname(coef(m)["sponsor_female"]), se = unname(se(m)["sponsor_female"]),
       n = nobs(m), ncl = length(unique(dd$group_sponsor)), rows = which(sub)[ok])
}

# ---------------- Stata-style probit with perfect-prediction handling for i.v2 ----------------
probit_ps <- function(sub, xvars) {
  dd <- d[sub, c("sponsor_female", "v2", xvars)]
  dd <- dd[complete.cases(dd), ]
  lv <- sort(unique(dd$v2))
  dum_lv <- lv                             # all levels checked for perfect prediction; base removed below
  mk <- function(df) {
    X <- sapply(dum_lv, function(l) as.numeric(df$v2 == l))
    X <- matrix(X, nrow = nrow(df))
    colnames(X) <- paste0("v2_", dum_lv)
    cbind(X, as.matrix(df[, xvars, drop = FALSE]))
  }
  X <- mk(dd); yv <- dd$sponsor_female
  # Stata probit: a regressor whose nonzero values predict the outcome perfectly is dropped
  # together with those observations ("x != 0 predicts failure perfectly"); repeat until none.
  dropped <- character(0)
  repeat {
    hit <- FALSE
    for (j in colnames(X)) {
      nz <- X[, j] != 0
      if (any(nz) && !all(nz) && length(unique(yv[nz])) == 1) {
        X <- X[!nz, setdiff(colnames(X), j), drop = FALSE]; yv <- yv[!nz]
        dropped <- c(dropped, j); hit <- TRUE; break
      }
    }
    if (!hit) break
  }
  v2cols <- grep("^v2_", colnames(X), value = TRUE)
  if (length(v2cols)) X <- X[, setdiff(colnames(X), v2cols[1]), drop = FALSE]   # lowest remaining level = base
  g <- glm.fit(cbind(1, X), yv, family = binomial(link = "probit"))
  cf <- g$coefficients; cf[is.na(cf)] <- 0   # collinear terms omitted
  names(cf) <- c("(Intercept)", colnames(X))
  Xall <- mk(d)
  xb <- cf[1] + drop(Xall[, colnames(X), drop = FALSE] %*% cf[-1])
  ps <- pnorm(xb)
  # Stata's predict (default, no 'rules') returns missing for observations excluded by a
  # perfect-prediction rule (x != 0 for a dropped regressor): those rows get no weight.
  for (j in dropped) ps[!is.na(Xall[, j]) & Xall[, j] != 0] <- NA
  list(ps = ps, dropped = dropped, n = length(yv))
}
ipw <- function(ps) ifelse(d$sponsor_female == 1, 1 / ps, 1 / (1 - ps))

# ---------------- rdbwselect_2014 (CCT 2014, uniform kernel, p=1, q=2, vce nn, matches 3) ----------------
stata_pct <- function(x, p) unname(quantile(x, p, type = 2))
nn_sigma <- function(X, Y, matches = 3) {
  m <- matches + 1
  ux <- sort(unique(X)); idx <- match(X, ux)
  cnt <- tabulate(idx, length(ux)); sm <- as.numeric(rowsum(Y, idx, reorder = TRUE))
  # for each unique value: included set (all values with distance <= m-th smallest distance incl. self)
  incl_n <- numeric(length(ux)); incl_s <- numeric(length(ux))
  for (u in seq_along(ux)) {
    if (cnt[u] >= m) { incl_n[u] <- cnt[u]; incl_s[u] <- sm[u]; next }
    dist <- abs(ux - ux[u]); o <- order(dist)
    cc <- cumsum(cnt[o]); kk <- which(cc >= m)[1]
    dm <- dist[o][kk]
    sel <- dist <= dm
    incl_n[u] <- sum(cnt[sel]); incl_s[u] <- sum(sm[sel])
  }
  Ji <- incl_n[idx] - 1
  avg <- (incl_s[idx] - Y) / Ji
  Ji / (Ji + 1) * (Y - avg)^2
}
polyX <- function(x, c, k) sapply(0:(k - 1), function(j) (x - c)^j)
wls <- function(X, w, y) { s <- w > 0; lm.wfit(X[s, , drop = FALSE], y[s], w[s])$coefficients }
sandw <- function(X, w, sig) {
  G <- crossprod(X, w * X); P <- crossprod(X, (w * sig * w) * X)
  iG <- solve(G); iG %*% P %*% iG
}
rdbw2014 <- function(y, x, c = 0, p = 1, q = 2, matches = 3, deriv = 0) {
  ok <- !is.na(y) & !is.na(x); y <- y[ok]; x <- x[ok]
  C1_h <- -0.166666666666666; C1_b <- 1.49999999999998; C1_q <- 1.99999999999972
  N <- length(x)
  h_pilot <- 1.84 * min(sd(x), (stata_pct(x, .75) - stata_pct(x, .25)) / 1.349) * N^(-1/5)
  L <- x < c; R <- x >= c
  Xl <- x[L]; Xr <- x[R]; Yl <- y[L]; Yr <- y[R]
  kw <- function(X, h) 0.5 * (abs((X - c) / h) <= 1) / h
  Xlq2 <- polyX(Xl, c, q + 3); Xrq2 <- polyX(Xr, c, q + 3)
  Xlq1 <- Xlq2[, 1:(q + 2)]; Xrq1 <- Xrq2[, 1:(q + 2)]
  Xlq <- Xlq2[, 1:(q + 1)]; Xrq <- Xrq2[, 1:(q + 1)]
  Xlp <- Xlq2[, 1:(p + 1)]; Xrp <- Xrq2[, 1:(p + 1)]
  wl <- kw(Xl, h_pilot); wr <- kw(Xr, h_pilot)
  sl <- nn_sigma(Xl, Yl, matches); sr <- nn_sigma(Xr, Yr, matches)
  V_m3 <- sandw(Xlq1, wl, sl)[q + 2, q + 2] + sandw(Xrq1, wr, sr)[q + 2, q + 2]
  V_m2 <- sandw(Xlq, wl, sl)[q + 1, q + 1] + sandw(Xrq, wr, sr)[q + 1, q + 1]
  V_m0 <- sandw(Xlp, wl, sl)[deriv + 1, deriv + 1] + sandw(Xrp, wr, sr)[deriv + 1, deriv + 1]
  N_q <- (2 * q + 3) * N * h_pilot^(2 * q + 3) * V_m3
  m4l <- lm.fit(Xlq2, Yl)$coefficients[q + 3]; m4r <- lm.fit(Xrq2, Yr)$coefficients[q + 3]
  D_q <- 2 * (C1_q * (m4r - (-1)^(deriv + q) * m4l))^2
  q_CCT <- (N_q / (N * D_q))^(1 / (2 * q + 5))
  N_b <- (2 * p + 3) * N * h_pilot^(2 * p + 3) * V_m2
  wql <- kw(Xl, q_CCT); wqr <- kw(Xr, q_CCT)
  m3l <- wls(Xlq1, wql, Yl)[q + 2]; m3r <- wls(Xrq1, wqr, Yr)[q + 2]
  D_b <- 2 * (q - p) * (C1_b * (m3r - (-1)^(deriv + q + 1) * m3l))^2
  V_m3q <- sandw(Xlq1, wql, sl)[q + 2, q + 2] + sandw(Xrq1, wqr, sr)[q + 2, q + 2]
  R_b <- 2 * (q - p) * C1_b^2 * 3 * V_m3q
  b_CCT <- (N_b / (N * (D_b + R_b)))^(1 / (2 * q + 3))
  N_h <- (2 * deriv + 1) * N * h_pilot^(2 * deriv + 1) * V_m0
  wbl <- kw(Xl, b_CCT); wbr <- kw(Xr, b_CCT)
  m2l <- wls(Xlq, wbl, Yl)[p + 2]; m2r <- wls(Xrq, wbr, Yr)[p + 2]
  D_h <- 2 * (p + 1 - deriv) * (C1_h * (m2r - (-1)^(deriv + p + 1) * m2l))^2
  V_m2b <- sandw(Xlq, wbl, sl)[p + 2, p + 2] + sandw(Xrq, wbr, sr)[p + 2, p + 2]
  R_h <- 2 * (p + 1 - deriv) * C1_h^2 * 3 * V_m2b
  h_CCT <- (N_h / (N * (D_h + R_h)))^(1 / (2 * p + 3))
  c(h = unname(h_CCT), b = unname(b_CCT), N = N, h_pilot = h_pilot)
}

# ---------------- Table 5 columns ----------------
col1 <- function(y, k) run_reg(y, other_controls, c("v2", "minor"), ifk[[k]])
mixed_sample <- function(y, k) {
  r <- run_reg(y, c("MV1_female", "femaleXMV1_female", other_controls), c("v2", "minor"),
               ifk[[k]] & !is.na(d$mixed_gender_election) & d$mixed_gender_election == 1)
  s <- rep(FALSE, nrow(d)); s[r$rows] <- TRUE; s
}
col2 <- function(y, k) {
  bw <- rdbw2014(d[[y]][ifk[[k]]], d$MV1_female[ifk[[k]]])
  smp <- mixed_sample(y, k)
  inb <- !is.na(d$MV1_female) & abs(d$MV1_female) <= bw["h"]
  r <- run_reg(y, c("MV1_female", "femaleXMV1_female"), "v2", smp & inb)
  r$bw <- bw; r
}
col3 <- function(y, k) {
  bw <- rdbw2014(d[[y]][ifk[[k]]], d$MV1_female[ifk[[k]]])
  smp <- mixed_sample(y, k)
  inb <- !is.na(d$MV1_female) & abs(d$MV1_female) <= bw["h"]
  pr <- probit_ps(ifk[[k]] & d$tag_sponsor == 1 & inb, districtchars)
  w <- ipw(pr$ps)
  r <- run_reg(y, c("MV1_female", "femaleXMV1_female", billchars), c("v2", "minor"), smp & inb, w = w)
  r$bw <- bw; r$dropped <- pr$dropped; r
}
col45 <- function(y, k, indiv) {
  xv <- c(districtchars, if (indiv) indivchars, "absMV")
  pr <- probit_ps(ifk[[k]] & d$tag_sponsor == 1, xv)
  w <- ipw(pr$ps)
  r <- run_reg(y, billchars, c("v2", "minor"), ifk[[k]], w = w)
  r$dropped <- pr$dropped; r
}
show <- function(lab, r) {
  cat(sprintf("%-45s b=%.4f se=%.4f N=%d clusters=%d", lab, r$b, r$se, r$n, r$ncl))
  if (!is.null(r$bw)) cat(sprintf(" h_CCT=%.3f b_CCT=%.3f", r$bw["h"], r$bw["b"]))
  if (!is.null(r$dropped) && length(r$dropped)) cat(" probit-dropped v2:", r$dropped)
  cat("\n")
}

r1 <- col1("numb_cosponsors", "all");             show("A all OLS", r1)
r2 <- col1("numb_cosponsors", "rep");             show("A rep OLS", r2)
r3 <- col3("numb_cosponsors", "rep");             show("A rep RD+IPW", r3)
r4 <- col45("numb_cosponsors", "rep", TRUE);      show("A rep PS district+MV+sponsor", r4)
r5 <- col1("pct_cosponsors_opposite", "dem");     show("B dem OLS", r5)
r6 <- col2("pct_cosponsors_opposite", "dem");     show("B dem RD", r6)
r7 <- col45("pct_cosponsors_opposite", "dem", TRUE); show("B dem PS district+MV+sponsor", r7)
r8 <- col1("pct_cosponsors_opposite", "rep");     show("B rep OLS", r8)
r9 <- col45("pct_cosponsors_opposite", "rep", FALSE); show("B rep PS district+MV", r9)

out <- c(
  female_sponsor_ncosponsors_all_ols = r1$b,
  female_sponsor_ncosponsors_rep_ols = r2$b,
  female_sponsor_ncosponsors_rep_rd_ipw = r3$b,
  female_sponsor_ncosponsors_rep_ipw_sponsor = r4$b,
  female_sponsor_pct_opposite_dem_ols = r5$b,
  female_sponsor_pct_opposite_dem_rd = r6$b,
  female_sponsor_pct_opposite_dem_ipw_sponsor = r7$b,
  female_sponsor_pct_opposite_rep_ols = r8$b,
  female_sponsor_pct_opposite_rep_ipw_district = r9$b,
  n_bills_ncosponsors_all_ols = r1$n,
  n_sponsor_terms_ncosponsors_all_ols = r1$ncl,
  n_bills_pct_opposite_dem_ols = r5$n,
  n_bills_pct_opposite_rep_ols = r8$n)
for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))
