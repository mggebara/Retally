suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
raw <- haven::read_dta(path)
df <- as.data.frame(haven::zap_labels(haven::zap_formats(raw)))
nms <- names(df)

num <- function(x) suppressWarnings(as.numeric(x))

# ---------- treatment and running variable ----------
df$Above500 <- num(df$Above500)
df$run <- num(df$own_amt) - 500
df$Above500 <- ifelse(is.na(df$Above500), as.numeric(df$run >= 0), df$Above500)

# ---------- outcome: household earnings per capita ----------
df$y <- num(df$hh_income_pc)
fill_y <- is.na(df$y) & !is.na(num(df$hh_income)) & !is.na(num(df$num_members)) & num(df$num_members) > 0
df$y[fill_y] <- num(df$hh_income)[fill_y] / num(df$num_members)[fill_y]
cat("Outcome NA count:", sum(is.na(df$y)), " filled:", sum(fill_y), "\n")
if (sum(fill_y) > 0) cat("DEVIATION: Filled missing hh_income_pc with hh_income/num_members\n")

# ---------- survey year (fall back to year when survey_year missing) ----------
df$survey_year <- num(df$survey_year)
yr_alt <- num(df$year)
n_fill_yr <- sum(is.na(df$survey_year) & !is.na(yr_alt))
df$survey_year <- ifelse(is.na(df$survey_year), yr_alt, df$survey_year)
cat("survey_year filled from year:", n_fill_yr, "\n")

# ---------- cluster: former owner ----------
df$cl <- as.character(df$Expropretario_ISTA)
df$cl[df$cl == "" | df$cl == "NA"] <- NA
miss_cl <- is.na(df$cl)
df$cl[miss_cl] <- paste0("amt_", round(df$run[miss_cl], 3))

# ---------- property id ----------
pid <- rep(NA_character_, nrow(df))
if ("match_id" %in% nms) { v <- as.character(df$match_id); v[v == ""] <- NA; pid <- v }
if ("Reform_Coop_id" %in% nms) {
  v <- as.character(df$Reform_Coop_id); v[v == "" | v == "0"] <- NA
  pid <- ifelse(is.na(pid) & !is.na(v), paste0("C", v), pid)
}
if ("Hacienda_id" %in% nms) {
  v <- as.character(df$Hacienda_id); v[v == "" | v == "0"] <- NA
  pid <- ifelse(is.na(pid) & !is.na(v), paste0("H", v), pid)
}
pid[is.na(pid)] <- paste0("O", df$cl[is.na(pid)])
df$pid <- pid

base <- df %>% filter(!is.na(y), !is.na(run), !is.na(Above500))
cat("Base N:", nrow(base), " with survey_year:", sum(!is.na(base$survey_year)), "\n")

run_level <- function(bw) {
  d <- base %>% filter(abs(run) <= bw)
  if (any(is.na(d$survey_year))) {
    m <- feols(y ~ Above500 + run + run:Above500, data = d, cluster = ~cl)
  } else {
    m <- feols(y ~ Above500 + run + run:Above500 | survey_year, data = d, cluster = ~cl)
  }
  print(summary(m))
  list(b = unname(coef(m)["Above500"]), n = nobs(m), ncl = length(unique(d$cl[obs(m)])))
}

# IQR of household earnings per capita computed within property x survey year
run_iqr <- function(bw) {
  d <- base %>% filter(abs(run) <= bw, !is.na(survey_year)) %>%
    group_by(pid, survey_year) %>%
    summarise(n = n(),
              iqr = as.numeric(quantile(y, 0.75) - quantile(y, 0.25)),
              Above500 = first(Above500), run = first(run), cl = first(cl),
              .groups = "drop") %>%
    filter(n >= 2)
  m <- tryCatch(feols(iqr ~ Above500 + run + run:Above500 | survey_year, data = d, cluster = ~cl),
                error = function(e) feols(iqr ~ Above500 + run + run:Above500, data = d, cluster = ~cl))
  print(summary(m))
  list(b = unname(coef(m)["Above500"]), n = nobs(m), ncl = length(unique(d$cl)))
}
cat("DEVIATION: IQR computed at the property x survey-year level (min 2 workers) since the paper's IQR unit (327 properties at bw300) exceeds the number of distinct properties\n")

safe <- function(f, ...) tryCatch(f(...), error = function(e) { message(e$message); list(b = NA, n = NA, ncl = NA) })

l300 <- safe(run_level, 300)
l150 <- safe(run_level, 150)
i300 <- safe(run_iqr, 300)
i150 <- safe(run_iqr, 150)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", i300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", i150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%s\n", l300$n))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%s\n", l150$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%s\n", i300$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%s\n", i150$n))
cat(sprintf("RESULT:n_clusters_bw300=%s\n", l300$ncl))
cat(sprintf("RESULT:n_clusters_bw150=%s\n", l150$ncl))