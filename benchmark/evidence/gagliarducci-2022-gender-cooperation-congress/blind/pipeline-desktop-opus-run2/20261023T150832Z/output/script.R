suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
f_dta <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")
f_csv <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")

d <- tryCatch(as.data.frame(zap_labels(read_dta(f_dta))), error = function(e) NULL)
if (is.null(d)) d <- as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE, guess_max = 100000))
# add columns only present in csv (e.g. sponsor_name, private) if row counts match
if (file.exists(f_csv)) {
  dc <- tryCatch(as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE, guess_max = 100000)), error = function(e) NULL)
  if (!is.null(dc) && nrow(dc) == nrow(d)) {
    extra <- setdiff(names(dc), names(d))
    for (v in extra) d[[v]] <- dc[[v]]
  }
}
nm <- names(d)
has <- function(v) v %in% names(d)

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) cat(sprintf("RESULT:%s=NA\n", name))
  else cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
}

# ---------- sample: public bills ----------
if (has("private")) d <- d[is.na(d$private) | d$private == 0, ]

# ---------- party ----------
pp <- d$sponsor_party
if (is.character(pp) || is.factor(pp)) {
  pp <- toupper(as.character(pp))
  d$dem <- as.integer(grepl("^D", pp)); d$rep <- as.integer(grepl("^R", pp))
} else {
  u <- sort(unique(na.omit(pp)))
  if (all(c(100, 200) %in% u)) {
    d$dem <- as.integer(pp == 100); d$rep <- as.integer(pp == 200)
  } else if (all(u %in% c(0, 1))) {
    d$rep <- as.integer(pp == 1); d$dem <- as.integer(pp == 0)
  } else {
    d$dem <- as.integer(pp == min(u)); d$rep <- as.integer(pp == u[2])
  }
}
d$dem[is.na(pp)] <- NA; d$rep[is.na(pp)] <- NA

d$female <- as.numeric(d$sponsor_female)
d$congress <- d$v2

# ---------- outcomes ----------
d$y_n <- as.numeric(d$numb_cosponsors)
if (has("pct_cosponsors_opposite")) {
  d$y_pct <- as.numeric(d$pct_cosponsors_opposite)
} else {
  d$y_pct <- 100 * d$numb_cosponsors_opposite / (d$numb_cosponsors + 1)
}
if (max(d$y_pct, na.rm = TRUE) <= 1.0001) d$y_pct <- 100 * d$y_pct

# ---------- cluster: sponsor x Congress ----------
st <- if (has("sponsor_state_abbrev")) d$sponsor_state_abbrev else d$sponsor_state_icpsr
idparts <- list(st, d$sponsor_district, d$v2)
if (has("sponsor_name")) idparts <- c(idparts, list(d$sponsor_name))
d$cl <- do.call(paste, c(idparts, sep = "_"))

# ---------- controls ----------
# bill characteristics: committee dummies + minor topic FE
comm <- grep("^house_", nm, value = TRUE)
comm <- comm[sapply(comm, function(v) is.numeric(d[[v]]) && all(na.omit(d[[v]]) %in% c(0, 1)))]
d$minor_f <- d$minor

# sponsor characteristics
if (has("rookie")) {
  d$rookie_x <- d$rookie
} else if (has("sponsor_tenure_run")) {
  d$rookie_x <- as.integer(d$sponsor_tenure_run == min(d$sponsor_tenure_run, na.rm = TRUE))
}
if (has("comc") && has("comr")) d$leader <- as.integer((d$comc %in% 1) | (d$comr %in% 1))
if (!has("nbills_sponsored")) {
  d <- d %>% group_by(cl) %>% mutate(nbills_spons = n()) %>% ungroup() %>% as.data.frame()
} else d$nbills_spons <- d$nbills_sponsored
occ <- grep("^occ[1-9]$", names(d), value = TRUE)
spons <- c("sponsor_age", "sponsor_tenure_run", "rookie_x", "leader", "black", "ivycoll",
           "borninstate", occ, "nbills_spons")
spons <- spons[spons %in% names(d)]
spons_ps <- setdiff(spons, "nbills_spons")

# district characteristics
s_icpsr <- d$sponsor_state_icpsr
d$reg_ne <- as.integer(s_icpsr >= 1 & s_icpsr <= 14)
d$reg_mw <- as.integer(s_icpsr >= 21 & s_icpsr <= 37)
d$reg_s  <- as.integer(s_icpsr >= 40 & s_icpsr <= 56)
if (has("lnarea") && has("lnpop")) d$lndens <- d$lnpop - d$lnarea else if (has("lnpop")) d$lndens <- d$lnpop
distr <- c("reg_ne", "reg_mw", "reg_s", "pct_black", "pct_urban", "pct_for_born", "pct_age_over65",
           "lninc", "lndens")
distr <- distr[distr %in% names(d)]

# margin of victory of the elected candidate
if (has("MV1_democrat")) d$mv_elected <- abs(d$MV1_democrat) else d$mv_elected <- abs(d$MV1_female)

rhs <- function(vars) paste(vars, collapse = " + ")

fit_ols <- function(dd, y, party_ctrl) {
  x <- c("female", comm, spons, distr)
  if (party_ctrl) x <- c(x, "rep")
  fml <- as.formula(paste0(y, " ~ ", rhs(x), " | congress + minor_f"))
  feols(fml, data = dd, cluster = ~cl, warn = FALSE, notes = FALSE)
}

