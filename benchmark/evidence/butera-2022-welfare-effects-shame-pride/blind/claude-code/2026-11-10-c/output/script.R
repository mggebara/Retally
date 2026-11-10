# Butera, Metcalfe, Morrison & Taubinsky -- "Measuring the Welfare Effects of Shame and Pride"
# Independent, blind reproduction of Table 5 cols (1)-(3) and the Berkeley rows of
# Table 7 panels (a) and (c) (action-signaling model), from the raw survey CSVs.
set.seed(42)
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-c/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)

# --- Coherence classification (Sections 4.1 / 6.1). Applied to the yes/no preference for
# public recognition across the 18 performance intervals: coherent = (weakly) increasing in
# performance (incl. constant) or single-peaked (no -> yes -> no, "wanting to look average").
# Decreasing, U-shaped and multiple-switch patterns are "incoherent".  (This rule reproduces
# the exclusion counts stated in the paper's notes: 40 Prolific, 11 Berkeley, 2 BU, and the
# 1.0/1.8/1.7% non-monotone-coherent shares in Section 6.1.)
classify <- function(w) {
  s <- sign(diff(w)); s <- s[s != 0]
  if (length(s) == 0) return("flat")
  if (all(s > 0)) return("inc")
  if (all(s < 0)) return("dec")
  ch <- sum(diff(s) != 0)
  if (ch == 1 && s[1] > 0) return("peak")
  if (ch == 1 && s[1] < 0) return("valley")
  paste0("multi", ch)
}
coherent_classes <- c("flat", "inc", "peak")

load_sample <- function(file) {
  x <- read_csv(file.path(D, file), show_col_types = FALSE, guess_max = 5000)
  # signed WTP for public recognition: + WTP to be recognised, - WTP to stay anonymous
  W <- sapply(lv, function(l) {
    p <- x[[paste0("preference_", l)]]
    ifelse(p == 1, x[[paste0("pref_rec_", l, "_1")]], -x[[paste0("pref_anom_", l, "_1")]])
  })
  colnames(W) <- paste0("w", lv)
  P <- as.matrix(x[paste0("preference_", lv)])
  cls <- apply(P, 1, function(w) if (any(is.na(w))) "NA" else classify(w))
  stopifnot(!any(is.na(W)))
  x$attn_pass <- is.na(x$attention_check)
  x$coherent <- cls %in% coherent_classes
  x <- bind_cols(x, as_tibble(W))
  cat(sprintf("%s: n=%d, fail attention=%d, incoherent among attention-passers=%d\n",
              file, nrow(x), sum(!x$attn_pass), sum(x$attn_pass & !x$coherent)))
  filter(x, attn_pass, coherent)
}

# --- Table 5: points on round indicators + round-order dummies, clustered by participant
round_panel <- function(x) {
  x %>% select(id, Condition, AnomPts, EarnPts, RecogPts) %>%
    pivot_longer(c(AnomPts, EarnPts, RecogPts), names_to = "round", values_to = "points") %>%
    mutate(letter = c(AnomPts = "A", EarnPts = "E", RecogPts = "R")[round],
           position = mapply(function(cond, l) regexpr(l, cond)[1], Condition, letter),
           recog = as.integer(letter == "R"), fin = as.integer(letter == "E"))
}
table5 <- function(x) {
  p <- round_panel(x)
  stopifnot(all(p$position %in% 1:3))
  feols(points ~ recog + fin + i(position, ref = 1), data = p, cluster = ~id)
}

samples <- list(
  prolific = load_sample("prolific_survey_data.csv"),
  berkeley = load_sample("berkeley_survey_data.csv"),
  bu       = load_sample("bu_qm222_survey_data.csv")   # BU = QM222 classroom (121 completers)
)
m5 <- lapply(samples, table5)
for (s in names(m5)) { cat("\n== Table 5,", s, "\n"); print(summary(m5[[s]])) }

# --- Table 6 col (4): Berkeley WTP on midpoint (hundreds of points) and its square, 1700+ excluded
bk <- samples$berkeley
wl <- bk %>% select(id, all_of(paste0("w", lv[lv < 1700]))) %>%
  pivot_longer(-id, names_to = "int", values_to = "wtp") %>%
  mutate(a = (as.numeric(sub("w", "", int)) + 50) / 100)
m6 <- feols(wtp ~ a + I(a^2), data = wl, cluster = ~id)
cat("\n== Table 6 col (4), Berkeley\n"); print(summary(m6))
r <- unname(coef(m6)); r0 <- r[1]; r1 <- r[2]; r2 <- r[3]

# --- Table 7, action-signaling model (Appendix F.1), effort in hundreds of points
a0  <- mean(bk$AnomPts) / 100                   # E[a | PR = 0], anonymous round
tau <- unname(coef(m5$berkeley)["recog"]) / 100 # public recognition effect, Table 5 col (2)
abar_pr <- a0 + tau                             # average performance with public recognition
gamma1 <- sqrt(r1^2 - 4 * r0 * r2)              # eq. (20)
gamma2 <- r2                                    # eq. (21)
rho <- (sqrt(r1^2 - 4 * gamma2 * r0) - r1) / (2 * abar_pr * r2)  # eq. (22)
cc  <- (r1 + 2 * r2 * (a0 + tau)) / tau         # eq. (27)
p   <- 0.05 * 10                                # 5 cents / 10 points = $0.50 per hundred points
pred_fin <- p / cc
cat(sprintf("\nBerkeley: r0=%.4f r1=%.4f r2=%.4f a0=%.4f tau=%.4f gamma1=%.4f gamma2=%.4f rho=%.4f c=%.4f p/c=%.4f\n",
            r0, r1, r2, a0, tau, gamma1, gamma2, rho, cc, pred_fin))

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.6f\n", coef(m5$prolific)["recog"]))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.6f\n", coef(m5$prolific)["fin"]))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.6f\n", coef(m5$berkeley)["recog"]))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.6f\n", coef(m5$berkeley)["fin"]))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.6f\n", coef(m5$bu)["recog"]))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.6f\n", coef(m5$bu)["fin"]))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", nobs(m5$prolific)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", nobs(m5$berkeley)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", nobs(m5$bu)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.6f\n", gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.6f\n", rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.6f\n", cc))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.6f\n", pred_fin))
