suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns.script-free/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
raw <- haven::read_dta(path)
nm <- names(raw)
cat("Columns:\n"); print(nm)

# ---------- helpers ----------
num <- function(v) as.numeric(haven::zap_labels(v))
first_match <- function(patterns, exclude = character(0)) {
  for (p in patterns) {
    hits <- setdiff(grep(p, nm, ignore.case = TRUE, value = TRUE), exclude)
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}
# recode an item to 1 = yes (symptom present), 0 = no
to_yes <- function(v) {
  labs <- attr(v, "labels")
  x <- num(v)
  vals <- sort(unique(x[!is.na(x)]))
  if (all(vals %in% c(0, 1))) return(x)
  if (!is.null(labs)) {
    ln <- tolower(names(labs))
    yesv <- labs[grepl("^yes|evet|^1\\s*yes", ln)]
    nov  <- labs[grepl("^no|hay", ln)]
    if (length(yesv) >= 1 && length(nov) >= 1) {
      out <- ifelse(x %in% yesv, 1, ifelse(x %in% nov, 0, NA))
      return(out)
    }
  }
  if (length(vals) == 2 && all(vals %in% c(1, 2))) return(ifelse(x == 1, 1, ifelse(x == 2, 0, NA)))
  x[!(x %in% c(0, 1))] <- NA
  x
}

df <- raw

# ---------- birth year / month ----------
yr_col <- if ("year" %in% nm) "year" else first_match(c("birth_year", "byear", "dogum_yil"))
mo_col <- if ("month" %in% nm) "month" else first_match(c("birth_month", "bmonth", "dogum_ay"))
df$by <- num(df[[yr_col]])
df$bm <- num(df[[mo_col]])
cat("Birth year range:", range(df$by, na.rm = TRUE), "\n")

# running variable: months older than December 1955 (Dec 1955 = 0; treated x >= 0)
df$ym <- df$by * 12 + df$bm
df$x <- (1955 * 12 + 12) - df$ym
df$z <- as.numeric(df$x >= 0)
if ("before1955" %in% nm) {
  b <- num(df$before1955)
  cat("Agreement constructed z vs before1955:", mean(b == df$z, na.rm = TRUE), "\n")
}
df$cl_ym <- df$by * 100 + df$bm

# ---------- fixed effects / controls ----------
prov_col <- first_match(c("^province$", "^province", "^il$", "^il_", "^city$", "^city", "^region$", "region", "^sehir"))
surv_col <- if ("survey_taker_id" %in% nm) "survey_taker_id" else first_match(c("surveyor", "interviewer", "survey_taker"))
cat("Province column:", prov_col, " Surveyor column:", surv_col, "\n")
df$prov <- if (!is.na(prov_col)) num(df[[prov_col]]) else 1
df$surv <- num(df[[surv_col]])
df$edu <- num(df$education)
df$eth <- num(df$ethnicity)
df$fem <- num(df$female)

# ---------- outcomes: mobility ----------
df$days_out <- num(df$outside_week)
df$under_curfew_y <- num(df$under_curfew)
df$never_out_y <- num(df$never_out)

# ---------- SRQ-20 items ----------
item_patterns <- list(
  # somatic
  headache    = c("headache", "head_ache", "bas_agri"),
  shaking     = c("^shaking", "shak", "tremb"),
  indigestion = c("indigestion", "digest"),
  stomach     = c("stomach", "uncomfort"),
  # nonsomatic
  appetite    = c("appetite"),
  sleep       = c("sleep"),
  frightened  = c("fright", "scare", "afraid"),
  nervous     = c("^nervous", "nervous", "worried", "tense"),
  thinking    = c("think", "clear"),
  unhappy     = c("^unhappy", "unhappy"),
  cry         = c("cry", "crie"),
  enjoy       = c("enjoy"),
  decision    = c("decision", "decide"),
  work_suffer = c("work_suff", "daily_work", "worksuff", "suffer"),
  useful      = c("useful", "play_part", "role"),
  interest    = c("uninte", "interest"),
  worthless   = c("^worthless", "worthless"),
  suicide     = c("suicid"),
  tired_all   = c("tired_all", "always_tired", "tired_always", "alltime", "all_time", "^tired$", "tired"),
  tired_easy  = c("tired_eas", "easily_tired", "tire_eas", "easily", "fatig")
)
item_cols <- c()
used <- c()
for (it in names(item_patterns)) {
  m <- first_match(item_patterns[[it]], exclude = used)
  item_cols[it] <- m
  if (!is.na(m)) used <- c(used, m)
}
cat("SRQ-20 item mapping:\n"); print(item_cols)
somatic_items <- c("headache", "shaking", "indigestion", "stomach")
nonsomatic_items <- setdiff(names(item_patterns), somatic_items)

items <- list()
for (it in names(item_cols)) {
  if (!is.na(item_cols[it])) items[[it]] <- to_yes(df[[item_cols[it]]])
}
items <- as.data.frame(items)
avail <- names(items)
cat("Items found:", length(avail), "\n")

ctrl <- df$z == 0
zscore_ctrl <- function(v) {
  mu <- mean(v[ctrl], na.rm = TRUE); s <- sd(v[ctrl], na.rm = TRUE)
  (v - mu) / s
}
make_index <- function(its) {
  its <- intersect(its, avail)
  zs <- sapply(its, function(i) zscore_ctrl(items[[i]]))
  zs <- as.matrix(zs)
  complete <- rowSums(is.na(as.matrix(items[, its, drop = FALSE]))) == 0
  idx <- rowMeans(zs)
  idx[!complete] <- NA
  zscore_ctrl(idx)
}
all_complete <- rowSums(is.na(as.matrix(items))) == 0
df$mdi <- make_index(avail)
df$som <- make_index(somatic_items)
df$nonsom <- make_index(nonsomatic_items)
df$srq_sum <- rowSums(as.matrix(items))
df$srq_sum[!all_complete] <- NA
# indices defined on respondents answering all SRQ-20 items
df$som[!all_complete] <- NA
df$nonsom[!all_complete] <- NA

# ---------- RD estimation ----------
h <- 45
sub <- df %>% filter(!is.na(x), abs(x) <= h)
sub$x_z <- sub$x * sub$z

run_rd <- function(y) {
  d <- sub[!is.na(sub[[y]]), ]
  fml <- as.formula(paste0(y, " ~ z + x + x_z + i(edu) + i(eth) + fem | bm + prov + surv"))
  m <- feols(fml, data = d, cluster = ~cl_ym, warn = FALSE, notes = FALSE)
  list(b = unname(coef(m)["z"]), se = unname(sqrt(diag(vcov(m)))["z"]), n = nobs(m))
}

r_days <- run_rd("days_out")
r_curf <- run_rd("under_curfew_y")
r_never <- run_rd("never_out_y")
r_mdi <- run_rd("mdi")
r_som <- run_rd("som")
r_nonsom <- run_rd("nonsom")
r_sum <- run_rd("srq_sum")

cat("SEs: days", r_days$se, "curfew", r_curf$se, "never", r_never$se,
    "mdi", r_mdi$se, "som", r_som$se, "nonsom", r_nonsom$se, "sum", r_sum$se, "\n")

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_days$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_curf$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", as.integer(r_days$n)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", as.integer(r_curf$n)))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_mdi$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_nonsom$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", as.integer(r_mdi$n)))