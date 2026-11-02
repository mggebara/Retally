# Arias & ... (2022) "Changing Tides": conjoint AMCEs, U.S. and Germany (independent reproduction)
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-11-02-c/mount/arias_2022_changing_tides_climate_migration"

choice_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")

build_long <- function(file, attr_map) {
  x <- read_csv(file.path(D, file), col_types = cols(.default = "c"))
  x <- x[-(1:2), ]                       # Qualtrics label / ImportId rows
  cat("rows:", nrow(x), " status table:", paste(names(table(x$Status)), table(x$Status), collapse = "; "), "\n")
  x <- x[x$Status == "0", ]              # drop survey-preview responses (Status = 1)
  x$rid <- seq_len(nrow(x))
  out <- list()
  for (t in 1:9) {
    ch <- suppressWarnings(as.integer(x[[choice_cols[t]]]))
    for (p in 1:2) {
      df <- data.frame(rid = x$rid, task = t, profile = p,
                       chosen = as.integer(ch == p), stringsAsFactors = FALSE)
      for (k in 1:7) {
        aname <- x[[sprintf("F-%d-%d", t, k)]]
        aval  <- x[[sprintf("F-%d-%d-%d", t, p, k)]]
        for (a in names(attr_map)) {
          sel <- !is.na(aname) & aname == attr_map[[a]]
          if (is.null(df[[a]])) df[[a]] <- NA_character_
          df[[a]][sel] <- aval[sel]
        }
      }
      out[[length(out) + 1]] <- df
    }
  }
  long <- bind_rows(out)
  long <- long[!is.na(long$chosen), ]
  long
}

us_map <- list(reason = "Reason for migration", lang = "Language Fluency", occ = "Occupation",
               gender = "Gender", relig = "Religion", origin = "Origin", vuln = "Vulnerability")
de_map <- list(reason = "Gründe für die Migration", lang = "Sprachkompetenz", occ = "Beruf",
               gender = "Geschlecht", relig = "Religion", origin = "Herkunft", vuln = "Zusätzliche Belastung")

us <- build_long("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", us_map)
de <- build_long("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", de_map)

set_levels <- function(d, base) {
  for (a in names(base)) d[[a]] <- relevel(factor(d[[a]]), ref = base[[a]])
  d
}
us <- set_levels(us, list(reason = "Economic opportunity", lang = "None", occ = "Unemployed",
                          gender = "Female", relig = "Agnostic", origin = "Another region in your country",
                          vuln = "None"))
de <- set_levels(de, list(reason = "Wirtschaftliche Perspektive", lang = "Keine", occ = "Arbeitslos",
                          gender = "Weiblich", relig = "Atheist", origin = "Aus einem anderen Teil Ihres Landes",
                          vuln = "Keine"))
for (d in list(us, de)) { print(sapply(d[, names(us_map)], function(v) sum(is.na(v)))); print(lapply(d[, names(us_map)], levels)) }

fml <- chosen ~ reason + lang + occ + gender + relig + origin + vuln
m_us <- feols(fml, data = us, cluster = ~rid)
m_de <- feols(fml, data = de, cluster = ~rid)
print(summary(m_us)); print(summary(m_de))

cu <- coef(m_us); cd <- coef(m_de)
cat(sprintf("RESULT:amce_drought_us=%.4f\n", cu["reasonDrought"]))
cat(sprintf("RESULT:amce_flooding_us=%.4f\n", cu["reasonFlooding"]))
cat(sprintf("RESULT:amce_wildfires_us=%.4f\n", cu["reasonWildfires"]))
cat(sprintf("RESULT:amce_persecution_us=%.4f\n", cu["reasonPolitical/religious/ethnic persecution"]))
cat(sprintf("RESULT:amce_drought_germany=%.4f\n", cd["reasonDürre"]))
cat(sprintf("RESULT:amce_flooding_germany=%.4f\n", cd["reasonÜberflutung"]))
cat(sprintf("RESULT:amce_wildfires_germany=%.4f\n", cd["reasonWaldbrände"]))
cat(sprintf("RESULT:amce_persecution_germany=%.4f\n", cd["reasonPolitische/religiöse/ethnische Verfolgung"]))
cat(sprintf("RESULT:respondents_us=%d\n", length(unique(us$rid))))
cat(sprintf("RESULT:respondents_germany=%d\n", length(unique(de$rid))))
cat(sprintf("RESULT:choice_tasks_us=%d\n", nobs(m_us)))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", nobs(m_de)))
