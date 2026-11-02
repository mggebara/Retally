# Arias & Blair (2022) "Changing Tides" -- Study 1 conjoint AMCEs (Table 2) and sample counts.
# Independent + blind reproduction.  Choice-based conjoint: 9 tasks x 2 profiles x 7 attributes.
# Outcome: 1 if the profile was chosen in the forced choice, 0 otherwise.
# AMCE estimated by OLS of the choice indicator on attribute-level dummies (baselines from Table 1),
# with the Language x Origin interaction implied by the design restriction (Language "None" never
# shown with Origin "Another region in your country"), as in the Hainmueller-Hopkins-Yamamoto estimator.
# Standard errors: cluster-robust by respondent.
set.seed(42)
suppressMessages({library(readr); library(dplyr); library(tidyr); library(sandwich); library(lmtest)})

D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-10-21-b/mount/arias_2022_changing_tides_climate_migration"
files <- c(us = "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv",
           de = "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

# choice variable for each of the 9 tasks (task 1 = force_choice; tasks 2..9 = Q184, Q186, ..., Q198)
choice_vars <- c("force_choice", paste0("Q", seq(184, 198, by = 2)))

# German -> English attribute names and levels
attr_map_de <- c("Gründe für die Migration" = "Reason for migration", "Sprachkompetenz" = "Language Fluency",
                 "Beruf" = "Occupation", "Geschlecht" = "Gender", "Religion" = "Religion",
                 "Herkunft" = "Origin", "Zusätzliche Belastung" = "Vulnerability")
lev_map_de <- c("Politische/religiöse/ethnische Verfolgung" = "Political/religious/ethnic persecution",
                "Überflutung" = "Flooding", "Dürre" = "Drought", "Wirtschaftliche Perspektive" = "Economic opportunity",
                "Waldbrände" = "Wildfires", "Fließend" = "Fluent", "Gebrochen" = "Broken", "Keine" = "None",
                "Reinigungskraft" = "Cleaner", "Lehrer" = "Teacher", "Arzt" = "Doctor", "Arbeitslos" = "Unemployed",
                "Männlich" = "Male", "Weiblich" = "Female", "Christian" = "Christian", "Muslim" = "Muslim",
                "Atheist" = "Atheist/Agnostic", "Aus einem anderen Teil Ihres Landes" = "Another region in your country",
                "Afghanistan" = "Afghanistan", "Äthiopien" = "Ethiopia", "Ukraine" = "Ukraine", "Myanmar" = "Myanmar",
                "PTBS (Posttraumatische Belastungsstörung)" = "Post Traumatic Stress Disorder (PTSD)",
                "Ernährungsunsicherheit" = "Food insecurity",
                "Keine überlebenden Familienmitglieder" = "No surviving family members",
                "Körperliche Behinderung" = "Physically handicapped")

baselines <- list(reason = "Economic opportunity", lang = "None", gender = "Female", occ = "Unemployed",
                  relig = "Atheist/Agnostic", origin = "Another region in your country", vuln = "None")
short <- c("Reason for migration" = "reason", "Language Fluency" = "lang", "Gender" = "gender",
           "Occupation" = "occ", "Religion" = "relig", "Origin" = "origin", "Vulnerability" = "vuln")

build_long <- function(f, country) {
  x <- read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE)
  x <- x[-(1:2), ]                                     # drop Qualtrics label + ImportId rows
  x <- x[x$DistributionChannel == "anonymous", ]       # drop survey previews
  rows <- list()
  for (k in 1:9) {
    for (p in 1:2) {
      d <- data.frame(resp = x$ResponseId, task = k, profile = p,
                      choice = suppressWarnings(as.integer(x[[choice_vars[k]]])), stringsAsFactors = FALSE)
      for (j in 1:7) {
        an <- x[[sprintf("F-%d-%d", k, j)]]
        lv <- x[[sprintf("F-%d-%d-%d", k, p, j)]]
        if (country == "de") { an <- unname(attr_map_de[an]); lv <- unname(lev_map_de[lv]) }
        if (country == "us" ) lv[lv == "Agnostic"] <- "Atheist/Agnostic"
        d[[paste0("a", j)]] <- an; d[[paste0("l", j)]] <- lv
      }
      rows[[length(rows) + 1]] <- d
    }
  }
  L <- bind_rows(rows)
  L$row <- seq_len(nrow(L))
  long_attr <- L %>% select(row, starts_with("a"), starts_with("l")) %>%
    pivot_longer(-row, names_to = c(".value", "j"), names_pattern = "([al])(\\d)") %>%
    mutate(var = short[a]) %>% select(row, var, l) %>%
    pivot_wider(names_from = var, values_from = l)
  L <- L %>% select(row, resp, task, profile, choice) %>% left_join(long_attr, by = "row")
  L <- L[!is.na(L$choice), ]                           # keep answered choice tasks only
  L$chosen <- as.integer(L$choice == L$profile)
  for (v in names(baselines)) {
    stopifnot(!any(is.na(L[[v]])))
    L[[v]] <- relevel(factor(L[[v]]), ref = baselines[[v]])
  }
  L
}

out <- list()
for (cc in c("us", "de")) {
  L <- build_long(files[[cc]], cc)
  cat("----", cc, "\n")
  cat("respondents:", length(unique(L$resp)), " profiles:", nrow(L), " choice pairs:", nrow(L) / 2, "\n")
  print(table(L$reason)); print(table(L$lang, L$origin))
  # Main spec: design-consistent AMCE with Language x Origin dependency interaction
  m <- lm(chosen ~ reason + lang * origin + gender + occ + relig + vuln, data = L)
  V <- vcovCL(m, cluster = ~resp, type = "HC1")
  ct <- coeftest(m, vcov. = V)
  print(round(ct[grep("^reason", rownames(ct)), ], 4))
  # Check: simple additive spec (no interaction)
  m2 <- lm(chosen ~ reason + lang + origin + gender + occ + relig + vuln, data = L)
  ct2 <- coeftest(m2, vcov. = vcovCL(m2, cluster = ~resp, type = "HC1"))
  cat("additive spec, reason rows:\n"); print(round(ct2[grep("^reason", rownames(ct2)), ], 4))
  out[[cc]] <- list(b = coef(m), n_resp = length(unique(L$resp)), n_prof = nrow(L))
}

nm <- c(us = "us", de = "germany")
for (cc in c("us", "de")) {
  b <- out[[cc]]$b
  cat(sprintf("RESULT:amce_drought_%s=%.6f\n", nm[cc], b["reasonDrought"]))
  cat(sprintf("RESULT:amce_flooding_%s=%.6f\n", nm[cc], b["reasonFlooding"]))
  cat(sprintf("RESULT:amce_wildfires_%s=%.6f\n", nm[cc], b["reasonWildfires"]))
  cat(sprintf("RESULT:amce_persecution_%s=%.6f\n", nm[cc], b["reasonPolitical/religious/ethnic persecution"]))
}
cat(sprintf("RESULT:respondents_us=%d\n", out$us$n_resp))
cat(sprintf("RESULT:respondents_germany=%d\n", out$de$n_resp))
cat(sprintf("RESULT:choice_tasks_us=%d\n", out$us$n_prof))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", out$de$n_prof))
