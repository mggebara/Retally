# Butera et al. (2022) "Measuring the Welfare Effects of Shame and Pride"
# Reproduces Table 5 (cols 1-3) and Table 7 panel (a)/(c) Berkeley full-sample
# point estimates, following the authors' Stata scripts:
#   Build/University_Build.do, Prolific_Build.do, Gen_Vars.do, Label_Rounds.do,
#   Analysis/Code/charity_reduced_form_analysis.do (Table 5),
#   Analysis/Code/welfare_estimates.do (Table 7, param_effort program).
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(fixest)
})
set.seed(42)

root <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride"
raw  <- file.path(root, "Packet", "Raw Data")

# ---------------------------------------------------------------- build ----
build_one <- function(file) {
  d <- read_csv(file.path(raw, file), col_types = cols(.default = col_character()),
                progress = FALSE)
  names(d) <- tolower(names(d))
  num <- function(x) suppressWarnings(as.numeric(x))
  out <- data.frame(
    sample = d$sample,
    flag_attention_check = as.integer(!is.na(d$attention_check) & d$attention_check != ""),
    anompts = num(d$anompts), recogpts = num(d$recogpts), earnpts = num(d$earnpts),
    condition = d$condition, stringsAsFactors = FALSE)
  # preferences & switches (Gen_Vars.do)
  pref <- sapply(seq(0, 1700, 100), function(j) num(d[[paste0("preference_", j)]]))
  sw <- rep(0, nrow(d))
  for (k in 2:18) sw <- sw + as.integer((pref[, k] != pref[, k - 1]) %in% TRUE |
                                        xor(is.na(pref[, k]), is.na(pref[, k - 1])))
  consistent <- (sw == 0) | (sw == 1 & pref[, 1] == 0)
  consistent_b <- consistent | (sw == 2 & pref[, 1] == 0)
  out$consistent_b <- as.integer(consistent_b %in% TRUE)
  # WTP: minus anonymous-slider value, else recognition-slider value
  for (i in 0:17) {
    j <- i * 100
    a <- -num(d[[paste0("pref_anom_", j, "_1")]])
    r <- num(d[[paste0("pref_rec_", j, "_1")]])
    out[[paste0("wtp", i)]] <- ifelse(is.na(a), r, a)
  }
  out
}

dat <- bind_rows(build_one("prolific_survey_data.csv"),
                 build_one("berkeley_survey_data.csv"),
                 build_one("bu_qm221_survey_data.csv"),
                 build_one("bu_qm222_survey_data.csv"))
dat$id <- seq_len(nrow(dat))           # unique participant id (clusters)
dat <- dat %>% filter(sample != "BU QM221")   # QM221 never enters Tables 5/7

# Stata: `x > 3000` is TRUE for missing x
over <- function(x) is.na(x) | x > 3000
dat$high_pts <- as.integer(over(dat$anompts) | over(dat$recogpts) | over(dat$earnpts))

# round-level long data (Label_Rounds.do)
ord_tab <- data.frame(
  condition = rep(c("AER", "ARE", "EAR", "ERA", "RAE", "REA"), each = 3),
  round = rep(c("anom", "recog", "earn"), 6),
  order = c(1, 2, 3,  1, 3, 2,  2, 1, 3,  3, 1, 2,  2, 3, 1,  3, 2, 1))
long_pts <- function(d) {
  d %>% select(id, sample, flag_attention_check, consistent_b, condition,
               anom = anompts, recog = recogpts, earn = earnpts) %>%
    pivot_longer(c(anom, recog, earn), names_to = "round", values_to = "pts") %>%
    left_join(ord_tab, by = c("condition", "round")) %>%
    mutate(SR = as.integer(round == "recog"), ownpay = as.integer(round == "earn"),
           o1 = as.integer(order == 1), o2 = as.integer(order == 2),
           pts00 = pts / 100)
}

# ---------------------------------------------------------- Table 5 -------
# charity_reduced_form_analysis.do drops high_pts before the regressions
t5 <- long_pts(dat %>% filter(high_pts == 0)) %>%
  filter(flag_attention_check == 0, consistent_b == 1)
