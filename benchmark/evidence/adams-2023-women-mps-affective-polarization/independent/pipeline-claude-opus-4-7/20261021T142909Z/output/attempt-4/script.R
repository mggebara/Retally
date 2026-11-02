#!/usr/bin/env Rscript

set.seed(42)

suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
  library(haven)
})

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

# List files in base to find all data
cat("Files in base:\n")
print(list.files(base, recursive=TRUE))

load(file.path(base, "dyadic_data_1-4-22.Rdata"))
df <- as.data.frame(updated_data)

cat("Columns:", paste(colnames(df), collapse=", "), "\n")
cat("Nrow raw:", nrow(df), "\n")

# Look for additional data files that might have women/men partisan DVs
other_files <- list.files(base, pattern="\\.(Rdata|RData|rda|rds|dta|csv)$", full.names=TRUE, ignore.case=TRUE)
cat("Data files:\n")
print(other_files)

# Try loading each
for (f in other_files) {
  if (f == file.path(base, "dyadic_data_1-4-22.Rdata")) next
  cat("Loading:", f, "\n")
  tryCatch({
    if (grepl("\\.(Rdata|RData|rda)$", f, ignore.case=TRUE)) {
      env <- new.env()
      load(f, envir=env)
      cat("  objects:", paste(ls(env), collapse=", "), "\n")
      for (nm in ls(env)) {
        obj <- get(nm, envir=env)
        if (is.data.frame(obj) || inherits(obj, "data.frame")) {
          cat("  ", nm, "nrow=", nrow(obj), " ncol=", ncol(obj), "\n")
          cat("  cols:", paste(colnames(obj), collapse=", "), "\n")
        }
      }
    } else if (grepl("\\.dta$", f, ignore.case=TRUE)) {
      d <- read_dta(f)
      cat("  nrow=", nrow(d), " ncol=", ncol(d), "\n")
      cat("  cols:", paste(colnames(d), collapse=", "), "\n")
    } else if (grepl("\\.rds$", f, ignore.case=TRUE)) {
      d <- readRDS(f)
      cat("  class=", class(d)[1], "\n")
      if (is.data.frame(d)) {
        cat("  nrow=", nrow(d), " ncol=", ncol(d), "\n")
        cat("  cols:", paste(colnames(d), collapse=", "), "\n")
      }
    }
  }, error = function(e) cat("  err:", conditionMessage(e), "\n"))
}

# The paper says ≥4 MPs. from_prior_seats and to_prior_seats go 0-999
# but 999 likely means missing. Let's examine distribution
cat("\nto_prior_seats distribution:\n")
print(table(cut(df$to_prior_seats, c(-1,0,3,10,50,100,500,998,1000))))
cat("\nfrom_prior_seats distribution:\n")
print(table(cut(df$from_prior_seats, c(-1,0,3,10,50,100,500,998,1000))))

needed <- c("party_like","to_pfeml","rile_distance_s","govern_together","opposition_together")
dsub0 <- df[complete.cases(df[, needed]), ]
cat("N after complete.cases main:", nrow(dsub0), "\n")

# Try filter prior_seats >= 4 and != 999
dsub <- dsub0[dsub0$from_prior_seats >= 4 & dsub0$to_prior_seats >= 4 &
              dsub0$from_prior_seats != 999 & dsub0$to_prior_seats != 999, ]
cat("N after prior_seats >=4 and !=999:", nrow(dsub), "\n")

# Try other filter: just >=4 (treating 999 as valid)
dsub_v2 <- dsub0[dsub0$from_prior_seats >= 4 & dsub0$to_prior_seats >= 4, ]
cat("N after prior_seats >=4 only:", nrow(dsub_v2), "\n")

# Full model with country-year FE on filtered data
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

# For women/men partisan models - need individual-level data
# Try to find it in other files
women_coef <- NA; men_coef <- NA; nw <- NA; nm <- NA

for (f in other_files) {
  if (f == file.path(base, "dyadic_data_1-4-22.Rdata")) next
  tryCatch({
    dw <- NULL
    if (grepl("\\.(Rdata|RData|rda)$", f, ignore.case=TRUE)) {
      env <- new.env()
      load(f, envir=env)
      for (nm0 in ls(env)) {
        obj <- get(nm0, envir=env)
        if (is.data.frame(obj) && nrow(obj) > 100) {
          cols <- colnames(obj)
          # Look for women-partisan version of party_like
          w_cols <- grep("women|female|^w_|_w$|fem", cols, value=TRUE, ignore.case=TRUE)
          like_c <- grep("like|therm", cols, value=TRUE, ignore.case=TRUE)
          cat(f, "/", nm0, " women cols:", paste(w_cols, collapse=","), "\n")
          cat(f, "/", nm0, " like cols:", paste(like_c, collapse=","), "\n")
          if (any(grepl("women|female|fem", like_c, ignore.case=TRUE)) ||
              any(grepl("women|female|fem", cols, ignore.case=TRUE) & grepl("like|therm", cols, ignore.case=TRUE))) {
            dw <- obj
            assign(paste0("alt_", nm0), obj, envir=.GlobalEnv)
          }
        }
      }
    }
  }, error = function(e) {})
}

# Search specifically for party_like_women / party_like_men type columns in any loaded data frame
all_dfs <- Filter(function(x) is.data.frame(get(x)), ls())
cat("All data frames in global env:", paste(all_dfs, collapse=", "), "\n")
for (nm0 in all_dfs) {
  obj <- get(nm0)
  w_like <- grep("(like|therm).*w|w.*like|female|women|fem", colnames(obj), value=TRUE, ignore.case=TRUE)
  if (length(w_like)) {
    cat(nm0, ":", paste(w_like, collapse=","), "\n")
  }
}

# If separate women/men dyadic data exist as separate rdata, try common names
for (fn in c("dyadic_data_women.Rdata","dyadic_data_men.Rdata","women_dyadic.Rdata","men_dyadic.Rdata")) {
  fp <- file.path(base, fn)
  if (file.exists(fp)) {
    cat("Found:", fp, "\n")
    load(fp)
  }
}

# Try individual-level data load
indiv_files <- list.files(base, pattern="indiv|individ|stacked|cses", full.names=TRUE, ignore.case=TRUE)
cat("Indiv files:", paste(indiv_files, collapse=", "), "\n")

# Build women/men partisan dyadic DVs from individual-level if available
# For now, since the dataset only has one party_like, check if there's a gender indicator
# that would let us split
# Looking at columns, there's no obvious gender column. The paper uses CSES individual data,
# computes mean thermometer rating by partisan gender for each dyad.

# Try to find individual-level stacked data file
for (f in list.files(base, full.names=TRUE, recursive=TRUE)) {
  if (grepl("\\.(Rdata|RData|rda|rds|dta|csv)$", f, ignore.case=TRUE)) {
    cat("File:", f, " size=", file.info(f)$size, "\n")
  }
}

cat(sprintf("RESULT:n_obs=%d\n", nrow(dsub)))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nrow(dsub)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_election_studies))
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", b0_pfeml))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", b2_pfeml))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", b2_rile))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", b2_gov))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", b2_opp))