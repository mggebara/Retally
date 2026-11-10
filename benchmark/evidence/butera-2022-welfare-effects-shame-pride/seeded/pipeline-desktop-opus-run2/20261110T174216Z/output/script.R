suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride"
raw_dir <- file.path(base_dir, "Packet", "Raw Data")

files <- c(
  "Prolific" = "prolific_survey_data.csv",
  "Berkeley" = "berkeley_survey_data.csv",
  "BU QM221" = "bu_qm221_survey_data.csv",
  "BU"       = "bu_qm222_survey_data.csv"
)

num <- function(x) suppressWarnings(as.numeric(as.character(x)))

# Stata-style inequality: missing == missing, missing != non-missing
neq <- function(a, b) {
  out <- a != b
  out[is.na(a) & is.na(b)] <- FALSE
  out[xor(is.na(a), is.na(b))] <- TRUE
  out
}

getcol <- function(d, nm) {
  if (nm %in% names(d)) d[[nm]] else rep(NA_character_, nrow(d))
}

# ---------------------------------------------------------------------------
# Build (Prolific_Build / University_Build / Gen_Vars)
# ---------------------------------------------------------------------------
build_one <- function(path, s) {
  d <- read_csv(path, col_types = cols(.default = col_character()),
                progress = FALSE, na = c("", "NA", "."))
  names(d) <- tolower(trimws(names(d)))
  n <- nrow(d)

  ac <- getcol(d, "attention_check")
  flag <- as.integer(!(is.na(ac) | trimws(ac) == ""))

  # preferences
  P <- sapply(0:17, function(i) num(getcol(d, paste0("preference_", i * 100))))
  if (is.null(dim(P))) P <- matrix(P, nrow = n)
  sw <- rep(0, n)
  for (i in 2:18) sw <- sw + as.integer(neq(P[, i - 1], P[, i]))
  p0zero <- !is.na(P[, 1]) & P[, 1] == 0
  consistent <- (sw == 0) | (sw == 1 & p0zero)
  consistent_b <- consistent | (sw == 2 & p0zero)

  out <- data.frame(
    sample = s,
    flag_attention_check = flag,
    consistent_b = as.integer(consistent_b),
    anompts = num(getcol(d, "anompts")),
    recogpts = num(getcol(d, "recogpts")),
    earnpts = num(getcol(d, "earnpts")),
    condition = toupper(trimws(getcol(d, "condition"))),
    stringsAsFactors = FALSE
  )

  # WTPs: anonymous WTPs negative, fill in recognition WTPs where missing
  for (i in 0:17) {
    j <- i * 100
    a <- num(getcol(d, paste0("pref_anom_", j, "_1")))
    r <- num(getcol(d, paste0("pref_rec_", j, "_1")))
    w <- -1 * a
    w[is.na(w)] <- r[is.na(w)]
    out[[paste0("wtp", i)]] <- w
  }
  out
}

dat <- bind_rows(lapply(names(files), function(s) build_one(file.path(raw_dir, files[[s]]), s)))
dat$id <- seq_len(nrow(dat))

# ---------------------------------------------------------------------------
# Round order (Label_Rounds.do)
# ---------------------------------------------------------------------------
order_map <- list(
  AER = c(anom = 1, recog = 2, earn = 3),
  ARE = c(anom = 1, recog = 3, earn = 2),
  EAR = c(anom = 2, recog = 1, earn = 3),
  ERA = c(anom = 3, recog = 1, earn = 2),
  RAE = c(anom = 2, recog = 3, earn = 1),
  REA = c(anom = 3, recog = 2, earn = 1)
)

make_round_long <- function(d) {
  long <- d %>%
    select(id, sample, flag_attention_check, consistent_b, condition,
           anom = anompts, recog = recogpts, earn = earnpts) %>%
    pivot_longer(c(anom, recog, earn), names_to = "round", values_to = "pts")
  long$order <- mapply(function(cnd, rd) {
    m <- order_map[[cnd]]
    if (is.null(m) || is.na(cnd)) NA_real_ else unname(m[rd])
  }, long$condition, long$round)
  long$SR <- as.integer(long$round == "recog")
  long$ownpay <- as.integer(long$round == "earn")
  long$o1 <- ifelse(is.na(long$order), NA, as.integer(long$order == 1))
  long$o2 <- ifelse(is.na(long$order), NA, as.integer(long$order == 2))
  long
}

