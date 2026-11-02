# Arias & Blair (2022) "Changing Tides" -- Study 1 conjoint, Table 2 AMCEs (full model)
# AMCE estimated by OLS of the forced-choice indicator (profile preferred) on dummies for
# all seven attributes (baselines from Table 1), on all profile pairs, with robust SEs
# clustered by respondent (Hainmueller, Hopkins & Yamamoto 2014).
set.seed(42)
suppressMessages({library(tidyverse); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-10-22-a/mount/arias_2022_changing_tides_climate_migration"

# choice question per task: task 1 = force_choice, tasks 2..9 = Q184,Q186,...,Q198
choice_cols <- c("force_choice", paste0("Q", seq(184, 198, by = 2)))

attr_map <- c(
  "Reason for migration" = "reason", "Gründe für die Migration" = "reason",
  "Language Fluency" = "language", "Sprachkompetenz" = "language",
  "Gender" = "gender", "Geschlecht" = "gender",
  "Occupation" = "occupation", "Beruf" = "occupation",
  "Religion" = "religion",
  "Origin" = "origin", "Herkunft" = "origin",
  "Vulnerability" = "vulnerability", "Zusätzliche Belastung" = "vulnerability")

level_map <- c(
  # reason
  "Politische/religiöse/ethnische Verfolgung" = "Political/religious/ethnic persecution",
  "Überflutung" = "Flooding", "Dürre" = "Drought",
  "Wirtschaftliche Perspektive" = "Economic opportunity", "Waldbrände" = "Wildfires",
  # language
  "Fließend" = "Fluent", "Gebrochen" = "Broken",
  # "Keine" = none, used for both language fluency and vulnerability
  "Keine" = "None",
  # occupation
  "Reinigungskraft" = "Cleaner", "Lehrer" = "Teacher", "Arzt" = "Doctor", "Arbeitslos" = "Unemployed",
  # gender
  "Männlich" = "Male", "Weiblich" = "Female",
  # religion (agnostic in US, atheist in Germany -> same baseline)
  "Agnostic" = "Atheist/Agnostic", "Atheist" = "Atheist/Agnostic",
  # origin
  "Aus einem anderen Teil Ihres Landes" = "Another region in your country", "Äthiopien" = "Ethiopia",
  # vulnerability
  "PTBS (Posttraumatische Belastungsstörung)" = "Post Traumatic Stress Disorder (PTSD)",
  "Ernährungsunsicherheit" = "Food insecurity",
  "Keine überlebenden Familienmitglieder" = "No surviving family members",
  "Körperliche Behinderung" = "Physically handicapped")

baselines <- list(reason = "Economic opportunity", language = "None", gender = "Female",
                  occupation = "Unemployed", religion = "Atheist/Agnostic",
                  origin = "Another region in your country", vulnerability = "None")

build_long <- function(fn, country) {
  raw <- read_csv(file.path(D, fn), col_types = cols(.default = "c"), show_col_types = FALSE)
  d <- raw[-(1:2), ]   # drop Qualtrics label and ImportId rows
  rows <- vector("list", 9 * 2 * 7)
  k <- 0
  out <- list()
  for (t in 1:9) {
    for (p in 1:2) {
      prof <- tibble(resp = d$ResponseId, task = t, profile = p,
                     choice = suppressWarnings(as.integer(d[[choice_cols[t]]])))
      for (a in 1:7) {
        aname <- d[[sprintf("F-%d-%d", t, a)]]
        lev <- d[[sprintf("F-%d-%d-%d", t, p, a)]]
        prof[[paste0("an", a)]] <- unname(attr_map[aname])
        prof[[paste0("lv", a)]] <- lev
      }
      out[[length(out) + 1]] <- prof
    }
  }
  L <- bind_rows(out)
  # reshape attribute slots into named columns (attribute order randomized per respondent)
  long <- L |>
    pivot_longer(matches("^(an|lv)\\d$"), names_to = c(".value", "slot"), names_pattern = "(an|lv)(\\d)") |>
    mutate(lv = ifelse(lv %in% names(level_map), level_map[lv], lv)) |>
    select(-slot) |>
    pivot_wider(names_from = an, values_from = lv)
  stopifnot(nrow(long) == nrow(L))
  long <- long |>
    mutate(chosen = as.integer(choice == profile), country = country)
  long
}

us <- build_long("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", "US")
de <- build_long("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", "DE")

res <- list()
for (cn in c("us", "germany")) {
  dat <- if (cn == "us") us else de
  dat <- dat |> filter(!is.na(chosen))
  for (a in names(baselines)) {
    dat[[a]] <- relevel(factor(dat[[a]]), ref = baselines[[a]])
  }
  cat("\n=====", cn, "=====\n")
  for (a in names(baselines)) { cat(a, ":\n"); print(table(dat[[a]], useNA = "ifany")) }
  cat("restricted combo (language None & internal origin):",
      sum(dat$language == "None" & dat$origin == "Another region in your country"), "\n")
  m <- feols(chosen ~ reason + language + gender + occupation + religion + origin + vulnerability,
             data = dat, cluster = ~resp)
  print(coeftable(m))
  n_resp <- n_distinct(dat$resp)
  n_obs <- nobs(m)
  cat("respondents:", n_resp, " profiles (obs):", n_obs, " choice pairs:", n_obs / 2, "\n")
  cf <- coef(m)
  res[[paste0("amce_drought_", cn)]] <- cf[["reasonDrought"]]
  res[[paste0("amce_flooding_", cn)]] <- cf[["reasonFlooding"]]
  res[[paste0("amce_wildfires_", cn)]] <- cf[["reasonWildfires"]]
  res[[paste0("amce_persecution_", cn)]] <- cf[["reasonPolitical/religious/ethnic persecution"]]
  res[[paste0("respondents_", cn)]] <- n_resp
  res[[paste0("choice_tasks_", cn)]] <- n_obs
}

ord <- c("amce_drought_us", "amce_flooding_us", "amce_wildfires_us", "amce_persecution_us",
         "amce_drought_germany", "amce_flooding_germany", "amce_wildfires_germany", "amce_persecution_germany",
         "respondents_us", "respondents_germany", "choice_tasks_us", "choice_tasks_germany")
cat("\n")
for (nm in ord) cat(sprintf("RESULT:%s=%s\n", nm, format(res[[nm]], digits = 10)))
