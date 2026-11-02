## Arias & ... (2022) "Changing Tides" -- Table 2 AMCEs for Reason for Migration
## Independent reproduction: choice-based conjoint, OLS of "profile chosen" on all seven
## attribute factors (baseline levels from Table 1), with the Language x Origin interaction
## implied by the design restriction (no "None" fluency for "Another region in your country"),
## robust SEs clustered by respondent (Hainmueller, Hopkins & Yamamoto 2014 estimator).
set.seed(42)
suppressMessages({library(readr); library(dplyr); library(tidyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-11-01-a/mount/arias_2022_changing_tides_climate_migration"
chv <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")  # tasks 1..9

## German -> English level / attribute map
de_attr <- c("Gründe für die Migration"="Reason","Sprachkompetenz"="Language","Geschlecht"="Gender",
             "Beruf"="Occupation","Religion"="Religion","Herkunft"="Origin","Zusätzliche Belastung"="Vulnerability")
en_attr <- c("Reason for migration"="Reason","Language Fluency"="Language","Gender"="Gender",
             "Occupation"="Occupation","Religion"="Religion","Origin"="Origin","Vulnerability"="Vulnerability")
de_lev <- c("Wirtschaftliche Perspektive"="Economic opportunity","Dürre"="Drought","Überflutung"="Flooding",
            "Waldbrände"="Wildfires","Politische/religiöse/ethnische Verfolgung"="Political/religious/ethnic persecution",
            "Fließend"="Fluent","Gebrochen"="Broken","Keine"="None","Männlich"="Male","Weiblich"="Female",
            "Arbeitslos"="Unemployed","Reinigungskraft"="Cleaner","Lehrer"="Teacher","Arzt"="Doctor",
            "Atheist"="Atheist/Agnostic","Christian"="Christian","Muslim"="Muslim",
            "Aus einem anderen Teil Ihres Landes"="Another region in your country","Afghanistan"="Afghanistan",
            "Äthiopien"="Ethiopia","Myanmar"="Myanmar","Ukraine"="Ukraine",
            "PTBS (Posttraumatische Belastungsstörung)"="Post Traumatic Stress Disorder (PTSD)",
            "Ernährungsunsicherheit"="Food insecurity","Keine überlebenden Familienmitglieder"="No surviving family members",
            "Körperliche Behinderung"="Physically handicapped")
baselines <- list(Reason="Economic opportunity", Language="None", Gender="Female", Occupation="Unemployed",
                  Religion="Atheist/Agnostic", Origin="Another region in your country", Vulnerability="None")

build <- function(file, german) {
  y <- suppressWarnings(read_csv(file.path(D, file), col_types = cols(.default = "c")))[-(1:2), ]
  y$rid <- seq_len(nrow(y))
  rows <- list()
  for (k in 1:9) {
    ch <- y[[chv[k]]]
    for (j in 1:2) {
      df <- data.frame(rid = y$rid, task = k, profile = j, choice = ch, stringsAsFactors = FALSE)
      for (a in 1:7) {
        an <- y[[sprintf("F-%d-%d", k, a)]]
        an <- if (german) de_attr[an] else en_attr[an]
        lv <- y[[sprintf("F-%d-%d-%d", k, j, a)]]
        if (german) lv <- de_lev[lv] else lv[lv == "Agnostic"] <- "Atheist/Agnostic"
        df[[paste0("an", a)]] <- unname(an); df[[paste0("lv", a)]] <- unname(lv)
      }
      rows[[length(rows) + 1]] <- df
    }
  }
  long <- bind_rows(rows)
  out <- long[, c("rid", "task", "profile", "choice")]
  for (att in names(baselines)) {
    v <- rep(NA_character_, nrow(long))
    for (a in 1:7) { m <- long[[paste0("an", a)]] == att; v[m] <- long[[paste0("lv", a)]][m] }
    out[[att]] <- v
  }
  out <- out[!is.na(out$choice), ]
  out$chosen <- as.integer(out$choice == as.character(out$profile))
  for (att in names(baselines)) out[[att]] <- relevel(factor(out[[att]]), ref = baselines[[att]])
  out
}

est <- function(d, tag) {
  stopifnot(!anyNA(d[, names(baselines)]))
  cat(sprintf("[%s] respondents=%d profiles=%d pairs=%d\n", tag, length(unique(d$rid)), nrow(d), nrow(d) / 2))
  cat(sprintf("[%s] None-fluency x Another-region profiles: %d\n", tag,
              sum(d$Language == "None" & d$Origin == "Another region in your country")))
  m <- feols(chosen ~ Reason + Language + Gender + Occupation + Religion + Origin + Vulnerability +
               Language:Origin, data = d, cluster = ~rid)
  m0 <- feols(chosen ~ Reason + Language + Gender + Occupation + Religion + Origin + Vulnerability,
              data = d, cluster = ~rid)
  ct <- coeftable(m); ct0 <- coeftable(m0)
  r <- grep("^Reason", rownames(ct), value = TRUE)
  cat(sprintf("[%s] interaction model (reported):\n", tag)); print(round(ct[r, 1:2], 4))
  cat(sprintf("[%s] additive model (check):\n", tag)); print(round(ct0[r, 1:2], 4))
  list(b = ct[, 1], n_resp = length(unique(d$rid)), n_prof = nrow(d))
}

us <- build("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", FALSE)
de <- build("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", TRUE)
U <- est(us, "US"); G <- est(de, "DE")

nm <- c(drought = "ReasonDrought", flooding = "ReasonFlooding", wildfires = "ReasonWildfires",
        persecution = "ReasonPolitical/religious/ethnic persecution")
for (s in names(nm)) cat(sprintf("RESULT:amce_%s_us=%.6f\n", s, U$b[nm[s]]))
for (s in names(nm)) cat(sprintf("RESULT:amce_%s_germany=%.6f\n", s, G$b[nm[s]]))
cat(sprintf("RESULT:respondents_us=%d\n", U$n_resp))
cat(sprintf("RESULT:respondents_germany=%d\n", G$n_resp))
cat(sprintf("RESULT:choice_tasks_us=%d\n", U$n_prof))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", G$n_prof))
