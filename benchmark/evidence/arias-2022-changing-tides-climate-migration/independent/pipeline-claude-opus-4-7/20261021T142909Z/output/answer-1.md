# Reproduce AMCEs from Arias & Blair (2022) Climate Migration conjoint
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(fixest)
  library(tibble)
})

set.seed(42)

data_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"

us_file <- file.path(data_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
de_file <- file.path(data_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

us_raw <- suppressWarnings(read_csv(us_file, show_col_types = FALSE))
de_raw <- suppressWarnings(read_csv(de_file, show_col_types = FALSE))

# First two rows of Qualtrics CSV are metadata/headers
drop_qualtrics_meta <- function(df) {
  # Determine rows to drop: Qualtrics typically includes 2 header rows
  # Drop rows where ResponseId doesn't start with "R_"
  if ("ResponseId" %in% names(df)) {
    df <- df[!is.na(df$ResponseId) & grepl("^R_", df$ResponseId), ]
  }
  df
}

us_raw <- drop_qualtrics_meta(us_raw)
de_raw <- drop_qualtrics_meta(de_raw)

# Build long dataset from conjoint attributes
# Conjoint has 9 tasks, 2 profiles each. Qualtrics stores attribute levels
# per task/profile. We need to detect these columns.

build_conjoint_long <- function(df, country) {
  # Identify conjoint columns. In Qualtrics conjoint using the "F-" syntax,
  # attribute columns are named like "F-X-Y" where X=task number, Y=attribute.
  # Also may be like "F.X.Y". Try several patterns.
  
  cn <- names(df)
  # Pattern: F-<task>-<attr>
  f_cols <- cn[grepl("^F-[0-9]+-[0-9]+$", cn)]
  
  if (length(f_cols) == 0) {
    # try F.
    f_cols <- cn[grepl("^F\\.[0-9]+\\.[0-9]+$", cn)]
  }
  
  # Choice columns - look for Q question patterns tied to tasks
  # Typically "choice" or specific Q numbers; look for columns with values 1 or 2
  
  # Preference/choice columns for conjoint: often named like "choice1".."choice9"
  # or specific question IDs. Let's find columns whose non-NA values are mostly 1 or 2.
  
  # Attempt to parse F-X-Y
  if (length(f_cols) > 0) {
    # Determine number of attributes and tasks
    parts <- do.call(rbind, strsplit(gsub("^F[-.]", "", f_cols), "[-.]"))
    tasks <- as.integer(parts[,1])
    attrs <- as.integer(parts[,2])
    n_tasks <- max(tasks)
    n_attrs <- max(attrs)
  } else {
    stop("Could not find conjoint attribute columns")
  }
  
  # Find choice columns. These are typically Q followed by a number, binary answer
  # The task choice vars will have 9 columns with values in {1,2}
  choice_candidates <- c()
  for (col in cn) {
    v <- df[[col]]
    v_num <- suppressWarnings(as.numeric(v))
    nn <- sum(!is.na(v_num))
    if (nn > nrow(df) * 0.5) {
      uv <- unique(v_num[!is.na(v_num)])
      if (length(uv) <= 3 && all(uv %in% c(1,2))) {
        choice_candidates <- c(choice_candidates, col)
      }
    }
  }
  
  # We need exactly n_tasks choice columns. Pick those with highest completion.
  # Filter to those with ~ all respondents answered
  compl <- sapply(choice_candidates, function(cc) sum(!is.na(suppressWarnings(as.numeric(df[[cc]])))))
  choice_candidates <- choice_candidates[order(-compl)]
  
  # Try to find columns in order - look for Q numbers that match a pattern
  # Alternative: columns that come right after each task's F- columns
  # Let's try: find top n_tasks by completion that aren't F- columns
  choice_cols <- head(choice_candidates, n_tasks)
  
  if (length(choice_cols) < n_tasks) {
    stop("Could not identify enough choice columns")
  }
  
  # Sort choice cols by column position in df to roughly match task order
  choice_cols <- choice_cols[order(match(choice_cols, cn))]
  choice_cols <- choice_cols[1:n_tasks]
  
  # Build long dataset
  rows <- list()
  resp_ids <- df$ResponseId
  
  for (t in 1:n_tasks) {
    chc <- suppressWarnings(as.numeric(df[[choice_cols[t]]]))
    for (p in 1:2) {
      # For each attribute, F-t-attr where profile indexing...
      # Actually, standard Hainmueller Qualtrics conjoint uses F-<task>-<attr> and
      # the attribute column itself contains values for both profiles? No - each
      # F-task-attr stores level for a single profile. But with 2 profiles per task
      # we'd expect F-task-attr with sub-index for profile.
      # 
      # Possibility: n_attrs here equals (actual_attrs * 2). With 7 attributes and 
      # 2 profiles, we'd have 14 F columns per task.
      
      # Determine actual number of attributes
      actual_n_attrs <- n_attrs / 2
      if (actual_n_attrs != round(actual_n_attrs)) {
        # Perhaps profiles are indicated differently
        actual_n_attrs <- n_attrs
      }
    }
  }
  
  actual_n_attrs <- n_attrs
  profiles_per_attr <- 1
  if (n_attrs %% 2 == 0 && n_attrs >= 14) {
    actual_n_attrs <- n_attrs / 2
    profiles_per_attr <- 2
  }
  
  for (t in 1:n_tasks) {
    chc <- suppressWarnings(as.numeric(df[[choice_cols[t]]]))
    for (p in 1:2) {
      prof_data <- data.frame(ResponseId = resp_ids, task = t, profile = p,
                              chosen = as.integer(chc == p),
                              stringsAsFactors = FALSE)
      for (a in 1:actual_n_attrs) {
        if (profiles_per_attr == 2) {
          attr_idx <- (p - 1) * actual_n_attrs + a
        } else {
          attr_idx <- a
        }
        col_name <- sprintf("F-%d-%d", t, attr_idx)
        if (!(col_name %in% cn)) col_name <- sprintf("F.%d.%d", t, attr_idx)
        if (col_name %in% cn) {
          prof_data[[paste0("attr", a)]] <- df[[col_name]]
        }
      }
      rows[[length(rows)+1]] <- prof_data
    }
  }
  
  long <- do.call(rbind, rows)
  long$country <- country
  long
}

us_long <- build_conjoint_long(us_raw, "US")
de_long <- build_conjoint_long(de_raw, "DE")

# Determine which attribute corresponds to "reason for migration"
# Likely one of the attributes contains levels like "drought", "flooding", 
# "wildfires", "persecution", "economic"
identify_reason_attr <- function(long) {
  attr_cols <- grep("^attr", names(long), value = TRUE)
  for (ac in attr_cols) {
    vals <- tolower(as.character(long[[ac]]))
    if (any(grepl("drought|flood|wildfire|persec|economic", vals, ignore.case = TRUE))) {
      return(ac)
    }
  }
  NA
}

us_reason_col <- identify_reason_attr(us_long)
de_reason_col <- identify_reason_attr(de_long)

# Standardize reason labels
standardize_reason <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("economic", x)] <- "economic"
  r[grepl("drought|dürre|duerre", x)] <- "drought"
  r[grepl("flood|überschwem|ueberschwem|hochwasser", x)] <- "flooding"
  r[grepl("wildfire|fire|waldbrand|brand", x)] <- "wildfires"
  r[grepl("persec|verfolg|politic|religi|ethnic", x)] <- "persecution"
  r
}

