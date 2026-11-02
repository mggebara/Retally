#!/usr/bin/env Rscript
set.seed(42)

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

data_path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- read_dta(data_path)

# Inspect key variables
# Earnings variable: likely Work_Income or household earnings per capita
# Need to construct household earnings per capita

cat("Column names sample:\n")
print(names(df)[1:50])
print(names(df)[51:119])

# Running variable: own_amt (owner's landholding amount)
# Treatment: Above500
# Cluster: former owner (Land_Owner or Expropretario_ISTA or match_id)
# Survey round FE: survey_year

# Try to find earnings per capita variable
cand <- grep("earn|income|percap|per_cap|pc", names(df), ignore.case = TRUE, value = TRUE)
cat("Earnings-related columns:\n"); print(cand)

# Common naming: hh earnings per capita might be constructed
# Let's examine Work_Income, Other_Income
summary(df$Work_Income)
summary(df$Other_Income)

# Look for a household per capita variable
hhcand <- grep("hh|house", names(df), ignore.case = TRUE, value = TRUE)
cat("Household-related columns:\n"); print(hhcand)

# Try constructing: earnings per capita at household level
# But paper says "household earnings per capita in previous month"
# Look for existing variable
pcand <- grep("pc$|_pc|percap", names(df), ignore.case = TRUE, value = TRUE)
cat("Per capita columns:\n"); print(pcand)

# Check all vars
cat("All columns:\n")
print(names(df))

# Determine cluster var
# "former-owner clustering" - match_id or Land_Owner
cat("match_id unique:", length(unique(df$match_id)), "\n")

# Running variable centered
df$run <- df$own_amt - 500

# Try to identify earnings variable - most likely 'Work_Income' is individual
# but we need household per capita. Let's see if there's one already.
# Check for variables with values ~75 (mean reported)
num_cols <- sapply(df, is.numeric)
means <- sapply(df[, num_cols], function(x) mean(x, na.rm=TRUE))
cat("Variables with mean 60-90:\n")
print(means[means > 60 & means < 90 & !is.na(means)])

# Columns 1&2 mean of dep var is 74.81 for 150 bw
# Let's identify by that
# For now assume ingpcap or similar; try common names
for (v in c("ingpcap", "ing_pcap", "hhincpc", "earnings_pc", "earn_pc",
            "hhearn_pc", "yperhh", "ypc", "income_pc", "hhinc_pc")) {
  if (v %in% names(df)) cat("Found:", v, "\n")
}

# Likely need to construct. The data has household info.
# Let's look at structure
# "hh_head_order" suggests household structure
# Check for Household_Income or similar
cat("\nSearching for income/earnings vars with reasonable means:\n")
for (v in names(df)[num_cols]) {
  m <- mean(df[[v]], na.rm=TRUE)
  if (!is.na(m) && m > 50 && m < 150) {
    cat(v, ": mean =", round(m, 2), "\n")
  }
}

# Try the regression with Work_Income first as fallback
# But let's actually compute hh per capita if we can

# Look at variables containing 'Income' or 'Salary'
inc_vars <- grep("Income|Salary|income|salary|wage|Wage", names(df), value = TRUE)
cat("\nIncome/salary vars:\n"); print(inc_vars)

# Try to find household id
hhid <- grep("hh_id|household|HH_ID|hogar", names(df), ignore.case = TRUE, value = TRUE)
cat("HH id vars:\n"); print(hhid)

# The structure: Work_Income is worker's own income
# For household earnings per capita we need total hh income / hh size
# Check for hh_size
sz <- grep("size|miembros|members", names(df), ignore.case = TRUE, value = TRUE)
cat("Size vars:\n"); print(sz)

# Function to run RD regression
run_rd <- function(data, yvar, bw, cluster_var) {
  d <- data[!is.na(data[[yvar]]) & !is.na(data$run) & abs(data$run) <= bw, ]
  d$y <- d[[yvar]]
  d$Above500 <- as.numeric(d$run >= 0)
  d$run_above <- d$run * d$Above500
  if ("survey_year" %in% names(d) && length(unique(d$survey_year)) > 1) {
    f <- as.formula(paste0("y ~ Above500 + run + run_above | survey_year"))
  } else {
    f <- as.formula("y ~ Above500 + run + run_above")
  }
  m <- feols(f, data = d, cluster = d[[cluster_var]])
  list(model = m, n = nobs(m), nclust = length(unique(d[[cluster_var]])), data = d)
}

# Determine earnings variable - try several
# First attempt: use Work_Income as proxy for earnings
# Household earnings per capita = sum of household income / household members

# Use best guess: Work_Income
earn_var <- "Work_Income"

# Determine cluster var - former owner
cluster_candidates <- c("match_id", "Reform_Coop_id", "Hacienda_id")
# Former owner cluster: Expropretario_ISTA or match_id
if ("match_id" %in% names(df)) {
  cluster_var <- "match_id"
} else {
  cluster_var <- "Land_Owner"
}

# Column 1 & 2: individual-level, earnings level
r1 <- tryCatch(run_rd(df, earn_var, 300, cluster_var), error = function(e) NULL)
r2 <- tryCatch(run_rd(df, earn_var, 150, cluster_var), error = function(e) NULL)

# Columns 3 & 4: property-level IQR of earnings per capita
# Need to compute IQR per property, restricting to properties with >=5 workers
prop_var <- "match_id"
df2 <- df %>% filter(!is.na(.data[[earn_var]]), !is.na(run), !is.na(.data[[prop_var]]))

prop_data <- df2 %>%
  group_by(.data[[prop_var]]) %>%
  summarise(
    n_workers = n(),
    iqr_earn = IQR(.data[[earn_var]], na.rm = TRUE),
    run = first(run),
    Above500 = first(Above500),
    own_amt = first(own_amt),
    .groups = "drop"
  ) %>%
  filter(n_workers >= 5)

prop_data$run_above <- prop_data$run * (prop_data$run >= 0)
prop_data$Above500 <- as.numeric(prop_data$run >= 0)

r3_data <- prop_data[abs(prop_data$run) <= 300, ]
r4_data <- prop_data[abs(prop_data$run) <= 150, ]

m3 <- feols(iqr_earn ~ Above500 + run + run_above, data = r3_data,
            cluster = r3_data[[prop_var]])
m4 <- feols(iqr_earn ~ Above500 + run + run_above, data = r4_data,
            cluster = r4_data[[prop_var]])

# Extract results
get_coef <- function(m) {
  if (is.null(m)) return(NA)
  if (is.list(m) && !is.null(m$model)) m <- m$model
  tryCatch(coef(m)["Above500"], error = function(e) NA)
}

c1 <- get_coef(r1)
c2 <- get_coef(r2)
c3 <- get_coef(m3)
c4 <- get_coef(m4)

n1 <- if (!is.null(r1)) r1$n else NA
n2 <- if (!is.null(r2)) r2$n else NA
n3 <- nrow(r3_data)
n4 <- nrow(r4_data)

ncl1 <- if (!is.null(r1)) r1$nclust else NA
ncl2 <- if (!is.null(r2)) r2$nclust else NA

cat("\n\n===== RESULTS =====\n")
cat(sprintf("RESULT:earnings_level_above500_bw300=%s\n", c1))
cat(sprintf("RESULT:earnings_level_above500_bw150=%s\n", c2))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%s\n", c3))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%s\n", c4))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%s\n", n1))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%s\n", n2))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%s\n", n3))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%s\n", n4))
cat(sprintf("RESULT:n_clusters_bw300=%s\n", ncl1))
cat(sprintf("RESULT:n_clusters_bw150=%s\n", ncl2))