tab5 <- list()
for (s in c("Prolific", "Berkeley", "BU")) {
  m <- feols(pts ~ SR + ownpay + o1 + o2, data = t5 %>% filter(sample == s),
             cluster = ~id)
  tab5[[s]] <- m
  cat(sprintf("Table5 %-9s SR=%.2f (%.2f) ownpay=%.2f (%.2f) N=%d clusters=%d\n", s,
              coef(m)["SR"], se(m)["SR"], coef(m)["ownpay"], se(m)["ownpay"],
              nobs(m), length(unique(t5$id[t5$sample == s]))))
}

# ---------------------------------------------------------- Table 7 -------
# welfare_estimates.do, param_effort for Berkeley (no high_pts drop there;
# none of the Berkeley participants exceeds 3000 points anyway).
param_effort <- function(d, inc) {
  dd <- d %>% filter(flag_attention_check == 0, consistent_b == 1)
  lp <- long_pts(dd)
  m1 <- feols(pts00 ~ SR + ownpay + o1 + o2, data = lp, cluster = ~id)
  tau <- unname(coef(m1)["SR"]); fin_act <- unname(coef(m1)["ownpay"])
  pts_noim <- mean(lp$pts00[lp$round == "anom"], na.rm = TRUE)
  pts_im <- pts_noim + tau
  # WTP on interval midpoint (hundreds) and its square, 1700+ excluded
  w <- dd %>% select(id, starts_with("wtp")) %>%
    pivot_longer(starts_with("wtp"), names_to = "k", values_to = "wtp") %>%
    mutate(interval = as.numeric(sub("wtp", "", k)) + 0.5,
           interval2 = interval^2) %>% filter(interval < 17)
  m2 <- feols(wtp ~ interval + interval2, data = w, cluster = ~id)
  r0 <- unname(coef(m2)[1]); r1 <- unname(coef(m2)["interval"])
  r2 <- unname(coef(m2)["interval2"])
  gamma2 <- r2
  gamma1 <- sqrt(r1^2 - 4 * gamma2 * r0)
  rho <- (gamma1 - r1) / (2 * gamma2 * pts_im)
  c <- (r1 + 2 * r2 * pts_im) / tau
  fin_inc <- inc / c
  list(tau = tau, fin_act = fin_act, pts_noim = pts_noim, pts_im = pts_im,
       r0 = r0, r1 = r1, r2 = r2, gamma1 = gamma1, gamma2 = gamma2, rho = rho,
       c = c, fin_inc = fin_inc, diff_fin = fin_inc - fin_act)
}
pb <- param_effort(dat %>% filter(sample == "Berkeley"), inc = 0.5)
cat("Table7 Berkeley:", paste(names(pb), signif(unlist(pb), 5), sep = "=", collapse = " "), "\n")

# ---------------------------------------------------------- RESULTS -------
res <- c(
  public_recognition_points_prolific_table5_col1 = coef(tab5$Prolific)[["SR"]],
  financial_incentives_points_prolific_table5_col1 = coef(tab5$Prolific)[["ownpay"]],
  public_recognition_points_berkeley_table5_col2 = coef(tab5$Berkeley)[["SR"]],
  financial_incentives_points_berkeley_table5_col2 = coef(tab5$Berkeley)[["ownpay"]],
  public_recognition_points_bu_table5_col3 = coef(tab5$BU)[["SR"]],
  financial_incentives_points_bu_table5_col3 = coef(tab5$BU)[["ownpay"]],
  n_obs_prolific_table5_col1 = nobs(tab5$Prolific),
  n_obs_berkeley_table5_col2 = nobs(tab5$Berkeley),
  n_obs_bu_table5_col3 = nobs(tab5$BU),
  action_signaling_gamma1_berkeley_table7_panelA = pb$gamma1,
  action_signaling_rho_berkeley_table7_panelA = pb$rho,
  cost_parameter_c_berkeley_table7_panelA = pb$c,
  predicted_financial_incentive_effect_berkeley_table7_panelC = pb$fin_inc)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
