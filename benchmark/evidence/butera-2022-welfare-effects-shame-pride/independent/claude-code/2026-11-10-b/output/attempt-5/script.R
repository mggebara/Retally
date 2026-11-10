# Independent reproduction: Butera, Metcalfe, Morrison & Taubinsky,
# "Measuring the Welfare Effects of Shame and Pride" -- Table 5 (cols 1-3),
# Table 6 col 4 (reduced-form PRU, Berkeley) feeding Table 7 panels (a) and (c) for Berkeley.
suppressMessages({library(readr); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)

base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)   # lower bounds of the 18 WTP intervals (last = 1700+)

mono_inc <- function(x) all(diff(x) >= 0)
mono_dec <- function(x) all(diff(x) <= 0)
single_peak <- function(x) {
  for (k in seq_along(x)) if (mono_inc(x[1:k]) && mono_dec(x[k:length(x)])) return(TRUE)
  FALSE
}

load_sample <- function(file) {
  d <- suppressWarnings(read_csv(file.path(base, file), show_col_types = FALSE, guess_max = 5000))
  P  <- as.matrix(d[paste0("preference_", lv)])                 # 1 = wants public recognition
  R1 <- as.matrix(d[paste0("pref_rec_", lv, "_1")])             # WTP for recognition (budget-limited)
  A1 <- as.matrix(d[paste0("pref_anom_", lv, "_1")])            # WTP to avoid recognition
  W  <- ifelse(P == 1, R1, -A1)                                  # signed WTP for public recognition
  # Coherence (YMCA-analogous): monotonically increasing preference for recognition,
  # or (signed WTP) monotonically decreasing, or single-peaked; a flat all-zero WTP
  # profile with a switching preference has no discernible relation to performance.
  p_inc <- apply(P, 1, mono_inc)
  w_ok  <- apply(W, 1, function(x) length(unique(x)) > 1 && (mono_dec(x) || single_peak(x)))
  coherent <- p_inc | w_ok
  attn_pass <- is.na(d$attention_check)
  keep <- attn_pass & coherent
  list(d = d[keep, ], W = W[keep, , drop = FALSE],
       n_all = nrow(d), n_attn_fail = sum(!attn_pass), n_incoh = sum(attn_pass & !coherent))
}

samples <- list(prolific = "prolific_survey_data.csv",
                berkeley = "berkeley_survey_data.csv",
                bu       = "bu_qm222_survey_data.csv")   # BU = QM222 classroom (121 completers)

# ---------------- Table 5: points on round type with round-order dummies ----------------
t5 <- list(); S <- list()
for (s in names(samples)) {
  S[[s]] <- load_sample(samples[[s]])
  d <- S[[s]]$d
  cat(sprintf("%s: completed %d, failed attention %d, incoherent %d, final %d\n",
              s, S[[s]]$n_all, S[[s]]$n_attn_fail, S[[s]]$n_incoh, nrow(d)))
  long <- d %>% select(id, Condition, AnomPts, RecogPts, EarnPts) %>%
    pivot_longer(c(AnomPts, RecogPts, EarnPts), names_to = "round", values_to = "points") %>%
    mutate(code = c(AnomPts = "A", RecogPts = "R", EarnPts = "E")[round],
           order = mapply(function(cond, cd) regexpr(cd, cond, fixed = TRUE)[1], Condition, code),
           pr = as.integer(code == "R"), fi = as.integer(code == "E"))
  m <- feols(points ~ pr + fi + i(order, ref = 1), data = long, cluster = ~id)
  cat("\n---", s, "Table 5 ---\n"); print(coeftable(m))
  cat("control mean (anonymous):", mean(d$AnomPts), "\n")
  t5[[s]] <- list(pr = unname(coef(m)["pr"]), fi = unname(coef(m)["fi"]), n = nobs(m),
                  a0 = mean(d$AnomPts) / 100)
}

# ---------------- Table 6 col 4: Berkeley quadratic PRU (excluding 1700+) ----------------
db <- S$berkeley
wl <- data.frame(id = rep(db$d$id, each = 17),
                 a  = rep((lv[1:17] + 50) / 100, times = nrow(db$d)),   # midpoint, hundreds of points
                 wtp = as.vector(t(db$W[, 1:17])))
m6 <- feols(wtp ~ a + I(a^2), data = wl, cluster = ~id)
cat("\n--- Berkeley Table 6 col 4 ---\n"); print(coeftable(m6)); cat("N obs:", nobs(m6), "\n")
r0 <- unname(coef(m6)[1]); r1 <- unname(coef(m6)[2]); r2 <- unname(coef(m6)[3])

# ---------------- Table 7: action-signaling structural parameters (Berkeley) ----------------
tau  <- t5$berkeley$pr / 100            # PR effect, hundreds of points
a0   <- t5$berkeley$a0                  # anonymous-round mean, hundreds of points
abar <- a0 + tau                        # average performance with public recognition
gamma1 <- sqrt(r1^2 - 4 * r0 * r2)
gamma2 <- r2
rho    <- (sqrt(r1^2 - 4 * gamma2 * r0) - r1) / (2 * abar * r2)
cpar   <- (r1 + 2 * r2 * (a0 + tau)) / tau
p      <- 0.05 * 10                     # 5 cents per 10 points = $0.50 per 100 points
pred   <- p / cpar
cat(sprintf("\nBerkeley structural: r0=%.4f r1=%.4f r2=%.5f a0=%.4f tau=%.4f gamma1=%.4f gamma2=%.5f rho=%.4f c=%.4f pred=%.4f\n",
            r0, r1, r2, a0, tau, gamma1, gamma2, rho, cpar, pred))

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.4f\n", t5$prolific$pr))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.4f\n", t5$prolific$fi))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.4f\n", t5$berkeley$pr))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.4f\n", t5$berkeley$fi))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.4f\n", t5$bu$pr))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.4f\n", t5$bu$fi))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", t5$prolific$n))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", t5$berkeley$n))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", t5$bu$n))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.4f\n", gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.4f\n", rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.4f\n", cpar))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.4f\n", pred))
