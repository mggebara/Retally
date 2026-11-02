# Adams et al. (2023) "Can't We All Just Get Along?" -- Table 1 independent/blind reproduction
set.seed(42)
suppressPackageStartupMessages(library(fixest))
D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-11-01-a/mount/adams_2023_women_mps_affective_polarization"

load(file.path(D, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
g <- as.data.frame(readRDS(file.path(D, "gender_disagregated_8-8-21.rds")))

# Seat counts: 999 is a missing-value code -> NA
fix_seats <- function(x) { x[x >= 999] <- NA; x }
d$to_prior_seats   <- fix_seats(d$to_prior_seats)
d$from_prior_seats <- fix_seats(d$from_prior_seats)
g$to_prior_seats   <- fix_seats(g$to_prior_seats)
g$from_prior_seats <- fix_seats(g$from_prior_seats)
cat("diag: dyadic rows with seat code 999 (either party):",
    sum(is.na(d$to_prior_seats) | is.na(d$from_prior_seats)), "\n")

# Sample: both parties have at least four MPs in the year before the survey
ds <- subset(d, to_prior_seats >= 4 & from_prior_seats >= 4)
gs <- subset(g, to_prior_seats >= 4 & from_prior_seats >= 4)

# DV: mean 0-10 thermometer (10 = strongly like) of i's partisans toward j
ds$eval <- ds$party_like
gs$eval <- 10 - gs$dislike          # gender file stores the reversed (dislike) scale

# Controls: standardized |rile_i - rile_j| (CMP), coalition partners, opposition partners
# (prior_coalition / prior_opposition: governing status during the survey period,
#  the variables the codebook flags as used in the analysis)
f1 <- eval ~ to_pfeml | cntryyr
f2 <- eval ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr

m1 <- feols(f1, data = ds, cluster = ~cntryyr)
m2 <- feols(f2, data = ds, cluster = ~cntryyr)
m3 <- feols(f2, data = subset(gs, gender == 2), cluster = ~cntryyr)   # women partisans
m4 <- feols(f2, data = subset(gs, gender == 1), cluster = ~cntryyr)   # men partisans

etable(m1, m2, m3, m4, fitstat = ~ n + ar2)

# Elections: count clusters in the main sample; also check elecdate splits within country-year
used2 <- ds[obs(m2), ]
cat("diag: N col1 =", nobs(m1), " N col2 =", nobs(m2), "\n")
cat("diag: country-years in col2 sample =", length(unique(used2$cntryyr)),
    "; distinct country-elecdate =", length(unique(paste(used2$country, used2$elecdate))), "\n")
cat("diag: countries in col2 sample =", length(unique(used2$country)), "\n")

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["to_pfeml"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rile_distance_s"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["prior_coalition"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["prior_opposition"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", length(unique(used2$cntryyr))))
