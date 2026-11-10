# Butera, Metcalfe, Morrison & Taubinsky (2022) "Measuring the Welfare Effects of Shame and Pride"
# Independent, blind reproduction of Table 5 (cols 1-3) and Table 7 Berkeley action-signaling
# parameters (gamma_1, rho, c) and the panel (c) model-predicted financial-incentive effect.
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)

base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific = "prolific_survey_data.csv",
           berkeley = "berkeley_survey_data.csv",
           bu       = "bu_qm222_survey_data.csv")   # BU sample = QM222 class (QM221 data not used in main text)
iv <- seq(0, 1700, 100)   # 18 WTP intervals: 0-99, ..., 1600-1699, 1700+

# ---- sample construction ---------------------------------------------------
# (1) attention check: attention_check is missing for those who passed.
# (2) "incoherent" preferences for public recognition: signed WTP profile
#     (WTP for recognition if preferred recognition, minus WTP for anonymity if preferred
#     anonymity) whose strict preferences (non-zero WTP) are not monotone in performance
#     direction, i.e. strictly prefers anonymity at some higher interval than one where
#     they strictly prefer recognition.  (Zero WTP = indifference, compatible with anything.)
weakly_inc <- function(x) length(x) < 2 || all(diff(x) >= 0)
coherent_fun <- function(w) { s <- sign(w); s <- s[s != 0]; weakly_inc(s) }

build <- function(nm) {
  d <- read_csv(file.path(base, files[[nm]]), show_col_types = FALSE, guess_max = 5000)
  P <- as.matrix(d[, paste0("preference_", iv)])
  R <- as.matrix(d[, paste0("pref_rec_", iv, "_1")])
  A <- as.matrix(d[, paste0("pref_anom_", iv, "_1")])
  W <- ifelse(P == 1, R, -A)
  d$coherent <- apply(W, 1, coherent_fun)
  d$att_pass <- is.na(d$attention_check)
  d$pid <- paste0(nm, "_", seq_len(nrow(d)))
  colnames(W) <- paste0("wtp_", iv)
  d <- bind_cols(d, as.data.frame(W))
  cat(sprintf("[%s] completed=%d  attention-fail=%d  incoherent(all)=%d  final=%d\n", nm, nrow(d),
              sum(!d$att_pass), sum(!d$coherent), sum(d$att_pass & d$coherent)))
  d[d$att_pass & d$coherent, ]
}
samples <- lapply(names(files), build); names(samples) <- names(files)

# ---- Table 5: points on round type, round-order dummies, cluster by participant -------------
to_long <- function(d) {
  d %>% select(pid, Condition, AnomPts, EarnPts, RecogPts) %>%
    pivot_longer(c(AnomPts, EarnPts, RecogPts), names_to = "round", values_to = "points") %>%
    mutate(letter = c(AnomPts = "A", EarnPts = "E", RecogPts = "R")[round],
           order = mapply(function(cond, l) regexpr(l, cond, fixed = TRUE)[1], Condition, letter),
           public = as.integer(letter == "R"),
           financial = as.integer(letter == "E"))
}
t5 <- list()
for (nm in names(samples)) {
  L <- to_long(samples[[nm]])
  stopifnot(all(L$order %in% 1:3))
  m <- feols(points ~ public + financial + i(order, ref = 1), data = L, cluster = ~pid)
  cm <- mean(samples[[nm]]$AnomPts)
  cat(sprintf("\n[%s] Table 5: N obs=%d, subjects=%d, control mean=%.1f (SE %.1f)\n", nm, nobs(m),
              length(unique(L$pid)), cm, sd(samples[[nm]]$AnomPts) / sqrt(nrow(samples[[nm]]))))
  print(coeftable(m))
  t5[[nm]] <- list(model = m, nobs = nobs(m), a0 = cm)
}

# ---- Table 6 col (4): Berkeley quadratic WTP regression, 1700+ interval excluded ---------------
b <- samples$berkeley
WL <- b %>% select(pid, starts_with("wtp_")) %>%
  pivot_longer(starts_with("wtp_"), names_to = "lev", values_to = "wtp") %>%
  mutate(lo = as.numeric(sub("wtp_", "", lev))) %>%
  filter(lo < 1700) %>%
  mutate(pts = (lo + 50) / 100, pts2 = pts^2)        # interval midpoint in hundreds of points
m6 <- feols(wtp ~ pts + pts2, data = WL, cluster = ~pid)
cat(sprintf("\n[berkeley] Table 6 col 4: N obs=%d\n", nobs(m6))); print(coeftable(m6))
r0 <- unname(coef(m6)["(Intercept)"]); r1 <- unname(coef(m6)["pts"]); r2 <- unname(coef(m6)["pts2"])

# ---- Table 7 Berkeley, action-signaling model (Appendix F.1) ----------------------------------
tau  <- unname(coef(t5$berkeley$model)["public"]) / 100      # PR effect, hundreds of points
a0   <- t5$berkeley$a0 / 100                                  # anonymous-round mean, hundreds
abar <- a0 + tau                                              # average performance with PR
disc <- r1^2 - 4 * r0 * r2
gamma1 <- sqrt(disc)                                          # eq. (20)
gamma2 <- r2                                                  # eq. (21)
rho    <- (sqrt(disc) - r1) / (2 * abar * r2)                 # eq. (22) / (26)
cpar   <- (r1 + 2 * r2 * (a0 + tau)) / tau                    # eq. (27)
p      <- 0.50                                                # 5 cents / 10 points = $0.50 / 100 points
pred   <- p / cpar                                            # predicted financial incentive effect
cat(sprintf("\n[berkeley] r0=%.4f r1=%.4f r2=%.5f a0=%.4f tau=%.4f abar=%.4f\n", r0, r1, r2, a0, tau, abar))
cat(sprintf("[berkeley] gamma1=%.4f gamma2=%.5f rho=%.4f c=%.4f pred=%.4f actual FI (00s)=%.4f\n",
            gamma1, gamma2, rho, cpar, pred, coef(t5$berkeley$model)["financial"] / 100))

cat("\nDEVIATION: Prolific final sample has 972 participants under the stated exclusions (paper reports 968); no further unexplained exclusions applied.\n")
cat("DEVIATION: rho uses the average with-PR performance (anonymous mean + Table 5 col 2 PR effect) as abar, per the quantity definition.\n")

res <- c(
  public_recognition_points_prolific_table5_col1   = unname(coef(t5$prolific$model)["public"]),
  financial_incentives_points_prolific_table5_col1 = unname(coef(t5$prolific$model)["financial"]),
  public_recognition_points_berkeley_table5_col2   = unname(coef(t5$berkeley$model)["public"]),
  financial_incentives_points_berkeley_table5_col2 = unname(coef(t5$berkeley$model)["financial"]),
  public_recognition_points_bu_table5_col3         = unname(coef(t5$bu$model)["public"]),
  financial_incentives_points_bu_table5_col3       = unname(coef(t5$bu$model)["financial"]),
  n_obs_prolific_table5_col1 = t5$prolific$nobs,
  n_obs_berkeley_table5_col2 = t5$berkeley$nobs,
  n_obs_bu_table5_col3       = t5$bu$nobs,
  action_signaling_gamma1_berkeley_table7_panelA = gamma1,
  action_signaling_rho_berkeley_table7_panelA    = rho,
  cost_parameter_c_berkeley_table7_panelA        = cpar,
  predicted_financial_incentive_effect_berkeley_table7_panelC = pred
)
cat("\n")
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