# ---------- propensity scores ----------
ps_weights <- function(dd, covs) {
  sp <- dd %>% group_by(cl) %>% summarise(across(all_of(c("female", covs)), ~ first(.x)), .groups = "drop")
  sp <- sp[complete.cases(sp), ]
  # drop constant covariates
  covs2 <- covs[sapply(covs, function(v) length(unique(sp[[v]])) > 1)]
  g <- glm(as.formula(paste0("female ~ ", rhs(covs2))), data = sp, family = binomial("probit"))
  sp$ps <- predict(g, type = "response")
  sp$w <- ifelse(sp$female == 1, 1 / sp$ps, 1 / (1 - sp$ps))
  dd$w <- sp$w[match(dd$cl, sp$cl)]
  dd
}

fit_ipw <- function(dd, y, covs) {
  dd <- ps_weights(dd, covs)
  dd <- dd[!is.na(dd$w), ]
  fml <- as.formula(paste0(y, " ~ ", rhs(c("female", comm)), " | congress + minor_f"))
  feols(fml, data = dd, weights = ~w, cluster = ~cl, warn = FALSE, notes = FALSE)
}

# RD
mv_scale <- if (max(abs(d$MV1_female), na.rm = TRUE) <= 1.0001) 0.01 else 1
d$mv <- d$MV1_female
d$fem_mv <- d$female * d$mv
rd_sample <- function(dd, h) {
  dd[!is.na(dd$mixed_gender_election) & dd$mixed_gender_election == 1 &
       !is.na(dd$mv) & abs(dd$mv) <= h * mv_scale, ]
}
fit_rd <- function(dd, y, h) {
  s <- rd_sample(dd, h)
  feols(as.formula(paste0(y, " ~ female + mv + fem_mv | congress")), data = s,
        cluster = ~cl, warn = FALSE, notes = FALSE)
}
fit_rd_ipw <- function(dd, y, h) {
  s <- rd_sample(dd, h)
  s <- ps_weights(s, distr)
  s <- s[!is.na(s$w), ]
  fml <- as.formula(paste0(y, " ~ ", rhs(c("female", "mv", "fem_mv", comm)), " | congress + minor_f"))
  feols(fml, data = s, weights = ~w, cluster = ~cl, warn = FALSE, notes = FALSE)
}

getb <- function(m) tryCatch(unname(coef(m)["female"]), error = function(e) NA)

dD <- d[!is.na(d$dem) & d$dem == 1, ]
dR <- d[!is.na(d$rep) & d$rep == 1, ]

m1 <- tryCatch(fit_ols(d, "y_n", TRUE), error = function(e) NULL)
emit("female_sponsor_ncosponsors_all_ols", if (!is.null(m1)) getb(m1) else NA)

m2 <- tryCatch(fit_ols(dR, "y_n", FALSE), error = function(e) NULL)
emit("female_sponsor_ncosponsors_rep_ols", if (!is.null(m2)) getb(m2) else NA)

m3 <- tryCatch(fit_rd_ipw(dR, "y_n", 13), error = function(e) NULL)
emit("female_sponsor_ncosponsors_rep_rd_ipw", if (!is.null(m3)) getb(m3) else NA)

m4 <- tryCatch(fit_ipw(dR, "y_n", c(distr, "mv_elected", spons_ps)), error = function(e) NULL)
emit("female_sponsor_ncosponsors_rep_ipw_sponsor", if (!is.null(m4)) getb(m4) else NA)

m5 <- tryCatch(fit_ols(dD, "y_pct", FALSE), error = function(e) NULL)
emit("female_sponsor_pct_opposite_dem_ols", if (!is.null(m5)) getb(m5) else NA)

m6 <- tryCatch(fit_rd(dD, "y_pct", 24), error = function(e) NULL)
emit("female_sponsor_pct_opposite_dem_rd", if (!is.null(m6)) getb(m6) else NA)

m7 <- tryCatch(fit_ipw(dD, "y_pct", c(distr, "mv_elected", spons_ps)), error = function(e) NULL)
emit("female_sponsor_pct_opposite_dem_ipw_sponsor", if (!is.null(m7)) getb(m7) else NA)

m8 <- tryCatch(fit_ols(dR, "y_pct", FALSE), error = function(e) NULL)
emit("female_sponsor_pct_opposite_rep_ols", if (!is.null(m8)) getb(m8) else NA)

m9 <- tryCatch(fit_ipw(dR, "y_pct", c(distr, "mv_elected")), error = function(e) NULL)
emit("female_sponsor_pct_opposite_rep_ipw_district", if (!is.null(m9)) getb(m9) else NA)

nclus <- function(m, dd) {
  tryCatch({
    obs <- obs(m)
    length(unique(dd$cl[obs]))
  }, error = function(e) NA)
}
emit("n_bills_ncosponsors_all_ols", if (!is.null(m1)) nobs(m1) else NA)
emit("n_sponsor_terms_ncosponsors_all_ols", if (!is.null(m1)) nclus(m1, d) else NA)
emit("n_bills_pct_opposite_dem_ols", if (!is.null(m5)) nobs(m5) else NA)
emit("n_bills_pct_opposite_rep_ols", if (!is.null(m8)) nobs(m8) else NA)