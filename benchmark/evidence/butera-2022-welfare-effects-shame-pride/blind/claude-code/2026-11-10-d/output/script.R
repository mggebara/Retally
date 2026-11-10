# Butera, Metcalfe, Morrison & Taubinsky -- "Measuring the Welfare Effects of Shame and Pride"
# Independent, blind reproduction of Table 5 (cols 1-3) and Table 7 action-signaling / financial-incentive
# entries for the Berkeley sample.  Method reconstructed from the paper text only.
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)

D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE, guess_max = 10000)
raw <- list(prolific = rd("prolific_survey_data.csv"),
            berkeley = rd("berkeley_survey_data.csv"),
            bu       = rd("bu_qm222_survey_data.csv"))   # BU experiment = QM222 classroom (121 completers)

ints <- seq(0, 1700, 100)

# ---- Sample construction -------------------------------------------------------------------
# (i) attention check: passed iff the item was left blank (attention_check missing).
# (ii) "incoherent" preferences: the yes/no preference-for-recognition profile over the 18 intervals
#      must be (weakly) monotone increasing, constant, or single-peaked (0..0 1..1 0..0); any other
#      shape (decreasing, U-shaped, multiple switches) is incoherent.
shape <- function(x) {
  s <- sign(diff(x)); s <- s[s != 0]
  if (length(s) == 0) return("flat")
  paste(ifelse(rle(s)$values > 0, "U", "D"), collapse = "")
}
clean <- lapply(names(raw), function(nm) {
  d <- raw[[nm]]
  P <- as.matrix(d[, paste0("preference_", ints)])
  d$pref_shape <- apply(P, 1, shape)
  d$att_ok <- is.na(d$attention_check)
  d$coherent <- d$pref_shape %in% c("flat", "U", "UD")
  cat(sprintf("%s: completed %d, fail attention %d, incoherent among passers %d, final %d\n",
              nm, nrow(d), sum(!d$att_ok), sum(d$att_ok & !d$coherent), sum(d$att_ok & d$coherent)))
  d[d$att_ok & d$coherent, ]
})
names(clean) <- names(raw)

# ---- Table 5: points on round indicators + round-order dummies, clustered by participant ----
to_long <- function(d) {
  d %>% select(id, Condition, AnomPts, RecogPts, EarnPts) %>%
    pivot_longer(c(AnomPts, RecogPts, EarnPts), names_to = "round", values_to = "points") %>%
    mutate(letter = recode(round, AnomPts = "A", RecogPts = "R", EarnPts = "E"),
           position = mapply(function(cond, l) regexpr(l, cond, fixed = TRUE)[1], Condition, letter),
           public = as.integer(letter == "R"),
           financial = as.integer(letter == "E"))
}
t5 <- list()
for (nm in names(clean)) {
  L <- to_long(clean[[nm]])
  stopifnot(all(L$position %in% 1:3))
  m <- feols(points ~ public + financial + i(position, ref = 1), data = L, cluster = ~id)
  cat("\n---- Table 5,", nm, "----\n"); print(coeftable(m))
  w <- tryCatch(wald(m, keep = "position", print = FALSE)$p, error = function(e) NA)
  cat("order dummies joint Wald p:", w, "\n")
  cat("control mean (anonymous round):", mean(clean[[nm]]$AnomPts), "\n")
  t5[[nm]] <- list(pr = unname(coef(m)["public"]), fi = unname(coef(m)["financial"]), n = nobs(m))
}

# ---- Table 6 column (4): Berkeley quadratic reduced-form PRU --------------------------------
wtp_long <- function(d) {
  P <- as.matrix(d[, paste0("preference_", ints)])
  R <- as.matrix(d[, paste0("pref_rec_", ints, "_1")])
  A <- as.matrix(d[, paste0("pref_anom_", ints, "_1")])
  W <- ifelse(P == 1, R, -A)          # WTP for recognition (negative = WTP to stay anonymous)
  data.frame(id = rep(d$id, times = length(ints)),
             lower = rep(ints, each = nrow(d)),
             wtp = as.vector(W)) %>%
    filter(lower < 1700) %>%                         # drop the ">= 1700" interval
    mutate(mid = (lower + 50) / 100, mid2 = mid^2)   # interval midpoint in hundreds of points
}
B <- clean$berkeley
WB <- wtp_long(B)
stopifnot(!any(is.na(WB$wtp)))
m6 <- feols(wtp ~ mid + mid2, data = WB, cluster = ~id)
cat("\n---- Table 6 col (4), Berkeley quadratic ----\n"); print(coeftable(m6))

