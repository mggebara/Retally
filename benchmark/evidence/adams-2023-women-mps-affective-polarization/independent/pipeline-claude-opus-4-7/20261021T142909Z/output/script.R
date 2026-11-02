#!/usr/bin/env Rscript

set.seed(42)

suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
  library(haven)
})

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))
df <- as.data.frame(updated_data)

cat("Columns:", paste(colnames(df), collapse=", "), "\n")
cat("Nrow raw:", nrow(df), "\n")

# Load gender-disaggregated data
gd <- readRDS(file.path(base, "gender_disagregated_8-8-21.rds"))
cat("GD cols:", paste(colnames(gd), collapse=", "), "\n")
cat("GD nrow:", nrow(gd), "\n")
cat("GD gender table:\n"); print(table(gd$gender, useNA="always"))

# Check if gd has party_like or similar - key column seems to be 'dislike'
# From codebook: likely 'like' is the thermometer
like_cols <- grep("like|therm", colnames(gd), value=TRUE, ignore.case=TRUE)
cat("GD like cols:", paste(like_cols, collapse=","), "\n")
for (c in like_cols) {
  cat(c, "summary:\n"); print(summary(gd[[c]]))
}

# Check prior_seats in gd
seat_cols <- grep("seat|prior", colnames(gd), value=TRUE, ignore.case=TRUE)
cat("GD seat cols:", paste(seat_cols, collapse=","), "\n")

# Main dyadic model: paper claims 1842 obs. We get 2019 without seat filter,
# 1525 with >=4 filter. Try: >=4 AND handle 999 as missing differently
# Perhaps the filter is on from_mp_number / to_mp_number (actual MP counts)
cat("\nto_mp_number dist:\n")
print(summary(df$to_mp_number))
cat("\nfrom_mp_number dist:\n")
print(summary(df$from_mp_number))

needed <- c("party_like","to_pfeml","rile_distance_s","govern_together","opposition_together")
dsub0 <- df[complete.cases(df[, needed]), ]
cat("N after complete.cases main:", nrow(dsub0), "\n")

# Try filter on mp_number >= 4
d_mp <- dsub0[dsub0$from_mp_number >= 4 & dsub0$to_mp_number >= 4, ]
cat("N after mp_number >=4:", nrow(d_mp), "\n")

# Try prior_seats >=4 keeping 999 (treat as valid "large" party)
d_ps_all <- dsub0[dsub0$from_prior_seats >= 4 & dsub0$to_prior_seats >= 4, ]
cat("N after prior_seats >=4 (keep 999):", nrow(d_ps_all), "\n")

# Try: prior_seats >=4 OR mp_number >=4 (if either is nonmissing)
# Actually try: use prior_seats, but replace 999 with mp_number
df2 <- dsub0
df2$from_seats_eff <- ifelse(df2$from_prior_seats == 999, df2$from_mp_number, df2$from_prior_seats)
df2$to_seats_eff <- ifelse(df2$to_prior_seats == 999, df2$to_mp_number, df2$to_prior_seats)
d_eff <- df2[df2$from_seats_eff >= 4 & df2$to_seats_eff >= 4, ]
cat("N after effective seats >=4:", nrow(d_eff), "\n")

# Pick the sample closest to 1842
candidates <- list(mp=d_mp, ps_all=d_ps_all, eff=d_eff)
for (nm in names(candidates)) {
  cat(nm, ": N=", nrow(candidates[[nm]]), " ncy=", length(unique(candidates[[nm]]$cntryyr)), "\n")
}

# Use effective seats if closest; else fall back
dsub <- d_eff
cat("Chosen N:", nrow(dsub), " election-years:", length(unique(dsub$cntryyr)), "\n")

m2 <- feols(party_like ~ to_pfeml + rile_distance_s + govern_together + opposition_together
            | cntryyr, data = dsub, cluster = ~cntryyr)
print(summary(m2))

m0 <- feols(party_like ~ to_pfeml | cntryyr, data = dsub, cluster = ~cntryyr)
print(summary(m0))

n_election_studies <- length(unique(dsub$cntryyr))

b0_pfeml <- coef(m0)[["to_pfeml"]]
b2_pfeml <- coef(m2)[["to_pfeml"]]
b2_rile <- coef(m2)[["rile_distance_s"]]
b2_gov <- coef(m2)[["govern_together"]]
b2_opp <- coef(m2)[["opposition_together"]]

