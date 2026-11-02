# Independent, blind reproduction of Gagliarducci & Paserman, Table 5 (selected cells)
suppressMessages({library(readr); library(dplyr); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-10-22-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data"
b <- read_csv(file.path(base, "AnalysisData/bills_analysis_101-111_replication.csv"),
              show_col_types = FALSE, guess_max = 100000)

# ---- sample: House public bills with sponsor information ----
b <- b %>% filter(!is.na(private), private == 0, !is.na(sponsor_female))

# sponsor-Congress unit (clustering level)
b <- b %>% mutate(sid = paste(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served, sep = "_"))
# total number of (public) bills sponsored within the Congress
b <- b %>% group_by(sid) %>% mutate(nbills = n()) %>% ungroup()

# outcomes
b <- b %>% mutate(ncosp = numb_cosponsors,
                  pctopp = 100 * pct_cosponsors_opposite)   # percent of cosponsors from opposite party

# sponsor characteristics
b <- b %>% mutate(
  rookie = as.integer(sponsor_tenure_run == 1),
  leader = as.integer(comc == 1 | comr == 1),
  occ = case_when(occ0 == 1 ~ 0, occ1 == 1 ~ 1, occ2 == 1 ~ 2, occ3 == 1 ~ 3,
                  occ4 == 1 ~ 4, occ5 == 1 ~ 5, occ6 == 1 ~ 6, TRUE ~ NA_real_),
  party = factor(sponsor_party)
)
# district characteristics: census macro areas from ICPSR state codes (Northeast = base)
s <- b$sponsor_state_icpsr
b <- b %>% mutate(
  midwest = as.integer(s >= 21 & s <= 37),
  south   = as.integer((s >= 40 & s <= 56) | s == 11),
  west    = as.integer(s >= 61),
  lndens  = lnpop - lnarea,
  mv_winner = 100 * abs(MV1_democrat),        # margin of victory of the elected candidate
  mvf = MV1_female                            # margin of victory of the female candidate (mixed-gender races)
)

hc <- grep("^house_", names(b), value = TRUE)
billc <- paste(hc, collapse = " + ")
spons_core <- "sponsor_age + sponsor_tenure_run + rookie + leader + black + factor(occ) + ivycoll + borninstate + nbills"
distc <- "midwest + south + west + pct_black + pct_urban + pct_for_born + pct_age_over65 + lninc + lndens"
ps_dist <- c("midwest","south","west","pct_black","pct_urban","pct_for_born","pct_age_over65","lninc","lndens")
ps_spons <- c("sponsor_age","sponsor_tenure_run","rookie","leader","black","ivycoll","borninstate","nbills")

sub <- function(grp) {
  if (grp == "all") b else if (grp == "dem") filter(b, sponsor_party == 100) else filter(b, sponsor_party == 200)
}

# ---- Column 1: OLS full sample ----
ols <- function(y, grp) {
  d <- sub(grp)
  sp <- if (grp == "all") paste(spons_core, "+ party") else spons_core
  f <- as.formula(paste(y, "~ sponsor_female +", billc, "+", sp, "+", distc, "| v2 + minor"))
  feols(f, data = d, cluster = ~sid)
}

# ---- Column 2: RD within bandwidth h (linear, separate slopes, Congress FE, no other controls) ----
rd <- function(y, grp, h, weights = NULL, bill = FALSE) {
  d <- sub(grp) %>% filter(mixed_gender_election == 1, !is.na(mvf), abs(mvf) <= h, !is.na(.data[[y]]))
  rhs <- "sponsor_female + mvf + sponsor_female:mvf"
  if (bill) rhs <- paste(rhs, "+", billc)
  fe <- if (bill) "| v2 + minor" else "| v2"
  list(d = d, rhs = rhs, fe = fe)
}

# probit propensity score of electing a woman, ATE inverse-probability weights
ipw <- function(d, covs) {
  d <- d[complete.cases(d[, covs]), ]
  f <- as.formula(paste("sponsor_female ~", paste(covs, collapse = " + "), "+ factor(v2)"))
  m <- glm(f, data = d, family = binomial(link = "probit"))
  p <- fitted(m)
  d$w <- ifelse(d$sponsor_female == 1, 1 / p, 1 / (1 - p))
  cat(sprintf("  [ps] n=%d  p range %.4f-%.4f  max w %.1f\n", nrow(d), min(p), max(p), max(d$w)))
  d
}

# ---- Column 3: RD with inverse PS weighting (district characteristics), bill chars ----
rd_ipw <- function(y, grp, h) {
  s0 <- rd(y, grp, h, bill = TRUE)
  d <- s0$d[complete.cases(s0$d[, c(ps_dist, "minor")]), ]
  d <- ipw(d, ps_dist)
  feols(as.formula(paste(y, "~", s0$rhs, s0$fe)), data = d, weights = ~w, cluster = ~sid)
}

# ---- Columns 4/5: PS weighting, full sample of races ----
ps_full <- function(y, grp, spons = FALSE) {
  d <- sub(grp) %>% filter(!is.na(.data[[y]]), !is.na(minor))
  covs <- c(ps_dist, "mv_winner")
  if (spons) {
    occd <- paste0("occ_", 1:6)
    for (k in 1:6) d[[occd[k]]] <- as.integer(d$occ == k)
    covs <- c(covs, ps_spons, occd)
    if (grp == "all") { d$repub <- as.integer(d$sponsor_party == 200); covs <- c(covs, "repub") }
  }
  d <- ipw(d, covs)
  f <- as.formula(paste(y, "~ sponsor_female +", billc, "| v2 + minor"))
  feols(f, data = d, weights = ~w, cluster = ~sid)
}

cf <- function(m) unname(coef(m)["sponsor_female"])
rep_m <- function(lbl, m) cat(sprintf("  %-45s b=%.4f se=%.4f n=%d\n", lbl, cf(m), unname(se(m)["sponsor_female"]), nobs(m)))

out <- list()

cat("Column 1: OLS\n")
m1 <- ols("ncosp", "all");   rep_m("ncosp all OLS", m1)
ncl_all <- length(unique(sub("all")$sid[obs(m1)]))
m2 <- ols("ncosp", "rep");   rep_m("ncosp rep OLS", m2)
m5 <- ols("pctopp", "dem");  rep_m("pctopp dem OLS", m5)
m8 <- ols("pctopp", "rep");  rep_m("pctopp rep OLS", m8)

cat("Column 2: RD (h = 24, Dem, pct opposite)\n")
s6 <- rd("pctopp", "dem", 24)
m6 <- feols(as.formula(paste("pctopp ~", s6$rhs, s6$fe)), data = s6$d, cluster = ~sid); rep_m("pctopp dem RD", m6)

cat("Column 3: RD + IPW (h = 13, Rep, ncosp)\n")
m3 <- rd_ipw("ncosp", "rep", 13); rep_m("ncosp rep RD-IPW", m3)

cat("Column 4: PS district + MV (Rep, pct opposite)\n")
m9 <- ps_full("pctopp", "rep", spons = FALSE); rep_m("pctopp rep PS distr+MV", m9)

cat("Column 5: PS district + MV + sponsor (Rep ncosp; Dem pct opposite)\n")
m4 <- ps_full("ncosp", "rep", spons = TRUE);  rep_m("ncosp rep PS distr+MV+spon", m4)
m7 <- ps_full("pctopp", "dem", spons = TRUE); rep_m("pctopp dem PS distr+MV+spon", m7)

cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.6f\n", cf(m1)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.6f\n", cf(m2)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.6f\n", cf(m3)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.6f\n", cf(m4)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.6f\n", cf(m5)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.6f\n", cf(m6)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.6f\n", cf(m7)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.6f\n", cf(m8)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.6f\n", cf(m9)))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", ncl_all))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", nobs(m5)))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", nobs(m8)))
