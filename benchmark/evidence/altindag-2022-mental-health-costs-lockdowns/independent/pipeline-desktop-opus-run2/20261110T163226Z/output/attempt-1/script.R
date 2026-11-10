suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns.script-free"
df <- haven::read_dta(file.path(base_dir, "ICPSR_183165-V1.1/konda_data_for_analysis.dta"))
df <- as.data.frame(haven::zap_labels(df))

nm <- names(df)
cat("Columns:", paste(nm, collapse = ", "), "\n")

num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- Running variable ----------------
yr <- num(df$year)
if (max(yr, na.rm = TRUE) < 100) yr <- yr + 1900
mo <- num(df$month)
df$byear <- yr
df$bmonth <- mo
# r = months relative to January 1956 (Jan 1956 = 0, Dec 1955 = -1)
df$r <- (yr - 1956) * 12 + (mo - 1)
df$treat <- as.integer(df$r < 0)
df$ym <- yr * 100 + mo
# running variable: months older than threshold (positive for treated)
df$x <- -df$r

if ("before1955" %in% nm) {
  cat("Agreement with before1955:", mean(df$treat == num(df$before1955), na.rm = TRUE), "\n")
}

# ---------------- Controls ----------------
find_col <- function(patterns, exclude = character(0)) {
  for (p in patterns) {
    hits <- nm[grepl(p, nm, ignore.case = TRUE)]
    hits <- setdiff(hits, exclude)
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

prov_col <- find_col(c("^province", "prov", "^il$", "^il_", "sehir", "city", "^region", "bolge"))
cat("Province column:", prov_col, "\n")
surveyor_col <- if ("survey_taker_id" %in% nm) "survey_taker_id" else find_col(c("survey", "interviewer", "anketor"))
cat("Surveyor column:", surveyor_col, "\n")

df$educ_f <- num(df$education)
if ("non_turk" %in% nm) {
  df$nonturk <- num(df$non_turk)
} else {
  df$nonturk <- num(df$ethnicity)
}
df$fem <- num(df$female)
if (!is.na(prov_col)) df$prov <- df[[prov_col]] else df$prov <- 1
df$surv <- if (!is.na(surveyor_col)) df[[surveyor_col]] else 1

# ---------------- Mobility outcomes ----------------
df$days_out <- num(df$outside_week)
df$under_cur <- num(df$under_curfew)
df$never <- num(df$never_out)

# ---------------- SRQ-20 items ----------------
item_patterns <- list(
  headache = c("headache", "head"),
  shaking = c("shak", "tremb"),
  indigestion = c("indigest", "digest"),
  stomach = c("stomach"),
  appetite = c("appetite"),
  sleep = c("sleep"),
  frightened = c("fright", "scare", "afraid"),
  nervous = c("nervous", "worri", "tense"),
  thinking = c("think", "clear"),
  unhappy = c("unhappy"),
  cry = c("cry", "crie"),
  enjoy = c("enjoy"),
  decision = c("decision", "decid"),
  worksuffer = c("work_suf", "worksuf", "suffer", "daily_work"),
  useful = c("useful", "useless", "play"),
  interest = c("uninterest", "interest"),
  worthless = c("worthless"),
  suicide = c("suicid"),
  tired_all = c("tired_all", "alltime", "all_time", "always_tired", "tired_always"),
  tired_easy = c("tired_eas", "easily_tired", "tire_eas", "easily")
)
used <- character(0)
items <- list()
for (it in names(item_patterns)) {
  col <- find_col(item_patterns[[it]], exclude = used)
  items[[it]] <- col
  if (!is.na(col)) used <- c(used, col)
}
# fallback for tired items
tired_cols <- setdiff(nm[grepl("tire", nm, ignore.case = TRUE)], used)
if (is.na(items$tired_all) && length(tired_cols) > 0) {
  items$tired_all <- tired_cols[1]; used <- c(used, tired_cols[1]); tired_cols <- tired_cols[-1]
}
if (is.na(items$tired_easy) && length(tired_cols) > 0) {
  items$tired_easy <- tired_cols[1]; used <- c(used, tired_cols[1])
}
cat("SRQ item mapping:\n")
for (it in names(items)) cat("  ", it, "->", items[[it]], "\n")

to_binary <- function(v) {
  v <- num(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(is.na(v), NA, as.numeric(v == 1)))
  # treat 0/1 valid, others missing codes
  if (all(c(0, 1) %in% u)) return(ifelse(v %in% c(0, 1), v, NA))
  if (all(c(1, 2) %in% u)) return(ifelse(v == 1, 1, ifelse(v == 2, 0, NA)))
  v
}

somatic_names <- c("headache", "shaking", "indigestion", "stomach")
item_names <- names(items)[!sapply(items, is.na)]
for (it in item_names) df[[paste0("srq_", it)]] <- to_binary(df[[items[[it]]]])
som_items <- paste0("srq_", intersect(somatic_names, item_names))
nonsom_items <- paste0("srq_", setdiff(item_names, somatic_names))
all_items <- c(som_items, nonsom_items)
cat("Somatic items:", length(som_items), " Nonsomatic items:", length(nonsom_items), "\n")

ctrl <- df$treat == 0 & !is.na(df$treat)
anderson_index <- function(d, its) {
  zs <- sapply(its, function(v) {
    m <- mean(d[[v]][ctrl], na.rm = TRUE)
    s <- sd(d[[v]][ctrl], na.rm = TRUE)
    (d[[v]] - m) / s
  })
  idx <- rowMeans(zs)  # requires all items answered
  m <- mean(idx[ctrl], na.rm = TRUE)
  s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - m) / s
}
complete_all <- complete.cases(df[, all_items, drop = FALSE])
df$mdi <- anderson_index(df, all_items)
df$som <- anderson_index(df, som_items)
df$nonsom <- anderson_index(df, nonsom_items)
df$srq_sum <- rowSums(df[, all_items, drop = FALSE])
# keep same sample (all 20 answered) for all mental health outcomes
df$mdi[!complete_all] <- NA
df$som[!complete_all] <- NA
df$nonsom[!complete_all] <- NA
df$srq_sum[!complete_all] <- NA

# ---------------- RD estimation ----------------
h <- 45
sub <- df %>% filter(!is.na(r), r >= -h, r < h)
cat("Obs within bandwidth:", nrow(sub), "\n")

fe_parts <- c("bmonth", "prov", "surv")
fe_str <- paste(fe_parts, collapse = " + ")

run_rd <- function(y) {
  f <- as.formula(paste0(y, " ~ treat + x + treat:x + i(educ_f) + nonturk + fem | ", fe_str))
  m <- feols(f, data = sub, cluster = ~ym)
  m
}

m_days <- run_rd("days_out")
m_cur <- run_rd("under_cur")
m_never <- run_rd("never")
m_mdi <- run_rd("mdi")
m_som <- run_rd("som")
m_nonsom <- run_rd("nonsom")
m_sum <- run_rd("srq_sum")

for (m in list(m_days, m_cur, m_never, m_mdi, m_som, m_nonsom, m_sum)) {
  cat(sprintf("coef=%.4f se=%.4f n=%d\n", coef(m)["treat"], se(m)["treat"], nobs(m)))
}

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", coef(m_days)["treat"]))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", coef(m_cur)["treat"]))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", coef(m_never)["treat"]))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", nobs(m_days)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", nobs(m_cur)))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", coef(m_mdi)["treat"]))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", coef(m_som)["treat"]))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", coef(m_nonsom)["treat"]))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", coef(m_sum)["treat"]))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", nobs(m_mdi)))