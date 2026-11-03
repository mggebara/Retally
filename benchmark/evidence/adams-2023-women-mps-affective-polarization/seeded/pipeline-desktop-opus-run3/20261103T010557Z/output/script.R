suppressPackageStartupMessages({
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization"

## ---------------- Table 1, columns 1 & 2 ----------------
load(file.path(base, "dyadic_data_1-4-22.Rdata"))
dta <- as.data.frame(updated_data)
dta$cntryyr <- paste(dta$country, dta$year, sep = "")
dta <- dta[!is.na(dta$to_prior_seats) & dta$to_prior_seats >= 4, ]

vars <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
          "year", "country", "party_dislike", "party_like", "cntryyr", "to_pfeml", "to_prior_seats", "to_mp_number")
dta <- dta[, vars]
dta <- na.omit(dta)

m1 <- feols(party_like ~ to_pfeml | cntryyr, data = dta, cluster = ~country)
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
            data = dta, cluster = ~country)

## ---------------- Table 1, columns 3 & 4 ----------------
g <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))
g$countryyear <- paste(g$country, g$year, sep = "")
g <- g[!is.na(g$to_prior_seats) & g$to_prior_seats >= 4, ]
g$like <- 10 - g$dislike

gvars <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
           "year", "country", "to_pfeml", "countryyear", "gender", "like", "dislike", "to_prior_seats")
g <- g[, gvars]
g <- na.omit(g)

g_male <- g[g$gender == 1, ]
g_female <- g[g$gender == 2, ]

m3 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = g_female, cluster = ~country)
m4 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = g_male, cluster = ~country)

## ---------------- Output ----------------
fmt <- function(x) format(unname(x), digits = 10)

cat("RESULT:women_mps_coef_bivariate=", fmt(coef(m1)["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_coef_full=", fmt(coef(m2)["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_coef_women_partisans=", fmt(coef(m3)["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_coef_men_partisans=", fmt(coef(m4)["to_pfeml"]), "\n", sep = "")
cat("RESULT:right_left_distance_coef_full=", fmt(coef(m2)["rile_distance_s"]), "\n", sep = "")
cat("RESULT:coalition_partners_coef_full=", fmt(coef(m2)["prior_coalition"]), "\n", sep = "")
cat("RESULT:opposition_partners_coef_full=", fmt(coef(m2)["prior_opposition"]), "\n", sep = "")
cat("RESULT:n_directed_dyads=", nobs(m2), "\n", sep = "")
cat("RESULT:n_obs_women_partisans=", nobs(m3), "\n", sep = "")
cat("RESULT:n_obs_men_partisans=", nobs(m4), "\n", sep = "")
cat("RESULT:n_election_studies=", length(unique(dta$cntryyr)), "\n", sep = "")

## Standard errors (clustered by country, as in the replication script)
se1 <- sqrt(diag(vcov(m1)))
se2 <- sqrt(diag(vcov(m2)))
se3 <- sqrt(diag(vcov(m3)))
se4 <- sqrt(diag(vcov(m4)))
cat("RESULT:women_mps_se_bivariate=", fmt(se1["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_se_full=", fmt(se2["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_se_women_partisans=", fmt(se3["to_pfeml"]), "\n", sep = "")
cat("RESULT:women_mps_se_men_partisans=", fmt(se4["to_pfeml"]), "\n", sep = "")