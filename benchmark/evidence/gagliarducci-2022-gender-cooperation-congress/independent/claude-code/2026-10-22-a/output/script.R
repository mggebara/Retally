## Independent reproduction of Gagliarducci & Paserman, Table 5 (selected cells)
suppressMessages({library(haven); library(dplyr); library(fixest); library(rdrobust)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-10-22-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/"
b <- read_dta(paste0(D, "bills_analysis_101-111_replication.dta"))
b <- zap_labels(b)

comm <- grep("^house_", names(b), value = TRUE)
cat("n committee dummies:", length(comm), "\n")

## ---- variable construction ----
b <- b %>%
  mutate(
    sc_id     = paste(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served, sep = "_"),
    female    = sponsor_female,
    rookie    = as.numeric(sponsor_tenure_run == 1),
    leader    = as.numeric(comc == 1 | comr == 1),
    republican = as.numeric(sponsor_party == 200),
    region    = case_when(sponsor_state_icpsr <= 14 ~ "NE",
                          sponsor_state_icpsr <= 37 ~ "MW",
                          sponsor_state_icpsr <= 56 ~ "S",
                          TRUE ~ "W"),
    lndens    = lnpop - lnarea,
    ncosp     = numb_cosponsors,
    # percent of cosponsors from opposite party, in percentage points; 0 for bills w/o cosponsors
    pctopp    = 100 * ifelse(!is.na(numb_cosponsors) & numb_cosponsors == 0, 0, pct_cosponsors_opposite),
    absmv     = abs(MV1_democrat),
    minor_f   = factor(minor)
  )
b <- b %>% group_by(sc_id) %>% mutate(nbills_sponsored = n()) %>% ungroup()
b$nbills_sponsored[is.na(b$sponsor_female)] <- NA

spons <- c("sponsor_age", "sponsor_tenure_run", "rookie", "leader", "black", "republican",
           paste0("occ", 1:5), "ivycoll", "borninstate", "nbills_sponsored")
distr <- c("i(region)", "pct_black", "pct_age_over65", "pct_for_born", "pct_urban", "lninc", "lndens")
distr_raw <- c("region", "pct_black", "pct_age_over65", "pct_for_born", "pct_urban", "lninc", "lndens")
billc <- c(comm, "minor_f")

subs <- list(all = function(d) d,
             dem = function(d) filter(d, sponsor_party == 100),
             rep = function(d) filter(d, sponsor_party == 200))

res <- list()
put <- function(name, val) { res[[name]] <<- val }

coef_f <- function(m) unname(coef(m)["female"])

## ---- Column 1: OLS full sample ----
ols <- function(d, y) {
  sp <- spons
  if (length(unique(d$republican[!is.na(d$republican)])) < 2) sp <- setdiff(sp, "republican")
  f <- as.formula(paste(y, "~ female +", paste(c(sp, distr, comm), collapse = " + "), "| v2 + minor_f"))
  feols(f, data = d, cluster = ~sc_id)
}

## ---- Columns 2/3: RD within bandwidth ----
rd_bw <- function(d, y) {
  dd <- d %>% filter(mixed_gender_election == 1, !is.na(MV1_female), !is.na(.data[[y]]))
  bw <- tryCatch(rdbwselect(dd[[y]], dd$MV1_female, c = 0, bwselect = "mserd")$bws[1, 1],
                 error = function(e) NA)
  bw
}
rd_est <- function(d, y, h, ipw = FALSE) {
  dd <- d %>% filter(mixed_gender_election == 1, !is.na(MV1_female), abs(MV1_female) <= h,
                     !is.na(.data[[y]]), !is.na(female))
  if (!ipw) {
    f <- as.formula(paste(y, "~ female + MV1_female + female:MV1_female | v2"))
    m <- feols(f, data = dd, cluster = ~sc_id)
  } else {
    pf <- as.formula(paste("female ~", paste(distr_raw, collapse = " + ")))
    dd <- dd %>% filter(if_all(all_of(c(distr_raw, comm, "minor")), ~ !is.na(.)))
    ps <- glm(pf, data = dd, family = binomial())
    p  <- fitted(ps)
    dd$w <- ifelse(dd$female == 1, 1 / p, 1 / (1 - p))
    f <- as.formula(paste(y, "~ female + MV1_female + female:MV1_female +", paste(comm, collapse = " + "), "| v2 + minor_f"))
    m <- feols(f, data = dd, weights = ~w, cluster = ~sc_id)
  }
  m
}

## ---- Columns 4/5: IPW full sample ----
ipw_est <- function(d, y, with_spons) {
  sp <- spons
  if (length(unique(d$republican[!is.na(d$republican)])) < 2) sp <- setdiff(sp, "republican")
  xs <- c(distr_raw, "absmv", if (with_spons) sp)
  dd <- d %>% filter(if_all(all_of(c(xs, y, "female", comm, "minor")), ~ !is.na(.)))
  pf <- as.formula(paste("female ~", paste(xs, collapse = " + ")))
  ps <- glm(pf, data = dd, family = binomial())
  p  <- fitted(ps)
  dd$w <- ifelse(dd$female == 1, 1 / p, 1 / (1 - p))
  f <- as.formula(paste(y, "~ female +", paste(comm, collapse = " + "), "| v2 + minor_f"))
  feols(f, data = dd, weights = ~w, cluster = ~sc_id)
}

paper_bw <- list(ncosp = c(all = 25, dem = 30, rep = 13), pctopp = c(all = 16, dem = 24, rep = 11))

for (y in c("ncosp", "pctopp")) {
  for (g in names(subs)) {
    d <- subs[[g]](b)
    m1 <- ols(d, y)
    cat(sprintf("[%s %s] OLS: b=%.3f se=%.3f N=%d clusters=%d\n", y, g, coef_f(m1), se(m1)["female"], nobs(m1),
                length(unique(d$sc_id[obs(m1)]))))
    bwc <- rd_bw(d, y)
    h <- paper_bw[[y]][[g]]
    m2 <- rd_est(d, y, h, FALSE); m3 <- rd_est(d, y, h, TRUE)
    cat(sprintf("[%s %s] CCT bw (bill-level, mserd)=%.2f ; using paper bw=%g\n", y, g, bwc, h))
    cat(sprintf("[%s %s] RD: b=%.3f se=%.3f N=%d | RD-IPW: b=%.3f se=%.3f N=%d\n", y, g,
                coef_f(m2), se(m2)["female"], nobs(m2), coef_f(m3), se(m3)["female"], nobs(m3)))
    m4 <- ipw_est(d, y, FALSE); m5 <- ipw_est(d, y, TRUE)
    cat(sprintf("[%s %s] IPW distr+MV: b=%.3f se=%.3f N=%d | IPW +spons: b=%.3f se=%.3f N=%d\n", y, g,
                coef_f(m4), se(m4)["female"], nobs(m4), coef_f(m5), se(m5)["female"], nobs(m5)))
    key <- paste(y, g, sep = "_")
    res[[key]] <- list(ols = m1, rd = m2, rdipw = m3, ipwd = m4, ipws = m5, d = d)
  }
}

nclus <- function(r) { m <- r$ols; length(unique(r$d$sc_id[obs(m)])) }

cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.4f\n", coef_f(res$ncosp_all$ols)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.4f\n", coef_f(res$ncosp_rep$ols)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.4f\n", coef_f(res$ncosp_rep$rdipw)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.4f\n", coef_f(res$ncosp_rep$ipws)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.4f\n", coef_f(res$pctopp_dem$ols)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.4f\n", coef_f(res$pctopp_dem$rd)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.4f\n", coef_f(res$pctopp_dem$ipws)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.4f\n", coef_f(res$pctopp_rep$ols)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.4f\n", coef_f(res$pctopp_rep$ipwd)))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", nobs(res$ncosp_all$ols)))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", nclus(res$ncosp_all)))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", nobs(res$pctopp_dem$ols)))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", nobs(res$pctopp_rep$ols)))
