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
# object: updated_data
dyadic <- updated_data

# Load gender-disaggregated data
gender_data <- readRDS(file.path(data_dir, "gender_disagregated_8-8-21.rds"))

# Inspect column names
cat("Dyadic columns:\n")
print(names(dyadic)[1:30])
cat("\nGender columns:\n")
print(names(gender_data)[1:30])

# Look for the key variables
# DV: thermometer (0-10), out-party j evaluated by in-party i partisans
# Regressor: proportion of women MPs in party j, lagged
# Controls: elite left-right distance, coalition partners, opposition partners
# FE: country-year

# Explore key variable names
key_vars <- c("thermometer_score", "dislike", "to_prop_women_mps", "prop_women_mps_t_1",
              "to_women_mps", "to_mp_number", "from_mp_number",
              "govern_together", "opposition_together", "prior_coalition", "prior_opposition",
              "elite_distance", "rile_distance", "left_right_distance",
              "country", "year", "party_from", "party_to")

cat("\nFull dyadic names:\n")
print(names(dyadic))

cat("\nFull gender names:\n")
print(names(gender_data))

# Find candidate columns for proportion of women MPs
women_cols_d <- grep("women|female|wmp|gender", names(dyadic), value = TRUE, ignore.case = TRUE)
cat("\nWomen-related in dyadic:\n"); print(women_cols_d)

women_cols_g <- grep("women|female|wmp|gender", names(gender_data), value = TRUE, ignore.case = TRUE)
cat("\nWomen-related in gender:\n"); print(women_cols_g)

dist_cols <- grep("dist|rile|left|right|cmp", names(dyadic), value = TRUE, ignore.case = TRUE)
cat("\nDistance-related:\n"); print(dist_cols)

therm_cols <- grep("therm|like|dislike|rating|eval", names(dyadic), value = TRUE, ignore.case = TRUE)
cat("\nThermometer-related:\n"); print(therm_cols)

# Try to identify the DV in dyadic data
cat("\nSummary of candidate DVs:\n")
for (v in therm_cols) {
  if (is.numeric(dyadic[[v]])) {
    cat(v, ": range=", paste(range(dyadic[[v]], na.rm=TRUE), collapse=","), 
        "mean=", mean(dyadic[[v]], na.rm=TRUE), "\n")
  }
}

# Candidate women-MP proportion
cat("\nSummary of women-MP vars in dyadic:\n")
for (v in women_cols_d) {
  if (is.numeric(dyadic[[v]])) {
    cat(v, ": range=", paste(range(dyadic[[v]], na.rm=TRUE), collapse=","), 
        "mean=", mean(dyadic[[v]], na.rm=TRUE), "\n")
  }
}

# Pick variable names based on inspection
# Based on typical naming:
#   DV candidate: "thermometer_score" or "like" (in dyadic) ... check gender_data has "dislike"
# The dyadic data likely has aggregated thermometer; gender_data split by gender

# Determine DV in dyadic data
dv_var <- NULL
if ("thermometer_score" %in% names(dyadic)) dv_var <- "thermometer_score"
if (is.null(dv_var) && "like" %in% names(dyadic)) dv_var <- "like"
if (is.null(dv_var) && "dislike" %in% names(dyadic)) dv_var <- "dislike"
cat("\nDV var selected (dyadic):", dv_var, "\n")

# Find a lagged women MP proportion
wmp_var <- NULL
candidates_wmp <- c("to_prop_women_mps_lag", "to_prop_women_mps_t_1", "to_prop_women_t_1",
                    "to_prop_women_mps", "to_prop_wmp", "prop_women_mps_lag",
                    "prop_women_mps_t_1", "to_women_prop_lag", "to_women_mps_prop",
                    "to_lag_prop_women_mps", "women_mps_t_1", "to_women_mps_t_1")
for (c0 in candidates_wmp) {
  if (c0 %in% names(dyadic)) { wmp_var <- c0; break }
}
if (is.null(wmp_var)) {
  # pick the first "to_" and "women" containing var
  cand <- intersect(grep("to_", names(dyadic), value = TRUE),
                    grep("women|female", names(dyadic), value = TRUE, ignore.case = TRUE))
  cat("\nCandidate wmp vars:\n"); print(cand)
  if (length(cand) > 0) wmp_var <- cand[1]
}
cat("\nWMP var selected:", wmp_var, "\n")

# distance variable
dist_var <- NULL
for (c0 in c("elite_distance_std", "rile_distance_std", "left_right_distance_std",
             "distance_std", "elite_distance", "rile_distance", "left_right_distance",
             "rile_dist", "elite_rl_distance")) {
  if (c0 %in% names(dyadic)) { dist_var <- c0; break }
}
if (is.null(dist_var)) {
  cand <- grep("dist", names(dyadic), value = TRUE, ignore.case = TRUE)
  cat("Distance candidates:\n"); print(cand)
  if (length(cand) > 0) dist_var <- cand[1]
}
cat("Dist var selected:", dist_var, "\n")

