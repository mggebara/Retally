suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, format(as.numeric(val), digits = 10)))
}

# ---------------- Cross-national analysis ----------------
cn <- as.data.frame(zap_labels(read_dta(file.path(base, "cross-national-data.dta"))))
cn[] <- lapply(cn, function(x) if (is.factor(x)) as.numeric(as.character(x)) else x)

# Volatility rescaled to 0-1 if in percent
if (max(cn$ev_total, na.rm = TRUE) > 1.5) cn$ev_total <- cn$ev_total / 100

# Programmaticness: average of two items (programmatic2), fall back to programmatic
prog_var <- if ("programmatic2" %in% names(cn) && sum(!is.na(cn$programmatic2)) > 0) "programmatic2" else "programmatic"
cn$prog <- cn[[prog_var]]
cn$pers <- cn$personal

# Ethnic party indicator (binary)
eth_vals <- unique(na.omit(cn$ethnic))
if (!all(eth_vals %in% c(0, 1))) cn$ethnic <- as.numeric(cn$ethnic > 0.5)

cn$extreme <- cn$extremist2

# Categorical controls
is_cat <- function(v) { u <- unique(na.omit(v)); length(u) <= 4 && length(u) > 2 }
cn$erule_f <- factor(cn$erule)
cn$system_f <- if (is_cat(cn$system)) factor(cn$system) else cn$system

controls <- c("partysize", "unions", "business", "religious",
              "pluralty", "pr", "erule_f", "mdmh", "polity", "cl",
              "demsys", "system_f", "gdppc", "gini", "ethfrac")
controls <- controls[controls %in% names(cn)]
# drop constant controls
controls <- controls[sapply(controls, function(v) length(unique(na.omit(cn[[v]]))) > 1)]

needed <- c("pers", "prog", "ev_total", "ethnic", "extreme", "ccode",
            "partysize", "unions", "business", "religious",
            "pluralty", "pr", "erule", "mdmh", "polity", "cl",
            "demsys", "system", "gdppc", "gini", "ethfrac")
needed <- needed[needed %in% names(cn)]
d <- cn[complete.cases(cn[, needed]), ]
d$erule_f <- droplevels(factor(d$erule))
if (is.factor(d$system_f)) d$system_f <- droplevels(factor(d$system))

ctrl_str <- paste(controls, collapse = " + ")

fit <- function(y, extra) {
  f <- as.formula(paste(y, "~ ev_total", extra, "+", ctrl_str))
  feols(f, data = d, cluster = ~ccode)
}

q25 <- as.numeric(quantile(d$ev_total, 0.25, type = 2))
q75 <- as.numeric(quantile(d$ev_total, 0.75, type = 2))
dq <- q75 - q25

# H1: overall
m_pers <- fit("pers", "")
m_prog <- fit("prog", "")
pers_diff_overall <- coef(m_pers)["ev_total"] * dq
prog_diff_overall <- coef(m_prog)["ev_total"] * dq

# Ethnicity panel
m_pers_e <- fit("pers", "+ ethnic + ev_total:ethnic")
m_prog_e <- fit("prog", "+ ethnic + ev_total:ethnic")
gi <- function(m, nm) { cf <- coef(m); k <- grep(nm, names(cf), fixed = TRUE); if (length(k)) cf[k[1]] else NA }
pers_diff_noneth <- coef(m_pers_e)["ev_total"] * dq
prog_diff_noneth <- coef(m_prog_e)["ev_total"] * dq
int_pe <- gi(m_pers_e, "ev_total:ethnic"); if (is.na(int_pe)) int_pe <- gi(m_pers_e, "ethnic:ev_total")
int_ge <- gi(m_prog_e, "ev_total:ethnic"); if (is.na(int_ge)) int_ge <- gi(m_prog_e, "ethnic:ev_total")
pers_eth_low <- coef(m_pers_e)["ethnic"] + int_pe * q25
prog_eth_high <- coef(m_prog_e)["ethnic"] + int_ge * q75

# Ideology panel
m_pers_x <- fit("pers", "+ extreme + ev_total:extreme")
m_prog_x <- fit("prog", "+ extreme + ev_total:extreme")
int_px <- gi(m_pers_x, "ev_total:extreme"); if (is.na(int_px)) int_px <- gi(m_pers_x, "extreme:ev_total")
int_gx <- gi(m_prog_x, "ev_total:extreme"); if (is.na(int_gx)) int_gx <- gi(m_prog_x, "extreme:ev_total")
pers_diff_mod <- coef(m_pers_x)["ev_total"] * dq
prog_diff_mod <- coef(m_prog_x)["ev_total"] * dq
pers_ext_low <- 3 * (coef(m_pers_x)["extreme"] + int_px * q25)
prog_ext_high <- 3 * (coef(m_prog_x)["extreme"] + int_gx * q75)

n_obs <- nobs(m_pers)

# ---------------- Brazil RD ----------------
rd_young <- NA
rd_yo <- NA
tryCatch({
  br <- as.data.frame(zap_labels(read_dta(file.path(base, "brazil-RD-data.dta"))))
  sub <- br
  if ("dlameduck_runs" %in% names(br)) {
    s0 <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 0, ]
    s1 <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 1, ]
    n0 <- sum(!is.na(s0$youngF_inc_for1) & !is.na(s0$mv_incparty))
    sub <- if (n0 >= 1000) s0 else s1
  }
  dd <- sub[!is.na(sub$mv_incparty) & !is.na(sub$youngF_inc_for1), ]
  r1 <- rdrobust(y = dd$youngF_inc_for1, x = dd$mv_incparty, c = 0, p = 1,
                 kernel = "triangular", bwselect = "mserd")
  rd_young <- r1$coef[1]
  dd2 <- sub[!is.na(sub$mv_incparty) & !is.na(sub$outyg1F_inc_for1), ]
  r2 <- rdrobust(y = dd2$outyg1F_inc_for1, x = dd2$mv_incparty, c = 0, p = 1,
                 kernel = "triangular", bwselect = "mserd")
  rd_yo <- r2$coef[1]
}, error = function(e) message("RD error: ", conditionMessage(e)))

emit("personalism_volatility_difference_overall", pers_diff_overall)
emit("programmaticness_volatility_difference_overall", prog_diff_overall)
emit("personalism_volatility_difference_nonethnic", pers_diff_noneth)
emit("programmaticness_volatility_difference_nonethnic", prog_diff_noneth)
emit("personalism_ethnic_minus_nonethnic_low_volatility", pers_eth_low)
emit("programmaticness_ethnic_minus_nonethnic_high_volatility", prog_eth_high)
emit("personalism_volatility_difference_moderate", pers_diff_mod)
emit("programmaticness_volatility_difference_moderate", prog_diff_mod)
emit("personalism_extremist_minus_moderate_low_volatility", pers_ext_low)
emit("programmaticness_extremist_minus_moderate_high_volatility", prog_ext_high)
emit("n_obs_table1", n_obs)
emit("rd_effect_young", rd_young)
emit("rd_effect_young_outsider", rd_yo)