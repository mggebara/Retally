set.seed(42)
suppressPackageStartupMessages(library(fixest))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-10-21-b/mount/arias_2022_changing_tides_climate_migration"

choice_vars <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")

# attribute-label -> canonical name, and level -> canonical level (German labels mapped to English)
attr_map <- c("Reason for migration" = "reason", "Language Fluency" = "language",
              "Occupation" = "occupation", "Gender" = "gender", "Religion" = "religion",
              "Origin" = "origin", "Vulnerability" = "vulnerability",
              "Gründe für die Migration" = "reason", "Sprachkompetenz" = "language",
              "Beruf" = "occupation", "Geschlecht" = "gender", "Herkunft" = "origin",
              "Zusätzliche Belastung" = "vulnerability")
lvl_map <- c("Politische/religiöse/ethnische Verfolgung" = "Political/religious/ethnic persecution",
             "Überflutung" = "Flooding", "Dürre" = "Drought",
             "Wirtschaftliche Perspektive" = "Economic opportunity", "Waldbrände" = "Wildfires",
             "Fließend" = "Fluent", "Gebrochen" = "Broken",
             "Reinigungskraft" = "Cleaner", "Lehrer" = "Teacher", "Arzt" = "Doctor", "Arbeitslos" = "Unemployed",
             "Männlich" = "Male", "Weiblich" = "Female",
             "Atheist" = "Agnostic/Atheist", "Agnostic" = "Agnostic/Atheist",
             "Aus einem anderen Teil Ihres Landes" = "Another region in your country",
             "Äthiopien" = "Ethiopia",
             "PTBS (Posttraumatische Belastungsstörung)" = "Post Traumatic Stress Disorder (PTSD)",
             "Ernährungsunsicherheit" = "Food insecurity",
             "Keine überlebenden Familienmitglieder" = "No surviving family members",
             "Körperliche Behinderung" = "Physically handicapped")
baselines <- c(reason = "Economic opportunity", language = "None", occupation = "Unemployed",
               gender = "Female", religion = "Agnostic/Atheist", origin = "Another region in your country",
               vulnerability = "None")

build <- function(file, german) {
  x <- read.csv(file.path(D, file), check.names = FALSE, stringsAsFactors = FALSE,
                encoding = "UTF-8", na.strings = c("", "NA"))
  x <- x[-(1:2), ]                      # drop Qualtrics label / import-id rows
  out <- vector("list", 9 * 2)
  i <- 0
  for (t in 1:9) {
    ch <- suppressWarnings(as.integer(x[[choice_vars[t]]]))
    for (p in 1:2) {
      i <- i + 1
      d <- data.frame(resp = x$ResponseId, task = t, profile = p,
                      chosen = as.integer(ch == p), stringsAsFactors = FALSE)
      for (k in 1:7) {
        an <- x[[sprintf("F-%d-%d", t, k)]]
        lv <- x[[sprintf("F-%d-%d-%d", t, p, k)]]
        cn <- unname(attr_map[an])
        for (a in unique(na.omit(cn))) {
          sel <- !is.na(cn) & cn == a
          if (!a %in% names(d)) d[[a]] <- NA_character_
          d[[a]][sel] <- lv[sel]
        }
      }
      d <- d[!is.na(ch), ]
      out[[i]] <- d
    }
  }
  d <- do.call(rbind, out)
  for (a in names(baselines)) {
    v <- d[[a]]
    if (german && a == "language") v[v == "Keine"] <- "None"
    if (german && a == "vulnerability") v[v == "Keine"] <- "None"
    m <- lvl_map[v]; v <- ifelse(is.na(m), v, m)
    d[[a]] <- relevel(factor(v), ref = baselines[[a]])
  }
  d
}

run <- function(d, tag) {
  cat("\n=====", tag, "\n")
  cat("respondents:", length(unique(d$resp)), " profiles:", nrow(d), "\n")
  for (a in names(baselines)) print(table(d[[a]], useNA = "ifany"))
  print(with(d, table(language, origin == "Another region in your country")))
  m <- feols(chosen ~ reason + language + gender + occupation + religion + origin + vulnerability,
             data = d, cluster = ~resp)
  print(coeftable(m))
  m
}

us <- build("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", FALSE)
de <- build("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", TRUE)
mu <- run(us, "US")
md <- run(de, "Germany")

g <- function(m, lv) unname(coef(m)[paste0("reason", lv)])
cat(sprintf("RESULT:amce_drought_us=%.6f\n", g(mu, "Drought")))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n", g(mu, "Flooding")))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n", g(mu, "Wildfires")))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", g(mu, "Political/religious/ethnic persecution")))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n", g(md, "Drought")))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n", g(md, "Flooding")))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n", g(md, "Wildfires")))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", g(md, "Political/religious/ethnic persecution")))
cat(sprintf("RESULT:respondents_us=%d\n", length(unique(us$resp))))
cat(sprintf("RESULT:respondents_germany=%d\n", length(unique(de$resp))))
cat(sprintf("RESULT:choice_tasks_us=%d\n", nrow(us)))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", nrow(de)))
