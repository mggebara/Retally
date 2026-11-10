# Retally reproduction: butera-2022-welfare-effects-shame-pride (seeded)
# Table 5 (points on public recognition / financial incentive round dummies,
# round-order dummies, participant-clustered SEs) and Table 7 panel (a)/(c)
# Berkeley structural parameters, following charity_reduced_form_analysis.do
# and welfare_estimates.do (full-sample point estimates; no bootstrap CIs).
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(fixest)
})
set.seed(42)

raw <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"

# ---- Build (University_Build / Prolific_Build / Gen_Vars) ----
build_one <- function(f) {
  d <- read_csv(file.path(raw, f), col_types = cols(.default = col_character()),
                na = c("", "NA"))
  names(d) <- tolower(names(d))
  num <- function(x) suppressWarnings(as.numeric(x))
  d$flag_attention_check <- as.integer(!is.na(d$attention_check))
  pv <- paste0("preference_", seq(0, 1700, 100))
  P <- sapply(pv, function(v) num(d[[v]]))
  # Stata: missing != value counts as a switch; missing == missing does not
  neq <- function(a, b) ifelse(is.na(a) & is.na(b), FALSE,
                        ifelse(is.na(a) | is.na(b), TRUE, a != b))
  sw <- rep(0, nrow(d))
  for (k in 2:ncol(P)) sw <- sw + neq(P[, k - 1], P[, k])
  p0 <- P[, 1]
  consistent <- (sw == 0) | (sw == 1 & !is.na(p0) & p0 == 0)
  consistent_b <- consistent | (sw == 2 & !is.na(p0) & p0 == 0)
  d$consistent_b <- as.integer(consistent_b)
  for (i in 0:17) {
    j <- i * 100
    w <- -1 * num(d[[paste0("pref_anom_", j, "_1")]])
    rec <- num(d[[paste0("pref_rec_", j, "_1")]])
    w[is.na(w)] <- rec[is.na(w)]
    d[[paste0("wtp", i)]] <- w
  }
  out <- data.frame(
    sample = d$sample, flag_attention_check = d$flag_attention_check,
    consistent_b = d$consistent_b, condition = d$condition,
    anompts = num(d$anompts), recogpts = num(d$recogpts), earnpts = num(d$earnpts),
    stringsAsFactors = FALSE)
  cbind(out, as.data.frame(d[, paste0("wtp", 0:17)]))
}
dat <- bind_rows(lapply(c("prolific_survey_data.csv", "berkeley_survey_data.csv",
                          "bu_qm221_survey_data.csv", "bu_qm222_survey_data.csv"),
                        build_one))
dat$id <- seq_len(nrow(dat))
cat("Raw N by sample:\n"); print(table(dat$sample))

# ---- Long by round, order dummies (Label_Rounds.do) ----
to_long <- function(d) {
  l <- d %>% select(id, sample, flag_attention_check, consistent_b, condition,
                    anompts, recogpts, earnpts) %>%
    pivot_longer(c(anompts, recogpts, earnpts), names_to = "round", values_to = "pts") %>%
    mutate(round = sub("pts$", "", round))
  ord <- c(
    "anom.AER" = 1, "recog.AER" = 2, "earn.AER" = 3,
    "anom.ARE" = 1, "recog.ARE" = 3, "earn.ARE" = 2,
    "anom.EAR" = 2, "recog.EAR" = 1, "earn.EAR" = 3,
    "anom.ERA" = 3, "recog.ERA" = 1, "earn.ERA" = 2,
    "anom.RAE" = 2, "recog.RAE" = 3, "earn.RAE" = 1,
    "anom.REA" = 3, "recog.REA" = 2, "earn.REA" = 1)
  l$order <- unname(ord[paste(l$round, l$condition, sep = ".")])
  l %>% mutate(SR = as.integer(round == "recog"), ownpay = as.integer(round == "earn"),
               o1 = as.integer(order == 1), o2 = as.integer(order == 2))
}

# ---- Table 5 (charity_reduced_form_analysis.do): drop high_pts first ----
high <- with(dat, (anompts > 3000) | (earnpts > 3000) | (recogpts > 3000))
high[is.na(high)] <- FALSE
d5 <- dat[!high, ]
L5 <- to_long(d5)
t5 <- list()
for (s in c("Prolific", "Berkeley", "BU")) {
  sub <- L5 %>% filter(sample == s, flag_attention_check == 0, consistent_b == 1)
  m <- feols(pts ~ SR + ownpay + o1 + o2, data = sub, cluster = ~id)
  t5[[s]] <- list(b = coef(m), n = nobs(m))
  cat("\nTable 5,", s, "\n"); print(coeftable(m))
}

# ---- Table 7 (welfare_estimates.do, section II): Berkeley ----
# welfare_estimates.do uses charity_cleaned_data without the high_pts drop
dw <- dat[dat$sample != "BU QM221", ]
Lw <- to_long(dw) %>% mutate(pts00 = pts / 100)
param_effort <- function(s, inc) {
  ss <- Lw %>% filter(sample == s, flag_attention_check == 0, consistent_b == 1)
  m1 <- feols(pts00 ~ SR + ownpay + o1 + o2, data = ss, cluster = ~id)
  tau <- unname(coef(m1)["SR"]); fin_act <- unname(coef(m1)["ownpay"])
  pts_noim <- mean(ss$pts00[ss$round == "anom"], na.rm = TRUE)
  pts_im <- pts_noim + tau
  # WTP regression: data long by (id, round, interval) as in the do-file
  wl <- ss %>% left_join(dw %>% select(id, starts_with("wtp")), by = "id") %>%
    pivot_longer(starts_with("wtp"), names_to = "int_no", values_to = "wtp") %>%
    mutate(int_no = as.integer(sub("wtp", "", int_no)),
           interval = int_no + 0.5, interval2 = interval^2) %>%
    filter(interval < 17)
  m2 <- feols(wtp ~ interval + interval2, data = wl, cluster = ~id)
  r0 <- unname(coef(m2)[1]); r1 <- unname(coef(m2)["interval"]); r2 <- unname(coef(m2)["interval2"])
  gamma2 <- r2
  gamma1 <- sqrt(r1^2 - 4 * gamma2 * r0)
  rho <- (gamma1 - r1) / (2 * gamma2 * pts_im)
  c_par <- (r1 + 2 * r2 * pts_im) / tau
  fin_inc <- inc / c_par
  cat("\nStructural", s, ": tau", tau, "fin_act", fin_act, "pts_noim", pts_noim,
      "r0", r0, "r1", r1, "r2", r2, "N wtp", nobs(m2), "\n")
  list(gamma1 = gamma1, gamma2 = gamma2, rho = rho, c = c_par, fin_inc = fin_inc,
       fin_act = fin_act)
}
sb <- param_effort("Berkeley", 0.5)
print(unlist(sb))

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.6f\n", t5$Prolific$b["SR"]))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.6f\n", t5$Prolific$b["ownpay"]))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.6f\n", t5$Berkeley$b["SR"]))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.6f\n", t5$Berkeley$b["ownpay"]))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.6f\n", t5$BU$b["SR"]))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.6f\n", t5$BU$b["ownpay"]))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", t5$Prolific$n))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", t5$Berkeley$n))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", t5$BU$n))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.6f\n", sb$gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.6f\n", sb$rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.6f\n", sb$c))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.6f\n", sb$fin_inc))
