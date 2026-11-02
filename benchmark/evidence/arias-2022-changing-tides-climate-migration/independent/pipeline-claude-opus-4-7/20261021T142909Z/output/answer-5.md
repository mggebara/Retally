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

# Diagnostic: look at German columns to understand structure
cat("DE column sample (first 50):\n")
print(head(names(de_raw), 50))
cat("DE total cols:", ncol(de_raw), "\n")

# Check for F- prefixed columns in German
de_f_cols <- grep("^F", names(de_raw), value = TRUE)
cat("DE F cols (first 30):\n")
print(head(de_f_cols, 30))

drop_qualtrics_meta <- function(df) {
  if ("ResponseId" %in% names(df)) {
    df <- df[!is.na(df$ResponseId) & grepl("^R_", df$ResponseId), ]
  }
  # Filter out preview/test responses using Status column if available
  if ("Status" %in% names(df)) {
    # Status 0 = IP Address, 1 = Survey Preview, 2 = Survey Test, etc.
    stat <- suppressWarnings(as.numeric(df$Status))
    df <- df[is.na(stat) | stat == 0, ]
  }
  # Filter to finished responses if available
  if ("Finished" %in% names(df)) {
    fin <- df$Finished
    fin_num <- suppressWarnings(as.numeric(fin))
    if (sum(!is.na(fin_num)) > nrow(df) * 0.5) {
      df <- df[is.na(fin_num) | fin_num == 1, ]
    } else {
      df <- df[is.na(fin) | tolower(as.character(fin)) %in% c("true","1","yes"), ]
    }
  }
  df
}

us_raw <- drop_qualtrics_meta(us_raw)
de_raw <- drop_qualtrics_meta(de_raw)

cat("US rows after Qualtrics filter:", nrow(us_raw), "\n")
cat("DE rows after Qualtrics filter:", nrow(de_raw), "\n")

build_conjoint_long <- function(df, country) {
  cn <- names(df)
  
  # Try multiple separator patterns
  hdr_cols <- cn[grepl("^F-[0-9]+-[0-9]+$", cn)]
  val_cols <- cn[grepl("^F-[0-9]+-[0-9]+-[0-9]+$", cn)]
  sep <- "-"
  
  if (length(hdr_cols) == 0) {
    hdr_cols <- cn[grepl("^F\\.[0-9]+\\.[0-9]+$", cn)]
    val_cols <- cn[grepl("^F\\.[0-9]+\\.[0-9]+\\.[0-9]+$", cn)]
    sep <- "."
  }
  
  if (length(hdr_cols) == 0) {
    hdr_cols <- cn[grepl("^F_[0-9]+_[0-9]+$", cn)]
    val_cols <- cn[grepl("^F_[0-9]+_[0-9]+_[0-9]+$", cn)]
    sep <- "_"
  }
  
  cat(sprintf("Country %s: sep='%s', n_hdr=%d, n_val=%d\n", country, sep, length(hdr_cols), length(val_cols)))
  
  if (length(hdr_cols) == 0 || length(val_cols) == 0) {
    # Diagnostic: show sample column names
    cat("Sample column names:\n")
    print(head(cn, 100))
    return(NULL)
  }
  
  pat <- paste0("^F\\", sep)
  split_pat <- paste0("[", sep, "]")
  if (sep == "-") split_pat <- "-"
  if (sep == "_") split_pat <- "_"
  if (sep == ".") split_pat <- "\\."
  
  hdr_parts <- do.call(rbind, strsplit(gsub(pat, "", hdr_cols), split_pat))
  val_parts <- do.call(rbind, strsplit(gsub(pat, "", val_cols), split_pat))
  
  hdr_tasks <- as.integer(hdr_parts[,1])
  hdr_slots <- as.integer(hdr_parts[,2])
  
  val_tasks  <- as.integer(val_parts[,1])
  val_profs  <- as.integer(val_parts[,2])
  val_slots  <- as.integer(val_parts[,3])
  
  n_tasks <- max(c(hdr_tasks, val_tasks))
  n_attrs <- max(c(hdr_slots, val_slots))
  n_profs <- max(val_profs)
  
  choice_candidates <- c()
  for (col in cn) {
    if (col %in% hdr_cols || col %in% val_cols) next
    v <- df[[col]]
    v_num <- suppressWarnings(as.numeric(v))
    nn <- sum(!is.na(v_num))
    if (nn > nrow(df) * 0.3) {
      uv <- unique(v_num[!is.na(v_num)])
      if (length(uv) <= 3 && length(uv) >= 1 && all(uv %in% c(1,2))) {
        choice_candidates <- c(choice_candidates, col)
      }
    }
  }
  compl <- sapply(choice_candidates, function(cc) sum(!is.na(suppressWarnings(as.numeric(df[[cc]])))))
  choice_candidates <- choice_candidates[order(-compl)]
  choice_cols <- head(choice_candidates, n_tasks)
  choice_cols <- choice_cols[order(match(choice_cols, cn))]
  
  rows <- list()
  resp_ids <- df$ResponseId
  
  for (t in 1:n_tasks) {
    chc <- suppressWarnings(as.numeric(df[[choice_cols[t]]]))
    for (p in 1:n_profs) {
      prof_data <- data.frame(ResponseId = resp_ids, task = t, profile = p,
                              chosen = as.integer(chc == p),
                              stringsAsFactors = FALSE)
      for (s in 1:n_attrs) {
        vcol <- sprintf("F%s%d%s%d%s%d", sep, t, sep, p, sep, s)
        hcol <- sprintf("F%s%d%s%d", sep, t, sep, s)
        if (vcol %in% cn) {
          prof_data[[paste0("slot", s, "_value")]] <- df[[vcol]]
        }
        if (hcol %in% cn) {
          prof_data[[paste0("slot", s, "_name")]] <- df[[hcol]]
        }
      }
      rows[[length(rows)+1]] <- prof_data
    }
  }
  
  long <- do.call(rbind, rows)
  long$country <- country
  attr(long, "n_attrs") <- n_attrs
  long
}

