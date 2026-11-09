# Independent reproduction: Gagliarducci & Paserman (2022), Table 5 (selected cells)
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest); library(rdrobust)})

f <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-07-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta"
d <- zap_labels(read_dta(f))

# ---- variable construction ----
d <- d %>% group_by(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served) %>%
  mutate(nbills = n(), clus = cur_group_id()) %>% ungroup()
d$clus[is.na(d$sponsor_female)] <- NA
d$female  <- d$sponsor_female
d$ncosp   <- d$numb_cosponsors
# percent of supporters (cosponsors + sponsor) from opposite party (paper fn. 11)
d$pctopp  <- 100 * d$numb_cosponsors_opposite / (d$numb_cosponsors + 1)
d$pctopp[!is.na(d$numb_cosponsors) & d$numb_cosponsors_opposite > d$numb_cosponsors] <- NA  # inconsistent records
d$rookie  <- as.numeric(d$sponsor_tenure_run == 1)
d$leader  <- as.numeric(d$comc == 1 | d$comr == 1)
d$party   <- factor(d$sponsor_party)
s <- d$sponsor_state_icpsr
d$reg_mw  <- as.numeric(s >= 21 & s <= 37)
d$reg_s   <- as.numeric(s >= 40 & s <= 56)
d$reg_w   <- as.numeric(s >= 61)
d$lndens  <- d$lnpop - d$lnarea
d$absmv   <- abs(d$MV1_democrat)
d$minor   <- factor(d$minor)

comm  <- grep("^house_", names(d), value = TRUE)
sponv <- c("sponsor_age","sponsor_tenure_run","rookie","leader","black","party",
           "occ1","occ2","occ3","occ4","occ5","ivycoll","borninstate","nbills")
distv <- c("reg_mw","reg_s","reg_w","pct_black","pct_age_over65","pct_for_born","pct_urban","lninc","lndens")
billrhs <- paste(comm, collapse = " + ")

samp <- function(dd, party) if (party == "all") dd else dd[!is.na(dd$sponsor_party) & dd$sponsor_party == party, ]
pnum <- c(all = "all", dem = 100, rep = 200)

# ---- column 1: OLS full controls ----
ols <- function(y, party) {
  dd <- samp(d, pnum[[party]])
  sp <- if (party == "all") sponv else setdiff(sponv, "party")
  fml <- as.formula(paste(y, "~ female +", billrhs, "+", paste(c(sp, distv), collapse = " + "), "| v2 + minor"))
  feols(fml, data = dd, cluster = ~clus)
}

# ---- column 2/3: RD within bandwidth, (3) with IPW on district chars and bill chars ----
rd <- function(y, party, h, ipw = FALSE) {
  dd <- samp(d, pnum[[party]])
  dd <- dd[!is.na(dd$mixed_gender_election) & dd$mixed_gender_election == 1 & !is.na(dd$MV1_female) &
           abs(dd$MV1_female) <= h & !is.na(dd[[y]]), ]
  if (!ipw) {
    m <- feols(as.formula(paste(y, "~ female + MV1_female + female:MV1_female | v2")), data = dd, cluster = ~clus)
  } else {
    dd <- dd[complete.cases(dd[, distv]), ]
    ps <- glm(as.formula(paste("female ~", paste(distv, collapse = " + "))), data = dd, family = binomial())
    p  <- fitted(ps)
    dd$w <- ifelse(dd$female == 1, 1 / p, 1 / (1 - p))
    m <- feols(as.formula(paste(y, "~ female + MV1_female + female:MV1_female +", billrhs, "| v2 + minor")),
               data = dd, weights = ~w, cluster = ~clus)
  }
  m
}

# optimal bandwidth (CCT 2014, bill-level observations), reported as a diagnostic
bw <- function(y, party) {
  dd <- samp(d, pnum[[party]])
  dd <- dd[!is.na(dd$mixed_gender_election) & dd$mixed_gender_election == 1 & !is.na(dd$MV1_female) & !is.na(dd[[y]]), ]
  b <- rdbwselect(dd[[y]], dd$MV1_female, c = 0, bwselect = "mserd")
  b$bws[1, 1]
}

# ---- columns 4/5: IPW on full sample; PS from district + MV (+ sponsor chars) ----
psw <- function(y, party, withspon) {
  dd <- samp(d, pnum[[party]])
  sp <- if (party == "all") sponv else setdiff(sponv, "party")
  xv <- c(distv, "absmv", if (withspon) sp)
  need <- c(y, "female", "v2", "minor", comm, xv, if (withspon) sp)
  dd <- dd[complete.cases(dd[, unique(need)]), ]
  ps <- glm(as.formula(paste("female ~", paste(xv, collapse = " + "))), data = dd, family = binomial())
  p  <- fitted(ps)
  dd$w <- ifelse(dd$female == 1, 1 / p, 1 / (1 - p))
  feols(as.formula(paste(y, "~ female +", billrhs, "| v2 + minor")), data = dd, weights = ~w, cluster = ~clus)
}

co <- function(m) unname(coef(m)["female"])

m_all_n <- ols("ncosp", "all")
m_rep_n <- ols("ncosp", "rep")
m_dem_p <- ols("pctopp", "dem")
m_rep_p <- ols("pctopp", "rep")

cat("Diagnostics (not scored):\n")
cat("OLS all ncosp: N =", nobs(m_all_n), " clusters =", fitstat(m_all_n, "g")[[1]], "\n")
cat("OLS dem pctopp: N =", nobs(m_dem_p), "; OLS rep pctopp: N =", nobs(m_rep_p), "; OLS rep ncosp N =", nobs(m_rep_n), "\n")
cat("CCT mserd bandwidth rep ncosp:", bw("ncosp", "rep"), " dem pctopp:", bw("pctopp", "dem"), "\n")

r_rep_n_ipw <- rd("ncosp", "rep", 13, ipw = TRUE)
r_dem_p     <- rd("pctopp", "dem", 24)
p_rep_n_5   <- psw("ncosp", "rep", TRUE)
p_dem_p_5   <- psw("pctopp", "dem", TRUE)
p_rep_p_4   <- psw("pctopp", "rep", FALSE)
cat("RD rep ncosp IPW N =", nobs(r_rep_n_ipw), "; RD dem pctopp N =", nobs(r_dem_p),
    "; PS5 rep ncosp N =", nobs(p_rep_n_5), "; PS5 dem pctopp N =", nobs(p_dem_p_5), "; PS4 rep pctopp N =", nobs(p_rep_p_4), "\n")
for (nm in c("m_all_n","m_rep_n","m_dem_p","m_rep_p","r_rep_n_ipw","r_dem_p","p_rep_n_5","p_dem_p_5","p_rep_p_4")) {
  m <- get(nm); cat(sprintf("%-12s coef=%8.3f se=%7.3f\n", nm, co(m), se(m)["female"]))
}

cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.4f\n", co(m_all_n)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.4f\n", co(m_rep_n)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.4f\n", co(r_rep_n_ipw)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.4f\n", co(p_rep_n_5)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.4f\n", co(m_dem_p)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.4f\n", co(r_dem_p)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.4f\n", co(p_dem_p_5)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.4f\n", co(m_rep_p)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.4f\n", co(p_rep_p_4)))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", nobs(m_all_n)))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", as.integer(fitstat(m_all_n, "g")[[1]])))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", nobs(m_dem_p)))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", nobs(m_rep_p)))
