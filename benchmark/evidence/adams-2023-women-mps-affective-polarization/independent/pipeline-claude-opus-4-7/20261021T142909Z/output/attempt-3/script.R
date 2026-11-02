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

# Check for women/men partisan DVs
cand_women <- grep("wom|fem", colnames(df), value=TRUE, ignore.case=TRUE)
cand_men <- grep("men|male", colnames(df), value=TRUE, ignore.case=TRUE)
cat("Women-related cols:", paste(cand_women, collapse=", "), "\n")
cat("Men-related cols:", paste(cand_men, collapse=", "), "\n")

# Likely party_like_women / party_like_men variants
like_cols <- grep("like|therm", colnames(df), value=TRUE, ignore.case=TRUE)
cat("Like/therm cols:", paste(like_cols, collapse=", "), "\n")

# MP count filter: paper restricts to parties with at least 4 MPs each
mp_cols <- grep("mp|seat", colnames(df), value=TRUE, ignore.case=TRUE)
cat("MP/seat cols:", paste(mp_cols, collapse=", "), "\n")

needed <- c("party_like","to_pfeml","rile_distance_s","govern_together","opposition_together")
dsub <- df[complete.cases(df[, needed]), ]
cat("N after complete.cases main:", nrow(dsub), "\n")

# Try to find the right sample filter to get 1842
# Check if there's a column for MP counts
for (cn in mp_cols) {
  cat(cn, "range:", paste(range(df[[cn]], na.rm=TRUE), collapse="-"), "NAs:", sum(is.na(df[[cn]])), "\n")
}

# Try filtering by MP count >= 4 for both parties
# Common names: from_mps, to_mps, mps_from, mps_to
possible_from <- intersect(c("from_mps","mps_from","from_totalmps","from_nmps","from_seats"), colnames(df))
possible_to <- intersect(c("to_mps","mps_to","to_totalmps","to_nmps","to_seats"), colnames(df))
cat("from mp col:", possible_from, "\n")
cat("to mp col:", possible_to, "\n")

# Bivariate model
m0 <- feols(party_like ~ to_pfeml | cntryyr, data = dsub, cluster = ~cntryyr)
print(summary(m0))

# Full model with country-year FE
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + govern_together + opposition_together
            | cntryyr, data = dsub, cluster = ~cntryyr)
print(summary(m2))

# Women/men partisan models - try common variable names
women_dv_candidates <- c("party_like_women","party_like_fem","party_like_f","women_party_like","fem_party_like")
men_dv_candidates <- c("party_like_men","party_like_m","party_like_male","men_party_like","male_party_like")

women_dv <- intersect(women_dv_candidates, colnames(df))
men_dv <- intersect(men_dv_candidates, colnames(df))
cat("women DV found:", women_dv, "\n")
cat("men DV found:", men_dv, "\n")

n_election_studies <- length(unique(dsub$cntryyr))
cat("n cntryyr:", n_election_studies, "\n")

b0_pfeml <- coef(m0)[["to_pfeml"]]
b2_pfeml <- coef(m2)[["to_pfeml"]]
b2_rile <- coef(m2)[["rile_distance_s"]]
b2_gov <- coef(m2)[["govern_together"]]
b2_opp <- coef(m2)[["opposition_together"]]

# Women partisans
if (length(women_dv) > 0) {
  dv_w <- women_dv[1]
  dsw <- df[complete.cases(df[, c(dv_w,"to_pfeml","rile_distance_s","govern_together","opposition_together")]), ]
  mw <- feols(as.formula(paste(dv_w, "~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr")),
              data = dsw, cluster = ~cntryyr)
  print(summary(mw))
  bw <- coef(mw)[["to_pfeml"]]
  nw <- nobs(mw)
} else {
  bw <- NA; nw <- NA
}

if (length(men_dv) > 0) {
  dv_m <- men_dv[1]
  dsm <- df[complete.cases(df[, c(dv_m,"to_pfeml","rile_distance_s","govern_together","opposition_together")]), ]
  mm <- feols(as.formula(paste(dv_m, "~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr")),
              data = dsm, cluster = ~cntryyr)
  print(summary(mm))
  bm <- coef(mm)[["to_pfeml"]]
  nm <- nobs(mm)
} else {
  bm <- NA; nm <- NA
}

cat(sprintf("RESULT:n_obs=%d\n", nrow(dsub)))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nrow(dsub)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_election_studies))
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", b0_pfeml))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", b2_pfeml))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", b2_rile))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", b2_gov))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", b2_opp))
if (!is.na(bw)) {
  cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", bw))
  cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nw))
}
if (!is.na(bm)) {
  cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", bm))
  cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nm))
}