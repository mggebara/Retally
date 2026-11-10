suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns.script-free/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
raw <- haven::read_dta(path)
df <- as.data.frame(haven::zap_labels(raw))
nm <- names(df)
cat("Columns:", paste(nm, collapse = ", "), "\n")

num <- function(v) suppressWarnings(as.numeric(v))

find_col <- function(patterns, exclude = character(0)) {
  for (p in patterns) {
    hits <- nm[grepl(p, nm, ignore.case = TRUE)]
    hits <- setdiff(hits, exclude)
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

# ---- birth year / month ----
by_col <- if ("year" %in% nm) "year" else find_col(c("birth_?year", "byear", "dob_year", "yob"))
bm_col <- if ("month" %in% nm) "month" else find_col(c("birth_?month", "bmonth", "dob_month", "mob"))
df$byear <- num(df[[by_col]])
df$bmonth <- num(df[[bm_col]])
if (all(is.na(df$byear)) || median(df$byear, na.rm = TRUE) < 1900) {
  alt <- find_col(c("birth_?year", "byear", "yob"), exclude = by_col)
  if (!is.na(alt)) df$byear <- num(df[[alt]])
}
cat("Birth year range:", range(df$byear, na.rm = TRUE), "\n")
df$bidx <- df$byear * 12 + df$bmonth

# ---- treatment & running variable ----
if ("before1955" %in% nm) {
  df$z_raw <- num(df$before1955)
  T_idx <- suppressWarnings(max(df$bidx[df$z_raw == 1], na.rm = TRUE))
  if (!is.finite(T_idx)) T_idx <- 1955 * 12 + 12
} else {
  T_idx <- 1955 * 12 + 12
}
cat("Threshold birth index (year, month):", floor((T_idx - 1) / 12), ((T_idx - 1) %% 12) + 1, "\n")
df$x <- T_idx - df$bidx          # months older than threshold month (>=0 treated)
df$z <- as.numeric(df$x >= 0)
if ("before1955" %in% nm) {
  cat("Agreement z vs before1955:", mean(df$z == df$z_raw, na.rm = TRUE), "\n")
}
df$mob_cluster <- df$bidx

# ---- fixed effects / controls ----
prov_col <- find_col(c("^province", "province", "^il$", "^il_", "^city", "sehir", "^region", "region", "prov"))
surv_col <- if ("survey_taker_id" %in% nm) "survey_taker_id" else find_col(c("survey_taker", "surveyor", "interviewer", "anketor"))
cat("Province column:", prov_col, " Surveyor column:", surv_col, "\n")

df$fe_month <- factor(df$bmonth)
df$fe_prov <- if (!is.na(prov_col)) factor(df[[prov_col]]) else factor(1)
df$fe_surv <- if (!is.na(surv_col)) factor(df[[surv_col]]) else factor(1)
df$c_edu <- factor(df$education)
df$c_eth <- factor(df$ethnicity)
df$c_fem <- factor(df$female)

# ---- SRQ-20 items ----
to_binary <- function(v) {
  v <- num(v)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) > 0 && all(u %in% c(1, 2)) && !all(u %in% c(0, 1))) {
    v <- ifelse(v == 1, 1, ifelse(v == 2, 0, NA))
  }
  v[!(v %in% c(0, 1))] <- NA
  v
}

item_specs <- list(
  # somatic
  headache    = list(p = c("headache", "head"), s = TRUE),
  shaking     = list(p = c("^shaking$", "shak", "trembl", "hand"), s = TRUE),
  indigestion = list(p = c("^indigestion$", "digest"), s = TRUE),
  stomach     = list(p = c("stomach", "uncomfort"), s = TRUE),
  # nonsomatic
  appetite    = list(p = c("appetite"), s = FALSE),
  sleep       = list(p = c("sleep"), s = FALSE),
  frightened  = list(p = c("fright", "scare", "afraid", "fear"), s = FALSE),
  nervous     = list(p = c("^nervous$", "nervous", "worried", "tense"), s = FALSE),
  suicide     = list(p = c("suicid", "end_?life", "kill"), s = FALSE),
  thinking    = list(p = c("think", "concentr", "clear"), s = FALSE),
  unhappy     = list(p = c("^unhappy$", "unhappy", "sad"), s = FALSE),
  cry         = list(p = c("cry", "cried"), s = FALSE),
  enjoy       = list(p = c("enjoy"), s = FALSE),
  decision    = list(p = c("decision", "decide"), s = FALSE),
  dailywork   = list(p = c("daily_?work", "work_?suffer", "suffer"), s = FALSE),
  useful      = list(p = c("useful", "play", "role", "part_in"), s = FALSE),
  interest    = list(p = c("uninte", "interest"), s = FALSE),
  worthless   = list(p = c("^worthless$", "worthless"), s = FALSE),
  tired_easy  = list(p = c("easily_?tired", "eas[a-z]*_?tire", "tire[a-z]*_?eas"), s = FALSE),
  tired_all   = list(p = c("tired_?all", "always_?tired", "tired_?always", "tire[a-z]*_?time", "^tired$", "tired", "fatigue"), s = FALSE)
)
used <- character(0)
item_cols <- c()
for (it in names(item_specs)) {
  col <- find_col(item_specs[[it]]$p, exclude = used)
  if (!is.na(col)) {
    used <- c(used, col)
    item_cols[it] <- col
  }
}
cat("SRQ items found:", length(item_cols), "\n")
print(item_cols)
som_items <- intersect(names(item_cols), c("headache", "shaking", "indigestion", "stomach"))
non_items <- setdiff(names(item_cols), som_items)