us_long <- build_conjoint_long(us_raw, "US")
de_long <- build_conjoint_long(de_raw, "DE")

# If DE still empty, try alternate column patterns
if (is.null(de_long) || nrow(de_long) == 0) {
  cat("DE empty, searching for alternative conjoint columns...\n")
  # Look for columns matching conjoint pattern more broadly
  cn <- names(de_raw)
  # German survey may use different prefix
  candidates <- grep("^[A-Z]+[-_.][0-9]+[-_.][0-9]+", cn, value = TRUE)
  cat("DE candidate prefixes:\n")
  prefixes <- unique(gsub("^([A-Z]+).*", "\\1", candidates))
  print(prefixes)
  cat("Sample candidates:\n")
  print(head(candidates, 20))
}

extract_attr_by_name <- function(long, name_patterns) {
  n_attrs <- attr(long, "n_attrs")
  out <- rep(NA_character_, nrow(long))
  for (s in 1:n_attrs) {
    name_col <- paste0("slot", s, "_name")
    val_col  <- paste0("slot", s, "_value")
    if (!(name_col %in% names(long)) || !(val_col %in% names(long))) next
    nm <- tolower(as.character(long[[name_col]]))
    match_rows <- rep(FALSE, length(nm))
    for (pat in name_patterns) {
      match_rows <- match_rows | grepl(pat, nm, ignore.case = TRUE)
    }
    match_rows[is.na(match_rows)] <- FALSE
    out[match_rows] <- as.character(long[[val_col]])[match_rows]
  }
  out
}

canonical_attr_names <- function() {
  list(
    reason        = c("reason for migration", "migrationsgrund", "grund", "reason", "migration"),
    vulnerability = c("vulnerability", "verletzlich", "vulnerabilit", "schutz"),
    language      = c("language fluency", "language", "sprachkenntnisse", "sprach"),
    gender        = c("gender", "geschlecht"),
    origin        = c("origin", "herkunft"),
    religion      = c("religion"),
    occupation    = c("occupation", "beruf")
  )
}

attach_all_attrs <- function(long) {
  if (is.null(long) || nrow(long) == 0) return(long)
  pats <- canonical_attr_names()
  for (nm in names(pats)) {
    long[[nm]] <- extract_attr_by_name(long, pats[[nm]])
  }
  long
}

