suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns.script-free/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
raw <- haven::read_dta(path)
df <- as.data.frame(lapply(raw, function(v) {
  if (inherits(v, "haven_labelled")) v <- haven::zap_labels(v)
  v
}), stringsAsFactors = FALSE)
nm <- names(df)
cat("Columns:", paste(nm, collapse = ", "), "\n")

num <- function(v) suppressWarnings(as.numeric(v))

# ---------------- running variable ----------------
by <- num(df$year)
bm <- num(df$month)
if (all(by[!is.na(by)] < 100)) by <- by + 1900
cat("Birth year range:", range(by, na.rm = TRUE), " month range:", range(bm, na.rm = TRUE), "\n")
# months older than the December 1955 index month (Dec 1955 = 0, treated if x >= 0)
df$x <- (1955 * 12 + 12) - (by * 12 + bm)
df$birth_ym <- by * 100 + bm

if ("before1955" %in% nm) {
  df$treat <- num(df$before1955)
  cat("Consistency of before1955 with x>=0:\n")
  print(table(before1955 = df$treat, x_ge0 = df$x >= 0, useNA = "ifany"))
} else {
  df$treat <- as.numeric(df$x >= 0)
}

# ---------------- fixed effects / controls ----------------
find_first <- function(pats, exclude = character(0)) {
  for (p in pats) {
    hits <- setdiff(grep(p, nm, ignore.case = TRUE, value = TRUE), exclude)
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}
prov_col <- find_first(c("^province$", "^province", "province", "^il$", "^il_", "^city", "region", "prov"))
surv_col <- find_first(c("^survey_taker_id$", "surveyor", "survey_taker", "interviewer", "anketor"))
cat("Province column:", prov_col, " Surveyor column:", surv_col, "\n")

df$fe_month <- factor(bm)
df$fe_prov <- if (!is.na(prov_col)) factor(df[[prov_col]]) else factor(1)
df$fe_surv <- if (!is.na(surv_col)) factor(df[[surv_col]]) else factor(1)
df$c_educ <- factor(df$education)
df$c_eth <- if ("ethnicity" %in% nm) factor(df$ethnicity) else factor(df$non_turk)
df$c_fem <- num(df$female)

# ---------------- SRQ-20 items ----------------
binary_cols <- nm[sapply(df, function(v) {
  u <- unique(num(v)); u <- u[!is.na(u)]
  length(u) >= 1 && length(u) <= 3
})]
used <- character(0)
find_item <- function(pats) {
  for (p in pats) {
    hits <- setdiff(grep(p, binary_cols, ignore.case = TRUE, value = TRUE), used)
    if (length(hits) > 0) { used <<- c(used, hits[1]); return(hits[1]) }
  }
  NA_character_
}
somatic_items <- c(
  headache = find_item(c("headache", "head")),
  shaking = find_item(c("^shaking$", "shak", "trembl")),
  indigestion = find_item(c("^indigestion$", "indigest", "digest")),
  stomach = find_item(c("stomach", "uncomf"))
)
nonsom_items <- c(
  appetite = find_item(c("^mal_appetite$", "appetite")),
  sleep = find_item(c("sleep", "insomn")),
  fright = find_item(c("fright", "scare", "afraid")),
  nervous = find_item(c("^nervous$", "nervous", "tense")),
  thinking = find_item(c("think", "concentr")),
  unhappy = find_item(c("^unhappy$", "unhappy")),
  cry = find_item(c("cry")),
  enjoy = find_item(c("enjoy")),
  decision = find_item(c("decis")),
  worksuffer = find_item(c("suffer", "daily_work", "dailywork")),
  useful = find_item(c("useful")),
  interest = find_item(c("interest")),
  worthless = find_item(c("^worthless$", "worthless")),
  suicide = find_item(c("suicid", "end_life", "endlife")),
  tired_easily = find_item(c("tired_eas", "easily_tired", "easy_tired", "tire.*eas", "eas.*tire")),
  tired = find_item(c("^tired", "tired", "tire", "fatigue"))
)
cat("Somatic items:\n"); print(somatic_items)
cat("Nonsomatic items:\n"); print(nonsom_items)
somatic_items <- somatic_items[!is.na(somatic_items)]
nonsom_items <- nonsom_items[!is.na(nonsom_items)]
all_items <- c(somatic_items, nonsom_items)

to_yes <- function(v) {
  v <- num(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(is.na(v), NA, as.numeric(v == 1)))
  v
}
for (it in all_items) df[[paste0("y_", it)]] <- to_yes(df[[it]])
item_vars <- paste0("y_", all_items)
complete_srq <- complete.cases(df[, item_vars, drop = FALSE])
ctrl <- df$treat == 0 & !is.na(df$treat)

anderson <- function(items) {
  iv <- paste0("y_", items)
  zs <- sapply(iv, function(v) {
    m <- mean(df[[v]][ctrl & complete_srq], na.rm = TRUE)
    s <- sd(df[[v]][ctrl & complete_srq], na.rm = TRUE)
    if (is.na(s) || s == 0) s <- 1
    (df[[v]] - m) / s
  })
  idx <- rowMeans(zs)
  idx[!complete_srq] <- NA
  m <- mean(idx[ctrl], na.rm = TRUE); s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - m) / s
}
df$mental_index <- anderson(all_items)
df$somatic_index <- anderson(somatic_items)
df$nonsomatic_index <- anderson(nonsom_items)
df$srq_sum <- rowSums(df[, item_vars, drop = FALSE])
df$srq_sum[!complete_srq] <- NA

# ---------------- outcomes ----------------
df$days_out <- num(df$outside_week)
df$under_curfew_y <- num(df$under_curfew)
df$never_out_y <- num(df$never_out)

# ---------------- RD estimation ----------------
h <- 45
dsub <- df[!is.na(df$x) & df$x >= -h & df$x <= h - 1, ]
cat("Bandwidth sample size:", nrow(dsub), "\n")

rd <- function(y) {
  f <- as.formula(paste0(y, " ~ treat + x + treat:x + c_fem + c_educ + c_eth | fe_month + fe_prov + fe_surv"))
  m <- feols(f, data = dsub, cluster = ~birth_ym)
  list(b = unname(coef(m)["treat"]), se = unname(sqrt(diag(vcov(m)))["treat"]), n = nobs(m))
}

r_days <- rd("days_out")
r_cur <- rd("under_curfew_y")
r_never <- rd("never_out_y")
r_mi <- rd("mental_index")
r_som <- rd("somatic_index")
r_non <- rd("nonsomatic_index")
r_sum <- rd("srq_sum")

for (nmx in c("r_days", "r_cur", "r_never", "r_mi", "r_som", "r_non", "r_sum")) {
  r <- get(nmx)
  cat(sprintf("%s: b=%.4f se=%.4f n=%d\n", nmx, r$b, r$se, r$n))
}

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_days$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_cur$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", as.integer(r_days$n)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", as.integer(r_cur$n)))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_mi$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_non$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", as.integer(r_mi$n)))
