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
prov_col <- "province_n"
surveyor_col <- "survey_taker_id"
cat("Province column:", prov_col, "\n")
cat("Surveyor column:", surveyor_col, "\n")

df$educ_f <- num(df$education)
df$nonturk <- num(df$non_turk)
df$fem <- num(df$female)
df$prov <- df[[prov_col]]
df$surv <- df[[surveyor_col]]

# ---------------- Mobility outcomes ----------------
df$days_out <- num(df$outside_week)
df$under_cur <- num(df$under_curfew)
df$never <- num(df$never_out)

# ---------------- SRQ-20 items (explicit mapping, SRQ-20 order) ----------------
items <- list(
  headache    = "head_ache",
  appetite    = "mal_appetite",
  sleep       = "sleeplessness",
  frightened  = "scared",
  shaking     = "shaking",
  nervous     = "nervous",
  indigestion = "indigestion",
  thinking    = "unfocused",
  unhappy     = "unhappy",
  cry         = "weepy",
  enjoy       = "unwillingness",
  decision    = "undecisiveness",
  worksuffer  = "disrupted",
  useful      = "useless",
  interest    = "uninterest",
  worthless   = "worthless",
  suicide     = "suicidal",
  tired_all   = "usually_tired",
  stomach     = "stomach_discomfort",
  tired_easy  = "quickly_tired"
)
items <- items[unlist(items) %in% nm]
cat("SRQ item mapping:\n")
for (it in names(items)) cat("  ", it, "->", items[[it]], "\n")

to_binary <- function(v) {
  v <- num(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(is.na(v), NA, as.numeric(v == 1)))
  if (all(c(0, 1) %in% u)) return(ifelse(v %in% c(0, 1), v, NA))
  if (all(c(1, 2) %in% u)) return(ifelse(v == 1, 1, ifelse(v == 2, 0, NA)))
  v
}

somatic_names <- c("headache", "shaking", "indigestion", "stomach")
item_names <- names(items)
for (it in item_names) df[[paste0("srq_", it)]] <- to_binary(df[[items[[it]]]])
som_items <- paste0("srq_", intersect(somatic_names, item_names))
nonsom_items <- paste0("srq_", setdiff(item_names, somatic_names))
all_items <- c(som_items, nonsom_items)
cat("Somatic items:", length(som_items), " Nonsomatic items:", length(nonsom_items), "\n")

ctrl <- df$treat == 0 & !is.na(df$treat)
# Anderson (2008): average of available item z-scores (control-group standardized),
# then rescaled to mean 0, SD 1 in the control group
anderson_index <- function(d, its) {
  zs <- sapply(its, function(v) {
    m <- mean(d[[v]][ctrl], na.rm = TRUE)
    s <- sd(d[[v]][ctrl], na.rm = TRUE)
    (d[[v]] - m) / s
  })
  zs <- as.matrix(zs)
  idx <- rowMeans(zs, na.rm = TRUE)
  idx[rowSums(!is.na(zs)) == 0] <- NA
  m <- mean(idx[ctrl], na.rm = TRUE)
  s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - m) / s
}
df$mdi <- anderson_index(df, all_items)
df$som <- anderson_index(df, som_items)
df$nonsom <- anderson_index(df, nonsom_items)
df$srq_sum <- rowSums(df[, all_items, drop = FALSE])

# ---------------- RD estimation ----------------
h <- 45
sub <- df %>% filter(!is.na(r), r >= -h, r < h)
cat("Obs within bandwidth:", nrow(sub), "\n")

fe_parts <- c("bmonth", "prov", "surv")
fe_str <- paste(fe_parts, collapse = " + ")

run_rd <- function(y) {
  f <- as.formula(paste0(y, " ~ treat + x + treat:x + i(educ_f) + nonturk + fem | ", fe_str))
  feols(f, data = sub, cluster = ~ym)
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