us_long <- attach_all_attrs(us_long)
de_long <- attach_all_attrs(de_long)

cat("US reason sample:\n")
print(head(unique(us_long$reason), 30))
cat("DE reason sample:\n")
if (!is.null(de_long)) print(head(unique(de_long$reason), 30))

# Diagnostic: dump unique slot names for DE
if (!is.null(de_long) && nrow(de_long) > 0) {
  cat("DE slot names across all slots:\n")
  n_attrs <- attr(de_long, "n_attrs")
  for (s in 1:n_attrs) {
    nc <- paste0("slot", s, "_name")
    if (nc %in% names(de_long)) {
      u <- unique(de_long[[nc]])
      cat(sprintf("  slot%d: %s\n", s, paste(head(u,5), collapse="|")))
    }
  }
  cat("DE slot values sample:\n")
  for (s in 1:n_attrs) {
    vc <- paste0("slot", s, "_value")
    if (vc %in% names(de_long)) {
      u <- unique(de_long[[vc]])
      cat(sprintf("  slot%d: %s\n", s, paste(head(u,8), collapse="|")))
    }
  }
}

standardize_reason <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("econom|wirtschaft|ökonom|oekonom|arbeit|job|arbeits", x)] <- "economic"
  r[grepl("drought|dürre|duerre|trocken", x)] <- "drought"
  r[grepl("flood|überschwem|ueberschwem|hochwasser|überflut|ueberflut", x)] <- "flooding"
  r[grepl("wildfire|wild fire|waldbrand|buschbrand|brand|feuer", x)] <- "wildfires"
  r[grepl("persec|verfolg|politisch|religi|ethnisch|ethnic|political", x)] <- "persecution"
  r
}

us_long$reason_std <- standardize_reason(us_long$reason)
if (!is.null(de_long)) de_long$reason_std <- standardize_reason(de_long$reason)

# If DE reason is still all NA, try scanning values directly across all slot_value columns
if (!is.null(de_long) && all(is.na(de_long$reason_std))) {
  cat("DE reason via name match failed, trying value-based detection...\n")
  n_attrs <- attr(de_long, "n_attrs")
  de_reason_val <- rep(NA_character_, nrow(de_long))
  for (s in 1:n_attrs) {
    vc <- paste0("slot", s, "_value")
    if (!(vc %in% names(de_long))) next
    vals <- as.character(de_long[[vc]])
    std <- standardize_reason(vals)
    # Only overwrite if this slot has reason-like values
    valid_count <- sum(!is.na(std))
    if (valid_count > nrow(de_long) * 0.1) {
      cat(sprintf("  slot%d has %d reason-like values\n", s, valid_count))
      de_reason_val[!is.na(std)] <- std[!is.na(std)]
    }
  }
  de_long$reason_std <- de_reason_val
}

cat("US reason_std table:\n"); print(table(us_long$reason_std, useNA="always"))
if (!is.null(de_long)) { cat("DE reason_std table:\n"); print(table(de_long$reason_std, useNA="always")) }

# Also detect other attrs by value if name-matching failed in DE
detect_attr_by_values <- function(long, attr_name, value_patterns) {
  n_attrs <- attr(long, "n_attrs")
  out <- rep(NA_character_, nrow(long))
  for (s in 1:n_attrs) {
    vc <- paste0("slot", s, "_value")
    if (!(vc %in% names(long))) next
    vals <- tolower(as.character(long[[vc]]))
    hits <- rep(FALSE, length(vals))
    for (pat in value_patterns) {
      hits <- hits | grepl(pat, vals, ignore.case = TRUE)
    }
    hits[is.na(hits)] <- FALSE
    if (sum(hits) > nrow(long) * 0.05) {
      # This slot carries this attribute - take all values from it
      out[hits] <- as.character(long[[vc]])[hits]
    }
  }
  out
}

