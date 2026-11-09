## Arias & co. (2022) "Changing Tides" -- independent reproduction of Table 2 reason-for-migration AMCEs
## Choice-based conjoint: OLS of forced choice (profile preferred = 1) on all seven attribute
## dummies (baselines per Table 1), all profiles, SEs clustered by respondent.
suppressMessages({library(tidyverse); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-11-07-a/mount/arias_2022_changing_tides_climate_migration"
files <- c(us = "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv",
           germany = "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
choice_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")

## German -> English attribute / level map
attr_map <- c("Beruf"="Occupation","Geschlecht"="Gender","Gründe für die Migration"="Reason for migration",
              "Herkunft"="Origin","Religion"="Religion","Sprachkompetenz"="Language Fluency",
              "Zusätzliche Belastung"="Vulnerability")
lev_map <- c("Politische/religiöse/ethnische Verfolgung"="Political/religious/ethnic persecution",
             "Überflutung"="Flooding","Dürre"="Drought","Wirtschaftliche Perspektive"="Economic opportunity",
             "Waldbrände"="Wildfires","Fließend"="Fluent","Gebrochen"="Broken","Keine"="None",
             "Reinigungskraft"="Cleaner","Lehrer"="Teacher","Arzt"="Doctor","Arbeitslos"="Unemployed",
             "Männlich"="Male","Weiblich"="Female","Atheist"="Agnostic",
             "Aus einem anderen Teil Ihres Landes"="Another region in your country",
             "Äthiopien"="Ethiopia","PTBS (Posttraumatische Belastungsstörung)"="Post Traumatic Stress Disorder (PTSD)",
             "Ernährungsunsicherheit"="Food insecurity",
             "Keine überlebenden Familienmitglieder"="No surviving family members",
             "Körperliche Behinderung"="Physically handicapped")
recode <- function(x, m) ifelse(x %in% names(m), m[x], x)

build_long <- function(f) {
  d <- read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE)[-(1:2), ]
  d$rid <- d$ResponseId
  out <- list()
  for (t in 1:9) {
    ch <- d[[choice_cols[t]]]
    for (j in 1:2) {
      prof <- tibble(rid = d$rid, task = t, profile = j, choice = ch)
      for (k in 1:7) {
        a <- recode(trimws(d[[sprintf("F-%d-%d", t, k)]]), attr_map)
        v <- recode(trimws(d[[sprintf("F-%d-%d-%d", t, j, k)]]), lev_map)
        prof[[paste0("a", k)]] <- a; prof[[paste0("v", k)]] <- v
      }
      out[[length(out) + 1]] <- prof
    }
  }
  long <- bind_rows(out) %>% filter(!is.na(choice), choice %in% c("1", "2"))
  ## map randomized attribute positions to named columns
  attrs <- c("Reason for migration","Language Fluency","Occupation","Gender","Religion","Origin","Vulnerability")
  for (a in attrs) {
    val <- rep(NA_character_, nrow(long))
    for (k in 1:7) { hit <- long[[paste0("a", k)]] == a; val[hit %in% TRUE] <- long[[paste0("v", k)]][hit %in% TRUE] }
    long[[make.names(a)]] <- val
  }
  long %>% mutate(chosen = as.integer(choice == as.character(profile))) %>%
    select(rid, task, profile, chosen, all_of(make.names(attrs)))
}

baselines <- c(Reason.for.migration = "Economic opportunity", Language.Fluency = "None",
               Occupation = "Unemployed", Gender = "Female", Religion = "Agnostic",
               Origin = "Another region in your country", Vulnerability = "None")
res <- list()
for (s in names(files)) {
  L <- build_long(files[[s]])
  for (v in names(baselines)) L[[v]] <- relevel(factor(L[[v]]), ref = baselines[[v]])
  cat(sprintf("[%s] profiles=%d respondents=%d missing-attr rows=%d\n", s, nrow(L),
              n_distinct(L$rid), sum(!complete.cases(L))))
  m <- feols(chosen ~ Reason.for.migration + Language.Fluency + Occupation + Gender + Religion +
               Origin + Vulnerability, data = L, cluster = ~rid)
  print(coeftable(m))
  cf <- coef(m)
  res[[s]] <- list(
    drought = cf[["Reason.for.migrationDrought"]], flooding = cf[["Reason.for.migrationFlooding"]],
    wildfires = cf[["Reason.for.migrationWildfires"]],
    persecution = cf[["Reason.for.migrationPolitical/religious/ethnic persecution"]],
    n_resp = n_distinct(L$rid), n_obs = nobs(m))
}
for (s in names(files)) {
  r <- res[[s]]
  cat(sprintf("RESULT:amce_drought_%s=%.4f\n", s, r$drought))
  cat(sprintf("RESULT:amce_flooding_%s=%.4f\n", s, r$flooding))
  cat(sprintf("RESULT:amce_wildfires_%s=%.4f\n", s, r$wildfires))
  cat(sprintf("RESULT:amce_persecution_%s=%.4f\n", s, r$persecution))
}
for (s in names(files)) {
  cat(sprintf("RESULT:respondents_%s=%d\n", s, res[[s]]$n_resp))
  cat(sprintf("RESULT:choice_tasks_%s=%d\n", s, res[[s]]$n_obs))
}
