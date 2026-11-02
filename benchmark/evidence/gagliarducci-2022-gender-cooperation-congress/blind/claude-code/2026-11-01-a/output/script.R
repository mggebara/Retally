## Gagliarducci & Paserman - Table 5 (independent, blind reproduction)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest); library(rdrobust)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-01-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta"
d <- zap_labels(read_dta(f))

comm <- grep("^house_", names(d), value = TRUE)
cat("n committee dummies:", length(comm), "\n")

d <- d %>% mutate(
  sp_id = paste(sponsor_state_abbrev, sponsor_district, sponsor_term_served, v2, sep = "_"),
  female = sponsor_female,
  rookie = as.numeric(sponsor_tenure_run == 1),
  leader = as.numeric(comc == 1 | comr == 1),
  dem = as.numeric(sponsor_party == 100),
  rep = as.numeric(sponsor_party == 200),
  region = case_when(sponsor_state_icpsr < 20 ~ "NE", sponsor_state_icpsr < 40 ~ "MW",
                     sponsor_state_icpsr < 60 ~ "S", TRUE ~ "W"),
  reg_mw = as.numeric(region == "MW"), reg_s = as.numeric(region == "S"), reg_w = as.numeric(region == "W"),
  lndens = lnpop - lnarea,
  mv_elected = abs(MV1_democrat),
  y_n = numb_cosponsors,
  y_pct = 100 * pct_cosponsors_opposite,
  minor_f = factor(minor)
)
d <- d %>% filter(!is.na(sponsor_female)) %>% group_by(sp_id) %>% mutate(nbills = n()) %>% ungroup()
# Public bills only (private-issue bills excluded; private is 0 or missing)
d <- d %>% filter(is.na(private) | private == 0)

chk <- d %>% filter(!is.na(pct_cosponsors_opposite)) %>%
  mutate(alt = numb_cosponsors_opposite / (numb_cosponsors + 1))
cat("pct_opposite vs opp/(n+1): max abs diff", max(abs(chk$alt - chk$pct_cosponsors_opposite)), "; corr", cor(chk$alt, chk$pct_cosponsors_opposite), "\n")
cat("pct missing when n=0:", sum(is.na(d$pct_cosponsors_opposite) & d$y_n == 0, na.rm=TRUE), "of", sum(is.na(d$pct_cosponsors_opposite)), "\n")

spons_x <- c("sponsor_age", "sponsor_tenure_run", "rookie", "leader", "black",
             "occ1", "occ2", "occ3", "occ4", "occ5", "ivycoll", "borninstate", "nbills")
distr_x <- c("reg_mw", "reg_s", "reg_w", "pct_black", "pct_age_over65", "pct_for_born", "pct_urban", "lninc", "lndens")
bill_x <- comm

subs <- list(all = function(x) x %>% filter(sponsor_party %in% c(100, 200, 328)),
             dem = function(x) x %>% filter(dem == 1),
             rep = function(x) x %>% filter(rep == 1))

ols_fit <- function(y, grp) {
  s <- subs[[grp]](d)
  sx <- spons_x; if (grp == "all") sx <- c(sx, "dem")
  fml <- as.formula(paste(y, "~ female +", paste(c(sx, distr_x, bill_x), collapse = " + "), "| v2 + minor_f"))
  feols(fml, data = s, cluster = ~sp_id, fixef.rm = "singleton")
}

## propensity score at race (sponsor-Congress) level
ps_weights <- function(s, xs, congress_fe = TRUE) {
  r <- s %>% group_by(sp_id) %>% slice(1) %>% ungroup()
  r <- r[complete.cases(r[, c("female", xs)]), ]
  fml <- as.formula(paste("female ~", paste(xs, collapse = " + "), if (congress_fe) "+ factor(v2)" else ""))
  m <- glm(fml, data = r, family = binomial())
  r$ps <- predict(m, type = "response")
  r$w <- ifelse(r$female == 1, 1 / r$ps, 1 / (1 - r$ps))
  cat(sprintf("  PS: races=%d, treated=%d, ps range [%.4f, %.4f]\n", nrow(r), sum(r$female), min(r$ps), max(r$ps)))
  s %>% inner_join(r %>% select(sp_id, w), by = "sp_id")
}

ipw_fit <- function(y, grp, with_sponsor) {
  s <- subs[[grp]](d)
  xs <- c(distr_x, "mv_elected")
  if (with_sponsor) xs <- c(xs, spons_x)
  if (grp == "all") xs <- c(xs, "dem")
  s <- ps_weights(s, xs, TRUE)
  fml <- as.formula(paste(y, "~ female +", paste(bill_x, collapse = " + "), "| v2 + minor_f"))
  feols(fml, data = s, weights = ~w, cluster = ~sp_id, fixef.rm = "singleton")
}

