suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"
cn <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(base, "cross-national-data.dta"))))

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

# ---------- variable construction ----------
cn$vol <- as.numeric(cn$ev_total)
if (max(cn$vol, na.rm = TRUE) > 1.5) cn$vol <- cn$vol / 100   # rescale to 0-1

cn$personalism <- as.numeric(cn$personal)
cn$programmaticness <- as.numeric(cn$programmatic2)

# ethnic party dummy
eth <- as.numeric(cn$ethnic)
ue <- unique(na.omit(eth))
if (!all(ue %in% c(0, 1))) eth <- as.numeric(eth > 0.5)
cn$ethnic_d <- eth

cn$extrem <- as.numeric(cn$extremist2)

# categorical-or-numeric helper
make_ctrl <- function(v) {
  v <- as.numeric(v)
  u <- unique(na.omit(v))
  if (length(u) > 2 && length(u) <= 5) factor(v) else v
}
cn$system_c <- make_ctrl(cn$system)
cn$erule_c  <- make_ctrl(cn$erule)
cn$cl_c     <- make_ctrl(cn$cl)

ctrl_vars <- c("partysize", "unions", "business", "religious",
               "pluralty", "pr", "cl_c", "erule_c", "mdmh", "polity",
               "demsys", "system_c", "gdppc", "gini", "ethfrac")
for (v in c("partysize", "unions", "business", "religious", "pluralty", "pr",
            "mdmh", "polity", "demsys", "gdppc", "gini", "ethfrac"))
  cn[[v]] <- as.numeric(cn[[v]])

need <- c("personalism", "programmaticness", "vol", "ccode", ctrl_vars)
samp <- cn[complete.cases(cn[, need]), ]
n_obs <- nrow(samp)

ctrl_str <- paste(ctrl_vars, collapse = " + ")

fit <- function(dv, rhs, data) {
  f <- as.formula(paste(dv, "~", rhs, "+", ctrl_str))
  m <- lm(f, data = data)
  V <- sandwich::vcovCL(m, cluster = ~ccode, type = "HC1")
  list(m = m, V = V)
}

q25 <- as.numeric(quantile(samp$vol, 0.25))
q75 <- as.numeric(quantile(samp$vol, 0.75))
dq <- q75 - q25

# ---------- Overall ----------
m_p <- fit("personalism", "vol", samp)
m_g <- fit("programmaticness", "vol", samp)
out("personalism_volatility_difference_overall", coef(m_p$m)["vol"] * dq)
out("programmaticness_volatility_difference_overall", coef(m_g$m)["vol"] * dq)

# ---------- Ethnicity ----------
s_e <- samp[!is.na(samp$ethnic_d), ]
e_p <- fit("personalism", "vol * ethnic_d", s_e)
e_g <- fit("programmaticness", "vol * ethnic_d", s_e)
out("personalism_volatility_difference_nonethnic", coef(e_p$m)["vol"] * dq)
out("programmaticness_volatility_difference_nonethnic", coef(e_g$m)["vol"] * dq)
out("personalism_ethnic_minus_nonethnic_low_volatility",
    coef(e_p$m)["ethnic_d"] + coef(e_p$m)["vol:ethnic_d"] * q25)
out("programmaticness_ethnic_minus_nonethnic_high_volatility",
    coef(e_g$m)["ethnic_d"] + coef(e_g$m)["vol:ethnic_d"] * q75)

# ---------- Ideology ----------
s_x <- samp[!is.na(samp$extrem), ]
x_p <- fit("personalism", "vol * extrem", s_x)
x_g <- fit("programmaticness", "vol * extrem", s_x)
out("personalism_volatility_difference_moderate", coef(x_p$m)["vol"] * dq)
out("programmaticness_volatility_difference_moderate", coef(x_g$m)["vol"] * dq)
out("personalism_extremist_minus_moderate_low_volatility",
    3 * (coef(x_p$m)["extrem"] + coef(x_p$m)["vol:extrem"] * q25))
out("programmaticness_extremist_minus_moderate_high_volatility",
    3 * (coef(x_g$m)["extrem"] + coef(x_g$m)["vol:extrem"] * q75))

out("n_obs_table1", n_obs)

# ---------- Brazil RD ----------
br <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(base, "brazil-RD-data.dta"))))
br$x <- as.numeric(br$mv_incparty)
br$ld <- as.numeric(br$dlameduck_runs)

pick_sample <- function(y) {
  ok <- !is.na(br$x) & !is.na(br[[y]])
  uld <- unique(na.omit(br$ld))
  if (all(uld %in% c(0, 1))) {
    s0 <- ok & !is.na(br$ld) & br$ld == 0
    if (sum(s0) > 100) return(br[s0, ])
    s1 <- ok & !is.na(br$ld) & br$ld == 1
    if (sum(s1) > 100) return(br[s1, ])
  }
  br[ok, ]
}

rd_est <- function(y) {
  d <- pick_sample(y)
  r <- rdrobust::rdrobust(y = as.numeric(d[[y]]), x = d$x, c = 0, p = 1,
                          kernel = "triangular", bwselect = "mserd")
  as.numeric(r$coef[1])
}

out("rd_effect_young", rd_est("youngF_inc_for1"))
out("rd_effect_young_outsider", rd_est("outyg1F_inc_for1"))