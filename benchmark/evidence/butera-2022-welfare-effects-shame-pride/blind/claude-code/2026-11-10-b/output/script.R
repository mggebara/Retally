# Butera, Metcalfe, Morrison & Taubinsky (2022), "Measuring the Welfare Effects of Shame and Pride"
# Independent, blind reproduction of Table 5 (cols 1-3) and Table 7 (Berkeley, action-signaling
# parameters and predicted financial-incentive effect).
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(fixest)
})
set.seed(42)

base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific = "prolific_survey_data.csv",
           berkeley = "berkeley_survey_data.csv",
           bu       = "bu_qm222_survey_data.csv")   # BU sample = QM222 class (QM221 reported separately in the appendix)
lev <- seq(0, 1700, 100)

# ---- Sample restrictions -------------------------------------------------------------
# (i) attention check: attention_check is missing for participants who pass.
# (ii) "incoherent" preferences for public recognition: the binary opt-in/opt-out
#      preference across the 18 performance intervals must be weakly increasing in points
#      (0...0 1...1, including all-0 / all-1) or single-peaked with an interior peak
#      (0...0 1...1 0...0, wanting to look "average"); anything else (decreasing,
#      valley-shaped, or multiple switches) is classified as incoherent.
pclass <- function(p) {
  s <- paste(rle(as.integer(p))$values, collapse = "")
  if (s %in% c("0", "1", "01")) return("increasing")
  if (s == "010") return("interior_peak")
  "incoherent"
}

load_sample <- function(f) {
  df <- read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 5000)
  P <- as.matrix(df[, paste0("preference_", lev)])
  df$pref_class <- apply(P, 1, pclass)
  df$att_pass <- is.na(df$attention_check)
  df
}

dat <- lapply(files, load_sample)
for (nm in names(dat)) {
  d <- dat[[nm]]
  cat(sprintf("%s: N=%d, attention fails=%d, incoherent among passers=%d, final=%d\n", nm, nrow(d),
              sum(!d$att_pass), sum(d$att_pass & d$pref_class == "incoherent"),
              sum(d$att_pass & d$pref_class != "incoherent")))
}
final <- lapply(dat, function(d) d[d$att_pass & d$pref_class != "incoherent", ])

# ---- Table 5: points on round indicators with round-order dummies ----------------------
make_long <- function(d) {
  long <- bind_rows(
    tibble(id = d$id, cond = d$Condition, round = "A", points = d$AnomPts),
    tibble(id = d$id, cond = d$Condition, round = "E", points = d$EarnPts),
    tibble(id = d$id, cond = d$Condition, round = "R", points = d$RecogPts))
  long$position <- mapply(function(cn, r) regexpr(r, cn, fixed = TRUE)[1], long$cond, long$round)
  long$public <- as.integer(long$round == "R")
  long$financial <- as.integer(long$round == "E")
  long
}

t5 <- list()
for (nm in names(final)) {
  L <- make_long(final[[nm]])
  stopifnot(all(L$position %in% 1:3))
  m <- feols(points ~ public + financial + i(position, ref = 1), data = L, cluster = ~id)
  cat("\nTable 5 regression,", nm, "\n"); print(coeftable(m))
  ft <- wald(m, keep = "position", print = FALSE)
  cat(sprintf("order dummies joint F p-value: %.3f ; control mean (anon round): %.1f\n",
              ft$p, mean(final[[nm]]$AnomPts)))
  t5[[nm]] <- m
}

# ---- Table 6 col (4): Berkeley quadratic reduced-form PRU --------------------------------
wtp_long <- function(d) {
  out <- lapply(lev, function(l) {
    p <- d[[paste0("preference_", l)]]
    rec <- d[[paste0("pref_rec_", l, "_1")]]
    an <- d[[paste0("pref_anom_", l, "_1")]]
    tibble(id = d$id, lev = l, wtp = ifelse(p == 1, rec, -an))
  })
  w <- bind_rows(out)
  w <- w[w$lev < 1700, ]                 # exclude the >=1700 interval
  w$m <- (w$lev + 50) / 100              # interval midpoint, hundreds of points
  w
}
WB <- wtp_long(final$berkeley)
stopifnot(!any(is.na(WB$wtp)))
q6 <- feols(wtp ~ m + I(m^2), data = WB, cluster = ~id)
cat("\nTable 6 col (4) (Berkeley quadratic PRU):\n"); print(coeftable(q6))

