# Retally independent + blind reproduction: Gagliarducci & Paserman, Table 5 (selected cells)
suppressMessages({library(haven); library(dplyr); library(fixest); library(rdrobust)})
set.seed(42)
R <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-02-c/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/"
b <- read_dta(paste0(R, "AnalysisData/bills_analysis_101-111_replication.dta"))
b <- zap_labels(b)

# ---- sample: public House bills with sponsor information ----
b <- b %>% filter(is.na(private) | private == 0, !is.na(sponsor_female))

# ---- variable construction ----
ne <- c("CT","ME","MA","NH","RI","VT","NJ","NY","PA")
mw <- c("IL","IN","MI","OH","WI","IA","KS","MN","MO","NE","ND","SD")
so <- c("DE","DC","FL","GA","MD","NC","SC","VA","WV","AL","KY","MS","TN","AR","LA","OK","TX")
we <- c("AZ","CO","ID","MT","NV","NM","UT","WY","AK","CA","HI","OR","WA")
b <- b %>% mutate(
  sid = paste(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served, sep = "_"),
  female = sponsor_female,
  rookie = as.numeric(sponsor_tenure_run == 1),
  leader = as.numeric(comc == 1 | comr == 1),
  party = factor(sponsor_party),
  reg_mw = as.numeric(sponsor_state_abbrev %in% mw),
  reg_so = as.numeric(sponsor_state_abbrev %in% so),
  reg_we = as.numeric(sponsor_state_abbrev %in% we),
  reg_ok = sponsor_state_abbrev %in% c(ne, mw, so, we),
  lnpopdens = lnpop - lnarea,
  ncosp = numb_cosponsors,
  pctopp = 100 * pct_cosponsors_opposite,
  mv_winner = abs(MV1_democrat),
  minor = factor(minor)
)
b <- b %>% group_by(sid) %>% mutate(totbills = n()) %>% ungroup()
b$reg_mw[!b$reg_ok] <- NA; b$reg_so[!b$reg_ok] <- NA; b$reg_we[!b$reg_ok] <- NA

comm <- grep("^house_", names(b), value = TRUE)
spons <- c("sponsor_age", "sponsor_tenure_run", "rookie", "leader", "black",
           paste0("occ", 1:5), "ivycoll", "borninstate", "totbills")
distr <- c("reg_mw", "reg_so", "reg_we", "pct_black", "pct_age_over65", "pct_for_born",
           "pct_urban", "lninc", "lnpopdens")

cc <- function(d, vars) d[stats::complete.cases(as.data.frame(d)[, vars]), ]

# ---- Column 1: OLS full sample ----
ols <- function(d, y, pooled) {
  sp <- if (pooled) c(spons, "party") else spons
  vars <- c(y, "female", sp, distr, comm, "v2", "minor", "sid")
  d <- cc(d, vars)
  f <- as.formula(paste(y, "~ female +", paste(c(sp, distr, comm), collapse = " + "), "| v2 + minor"))
  m <- feols(f, data = d, cluster = ~sid, fixef.rm = "singleton")
  used <- d[obs(m), ]
  list(b = unname(coef(m)["female"]), se = unname(se(m)["female"]), n = nobs(m),
       ncl = length(unique(used$sid)))
}

# ---- Column 2/3: RD within bandwidth h (uniform kernel, linear, separate slopes) ----
rd <- function(d, y, h, ipw = FALSE, billchar = FALSE) {
  d <- d %>% filter(mixed_gender_election == 1, !is.na(MV1_female), abs(MV1_female) <= h)
  vars <- c(y, "female", "MV1_female", "v2", "sid")
  if (billchar) vars <- c(vars, comm, "minor")
  if (ipw) vars <- c(vars, distr)
  d <- cc(d, vars)
  d$fxmv <- d$female * d$MV1_female
  rhs <- "female + MV1_female + fxmv"
  if (billchar) rhs <- paste(rhs, "+", paste(comm, collapse = " + "))
  fe <- if (billchar) "| v2 + minor" else "| v2"
  if (ipw) {
    ps <- glm(as.formula(paste("female ~", paste(distr, collapse = " + "))), data = d,
              family = binomial("logit"))
    p <- fitted(ps)
    d$w <- ifelse(d$female == 1, 1 / p, 1 / (1 - p))
    m <- feols(as.formula(paste(y, "~", rhs, fe)), data = d, weights = ~w, cluster = ~sid,
               fixef.rm = "singleton")
  } else {
    m <- feols(as.formula(paste(y, "~", rhs, fe)), data = d, cluster = ~sid, fixef.rm = "singleton")
  }
  list(b = unname(coef(m)["female"]), se = unname(se(m)["female"]), n = nobs(m))
}

