suppressPackageStartupMessages({library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/seeded/2026-11-02-b/mount/adams_2023_women_mps_affective_polarization"

## Table 1, columns 1-2 (dyadic data), following replication_code.R
load(file.path(D, "dyadic_data_1-4-22.Rdata"))
dta <- as.data.frame(updated_data)
dta$cntryyr <- paste(dta$country, dta$year, sep = "")
dta <- subset(dta, dta$to_prior_seats >= 4)
vars <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
          "year", "country", "party_dislike", "party_like", "cntryyr", "to_pfeml", "to_prior_seats", "to_mp_number")
dta <- na.omit(dta[vars])

m1 <- feols(party_like ~ to_pfeml | cntryyr, data = dta, cluster = ~country)
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
            data = dta, cluster = ~country)
print(summary(m1)); print(summary(m2))
# election-clustered SEs as described in the paper text (coefficients identical)
print(summary(m2, cluster = ~cntryyr))

## Table 1, columns 3-4 (gender-disaggregated data)
g <- readRDS(file.path(D, "gender_disagregated_8-8-21.rds"))
g$countryyear <- paste(g$country, g$year, sep = "")
g <- subset(g, g$to_prior_seats >= 4)
g$like <- 10 - g$dislike
gv <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
        "year", "country", "to_pfeml", "countryyear", "gender", "like", "dislike", "to_prior_seats")
g <- na.omit(g[gv])
gm <- subset(g, gender == 1); gf <- subset(g, gender == 2)
m3 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = gf, cluster = ~country)
m4 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = gm, cluster = ~country)
print(summary(m3)); print(summary(m4))

f <- function(x) formatC(x, digits = 6, format = "f")
cat("RESULT:women_mps_coef_bivariate=", f(coef(m1)["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_coef_full=", f(coef(m2)["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_coef_women_partisans=", f(coef(m3)["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_coef_men_partisans=", f(coef(m4)["to_pfeml"]), "\n", sep = "")
cat("RESULT:right_left_distance_coef_full=", f(coef(m2)["rile_distance_s"]), "\n", sep = "")
cat("RESULT:coalition_partners_coef_full=", f(coef(m2)["prior_coalition"]), "\n", sep = "")
cat("RESULT:opposition_partners_coef_full=", f(coef(m2)["prior_opposition"]), "\n", sep = "")
cat("RESULT:n_directed_dyads=", nobs(m2), "\n", sep = "")
cat("RESULT:n_obs_women_partisans=", nobs(m3), "\n", sep = "")
cat("RESULT:n_obs_men_partisans=", nobs(m4), "\n", sep = "")
cat("RESULT:n_election_studies=", length(unique(dta$cntryyr)), "\n", sep = "")
