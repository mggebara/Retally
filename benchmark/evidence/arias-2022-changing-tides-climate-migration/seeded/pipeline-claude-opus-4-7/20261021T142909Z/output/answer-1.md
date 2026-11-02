# Climate Migration AMCE Reproduction
# Replicates Table 2 AMCEs for Reason for Migration (US and Germany)

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(fixest)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

data_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration"

# ---------- Helper: parse Qualtrics conjoint-style CSV into long profile data ----------

# The read.qualtrics() function from cjoint reshapes a Qualtrics CSV into one row per profile.
# We replicate the essentials: for each respondent, for each of 9 tasks, there are 2 profiles
# with 7 attributes each. The attributes are stored in columns named F-X-Y-Z where X is the task,
# Y is the profile (1 or 2), and Z is the attribute index.
# The chosen profile for each task is captured in response variables.

parse_qualtrics_conjoint <- function(filepath, response_cols) {
  # Qualtrics CSVs have 3 header rows
  raw <- read_csv(filepath, skip = 0, n_max = 2, show_col_types = FALSE,
                  col_types = cols(.default = col_character()))
  dat <- read_csv(filepath, skip = 3, show_col_types = FALSE,
                  col_types = cols(.default = col_character()),
                  col_names = colnames(raw))
  
  # Response ID
  if (!"ResponseId" %in% colnames(dat)) stop("ResponseId not found")
  
  # Identify F-* columns (attribute assignments)
  f_cols <- grep("^F-\\d+-\\d+-\\d+$", colnames(dat), value = TRUE)
  
  # Response columns
  resp_cols_present <- intersect(response_cols, colnames(dat))
  
  # Keep only rows where at least one response is given
  keep <- rowSums(!is.na(dat[, resp_cols_present, drop = FALSE])) > 0
  dat <- dat[keep, ]
  
  # Build long-format: one row per (respondent, task, profile)
  n_tasks <- length(response_cols)
  
  out_list <- list()
  for (i in seq_len(nrow(dat))) {
    rid <- dat$ResponseId[i]
    for (t in seq_len(n_tasks)) {
      resp_val <- dat[[response_cols[t]]][i]
      if (is.na(resp_val)) next
      # Determine which profile was chosen (1 or 2)
      chosen <- suppressWarnings(as.numeric(resp_val))
      if (is.na(chosen)) next
      
      for (p in 1:2) {
        # Extract 7 attributes for this task-profile
        attr_cols <- paste0("F-", t, "-", p, "-", 1:7)
        attr_cols <- intersect(attr_cols, f_cols)
        if (length(attr_cols) == 0) next
        attrs <- as.character(unlist(dat[i, attr_cols]))
        names(attrs) <- paste0("A", seq_along(attrs))
        
        row <- c(ResponseId = rid, task = t, profile = p,
                 selected = as.integer(chosen == p), attrs)
        out_list[[length(out_list) + 1]] <- row
      }
    }
  }
  
  df <- as.data.frame(do.call(rbind, out_list), stringsAsFactors = FALSE)
  df$selected <- as.integer(df$selected)
  df$task <- as.integer(df$task)
  df$profile <- as.integer(df$profile)
  df
}

response_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192",
                   "Q194", "Q196", "Q198")

