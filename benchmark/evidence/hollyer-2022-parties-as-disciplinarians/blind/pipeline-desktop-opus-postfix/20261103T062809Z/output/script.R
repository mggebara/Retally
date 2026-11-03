suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"

# ---------------- Cross-national analysis (Table 1) ----------------
cn <- as.data.frame(zap_labels(read_dta(file.path(base, "cross-national-data.dta"))))
cat(sprintf("SAMPLE:table1:loaded=%d\n", nrow(cn)))

# Volatility on 0-1 scale
if (max(cn$ev_total, na.rm = TRUE) > 1) cn$ev_total <- cn$ev_total / 100

# Ethnic party: binary indicator (1 if most experts report ethnic linkages)
eth_vals <- unique(na.omit(cn$ethnic))
if (all(eth_vals %in% c(0, 1))) {
  cn$ethnic_d <- cn$ethnic
} else if (max(eth_vals) <= 1) {
  cn$ethnic_d <- as.numeric(cn$ethnic > 0.5)
} else {
  mid <- (min(eth_vals) + max(eth_vals)) / 2
  cn$ethnic_d <- as.numeric(cn$ethnic > mid)
}
cn$ethnic_d[is.na(cn$ethnic)] <- NA

# Economic development: log GDP per capita if not already logged
if (max(cn$gdppc, na.rm = TRUE) > 100) cn$gdppc <- log(cn$gdppc)

# Separation of powers (political system) and ballot rules as categorical
cn$system_f <- factor(cn$system)
cl_vals <- unique(na.omit(cn$cl))
if (length(cl_vals) > 2) {
  cn$cl_f <- factor(cn$cl)
} else {
  cn$cl_f <- factor(cn$cl)
}

controls <- c("partysize", "unions", "business", "religious",
              "pluralty", "pr", "cl_f", "mdmh", "polity", "demsys",
              "system_f", "gdppc", "gini", "ethfrac")
needed <- c("personal", "programmatic", "ev_total", "ethnic_d", "extremist2",
            "partysize", "unions", "business", "religious",
            "pluralty", "pr", "cl", "mdmh", "polity", "demsys",
            "system", "gdppc", "gini", "ethfrac", "ccode")
cn <- cn[complete.cases(cn[, needed]), ]
cat(sprintf("SAMPLE:table1:complete_data=%d\n", nrow(cn)))

ctrl_str <- paste(controls, collapse = " + ")
f_main <- function(y) as.formula(paste(y, "~ ev_total +", ctrl_str))
f_eth  <- function(y) as.formula(paste(y, "~ ev_total * ethnic_d +", ctrl_str))
f_ext  <- function(y) as.formula(paste(y, "~ ev_total * extremist2 +", ctrl_str))

m_pers   <- feols(f_main("personal"), data = cn, cluster = ~ccode)
m_prog   <- feols(f_main("programmatic"), data = cn, cluster = ~ccode)
m_pers_e <- feols(f_eth("personal"), data = cn, cluster = ~ccode)
m_prog_e <- feols(f_eth("programmatic"), data = cn, cluster = ~ccode)
m_pers_x <- feols(f_ext("personal"), data = cn, cluster = ~ccode)
m_prog_x <- feols(f_ext("programmatic"), data = cn, cluster = ~ccode)

cat(sprintf("SAMPLE:table1:estimation=%d\n", nobs(m_pers)))

q25 <- as.numeric(quantile(cn$ev_total, 0.25))
q75 <- as.numeric(quantile(cn$ev_total, 0.75))
dq <- q75 - q25
ext_level <- 3

cf <- function(m, v) as.numeric(coef(m)[v])
int_name <- function(m, a, b) {
  nm <- names(coef(m))
  c1 <- paste0(a, ":", b); c2 <- paste0(b, ":", a)
  if (c1 %in% nm) c1 else c2
}

pers_diff_overall <- cf(m_pers, "ev_total") * dq
prog_diff_overall <- cf(m_prog, "ev_total") * dq