# CCT (rdrobust mserd) bandwidth on bill-level observations, for information only
cct_bw <- function(d, y) {
  d <- d %>% filter(mixed_gender_election == 1, !is.na(MV1_female), !is.na(.data[[y]]))
  bw <- rdbwselect(y = d[[y]], x = d$MV1_female, c = 0, p = 1, kernel = "triangular",
                   bwselect = "mserd")
  bw$bws[1, 1]
}

# ---- Columns 4/5: IPW full sample ----
ipw_full <- function(d, y, with_spons) {
  psv <- c(distr, "mv_winner", if (with_spons) spons)
  vars <- c(y, "female", psv, comm, "v2", "minor", "sid")
  d <- cc(d, vars)
  ps <- glm(as.formula(paste("female ~", paste(psv, collapse = " + "))), data = d,
            family = binomial("logit"))
  p <- fitted(ps)
  d$w <- ifelse(d$female == 1, 1 / p, 1 / (1 - p))
  f <- as.formula(paste(y, "~ female +", paste(comm, collapse = " + "), "| v2 + minor"))
  m <- feols(f, data = d, weights = ~w, cluster = ~sid, fixef.rm = "singleton")
  list(b = unname(coef(m)["female"]), se = unname(se(m)["female"]), n = nobs(m))
}

dem <- b %>% filter(sponsor_party == 100)
rep <- b %>% filter(sponsor_party == 200)

r1 <- ols(b, "ncosp", TRUE)
r2 <- ols(rep, "ncosp", FALSE)
r3 <- rd(rep, "ncosp", h = 13, ipw = TRUE, billchar = TRUE)
r4 <- ipw_full(rep, "ncosp", TRUE)
r5 <- ols(dem, "pctopp", FALSE)
r6 <- rd(dem, "pctopp", h = 24, ipw = FALSE, billchar = FALSE)
r7 <- ipw_full(dem, "pctopp", TRUE)
r8 <- ols(rep, "pctopp", FALSE)
r9 <- ipw_full(rep, "pctopp", FALSE)

bw_rep_n <- tryCatch(cct_bw(rep, "ncosp"), error = function(e) NA)
bw_dem_p <- tryCatch(cct_bw(dem, "pctopp"), error = function(e) NA)
cat(sprintf("INFO: rdrobust mserd bandwidth (bill level): rep ncosp = %.2f; dem pctopp = %.2f (paper-stated 13 and 24 used)\n",
            bw_rep_n, bw_dem_p))
show <- function(nm, r) cat(sprintf("INFO: %-45s b=%.4f se=%.4f n=%d\n", nm, r$b, r$se, r$n))
show("ncosp all OLS", r1); show("ncosp rep OLS", r2); show("ncosp rep RD-IPW", r3)
show("ncosp rep IPW distr+MV+spons", r4); show("pctopp dem OLS", r5); show("pctopp dem RD", r6)
show("pctopp dem IPW distr+MV+spons", r7); show("pctopp rep OLS", r8); show("pctopp rep IPW distr+MV", r9)

cat("DEVIATION: macro-area dummies built from Census regions of the sponsor state; log population density = lnpop - lnarea; rookie = tenure 1; committee leader = chair or ranking member; total bills sponsored counted per sponsor-Congress in the data; singletons dropped (reghdfe-style).\n")
cat("DEVIATION: RD bandwidths fixed at the paper-stated optimal values (13 pp Rep ncosp, 24 pp Dem pct opposite) with uniform kernel; IPW uses ATE weights 1/p and 1/(1-p) from a bill-level logit.\n")

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
