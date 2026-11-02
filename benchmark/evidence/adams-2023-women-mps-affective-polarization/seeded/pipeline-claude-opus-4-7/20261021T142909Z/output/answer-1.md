```r
suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})

set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization"

# Load dyadic data
load(file.path(base, "dyadic_data_1-4-22.Rdata"))
dta <- updated_data
dta$cntryyr <- paste(dta$country, dta$year, sep = "")
dta <- subset(dta, dta$to_prior_seats >= 4)

vars <- c("rile_distance_s", "prior_coalition", "prior_opposition",
          "year", "country", "party_like", "cntryyr", "to_pfeml", "to_prior_seats", "to_mp_number")
dta <- dta[vars]
dta <- na.omit(dta)

m1 <- feols(party_like ~ to_pfeml | cntryyr, data = dta, cluster = ~country)
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
            data = dta, cluster = ~country)

coef_bivariate <- coef(m1)["to_pfeml"]
coef_full <- coef(m2)["to_pfeml"]
coef_rile <- coef(m2)["rile_distance_s"]
coef_coalition <- coef(m2)["prior_coalition"]
coef_opposition <- coef(m2)["prior_opposition"]
n_dyads <- nobs(m2)

# Gender disaggregated
dta_g <- readRDS(file.path(base, "gender_disagregated_8-8-21.rds"))
dta_g$countryyear <- paste(dta_g$country, dta_g$year, sep = "")
dta_g <- subset(dta_g, dta_g$to_prior_seats >= 4)
dta_g$like <- 10 - dta_g$dislike

vars_g <- c("rile_distance_s", "prior_coalition", "prior_opposition",
            "year", "country", "to_pfeml",
            "countryyear", "gender", "like", "dislike", "to_prior_seats")
dta_g <- dta_g[vars_g]
dta_g <- na.omit(dta_g)

dta_male <- subset(dta_g, gender == 1)
dta_female <- subset(dta_g, gender == 2)

m3 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = dta_female, cluster = ~country)
m4 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = dta_male, cluster = ~country)

coef_women_part <- coef(m3)["to_pfeml"]
coef_men_part <- coef(m4)["to_pfeml"]
n_women <- nobs(m3)
n_men <- nobs(m4)

# number of election studies (country-year)
n_elec <- length(unique(dta$cntryyr))

cat(sprintf("RESULT:women_mps_coef_bivariate=%.4f\n", coef_bivariate))
cat(sprintf("RESULT:women_mps_coef_full=%.4f\n", coef_full))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.4f\n", coef_women_part))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.4f\n", coef_men_part))
cat(sprintf("RESULT:right_left_distance_coef_full=%.4f\n", coef_rile))
cat(sprintf("RESULT:coalition_partners_coef_full=%.4f\n", coef_coalition))
cat(sprintf("RESULT:opposition_partners_coef_full=%.4f\n", coef_opposition))
cat(sprintf("RESULT:n_directed_dyads=%d\n", as.integer(n_dyads)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", as.integer(n_women)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", as.integer(n_men)))
cat(sprintf("RESULT:n_election_studies=%d\n", as.integer(n_elec)))
```