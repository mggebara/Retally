suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"
cn <- as.data.frame(zap_labels(read_dta(file.path(base, "cross-national-data.dta"))))
br <- as.data.frame(zap_labels(read_dta(file.path(base, "brazil-RD-data.dta"))))

res <- list()
emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || !is.finite(val)) val <- NA
  res[[name]] <<- val
}

# ---------------- Cross-national (Table 1) ----------------
d <- cn
for (v in names(d)) if (!is.numeric(d[[v]]) && v != "ccode") d[[v]] <- suppressWarnings(as.numeric(d[[v]]))

# Volatility, rescaled to 0-1 if in percent
d$vol <- d$ev_total
if (max(d$vol, na.rm = TRUE) > 1.5) d$vol <- d$vol / 100

# Ethnic party indicator
eth <- d$ethnic
u <- sort(unique(na.omit(eth)))
if (all(u %in% c(0, 1))) {
  d$eth_d <- eth
} else if (max(eth, na.rm = TRUE) <= 1) {
  d$eth_d <- as.numeric(eth > 0.5)
} else {
  d$eth_d <- as.numeric(eth > median(eth, na.rm = TRUE))
}
d$ext <- d$extremist2

# Economic development: log if in levels
d$dev <- d$gdppc
if (max(d$dev, na.rm = TRUE) > 100) d$dev <- log(d$dev)

# Ballot rule and separation of powers as categories when few values
mkfac <- function(x) {
  if (length(unique(na.omit(x))) <= 4) factor(x) else x
}
d$erule_f <- mkfac(d$erule)
d$system_f <- mkfac(d$system)

ctrl <- c("partysize", "unions", "business", "religious",
          "pluralty", "pr", "erule_f", "mdmh", "polity", "demsys",
          "system_f", "dev", "gini", "ethfrac")
ctrl <- ctrl[ctrl %in% names(d)]

need <- c("personal", "programmatic", "vol", "eth_d", "ext", "ccode", ctrl)
s <- d[complete.cases(d[, need]), ]
s$ccode <- as.character(s$ccode)
emit("n_obs_table1", nrow(s))

q25 <- as.numeric(quantile(s$vol, 0.25))
q75 <- as.numeric(quantile(s$vol, 0.75))
dq <- q75 - q25

rhs <- paste(ctrl, collapse = " + ")
fit <- function(y, extra) {
  f <- as.formula(paste(y, "~", extra, "+", rhs))
  feols(f, data = s, cluster = ~ccode)
}

for (y in c("personal", "programmatic")) {
  nm <- if (y == "personal") "personalism" else "programmaticness"
  m0 <- tryCatch(fit(y, "vol"), error = function(e) NULL)
  if (!is.null(m0)) emit(paste0(nm, "_volatility_difference_overall"), coef(m0)["vol"] * dq)

  m1 <- tryCatch(fit(y, "vol * eth_d"), error = function(e) NULL)
  if (!is.null(m1)) {
    b <- coef(m1)
    emit(paste0(nm, "_volatility_difference_nonethnic"), b["vol"] * dq)
    if (y == "personal") emit("personalism_ethnic_minus_nonethnic_low_volatility",
                             b["eth_d"] + b["vol:eth_d"] * q25)
    if (y == "programmatic") emit("programmaticness_ethnic_minus_nonethnic_high_volatility",
                                 b["eth_d"] + b["vol:eth_d"] * q75)
  }

  m2 <- tryCatch(fit(y, "vol * ext"), error = function(e) NULL)
  if (!is.null(m2)) {
    b <- coef(m2)
    emit(paste0(nm, "_volatility_difference_moderate"), b["vol"] * dq)
    if (y == "personal") emit("personalism_extremist_minus_moderate_low_volatility",
                             3 * (b["ext"] + b["vol:ext"] * q25))
    if (y == "programmatic") emit("programmaticness_extremist_minus_moderate_high_volatility",
                                 3 * (b["ext"] + b["vol:ext"] * q75))
  }
}

# ---------------- Brazil RD (Table 2) ----------------
b <- br
for (v in names(b)) b[[v]] <- suppressWarnings(as.numeric(b[[v]]))
# Open-seat sample: winner not term-limited / does not run (lame-duck flag == 0)
bs <- b[!is.na(b$dlameduck_runs) & b$dlameduck_runs == 0, ]
if (nrow(bs) < 100) bs <- b

rd <- function(yv) {
  dd <- bs[complete.cases(bs[, c(yv, "mv_incparty")]), ]
  r <- tryCatch(rdrobust(y = dd[[yv]], x = dd$mv_incparty, c = 0, p = 1,
                         kernel = "triangular", bwselect = "mserd"),
                error = function(e) NULL)
  if (is.null(r)) return(NA)
  as.numeric(r$coef[1, 1])
}
emit("rd_effect_young", rd("youngF_inc_for1"))
emit("rd_effect_young_outsider", rd("outyg1F_inc_for1"))

names_out <- c("personalism_volatility_difference_overall",
               "programmaticness_volatility_difference_overall",
               "personalism_volatility_difference_nonethnic",
               "programmaticness_volatility_difference_nonethnic",
               "personalism_ethnic_minus_nonethnic_low_volatility",
               "programmaticness_ethnic_minus_nonethnic_high_volatility",
               "personalism_volatility_difference_moderate",
               "programmaticness_volatility_difference_moderate",
               "personalism_extremist_minus_moderate_low_volatility",
               "programmaticness_extremist_minus_moderate_high_volatility",
               "n_obs_table1", "rd_effect_young", "rd_effect_young_outsider")
for (n in names_out) {
  v <- res[[n]]
  if (is.null(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(unname(v), digits = 10)))
}
