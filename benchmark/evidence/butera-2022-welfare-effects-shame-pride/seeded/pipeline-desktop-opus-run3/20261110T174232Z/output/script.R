suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})

set.seed(42)

root <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride"
rawdir <- file.path(root, "Packet", "Raw Data")

files <- list(
  list(sample = "Prolific", file = "prolific_survey_data.csv"),
  list(sample = "Berkeley", file = "berkeley_survey_data.csv"),
  list(sample = "BU QM221", file = "bu_qm221_survey_data.csv"),
  list(sample = "BU",       file = "bu_qm222_survey_data.csv")
)

num <- function(x) suppressWarnings(as.numeric(as.character(x)))

# Stata-style "!=" with missing values: missing equals missing, missing differs from any number
neq <- function(a, b) {
  (is.na(a) != is.na(b)) | (!is.na(a) & !is.na(b) & a != b)
}

getcol <- function(d, nm) {
  if (nm %in% names(d)) num(d[[nm]]) else rep(NA_real_, nrow(d))
}

build_one <- function(path, sname) {
  d <- read_csv(path, col_types = cols(.default = col_character()),
                progress = FALSE, show_col_types = FALSE)
  names(d) <- tolower(names(d))
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  n <- nrow(d)

  out <- data.frame(sample = rep(sname, n), stringsAsFactors = FALSE)

  # attention check flag: 1 if attention_check non-missing
  ac <- if ("attention_check" %in% names(d)) d$attention_check else rep(NA_character_, n)
  out$flag_attention_check <- as.integer(!(is.na(ac) | trimws(ac) == ""))

  # preferences 0..1700
  pref <- do.call(cbind, lapply(0:17, function(i) getcol(d, paste0("preference_", i * 100))))
  pref <- matrix(pref, nrow = n, ncol = 18)
  sw <- rep(0, n)
  for (k in 2:18) sw <- sw + as.integer(neq(pref[, k - 1], pref[, k]))
  p0zero <- !is.na(pref[, 1]) & pref[, 1] == 0
  consistent <- (sw == 0) | (sw == 1 & p0zero)
  consistent_b <- consistent | (sw == 2 & p0zero)
  out$consistent_b <- as.integer(consistent_b)

  # WTP variables
  for (i in 0:17) {
    j <- i * 100
    a <- getcol(d, paste0("pref_anom_", j, "_1"))
    r <- getcol(d, paste0("pref_rec_", j, "_1"))
    w <- -1 * a
    miss <- is.na(w)
    w[miss] <- r[miss]
    out[[paste0("wtp", i)]] <- w
  }

  out$anompts <- getcol(d, "anompts")
  out$recogpts <- getcol(d, "recogpts")
  out$earnpts <- getcol(d, "earnpts")
  out$condition <- if ("condition" %in% names(d)) toupper(trimws(d$condition)) else rep(NA_character_, n)
  out
}

all <- bind_rows(lapply(files, function(f) build_one(file.path(rawdir, f$file), f$sample)))
all$id <- seq_len(nrow(all))

# Round-order mapping (Label_Rounds.do)
order_map <- data.frame(
  condition = rep(c("AER", "ARE", "EAR", "ERA", "RAE", "REA"), each = 3),
  round = rep(c("anom", "recog", "earn"), times = 6),
  order = c(1, 2, 3,
            1, 3, 2,
            2, 1, 3,
            3, 1, 2,
            2, 3, 1,
            3, 2, 1),
  stringsAsFactors = FALSE
)

make_long <- function(df) {
  lst <- lapply(c("anom", "recog", "earn"), function(rd) {
    data.frame(id = df$id, sample = df$sample,
               flag_attention_check = df$flag_attention_check,
               consistent_b = df$consistent_b,
               condition = df$condition,
               round = rd,
               pts = df[[paste0(rd, "pts")]],
               stringsAsFactors = FALSE)
  })
  long <- bind_rows(lst)
  long <- left_join(long, order_map, by = c("condition", "round"))
  long$SR <- as.integer(long$round == "recog")
  long$ownpay <- as.integer(long$round == "earn")
  long$o1 <- ifelse(is.na(long$order), NA, as.integer(long$order == 1))
  long$o2 <- ifelse(is.na(long$order), NA, as.integer(long$order == 2))
  long
}

fit_pts <- function(sub, yvar = "pts") {
  sub <- sub[!is.na(sub[[yvar]]), ]
  if (all(is.na(sub$o1))) {
    fml <- as.formula(paste(yvar, "~ SR + ownpay"))
  } else {
    fml <- as.formula(paste(yvar, "~ SR + ownpay + o1 + o2"))
  }
  feols(fml, data = sub, cluster = ~id)
}