# ---------------------------------------------------------------------------
# Table 5 (charity_reduced_form_analysis.do): drop disqualifying points
# (Stata: missing > 3000 evaluates true)
# ---------------------------------------------------------------------------
high_pts <- with(dat, (is.na(anompts) | anompts > 3000) |
                      (is.na(earnpts) | earnpts > 3000) |
                      (is.na(recogpts) | recogpts > 3000))
dat5 <- dat[!high_pts, ]
long5 <- make_round_long(dat5)

run_t5 <- function(s) {
  dd <- long5 %>%
    filter(sample == s, flag_attention_check == 0, consistent_b == 1,
           !is.na(pts), !is.na(o1), !is.na(o2))
  m <- feols(pts ~ SR + ownpay + o1 + o2, data = dd, cluster = ~id)
  list(b_sr = unname(coef(m)["SR"]), b_fi = unname(coef(m)["ownpay"]),
       se_sr = unname(se(m)["SR"]), se_fi = unname(se(m)["ownpay"]),
       n = nobs(m))
}

t5_pro <- run_t5("Prolific")
t5_ber <- run_t5("Berkeley")
t5_bu  <- run_t5("BU")

# ---------------------------------------------------------------------------
# Table 7 (welfare_estimates.do, param_effort) for Berkeley
# No disqualifying-points drop in that script.
# ---------------------------------------------------------------------------
longw <- make_round_long(dat) %>% mutate(pts00 = pts / 100)
berk <- longw %>% filter(sample == "Berkeley", flag_attention_check == 0, consistent_b == 1)

m_tau <- feols(pts00 ~ SR + ownpay + o1 + o2,
               data = berk %>% filter(!is.na(pts00), !is.na(o1), !is.na(o2)),
               cluster = ~id)
tau <- unname(coef(m_tau)["SR"])
fin_act <- unname(coef(m_tau)["ownpay"])

pts_noim <- mean(berk$pts00[berk$round == "anom" & !is.na(berk$pts00)])
pts_im <- pts_noim + tau

wtp_long <- dat %>%
  filter(sample == "Berkeley", flag_attention_check == 0, consistent_b == 1) %>%
  select(id, starts_with("wtp")) %>%
  pivot_longer(starts_with("wtp"), names_to = "int", values_to = "wtp") %>%
  mutate(int_no = as.numeric(sub("wtp", "", int)),
         interval = int_no + 0.5,
         interval2 = interval^2) %>%
  filter(int_no < 17, !is.na(wtp))

m_wtp <- feols(wtp ~ interval + interval2, data = wtp_long, cluster = ~id)
r0 <- unname(coef(m_wtp)["(Intercept)"])
r1 <- unname(coef(m_wtp)["interval"])
r2 <- unname(coef(m_wtp)["interval2"])

gamma2 <- r2
gamma1 <- sqrt(r1^2 - 4 * gamma2 * r0)
rho <- (gamma1 - r1) / (2 * gamma2 * pts_im)
c_par <- (r1 + 2 * r2 * pts_im) / tau
inc <- 0.5
fin_inc <- inc / c_par

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
emit <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

emit("public_recognition_points_prolific_table5_col1", t5_pro$b_sr)
emit("financial_incentives_points_prolific_table5_col1", t5_pro$b_fi)
emit("public_recognition_points_berkeley_table5_col2", t5_ber$b_sr)
emit("financial_incentives_points_berkeley_table5_col2", t5_ber$b_fi)
emit("public_recognition_points_bu_table5_col3", t5_bu$b_sr)
emit("financial_incentives_points_bu_table5_col3", t5_bu$b_fi)
emit("n_obs_prolific_table5_col1", t5_pro$n)
emit("n_obs_berkeley_table5_col2", t5_ber$n)
emit("n_obs_bu_table5_col3", t5_bu$n)
emit("action_signaling_gamma1_berkeley_table7_panelA", gamma1)
emit("action_signaling_rho_berkeley_table7_panelA", rho)
emit("cost_parameter_c_berkeley_table7_panelA", c_par)
emit("predicted_financial_incentive_effect_berkeley_table7_panelC", fin_inc)