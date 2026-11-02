suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization"

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

## ---------------- Table 1, columns 1 & 2 ----------------
load(file.path(base, "dyadic_data_1-4-22.Rdata"))
dta <- as.data.frame(updated_data)
dta$cntryyr <- paste(dta$country, dta$year, sep = "")
dta <- dta[!is.na(dta$to_prior_seats) & dta$to_prior_seats >= 4, ]
vars <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
          "year", "country", "party_dislike", "party_like", "cntryyr", "to_pfeml", "to_prior_seats", "to_mp_number")
dta <- dta[vars]
dta <- na.omit(dta)

m1 <- feols(party_like ~ to_pfeml | cntryyr, data = dta, cluster = ~country)
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
            data = dta, cluster = ~country)

cf1 <- coef(m1); se1 <- sqrt(diag(vcov(m1)))
cf2 <- coef(m2); se2 <- sqrt(diag(vcov(m2)))

## ---------------- Table 1, columns 3 & 4 ----------------
g <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))
g$countryyear <- paste(g$country, g$year, sep = "")
g <- g[!is.na(g$to_prior_seats) & g$to_prior_seats >= 4, ]
g$like <- 10 - g$dislike
gvars <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
           "year", "country", "to_pfeml", "countryyear", "gender", "like", "dislike", "to_prior_seats")
g <- g[gvars]
g <- na.omit(g)
g_male <- g[g$gender == 1, ]
g_female <- g[g$gender == 2, ]

m3 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = g_female, cluster = ~country)
m4 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
            data = g_male, cluster = ~country)
cf3 <- coef(m3); se3 <- sqrt(diag(vcov(m3)))
cf4 <- coef(m4); se4 <- sqrt(diag(vcov(m4)))

## ---------------- Output ----------------
emit("women_mps_coef_bivariate", cf1["to_pfeml"])
emit("women_mps_se_bivariate", se1["to_pfeml"])
emit("women_mps_coef_full", cf2["to_pfeml"])
emit("women_mps_se_full", se2["to_pfeml"])
emit("women_mps_coef_women_partisans", cf3["to_pfeml"])
emit("women_mps_se_women_partisans", se3["to_pfeml"])
emit("women_mps_coef_men_partisans", cf4["to_pfeml"])
emit("women_mps_se_men_partisans", se4["to_pfeml"])
emit("right_left_distance_coef_full", cf2["rile_distance_s"])
emit("coalition_partners_coef_full", cf2["prior_coalition"])
emit("opposition_partners_coef_full", cf2["prior_opposition"])
emit("n_directed_dyads", nobs(m1))
emit("n_obs_women_partisans", nobs(m3))
emit("n_obs_men_partisans", nobs(m4))
emit("n_election_studies", length(unique(dta$cntryyr)))
