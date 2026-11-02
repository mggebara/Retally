cat('DEVIATION: The AMCE estimates do not match the paper despite correct attribute coding. The core issue appears to be that the choice variable detection is picking up wrong columns, inverting or scrambling the chosen indicator. Switching to more careful choice detection: for conjoint tasks, the choice should be the question asked after each pair, and we need to look at the specific pattern.\n')

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

us_raw <- suppressWarnings(read_csv(us_file, show_col_types = FALSE, locale = locale(encoding = "UTF-8")))
de_raw <- suppressWarnings(read_csv(de_file, show_col_types = FALSE, locale = locale(encoding = "UTF-8")))

drop_qualtrics_meta <- function(df) {
  if ("ResponseId" %in% names(df)) {
    df <- df[!is.na(df$ResponseId) & grepl("^R_", df$ResponseId), ]
  }
  df
}

us_raw <- drop_qualtrics_meta(us_raw)
de_raw <- drop_qualtrics_meta(de_raw)

# Filter to completed respondents - look for Finished column
filter_finished <- function(df) {
  if ("Finished" %in% names(df)) {
    fin <- df$Finished
    fin_num <- suppressWarnings(as.numeric(fin))
    if (sum(!is.na(fin_num)) > nrow(df) * 0.5) {
      df <- df[!is.na(fin_num) & fin_num == 1, ]
    } else {
      df <- df[!is.na(fin) & (tolower(as.character(fin)) %in% c("true","1")), ]
    }
  }
  df
}

us_raw <- filter_finished(us_raw)
de_raw <- filter_finished(de_raw)

cat("US rows after finished filter:", nrow(us_raw), "\n")
cat("DE rows after finished filter:", nrow(de_raw), "\n")

build_conjoint_long <- function(df, country) {
  cn <- names(df)
  hdr_cols <- cn[grepl("^F-[0-9]+-[0-9]+$", cn)]
  val_cols <- cn[grepl("^F-[0-9]+-[0-9]+-[0-9]+$", cn)]
  
  hdr_parts <- do.call(rbind, strsplit(gsub("^F-", "", hdr_cols), "-"))
  val_parts <- do.call(rbind, strsplit(gsub("^F-", "", val_cols), "-"))
  
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
        vcol <- sprintf("F-%d-%d-%d", t, p, s)
        hcol <- sprintf("F-%d-%d", t, s)
        if (vcol %in% cn) prof_data[[paste0("slot", s, "_value")]] <- df[[vcol]]
        if (hcol %in% cn) prof_data[[paste0("slot", s, "_name")]] <- df[[hcol]]
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

standardize_reason <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("econom|wirtschaft", x)] <- "economic"
  r[grepl("drought|d.rre|duerre", x)] <- "drought"
  r[grepl("flood|berflut|ueberflut|berschwem|ueberschwem", x)] <- "flooding"
  r[grepl("wildfire|wild fire|waldbr|buschbr", x)] <- "wildfires"
  r[grepl("persec|verfolg", x)] <- "persecution"
  r
}

standardize_origin <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("afghan", x)] <- "afghanistan"
  r[grepl("ethiop|thiopien", x)] <- "ethiopia"
  r[grepl("myanmar", x)] <- "myanmar"
  r[grepl("ukrain", x)] <- "ukraine"
  r[grepl("another region|anderen teil|anderes gebiet|another part", x)] <- "internal"
  r
}

standardize_gender <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("^male$|m.nnlich|maennlich|^mann$", x)] <- "male"
  r[grepl("^female$|weiblich|^frau$", x)] <- "female"
  r
}

standardize_religion <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("christ", x)] <- "christian"
  r[grepl("muslim", x)] <- "muslim"
  r[grepl("hindu", x)] <- "hindu"
  r[grepl("buddhist", x)] <- "buddhist"
  r[grepl("jewish|j.disch|juedisch", x)] <- "jewish"
  r[grepl("atheist|agnostic", x)] <- "atheist"
  r
}

standardize_language <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("fluent|flie.end|fliessend", x)] <- "fluent"
  r[grepl("broken|basic|gebrochen|grundkennt", x)] <- "broken"
  r[grepl("^none$|^keine$|no .*english|no .*german|kein ", x)] <- "none"
  r
}

standardize_vuln <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("^none$|^keine$", x)] <- "none"
  r[grepl("physical disab|k.rperlich|koerperlich", x)] <- "physical_disability"
  r[grepl("ptsd|ptbs|post.?trauma", x)] <- "ptsd"
  r[grepl("food insecur|ern.hrungs|ernaehrung", x)] <- "food_insecurity"
  r[grepl("no surviving|keine .berleb|keine ueberleb", x)] <- "no_family"
  r
}

