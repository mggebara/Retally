# Independent, blind reproduction of Table 5 (selected cells), Gagliarducci & Paserman,
# "Gender Differences in Cooperative Environments? Evidence from the U.S. Congress".
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest); library(rdrobust)})

f <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-07-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta"
d <- zap_labels(read_dta(f))

# ---- sample: House public bills, 101st-111th Congress ----
d <- d %>% filter(!is.na(private), private == 0)

# total number of (public) bills sponsored by the member in the Congress
d <- d %>%
  mutate(spid = paste(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served, sep = "_")) %>%
  group_by(spid) %>% mutate(nbills_sponsored = n()) %>% ungroup()

# ---- variable construction ----
st <- d$sponsor_state_icpsr
d <- d %>% mutate(
  female      = sponsor_female,
  ncosp       = numb_cosponsors,
  pct_opp     = 100 * pct_cosponsors_opposite,      # percent of cosponsors from the opposite party
  rookie      = as.numeric(sponsor_tenure_run == 1),
  leader      = as.numeric(comc == 1 | comr == 1),
  party_f     = factor(sponsor_party),
  republican  = as.numeric(sponsor_party == 200),
  democrat    = as.numeric(sponsor_party == 100),
  # census macro areas from ICPSR state codes (South omitted)
  reg_ne      = as.numeric(st >= 1 & st <= 14),
  reg_mw      = as.numeric(st >= 21 & st <= 37),
  reg_west    = as.numeric(st >= 61),
  lndens      = lnpop - lnarea,
  mv_winner   = 100 * abs(MV1_democrat),             # margin of victory of the elected candidate
  mvf         = MV1_female                            # margin of victory of the female candidate (mixed-gender races)
)

comm <- grep("^house_", names(d), value = TRUE)          # 33 committee-of-referral dummies
spons <- c("sponsor_age", "sponsor_tenure_run", "rookie", "leader", "black", "party_f",
           paste0("occ", 1:5), "ivycoll", "borninstate", "nbills_sponsored")
spons_np <- setdiff(spons, "party_f")                     # within-party samples: no party dummy
distr <- c("reg_ne", "reg_mw", "reg_west", "pct_black", "pct_age_over65", "pct_for_born",
           "pct_urban", "lninc", "lndens")
cat("committee dummies:", length(comm), "\n")

subs <- list(all = rep(TRUE, nrow(d)), dem = d$democrat %in% 1, rep = d$republican %in% 1)

# ---- Column 1: OLS full sample ----
ols <- function(y, s) {
  sp <- if (s == "all") spons else spons_np
  fml <- as.formula(paste(y, "~ female +", paste(c(comm, sp, distr), collapse = " + "), "| v2 + minor"))
  feols(fml, data = d[subs[[s]], ], cluster = ~spid)
}

# ---- probit propensity score with ATE inverse-probability weights ----
ipw <- function(dat, xs) {
  pf <- as.formula(paste("female ~", paste(xs, collapse = " + ")))
  m <- glm(pf, family = binomial(link = "probit"), data = dat)
  p <- predict(m, newdata = dat, type = "response")
  ifelse(dat$female == 1, 1 / p, 1 / (1 - p))
}

# ---- Columns 2/3: RD in mixed-gender races within bandwidth h ----
rd <- function(y, s, h, weighted = FALSE) {
  sp_cols <- c(y, "female", "mvf", "v2", "spid", "minor", comm, distr)
  dat <- d[subs[[s]] & !is.na(d$mvf) & abs(d$mvf) <= h, ]
  dat <- dat[complete.cases(dat[, sp_cols]), ]
  dat$fem_mv <- dat$female * dat$mvf
  if (!weighted) {
    feols(as.formula(paste(y, "~ female + mvf + fem_mv | v2")), data = dat, cluster = ~spid)
  } else {
    dat$w <- ipw(dat, distr)
    feols(as.formula(paste(y, "~ female + mvf + fem_mv +", paste(comm, collapse = " + "), "| v2 + minor")),
          data = dat, weights = ~w, cluster = ~spid)
  }
}

