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
cat("dups bill:", sum(d$tag_bill == 0), " nrow:", nrow(d), "\n")
cat("house NA:", sum(is.na(d[, house])), "\n")
for (dv in c("numb_cosponsors", "pct_cosponsors_opposite")) for (k in names(ifk)) {
  s <- ifk[[k]](d)
  for (sem in c("distinct", "count")) {
    t0 <- Sys.time()
    h <- cct_h(d[[dv]][s], d$MV1_female[s], 0, sem)
    cat(sprintf("BW %s %s %s: %.4f (%.1fs)\n", dv, k, sem, h, as.numeric(Sys.time() - t0, units = "secs")))
  }
}
cat("paper: ncosp all 25 dem 30 rep 13; pctopp all 16 dem 24 rep 11\n")
