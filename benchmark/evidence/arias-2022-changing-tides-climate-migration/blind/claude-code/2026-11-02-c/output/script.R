# Arias & Blair (2022) "Changing Tides" -- independent, blind reproduction of Table 2
# (reason-for-migration AMCEs, U.S. and German samples) and the Study 1 sample counts.
# AMCE: OLS (linear probability model) of profile chosen (forced choice) on dummies for
# all seven attributes, all profile pairs, baseline levels as in Table 1, SEs clustered by respondent.
set.seed(42)
suppressMessages({library(tidyverse); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-11-02-c/mount/arias_2022_changing_tides_climate_migration"

# choice question per task (1..9): task 1 = force_choice, tasks 2..9 = Q184..Q198 (by 2)
choice_cols <- c("force_choice", paste0("Q", seq(184, 198, by = 2)))

# German -> English level/attribute translation (order from conjoint_design*.dat files)
de_attr <- c("Gründe für die Migration" = "Reason for migration", "Sprachkompetenz" = "Language Fluency",
             "Beruf" = "Occupation", "Geschlecht" = "Gender", "Religion" = "Religion",
             "Herkunft" = "Origin", "Zusätzliche Belastung" = "Vulnerability")
read_design <- function(f) {
  l <- readLines(file.path(D, f), encoding = "UTF-8", warn = FALSE)
  i0 <- which(l == "Attributes") + 1; i1 <- which(l == "Weights") - 1
  x <- strsplit(l[i0:i1], ":", fixed = TRUE)
  setNames(lapply(x, function(z) strsplit(z[2], ",", fixed = TRUE)[[1]]), sapply(x, `[`, 1))
}
en_des <- read_design("conjoint_design.dat")
de_des <- read_design("conjoint_design_german2.dat")
de_map <- unlist(lapply(names(en_des), function(a) setNames(en_des[[a]], de_des[[a]])))
de_map["Atheist"] <- "Agnostic"  # atheist replaces agnostic in Germany (same baseline category)

build <- function(file, german = FALSE) {
  d <- read_csv(file.path(D, file), col_types = cols(.default = "c"))
  d <- d[-(1:2), ]                                   # Qualtrics label / ImportId rows
  n_raw <- nrow(d)
  d <- d %>% filter(DistributionChannel != "preview", Status == "0")  # drop survey previews
  rows <- list()
  for (k in 1:9) {
    attr_names <- sapply(1:7, function(j) d[[sprintf("F-%d-%d", k, j)]])
    for (p in 1:2) {
      lev <- sapply(1:7, function(j) d[[sprintf("F-%d-%d-%d", k, p, j)]])
      df <- tibble(resp = d$ResponseId, task = k, profile = p,
                   choice = suppressWarnings(as.integer(d[[choice_cols[k]]])))
      for (j in 1:7) {
        an <- attr_names[, j]; if (german) an <- unname(de_attr[an])
        lv <- lev[, j];        if (german) lv <- unname(de_map[lv])
        df[[paste0("a", j, "_name")]] <- an; df[[paste0("a", j, "_lev")]] <- lv
      }
      rows[[length(rows) + 1]] <- df
    }
  }
  long <- bind_rows(rows)
  # reshape attribute positions (randomized order) into named attribute columns
  out <- long %>% select(resp, task, profile, choice)
  for (a in names(en_des)) {
    v <- rep(NA_character_, nrow(long))
    for (j in 1:7) { m <- long[[paste0("a", j, "_name")]] == a; v[m] <- long[[paste0("a", j, "_lev")]][m] }
    out[[a]] <- v
  }
  out <- out %>% filter(!is.na(choice)) %>% mutate(chosen = as.integer(choice == profile))
  stopifnot(!anyNA(out[, names(en_des)]))
  cat(sprintf("%s: raw rows %d, non-preview %d, profiles %d, respondents %d\n",
              file, n_raw, nrow(d), nrow(out), n_distinct(out$resp)))
  out
}

prep <- function(x) {
  x %>% mutate(
    reason = relevel(factor(`Reason for migration`), "Economic opportunity"),
    lang   = relevel(factor(`Language Fluency`), "None"),
    gender = relevel(factor(Gender), "Female"),
    occ    = relevel(factor(Occupation), "Unemployed"),
    relig  = relevel(factor(Religion), "Agnostic"),
    origin = relevel(factor(Origin), "Another region in your country"),
    vuln   = relevel(factor(Vulnerability), "None"))
}

us <- prep(build("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv"))
de <- prep(build("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", german = TRUE))

fml <- chosen ~ reason + lang + gender + occ + relig + origin + vuln
m_us <- feols(fml, data = us, cluster = ~resp)
m_de <- feols(fml, data = de, cluster = ~resp)
print(summary(m_us)); print(summary(m_de))

g <- function(m, lv) unname(coef(m)[paste0("reason", lv)])
cat(sprintf("RESULT:amce_drought_us=%.6f\n",       g(m_us, "Drought")))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n",      g(m_us, "Flooding")))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n",     g(m_us, "Wildfires")))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n",   g(m_us, "Political/religious/ethnic persecution")))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n",     g(m_de, "Drought")))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n",    g(m_de, "Flooding")))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n",   g(m_de, "Wildfires")))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", g(m_de, "Political/religious/ethnic persecution")))
cat(sprintf("RESULT:respondents_us=%d\n", n_distinct(us$resp)))
cat(sprintf("RESULT:respondents_germany=%d\n", n_distinct(de$resp)))
cat(sprintf("RESULT:choice_tasks_us=%d\n", nobs(m_us)))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", nobs(m_de)))
