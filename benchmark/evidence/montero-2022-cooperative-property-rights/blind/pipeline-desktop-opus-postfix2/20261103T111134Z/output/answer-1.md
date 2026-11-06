suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
raw <- haven::read_dta(path)
raw <- haven::zap_labels(raw)
df <- as.data.frame(raw)
nms <- names(df)

pick_col <- function(cands, regex = NULL, numeric_only = TRUE) {
  for (c in cands) {
    hit <- nms[tolower(nms) == tolower(c)]
    if (length(hit) > 0) {
      v <- df[[hit[1]]]
      if (!numeric_only || is.numeric(v)) return(hit[1])
    }
  }
  if (!is.null(regex)) {
    hits <- nms[grepl(regex, nms, ignore.case = TRUE)]
    for (h in hits) {
      v <- df[[h]]
      if (!numeric_only || is.numeric(v)) {
        if (sum(!is.na(v)) > 0) return(h)
      }
    }
  }
  NA_character_
}

# Outcome: household earnings per capita in the previous month
y_col <- pick_col(
  c("hh_earnings_pc", "HH_Earnings_pc", "Earnings_pc", "earnings_pc", "hh_income_pc",
    "HH_Income_pc", "Income_pc", "income_pc", "ingpe", "Household_Earnings_pc",
    "hh_earn_pc", "earn_pc", "Earnings_per_capita", "Income_per_capita"),
  regex = "(earn|income|ing).*(pc|per_?cap|percap)|^ingpe$"
)
if (is.na(y_col)) y_col <- pick_col(c("Work_Income"))
cat(sprintf("NOTE: outcome column = %s\n", y_col))

# Running variable and treatment
run_col <- pick_col(c("own_amt"))
df$own_amt_rv <- as.numeric(df[[run_col]])
df$dist <- df$own_amt_rv - 500
if ("Above500" %in% nms) {
  df$Above500 <- as.numeric(df$Above500)
  df$Above500[is.na(df$Above500) & !is.na(df$own_amt_rv)] <-
    as.numeric(df$own_amt_rv[is.na(df$Above500) & !is.na(df$own_amt_rv)] >= 500)
} else {
  df$Above500 <- as.numeric(df$own_amt_rv >= 500)
}

# Survey round
yr_col <- pick_col(c("survey_year", "year", "anio"), numeric_only = FALSE)
df$round <- if (!is.na(yr_col)) as.character(df[[yr_col]]) else "1"

# Former owner (cluster) identifier
owner_col <- pick_col(c("Expropretario_ISTA", "owner_id", "Owner_id", "propietario_id",
                        "Total_Propretario"), numeric_only = FALSE)
if (!is.na(owner_col)) {
  ov <- as.character(df[[owner_col]])
  ov[ov == ""] <- NA
  df$owner <- ov
} else {
  df$owner <- NA_character_
}
# Fallback: identify owner by cumulative landholdings (unique per former owner)
df$owner[is.na(df$owner)] <- paste0("amt_", format(df$own_amt_rv[is.na(df$owner)], digits = 12))

# Property identifier
mk <- function(col) {
  if (col %in% nms) { v <- as.character(df[[col]]); v[v == "" | v == "NA"] <- NA; v } else rep(NA_character_, nrow(df))
}
prop <- mk("match_id")
coop <- mk("Reform_Coop_id"); hac <- mk("Hacienda_id")
prop[is.na(prop) & !is.na(coop)] <- paste0("C_", coop[is.na(prop) & !is.na(coop)])
prop[is.na(prop) & !is.na(hac)] <- paste0("H_", hac[is.na(prop) & !is.na(hac)])
prop[is.na(prop)] <- paste0("O_", df$owner[is.na(prop)])
df$prop <- prop

df$y <- as.numeric(df[[y_col]])

# ---------------- Sample construction ----------------
build_sample <- function(bw, name) {
  s <- df
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(s)))
  if ("Matched" %in% nms) {
    m <- suppressWarnings(as.numeric(s$Matched))
    if (length(unique(na.omit(m))) > 1) s <- s[!is.na(m) & m == 1, ]
  }
  cat(sprintf("SAMPLE:%s:matched_to_coop_or_hacienda=%d\n", name, nrow(s)))
  s <- s[!is.na(s$own_amt_rv), ]
  cat(sprintf("SAMPLE:%s:nonmissing_landholdings=%d\n", name, nrow(s)))
  s <- s[abs(s$dist) <= bw, ]
  cat(sprintf("SAMPLE:%s:within_%dha=%d\n", name, bw, nrow(s)))
  s
}

fit_level <- function(s, name) {
  s <- s[!is.na(s$y), ]
  m <- feols(y ~ Above500 + dist + Above500:dist | round, data = s, cluster = ~owner)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  used <- s
  if (!is.null(m$obs_selection$obsRemoved)) used <- s[m$obs_selection$obsRemoved, ]
  list(m = m, ncl = length(unique(used$owner)))
}

fit_iqr <- function(s, name) {
  s <- s[!is.na(s$y), ]
  agg <- s %>%
    group_by(prop) %>%
    summarise(n_mem = n(),
              iqr = as.numeric(quantile(y, 0.75, na.rm = TRUE) - quantile(y, 0.25, na.rm = TRUE)),
              Above500 = first(Above500),
              dist = first(dist),
              owner = first(owner),
              .groups = "drop")
  cat(sprintf("SAMPLE:%s:collapsed_to_property=%d\n", name, nrow(agg)))
  agg <- agg[agg$n_mem >= 5, ]
  cat(sprintf("SAMPLE:%s:at_least_5_members=%d\n", name, nrow(agg)))
  m <- feols(iqr ~ Above500 + dist + Above500:dist, data = agg, cluster = ~owner)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  list(m = m, ncl = length(unique(agg$owner)))
}

s300 <- build_sample(300, "level_bw300")
r1 <- fit_level(s300, "level_bw300")
s150 <- build_sample(150, "level_bw150")
r2 <- fit_level(s150, "level_bw150")
s300b <- build_sample(300, "iqr_bw300")
r3 <- fit_iqr(s300b, "iqr_bw300")
s150b <- build_sample(150, "iqr_bw150")
r4 <- fit_iqr(s150b, "iqr_bw150")

for (r in list(r1, r2, r3, r4)) print(summary(r$m))

gc <- function(r) unname(coef(r$m)["Above500"])
gse <- function(r) unname(sqrt(diag(vcov(r$m)))["Above500"])

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", gc(r1)))
cat(sprintf("RESULT:earnings_level_above500_bw300_se=%.6f\n", gse(r1)))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", gc(r2)))
cat(sprintf("RESULT:earnings_level_above500_bw150_se=%.6f\n", gse(r2)))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", gc(r3)))
cat(sprintf("RESULT:earnings_iqr_above500_bw300_se=%.6f\n", gse(r3)))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", gc(r4)))
cat(sprintf("RESULT:earnings_iqr_above500_bw150_se=%.6f\n", gse(r4)))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", nobs(r1$m)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", nobs(r2$m)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", nobs(r3$m)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", nobs(r4$m)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", r1$ncl))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", r2$ncl))
