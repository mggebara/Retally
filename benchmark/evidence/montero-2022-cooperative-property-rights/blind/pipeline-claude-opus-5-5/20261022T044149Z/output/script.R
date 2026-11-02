# Reproduction of Montero (2022), Table 5: RD at the 500 ha threshold for worker
# earnings levels and within-property interquartile range (IQR).
# Column names are detected heuristically, so check the diagnostic lines printed below.
suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free"
df <- haven::read_dta(file.path(path, "ehpm_incomemodule_wreform.dta"))
df <- haven::zap_labels(df)
df <- as.data.frame(df)
nm <- names(df)
cat("Columns:\n"); print(nm)

# Return the first candidate name that exists in the data, matching case-insensitively.
pick <- function(cands) {
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  NULL
}

# ---- Earnings variable: household earnings per capita ----
earn_var <- pick(c("ingpe", "hh_earnings_pc", "hh_income_pc", "income_pc", "earnings_pc",
                   "Earnings_pc", "HH_Earnings_pc", "Income_pc", "ingreso_pc", "inc_pc",
                   "hh_inc_pc", "ingpe_m", "Household_Earnings_pc"))
if (is.null(earn_var)) {
  # Fall back to the first numeric column whose name suggests per-capita income.
  cand <- nm[grepl("ingpe|percap|per_cap|_pc$|pc_|capita", tolower(nm))]
  cand <- cand[sapply(df[cand], is.numeric)]
  if (length(cand) > 0) earn_var <- cand[1]
}
cat("Earnings variable:", earn_var, "\n")

# ---- Running variable: former owner's total landholdings, centred at 500 ha ----
run <- NULL
if (!is.null(pick("norm_dist_Above"))) {
  r <- as.numeric(df[[pick("norm_dist_Above")]])
  # Use the normalised distance only if it looks like it is measured in hectares.
  if (max(abs(r), na.rm = TRUE) > 10) run <- r
}
if (is.null(run)) {
  ls <- pick(c("Land_Size", "Land_Size_ha", "AREA_HECTAREA"))
  run <- as.numeric(df[[ls]]) - 500
}
df$run <- run
cat("Running variable summary:\n"); print(summary(df$run))

# ---- Treatment indicator ----
if (!is.null(pick("Above500"))) {
  df$above <- as.numeric(df[[pick("Above500")]])
  df$above[is.na(df$above)] <- as.numeric(df$run[is.na(df$above)] >= 0)
} else {
  df$above <- as.numeric(df$run >= 0)
}

# ---- Former-owner cluster identifier ----
own_var <- pick(c("Land_Owner", "Expropretario_ISTA", "owner_id"))
df$owner <- as.character(df[[own_var]])
cat("Owner variable:", own_var, "\n")

# ---- Property identifier ----
pid_var <- pick(c("match_id"))
if (!is.null(pid_var)) {
  df$pid <- as.character(df[[pid_var]])
} else {
  # No single property ID: combine the cooperative and hacienda IDs.
  rc <- if (!is.null(pick("Reform_Coop_id"))) as.character(df[[pick("Reform_Coop_id")]]) else NA
  hc <- if (!is.null(pick("Hacienda_id"))) as.character(df[[pick("Hacienda_id")]]) else NA
  df$pid <- ifelse(!is.na(rc) & rc != "", paste0("C", rc), paste0("H", hc))
}

# ---- Survey round ----
yr_var <- pick(c("survey_year", "year", "anio"))
df$yr <- as.factor(df[[yr_var]])

df$y <- as.numeric(df[[earn_var]])

base <- df %>%
  filter(!is.na(y), !is.na(run), !is.na(owner), owner != "", !is.na(yr))

# ---- Worker-level levels regressions ----
# y on Above500 with a separate linear slope on each side, survey-round FE, owner clusters.
run_level <- function(bw) {
  d <- base %>% filter(abs(run) <= bw)
  m <- feols(y ~ above + run + above:run | yr, data = d, cluster = ~owner)
  list(b = unname(coef(m)["above"]),
       n = nobs(m),
       ncl = length(unique(d$owner[obs(m)])))
}

l300 <- run_level(300)
l150 <- run_level(150)

# ---- Property-level IQR regressions (properties with >= 5 surveyed members) ----
# type = 2 averages at discontinuities, approximating Stata's default percentiles.
prop <- base %>%
  group_by(pid) %>%
  summarise(n_mem = n(),
            iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
            run = first(run), above = first(above), owner = first(owner),
            .groups = "drop") %>%
  filter(n_mem >= 5)

# One observation per property, so survey-round FE cannot be included here.
run_iqr <- function(bw) {
  d <- prop %>% filter(abs(run) <= bw)
  m <- feols(iqr ~ above + run + above:run, data = d, cluster = ~owner)
  list(b = unname(coef(m)["above"]), n = nobs(m))
}

i300 <- run_iqr(300)
i150 <- run_iqr(150)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", i300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", i150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(l300$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(l150$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(i300$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(i150$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(l300$ncl)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(l150$ncl)))