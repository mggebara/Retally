# Reproduction script for Adams (2023) - Women MPs and affective polarization
set.seed(42)

suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
  library(haven)
})

data_dir <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

# Load dyadic data (main analysis)
load(file.path(data_dir, "dyadic_data_1-4-22.Rdata"))
dyadic <- updated_data

# Load gender-disaggregated data
gender_data <- readRDS(file.path(data_dir, "gender_disagregated_8-8-21.rds"))

cat("Dyadic names:\n"); print(names(dyadic))
cat("\nGender names:\n"); print(names(gender_data))

# Based on inspection:
# DV in dyadic: party_dislike (0-10, higher = more dislike = affective polarization)
# WMP (women MPs proportion): to_pfeml  (proportion female MPs in to-party)
# Distance: rile_distance_s (standardized rile distance)
# Coalition: govern_together or prior_coalition
# Opposition: opposition_together or prior_opposition

dv_var <- "party_dislike"
wmp_var <- "to_pfeml"
dist_var <- "rile_distance_s"
coal_var <- "prior_coalition"
opp_var <- "prior_opposition"

cat("DV:", dv_var, " WMP:", wmp_var, " Dist:", dist_var, "\n")
cat("Coal:", coal_var, " Opp:", opp_var, "\n")

mp_to <- "to_mp_number"
mp_from <- "from_mp_number"

df <- dyadic %>%
  mutate(country_year = paste(country, year, sep = "_"))

# Standardize distance if not already standardized (rile_distance_s already standardized by author, but re-scale for safety)
if (is.numeric(df[[dist_var]])) {
  df$dist_std <- as.numeric(scale(df[[dist_var]]))
}

df_s <- df %>% filter(.data[[mp_to]] >= 4, .data[[mp_from]] >= 4,
                     !is.na(.data[[dv_var]]), !is.na(.data[[wmp_var]]))

cat("\nRows after restriction:", nrow(df_s), "\n")
cat("Unique country-years:", length(unique(df_s$country_year)), "\n")

df_s$election <- df_s$country_year

# Model 1: Bivariate
f1 <- as.formula(paste0(dv_var, " ~ ", wmp_var))
m1 <- feols(f1, data = df_s, cluster = ~election)

# Model 2: Full
f2 <- as.formula(paste0(dv_var, " ~ ", wmp_var, " + dist_std + ", coal_var, " + ", opp_var,
                        " | country_year"))
m2 <- feols(f2, data = df_s, cluster = ~election)

cat("\n--- Model 1 ---\n"); print(summary(m1))
cat("\n--- Model 2 ---\n"); print(summary(m2))

coef1 <- coef(m1)[wmp_var]
coef2 <- coef(m2)[wmp_var]
coef_dist <- coef(m2)["dist_std"]
coef_coal <- coef(m2)[coal_var]
coef_opp  <- coef(m2)[opp_var]
n_dyads   <- nobs(m2)
n_elections <- length(unique(df_s$election))

# Gender data
gender_data <- gender_data %>%
  mutate(country_year = paste(country, year, sep = "_"))

dv_gvar <- "dislike"  # gender data uses "dislike"
wmp_gvar <- if (wmp_var %in% names(gender_data)) wmp_var else "to_pfeml"
dist_gvar <- if ("rile_distance_s" %in% names(gender_data)) "rile_distance_s" else "rile_distance"
coal_gvar <- if ("prior_coalition" %in% names(gender_data)) "prior_coalition" else "govern_together"
opp_gvar  <- if ("prior_opposition" %in% names(gender_data)) "prior_opposition" else "opposition_together"

gender_data$dist_std <- as.numeric(scale(gender_data[[dist_gvar]]))
gender_data$election <- gender_data$country_year

cat("\nGender table:\n"); print(table(gender_data$gender, useNA="always"))

g_s <- gender_data %>%
  filter(.data[[mp_to]] >= 4, .data[[mp_from]] >= 4,
         !is.na(.data[[dv_gvar]]), !is.na(.data[[wmp_gvar]]))

gvals <- unique(as.character(g_s$gender))
cat("Gender levels:", paste(gvals, collapse=", "), "\n")

# Identify labels
women_label <- gvals[grepl("female|women|^f$|^w$", gvals, ignore.case = TRUE)]
men_label   <- setdiff(gvals, women_label)
men_label   <- men_label[grepl("male|men|^m$", men_label, ignore.case = TRUE)]
if (length(women_label) == 0 || length(men_label) == 0) {
  # fallback: assume first two
  if (length(gvals) >= 2) { women_label <- gvals[1]; men_label <- gvals[2] }
}
cat("Women label:", paste(women_label, collapse=","), " Men label:", paste(men_label, collapse=","), "\n")

df_w <- g_s %>% filter(as.character(gender) %in% women_label)
df_m <- g_s %>% filter(as.character(gender) %in% men_label)

cat("Women rows:", nrow(df_w), " Men rows:", nrow(df_m), "\n")

f_full <- as.formula(paste0(dv_gvar, " ~ ", wmp_gvar, " + dist_std + ", coal_gvar, " + ", opp_gvar,
                            " | country_year"))

m3 <- feols(f_full, data = df_w, cluster = ~election)
m4 <- feols(f_full, data = df_m, cluster = ~election)

cat("\n--- Model 3 (women) ---\n"); print(summary(m3))
cat("\n--- Model 4 (men) ---\n"); print(summary(m4))

coef3 <- coef(m3)[wmp_gvar]
coef4 <- coef(m4)[wmp_gvar]
n_w <- nobs(m3)
n_m <- nobs(m4)

cat("\n\n=== RESULTS ===\n")
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef1))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef2))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef3))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef4))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef_dist))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef_coal))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef_opp))
cat(sprintf("RESULT:n_directed_dyads=%d\n", as.integer(n_dyads)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", as.integer(n_w)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", as.integer(n_m)))
cat(sprintf("RESULT:n_election_studies=%d\n", as.integer(n_elections)))