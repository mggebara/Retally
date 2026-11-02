suppressMessages({library(haven); library(dplyr); library(fixest); library(rdrobust)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-02-c/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/"
b <- read_dta(paste0(D,"bills_analysis_101-111_replication.dta")) %>% zap_labels() %>% as.data.frame()

ne <- c("CT","ME","MA","NH","RI","VT","NJ","NY","PA")
mw <- c("IL","IN","MI","OH","WI","IA","KS","MN","MO","NE","ND","SD")
so <- c("DE","FL","GA","MD","NC","SC","VA","DC","WV","AL","KY","MS","TN","AR","LA","OK","TX")
b <- b %>% mutate(
  sid = paste(v2, sponsor_state_abbrev, sponsor_district, sponsor_term_served),
  reg_ne = as.integer(sponsor_state_abbrev %in% ne),
  reg_mw = as.integer(sponsor_state_abbrev %in% mw),
  reg_so = as.integer(sponsor_state_abbrev %in% so),
  lndens = lnpop - lnarea,
  rookie = as.integer(sponsor_tenure_run == 1),
  leader = as.integer(comc == 1 | comr == 1),
  pct_opp = 100 * numb_cosponsors_opposite / (numb_cosponsors + 1),
  mv_elected = abs(MV1_democrat),
  female = sponsor_female,
  mv = MV1_female)
b <- b %>% group_by(sid) %>% mutate(nbills_sp = n()) %>% ungroup() %>% as.data.frame()
cat("bills with opp > n cosponsors:", sum(b$numb_cosponsors_opposite > b$numb_cosponsors, na.rm=TRUE), "\n")

hc <- grep("^house_", names(b), value = TRUE)
billc <- paste(hc, collapse = " + ")
sponc_v <- c("sponsor_age","sponsor_tenure_run","rookie","leader","black","occ1","occ2","occ3","occ4","occ5","ivycoll","borninstate","nbills_sp")
distc_v <- c("reg_ne","reg_mw","reg_so","pct_black","pct_age_over65","pct_for_born","pct_urban","lninc","lndens")
need <- c("female","numb_cosponsors","minor","v2","sponsor_party", hc, sponc_v, distc_v, "occ6")
b$base <- complete.cases(b[, need])
b <- b[b$base, ]
cat("base sample:", nrow(b), "sponsor-terms:", length(unique(b$sid)), "\n")

samp <- function(p) if (p == "all") b else b[b$sponsor_party == ifelse(p == "dem", 100, 200), ]

ols <- function(y, p) {
  d <- samp(p)
  partyterm <- if (p == "all") " + i(sponsor_party)" else ""
  f <- as.formula(paste(y, "~ female +", billc, "+", paste(sponc_v, collapse = " + "), partyterm, "+",
                        paste(distc_v, collapse = " + "), "| v2 + minor"))
  m <- feols(f, d, cluster = ~sid)
  list(b = coef(m)["female"], se = se(m)["female"], n = nobs(m), ns = length(unique(d$sid[obs(m)])))
}

# Stata-like dropping of observations perfectly predicted by a binary regressor
drop_pp <- function(d, xs) {
  repeat {
    changed <- FALSE
    for (x in xs) {
      v <- d[[x]]
      if (all(v %in% c(0, 1)) && length(unique(v)) == 2) {
        for (val in c(0, 1)) {
          s <- v == val
          if (any(s) && length(unique(d$female[s])) == 1 && sum(!s) > 0) {
            d <- d[!s, ]; changed <- TRUE; break
          }
        }
      }
      if (changed) break
    }
    if (!changed) break
  }
  d
}

ipw <- function(d, xs) {
  d <- drop_pp(d, xs)
  xs2 <- xs[sapply(xs, function(x) length(unique(d[[x]])) > 1)]
  ps <- glm(as.formula(paste("female ~", paste(xs2, collapse = " + "))), data = d, family = binomial())
  p <- fitted(ps)
  d$w <- ifelse(d$female == 1, 1 / p, 1 / (1 - p))
  d
}

rd <- function(y, p, h, pscore) {
  d <- samp(p)
  d <- d[!is.na(d$mv) & d$mixed_gender_election %in% 1, ]
  bw <- tryCatch(rdrobust(d[[y]], d$mv, c = 0)$bws[1, 1], error = function(e) NA)
  cat(sprintf("  rdrobust MSE bandwidth (%s,%s): %.2f; used h=%g\n", y, p, bw, h))
  d <- d[abs(d$mv) <= h, ]
  if (pscore) {
    d <- ipw(d, distc_v)
    f <- as.formula(paste(y, "~ female + mv + female:mv +", billc, "| v2 + minor"))
    m <- feols(f, d, weights = ~w, cluster = ~sid)
  } else {
    m <- feols(as.formula(paste(y, "~ female + mv + female:mv | v2")), d, cluster = ~sid)
  }
  list(b = coef(m)["female"], se = se(m)["female"], n = nobs(m), ns = length(unique(d$sid[obs(m)])))
}

psw <- function(y, p, spons) {
  d <- samp(p)
  d <- d[!is.na(d$mv_elected), ]
  xs <- c(distc_v, "mv_elected")
  if (spons) xs <- c(xs, sponc_v)
  d <- ipw(d, xs)
  f <- as.formula(paste(y, "~ female +", billc, "| v2 + minor"))
  m <- feols(f, d, weights = ~w, cluster = ~sid)
  list(b = coef(m)["female"], se = se(m)["female"], n = nobs(m), ns = length(unique(d$sid[obs(m)])))
}

show <- function(lab, r) { cat(sprintf("%-40s b=%8.3f se=%7.3f n=%6d ns=%5d\n", lab, r$b, r$se, r$n, r$ns)); r }

r1 <- show("ncosp all OLS", ols("numb_cosponsors", "all"))
r2 <- show("ncosp rep OLS", ols("numb_cosponsors", "rep"))
r3 <- show("ncosp rep RD+IPW h=13", rd("numb_cosponsors", "rep", 13, TRUE))
show("ncosp rep RD h=13", rd("numb_cosponsors", "rep", 13, FALSE))
r4 <- show("ncosp rep PS distr+MV+spons", psw("numb_cosponsors", "rep", TRUE))
show("ncosp rep PS distr+MV", psw("numb_cosponsors", "rep", FALSE))
r5 <- show("pctopp dem OLS", ols("pct_opp", "dem"))
r6 <- show("pctopp dem RD h=24", rd("pct_opp", "dem", 24, FALSE))
r7 <- show("pctopp dem PS distr+MV+spons", psw("pct_opp", "dem", TRUE))
r8 <- show("pctopp rep OLS", ols("pct_opp", "rep"))
r9 <- show("pctopp rep PS distr+MV", psw("pct_opp", "rep", FALSE))

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
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", r1$ns))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", r5$n))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", r8$n))