for (it in names(item_cols)) df[[paste0("srq_", it)]] <- to_binary(df[[item_cols[it]]])

control <- df$z == 0

anderson <- function(items) {
  cols <- paste0("srq_", items)
  M <- as.matrix(df[, cols, drop = FALSE])
  Zs <- sapply(seq_along(cols), function(j) {
    v <- M[, j]
    mu <- mean(v[control], na.rm = TRUE)
    s <- sd(v[control], na.rm = TRUE)
    if (!is.finite(s) || s == 0) s <- sd(v, na.rm = TRUE)
    (v - mu) / s
  })
  Zs <- matrix(Zs, ncol = length(cols))
  complete <- rowSums(is.na(M)) == 0
  idx <- rowMeans(Zs)
  idx[!complete] <- NA
  mu <- mean(idx[control], na.rm = TRUE)
  s <- sd(idx[control], na.rm = TRUE)
  (idx - mu) / s
}

prebuilt <- function(pats) {
  c <- find_col(pats)
  if (!is.na(c)) num(df[[c]]) else NULL
}

if (length(item_cols) == 20) {
  df$mdi <- anderson(names(item_cols))
  df$somi <- anderson(som_items)
  df$nsomi <- anderson(non_items)
  M <- as.matrix(df[, paste0("srq_", names(item_cols))])
  df$srq_sum <- ifelse(rowSums(is.na(M)) == 0, rowSums(M), NA)
} else {
  cat("Not all 20 SRQ items identified; using prebuilt indices where available\n")
  v <- prebuilt(c("distress_index", "mental_distress", "srq_index", "mh_index"))
  df$mdi <- if (!is.null(v)) v else anderson(names(item_cols))
  v <- prebuilt(c("^somatic", "somatic_index"))
  df$somi <- if (!is.null(v)) v else anderson(som_items)
  v <- prebuilt(c("nonsomatic", "non_somatic"))
  df$nsomi <- if (!is.null(v)) v else anderson(non_items)
  v <- prebuilt(c("srq_?sum", "sum_srq", "srq20", "srq_?total"))
  if (!is.null(v)) {
    df$srq_sum <- v
  } else {
    M <- as.matrix(df[, paste0("srq_", names(item_cols))])
    df$srq_sum <- ifelse(rowSums(is.na(M)) == 0, rowSums(M), NA)
  }
}

# ---- outcomes ----
df$y_out <- num(df$outside_week)
df$y_curf <- to_binary(df$under_curfew)
df$y_never <- to_binary(df$never_out)

# ---- RD estimation ----
h <- 45
sub <- df[!is.na(df$x) & abs(df$x) < h, ]
cat("Obs within bandwidth:", nrow(sub), "\n")

rd <- function(y) {
  f <- as.formula(paste0(y, " ~ z + x + z:x + c_edu + c_eth + c_fem | fe_month + fe_prov + fe_surv"))
  m <- feols(f, data = sub, cluster = ~mob_cluster)
  list(b = unname(coef(m)["z"]), se = unname(sqrt(diag(vcov(m)))["z"]), n = nobs(m))
}

r_out <- rd("y_out")
r_curf <- rd("y_curf")
r_never <- rd("y_never")
r_mdi <- rd("mdi")
r_som <- rd("somi")
r_non <- rd("nsomi")
r_sum <- rd("srq_sum")

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_out$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_curf$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", as.integer(r_out$n)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", as.integer(r_curf$n)))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_mdi$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_non$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", as.integer(r_mdi$n)))