# coalition / opposition dummies
coal_var <- if ("govern_together" %in% names(dyadic)) "govern_together" else "prior_coalition"
opp_var  <- if ("opposition_together" %in% names(dyadic)) "opposition_together" else "prior_opposition"

cat("Coal var:", coal_var, "  Opp var:", opp_var, "\n")

# MP count variables for sample restriction
mp_to <- "to_mp_number"
mp_from <- "from_mp_number"

# Build analysis sample
df <- dyadic %>%
  mutate(country_year = paste(country, year, sep = "_"))

# Standardize distance
if (!is.null(dist_var) && is.numeric(df[[dist_var]])) {
  df$dist_std <- as.numeric(scale(df[[dist_var]]))
} else {
  df$dist_std <- NA
}

# Sample restriction: at least 4 MPs each side
df_s <- df %>% filter(.data[[mp_to]] >= 4, .data[[mp_from]] >= 4)

# Also require non-missing DV and regressor
df_s <- df_s %>% filter(!is.na(.data[[dv_var]]), !is.na(.data[[wmp_var]]))

cat("\nRows after restriction:", nrow(df_s), "\n")
cat("Unique country-years:", length(unique(df_s$country_year)), "\n")

# Election cluster: country-year as proxy for election
df_s$election <- df_s$country_year

# Model 1: Bivariate
f1 <- as.formula(paste0(dv_var, " ~ ", wmp_var))
m1 <- feols(f1, data = df_s, cluster = ~election)

# Model 2: Full
f2 <- as.formula(paste0(dv_var, " ~ ", wmp_var, " + dist_std + ", coal_var, " + ", opp_var,
                        " | country_year"))
m2 <- feols(f2, data = df_s, cluster = ~election)

cat("\n--- Model 1 (bivariate) ---\n")
print(summary(m1))
cat("\n--- Model 2 (full) ---\n")
print(summary(m2))

coef1 <- coef(m1)[wmp_var]
coef2 <- coef(m2)[wmp_var]
coef_dist <- coef(m2)["dist_std"]
coef_coal <- coef(m2)[coal_var]
coef_opp  <- coef(m2)[opp_var]
n_dyads   <- nobs(m2)
n_elections <- length(unique(df_s$election))

# Models 3-4: women / men partisans from gender_data
gender_data <- gender_data %>%
  mutate(country_year = paste(country, year, sep = "_"))

# DV in gender_data
dv_gvar <- NULL
for (c0 in c("thermometer_score", "like", "dislike")) {
  if (c0 %in% names(gender_data)) { dv_gvar <- c0; break }
}
cat("\nDV in gender data:", dv_gvar, "\n")

# wmp var in gender data
wmp_gvar <- NULL
if (wmp_var %in% names(gender_data)) {
  wmp_gvar <- wmp_var
} else {
  cand <- intersect(grep("to_", names(gender_data), value = TRUE),
                    grep("women|female", names(gender_data), value = TRUE, ignore.case = TRUE))
  cat("gender wmp candidates:\n"); print(cand)
  if (length(cand) > 0) wmp_gvar <- cand[1]
}
cat("wmp gender var:", wmp_gvar, "\n")

dist_gvar <- NULL
for (c0 in c("elite_distance_std", "rile_distance_std", "left_right_distance_std",
             "distance_std", "elite_distance", "rile_distance", "left_right_distance",
             "rile_dist")) {
  if (c0 %in% names(gender_data)) { dist_gvar <- c0; break }
}
if (is.null(dist_gvar)) {
  cand <- grep("dist", names(gender_data), value = TRUE, ignore.case = TRUE)
  if (length(cand) > 0) dist_gvar <- cand[1]
}

coal_gvar <- if ("govern_together" %in% names(gender_data)) "govern_together" else "prior_coalition"
opp_gvar  <- if ("opposition_together" %in% names(gender_data)) "opposition_together" else "prior_opposition"

gender_data$dist_std <- as.numeric(scale(gender_data[[dist_gvar]]))
gender_data$election <- gender_data$country_year

# Check gender variable values
cat("\nGender variable values:\n")
print(table(gender_data$gender, useNA = "always"))

# Sample restriction
g_s <- gender_data %>%
  filter(.data[[mp_to]] >= 4, .data[[mp_from]] >= 4,
         !is.na(.data[[dv_gvar]]), !is.na(.data[[wmp_gvar]]))

# Try to detect women / men labels
gvals <- unique(as.character(g_s$gender))
cat("Gender levels:", paste(gvals, collapse=", "), "\n")

women_label <- gvals[grepl("w|f|1", gvals, ignore.case = TRUE) & !grepl("m", gvals, ignore.case = TRUE)]
men_label   <- gvals[grepl("^m|male|men|2", gvals, ignore.case = TRUE)]

if (length(women_label) == 0) {
  # try numeric encoding
  if (all(gvals %in% c("1","2"))) {
    women_label <- "2"; men_label <- "1"
  }
}

# Fallback: try common strings
if (length(women_label) == 0) women_label <- gvals[grepl("female|women", gvals, ignore.case = TRUE)]
if (length(men_label) == 0) men_label <- gvals[grepl("^male|^men", gvals, ignore.case = TRUE)]

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

# Emit results
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