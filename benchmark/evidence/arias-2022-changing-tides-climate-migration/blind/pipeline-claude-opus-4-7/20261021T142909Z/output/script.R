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

read_qualtrics <- function(path) {
  hdr <- read_csv(path, n_max = 0, show_col_types = FALSE)
  df <- read_csv(path, skip = 3, col_names = names(hdr), show_col_types = FALSE,
                 guess_max = 20000)
  df
}

us <- read_qualtrics(us_file)
de <- read_qualtrics(de_file)

norm_fin <- function(x) {
  if (is.logical(x)) return(x)
  if (is.numeric(x)) return(x == 1)
  xl <- tolower(as.character(x))
  xl %in% c("true", "1", "yes")
}

us <- us %>% filter(norm_fin(Finished))
de <- de %>% filter(norm_fin(Finished))

# F columns are of form "F-{task}-{profile}-{attr}" (based on sample "F-9-2-7")
f_cols_us <- grep("^F-\\d+-\\d+-\\d+$", names(us), value = TRUE)
f_cols_de <- grep("^F-\\d+-\\d+-\\d+$", names(de), value = TRUE)

split_fcols <- function(cols) {
  parts <- str_match(cols, "^F-(\\d+)-(\\d+)-(\\d+)$")
  data.frame(col = cols,
             task = as.integer(parts[,2]),
             profile = as.integer(parts[,3]),
             attr = as.integer(parts[,4]),
             stringsAsFactors = FALSE)
}

us_meta <- split_fcols(f_cols_us)
de_meta <- split_fcols(f_cols_de)

cat("US F cols:", length(f_cols_us), "tasks:", paste(sort(unique(us_meta$task)), collapse=","),
    "profiles:", paste(sort(unique(us_meta$profile)), collapse=","),
    "attrs:", paste(sort(unique(us_meta$attr)), collapse=","), "\n", file=stderr())

n_us <- nrow(us)
n_de <- nrow(de)

# Choice columns: Q184, Q186, ... Q198 (8 cols found). Also need 9th. 
# Based on column ordering: force_choice is the first task's choice, then Q184..Q198
# That makes 1 + 8 = 9 choice variables
us_choice_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")
de_choice_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")

cat("US choice cols:", us_choice_cols, "\n", file=stderr())

build_dataset <- function(df, meta, choice_cols) {
  resp <- "ResponseId"
  n_tasks <- length(choice_cols)
  recs <- list()
  attrs <- sort(unique(meta$attr))
  for (ti in seq_len(n_tasks)) {
    cc <- choice_cols[ti]
    choice_val <- suppressWarnings(as.numeric(df[[cc]]))
    for (pi in 1:2) {
      row <- data.frame(ResponseId = df[[resp]], task = ti, profile = pi,
                        chosen = as.integer(choice_val == pi),
                        stringsAsFactors = FALSE)
      for (a in attrs) {
        colnm <- meta$col[meta$task == ti & meta$profile == pi & meta$attr == a]
        if (length(colnm) == 1 && !is.na(colnm)) {
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
de_data <- build_dataset(de, de_meta, de_meta$attr |> (\(x) x)() |> {\(.) de_choice_cols}())
de_data <- build_dataset(de, de_meta, de_choice_cols)

cat("US data nrow:", nrow(us_data), "DE data nrow:", nrow(de_data), "\n", file=stderr())

# Identify reason attribute
attr_levels <- function(data, meta) {
  for (a in sort(unique(meta$attr))) {
    col <- paste0("attr", a)
    if (col %in% names(data)) {
      uv <- unique(data[[col]])
      uv <- uv[!is.na(uv)]
      cat("attr", a, "levels:", paste(head(uv, 10), collapse=" | "), "\n", file=stderr())
    }
  }
}
cat("\nUS levels:\n", file=stderr()); attr_levels(us_data, us_meta)
cat("\nDE levels:\n", file=stderr()); attr_levels(de_data, de_meta)

find_reason_attr <- function(data, meta, lang = "en") {
  for (a in sort(unique(meta$attr))) {
    col <- paste0("attr", a)
    if (col %in% names(data)) {
      uv <- unique(data[[col]])
      uv <- uv[!is.na(uv)]
      txt <- tolower(paste(uv, collapse = " "))
      if (lang == "en") {
        if (grepl("drought", txt) && grepl("flood", txt)) return(a)
      } else {
        if ((grepl("dürre", txt) || grepl("durre", txt)) && 
            (grepl("überschwemm", txt) || grepl("flut", txt))) return(a)
        if (grepl("drought", txt) && grepl("flood", txt)) return(a)
      }
    }
  }
  NA_integer_
}

reason_attr_us <- find_reason_attr(us_data, us_meta, "en")
reason_attr_de <- find_reason_attr(de_data, de_meta, "de")
cat("US reason attr =", reason_attr_us, "DE reason attr =", reason_attr_de, "\n", file=stderr())

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
  out[grepl("wirtschaft|economic|möglich|moglich", xl)] <- "economic"
  out[grepl("dürre|durre|drought", xl)] <- "drought"
  out[grepl("überschwemm|uberschwemm|flut|flood", xl)] <- "flooding"
  out[grepl("waldbr|wildfire|brand", xl)] <- "wildfires"
  out[grepl("verfolg|persecut|politische|religiöse|ethnische|religiose|ethnische", xl)] <- "persecution"
  out
}

run_amce <- function(data, reason_attr, norm_fn, meta) {
  rcol <- paste0("attr", reason_attr)
  data$reason <- norm_fn(data[[rcol]])
  data <- data[!is.na(data$reason) & !is.na(data$chosen), ]
  data$reason <- factor(data$reason, levels = c("economic","drought","flooding","wildfires","persecution"))
  
  other_attrs <- setdiff(sort(unique(meta$attr)), reason_attr)
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

m_us <- run_amce(us_data, reason_attr_us, norm_reason_us, us_meta)
m_de <- run_amce(de_data, reason_attr_de, norm_reason_de, de_meta)

cat("\n--- US model ---\n", file=stderr())
print(summary(m_us))
cat("\n--- DE model ---\n", file=stderr())
print(summary(m_de))

coef_us <- coef(m_us)
coef_de <- coef(m_de)

get_coef <- function(cf, pat) {
  v <- cf[grep(pat, names(cf))]
  if (length(v) == 0) return(NA_real_)
  as.numeric(v[1])
}

amce_drought_us    <- get_coef(coef_us, "drought")
amce_flooding_us   <- get_coef(coef_us, "flooding")
amce_wildfires_us  <- get_coef(coef_us, "wildfires")
amce_persecution_us<- get_coef(coef_us, "persecution")

amce_drought_de    <- get_coef(coef_de, "drought")
amce_flooding_de   <- get_coef(coef_de, "flooding")
amce_wildfires_de  <- get_coef(coef_de, "wildfires")
amce_persecution_de<- get_coef(coef_de, "persecution")

choice_tasks_us <- nrow(us_data)
choice_tasks_de <- nrow(de_data)

cat(sprintf("RESULT:amce_drought_us=%.6f\n", amce_drought_us))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n", amce_flooding_us))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n", amce_wildfires_us))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", amce_persecution_us))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n", amce_drought_de))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n", amce_flooding_de))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n", amce_wildfires_de))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", amce_persecution_de))
cat(sprintf("RESULT:respondents_us=%d\n", n_us))
cat(sprintf("RESULT:respondents_germany=%d\n", n_de))
cat(sprintf("RESULT:choice_tasks_us=%d\n", choice_tasks_us))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", choice_tasks_de))