# ---- Table 7: action-signaling structural parameters, Berkeley -----------------------------
structural <- function(r, tau, a0, p = 0.50) {
  r0 <- r[1]; r1 <- r[2]; r2 <- r[3]
  abar <- a0 + tau                       # average action with public recognition (comparison population)
  g1 <- sqrt(r1^2 - 4 * r0 * r2)         # eq. (20)
  g2 <- r2                               # eq. (21)
  rho <- (g1 - r1) / (2 * abar * r2)     # eq. (22)/(24)
  cc <- (r1 + 2 * r2 * (a0 + tau)) / tau # eq. (27)
  c(gamma1 = g1, gamma2 = g2, rho = rho, c = cc, pred_fi = p / cc)
}
rB <- unname(coef(m6)[c("(Intercept)", "mid", "mid2")])
tauB <- t5$berkeley$pr / 100
a0B <- mean(B$AnomPts) / 100
est <- structural(rB, tauB, a0B)
cat("\nBerkeley inputs: r =", rB, " tau(hundreds) =", tauB, " a0(hundreds) =", a0B, "\n")
print(est)
cat("Directly estimated financial incentive effect (hundreds):", t5$berkeley$fi / 100, "\n")

# Participant-block percentile bootstrap (1000 reps) for the Table 7 Berkeley entries (diagnostic only)
LB <- to_long(B)
ids <- unique(B$id)
boot <- t(replicate(1000, {
  s <- sample(ids, length(ids), replace = TRUE)
  idx <- data.frame(id = s, bid = seq_along(s))
  Lb <- inner_join(idx, LB, by = "id", relationship = "many-to-many")
  Wb <- inner_join(idx, WB, by = "id", relationship = "many-to-many")
  Bb <- inner_join(idx, B[, c("id", "AnomPts")], by = "id", relationship = "many-to-many")
  mb5 <- lm(points ~ public + financial + factor(position), data = Lb)
  mb6 <- lm(wtp ~ mid + mid2, data = Wb)
  structural(unname(coef(mb6)), unname(coef(mb5)["public"]) / 100, mean(Bb$AnomPts) / 100)
}))
cat("\nBootstrap 95% percentile CIs (Berkeley):\n")
print(apply(boot, 2, quantile, probs = c(0.025, 0.975), na.rm = TRUE))

# ---- Results --------------------------------------------------------------------------------
out <- c(
  public_recognition_points_prolific_table5_col1   = t5$prolific$pr,
  financial_incentives_points_prolific_table5_col1 = t5$prolific$fi,
  public_recognition_points_berkeley_table5_col2   = t5$berkeley$pr,
  financial_incentives_points_berkeley_table5_col2 = t5$berkeley$fi,
  public_recognition_points_bu_table5_col3         = t5$bu$pr,
  financial_incentives_points_bu_table5_col3       = t5$bu$fi,
  n_obs_prolific_table5_col1 = t5$prolific$n,
  n_obs_berkeley_table5_col2 = t5$berkeley$n,
  n_obs_bu_table5_col3       = t5$bu$n,
  action_signaling_gamma1_berkeley_table7_panelA = unname(est["gamma1"]),
  action_signaling_rho_berkeley_table7_panelA    = unname(est["rho"]),
  cost_parameter_c_berkeley_table7_panelA        = unname(est["c"]),
  predicted_financial_incentive_effect_berkeley_table7_panelC = unname(est["pred_fi"])
)
cat("\n")
for (k in names(out)) cat(sprintf("RESULT:%s=%.6g\n", k, out[[k]]))
