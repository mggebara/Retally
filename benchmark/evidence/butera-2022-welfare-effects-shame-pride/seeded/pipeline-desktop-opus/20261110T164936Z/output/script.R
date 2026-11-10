suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"

files <- c(
  Prolific = "prolific_survey_data.csv",
  Berkeley = "berkeley_survey_data.csv",
  BU       = "bu_qm222_survey_data.csv"
)

num <- function(x) suppressWarnings(as.numeric(x))

# Stata-style inequality: missing == missing, missing != non-missing
neq <- function(a, b) {
  out <- ifelse(is.na(a) & is.na(b), FALSE,
                ifelse(is.na(a) | is.na(b), TRUE, a != b))
  as.logical(out)
}

getcol <- function(d, nm) {
  if (nm %in% names(d)) num(d[[nm]]) else rep(NA_real_, nrow(d))
}

build_sample <- function(fname, lab) {
  d <- readr::read_csv(file.path(base_dir, fname),
                       col_types = readr::cols(.default = readr::col_character()),
                       progress = FALSE)
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  names(d) <- tolower(names(d))
  n <- nrow(d)

  out <- data.frame(cid = paste(lab, seq_len(n), sep = "_"),
                    sample = lab, stringsAsFactors = FALSE)

  # attention check flag: 1 if attention_check non-missing
  ac <- d[["attention_check"]]
  if (is.null(ac)) ac <- rep(NA_character_, n)
  ac[!is.na(ac) & trimws(ac) == ""] <- NA
  out$flag_attention_check <- as.integer(!is.na(ac))

  # preference switches & consistency
  P <- sapply(0:17, function(k) getcol(d, paste0("preference_", k * 100)))
  if (is.null(dim(P))) P <- matrix(P, nrow = n)
  sw <- rep(0, n)
  for (k in 2:18) sw <- sw + as.integer(neq(P[, k - 1], P[, k]))
  p0zero <- !is.na(P[, 1]) & P[, 1] == 0
  consistent <- (sw == 0) | (sw == 1 & p0zero)
  consistent_b <- consistent | (sw == 2 & p0zero)
  out$consistent_b <- as.integer(consistent_b)

  # WTP variables
  for (k in 0:17) {
    a <- getcol(d, paste0("pref_anom_", k * 100, "_1"))
    r <- getcol(d, paste0("pref_rec_", k * 100, "_1"))
    w <- -1 * a
    w[is.na(w)] <- r[is.na(w)]
    out[[paste0("wtp", k)]] <- w
  }

  out$anompts  <- getcol(d, "anompts")
  out$recogpts <- getcol(d, "recogpts")
  out$earnpts  <- getcol(d, "earnpts")
  cond <- d[["condition"]]
  if (is.null(cond)) cond <- rep(NA_character_, n)
  out$condition <- toupper(trimws(cond))
  out
}

dat <- bind_rows(lapply(names(files), function(s) build_sample(files[[s]], s)))

# order of rounds (Label_Rounds.do)
order_map <- list(
  AER = c(anom = 1, recog = 2, earn = 3),
  ARE = c(anom = 1, recog = 3, earn = 2),
  EAR = c(anom = 2, recog = 1, earn = 3),
  ERA = c(anom = 3, recog = 1, earn = 2),
  RAE = c(anom = 2, recog = 3, earn = 1),
  REA = c(anom = 3, recog = 2, earn = 1)
)

to_round_long <- function(df) {
  rounds <- c("anom", "earn", "recog")
  bind_rows(lapply(rounds, function(rd) {
    ord <- sapply(df$condition, function(cn) {
      if (!is.na(cn) && cn %in% names(order_map)) order_map[[cn]][[rd]] else NA_real_
    })
    data.frame(cid = df$cid, sample = df$sample,
               flag_attention_check = df$flag_attention_check,
               consistent_b = df$consistent_b,
               round = rd,
               pts = df[[paste0(rd, "pts")]],
               order = as.numeric(ord),
               stringsAsFactors = FALSE)
  })) %>%
    mutate(SR = as.integer(round == "recog"),
           ownpay = as.integer(round == "earn"),
           o1 = as.integer(order == 1),
           o2 = as.integer(order == 2))
}

# ---------------------------------------------------------------
# Table 5: drop participants with disqualifying points (> 3000;
# Stata treats missing as > 3000)
# ---------------------------------------------------------------
hp <- function(x) is.na(x) | x > 3000
high_pts <- hp(dat$anompts) | hp(dat$earnpts) | hp(dat$recogpts)
dat5 <- dat[!high_pts, ]
long5 <- to_round_long(dat5)

t5 <- list()
for (s in c("Prolific", "Berkeley", "BU")) {
  sub <- long5 %>% filter(sample == s, flag_attention_check == 0, consistent_b == 1)
  m <- feols(pts ~ SR + ownpay + o1 + o2, data = sub, cluster = ~cid)
  t5[[s]] <- list(SR = unname(coef(m)["SR"]),
                  ownpay = unname(coef(m)["ownpay"]),
                  N = nobs(m))
}

# ---------------------------------------------------------------
# Table 7 (welfare_estimates.do): Berkeley structural parameters
# (no high-points drop in that script)
# ---------------------------------------------------------------
long7 <- to_round_long(dat) %>% mutate(pts00 = pts / 100)
subB <- long7 %>% filter(sample == "Berkeley", flag_attention_check == 0, consistent_b == 1)

m_tau <- feols(pts00 ~ SR + ownpay + o1 + o2, data = subB, cluster = ~cid)
tau <- unname(coef(m_tau)["SR"])
pts_noim <- mean(subB$pts00[subB$round == "anom"], na.rm = TRUE)
pts_im <- pts_noim + tau

wB <- dat %>% filter(sample == "Berkeley", flag_attention_check == 0, consistent_b == 1)
wlong <- bind_rows(lapply(0:16, function(k) {
  data.frame(cid = wB$cid, interval = k + 0.5, wtp = wB[[paste0("wtp", k)]],
             stringsAsFactors = FALSE)
})) %>% mutate(interval2 = interval^2)

m_wtp <- feols(wtp ~ interval + interval2, data = wlong, cluster = ~cid)
r0 <- unname(coef(m_wtp)["(Intercept)"])
r1 <- unname(coef(m_wtp)["interval"])
r2 <- unname(coef(m_wtp)["interval2"])

gamma2 <- r2
gamma1 <- sqrt(r1^2 - 4 * gamma2 * r0)
rho <- (gamma1 - r1) / (2 * gamma2 * pts_im)
c_par <- (r1 + 2 * r2 * pts_im) / tau
inc <- 0.5
fin_inc <- inc / c_par

fmt <- function(x) format(x, digits = 10, scientific = FALSE)

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%s\n", fmt(t5$Prolific$SR)))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%s\n", fmt(t5$Prolific$ownpay)))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%s\n", fmt(t5$Berkeley$SR)))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%s\n", fmt(t5$Berkeley$ownpay)))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%s\n", fmt(t5$BU$SR)))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%s\n", fmt(t5$BU$ownpay)))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%s\n", fmt(t5$Prolific$N)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%s\n", fmt(t5$Berkeley$N)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%s\n", fmt(t5$BU$N)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%s\n", fmt(gamma1)))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%s\n", fmt(rho)))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%s\n", fmt(c_par)))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%s\n", fmt(fin_inc)))