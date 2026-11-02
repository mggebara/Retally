suppressPackageStartupMessages({
  library(haven)
  library(survival)
  library(dplyr)
})

set.seed(42)

base_path <- "/Users/matthew/dev/Retally/.cache/datasets/grier_2023_sugar_roll_call_voting"

# Inspect data first
d1_raw <- read_dta(file.path(base_path, "SugarReplicate.dta"))
cat("Columns:", paste(names(d1_raw), collapse=", "), "\n")
cat("Nrow:", nrow(d1_raw), "\n")
print(head(d1_raw))

prep <- function(df) {
  df$yesvote <- ifelse(df$vote == "Aye", 1, 0)
  df$rsugcont <- ifelse(df$cong == 115, df$totalcont / 1.103, df$totalcont)
  df
}

# The paper has 186 obs for district FE and 106 for incumbent FE
# Current code gives 860 and 612 — way too many rows. The data likely has one row per
# member per congress but perhaps duplicated. 186 = 93 districts * 2 votes. 
# Need to figure out the right unit grouping. Likely id should be district id, not member id.

fit_clogit <- function(df, strata_var) {
  f <- as.formula(paste0("yesvote ~ rsugcont + ncu + tenure + poverty + bach + medincome + over65 + agcom + strata(", strata_var, ")"))
  clogit(f, data = df, method = "efron")
}

d1 <- prep(d1_raw)

# Try different strata variables - look for district identifier
cat("Unique id:", length(unique(d1$id)), "\n")
if ("district" %in% names(d1)) cat("Unique district:", length(unique(d1$district)), "\n")
if ("distid" %in% names(d1)) cat("Unique distid:", length(unique(d1$distid)), "\n")
if ("cd" %in% names(d1)) cat("Unique cd:", length(unique(d1$cd)), "\n")
if ("statedist" %in% names(d1)) cat("Unique statedist:", length(unique(d1$statedist)), "\n")
cat("Table cong:\n"); print(table(d1$cong))
cat("Table both:\n"); print(table(d1$both))

# 860 rows / something. Check: maybe there's one obs per contributor-member
# or we need to filter to unique member-vote
# Paper: 186 = district-vote observations in Table 1 district FE
# So dataset likely needs deduplication to one row per member-vote

# Check for duplicates
if ("name" %in% names(d1)) {
  cat("Unique names:", length(unique(d1$name)), "\n")
  dup_check <- d1 %>% group_by(id, cong) %>% summarise(n=n()) %>% ungroup()
  cat("Rows per id-cong:\n"); print(table(dup_check$n))
}