rd_sample <- function(y, grp) {
  subs[[grp]](d) %>% filter(mixed_gender_election == 1, !is.na(MV1_female), !is.na(.data[[y]]))
}
rd_bw <- function(y, grp) {
  s <- rd_sample(y, grp)
  b <- rdbwselect(s[[y]], s$MV1_female, c = 0, p = 1, bwselect = "mserd", vce = "nn")
  as.numeric(b$bws[1, 1])
}
rd_fit <- function(y, grp, h, ipw) {
  s <- rd_sample(y, grp) %>% filter(abs(MV1_female) <= h) %>% mutate(fXmv = female * MV1_female)
  if (!ipw) {
    return(feols(as.formula(paste(y, "~ female + MV1_female + fXmv | v2")), data = s, cluster = ~sp_id))
  }
  s <- ps_weights(s, distr_x, FALSE)
  fml <- as.formula(paste(y, "~ female + MV1_female + fXmv +", paste(bill_x, collapse = " + "), "| v2 + minor_f"))
  feols(fml, data = s, weights = ~w, cluster = ~sp_id, fixef.rm = "singleton")
}

co <- function(m) unname(coef(m)["female"])
res <- list()

## OLS (col 1)
m1 <- ols_fit("y_n", "all")
dd_all <- subs$all(d)
n_cl_all <- length(unique(dd_all$sp_id[obs(m1)]))
res$female_sponsor_ncosponsors_all_ols <- co(m1)
res$n_bills_ncosponsors_all_ols <- nobs(m1)
res$n_sponsor_terms_ncosponsors_all_ols <- n_cl_all
cat("OLS all ncosp: N", nobs(m1), "clusters", n_cl_all, "\n")

m2 <- ols_fit("y_n", "rep"); res$female_sponsor_ncosponsors_rep_ols <- co(m2)
m5 <- ols_fit("y_pct", "dem"); res$female_sponsor_pct_opposite_dem_ols <- co(m5)
res$n_bills_pct_opposite_dem_ols <- nobs(m5)
m8 <- ols_fit("y_pct", "rep"); res$female_sponsor_pct_opposite_rep_ols <- co(m8)
res$n_bills_pct_opposite_rep_ols <- nobs(m8)

## bandwidths (diagnostic) and RD
bw_rep_n <- rd_bw("y_n", "rep"); bw_dem_pct <- rd_bw("y_pct", "dem")
cat(sprintf("computed CCT mserd bw: rep ncosp %.2f ; dem pct %.2f (paper states 13 and 24)\n", bw_rep_n, bw_dem_pct))
# use the bandwidths stated for these rows in the task description
cat("RD rep ncosp IPW:\n")
m3 <- rd_fit("y_n", "rep", 13, TRUE); res$female_sponsor_ncosponsors_rep_rd_ipw <- co(m3)
m6 <- rd_fit("y_pct", "dem", 24, FALSE); res$female_sponsor_pct_opposite_dem_rd <- co(m6)

## IPW full sample
cat("IPW rep ncosp sponsor:\n"); m4 <- ipw_fit("y_n", "rep", TRUE); res$female_sponsor_ncosponsors_rep_ipw_sponsor <- co(m4)
cat("IPW dem pct sponsor:\n"); m7 <- ipw_fit("y_pct", "dem", TRUE); res$female_sponsor_pct_opposite_dem_ipw_sponsor <- co(m7)
cat("IPW rep pct district:\n"); m9 <- ipw_fit("y_pct", "rep", FALSE); res$female_sponsor_pct_opposite_rep_ipw_district <- co(m9)

for (nm in c("m1","m2","m3","m4","m5","m6","m7","m8","m9")) {
  m <- get(nm); cat(sprintf("%s b=%.4f se=%.4f N=%d\n", nm, co(m), se(m)["female"], nobs(m)))
}

ord <- c("female_sponsor_ncosponsors_all_ols", "female_sponsor_ncosponsors_rep_ols",
         "female_sponsor_ncosponsors_rep_rd_ipw", "female_sponsor_ncosponsors_rep_ipw_sponsor",
         "female_sponsor_pct_opposite_dem_ols", "female_sponsor_pct_opposite_dem_rd",
         "female_sponsor_pct_opposite_dem_ipw_sponsor", "female_sponsor_pct_opposite_rep_ols",
         "female_sponsor_pct_opposite_rep_ipw_district", "n_bills_ncosponsors_all_ols",
         "n_sponsor_terms_ncosponsors_all_ols", "n_bills_pct_opposite_dem_ols", "n_bills_pct_opposite_rep_ols")
for (nm in ord) cat(sprintf("RESULT:%s=%s\n", nm, format(res[[nm]], digits = 10)))