if (!is.null(de_long)) {
  # Fill in other attrs by value if NA
  if (all(is.na(de_long$origin))) {
    de_long$origin <- detect_attr_by_values(de_long, "origin",
      c("afghanistan","ethiopia|äthiopien|aethiopien","myanmar","ukraine","another region|anderen region|anderes gebiet"))
  }
  if (all(is.na(de_long$gender))) {
    de_long$gender <- detect_attr_by_values(de_long, "gender",
      c("^male$|^female$|männlich|maennlich|weiblich|^mann$|^frau$"))
  }
  if (all(is.na(de_long$religion))) {
    de_long$religion <- detect_attr_by_values(de_long, "religion",
      c("christian|christ|muslim|hindu|buddhist|jewish|jüdisch|juedisch|atheist|agnostic"))
  }
  if (all(is.na(de_long$language))) {
    de_long$language <- detect_attr_by_values(de_long, "language",
      c("fluent|basic|none|fließend|fliessend|grundkennt|keine"))
  }
  if (all(is.na(de_long$vulnerability))) {
    de_long$vulnerability <- detect_attr_by_values(de_long, "vulnerability",
      c("physical|psycho|none|keine|körperlich|koerperlich|psychisch"))
  }
  if (all(is.na(de_long$occupation))) {
    de_long$occupation <- detect_attr_by_values(de_long, "occupation",
      c("teacher|doctor|farmer|engineer|nurse|construction|lehrer|arzt|bauer|landwirt|ingenieur|krankenpfleger|bau"))
  }
}

prep_for_amce <- function(long) {
  if (is.null(long) || nrow(long) == 0) return(long)
  long <- long[!is.na(long$chosen) & !is.na(long$reason_std), ]
  long$reason_std <- factor(long$reason_std, levels = c("economic","drought","flooding","wildfires","persecution"))
  for (ac in c("vulnerability","language","gender","origin","religion","occupation")) {
    if (ac %in% names(long)) long[[ac]] <- factor(long[[ac]])
  }
  long
}

us_long_m <- prep_for_amce(us_long)
de_long_m <- prep_for_amce(de_long)

cat("US rows after prep:", nrow(us_long_m), "\n")
cat("DE rows after prep:", if(is.null(de_long_m)) 0 else nrow(de_long_m), "\n")

build_formula <- function(long) {
  other_cols <- intersect(c("vulnerability","language","gender","origin","religion","occupation"), names(long))
  keep <- other_cols[sapply(other_cols, function(c) {
    v <- long[[c]]
    v <- v[!is.na(v)]
    length(unique(v)) > 1
  })]
  rhs <- paste(c("reason_std", keep), collapse = " + ")
  as.formula(paste("chosen ~", rhs))
}

run_mod <- function(long) {
  if (is.null(long) || nrow(long) == 0) return(NULL)
  fml <- build_formula(long)
  tryCatch(feols(fml, data = long, cluster = ~ResponseId),
           error = function(e) {
             tryCatch(feols(chosen ~ reason_std, data = long, cluster = ~ResponseId),
                      error = function(e2) NULL)
           })
}

us_mod <- run_mod(us_long_m)
de_mod <- run_mod(de_long_m)

get_coef <- function(mod, name) {
  if (is.null(mod)) return(NA_real_)
  co <- coef(mod)
  v <- co[name]
  if (is.na(v)) {
    matches <- grep(name, names(co), value = TRUE, fixed = TRUE)
    if (length(matches) > 0) v <- co[matches[1]]
  }
  as.numeric(v)
}

amce_drought_us     <- get_coef(us_mod, "reason_stddrought")
amce_flooding_us    <- get_coef(us_mod, "reason_stdflooding")
amce_wildfires_us   <- get_coef(us_mod, "reason_stdwildfires")
amce_persecution_us <- get_coef(us_mod, "reason_stdpersecution")

amce_drought_de     <- get_coef(de_mod, "reason_stddrought")
amce_flooding_de    <- get_coef(de_mod, "reason_stdflooding")
amce_wildfires_de   <- get_coef(de_mod, "reason_stdwildfires")
amce_persecution_de <- get_coef(de_mod, "reason_stdpersecution")

respondents_us <- length(unique(us_long_m$ResponseId))
respondents_de <- if (is.null(de_long_m)) 0 else length(unique(de_long_m$ResponseId))
choice_tasks_us <- nrow(us_long_m)
choice_tasks_de <- if (is.null(de_long_m)) 0 else nrow(de_long_m)

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