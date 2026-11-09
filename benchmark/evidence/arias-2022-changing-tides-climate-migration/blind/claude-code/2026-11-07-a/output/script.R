# Arias & co. (2022) "Changing Tides" -- Study 1 conjoint, independent blind reproduction
# Full-model AMCEs (all seven attributes, all profiles), OLS on forced-choice outcome,
# robust SEs clustered by respondent (Hainmueller, Hopkins & Yamamoto 2014 estimator).
suppressMessages({library(tidyverse); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-11-07-a/mount/arias_2022_changing_tides_climate_migration"

attr_map <- c(
  "Reason for migration"="reason", "Language Fluency"="language", "Occupation"="occupation",
  "Gender"="gender", "Religion"="religion", "Origin"="origin", "Vulnerability"="vulnerability",
  "Gründe für die Migration"="reason", "Sprachkompetenz"="language", "Beruf"="occupation",
  "Geschlecht"="gender", "Herkunft"="origin", "Zusätzliche Belastung"="vulnerability")

# forced-choice column for task 1..9
choice_cols <- c("force_choice", "Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")

build_long <- function(file) {
  x <- read_csv(file.path(D, file), col_types = cols(.default = "c"), show_col_types = FALSE)
  x <- x[-(1:2), ]                                   # drop Qualtrics label / ImportId rows
  x <- x[x$DistributionChannel != "preview" & x$Status == "0", ]   # drop survey previews
  out <- list()
  for (k in 1:9) for (p in 1:2) {
    d <- tibble(resp = x$ResponseId, task = k, profile = p,
                choice = x[[choice_cols[k]]])
    for (j in 1:7) {
      an <- x[[sprintf("F-%d-%d", k, j)]]
      lv <- x[[sprintf("F-%d-%d-%d", k, p, j)]]
      for (a in unique(an)) {
        v <- attr_map[[a]]
        if (is.null(d[[v]])) d[[v]] <- NA_character_
        d[[v]][an == a] <- lv[an == a]
      }
    }
    out[[length(out) + 1]] <- d
  }
  long <- bind_rows(out)
  long$chosen <- as.integer(long$choice == as.character(long$profile))
  long
}

recode_de <- function(d) {
  d %>% mutate(
    reason = case_when(grepl("Wirtschaft", reason) ~ "Economic opportunity",
                       grepl("Dürre", reason) ~ "Drought",
                       grepl("berflutung", reason) ~ "Flooding",
                       grepl("Waldbr", reason) ~ "Wildfires",
                       grepl("Verfolgung", reason) ~ "Political/religious/ethnic persecution"),
    language = recode(language, "Fließend"="Fluent", "Gebrochen"="Broken", "Keine"="None"),
    occupation = recode(occupation, "Reinigungskraft"="Cleaner", "Lehrer"="Teacher", "Arzt"="Doctor", "Arbeitslos"="Unemployed"),
    gender = recode(gender, "Männlich"="Male", "Weiblich"="Female"),
    origin = ifelse(grepl("anderen Teil", origin), "Another region in your country", origin),
    vulnerability = ifelse(vulnerability == "Keine", "None", vulnerability))
}

set_baselines <- function(d) {
  d %>% mutate(
    reason = relevel(factor(reason), "Economic opportunity"),
    language = relevel(factor(language), "None"),
    occupation = relevel(factor(occupation), "Unemployed"),
    gender = relevel(factor(gender), "Female"),
    religion = relevel(factor(religion), "Christian"),
    origin = relevel(factor(origin), "Another region in your country"),
    vulnerability = relevel(factor(vulnerability), "None"))
}

run <- function(file, de = FALSE, tag) {
  long <- build_long(file)
  if (de) long <- recode_de(long)
  est <- long %>% filter(!is.na(chosen)) %>% set_baselines()
  stopifnot(!anyNA(est$reason))
  cat("\n==", tag, "==\n")
  cat("rows with outcome:", nrow(est), " respondents:", n_distinct(est$resp), "\n")
  cat("tasks per pair check (each pair one chosen):", mean(tapply(est$chosen, paste(est$resp, est$task), sum) == 1), "\n")
  print(table(est$language == "None", est$origin == "Another region in your country", dnn = c("lang None", "origin internal")))
  m <- feols(chosen ~ reason + language + gender + occupation + religion + origin + vulnerability,
             data = est, cluster = ~resp)
  print(coeftable(m))
  list(m = m, n = nrow(est), r = n_distinct(est$resp))
}

us <- run("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", FALSE, "US")
de <- run("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", TRUE, "Germany")

cf <- function(r, lvl) unname(coef(r$m)[paste0("reason", lvl)])
P <- "Political/religious/ethnic persecution"
cat(sprintf("RESULT:amce_drought_us=%.6f\n", cf(us, "Drought")))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n", cf(us, "Flooding")))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n", cf(us, "Wildfires")))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", cf(us, P)))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n", cf(de, "Drought")))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n", cf(de, "Flooding")))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n", cf(de, "Wildfires")))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", cf(de, P)))
cat(sprintf("RESULT:respondents_us=%d\n", us$r))
cat(sprintf("RESULT:respondents_germany=%d\n", de$r))
cat(sprintf("RESULT:choice_tasks_us=%d\n", us$n))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", de$n))
