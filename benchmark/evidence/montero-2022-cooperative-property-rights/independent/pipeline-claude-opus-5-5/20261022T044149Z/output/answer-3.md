# Reproduces Table 5 (columns 1-4) of "Cooperative Property Rights":
# RD at the 500 ha cumulative-landholding threshold, earnings levels and IQR.
# Most variable names are not documented in the dataset listing, so the script
# picks them from candidate lists and logs every choice to stderr.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free"
df <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(path, "ehpm_incomemodule_wreform.dta"))))
nm <- names(df)

message("Columns: ", paste(nm, collapse = ", "))

# Return the first column whose name matches any pattern (case-insensitive).
# Patterns are tried in priority order. Optionally require a numeric column.
pick <- function(patterns, exclude = character(0), numeric_only = TRUE) {
  for (p in patterns) {
    hits <- nm[grepl(p, nm, ignore.case = TRUE)]
    hits <- setdiff(hits, exclude)
    if (length(hits) == 0) next
    if (numeric_only) {
      is_num <- vapply(hits, function(h) is.numeric(df[[h]]), logical(1))
      hits <- hits[is_num]
    }
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

# ---- Outcome: household earnings per capita in the previous month ----
yvar <- pick(c("^ingpe$", "^ingpc$", "hh_?inc.*pc", "income_?pc", "inc_?pc", "earn.*pc", "earn.*cap",
               "inc.*per_?cap", "per_?cap", "percap", "income_per", "ingpe", "ingpc",
               "hh_?earn", "earning", "^income$", "hh_?income", "ingreso"),
             exclude = c("Other_Income", "Land_Net_Income", "Land_revenue", "Land_Revenue"))
message("Outcome variable: ", yvar)

# ---- Running variable: former owner's total landholdings, centered at 500 ha ----
# norm_dist_Above is the interaction Above500 * norm_dist (zero below the cutoff),
# which makes Above500:x collinear; use the two-sided norm_dist instead.
two_sided <- function(v) {
  v <- v[!is.na(v)]
  length(v) > 0 && any(v < 0) && any(v > 0) && diff(range(v)) > 50
}
if ("norm_dist" %in% nm && two_sided(df$norm_dist)) {
  df$x <- df$norm_dist
  message("Running variable: norm_dist")
} else if ("own_amt" %in% nm) {
  df$x <- df$own_amt - 500
  message("Running variable: own_amt - 500")
} else {
  df$x <- df$norm_dist_Above
  message("Running variable: norm_dist_Above (fallback)")
}

# ---- Treatment indicator ----
if (!"Above500" %in% nm) df$Above500 <- as.numeric(df$x >= 0)
df$Above500 <- as.numeric(df$Above500)

# ---- Survey-round fixed effect ----
fevar <- if ("survey_year" %in% nm) "survey_year" else "year"
df$fe <- df[[fevar]]
message("Survey-round FE variable: ", fevar)

# ---- Cluster variable: former owner ----
clvar <- pick(c("^owner_?id$", "^own_?id$", "former_?owner", "landowner_?id", "expropietario_?id",
                "propietario_?id", "^Expropretario_ISTA$", "^Land_Owner$"), numeric_only = FALSE)
if (is.na(clvar) || mean(is.na(df[[clvar]]) | as.character(df[[clvar]]) == "") > 0.2) {
  # Fallback: an owner's cumulative holdings uniquely identify the owner in practice.
  df$cl <- as.character(round(df$x, 4))
  message("Cluster variable: running variable value (fallback)")
} else {
  df$cl <- as.character(df[[clvar]])
  message("Cluster variable: ", clvar)
}

# ---- Property identifier (for the within-property IQR) ----
if (all(c("Reform_Coop_id", "Hacienda_id") %in% nm)) {
  df$prop <- ifelse(!is.na(df$Reform_Coop_id) & df$Reform_Coop_id != "",
                    paste0("c", df$Reform_Coop_id), paste0("h", df$Hacienda_id))
  message("Property id: Reform_Coop_id / Hacienda_id")
} else if ("match_id" %in% nm) {
  df$prop <- as.character(df$match_id)
  message("Property id: match_id")
} else {
  df$prop <- df$cl
  message("Property id: cluster variable (fallback)")
}

df$y <- as.numeric(df[[yvar]])
base <- df %>% filter(!is.na(y), !is.na(x), !is.na(Above500))

# ---- Columns 1-2: earnings levels, one observation per worker ----
# Local linear in the running variable on each side of the cutoff, survey-round FE,
# SEs clustered by former owner.
run_level <- function(bw) {
  d <- base %>% filter(abs(x) <= bw)
  m <- feols(y ~ Above500 + x + Above500:x | fe, data = d, cluster = ~cl)
  list(b = unname(coef(m)["Above500"]), se = unname(sqrt(diag(vcov(m)))["Above500"]),
       n = nobs(m), ncl = length(unique(d$cl[obs(m)])))
}

# Mode of a vector that may be entirely NA (returns NA in that case).
safe_mode <- function(v) {
  v <- v[!is.na(v)]
  if (length(v) == 0) return(NA_real_)
  tb <- table(v)
  as.numeric(names(tb)[which.max(tb)])
}

# ---- Columns 3-4: within-property IQR, one observation per property ----
# Properties need at least five surveyed workers.
run_iqr <- function(bw) {
  d <- base %>% filter(abs(x) <= bw) %>%
    group_by(prop) %>%
    summarise(n_mem = n(),
              iqr = unname(quantile(y, 0.75, na.rm = TRUE) - quantile(y, 0.25, na.rm = TRUE)),
              x = first(x), Above500 = first(Above500), cl = first(cl),
              fe = safe_mode(fe), .groups = "drop") %>%
    filter(n_mem >= 5)
  # Survey-round FE are not identifiable with one observation per property, so plain OLS.
  m <- feols(iqr ~ Above500 + x + Above500:x, data = d, cluster = ~cl)
  list(b = unname(coef(m)["Above500"]), se = unname(sqrt(diag(vcov(m)))["Above500"]),
       n = nobs(m), ncl = length(unique(d$cl)))
}

l300 <- run_level(300)
l150 <- run_level(150)
q300 <- run_iqr(300)
q150 <- run_iqr(150)

message(sprintf("Level bw300: b=%.2f se=%.2f n=%d cl=%d", l300$b, l300$se, l300$n, l300$ncl))
message(sprintf("Level bw150: b=%.2f se=%.2f n=%d cl=%d", l150$b, l150$se, l150$n, l150$ncl))
message(sprintf("IQR bw300: b=%.2f se=%.2f n=%d cl=%d", q300$b, q300$se, q300$n, q300$ncl))
message(sprintf("IQR bw150: b=%.2f se=%.2f n=%d cl=%d", q150$b, q150$se, q150$n, q150$ncl))

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", q300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", q150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(l300$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(l150$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(q300$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(q150$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(l300$ncl)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(l150$ncl)))