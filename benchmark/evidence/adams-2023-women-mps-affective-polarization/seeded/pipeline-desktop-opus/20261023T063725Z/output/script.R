suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization"

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) return(invisible(NULL))
  cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(value)))
}

strip <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled") || inherits(x, "labelled")) {
      attributes(x) <- NULL
      df[[v]] <- x
    }
  }
  df
}

## ---------------- Table 1, columns 1 & 2 ----------------
load(file.path(base, "dyadic_data_1-4-22.Rdata"))
dta <- strip(updated_data)
dta$cntryyr <- paste(dta$country, dta$year, sep = "")
dta <- dta[!is.na(dta$to_prior_seats) & dta$to_prior_seats >= 4, ]

vars <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
          "year", "country", "party_dislike", "party_like", "cntryyr", "to_pfeml", "to_prior_seats", "to_mp_number")
dta <- dta[, vars]
dta <- na.omit(dta)

m1 <- lm(party_like ~ to_pfeml + as.factor(cntryyr), data = dta)
m2 <- lm(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition + as.factor(cntryyr), data = dta)

f1 <- tryCatch(feols(party_like ~ to_pfeml | cntryyr, data = dta, cluster = ~country), error = function(e) NULL)
f2 <- tryCatch(feols(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
                     data = dta, cluster = ~country), error = function(e) NULL)

n_dyads <- nobs(m2)
n_elections <- length(unique(dta$cntryyr))

## ---------------- Table 1, columns 3 & 4 ----------------
g <- strip(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))
g$countryyear <- paste(g$country, g$year, sep = "")
g <- g[!is.na(g$to_prior_seats) & g$to_prior_seats >= 4, ]
g$like <- 10 - g$dislike
gvars <- c("rile_distance_s", "prior_coalition", "prior_opposition", "econ_distance_s", "society_distance_s",
           "year", "country", "to_pfeml", "countryyear", "gender", "like", "dislike", "to_prior_seats")
g <- g[, gvars]
g <- na.omit(g)
g$gender <- as.numeric(as.character(g$gender))

g_male <- g[g$gender == 1, ]
g_female <- g[g$gender == 2, ]

m3 <- lm(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition + as.factor(countryyear), data = g_female)
m4 <- lm(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition + as.factor(countryyear), data = g_male)

f3 <- tryCatch(feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
                     data = g_female, cluster = ~country), error = function(e) NULL)
f4 <- tryCatch(feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | countryyear,
                     data = g_male, cluster = ~country), error = function(e) NULL)

se_of <- function(f, v) {
  if (is.null(f)) return(NA)
  s <- tryCatch(sqrt(diag(vcov(f)))[v], error = function(e) NA)
  as.numeric(s)
}

## ---------------- Output ----------------
emit("women_mps_coef_bivariate", coef(m1)["to_pfeml"])
emit("women_mps_coef_full", coef(m2)["to_pfeml"])
emit("women_mps_coef_women_partisans", coef(m3)["to_pfeml"])
emit("women_mps_coef_men_partisans", coef(m4)["to_pfeml"])
emit("right_left_distance_coef_full", coef(m2)["rile_distance_s"])
emit("coalition_partners_coef_full", coef(m2)["prior_coalition"])
emit("opposition_partners_coef_full", coef(m2)["prior_opposition"])
emit("n_directed_dyads", n_dyads)
emit("n_obs_women_partisans", nobs(m3))
emit("n_obs_men_partisans", nobs(m4))
emit("n_election_studies", n_elections)

emit("women_mps_se_bivariate", se_of(f1, "to_pfeml"))
emit("women_mps_se_full", se_of(f2, "to_pfeml"))
emit("women_mps_se_women_partisans", se_of(f3, "to_pfeml"))
emit("women_mps_se_men_partisans", se_of(f4, "to_pfeml"))
emit("right_left_distance_se_full", se_of(f2, "rile_distance_s"))
emit("coalition_partners_se_full", se_of(f2, "prior_coalition"))
emit("opposition_partners_se_full", se_of(f2, "prior_opposition"))
emit("adj_r2_bivariate", summary(m1)$adj.r.squared)
emit("adj_r2_full", summary(m2)$adj.r.squared)
emit("adj_r2_women_partisans", summary(m3)$adj.r.squared)
emit("adj_r2_men_partisans", summary(m4)$adj.r.squared)