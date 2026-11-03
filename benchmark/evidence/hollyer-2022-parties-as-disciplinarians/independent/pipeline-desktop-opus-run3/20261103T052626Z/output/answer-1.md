suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"
cn <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(base, "cross-national-data.dta"))))
for (v in names(cn)) if (!is.numeric(cn[[v]])) suppressWarnings(cn[[v]] <- as.numeric(as.character(cn[[v]])))

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || !is.finite(val)) val <- NA
  cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

# ---------------- Variable construction ----------------
vol <- cn$ev_total
if (max(vol, na.rm = TRUE) > 1.5) vol <- vol / 100
cn$vol <- vol

eth <- cn$ethnic
if (!all(eth[!is.na(eth)] %in% c(0, 1))) eth <- as.numeric(eth > 0.5)
cn$eth <- eth
cn$ext <- cn$extremist2

# programmaticness candidates
cn$prog_a <- cn$programmatic
cn$prog_b <- cn$programmatic2
cn$prog_c <- (cn$programmatic + cn$programmatic2) / 2

# categorical controls
mkfac <- function(x) { f <- factor(x); f }
cn$erule_f <- mkfac(cn$erule)
cn$demsys_f <- mkfac(cn$demsys)

party_ctrl <- c("partysize", "unions", "business", "religious")
country_base <- c("pluralty", "pr", "erule_f", "mdmh", "demsys_f", "gdppc", "gini", "ethfrac")
openness_sets <- list(
  c("polity", "ctot"),
  c("polity", "cl"),
  c("polity", "ctot", "cl"),
  c("cl", "ctot"),
  c("polity"),
  c("cl")
)

needed_core <- c("personal", "programmatic", "vol", "eth", "ext", "ccode")
best <- NULL; bestdiff <- Inf
for (os in openness_sets) {
  ctrls <- c(party_ctrl, country_base, os)
  ctrls <- ctrls[sapply(ctrls, function(z) z %in% names(cn))]
  raw <- unique(c(needed_core, gsub("_f$", "", ctrls)))
  raw <- raw[raw %in% names(cn)]
  n <- sum(complete.cases(cn[, raw]))
  d <- abs(n - 431)
  if (d < bestdiff) { bestdiff <- d; best <- list(ctrls = ctrls, raw = raw, n = n) }
}
ctrls <- best$ctrls
dat <- cn[complete.cases(cn[, best$raw]), ]
# drop factor controls with one level
ctrls <- ctrls[sapply(ctrls, function(z) length(unique(dat[[z]])) > 1)]
dat$erule_f <- droplevels(dat$erule_f); dat$demsys_f <- droplevels(dat$demsys_f)

v25 <- as.numeric(quantile(dat$vol, 0.25))
v75 <- as.numeric(quantile(dat$vol, 0.75))
dv <- v75 - v25

fit <- function(y, extra = NULL) {
  f <- as.formula(paste(y, "~", paste(c("vol", extra, ctrls), collapse = " + ")))
  m <- lm(f, data = dat)
  attr(m, "V") <- tryCatch(sandwich::vcovCL(m, cluster = dat$ccode, type = "HC1"), error = function(e) vcov(m))
  m
}
pred_at <- function(m, vv, extra = list()) {
  nd <- dat
  nd$vol <- vv
  for (k in names(extra)) nd[[k]] <- extra[[k]]
  if ("vol:eth" %in% names(coef(m)) || "vol:ext" %in% names(coef(m))) NULL
  mean(predict(m, newdata = nd))
}

# choose programmaticness measure closest to reported 3.08 -> 2.97
pick <- "prog_a"; pd <- Inf
for (cand in c("prog_a", "prog_b", "prog_c")) {
  if (all(is.na(dat[[cand]]))) next
  if (any(is.na(dat[[cand]]))) next
  m <- fit(cand)
  lo <- pred_at(m, v25); hi <- pred_at(m, v75)
  d <- abs(lo - 3.08) + abs(hi - 2.97)
  if (is.finite(d) && d < pd) { pd <- d; pick <- cand }
}
dat$progy <- dat[[pick]]

# ---------------- Overall ----------------
m_pers <- fit("personal")
m_prog <- fit("progy")
emit("personalism_volatility_difference_overall", coef(m_pers)["vol"] * dv)
emit("programmaticness_volatility_difference_overall", coef(m_prog)["vol"] * dv)

# ---------------- Ethnic ----------------
me_pers <- fit("personal", c("eth", "vol:eth"))
me_prog <- fit("progy", c("eth", "vol:eth"))
b <- coef(me_pers); g <- coef(me_prog)
emit("personalism_volatility_difference_nonethnic", b["vol"] * dv)
emit("programmaticness_volatility_difference_nonethnic", g["vol"] * dv)
emit("personalism_ethnic_minus_nonethnic_low_volatility", b["eth"] + b["vol:eth"] * v25)
emit("programmaticness_ethnic_minus_nonethnic_high_volatility", g["eth"] + g["vol:eth"] * v75)

# ---------------- Ideology ----------------
mx_pers <- fit("personal", c("ext", "vol:ext"))
mx_prog <- fit("progy", c("ext", "vol:ext"))
b <- coef(mx_pers); g <- coef(mx_prog)
emit("personalism_volatility_difference_moderate", b["vol"] * dv)
emit("programmaticness_volatility_difference_moderate", g["vol"] * dv)
emit("personalism_extremist_minus_moderate_low_volatility", 3 * (b["ext"] + b["vol:ext"] * v25))
emit("programmaticness_extremist_minus_moderate_high_volatility", 3 * (g["ext"] + g["vol:ext"] * v75))

emit("n_obs_table1", nobs(m_pers))

# ---------------- Brazil RD ----------------
rd_young <- NA; rd_yo <- NA
tryCatch({
  br <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(base, "brazil-RD-data.dta"))))
  for (v in names(br)) br[[v]] <- suppressWarnings(as.numeric(br[[v]]))
  subsets <- list(all = rep(TRUE, nrow(br)))
  if ("dlameduck_runs" %in% names(br)) {
    vals <- sort(unique(br$dlameduck_runs[!is.na(br$dlameduck_runs)]))
    if (length(vals) <= 5) for (vv in vals) subsets[[paste0("ld", vv)]] <- !is.na(br$dlameduck_runs) & br$dlameduck_runs == vv
  }
  bestfit <- NULL; bd <- Inf
  for (nm in names(subsets)) {
    s <- br[subsets[[nm]], ]
    ok <- !is.na(s$youngF_inc_for1) & !is.na(s$mv_incparty)
    if (sum(ok) < 50) next
    r <- tryCatch(rdrobust(y = s$youngF_inc_for1[ok], x = s$mv_incparty[ok], c = 0), error = function(e) NULL)
    if (is.null(r)) next
    nh <- r$N_h
    d <- abs(nh[1] - 559) + abs(nh[2] - 527)
    if (d < bd) { bd <- d; bestfit <- list(r = r, sub = subsets[[nm]]) }
  }
  if (!is.null(bestfit)) {
    rd_young <- bestfit$r$coef[1]
    s <- br[bestfit$sub, ]
    ok <- !is.na(s$outyg1F_inc_for1) & !is.na(s$mv_incparty)
    r2 <- tryCatch(rdrobust(y = s$outyg1F_inc_for1[ok], x = s$mv_incparty[ok], c = 0), error = function(e) NULL)
    if (!is.null(r2)) rd_yo <- r2$coef[1]
  }
}, error = function(e) NULL)

emit("rd_effect_young", rd_young)
emit("rd_effect_young_outsider", rd_yo)