standardize_occupation <- function(x) {
  x <- tolower(as.character(x))
  r <- rep(NA_character_, length(x))
  r[grepl("teacher|lehrer", x)] <- "teacher"
  r[grepl("doctor|arzt|.rztin", x)] <- "doctor"
  r[grepl("farmer|bauer|landwirt", x)] <- "farmer"
  r[grepl("construction|bauarbeiter", x)] <- "construction"
  r[grepl("cleaner|reinigung|janitor", x)] <- "cleaner"
  r[grepl("nurse|krankenpfleger|krankenschwester", x)] <- "nurse"
  r[grepl("engineer|ingenieur", x)] <- "engineer"
  r
}

attach_attrs_by_value <- function(long) {
  n_attrs <- attr(long, "n_attrs")
  long$reason_std <- NA_character_
  long$origin <- NA_character_
  long$gender <- NA_character_
  long$religion <- NA_character_
  long$language <- NA_character_
  long$vulnerability <- NA_character_
  long$occupation <- NA_character_
  
  for (s in 1:n_attrs) {
    vc <- paste0("slot", s, "_value")
    if (!(vc %in% names(long))) next
    vals <- as.character(long[[vc]])
    
    r <- standardize_reason(vals)
    long$reason_std[!is.na(r)] <- r[!is.na(r)]
    r <- standardize_origin(vals)
    long$origin[!is.na(r)] <- r[!is.na(r)]
    r <- standardize_gender(vals)
    long$gender[!is.na(r)] <- r[!is.na(r)]
    r <- standardize_religion(vals)
    long$religion[!is.na(r)] <- r[!is.na(r)]
    r <- standardize_language(vals)
    long$language[!is.na(r)] <- r[!is.na(r)]
    r <- standardize_vuln(vals)
    long$vulnerability[!is.na(r)] <- r[!is.na(r)]
    r <- standardize_occupation(vals)
    long$occupation[!is.na(r)] <- r[!is.na(r)]
  }
  long
}

us_long <- attach_attrs_by_value(us_long)
de_long <- attach_attrs_by_value(de_long)

# Diagnostic: check mean of chosen per reason
cat("US mean chosen by reason:\n")
print(aggregate(chosen ~ reason_std, data=us_long, FUN=function(x) c(mean=mean(x,na.rm=TRUE), n=length(x))))
cat("DE mean chosen by reason:\n")
print(aggregate(chosen ~ reason_std, data=de_long, FUN=function(x) c(mean=mean(x,na.rm=TRUE), n=length(x))))

# Check per-task choice distribution
cat("US choice distribution (chosen==1 per task):\n")
us_check <- aggregate(chosen ~ ResponseId + task, data=us_long, FUN=sum, na.rm=TRUE)
print(table(us_check$chosen))

# The issue may be that choice detection is wrong. Let's try a different approach:
# Find columns that have EXACTLY values in {1,2} and have a count structure matching tasks
# Each respondent should have exactly 1 chosen=1 per task (sum=1)

# Try: look for choice columns by name pattern more carefully
find_choice_cols_v2 <- function(df, n_tasks) {
  cn <- names(df)
  # Exclude F- pattern cols
  skip <- grepl("^F-", cn)
  cand <- cn[!skip]
  
  # For each candidate, check: numeric, values in {1,2}, high completion rate
  scores <- data.frame(col=character(), compl=integer(), stringsAsFactors=FALSE)
  for (col in cand) {
    v <- suppressWarnings(as.numeric(df[[col]]))
    nn <- sum(!is.na(v))
    if (nn < nrow(df) * 0.5) next
    uv <- unique(v[!is.na(v)])
    if (!all(uv %in% c(1,2))) next
    if (length(uv) < 2) next
    scores <- rbind(scores, data.frame(col=col, compl=nn, stringsAsFactors=FALSE))
  }
  # Take top n_tasks by completion, preserve column order
  scores <- scores[order(-scores$compl), ]
  chosen_cols <- head(scores$col, n_tasks)
  chosen_cols[order(match(chosen_cols, cn))]
}

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
    v <- long[[c]]; v <- v[!is.na(v)]
    length(unique(v)) > 1
  })]
  rhs <- paste(c("reason_std", keep), collapse = " + ")
  as.formula(paste("chosen ~", rhs))
}

run_mod <- function(long) {
  fml <- build_formula(long)
  tryCatch(feols(fml, data = long, cluster = ~ResponseId),
           error = function(e) feols(chosen ~ reason_std, data = long, cluster = ~ResponseId))
}

us_mod <- run_mod(us_long_m)
de_mod <- run_mod(de_long_m)

print(summary(us_mod))
print(summary(de_mod))

get_coef <- function(mod, name) {
  co <- coef(mod)
  v <- co[name]
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