# CCT (2014) MSE-optimal bandwidth computed on bill-level observations (reported for information)
cct_bw <- function(y, s) {
  dat <- d[subs[[s]] & !is.na(d$mvf) & !is.na(d[[y]]) & !is.na(d$female), ]
  b <- rdbwselect(y = dat[[y]], x = dat$mvf, c = 0, p = 1, kernel = "triangular", bwselect = "mserd")
  b$bws[1, 1]
}

# ---- Columns 4/5: PS weighting, full sample of races ----
psw <- function(y, s, with_sponsor) {
  sp <- if (s == "all") spons else spons_np
  xs <- c(distr, "mv_winner", if (with_sponsor) sp)
  cols <- c(y, "female", "v2", "spid", "minor", comm, xs)
  dat <- d[subs[[s]], ]
  dat <- dat[complete.cases(dat[, cols]), ]
  dat$w <- ipw(dat, xs)
  feols(as.formula(paste(y, "~ female +", paste(comm, collapse = " + "), "| v2 + minor")),
        data = dat, weights = ~w, cluster = ~spid)
}

co <- function(m) unname(coef(m)["female"])

m1  <- ols("ncosp", "all")
m2  <- ols("ncosp", "rep")
m5  <- ols("pct_opp", "dem")
m8  <- ols("pct_opp", "rep")

h_rep_n <- 13; h_dem_p <- 24   # bandwidths stated for these rows (CCT 2014, bill-level)
bw_a <- tryCatch(cct_bw("ncosp", "rep"), error = function(e) NA)
bw_b <- tryCatch(cct_bw("pct_opp", "dem"), error = function(e) NA)
cat(sprintf("Note: rdrobust mserd bandwidth (R implementation): rep ncosp = %.2f; dem pct_opp = %.2f; using stated %d and %d\n",
            bw_a, bw_b, h_rep_n, h_dem_p))

m3  <- rd("ncosp", "rep", h_rep_n, weighted = TRUE)
m6  <- rd("pct_opp", "dem", h_dem_p, weighted = FALSE)
m4  <- psw("ncosp", "rep", with_sponsor = TRUE)
m7  <- psw("pct_opp", "dem", with_sponsor = TRUE)
m9  <- psw("pct_opp", "rep", with_sponsor = FALSE)

nclust <- function(m, s) {
  # number of sponsor-Congress clusters used in the estimation sample
  dat <- d[subs[[s]], ]
  length(unique(dat$spid[obs(m)]))
}

for (nm in c("m1","m2","m3","m4","m5","m6","m7","m8","m9")) {
  m <- get(nm); cat(sprintf("%s: coef=%.4f se=%.4f N=%d\n", nm, co(m), unname(se(m)["female"]), nobs(m)))
}

res <- c(
  female_sponsor_ncosponsors_all_ols = co(m1),
  female_sponsor_ncosponsors_rep_ols = co(m2),
  female_sponsor_ncosponsors_rep_rd_ipw = co(m3),
  female_sponsor_ncosponsors_rep_ipw_sponsor = co(m4),
  female_sponsor_pct_opposite_dem_ols = co(m5),
  female_sponsor_pct_opposite_dem_rd = co(m6),
  female_sponsor_pct_opposite_dem_ipw_sponsor = co(m7),
  female_sponsor_pct_opposite_rep_ols = co(m8),
  female_sponsor_pct_opposite_rep_ipw_district = co(m9),
  n_bills_ncosponsors_all_ols = nobs(m1),
  n_sponsor_terms_ncosponsors_all_ols = nclust(m1, "all"),
  n_bills_pct_opposite_dem_ols = nobs(m5),
  n_bills_pct_opposite_rep_ols = nobs(m8)
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6g\n", n, res[[n]]))
