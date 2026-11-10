# Butera, Metcalfe, Morrison & Taubinsky (2022), "Measuring the Welfare Effects of Shame and Pride"
# Independent reproduction of Table 5 (cols 1-3) and Table 7 (Berkeley action-signaling + panel c)
suppressMessages({library(readr); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-c/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)

# Pattern of the binary yes/no preference for public recognition across the 18 intervals (0-99 ... 1700+)
pat <- function(x) { d <- diff(x); d <- sign(d[d != 0]); if (!length(d)) return("flat")
  paste(ifelse(rle(d)$values > 0, "U", "D"), collapse = "") }

load_sample <- function(fn) {
  d <- suppressMessages(read_csv(file.path(base, fn), show_col_types = FALSE, guess_max = 5000))
  n0 <- nrow(d)
  d$pat <- apply(as.matrix(d[, paste0("preference_", lv)]), 1, pat)
  # Exclusion 1: attention check (pass = left blank / missing)
  d <- d[is.na(d$attention_check), ]
  n1 <- nrow(d)
  # Exclusion 2: incoherent preferences. Coherent = never wants PR, monotonically increasing
  # (single switch no->yes), or single-peaked (no->yes->no). Everything else is incoherent.
  d <- d[d$pat %in% c("flat", "U", "UD"), ]
  n2 <- nrow(d)
  cat(sprintf("%s: raw %d, fail attention %d, incoherent %d, remaining %d\n", fn, n0, n0 - n1, n1 - n2, n2))
  d
}

pro <- load_sample("prolific_survey_data.csv")
# Prolific: drop participants with missing recognition-group assignment or missing practice-round score
# (2 participants); needed to match the paper's final Prolific sample of 968 and its group-size breakdown.
nb <- nrow(pro)
pro <- pro[!is.na(pro$recog_group_assign) & !is.na(pro$PracticePts), ]
cat(sprintf("Prolific: dropped %d with missing group assignment / practice score -> %d\n", nb - nrow(pro), nrow(pro)))
cat(sprintf("DEVIATION: Prolific sample additionally drops %d participants with missing recog_group_assign or PracticePts (to reach the paper's N=968)\n", nb - nrow(pro)))
ber <- load_sample("berkeley_survey_data.csv")
bu  <- load_sample("bu_qm222_survey_data.csv")   # BU main sample = QM222 classroom (121 completers)

to_long <- function(d) {
  d %>% select(id, Condition, AnomPts, EarnPts, RecogPts) %>%
    pivot_longer(c(AnomPts, EarnPts, RecogPts), names_to = "round", values_to = "points") %>%
    mutate(letter = c(AnomPts = "A", EarnPts = "E", RecogPts = "R")[round],
           pos = mapply(function(s, l) regexpr(l, s)[1], Condition, letter),
           pr = as.integer(letter == "R"), fi = as.integer(letter == "E"),
           pos2 = as.integer(pos == 2), pos3 = as.integer(pos == 3))
}

t5 <- function(d) {
  L <- to_long(d)
  m <- feols(points ~ pr + fi + pos2 + pos3, data = L, cluster = ~id)
  list(m = m, L = L, ctrl = mean(d$AnomPts))
}
r_pro <- t5(pro); r_ber <- t5(ber); r_bu <- t5(bu)
for (nm in c("Prolific", "Berkeley", "BU")) {
  r <- list(Prolific = r_pro, Berkeley = r_ber, BU = r_bu)[[nm]]
  ct <- coeftable(r$m)
  cat(sprintf("Table5 %s: PR %.2f (%.2f)  FI %.2f (%.2f)  N=%d  control mean %.1f  order F p=%.3f\n", nm,
              ct["pr", 1], ct["pr", 2], ct["fi", 1], ct["fi", 2], nobs(r$m), r$ctrl,
              wald(r$m, keep = "^pos", print = FALSE)$p))
}

# ---- Table 6 col (4): Berkeley WTP on midpoint (00s) and square, excl. 1700+ interval ----
wtp_long <- function(d) {
  P <- as.matrix(d[, paste0("preference_", lv)])
  A <- as.matrix(d[, paste0("pref_anom_", lv, "_1")])
  R <- as.matrix(d[, paste0("pref_rec_", lv, "_1")])
  W <- ifelse(P == 1, R, -A)   # signed WTP for public recognition ($)
  data.frame(id = rep(d$id, times = length(lv)), lvl = rep(lv, each = nrow(d)), wtp = as.vector(W)) %>%
    filter(lvl < 1700) %>% mutate(x = (lvl + 50) / 100, x2 = x^2)
}
Wb <- wtp_long(ber)
m6 <- feols(wtp ~ x + x2, data = Wb, cluster = ~id)
print(coeftable(m6)); cat("Table6 col4 N =", nobs(m6), "\n")

structural <- function(r0, r1, r2, a0, tau, p) {
  r0 <- unname(r0); r1 <- unname(r1); r2 <- unname(r2); a0 <- unname(a0); tau <- unname(tau)
  abar <- a0 + tau                       # average performance with public recognition (00s)
  g1 <- sqrt(r1^2 - 4 * r0 * r2)
  g2 <- r2
  rho <- (g1 - r1) / (2 * abar * r2)
  cc <- (r1 + 2 * r2 * (a0 + tau)) / tau
  c(g1 = g1, g2 = g2, rho = rho, c = cc, pred = p / cc)
}
b6 <- coef(m6)
a0_b <- mean(ber$AnomPts) / 100
tau_b <- coef(r_ber$m)["pr"] / 100
p_b <- 0.05 * 10                         # 5 cents per 10 points = $0.50 per 100 points
st <- structural(b6[1], b6["x"], b6["x2"], a0_b, tau_b, p_b)
cat(sprintf("Structural Berkeley: g1=%.3f g2=%.4f rho=%.3f c=%.3f pred=%.3f actual FI=%.3f\n",
            st["g1"], st["g2"], st["rho"], st["c"], st["pred"], coef(r_ber$m)["fi"] / 100))

# Participant-blocked percentile bootstrap (1000 reps) for the structural parameters
ids <- unique(ber$id)
Lb <- r_ber$L
idxL <- split(seq_len(nrow(Lb)), Lb$id)[as.character(ids)]
idxW <- split(seq_len(nrow(Wb)), Wb$id)[as.character(ids)]
XL <- cbind(1, Lb$pr, Lb$fi, Lb$pos2, Lb$pos3); XW <- cbind(1, Wb$x, Wb$x2)
boot <- replicate(1000, {
  s <- sample(seq_along(ids), length(ids), replace = TRUE)
  db <- ber[s, ]
  rl <- unlist(idxL[s], use.names = FALSE); rw <- unlist(idxW[s], use.names = FALSE)
  b5 <- lm.fit(XL[rl, ], Lb$points[rl])$coefficients
  b6s <- lm.fit(XW[rw, ], Wb$wtp[rw])$coefficients
  structural(b6s[1], b6s[2], b6s[3], mean(db$AnomPts) / 100, b5[2] / 100, p_b)
})
ci <- apply(boot, 1, quantile, c(0.025, 0.975), na.rm = TRUE)
print(round(ci, 3))

ctp <- coef(r_pro$m); ctb <- coef(r_ber$m); ctu <- coef(r_bu$m)
cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.4f\n", ctp["pr"]))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.4f\n", ctp["fi"]))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.4f\n", ctb["pr"]))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.4f\n", ctb["fi"]))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.4f\n", ctu["pr"]))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.4f\n", ctu["fi"]))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", nobs(r_pro$m)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", nobs(r_ber$m)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", nobs(r_bu$m)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.4f\n", st["g1"]))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.4f\n", st["rho"]))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.4f\n", st["c"]))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.4f\n", st["pred"]))