pers_diff_noneth <- cf(m_pers_e, "ev_total") * dq
prog_diff_noneth <- cf(m_prog_e, "ev_total") * dq
pers_eth_low  <- cf(m_pers_e, "ethnic_d") + cf(m_pers_e, int_name(m_pers_e, "ev_total", "ethnic_d")) * q25
prog_eth_high <- cf(m_prog_e, "ethnic_d") + cf(m_prog_e, int_name(m_prog_e, "ev_total", "ethnic_d")) * q75

pers_diff_mod <- cf(m_pers_x, "ev_total") * dq
prog_diff_mod <- cf(m_prog_x, "ev_total") * dq
pers_ext_low  <- ext_level * (cf(m_pers_x, "extremist2") + cf(m_pers_x, int_name(m_pers_x, "ev_total", "extremist2")) * q25)
prog_ext_high <- ext_level * (cf(m_prog_x, "extremist2") + cf(m_prog_x, int_name(m_prog_x, "ev_total", "extremist2")) * q75)

# ---------------- Brazil RD (Table 2) ----------------
br <- as.data.frame(zap_labels(read_dta(file.path(base, "brazil-RD-data.dta"))))
cat(sprintf("SAMPLE:rd_young:loaded=%d\n", nrow(br)))
br_open <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 0, ]
cat(sprintf("SAMPLE:rd_young:incumbent_not_running=%d\n", nrow(br_open)))

d1 <- br_open[complete.cases(br_open[, c("youngF_inc_for1", "mv_incparty")]), ]
rd1 <- rdrobust(y = d1$youngF_inc_for1, x = d1$mv_incparty, c = 0)
cat(sprintf("SAMPLE:rd_young:estimation=%d\n", sum(rd1$N_h)))

cat(sprintf("SAMPLE:rd_young_outsider:loaded=%d\n", nrow(br)))
cat(sprintf("SAMPLE:rd_young_outsider:incumbent_not_running=%d\n", nrow(br_open)))
d2 <- br_open[complete.cases(br_open[, c("outyg1F_inc_for1", "mv_incparty")]), ]
rd2 <- rdrobust(y = d2$outyg1F_inc_for1, x = d2$mv_incparty, c = 0)
cat(sprintf("SAMPLE:rd_young_outsider:estimation=%d\n", sum(rd2$N_h)))

rd_young <- as.numeric(rd1$coef[1])
rd_young_out <- as.numeric(rd2$coef[1])

# ---------------- Results ----------------
cat(sprintf("RESULT:personalism_volatility_difference_overall=%.6f\n", pers_diff_overall))
cat(sprintf("RESULT:programmaticness_volatility_difference_overall=%.6f\n", prog_diff_overall))
cat(sprintf("RESULT:personalism_volatility_difference_nonethnic=%.6f\n", pers_diff_noneth))
cat(sprintf("RESULT:programmaticness_volatility_difference_nonethnic=%.6f\n", prog_diff_noneth))
cat(sprintf("RESULT:personalism_ethnic_minus_nonethnic_low_volatility=%.6f\n", pers_eth_low))
cat(sprintf("RESULT:programmaticness_ethnic_minus_nonethnic_high_volatility=%.6f\n", prog_eth_high))
cat(sprintf("RESULT:personalism_volatility_difference_moderate=%.6f\n", pers_diff_mod))
cat(sprintf("RESULT:programmaticness_volatility_difference_moderate=%.6f\n", prog_diff_mod))
cat(sprintf("RESULT:personalism_extremist_minus_moderate_low_volatility=%.6f\n", pers_ext_low))
cat(sprintf("RESULT:programmaticness_extremist_minus_moderate_high_volatility=%.6f\n", prog_ext_high))
cat(sprintf("RESULT:n_obs_table1=%d\n", nobs(m_pers)))
cat(sprintf("RESULT:rd_effect_young=%.6f\n", rd_young))
cat(sprintf("RESULT:rd_effect_young_outsider=%.6f\n", rd_young_out))