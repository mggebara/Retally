suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
raw <- haven::read_dta(path)
df <- as.data.frame(haven::zap_labels(raw))
nm <- names(df)
cat("Columns:\n"); print(nm)

find_col <- function(cands, data_names = nm) {
  low <- tolower(data_names)
  for (c in cands) {
    i <- which(low == tolower(c))
    if (length(i) > 0) return(data_names[i[1]])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- Running variable (former owner's landholdings, centred at 500) ----------------
run_col <- find_col(c("norm_dist_Above", "norm_dist", "dist_Above", "dist500", "running", "Landholding_dist"))
if (is.na(run_col)) {
  hold_col <- find_col(c("Total_Landholdings", "landholdings", "cum_landholdings", "Landholdings", "total_holdings"))
  if (is.na(hold_col)) {
    g <- nm[grepl("landhold|holding", nm, ignore.case = TRUE)]
    g <- g[sapply(g, function(v) is.numeric(df[[v]]))]
    hold_col <- if (length(g)) g[1] else NA
  }
  if (is.na(hold_col)) stop("No running variable found")
  df$run <- num(df[[hold_col]]) - 500
  cat("Running variable built from", hold_col, "- 500\n")
} else {
  df$run <- num(df[[run_col]])
  cat("Running variable:", run_col, "\n")
}
print(summary(df$run))
mx <- max(abs(df$run), na.rm = TRUE)
if (is.finite(mx) && mx < 20) {
  cat("Running variable appears scaled in hundreds of ha; rescaling by 100\n")
  df$run <- df$run * 100
}

# ---------------- Treatment ----------------
a_col <- find_col(c("Above500", "above500", "Above"))
if (!is.na(a_col)) {
  df$above <- num(df[[a_col]])
} else {
  df$above <- as.numeric(df$run >= 0)
}
df$above[is.na(df$above) & !is.na(df$run)] <- as.numeric(df$run[is.na(df$above) & !is.na(df$run)] >= 0)
cat("Treatment vs sign(run):\n"); print(table(df$above, df$run >= 0, useNA = "ifany"))

# ---------------- Outcome: household earnings per capita ----------------
y_col <- find_col(c("hh_earnings_pc", "hh_earnings_percap", "earnings_pc", "earnings_percap",
                    "hh_income_pc", "income_pc", "income_percap", "Income_pc", "HH_Income_pc",
                    "hh_inc_pc", "ingpe", "ingpc", "earnings_per_capita", "income_per_capita"))
if (is.na(y_col)) {
  g <- nm[grepl("(earn|income|ingre|ingpe|inc_)", nm, ignore.case = TRUE) &
            grepl("(pc|cap|perc|per_c)", nm, ignore.case = TRUE)]
  g <- g[sapply(g, function(v) is.numeric(df[[v]]))]
  if (length(g)) y_col <- g[1]
}
if (is.na(y_col)) {
  # construct from household income / household size
  inc_col <- find_col(c("hh_income", "hh_earnings", "ingfa", "Household_Income", "income_hh", "Total_Income"))
  sz_col <- find_col(c("hh_size", "hhsize", "Household_Size", "miembros", "num_members", "hh_members"))
  if (!is.na(inc_col) && !is.na(sz_col)) {
    df$y_lvl <- num(df[[inc_col]]) / num(df[[sz_col]])
    cat("Outcome constructed:", inc_col, "/", sz_col, "\n")
  } else stop("No earnings per capita outcome found")
} else {
  df$y_lvl <- num(df[[y_col]])
  cat("Outcome:", y_col, "\n")
}
print(summary(df$y_lvl))

# ---------------- Survey round ----------------
yr_col <- find_col(c("survey_year", "year", "anio", "round"))
df$round <- if (!is.na(yr_col)) df[[yr_col]] else 1

# ---------------- Former owner (cluster) ----------------
own_col <- find_col(c("owner_id", "Owner_id", "former_owner_id", "Expropretario_id", "Expropietario_id",
                      "Landowner_id", "exprop_id", "Expropretario_ISTA", "Expropietario_ISTA",
                      "former_owner", "Owner", "propietario"))
if (is.na(own_col)) {
  g <- nm[grepl("(owner|propiet|expropr)", nm, ignore.case = TRUE) & !grepl("^Land_Owner$", nm)]
  if (length(g)) own_col <- g[1]
}
cat("Cluster (former owner):", own_col, "\n")

# ---------------- Property id ----------------
prop_col <- find_col(c("match_id", "property_id", "prop_id"))
if (!is.na(prop_col)) {
  df$prop <- as.character(df[[prop_col]])
} else {
  rc <- find_col(c("Reform_Coop_id")); hc <- find_col(c("Hacienda_id"))
  df$prop <- ifelse(!is.na(df[[rc]]) & as.character(df[[rc]]) != "",
                    paste0("C", df[[rc]]), paste0("H", df[[hc]]))
}
# If property ids missing, fall back to coop/hacienda ids
miss_p <- is.na(df$prop) | df$prop == "" | df$prop == "NA"
if (any(miss_p)) {
  rc <- find_col(c("Reform_Coop_id")); hc <- find_col(c("Hacienda_id"))
  alt <- rep(NA_character_, nrow(df))
  if (!is.na(rc)) alt <- ifelse(!is.na(df[[rc]]) & as.character(df[[rc]]) != "", paste0("C", df[[rc]]), alt)
  if (!is.na(hc)) alt <- ifelse(is.na(alt) & !is.na(df[[hc]]) & as.character(df[[hc]]) != "", paste0("H", df[[hc]]), alt)
  df$prop[miss_p] <- alt[miss_p]
}

if (!is.na(own_col)) {
  df$owner <- as.character(df[[own_col]])
  bad <- is.na(df$owner) | df$owner == "" | df$owner == "NA"
  df$owner[bad] <- paste0("P_", df$prop[bad])
} else {
  df$owner <- df$prop
}

# ---------------- Matched sample ----------------
base <- df %>% filter(!is.na(run), !is.na(above), !is.na(prop))
cat("Base rows:", nrow(base), "\n")

# ---------------- Level regressions ----------------
lvl <- function(bw) {
  d <- base %>% filter(abs(run) <= bw, !is.na(y_lvl))
  m <- feols(y_lvl ~ above + run + above:run | round, data = d, cluster = ~owner)
  print(summary(m))
  list(b = unname(coef(m)["above"]), n = nobs(m), cl = length(unique(d$owner)))
}
l300 <- lvl(300)
l150 <- lvl(150)

# ---------------- IQR regressions (one obs per property, >= 5 workers) ----------------
q2 <- function(x, p) as.numeric(quantile(x, p, type = 2, na.rm = TRUE))
prop_df <- base %>% filter(!is.na(y_lvl)) %>%
  group_by(prop) %>%
  summarise(n_w = n(),
            iqr = q2(y_lvl, 0.75) - q2(y_lvl, 0.25),
            run = first(run), above = first(above), owner = first(owner),
            .groups = "drop") %>%
  filter(n_w >= 5)

iqr_reg <- function(bw) {
  d <- prop_df %>% filter(abs(run) <= bw)
  m <- feols(iqr ~ above + run + above:run, data = d, cluster = ~owner)
  print(summary(m))
  list(b = unname(coef(m)["above"]), n = nobs(m), cl = length(unique(d$owner)))
}
i300 <- iqr_reg(300)
i150 <- iqr_reg(150)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", i300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", i150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(l300$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(l150$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(i300$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(i150$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(l300$cl)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(l150$cl)))