# ---- Table 7 panel (a)/(c): action-signaling model, Berkeley ----------------------------
p_incentive <- 0.05 * 10   # 5 cents per 10 points = $0.50 per hundred points
structural <- function(r0, r1, r2, a0, tau) {
  abar <- a0 + tau                                   # average performance with public recognition
  disc <- r1^2 - 4 * r0 * r2
  g1 <- sqrt(disc)                                   # eq. (20)
  g2 <- r2                                           # eq. (21)
  rho <- (g1 - r1) / (2 * abar * r2)                 # eq. (22)
  cc <- (r1 + 2 * r2 * (a0 + tau)) / tau             # eq. (27)
  c(gamma1 = g1, gamma2 = g2, rho = rho, c = cc, pred = p_incentive / cc)
}
est_berk <- function(d) {
  W <- wtp_long(d)
  X <- cbind(1, W$m, W$m^2)
  r <- qr.coef(qr(X), W$wtp)
  L <- make_long(d)
  X5 <- cbind(1, L$public, L$financial, L$position == 2, L$position == 3)
  b5 <- qr.coef(qr(X5), L$points)
  structural(r[1], r[2], r[3], mean(d$AnomPts) / 100, b5[2] / 100)
}
rr <- coef(q6)
a0B <- mean(final$berkeley$AnomPts) / 100
tauB <- coef(t5$berkeley)[["public"]] / 100
stB <- structural(rr[[1]], rr[[2]], rr[[3]], a0B, tauB)
stopifnot(isTRUE(all.equal(unname(stB), unname(est_berk(final$berkeley)))))
cat(sprintf("\nBerkeley: a0 = %.4f (hundreds), tau = %.4f (hundreds), r = (%.4f, %.4f, %.5f)\n",
            a0B, tauB, rr[[1]], rr[[2]], rr[[3]]))
print(round(stB, 4))
cat(sprintf("Directly estimated financial incentive effect (hundreds): %.4f\n",
            coef(t5$berkeley)[["financial"]] / 100))
# diagnostic: rho using the anonymous-round mean as the reference average instead
cat(sprintf("Diagnostic: rho with abar = anonymous mean only: %.4f\n",
            (stB[["gamma1"]] - rr[[2]]) / (2 * a0B * rr[[3]])))

# participant-level (block) bootstrap, 1000 replications, percentile CIs
dB <- final$berkeley
B <- 1000
bs <- t(replicate(B, est_berk(dB[sample.int(nrow(dB), replace = TRUE), ])))
ci <- apply(bs, 2, quantile, probs = c(0.025, 0.975), na.rm = TRUE)
cat("\nBootstrap 95% percentile CIs (Berkeley, 1000 reps, participant-level):\n"); print(round(ci, 4))
cat("bootstrap reps with NaN gamma1:", sum(is.na(bs[, "gamma1"])), "\n")

# ---- RESULT lines ---------------------------------------------------------------------
cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.6f\n", coef(t5$prolific)[["public"]]))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.6f\n", coef(t5$prolific)[["financial"]]))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.6f\n", coef(t5$berkeley)[["public"]]))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.6f\n", coef(t5$berkeley)[["financial"]]))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.6f\n", coef(t5$bu)[["public"]]))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.6f\n", coef(t5$bu)[["financial"]]))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", nobs(t5$prolific)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", nobs(t5$berkeley)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", nobs(t5$bu)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.6f\n", stB[["gamma1"]]))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.6f\n", stB[["rho"]]))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.6f\n", stB[["c"]]))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.6f\n", stB[["pred"]]))
