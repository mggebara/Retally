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

drop_qualtrics_meta <- function(df) {
  if ("ResponseId" %in% names(df)) {
    df <- df[!is.na(df$ResponseId) & grepl("^R_", df$ResponseId), ]
  }
  df
}

us_raw <- drop_qualtrics_meta(us_raw)
de_raw <- drop_qualtrics_meta(de_raw)

build_conjoint_long <- function(df, country) {
  cn <- names(df)
  
  hdr_cols <- cn[grepl("^F-[0-9]+-[0-9]+$", cn)]
  if (length(hdr_cols) == 0) hdr_cols <- cn[grepl("^F\\.[0-9]+\\.[0-9]+$", cn)]
  
  val_cols <- cn[grepl("^F-[0-9]+-[0-9]+-[0-9]+$", cn)]
  if (length(val_cols) == 0) val_cols <- cn[grepl("^F\\.[0-9]+\\.[0-9]+\\.[0-9]+$", cn)]
  
  sep <- if (any(grepl("^F-", cn))) "-" else "."
  pat <- paste0("^F\\", sep)
  
  hdr_parts <- do.call(rbind, strsplit(gsub(pat, "", hdr_cols), paste0("[", sep, "]")))
  val_parts <- do.call(rbind, strsplit(gsub(pat, "", val_cols), paste0("[", sep, "]")))
  
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
    reason        = c("reason for migration", "migrationsgrund", "grund", "reason"),
    vulnerability = c("vulnerability", "verletzlich", "vulnerabilit"),
    language      = c("language fluency", "language", "sprachkenntnisse", "sprach"),
    gender        = c("gender", "geschlecht"),
    origin        = c("origin", "herkunft"),
    religion      = c("religion"),
    occupation    = c("occupation", "beruf")
  )
}

attach_all_attrs <- function(long) {
  pats <- canonical_attr_names()
  for (nm in names(pats)) {
    long[[nm]] <- extract_attr_by_name(long, pats[[nm]])
  }
  long
}

us_long <- attach_all_attrs(us_long)
de_long <- attach_all_attrs(de_long)

# Diagnostic: check what reason values look like
cat("US reason sample:\n")
print(head(unique(us_long$reason), 30))
cat("DE reason sample:\n")
print(head(unique(de_long$reason), 30))

standardize_reason <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("econom|wirtschaft|ökonom|oekonom|arbeit|job", x)] <- "economic"
  r[grepl("drought|dürre|duerre|trocken", x)] <- "drought"
  r[grepl("flood|überschwem|ueberschwem|hochwasser|überflut|ueberflut", x)] <- "flooding"
  r[grepl("wildfire|fire|waldbrand|brand|feuer", x)] <- "wildfires"
  r[grepl("persec|verfolg|politic|politisch|religi|ethnic|ethnisch", x)] <- "persecution"
  r
}

us_long$reason_std <- standardize_reason(us_long$reason)
de_long$reason_std <- standardize_reason(de_long$reason)

cat("US reason_std table:\n"); print(table(us_long$reason_std, useNA="always"))
cat("DE reason_std table:\n"); print(table(de_long$reason_std, useNA="always"))

prep_for_amce <- function(long) {
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
cat("DE rows after prep:", nrow(de_long_m), "\n")

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
  if (nrow(long) == 0) return(NULL)
  fml <- build_formula(long)
  tryCatch(feols(fml, data = long, cluster = ~ResponseId),
           error = function(e) {
             # fallback: just reason
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
respondents_de <- length(unique(de_long_m$ResponseId))
choice_tasks_us <- nrow(us_long_m)
choice_tasks_de <- nrow(de_long_m)

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