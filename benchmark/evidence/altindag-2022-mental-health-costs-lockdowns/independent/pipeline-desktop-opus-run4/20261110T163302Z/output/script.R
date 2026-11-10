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
  v <- haven::zap_missing(v)
  as.vector(v)
}), stringsAsFactors = FALSE)
nms <- names(df)
cat("Columns:", paste(nms, collapse = ", "), "\n")

find_col <- function(patterns, exclude = character(0)) {
  for (p in patterns) {
    hit <- nms[grepl(p, nms, ignore.case = TRUE) & !(nms %in% exclude)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

# ---------------- running variable & treatment ----------------
yr <- suppressWarnings(as.numeric(df$year))
mo <- suppressWarnings(as.numeric(df$month))
if (all(is.na(yr)) || all(is.na(mo))) stop("year/month missing")
if (median(yr, na.rm = TRUE) < 100) yr <- yr + 1900
bidx <- yr * 12 + mo
thr <- 1955 * 12 + 12   # December 1955 (last treated birth month)
# months older than threshold, centered between Dec 1955 and Jan 1956
df$run <- (thr - bidx) + 0.5
df$z <- as.integer(df$run > 0)
if ("before1955" %in% nms) {
  b55 <- suppressWarnings(as.numeric(df$before1955))
  agree <- mean(b55 == df$z, na.rm = TRUE)
  cat("Agreement constructed treatment vs before1955:", agree, "\n")
  if (is.finite(agree) && agree > 0.95) df$z <- ifelse(is.na(b55), df$z, b55)
}
df$birth_ym <- bidx
df$mob <- mo

# ---------------- controls / FE ----------------
prov <- find_col(c("^province$", "province", "^il$", "^il_", "^city", "^sehir", "region", "^bolge", "prov"))
surv <- find_col(c("survey_taker_id", "surveyor", "interviewer", "anketor"))
cat("Province column:", prov, " Surveyor column:", surv, "\n")
df$prov_fe <- if (!is.na(prov)) as.character(df[[prov]]) else "1"
df$surv_fe <- if (!is.na(surv)) as.character(df[[surv]]) else "1"
df$educ_f <- as.character(df$education)
eth <- if ("non_turk" %in% nms) "non_turk" else find_col(c("non_turk", "ethnic"))
df$nonturk <- suppressWarnings(as.numeric(df[[eth]]))
df$fem <- suppressWarnings(as.numeric(df$female))

# ---------------- SRQ-20 items ----------------
to_yes <- function(v) {
  v <- suppressWarnings(as.numeric(v))
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) <= 2 && all(u %in% c(0, 1))) return(v)
  if (length(u) <= 2 && all(u %in% c(1, 2))) return(ifelse(is.na(v), NA, as.numeric(v == 1)))
  ifelse(v %in% c(0, 1), v, NA)
}
# Explicit mapping of the 20 SRQ-20 items to dataset columns
som_cols <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
non_cols <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused",
              "unhappy", "weepy", "unwillingness", "undecisiveness", "disrupted",
              "useless", "uninterest", "worthless", "suicidal", "usually_tired",
              "quickly_tired")
som_cols <- som_cols[som_cols %in% nms]
non_cols <- non_cols[non_cols %in% nms]
cat("Somatic items:", paste(som_cols, collapse = ", "), "\n")
cat("Nonsomatic items:", paste(non_cols, collapse = ", "), "\n")
all_cols <- c(som_cols, non_cols)
for (cc in all_cols) df[[paste0("it_", cc)]] <- to_yes(df[[cc]])
for (cc in all_cols) cat("item", cc, "nonmissing:", sum(!is.na(df[[paste0("it_", cc)]])),
                         "mean:", round(mean(df[[paste0("it_", cc)]], na.rm = TRUE), 3), "\n")

# number of answered SRQ-20 items per respondent
itm_all <- as.matrix(df[, paste0("it_", all_cols), drop = FALSE])
n_answered <- rowSums(!is.na(itm_all))
cat("Distribution of answered SRQ-20 items:\n"); print(table(n_answered))
max_missing <- 2
keep_full <- n_answered >= (length(all_cols) - max_missing)
cat(sprintf("DEVIATION: Overall SRQ-20 distress index and yes-count set to missing when more than %d of the 20 items are unanswered (paper does not state its missing-item rule; complete-case gave too few obs, any-item too many)\n", max_missing))

