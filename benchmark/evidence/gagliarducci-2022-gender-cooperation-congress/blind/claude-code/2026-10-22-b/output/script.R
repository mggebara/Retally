# Gagliarducci & Paserman (2022) -- Table 5 (Panels A and B), independent blind reproduction
suppressMessages({library(haven); library(dplyr); library(fixest); library(rdrobust)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-10-22-b/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/"
b <- read_dta(paste0(D, "bills_analysis_101-111_replication.dta"))
b <- zap_labels(b)

# ---- sample: House public bills with a matched sponsor -------------------------------------
b <- b %>% filter(!is.na(sponsor_female))
b <- b %>% mutate(
  sid = paste(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served, sep = "_"),
  female = sponsor_female,
  rookie = as.numeric(sponsor_tenure_run == 1),
  leader = as.numeric(comc == 1 | comr == 1),
  party_f = factor(sponsor_party),
  # Census macro regions from ICPSR state codes (Northeast base)
  region = case_when(sponsor_state_icpsr < 20 ~ "NE", sponsor_state_icpsr < 40 ~ "MW",
                     sponsor_state_icpsr < 60 ~ "S", TRUE ~ "W"),
  reg_mw = as.numeric(region == "MW"), reg_s = as.numeric(region == "S"), reg_w = as.numeric(region == "W"),
  # lnarea is recorded in two different units (sq. miles vs sq. meters); harmonise to sq. miles
  lnarea_mi = ifelse(lnarea > 15, lnarea - log(2589988.11), lnarea),
  lnpopdens = lnpop - lnarea_mi,
  ncosp = numb_cosponsors,
  pctopp = 100 * pct_cosponsors_opposite,
  mv_winner = abs(MV1_democrat)
)
cat("lnarea >15 by Congress (diagnostic):\n"); print(table(b$v2, b$lnarea > 15))
b <- b %>% group_by(sid) %>% mutate(nbills_sponsored = n()) %>% ungroup()

com <- grep("^house_", names(b), value = TRUE)
billc <- paste(com, collapse = " + ")
sponc <- "sponsor_age + sponsor_tenure_run + rookie + leader + black + occ1 + occ2 + occ3 + occ4 + occ5 + ivycoll + borninstate + nbills_sponsored"
distc <- "reg_mw + reg_s + reg_w + pct_black + pct_age_over65 + pct_for_born + pct_urban + lninc + lnpopdens"

samp <- function(p) if (p == "all") b else if (p == "dem") filter(b, sponsor_party == 100) else filter(b, sponsor_party == 200)

# ---- Column 1: OLS full sample ----------------------------------------------------------------
ols <- function(y, p) {
  d <- samp(p)
  sc <- if (p == "all") paste(sponc, "+ party_f") else sponc
  f <- as.formula(paste(y, "~ female +", billc, "+", sc, "+", distc, "| v2 + minor"))
  m <- feols(f, data = d, cluster = ~sid)
  ids <- d$sid[obs(m)]
  list(b = unname(coef(m)["female"]), se = unname(se(m)["female"]), n = nobs(m), ncl = length(unique(ids)))
}

# ---- Columns 2/3: RD in mixed-gender races ------------------------------------------------------
rd <- function(y, p, h, ipw = FALSE) {
  d <- samp(p) %>% filter(mixed_gender_election == 1, !is.na(MV1_female), !is.na(.data[[y]]))
  bw <- tryCatch(rdbwselect(d[[y]], d$MV1_female, c = 0, bwselect = "mserd")$bws[1, 1], error = function(e) NA)
  cat(sprintf("  [diag] %s/%s CCT mserd bandwidth computed on bills: %.2f (paper's bandwidth used: %g)\n", y, p, bw, h))
  d <- d %>% filter(abs(MV1_female) <= h)
  w <- NULL
  if (ipw) {
    d <- d %>% filter(if_all(all.vars(as.formula(paste("~", distc))), ~ !is.na(.x)))
    ps <- glm(as.formula(paste("female ~", distc)), data = d, family = binomial(link = "probit"))
    d$p <- fitted(ps)
    d$w <- ifelse(d$female == 1, 1 / d$p, 1 / (1 - d$p))
    f <- as.formula(paste(y, "~ female + MV1_female + femaleXMV1_female +", billc, "| v2 + minor"))
    m <- feols(f, data = d, weights = ~w, cluster = ~sid)
  } else {
    f <- as.formula(paste(y, "~ female + MV1_female + femaleXMV1_female | v2"))
    m <- feols(f, data = d, cluster = ~sid)
  }
  list(b = unname(coef(m)["female"]), se = unname(se(m)["female"]), n = nobs(m))
}

# ---- Columns 4/5: IPW on full sample of races ---------------------------------------------------
ipw_full <- function(y, p, spons = FALSE) {
  d <- samp(p) %>% filter(!is.na(.data[[y]]))
  psf <- paste("female ~", distc, "+ mv_winner", if (spons) paste("+", sponc) else "")
  d <- d %>% filter(if_all(all.vars(as.formula(psf)), ~ !is.na(.x)))
  ps <- glm(as.formula(psf), data = d, family = binomial(link = "probit"))
  d$p <- fitted(ps)
  d$w <- ifelse(d$female == 1, 1 / d$p, 1 / (1 - d$p))
  f <- as.formula(paste(y, "~ female +", billc, "| v2 + minor"))
  m <- feols(f, data = d, weights = ~w, cluster = ~sid)
  list(b = unname(coef(m)["female"]), se = unname(se(m)["female"]), n = nobs(m))
}

rep <- function(nm, r) cat(sprintf("  [diag] %-45s b=%.4f se=%.4f n=%d\n", nm, r$b, r$se, r$n))

r1 <- ols("ncosp", "all");  rep("ncosp all ols", r1)
r2 <- ols("ncosp", "rep");  rep("ncosp rep ols", r2)
r3 <- rd("ncosp", "rep", 13, ipw = TRUE); rep("ncosp rep rd ipw (h=13)", r3)
r4 <- ipw_full("ncosp", "rep", spons = TRUE); rep("ncosp rep ipw distr+mv+spons", r4)
r5 <- ols("pctopp", "dem"); rep("pctopp dem ols", r5)
r6 <- rd("pctopp", "dem", 24, ipw = FALSE); rep("pctopp dem rd (h=24)", r6)
r7 <- ipw_full("pctopp", "dem", spons = TRUE); rep("pctopp dem ipw distr+mv+spons", r7)
r8 <- ols("pctopp", "rep"); rep("pctopp rep ols", r8)
r9 <- ipw_full("pctopp", "rep", spons = FALSE); rep("pctopp rep ipw distr+mv", r9)

cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.6f\n", r1$b))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.6f\n", r2$b))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.6f\n", r3$b))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.6f\n", r4$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.6f\n", r5$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.6f\n", r6$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.6f\n", r7$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.6f\n", r8$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.6f\n", r9$b))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", r1$n))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", r1$ncl))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", r5$n))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", r8$n))
cat("DEVIATION: percent of opposite-party cosponsors uses the dataset's pct_cosponsors_opposite (opposite/cosponsors, sponsor not in denominator) x100; propensity scores are probit at bill level with ATE inverse-probability weights; RD bandwidths are the ones stated for these rows (13, 24) with a uniform kernel.\n")
