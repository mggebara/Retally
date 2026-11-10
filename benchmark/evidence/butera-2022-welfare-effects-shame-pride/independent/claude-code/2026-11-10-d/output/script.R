## Independent reproduction: Butera, Metcalfe, Morrison & Taubinsky (2022)
## "Measuring the Welfare Effects of Shame and Pride" -- Table 5 (cols 1-3) and
## Table 7 Berkeley action-signaling estimates, built from the paper text only.
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(fixest)
})
set.seed(42)

D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(Prolific = "prolific_survey_data.csv",
           Berkeley = "berkeley_survey_data.csv",
           BU       = "bu_qm222_survey_data.csv")   # main BU sample (QM221 is an appendix sample)
lev <- seq(0, 1700, 100)   # lower bounds of the 18 performance intervals

load_sample <- function(s) {
  x <- read_csv(file.path(D, files[[s]]), show_col_types = FALSE)
  P <- as.matrix(x[, paste0("preference_", lev)])            # 1 = wants recognition
  R <- as.matrix(x[, paste0("pref_rec_", lev, "_1")])         # WTP for recognition
  A <- as.matrix(x[, paste0("pref_anom_", lev, "_1")])        # WTP to avoid recognition
  W <- ifelse(P == 1, R, -A)                                  # signed WTP
  pass <- is.na(x$attention_check)                            # missing = passed
  ## Coherence, defined on the yes/no recognition preferences across the 18 intervals:
  ## coherent = monotonically increasing (0...01...1, incl. constant) or single-peaked
  ## with an interior peak (0..01..10..0, "wanting to look average").  Profiles that switch
  ## more often, or that want recognition only for low scores (1..10..0), are incoherent.
  ps <- apply(P, 1, paste, collapse = "")
  coherent <- grepl("^0*1*$", ps) | grepl("^0+1+0+$", ps)
  ## implausible scores (> 3000 points in a round; only in Prolific) treated as invalid
  valid <- pmax(x$AnomPts, x$EarnPts, x$RecogPts) <= 3000
  keep <- pass & coherent & valid
  cat(sprintf("%s: n=%d, failed attention=%d, incoherent (all rows)=%d, implausible scores=%d, final=%d\n",
              s, nrow(x), sum(!pass), sum(!coherent), sum(!valid), sum(keep)))
  colnames(W) <- paste0("w_", lev)
  list(x = x[keep, ], W = W[keep, , drop = FALSE])
}

S <- lapply(names(files), load_sample); names(S) <- names(files)

## ---------------- Table 5: points on round type with round-order dummies ----------------
points_long <- function(x) {
  base <- x %>% transmute(id = row_number(), Condition, A = AnomPts, R = RecogPts, E = EarnPts)
  base %>% pivot_longer(c(A, R, E), names_to = "round", values_to = "points") %>%
    mutate(order = mapply(function(cnd, r) regexpr(r, cnd)[1], Condition, round),
           pr = as.integer(round == "R"), fin = as.integer(round == "E"))
}
t5 <- list()
for (s in names(S)) {
  d <- points_long(S[[s]]$x)
  stopifnot(all(d$order %in% 1:3))
  m <- feols(points ~ pr + fin + i(order, ref = 1), data = d, cluster = ~id)
  t5[[s]] <- list(m = m, d = d)
  cat(sprintf("Table 5 %s: PR=%.2f (%.2f) FIN=%.2f (%.2f) N=%d, control mean=%.1f\n", s,
              coef(m)["pr"], se(m)["pr"], coef(m)["fin"], se(m)["fin"], nobs(m),
              mean(d$points[d$round == "A"])))
}

## ---------------- Table 6 col (4): Berkeley quadratic PRU ----------------
wtp_long <- function(W) {
  as.data.frame(W) %>% mutate(id = row_number()) %>%
    pivot_longer(-id, names_to = "lev", values_to = "wtp") %>%
    mutate(lev = as.numeric(sub("w_", "", lev))) %>%
    filter(lev < 1700) %>%                       # drop the open ">=1700" interval
    mutate(a = (lev + 50) / 100, a2 = a^2)       # interval midpoint in hundreds of points
}
wb <- wtp_long(S$Berkeley$W)
m6 <- feols(wtp ~ a + a2, data = wb, cluster = ~id)
r0 <- unname(coef(m6)[1]); r1 <- unname(coef(m6)["a"]); r2 <- unname(coef(m6)["a2"])
cat(sprintf("Table 6 col4 Berkeley: r1=%.4f r2=%.5f r0=%.4f N=%d\n", r1, r2, r0, nobs(m6)))

## ---------------- Table 7: action-signaling model, Berkeley ----------------
structural <- function(r0, r1, r2, a0, tau, p) {
  abar <- a0 + tau                                  # average performance with public recognition
  g1 <- sqrt(r1^2 - 4 * r0 * r2)                    # eq. (20)
  g2 <- r2                                          # eq. (21)
  rho <- (g1 - r1) / (2 * abar * r2)                # eq. (22)
  cc <- (r1 + 2 * r2 * (a0 + tau)) / tau            # eq. (27)
  c(gamma1 = g1, gamma2 = g2, rho = rho, c = cc, pred = p / cc)
}
db <- t5$Berkeley$d
a0 <- mean(db$points[db$round == "A"]) / 100
tau <- unname(coef(t5$Berkeley$m)["pr"]) / 100
p_berk <- 0.05 * 10                                 # 5 cents per 10 points = $0.50 per 100 points
est <- structural(r0, r1, r2, a0, tau, p_berk)
cat(sprintf("Berkeley a0=%.3f tau=%.3f -> gamma1=%.3f gamma2=%.4f rho=%.3f c=%.3f pred=%.3f\n",
            a0, tau, est["gamma1"], est["gamma2"], est["rho"], est["c"], est["pred"]))

## participant-block percentile bootstrap (informational only)
B <- 200
nb <- nrow(S$Berkeley$x)
bs <- t(replicate(B, {
  ids <- sample.int(nb, nb, replace = TRUE)
  map <- data.frame(id = ids, bid = seq_along(ids))
  d5 <- inner_join(map, db, by = "id", relationship = "many-to-many")
  d6 <- inner_join(map, wb, by = "id", relationship = "many-to-many")
  mm5 <- feols(points ~ pr + fin + i(order, ref = 1), data = d5, vcov = "iid")
  mm6 <- feols(wtp ~ a + a2, data = d6, vcov = "iid")
  structural(unname(coef(mm6)[1]), unname(coef(mm6)["a"]), unname(coef(mm6)["a2"]),
             mean(d5$points[d5$round == "A"]) / 100, unname(coef(mm5)["pr"]) / 100, p_berk)
}))
ci <- apply(bs, 2, quantile, c(0.025, 0.975), na.rm = TRUE)
cat("Bootstrap 95% CIs (", B, " reps):\n"); print(round(ci, 3))

## ---------------- results ----------------
cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.4f\n", coef(t5$Prolific$m)["pr"]))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.4f\n", coef(t5$Prolific$m)["fin"]))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.4f\n", coef(t5$Berkeley$m)["pr"]))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.4f\n", coef(t5$Berkeley$m)["fin"]))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.4f\n", coef(t5$BU$m)["pr"]))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.4f\n", coef(t5$BU$m)["fin"]))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", nobs(t5$Prolific$m)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", nobs(t5$Berkeley$m)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", nobs(t5$BU$m)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.4f\n", est["gamma1"]))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.4f\n", est["rho"]))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.4f\n", est["c"]))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.4f\n", est["pred"]))