# ---------------------------------------------------------------
# Table 5: drop disqualifying points (> 3000 or missing, as in Stata)
# ---------------------------------------------------------------
high <- with(all, is.na(anompts) | anompts > 3000 |
                  is.na(earnpts) | earnpts > 3000 |
                  is.na(recogpts) | recogpts > 3000)
dat5 <- all[!high, ]
long5 <- make_long(dat5)

t5 <- list()
for (s in c("Prolific", "Berkeley", "BU")) {
  sub <- long5[long5$sample == s & long5$flag_attention_check == 0 & long5$consistent_b == 1, ]
  t5[[s]] <- fit_pts(sub)
}

# ---------------------------------------------------------------
# Table 7, Berkeley: structural parameters (welfare_estimates.do)
# (no high-points drop in that script)
# ---------------------------------------------------------------
wel <- all[all$sample != "BU QM221", ]
longw <- make_long(wel)
longw$pts00 <- longw$pts / 100

subB <- longw[longw$sample == "Berkeley" & longw$flag_attention_check == 0 & longw$consistent_b == 1, ]
mB <- fit_pts(subB, "pts00")
tau <- unname(coef(mB)["SR"])
fin_act <- unname(coef(mB)["ownpay"])
pts_noim <- mean(subB$pts00[subB$round == "anom"], na.rm = TRUE)
pts_im <- pts_noim + tau

wideB <- wel[wel$sample == "Berkeley" & wel$flag_attention_check == 0 & wel$consistent_b == 1, ]
wtp_long <- bind_rows(lapply(0:16, function(i) {
  data.frame(id = wideB$id, interval = i + 0.5, wtp = wideB[[paste0("wtp", i)]])
}))
wtp_long <- wtp_long[!is.na(wtp_long$wtp), ]
wtp_long$interval2 <- wtp_long$interval^2
mW <- feols(wtp ~ interval + interval2, data = wtp_long, cluster = ~id)
r0 <- unname(coef(mW)["(Intercept)"])
r1 <- unname(coef(mW)["interval"])
r2 <- unname(coef(mW)["interval2"])

gamma2 <- r2
gamma1 <- sqrt(r1^2 - 4 * gamma2 * r0)
rho <- (gamma1 - r1) / (2 * gamma2 * pts_im)
c_par <- (r1 + 2 * r2 * pts_im) / tau
inc <- 0.5
fin_inc <- inc / c_par

# ---------------------------------------------------------------
# Output
# ---------------------------------------------------------------
fmt <- function(x) format(x, digits = 10)

cat(paste0("RESULT:public_recognition_points_prolific_table5_col1=", fmt(unname(coef(t5[["Prolific"]])["SR"])), "\n"))
cat(paste0("RESULT:financial_incentives_points_prolific_table5_col1=", fmt(unname(coef(t5[["Prolific"]])["ownpay"])), "\n"))
cat(paste0("RESULT:public_recognition_points_berkeley_table5_col2=", fmt(unname(coef(t5[["Berkeley"]])["SR"])), "\n"))
cat(paste0("RESULT:financial_incentives_points_berkeley_table5_col2=", fmt(unname(coef(t5[["Berkeley"]])["ownpay"])), "\n"))
cat(paste0("RESULT:public_recognition_points_bu_table5_col3=", fmt(unname(coef(t5[["BU"]])["SR"])), "\n"))
cat(paste0("RESULT:financial_incentives_points_bu_table5_col3=", fmt(unname(coef(t5[["BU"]])["ownpay"])), "\n"))
cat(paste0("RESULT:n_obs_prolific_table5_col1=", nobs(t5[["Prolific"]]), "\n"))
cat(paste0("RESULT:n_obs_berkeley_table5_col2=", nobs(t5[["Berkeley"]]), "\n"))
cat(paste0("RESULT:n_obs_bu_table5_col3=", nobs(t5[["BU"]]), "\n"))
cat(paste0("RESULT:action_signaling_gamma1_berkeley_table7_panelA=", fmt(gamma1), "\n"))
cat(paste0("RESULT:action_signaling_rho_berkeley_table7_panelA=", fmt(rho), "\n"))
cat(paste0("RESULT:cost_parameter_c_berkeley_table7_panelA=", fmt(c_par), "\n"))
cat(paste0("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=", fmt(fin_inc), "\n"))