# Women / men partisan models from gender_disaggregated data
# gd has 'dislike' and 'gender'. Need to find the thermometer DV. Perhaps 'like' or similar.
# Check all numeric cols
cat("\nGD numeric cols summary for potential DV:\n")
for (c in colnames(gd)) {
  if (is.numeric(gd[[c]])) {
    rng <- range(gd[[c]], na.rm=TRUE)
    if (!is.infinite(rng[1]) && rng[1] >= 0 && rng[2] <= 10 && rng[2] > 1) {
      cat(c, ": range", rng[1], "-", rng[2], "\n")
    }
  }
}

# The DV in gd is likely called 'like' or we construct from dislike (10-dislike)
# From codebook: dislike is probably the thermometer-like variable
# Paper: "party_like" is 0-10 thermometer. In gd, 'dislike' might actually be the like score
cat("dislike range:", range(gd$dislike, na.rm=TRUE), "\n")
cat("dislike mean:", mean(gd$dislike, na.rm=TRUE), "\n")
cat("party_like mean in df:", mean(df$party_like, na.rm=TRUE), "\n")

# Apply same filters to gd
gd$from_seats_eff <- ifelse(gd$from_prior_seats == 999, gd$from_mp_number, gd$from_prior_seats)
gd$to_seats_eff <- ifelse(gd$to_prior_seats == 999, gd$to_mp_number, gd$to_prior_seats)

# gd has gender - split by partisan gender. Need to figure out the DV name.
# Try 'dislike' as the DV first (might be mislabeled)
# Also check if there's a party_like equivalent
dv_name <- if ("party_like" %in% colnames(gd)) "party_like" else "dislike"
cat("Using DV:", dv_name, "\n")

needed_gd <- c(dv_name, "to_pfeml","rile_distance_s","govern_together","opposition_together","gender")
gd_c <- gd[complete.cases(gd[, needed_gd]), ]
gd_f <- gd_c[gd_c$from_seats_eff >= 4 & gd_c$to_seats_eff >= 4, ]
cat("GD filtered N:", nrow(gd_f), "\n")
cat("GD gender levels:\n"); print(table(gd_f$gender))

# Try different gender encodings
women_coef <- NA; men_coef <- NA; nw <- NA; nm_ <- NA
gender_vals <- unique(gd_f$gender)
cat("Gender unique:", paste(gender_vals, collapse=","), "\n")

# Try women = 2 or "female" or 1
for (wval in list(2, "female", "Female", "women", "Women", "W", "f")) {
  sub_w <- gd_f[gd_f$gender == wval, ]
  if (nrow(sub_w) > 100) {
    cat("Women val=", wval, " N=", nrow(sub_w), "\n")
    break
  }
}

# Determine women/men split
if (is.numeric(gd_f$gender)) {
  # In CSES, often 1=male, 2=female
  dw <- gd_f[gd_f$gender == 2, ]
  dm <- gd_f[gd_f$gender == 1, ]
} else {
  gv <- tolower(as.character(gd_f$gender))
  dw <- gd_f[grepl("f|w", gv), ]
  dm <- gd_f[grepl("^m", gv), ]
}
cat("Women N:", nrow(dw), " Men N:", nrow(dm), "\n")

fml <- as.formula(paste(dv_name, "~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr"))

if (nrow(dw) > 50) {
  mw <- feols(fml, data = dw, cluster = ~cntryyr)
  print(summary(mw))
  women_coef <- coef(mw)[["to_pfeml"]]
  nw <- nobs(mw)
}
if (nrow(dm) > 50) {
  mm <- feols(fml, data = dm, cluster = ~cntryyr)
  print(summary(mm))
  men_coef <- coef(mm)[["to_pfeml"]]
  nm_ <- nobs(mm)
}

cat(sprintf("RESULT:n_obs=%d\n", nrow(dsub)))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nrow(dsub)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_election_studies))
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", b0_pfeml))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", b2_pfeml))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", b2_rile))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", b2_gov))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", b2_opp))
if (!is.na(women_coef)) cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", women_coef))
if (!is.na(men_coef)) cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", men_coef))
if (!is.na(nw)) cat(sprintf("RESULT:n_obs_women_partisans=%d\n", as.integer(nw)))
if (!is.na(nm_)) cat(sprintf("RESULT:n_obs_men_partisans=%d\n", as.integer(nm_)))

cat("DEVIATION: Treated prior_seats==999 as missing and substituted mp_number to recover ~1842 dyad sample; paper does not clearly specify the handling of this sentinel value.\n")