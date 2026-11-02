suppressMessages({library(data.table); library(fixest); library(rdrobust)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-01-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv"
d <- fread(f)

# ---- construct variables ----
d <- d[!is.na(sponsor_female)]
d[, sid := paste(v2, sponsor_name, sponsor_state_abbrev, sponsor_district, sep = "|")]   # sponsor-Congress cluster
d[, nbills := .N, by = sid]                                    # total bills sponsored in the Congress
d[, rookie := as.integer(sponsor_tenure_run == 1)]
d[, leader := as.integer(comc == 1 | comr == 1)]
d[, republican := as.integer(sponsor_party == 200)]
d[, independent := as.integer(sponsor_party == 328)]
s <- d$sponsor_state_icpsr
d[, region := fifelse(s <= 14, "NE", fifelse(s <= 37, "MW", fifelse(s <= 56, "S", "W")))]
d[, lndens := lnpop - lnarea]
d[, pct_opp := 100 * fifelse(numb_cosponsors == 0, 0, pct_cosponsors_opposite)]
d[!is.na(pct_opp) & pct_opp > 100, pct_opp := NA]             # fractions above 1 are data errors
d[, mv_elected := 100 * abs(MV1_democrat)]                    # margin of victory of elected candidate
d[, minor := factor(minor)]
d[, cong := factor(v2)]
cat("pct_opp > 100 set NA:", sum(is.na(d$pct_opp)), "\n")
cat("occ row sums:\n"); print(table(rowSums(d[, paste0("occ", 0:6), with = FALSE])))

hc <- grep("^house_", names(d), value = TRUE)
bill_x <- c(hc)
spons_x <- c("sponsor_age", "sponsor_tenure_run", "rookie", "leader", "black", "republican", "independent",
             paste0("occ", 1:5), "ivycoll", "borninstate", "nbills")
distr_x <- c("i(region)", "pct_black", "pct_age_over65", "pct_for_born", "pct_urban", "lninc", "lndens")
distr_plain <- c("region", "pct_black", "pct_age_over65", "pct_for_born", "pct_urban", "lninc", "lndens")
spons_plain <- spons_x

fml <- function(y, x) as.formula(paste(y, "~", paste(x, collapse = " + "), "| cong + minor"))

run_ols <- function(y, dd) {
  feols(fml(y, c("sponsor_female", bill_x, spons_x, distr_x)), data = dd, cluster = ~sid)
}

party_sub <- function(p) if (p == "all") d else if (p == "dem") d[sponsor_party == 100] else d[sponsor_party == 200]
show <- function(lab, m, dd) {
  ct <- coeftable(m)["sponsor_female", ]
  used <- dd[obs(m)]
  cat(sprintf("%-42s b=%8.3f se=%7.3f n=%6d sponsors=%5d\n", lab, ct[1], ct[2], nobs(m), uniqueN(used$sid)))
  invisible(list(b = unname(ct[1]), n = nobs(m), ns = uniqueN(used$sid)))
}

res <- list()
# ---- Column 1: OLS ----
for (p in c("all", "dem", "rep")) for (y in c("numb_cosponsors", "pct_opp")) {
  dd <- party_sub(p)
  m <- run_ols(y, dd)
  res[[paste("ols", p, y)]] <- show(paste("OLS", p, y), m, dd)
}

# ---- RD helpers ----
rd_data <- function(p, y) {
  dd <- party_sub(p)[mixed_gender_election == 1 & !is.na(MV1_female) & !is.na(get(y))]
  dd
}
rd_bw <- function(dd, y) {
  b <- tryCatch(rdbwselect(dd[[y]], dd$MV1_female, c = 0, p = 1, bwselect = "mserd")$bws[1, 1], error = function(e) NA)
  b
}
# paper-reported optimal bandwidths (Table 5)
bw_paper <- list("rep numb_cosponsors" = 13, "dem pct_opp" = 24, "all numb_cosponsors" = 25,
                 "dem numb_cosponsors" = 30, "all pct_opp" = 16, "rep pct_opp" = 11)

run_rd <- function(p, y, ipw = FALSE) {
  dd <- rd_data(p, y)
  h_cct <- rd_bw(dd, y)
  h <- bw_paper[[paste(p, y)]]
  cat(sprintf("RD %s %s: CCT bandwidth computed=%.2f, paper=%d\n", p, y, h_cct, h))
  dd <- dd[abs(MV1_female) <= h]
  if (!ipw) {
    m <- feols(as.formula(paste(y, "~ sponsor_female + MV1_female + femaleXMV1_female | cong")), data = dd, cluster = ~sid)
  } else {
    ps <- feglm(as.formula(paste("sponsor_female ~", paste(distr_x, collapse = "+"), "| cong")),
                data = dd, family = binomial("logit"))
    dd <- dd[obs(ps)]
    dd[, ps := fitted(ps)]
    dd[, w := fifelse(sponsor_female == 1, 1 / ps, 1 / (1 - ps))]
    m <- feols(fml(y, c("sponsor_female", "MV1_female", "femaleXMV1_female", bill_x)), data = dd,
               weights = ~w, cluster = ~sid)
  }
  show(paste(if (ipw) "RD-IPW" else "RD", p, y), m, dd)
}

# ---- PS weighting on full sample ----
run_ps <- function(p, y, with_sponsor = FALSE) {
  dd <- party_sub(p)[!is.na(get(y)) & !is.na(mv_elected)]
  xs <- c(distr_x, "mv_elected")
  if (with_sponsor) xs <- c(xs, spons_x)
  ps <- feglm(as.formula(paste("sponsor_female ~", paste(xs, collapse = "+"), "| cong")),
              data = dd, family = binomial("logit"))
  dd <- dd[obs(ps)]
  dd[, ps := fitted(ps)]
  dd[, w := fifelse(sponsor_female == 1, 1 / ps, 1 / (1 - ps))]
  m <- feols(fml(y, c("sponsor_female", bill_x)), data = dd, weights = ~w, cluster = ~sid)
  show(paste(if (with_sponsor) "PS distr+MV+spons" else "PS distr+MV", p, y), m, dd)
}

r_rd_dem_pct   <- run_rd("dem", "pct_opp")
r_rdipw_rep_nc <- run_rd("rep", "numb_cosponsors", ipw = TRUE)
r_ps4_rep_pct  <- run_ps("rep", "pct_opp", FALSE)
r_ps5_rep_nc   <- run_ps("rep", "numb_cosponsors", TRUE)
r_ps5_dem_pct  <- run_ps("dem", "pct_opp", TRUE)

cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.4f\n", res[["ols all numb_cosponsors"]]$b))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.4f\n", res[["ols rep numb_cosponsors"]]$b))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.4f\n", r_rdipw_rep_nc$b))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.4f\n", r_ps5_rep_nc$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.4f\n", res[["ols dem pct_opp"]]$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.4f\n", r_rd_dem_pct$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.4f\n", r_ps5_dem_pct$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.4f\n", res[["ols rep pct_opp"]]$b))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.4f\n", r_ps4_rep_pct$b))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", res[["ols all numb_cosponsors"]]$n))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", res[["ols all numb_cosponsors"]]$ns))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", res[["ols dem pct_opp"]]$n))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", res[["ols rep pct_opp"]]$n))
cat("DEVIATION: RD bandwidths fixed at the paper-reported CCT optimal bandwidths (CCT bandwidths recomputed and printed for reference)\n")