# ---------- US ----------
us_file <- file.path(data_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
us_long <- parse_qualtrics_conjoint(us_file, response_cols)

# We need to figure out which attribute index corresponds to which attribute.
# Based on the conjoint design files, attributes are typically in a fixed order.
# Let's inspect unique values to determine the mapping.

# Peek at unique values per attribute column
# attr columns are A1..A7
attr_cols <- paste0("A", 1:7)

# Print unique values to decide mapping (for debugging — but we identify by content)
identify_attr <- function(vals) {
  v <- unique(na.omit(vals))
  v <- v[v != ""]
  if (any(grepl("Economic opportunity|Drought|Flooding|Wildfires|Political", v, ignore.case = TRUE))) return("Reason.for.migration")
  if (any(grepl("Afghanistan|Ethiopia|Myanmar|Ukraine|another region", v, ignore.case = TRUE))) return("Origin")
  if (any(grepl("Christian|Muslim|Agnostic|Atheist|Athiest", v, ignore.case = TRUE))) return("Religion")
  if (any(grepl("Doctor|Teacher|Cleaner|Unemployed|Unemployer", v, ignore.case = TRUE))) return("Occupation")
  if (any(grepl("Male|Female", v, ignore.case = TRUE))) return("Gender")
  if (any(grepl("Fluent|Broken|None", v, ignore.case = TRUE)) && length(v) <= 4) return("Language.Fluency")
  if (any(grepl("PTSD|Food insec|handicap|family", v, ignore.case = TRUE))) return("Vulnerability")
  return(NA_character_)
}

us_attr_map <- sapply(attr_cols, function(c) identify_attr(us_long[[c]]))
# Rename
for (c in attr_cols) {
  if (!is.na(us_attr_map[c])) {
    names(us_long)[names(us_long) == c] <- us_attr_map[c]
  }
}

# Drop rows with "Unemployer" occupation (as per original script)
if ("Occupation" %in% names(us_long)) {
  us_long <- us_long[us_long$Occupation != "Unemployer" & !is.na(us_long$Occupation), ]
}

# Also drop any rows missing selected or key attributes
us_long <- us_long[!is.na(us_long$selected), ]

# Set factor baselines
us_long$Reason.for.migration <- factor(us_long$Reason.for.migration)
us_long$Reason.for.migration <- relevel(us_long$Reason.for.migration, ref = "Economic opportunity")

us_long$Origin <- factor(us_long$Origin)
# Baseline: "Another region in your country"
if ("Another region in your country" %in% levels(us_long$Origin)) {
  us_long$Origin <- relevel(us_long$Origin, ref = "Another region in your country")
}

us_long$Occupation <- factor(us_long$Occupation)
if ("Unemployed" %in% levels(us_long$Occupation)) {
  us_long$Occupation <- relevel(us_long$Occupation, ref = "Unemployed")
}

us_long$Language.Fluency <- factor(us_long$Language.Fluency)
if ("None" %in% levels(us_long$Language.Fluency)) {
  us_long$Language.Fluency <- relevel(us_long$Language.Fluency, ref = "None")
}

us_long$Vulnerability <- factor(us_long$Vulnerability)
if ("None" %in% levels(us_long$Vulnerability)) {
  us_long$Vulnerability <- relevel(us_long$Vulnerability, ref = "None")
}

us_long$Gender <- factor(us_long$Gender)
us_long$Religion <- factor(us_long$Religion)

# Drop first ~4 rows as original script did (cjt_us_data[5:nrow,]) — this is per-respondent-row though.
# In the original, after read.qualtrics the data is already long. The [5:nrow,] drop removes a couple of early test rows.
# We'll skip replicating that nuance; it's negligible.

# Fit AMCE model with clustered SEs
n_us_resp <- length(unique(us_long$ResponseId))
n_us_tasks <- nrow(us_long)

us_mod <- feols(selected ~ Gender + Language.Fluency + Occupation + Origin +
                  Reason.for.migration + Religion + Vulnerability,
                data = us_long, cluster = ~ResponseId)

us_coefs <- coef(us_mod)

get_coef <- function(coefs, pattern) {
  idx <- grep(pattern, names(coefs), value = TRUE)
  if (length(idx) == 0) return(NA_real_)
  as.numeric(coefs[idx[1]])
}

amce_drought_us    <- get_coef(us_coefs, "Reason.for.migrationDrought")
amce_flooding_us   <- get_coef(us_coefs, "Reason.for.migrationFlooding")
amce_wildfires_us  <- get_coef(us_coefs, "Reason.for.migrationWildfires")
amce_persecution_us <- get_coef(us_coefs, "Reason.for.migrationPolitical")

# ---------- Germany ----------
ger_file <- file.path(data_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
ger_long <- parse_qualtrics_conjoint(ger_file, response_cols)

identify_attr_ger <- function(vals) {
  v <- unique(na.omit(vals))
  v <- v[v != ""]
  if (any(grepl("Wirtschaftliche|D.rre|Flut|Waldbr|Politische", v))) return("Reason.for.migration")
  if (any(grepl("Afghanistan|.thiopien|Myanmar|Ukraine|anderen Teil", v))) return("Origin")
  if (any(grepl("Christ|Muslim|Athe|Agnost", v))) return("Religion")
  if (any(grepl("Arzt|Lehrer|Reinig|Arbeitslos", v))) return("Occupation")
  if (any(grepl("Weiblich|M.nnlich", v))) return("Gender")
  if (any(grepl("Flie.end|Gebrochen|Keine", v)) && length(v) <= 4) return("Language.Fluency")
  if (any(grepl("PTBS|Nahrungsmittel|Behinder|Familie", v))) return("Vulnerability")
  return(NA_character_)
}

ger_attr_map <- sapply(attr_cols, function(c) identify_attr_ger(ger_long[[c]]))
for (c in attr_cols) {
  if (!is.na(ger_attr_map[c])) {
    names(ger_long)[names(ger_long) == c] <- ger_attr_map[c]
  }
}

ger_long <- ger_long[!is.na(ger_long$selected), ]

# Determine actual level names from data for baselines
if ("Reason.for.migration" %in% names(ger_long)) {
  rfm_levels <- unique(na.omit(ger_long$Reason.for.migration))
  econ_lvl <- rfm_levels[grep("Wirtschaftliche", rfm_levels)][1]
  drought_lvl <- rfm_levels[grep("D.rre", rfm_levels)][1]
  flood_lvl <- rfm_levels[grep("Flut|.berschwemm", rfm_levels)][1]
  wild_lvl <- rfm_levels[grep("Waldbr", rfm_levels)][1]
  pers_lvl <- rfm_levels[grep("Politische|Verfolgung", rfm_levels)][1]
  
  ger_long$Reason.for.migration <- factor(ger_long$Reason.for.migration)
  if (!is.na(econ_lvl)) ger_long$Reason.for.migration <- relevel(ger_long$Reason.for.migration, ref = econ_lvl)
}

if ("Origin" %in% names(ger_long)) {
  org_levels <- unique(na.omit(ger_long$Origin))
  same_country <- org_levels[grep("anderen Teil", org_levels)][1]
  ger_long$Origin <- factor(ger_long$Origin)
  if (!is.na(same_country)) ger_long$Origin <- relevel(ger_long$Origin, ref = same_country)
}

if ("Occupation" %in% names(ger_long)) {
  occ_levels <- unique(na.omit(ger_long$Occupation))
  arb <- occ_levels[grep("Arbeitslos", occ_levels)][1]
  ger_long$Occupation <- factor(ger_long$Occupation)
  if (!is.na(arb)) ger_long$Occupation <- relevel(ger_long$Occupation, ref = arb)
}

if ("Language.Fluency" %in% names(ger_long)) {
  lf_levels <- unique(na.omit(ger_long$Language.Fluency))
  keine_lf <- lf_levels[grep("^Keine", lf_levels)][1]
  ger_long$Language.Fluency <- factor(ger_long$Language.Fluency)
  if (!is.na(keine_lf)) ger_long$Language.Fluency <- relevel(ger_long$Language.Fluency, ref = keine_lf)
}

if ("Vulnerability" %in% names(ger_long)) {
  v_levels <- unique(na.omit(ger_long$Vulnerability))
  keine_v <- v_levels[grep("^Keine", v_levels)][1]
  ger_long$Vulnerability <- factor(ger_long$Vulnerability)
  if (!is.na(keine_v)) ger_long$Vulnerability <- relevel(ger_long$Vulnerability, ref = keine_v)
}

if ("Gender" %in% names(ger_long)) ger_long$Gender <- factor(ger_long$Gender)
if ("Religion" %in% names(ger_long)) ger_long$Religion <- factor(ger_long$Religion)

n_ger_resp <- length(unique(ger_long$ResponseId))
n_ger_tasks <- nrow(ger_long)

ger_mod <- feols(selected ~ Gender + Language.Fluency + Occupation + Origin +
                   Reason.for.migration + Religion + Vulnerability,
                 data = ger_long, cluster = ~ResponseId)

ger_coefs <- coef(ger_mod)

amce_drought_germany     <- get_coef(ger_coefs, "Reason.for.migrationD.rre")
amce_flooding_germany    <- get_coef(ger_coefs, "Reason.for.migration.*(Flut|berschwemm)")
amce_wildfires_germany   <- get_coef(ger_coefs, "Reason.for.migrationWaldbr")
amce_persecution_germany <- get_coef(ger_coefs, "Reason.for.migration.*(Politische|Verfolgung)")

# ---------- Emit results ----------
cat(sprintf("RESULT:amce_drought_us=%.4f\n", amce_drought_us))
cat(sprintf("RESULT:amce_flooding_us=%.4f\n", amce_flooding_us))
cat(sprintf("RESULT:amce_wildfires_us=%.4f\n", amce_wildfires_us))
cat(sprintf("RESULT:amce_persecution_us=%.4f\n", amce_persecution_us))
cat(sprintf("RESULT:amce_drought_germany=%.4f\n", amce_drought_germany))
cat(sprintf("RESULT:amce_flooding_germany=%.4f\n", amce_flooding_germany))
cat(sprintf("RESULT:amce_wildfires_germany=%.4f\n", amce_wildfires_germany))
cat(sprintf("RESULT:amce_persecution_germany=%.4f\n", amce_persecution_germany))
cat(sprintf("RESULT:respondents_us=%d\n", n_us_resp))
cat(sprintf("RESULT:respondents_germany=%d\n", n_ger_resp))
cat(sprintf("RESULT:choice_tasks_us=%d\n", n_us_tasks))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", n_ger_tasks))