us_long$reason <- standardize_reason(us_long[[us_reason_col]])
de_long$reason <- standardize_reason(de_long[[de_reason_col]])

# For AMCE we need all 7 attributes as factors. Keep all attr cols as factors.
prep_for_amce <- function(long) {
  long <- long[!is.na(long$chosen) & !is.na(long$reason), ]
  long$reason <- factor(long$reason, levels = c("economic","drought","flooding","wildfires","persecution"))
  attr_cols <- grep("^attr", names(long), value = TRUE)
  for (ac in attr_cols) {
    long[[ac]] <- factor(long[[ac]])
  }
  long
}

us_long <- prep_for_amce(us_long)
de_long <- prep_for_amce(de_long)

# Build formula: chosen ~ reason + all other attr factors
build_formula <- function(long, reason_col) {
  attr_cols <- grep("^attr", names(long), value = TRUE)
  other_cols <- setdiff(attr_cols, reason_col)
  rhs <- paste(c("reason", other_cols), collapse = " + ")
  as.formula(paste("chosen ~", rhs))
}

us_fml <- build_formula(us_long, us_reason_col)
de_fml <- build_formula(de_long, de_reason_col)

us_mod <- feols(us_fml, data = us_long, cluster = ~ResponseId)
de_mod <- feols(de_fml, data = de_long, cluster = ~ResponseId)

get_coef <- function(mod, name) {
  co <- coef(mod)
  v <- co[name]
  if (is.na(v)) {
    # Try alternative naming
    matches <- grep(name, names(co), value = TRUE, fixed = TRUE)
    if (length(matches) > 0) v <- co[matches[1]]
  }
  as.numeric(v)
}

amce_drought_us     <- get_coef(us_mod, "reasondrought")
amce_flooding_us    <- get_coef(us_mod, "reasonflooding")
amce_wildfires_us   <- get_coef(us_mod, "reasonwildfires")
amce_persecution_us <- get_coef(us_mod, "reasonpersecution")

amce_drought_de     <- get_coef(de_mod, "reasondrought")
amce_flooding_de    <- get_coef(de_mod, "reasonflooding")
amce_wildfires_de   <- get_coef(de_mod, "reasonwildfires")
amce_persecution_de <- get_coef(de_mod, "reasonpersecution")

respondents_us <- length(unique(us_long$ResponseId))
respondents_de <- length(unique(de_long$ResponseId))
choice_tasks_us <- nrow(us_long)
choice_tasks_de <- nrow(de_long)

cat(sprintf("RESULT:amce_drought_us=%.4f\n", amce_drought_us))
cat(sprintf("RESULT:amce_flooding_us=%.4f\n", amce_flooding_us))
cat(sprintf("RESULT:amce_wildfires_us=%.4f\n", amce_wildfires_us))
cat(sprintf("RESULT:amce_persecution_us=%.4f\n", amce_persecution_us))
cat(sprintf("RESULT:amce_drought_germany=%.4f\n", amce_drought_de))
cat(sprintf("RESULT:amce_flooding_germany=%.4f\n", amce_flooding_de))
cat(sprintf("RESULT:amce_wildfires_germany=%.4f\n", amce_wildfires_de))
cat(sprintf("RESULT:amce_persecution_germany=%.4f\n", amce_persecution_de))
cat(sprintf("RESULT:respondents_us=%d\n", respondents_us))
cat(sprintf("RESULT:respondents_germany=%d\n", respondents_de))
cat(sprintf("RESULT:choice_tasks_us=%d\n", choice_tasks_us))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", choice_tasks_de))