suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- haven::read_dta(path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)
nm <- names(df)
cat("Columns:\n"); print(nm)

pick <- function(cands, regex = NULL, exclude = NULL) {
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  if (!is.null(regex)) {
    hit <- nm[grepl(regex, nm, ignore.case = TRUE)]
    if (!is.null(exclude)) hit <- hit[!grepl(exclude, hit, ignore.case = TRUE)]
    hit <- hit[sapply(hit, function(h) is.numeric(df[[h]]))]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

# ---- Running variable (former owner's landholdings, centred at 500) ----
# NOTE: norm_dist_Above is the interaction norm_dist * Above500 (zero below the
# cutoff), so it is NOT the running variable. Use norm_dist itself.
run_var <- pick(c("norm_dist", "dist_500", "Dist_Above"), "norm_dist|dist", exclude = "above|perc")
cat("Running variable:", run_var, "\n")
x <- as.numeric(df[[run_var]])
print(summary(x))

# ---- Treatment ----
has_above <- "Above500" %in% nm
if (has_above) {
  above_raw <- as.numeric(df$Above500)
  # if running variable is not centred (all non-negative), check whether centring at 500 fits
  agree0 <- mean(above_raw == as.numeric(x >= 0), na.rm = TRUE)
  agree500 <- mean(above_raw == as.numeric(x >= 500), na.rm = TRUE)
  cat("Agreement Above500 vs x>=0:", agree0, " vs x>=500:", agree500, "\n")
  if (is.finite(agree500) && agree500 > agree0 + 0.05) {
    cat("Running variable appears uncentred; subtracting 500\n")
    x <- x - 500
  }
}
# if apparently normalised to units of 100 ha rather than ha, rescale
qx <- quantile(abs(x), 0.9, na.rm = TRUE)
if (is.finite(qx) && qx > 0 && qx < 5) {
  cat("Running variable looks rescaled; multiplying by 100 to ha\n")
  x <- x * 100
}
df$xrun <- x
print(summary(df$xrun))

if (has_above) {
  df$above <- as.numeric(df$Above500)
} else {
  df$above <- as.numeric(df$xrun >= 0)
}
print(table(df$above, useNA = "ifany"))
print(with(df, table(above, xrun >= 0, useNA = "ifany")))

# ---- Outcome: household earnings per capita ----
y_var <- pick(c("ingpe", "ingpc", "ing_pc", "hh_income_pc", "income_pc", "Income_pc",
                "earnings_pc", "Earnings_pc", "hh_earnings_pc", "HH_Income_pc",
                "Household_Income_pc", "ingreso_pc", "income_per_capita", "earnings_per_capita"),
              "ingpe|percap|per_cap|_pc$|earn|ingpc",
              exclude = "land|iqr")
if (is.na(y_var)) y_var <- pick(c("income", "Income", "ingfa", "earnings"), "income|ingre", exclude = "land|other")
cat("Outcome variable:", y_var, "\n")
df$y <- as.numeric(df[[y_var]])
print(summary(df$y))

# ---- Cluster: former owner ----
cl_var <- pick(c("Expropretario_ISTA", "owner_id", "Owner_id", "expropietario", "Expropietario",
                 "former_owner", "Former_Owner", "owner"), "expro|owner|propiet", exclude = "land_owner")
cat("Cluster variable:", cl_var, "\n")
df$cl <- as.character(df[[cl_var]])
df$cl[is.na(df$cl) | df$cl == ""] <- NA

# ---- Property id ----
if ("match_id" %in% nm) {
  df$prop <- as.character(df$match_id)
} else {
  rc <- if ("Reform_Coop_id" %in% nm) as.character(df$Reform_Coop_id) else NA
  hc <- if ("Hacienda_id" %in% nm) as.character(df$Hacienda_id) else NA
  df$prop <- ifelse(!is.na(rc) & rc != "", paste0("c", rc), paste0("h", hc))
}
df$prop[is.na(df$prop) | df$prop == "" | df$prop == "NA"] <- NA

# ---- Survey year (use whichever candidate has fewest missing values) ----
yr_cands <- intersect(c("survey_year", "year", "anio"), nm)
if (length(yr_cands) > 0) {
  nmiss <- sapply(yr_cands, function(v) sum(is.na(df[[v]])))
  yr_var <- yr_cands[which.min(nmiss)]
} else {
  yr_var <- pick(character(0), "year")
}
cat("Year variable:", yr_var, "\n")
df$yr <- as.factor(df[[yr_var]])

base <- df %>% filter(!is.na(y), !is.na(xrun), !is.na(above), !is.na(cl))
cat("Base N:", nrow(base), "\n")

run_level <- function(bw) {
  d <- base %>% filter(abs(xrun) <= bw)
  m <- feols(y ~ above + xrun + above:xrun | yr, data = d, cluster = ~cl)
  print(summary(m))
  list(b = unname(coef(m)["above"]), n = nobs(m),
       ncl = length(unique(d$cl[obs(m)])), m = m)
}

run_iqr <- function(bw) {
  d <- base %>% filter(abs(xrun) <= bw, !is.na(prop)) %>%
    group_by(prop) %>%
    summarise(n_w = n(),
              iqr = as.numeric(quantile(y, 0.75, na.rm = TRUE) - quantile(y, 0.25, na.rm = TRUE)),
              xrun = first(xrun), above = first(above), cl = first(cl),
              yr = names(sort(table(as.character(yr)), decreasing = TRUE))[1],
              .groups = "drop") %>%
    filter(n_w >= 5)
  m <- tryCatch(feols(iqr ~ above + xrun + above:xrun | yr, data = d, cluster = ~cl),
                error = function(e) feols(iqr ~ above + xrun + above:xrun, data = d, cluster = ~cl))
  print(summary(m))
  list(b = unname(coef(m)["above"]), n = nobs(m), ncl = length(unique(d$cl)))
}

l300 <- run_level(300)
l150 <- run_level(150)
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
