# Arias & ... (2022) "Changing Tides" -- Study 1 conjoint, Table 2 AMCEs (reason for migration)
# Independent, blind reproduction.  Full model: chosen ~ all seven attributes (baseline levels per
# Table 1), all profile pairs, OLS, robust SEs clustered by respondent.  The design restricts
# Language=None x Origin=Another region; following the cjoint convention for restricted designs,
# the Language x Origin interaction is included so the AMCEs of those attributes are well defined
# (reason for migration is unrestricted, so its AMCE is the main-effect coefficient).
set.seed(42)
suppressMessages({library(tidyverse); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-11-01-a/mount/arias_2022_changing_tides_climate_migration"
chq <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")

# map German attribute names / levels to English
attr_de <- c("Gründe für die Migration"="Reason", "Sprachkompetenz"="Language", "Beruf"="Occupation",
             "Geschlecht"="Gender", "Religion"="Religion", "Herkunft"="Origin", "Zusätzliche Belastung"="Vulnerability")
attr_en <- c("Reason for migration"="Reason", "Language Fluency"="Language", "Occupation"="Occupation",
             "Gender"="Gender", "Religion"="Religion", "Origin"="Origin", "Vulnerability"="Vulnerability")
lev_de <- list(
  Reason = c("Politische/religiöse/ethnische Verfolgung"="Persecution","Überflutung"="Flooding","Dürre"="Drought",
             "Wirtschaftliche Perspektive"="Economic opportunity","Waldbrände"="Wildfires"),
  Language = c("Fließend"="Fluent","Gebrochen"="Broken","Keine"="None"),
  Occupation = c("Reinigungskraft"="Cleaner","Lehrer"="Teacher","Arzt"="Doctor","Arbeitslos"="Unemployed"),
  Gender = c("Männlich"="Male","Weiblich"="Female"),
  Religion = c("Christian"="Christian","Muslim"="Muslim","Atheist"="Atheist/Agnostic"),
  Origin = c("Aus einem anderen Teil Ihres Landes"="Another region","Afghanistan"="Afghanistan","Äthiopien"="Ethiopia",
             "Ukraine"="Ukraine","Myanmar"="Myanmar"),
  Vulnerability = c("Keine"="None","PTBS (Posttraumatische Belastungsstörung)"="PTSD","Ernährungsunsicherheit"="Food insecurity",
                    "Keine überlebenden Familienmitglieder"="No surviving family","Körperliche Behinderung"="Handicapped"))
lev_en <- list(
  Reason = c("Political/religious/ethnic persecution"="Persecution","Flooding"="Flooding","Drought"="Drought",
             "Economic opportunity"="Economic opportunity","Wildfires"="Wildfires"),
  Language = c("Fluent"="Fluent","Broken"="Broken","None"="None"),
  Occupation = c("Cleaner"="Cleaner","Teacher"="Teacher","Doctor"="Doctor","Unemployed"="Unemployed"),
  Gender = c("Male"="Male","Female"="Female"),
  Religion = c("Christian"="Christian","Muslim"="Muslim","Agnostic"="Atheist/Agnostic"),
  Origin = c("Another region in your country"="Another region","Afghanistan"="Afghanistan","Ethiopia"="Ethiopia",
             "Ukraine"="Ukraine","Myanmar"="Myanmar"),
  Vulnerability = c("None"="None","Post Traumatic Stress Disorder (PTSD)"="PTSD","Food insecurity"="Food insecurity",
                    "No surviving family members"="No surviving family","Physically handicapped"="Handicapped"))
base <- c(Reason="Economic opportunity", Language="None", Occupation="Unemployed", Gender="Female",
          Religion="Atheist/Agnostic", Origin="Another region", Vulnerability="None")

stack <- function(f, amap, lmap) {
  d <- read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE)[-(1:2), ]
  rows <- list()
  for (k in 1:9) for (p in 1:2) {
    out <- tibble(resp = d$ResponseId, task = k, profile = p, choice = d[[chq[k]]])
    for (j in 1:7) {
      an <- unname(amap[d[[paste0("F-", k, "-", j)]]])
      lv <- d[[paste0("F-", k, "-", p, "-", j)]]
      for (a in unique(an)) {
        idx <- which(an == a)
        if (!a %in% names(out)) out[[a]] <- NA_character_
        out[[a]][idx] <- unname(lmap[[a]][lv[idx]])
      }
    }
    rows[[length(rows) + 1]] <- out
  }
  s <- bind_rows(rows) %>% filter(!is.na(choice)) %>%
    mutate(chosen = as.integer(as.integer(choice) == profile))
  stopifnot(!anyNA(s[, names(base)]))
  for (a in names(base)) s[[a]] <- relevel(factor(s[[a]]), ref = base[[a]])
  s
}

us <- stack("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", attr_en, lev_en)
de <- stack("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", attr_de, lev_de)

fml <- chosen ~ Reason + Language + Occupation + Gender + Religion + Origin + Vulnerability + Language:Origin
est <- function(s, lab) {
  m <- feols(fml, data = s, cluster = ~resp)
  print(coeftable(m)[grep("^Reason", names(coef(m))), ])
  cat(lab, "N obs", nobs(m), " respondents", n_distinct(s$resp), "\n")
  coef(m)
}
cu <- est(us, "US"); cd <- est(de, "DE")

cat(sprintf("RESULT:amce_drought_us=%.6f\n", cu["ReasonDrought"]))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n", cu["ReasonFlooding"]))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n", cu["ReasonWildfires"]))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", cu["ReasonPersecution"]))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n", cd["ReasonDrought"]))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n", cd["ReasonFlooding"]))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n", cd["ReasonWildfires"]))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", cd["ReasonPersecution"]))
cat(sprintf("RESULT:respondents_us=%d\n", n_distinct(us$resp)))
cat(sprintf("RESULT:respondents_germany=%d\n", n_distinct(de$resp)))
cat(sprintf("RESULT:choice_tasks_us=%d\n", nrow(us)))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", nrow(de)))
