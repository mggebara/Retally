# Independent reproduction: Butera, Metcalfe, Morrison & Taubinsky (2022),
# "Measuring the Welfare Effects of Shame and Pride" -- Table 5 (cols 1-3),
# Table 6 col 4 (input), Table 7 Berkeley action-signaling parameters and
# panel (c) predicted financial-incentive effect.
suppressPackageStartupMessages({ library(readr); library(fixest) })
set.seed(42)

base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific = "prolific_survey_data.csv",
           berkeley = "berkeley_survey_data.csv",
           bu       = "bu_qm222_survey_data.csv")   # BU sample = QM222 classroom (121 completes)
lv <- seq(0, 1700, 100)

# Preference-pattern shape over the 18 intervals (0/1 "want public recognition").
shape <- function(x) {
  s <- sign(diff(x)); s <- s[s != 0]
  if (length(s) == 0) return("flat")
  if (all(s > 0)) return("inc")
  if (all(s < 0)) return("dec")
  if (all(diff(s) <= 0)) return("peak")
  if (all(diff(s) >= 0)) return("dip")
  "other"
}

load_sample <- function(s) {
  d <- suppressWarnings(read_csv(file.path(base, files[s]), show_col_types = FALSE, guess_max = 5000))
  n0 <- nrow(d)
  pref <- as.matrix(d[, paste0("preference_", lv)])
  sh <- apply(pref, 1, shape)
  # Coherent: weakly increasing in performance, or single-peaked ("look average");
  # incoherent: everything else (decreasing-only, dips, multiple reversals).
  coherent <- sh %in% c("flat", "inc", "peak")
  pass_att <- is.na(d$attention_check)
  keep <- pass_att & coherent
  cat(sprintf("[%s] completed=%d attention_fail=%d incoherent(among passers)=%d\n",
              s, n0, sum(!pass_att), sum(pass_att & !coherent)))
  if (s == "prolific") {
    # two Prolific participants with an unrecorded group assignment / practice
    # round (and 0-1 points in the public round) are not part of the final sample
    inc2 <- !is.na(d$recog_group_assign) & !is.na(d$PracticePts)
    cat(sprintf("[%s] dropped for missing group/practice record: %d\n", s, sum(keep & !inc2)))
    keep <- keep & inc2
  }
  d <- d[keep, ]
  cat(sprintf("[%s] final N subjects = %d\n", s, nrow(d)))
  d
}

dat <- lapply(names(files), load_sample); names(dat) <- names(files)

# ---------------- Table 5 ----------------
t5 <- list()
for (s in names(dat)) {
  d <- dat[[s]]
  cond <- d$Condition  # e.g. "RAE": order of R (public), A (anonymous), E (paid)
  long <- do.call(rbind, lapply(c("A", "R", "E"), function(r) {
    pts <- switch(r, A = d$AnomPts, R = d$RecogPts, E = d$EarnPts)
    data.frame(id = d$id, round = r, points = pts,
               pos = regexpr(r, cond, fixed = TRUE))
  }))
  long$pr  <- as.integer(long$round == "R")
  long$fin <- as.integer(long$round == "E")
  m <- feols(points ~ pr + fin + i(pos, ref = 1), data = long, cluster = ~id)
  print(summary(m))
  t5[[s]] <- list(pr = unname(coef(m)["pr"]), fin = unname(coef(m)["fin"]),
                  n = nobs(m), a0 = mean(d$AnomPts))
  cat(sprintf("[%s] control mean (anonymous round) = %.1f\n", s, mean(d$AnomPts)))
}

# ---------------- Table 6, quadratic (Berkeley col 4 used below; all printed) ----------------
t6 <- list()
for (s in names(dat)) {
  d <- dat[[s]]
  lvx <- seq(0, 1600, 100)  # exclude the >=1700 interval
  long <- do.call(rbind, lapply(lvx, function(l) {
    p <- d[[paste0("preference_", l)]]
    w <- ifelse(p == 1, d[[paste0("pref_rec_", l, "_1")]], -d[[paste0("pref_anom_", l, "_1")]])
    data.frame(id = d$id, x = (l + 50) / 100, wtp = w)
  }))
  m <- feols(wtp ~ x + I(x^2), data = long, cluster = ~id)
  print(summary(m))
  cf <- coef(m)
  t6[[s]] <- c(r0 = unname(cf[1]), r1 = unname(cf[2]), r2 = unname(cf[3]))
}

# ---------------- Table 7, Berkeley action-signaling model (Appendix F.1) ----------------
r <- t6$berkeley
a0  <- t5$berkeley$a0 / 100           # anonymous-round mean, hundreds of points
tau <- t5$berkeley$pr / 100           # public recognition effect, hundreds of points
abar <- a0 + tau                      # average performance with public recognition
gamma1 <- sqrt(r["r1"]^2 - 4 * r["r0"] * r["r2"])
gamma2 <- r["r2"]
rho    <- (sqrt(r["r1"]^2 - 4 * gamma2 * r["r0"]) - r["r1"]) / (2 * abar * r["r2"])
cpar   <- (r["r1"] + 2 * r["r2"] * (a0 + tau)) / tau
p_inc  <- 0.05 * 10                   # 5 cents per 10 points = $0.50 per hundred points
pred   <- p_inc / cpar
cat(sprintf("Berkeley: r0=%.4f r1=%.4f r2=%.5f a0=%.4f tau=%.4f gamma1=%.4f gamma2=%.5f rho=%.4f c=%.4f pred=%.4f actual=%.4f\n",
            r["r0"], r["r1"], r["r2"], a0, tau, gamma1, gamma2, rho, cpar, pred, t5$berkeley$fin / 100))

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.4f\n", t5$prolific$pr))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.4f\n", t5$prolific$fin))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.4f\n", t5$berkeley$pr))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.4f\n", t5$berkeley$fin))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.4f\n", t5$bu$pr))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.4f\n", t5$bu$fin))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", t5$prolific$n))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", t5$berkeley$n))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", t5$bu$n))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.4f\n", gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.4f\n", rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.4f\n", cpar))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.4f\n", pred))
