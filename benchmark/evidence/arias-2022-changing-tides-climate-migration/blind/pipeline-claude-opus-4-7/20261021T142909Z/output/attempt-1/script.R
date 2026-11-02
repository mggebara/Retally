# Reproduction script for Arias et al. "Changing Tides"
# Study 1: Conjoint experiment AMCEs

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(fixest)
})

set.seed(42)

base_path <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"

us_file <- file.path(base_path, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
de_file <- file.path(base_path, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

# Qualtrics files have 2 header rows; use the first as names, skip the 2nd and 3rd metadata row
read_qualtrics <- function(path) {
  hdr <- read_csv(path, n_max = 0, show_col_types = FALSE)
  df <- read_csv(path, skip = 3, col_names = names(hdr), show_col_types = FALSE,
                 guess_max = 20000)
  df
}

us <- read_qualtrics(us_file)
de <- read_qualtrics(de_file)

# Keep only finished respondents (Finished == TRUE/1)
# Qualtrics Finished may be "True"/"False" or 1/0
norm_fin <- function(x) {
  if (is.logical(x)) return(x)
  if (is.numeric(x)) return(x == 1)
  xl <- tolower(as.character(x))
  xl %in% c("true", "1", "yes")
}

us <- us %>% filter(norm_fin(Finished))
de <- de %>% filter(norm_fin(Finished))

# Identify the conjoint attribute columns.
# Qualtrics conjoint typically produces variables named like F-1-1, F-1-2 etc. or Fx-y
# plus a choice variable per task. Let's find columns matching conjoint attributes.

# Build the long format: for each respondent, 9 tasks x 2 profiles x 7 attributes
# The attribute columns in Qualtrics-style conjoints often look like "F-{task}-{attr}-{profile}"
# or similar. Let's inspect column names.

parse_conjoint <- function(df, sample_label) {
  nm <- names(df)
  # Pattern 1: F-{task}-{profile}-{attr} or F-{task}-{attr}-{profile}
  # Try to detect
  patt <- grep("^F-\\d+-\\d+-\\d+$", nm, value = TRUE)
  if (length(patt) == 0) {
    patt <- grep("^F\\.\\d+\\.\\d+\\.\\d+$", nm, value = TRUE)
  }
  patt
}

# Let's look at columns to figure out the structure
cat("US columns matching 'F-' or 'F.':\n", file = stderr())
f_us <- grep("^F[-\\.]", names(us), value = TRUE)
cat(head(f_us, 30), sep = "\n", file = stderr())
cat("\nDE columns matching 'F-' or 'F.':\n", file = stderr())
f_de <- grep("^F[-\\.]", names(de), value = TRUE)
cat(head(f_de, 30), sep = "\n", file = stderr())

# Also look for choice outcome column names
cat("\nUS Q columns sample:\n", file = stderr())
cat(head(grep("^Q", names(us), value=TRUE), 50), sep="\n", file=stderr())

# Try to find conjoint attribute columns. In Qualtrics conjoints they often have format
# like "F-1-1" (task 1, attribute 1) and the value is the level number for the first profile
# But typical layout:  "F-{task}-{attribute}" -> array of levels, one per profile
# Then rating / choice stored separately.

# Build attribute long dataset
# Try matching F-task-attribute pattern -> each cell contains a level string

f_cols_us <- grep("^F-\\d+-\\d+", names(us), value = TRUE)
f_cols_de <- grep("^F-\\d+-\\d+", names(de), value = TRUE)

cat("\nnum F cols US:", length(f_cols_us), "\n", file=stderr())
cat("num F cols DE:", length(f_cols_de), "\n", file=stderr())

# Try pattern F-task-profile-attribute (4 numbers) - more common
# Actually Qualtrics stores as F-{set}-{profile}-{attribute}
split_fcols <- function(cols) {
  parts <- str_match(cols, "^F-(\\d+)-(\\d+)-(\\d+)$")
  if (all(is.na(parts[,1]))) {
    parts <- str_match(cols, "^F-(\\d+)-(\\d+)$")
    if (all(is.na(parts[,1]))) return(NULL)
    data.frame(col = cols, task = as.integer(parts[,2]), attr = as.integer(parts[,3]),
               profile = NA)
  } else {
    data.frame(col = cols, task = as.integer(parts[,2]), profile = as.integer(parts[,3]),
               attr = as.integer(parts[,4]))
  }
}

us_meta <- split_fcols(f_cols_us)
de_meta <- split_fcols(f_cols_de)

cat("\nUS meta head:\n", file=stderr())
print(head(us_meta), file=stderr())
cat("\nUS unique attrs:", sort(unique(us_meta$attr)), "\n", file=stderr())
cat("US unique tasks:", sort(unique(us_meta$task)), "\n", file=stderr())
cat("US unique profiles:", sort(unique(us_meta$profile)), "\n", file=stderr())

# Find choice columns - typically "choice" or Q followed by task number
choice_candidates_us <- grep("choice|Choice|CHOICE", names(us), value = TRUE)
cat("\nUS choice candidates:", choice_candidates_us, "\n", file=stderr())
choice_candidates_de <- grep("choice|Choice|CHOICE", names(de), value = TRUE)
cat("DE choice candidates:", choice_candidates_de, "\n", file=stderr())

# Also look for rating / selection vars  
cat("\nUS all cols around Q60-Q80:\n", file=stderr())
qcols <- grep("^Q[0-9]+", names(us), value=TRUE)
cat(head(qcols, 80), sep="\n", file=stderr())

# Build long data: one row per (respondent, task, profile)
make_long <- function(df, meta, resp_id = "ResponseId") {
  # pivot the F columns to long
  dfl <- df %>%
    select(all_of(c(resp_id, meta$col))) %>%
    pivot_longer(cols = -all_of(resp_id), names_to = "col", values_to = "level") %>%
    left_join(meta, by = "col") %>%
    select(-col) %>%
    pivot_wider(names_from = attr, values_from = level, names_prefix = "attr_")
  dfl
}

us_long <- make_long(us, us_meta)
de_long <- make_long(de, de_meta)

cat("\nUS long head:\n", file=stderr())
print(head(us_long), file=stderr())
cat("US long nrow:", nrow(us_long), "\n", file=stderr())
cat("DE long nrow:", nrow(de_long), "\n", file=stderr())

# Now find choice outcome. In this design, respondent picks 1 of 2 profiles per task.
# Choice variable likely named like "choice1".."choice9" or similar.
# Let's search for columns that look numeric with values in {1,2}

guess_choice_cols <- function(df, n_tasks = 9) {
  nm <- names(df)
  cands <- c()
  for (c in nm) {
    v <- df[[c]]
    if (is.character(v) || is.numeric(v)) {
      vv <- suppressWarnings(as.numeric(v))
      vv <- vv[!is.na(vv)]
      if (length(vv) > 50 && all(vv %in% c(1, 2))) {
        cands <- c(cands, c)
      }
    }
  }
  cands
}

us_choice_cands <- guess_choice_cols(us)
cat("\nUS choice candidate cols (values in {1,2}):", head(us_choice_cands, 30), "\n", file=stderr())
de_choice_cands <- guess_choice_cols(de)
cat("DE choice candidate cols:", head(de_choice_cands, 30), "\n", file=stderr())

# Need to find 9 choice cols for 9 tasks. Let's look for patterns
# Typically Qualtrics forced-choice names them like "Q{num}" where num is sequential
# Try to find exactly 9 cols that correspond to the 9 tasks

# Also look for columns with "select" in name
sel_us <- grep("select|Select|SELECT|pick|Pick", names(us), value = TRUE)
cat("\nUS select cols:", sel_us, "\n", file=stderr())

# Look for all columns ordered - group of 9 consecutive Q cols with values 1/2
# A simpler approach: find all cols with values exclusively in {1,2,NA} and non-trivial length
usable_us <- us_choice_cands

# Try to find 9 such columns that align with F columns in position
# Print column indices
cat("\nUS F col indices:\n", file=stderr())
print(which(names(us) %in% head(f_cols_us, 10)), file=stderr())

cat("\nUS choice cand indices:\n", file=stderr())
cc_idx <- which(names(us) %in% us_choice_cands)
print(cc_idx, file=stderr())
cat("Names of first choice cands with indices:\n", file=stderr())
print(data.frame(idx = cc_idx, name = names(us)[cc_idx]), file=stderr())

# The user wants us to produce AMCEs. Let's assume for now choice variables are named Q{something}_1 or similar.
# Based on common Qualtrics conjoints, forced-choice uses QID or named like "pair1_choice" etc.

# Let me try a different approach - find all column names and look for patterns
all_us_names <- names(us)
# print all names containing digit followed by letter patterns
# print columns 1:200 
cat("\n\nUS cols 1-100:\n", file=stderr())
cat(all_us_names[1:min(100, length(all_us_names))], sep="\n", file=stderr())

# Let's try to proceed with the most likely setup. We'll fall back to patterns.
# Many Arias-style conjoints label pair choice as "Pair{i}_Choice" or similar.
# Let me check by scanning for cols with pair in them.
pair_us <- grep("pair|Pair|PAIR", names(us), value = TRUE)
cat("\nUS pair cols:", pair_us, "\n", file=stderr())
pair_de <- grep("pair|Pair|PAIR", names(de), value = TRUE)
cat("DE pair cols:", pair_de, "\n", file=stderr())

# Look for cols that are forced-choice related - likely containing a certain word
# Just dump unique cols containing numbers 1-9 as suffix
cat("\n\nUS cols with Q plus number plus underscore:\n", file=stderr())
cat(grep("Q\\d+_\\d+", names(us), value=TRUE)[1:30], sep="\n", file=stderr())

# Given uncertainty, let's try one more thing: look for columns right after the F columns
f_last_idx_us <- max(which(names(us) %in% f_cols_us))
cat("\nUS columns around last F col (indices", f_last_idx_us-5, "to", f_last_idx_us+15, "):\n", file=stderr())
print(data.frame(idx = (f_last_idx_us-5):(f_last_idx_us+30), 
                 name = names(us)[(f_last_idx_us-5):(f_last_idx_us+30)]), file=stderr())

# Try to detect: columns labeled like Q10, Q11, ... Q18 or similar with values 1/2
# Let's collect Q columns that look like forced-choice
qnum_cols <- function(df) {
  nm <- names(df)
  cands <- grep("^Q\\d+$", nm, value = TRUE)
  res <- c()
  for (c in cands) {
    v <- suppressWarnings(as.numeric(df[[c]]))
    vv <- v[!is.na(v)]
    if (length(vv) > 50 && all(vv %in% c(1,2))) res <- c(res, c)
  }
  res
}

us_q12 <- qnum_cols(us)
de_q12 <- qnum_cols(de)
cat("\nUS Q{num} cols with 1/2:", us_q12, "\n", file=stderr())
cat("DE Q{num} cols with 1/2:", de_q12, "\n", file=stderr())

# Based on the paper, there are 9 forced-choice tasks per respondent. Need to identify these.
# Report preliminary respondent counts
n_us <- nrow(us)
n_de <- nrow(de)

# Build analysis dataset
# Attribute order (from paper):
# 1: Reason for migration (5 levels)
# 2: Language fluency
# 3: Gender
# 4: Occupation
# 5: Religion
# 6: Origin
# 7: Vulnerability
# But actual order in Qualtrics may differ. Let's examine levels per attribute.

for (a in sort(unique(us_meta$attr))) {
  cols <- us_meta$col[us_meta$attr == a]
  vals <- unique(unlist(lapply(cols, function(c) us[[c]])))
  vals <- vals[!is.na(vals)][1:min(10, length(vals))]
  cat("US attr", a, "sample vals:", vals, "\n", file=stderr())
}

# Pick choice columns. If we have 9 candidates in us_q12, use them.
# Otherwise try all cands that have numeric 1/2 only
pick_choice_cols <- function(cands, n = 9) {
  if (length(cands) >= n) return(cands[1:n])
  cands
}

us_choice_cols <- if (length(us_q12) >= 9) us_q12[1:9] else head(us_choice_cands, 9)
de_choice_cols <- if (length(de_q12) >= 9) de_q12[1:9] else head(de_choice_cands, 9)

cat("\nSelected US choice cols:", us_choice_cols, "\n", file=stderr())
cat("Selected DE choice cols:", de_choice_cols, "\n", file=stderr())

build_dataset <- function(df, meta, choice_cols) {
  resp <- "ResponseId"
  n_tasks <- length(choice_cols)
  # Long-format: one row per (resp, task, profile)
  recs <- list()
  attrs <- sort(unique(meta$attr))
  for (ti in seq_len(n_tasks)) {
    cc <- choice_cols[ti]
    choice_val <- suppressWarnings(as.numeric(df[[cc]]))
    for (pi in 1:2) {
      row <- data.frame(ResponseId = df[[resp]], task = ti, profile = pi,
                        chosen = as.integer(choice_val == pi))
      for (a in attrs) {
        colnm <- meta$col[meta$task == ti & meta$profile == pi & meta$attr == a]
        if (length(colnm) == 1) {
          row[[paste0("attr", a)]] <- df[[colnm]]
        } else {
          row[[paste0("attr", a)]] <- NA
        }
      }
      recs[[length(recs) + 1]] <- row
    }
  }
  do.call(rbind, recs)
}

us_data <- build_dataset(us, us_meta, us_choice_cols)
de_data <- build_dataset(de, de_meta, de_choice_cols)

cat("\nUS data head:\n", file=stderr())
print(head(us_data), file=stderr())
cat("US data nrow:", nrow(us_data), "\n", file=stderr())
cat("DE data nrow:", nrow(de_data), "\n", file=stderr())

# Identify which attribute is "Reason for migration"
# The 5 levels: economic opportunity, drought, flooding, wildfires, political/religious/ethnic persecution
# Check each attribute's levels
reason_attr_us <- NULL
for (a in sort(unique(us_meta$attr))) {
  col <- paste0("attr", a)
  if (col %in% names(us_data)) {
    uv <- unique(us_data[[col]])
    uv <- uv[!is.na(uv)]
    cat("US attr", a, "unique levels:", paste(uv, collapse=" | "), "\n", file=stderr())
    txt <- tolower(paste(uv, collapse = " "))
    if (grepl("drought|flood|wildfire|persecut|economic", txt)) {
      reason_attr_us <- a
    }
  }
}
cat("US reason attr =", reason_attr_us, "\n", file=stderr())

reason_attr_de <- NULL
for (a in sort(unique(de_meta$attr))) {
  col <- paste0("attr", a)
  if (col %in% names(de_data)) {
    uv <- unique(de_data[[col]])
    uv <- uv[!is.na(uv)]
    cat("DE attr", a, "unique levels:", paste(uv, collapse=" | "), "\n", file=stderr())
    txt <- tolower(paste(uv, collapse = " "))
    if (grepl("dürre|dur|flut|überschwemm|wald|verfolg|wirtschaft|drought|flood|wildfire", txt)) {
      reason_attr_de <- a
    }
  }
}
cat("DE reason attr =", reason_attr_de, "\n", file=stderr())

# Normalize reason levels to standard labels
norm_reason_us <- function(x) {
  xl <- tolower(as.character(x))
  out <- rep(NA_character_, length(x))
  out[grepl("economic", xl)] <- "economic"
  out[grepl("drought", xl)] <- "drought"
  out[grepl("flood", xl)] <- "flooding"
  out[grepl("wildfire|fire", xl)] <- "wildfires"
  out[grepl("persecut|political|religious|ethnic", xl)] <- "persecution"
  out
}

norm_reason_de <- function(x) {
  xl <- tolower(as.character(x))
  out <- rep(NA_character_, length(x))
  # German words: wirtschaftliche Möglichkeiten, Dürre, Überschwemmung, Waldbrände, politische/religiöse/ethnische Verfolgung
  out[grepl("wirtschaft|economic|möglich", xl)] <- "economic"
  out[grepl("dürre|durre|drought", xl)] <- "drought"
  out[grepl("überschwemm|uberschwemm|flut|flood", xl)] <- "flooding"
  out[grepl("waldbr|wildfire|brand", xl)] <- "wildfires"
  out[grepl("verfolg|persecut|politische|religiöse|ethnische", xl)] <- "persecution"
  out
}

# Run AMCE regressions
run_amce <- function(data, reason_attr, norm_fn) {
  rcol <- paste0("attr", reason_attr)
  data$reason <- norm_fn(data[[rcol]])
  data <- data[!is.na(data$reason) & !is.na(data$chosen), ]
  data$reason <- factor(data$reason, levels = c("economic","drought","flooding","wildfires","persecution"))
  
  # Also include other attributes as controls (as per standard AMCE spec)
  other_attrs <- setdiff(sort(unique(c(us_meta$attr, de_meta$attr))), reason_attr)
  rhs_cols <- c()
  for (a in other_attrs) {
    cn <- paste0("attr", a)
    if (cn %in% names(data)) {
      data[[cn]] <- factor(data[[cn]])
      if (length(levels(data[[cn]])) > 1) {
        rhs_cols <- c(rhs_cols, cn)
      }
    }
  }
  
  fml <- as.formula(paste("chosen ~ reason +", paste(rhs_cols, collapse = " + ")))
  m <- feols(fml, data = data, cluster = ~ResponseId)
  m
}

m_us <- run_amce(us_data, reason_attr_us, norm_reason_us)
m_de <- run_amce(de_data, reason_attr_de, norm_reason_de)

cat("\n--- US model ---\n", file=stderr())
print(summary(m_us), file=stderr())
cat("\n--- DE model ---\n", file=stderr())
print(summary(m_de), file=stderr())

coef_us <- coef(m_us)
coef_de <- coef(m_de)

amce_drought_us    <- coef_us[grep("drought", names(coef_us))]
amce_flooding_us   <- coef_us[grep("flooding", names(coef_us))]
amce_wildfires_us  <- coef_us[grep("wildfires", names(coef_us))]
amce_persecution_us<- coef_us[grep("persecution", names(coef_us))]

amce_drought_de    <- coef_de[grep("drought", names(coef_de))]
amce_flooding_de   <- coef_de[grep("flooding", names(coef_de))]
amce_wildfires_de  <- coef_de[grep("wildfires", names(coef_de))]
amce_persecution_de<- coef_de[grep("persecution", names(coef_de))]

choice_tasks_us <- nrow(us_data)
choice_tasks_de <- nrow(de_data)

cat(sprintf("RESULT:amce_drought_us=%.6f\n", as.numeric(amce_drought_us[1])))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n", as.numeric(amce_flooding_us[1])))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n", as.numeric(amce_wildfires_us[1])))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", as.numeric(amce_persecution_us[1])))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n", as.numeric(amce_drought_de[1])))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n", as.numeric(amce_flooding_de[1])))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n", as.numeric(amce_wildfires_de[1])))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", as.numeric(amce_persecution_de[1])))
cat(sprintf("RESULT:respondents_us=%d\n", n_us))
cat(sprintf("RESULT:respondents_germany=%d\n", n_de))
cat(sprintf("RESULT:choice_tasks_us=%d\n", choice_tasks_us))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", choice_tasks_de))