ctrl <- df$z == 0
anderson <- function(cols, keep = rep(TRUE, nrow(df))) {
  if (length(cols) == 0) return(rep(NA_real_, nrow(df)))
  zs <- sapply(cols, function(cc) {
    v <- df[[paste0("it_", cc)]]
    m <- mean(v[ctrl], na.rm = TRUE); s <- sd(v[ctrl], na.rm = TRUE)
    if (!is.finite(s) || s == 0) s <- 1
    (v - m) / s
  })
  zs <- as.matrix(zs)
  # average over available items (Anderson 2008 uses non-missing components)
  idx <- rowMeans(zs, na.rm = TRUE)
  idx[!is.finite(idx)] <- NA
  idx[!keep] <- NA
  m <- mean(idx[ctrl], na.rm = TRUE); s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - m) / s
}
df$distress_idx <- anderson(all_cols, keep_full)
df$somatic_idx <- anderson(som_cols)
df$nonsomatic_idx <- anderson(non_cols)
if (length(all_cols) > 0) {
  itm <- as.matrix(df[, paste0("it_", all_cols), drop = FALSE])
  df$srq_sum <- rowSums(itm, na.rm = TRUE)
  df$srq_sum[rowSums(!is.na(itm)) == 0] <- NA
  df$srq_sum[!keep_full] <- NA
} else df$srq_sum <- NA_real_
cat("Rows with complete SRQ-20:", sum(complete.cases(df[, paste0("it_", all_cols), drop = FALSE])), "\n")
cat("Rows with any SRQ-20 item:", sum(n_answered > 0), "\n")
cat("Rows meeting missing-item rule:", sum(keep_full), "\n")

# ---------------- estimation ----------------
h <- 45
est <- df[!is.na(df$run) & abs(df$run) < h, ]
cat("Obs within bandwidth:", nrow(est), "\n")

run_rd <- function(y) {
  d <- est
  d$yy <- suppressWarnings(as.numeric(d[[y]]))
  f <- yy ~ z + run + z:run + fem + nonturk | mob + prov_fe + surv_fe + educ_f
  m <- tryCatch(feols(f, data = d, cluster = ~birth_ym, warn = FALSE, notes = FALSE),
                error = function(e) { cat("Error for", y, ":", conditionMessage(e), "\n"); NULL })
  m
}

out <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
  else cat(sprintf("RESULT:%s=NA\n", name))
}

m_days <- run_rd("outside_week")
m_cur <- run_rd("under_curfew")
m_never <- run_rd("never_out")
m_dist <- run_rd("distress_idx")
m_som <- run_rd("somatic_idx")
m_non <- run_rd("nonsomatic_idx")
m_sum <- run_rd("srq_sum")

cf <- function(m) if (is.null(m)) NA_real_ else unname(coef(m)["z"])
se <- function(m) if (is.null(m)) NA_real_ else unname(sqrt(diag(vcov(m)))["z"])
nob <- function(m) if (is.null(m)) NA_real_ else as.numeric(nobs(m))

for (p in list(list("days", m_days), list("curfew", m_cur), list("never", m_never),
               list("distress", m_dist), list("somatic", m_som), list("nonsomatic", m_non),
               list("srqsum", m_sum))) {
  cat(sprintf("%s: coef=%.4f se=%.4f n=%s\n", p[[1]], cf(p[[2]]), se(p[[2]]), nob(p[[2]])))
}

emit("days_outside_last_week_table3_col3", cf(m_days))
emit("under_curfew_table3_col3", cf(m_cur))
emit("never_goes_out_table3_col3", cf(m_never))
emit("n_obs_days_outside_table3_col3", nob(m_days))
emit("n_obs_under_curfew_table3_col3", nob(m_cur))
emit("mental_distress_index_table4_col3", cf(m_dist))
emit("somatic_symptoms_index_table4_col3", cf(m_som))
emit("nonsomatic_symptoms_index_table4_col3", cf(m_non))
emit("sum_srq20_yes_answers_table4_col3", cf(m_sum))
emit("n_obs_mental_distress_index_table4_col3", nob(m_dist))