# Retally reproduction: Arias & Blair (2022) "Changing Tides: Public Attitudes on Climate Migration"
# Study 1 conjoint, Table 2 AMCEs for Reason for Migration (US and German samples) + sample sizes.
# Follows Migration_Analysis_Final.R: cjoint::read.qualtrics() reshaping, drop NA choices,
# (US) drop 'Unemployer' occupation rows and the first 4 rows, cjoint::amce() with
# respondent-clustered SEs, baseline reason = Economic opportunity.
# cjoint is not installed, so read.qualtrics() and amce() are re-implemented:
#  - long data: one row per respondent x task x profile, selected = 1 if the profile was chosen
#  - AMCE = OLS coefficient on attribute dummies (uniform, independent randomisation);
#    where the design file declares a restriction between two attributes that cjoint can match
#    to attribute names (German design: Language Fluency 'Keine' x Origin 'Aus einem anderen Teil
#    Ihres Landes'), cjoint::amce adds the Language x Origin interaction to the regression; we do
#    the same.  The US design's restriction refers to "Country of Origin", which is not an
#    attribute name in the design, so no interaction is added there.
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)

D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration"
resp_cols <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")

build_long <- function(f) {
  x <- read.csv(file.path(D, f), stringsAsFactors = FALSE, check.names = FALSE, encoding = "UTF-8")
  x <- x[-(1:2), ]   # Qualtrics new format: drop question-text and ImportId rows
  out <- list()
  for (k in 1:9) for (j in 1:2) {
    d <- data.frame(Response.ID = x$ResponseId, row = seq_len(nrow(x)), task = k, profile = j,
                    resp = x[[resp_cols[k]]], stringsAsFactors = FALSE)
    for (a in 1:7) {
      d[[paste0("attr", a)]] <- x[[sprintf("F-%d-%d", k, a)]]
      d[[paste0("lev", a)]]  <- x[[sprintf("F-%d-%d-%d", k, j, a)]]
    }
    out[[length(out) + 1]] <- d
  }
  L <- do.call(rbind, out)
  anames <- sort(unique(unlist(L[, paste0("attr", 1:7)])))
  anames <- anames[anames != ""]
  for (an in anames) {
    v <- rep(NA_character_, nrow(L))
    for (a in 1:7) { m <- L[[paste0("attr", a)]] == an; v[m] <- L[[paste0("lev", a)]][m] }
    L[[an]] <- v
  }
  L$selected <- ifelse(L$resp == "", NA, as.integer(L$resp == as.character(L$profile)))
  L <- L[order(L$row, L$task, L$profile), ]   # respondent-major order, as read.qualtrics
  L <- L[!is.na(L$selected), ]
  L
}

## ---------------- US ----------------
us <- build_long("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
names(us)[names(us) == "Reason for migration"] <- "Reason"
names(us)[names(us) == "Language Fluency"] <- "Language"
us <- us[us$Occupation != "Unemployer", ]
us <- us[5:nrow(us), ]
us$Reason     <- relevel(factor(us$Reason), "Economic opportunity")
us$Language   <- relevel(factor(us$Language), "None")
us$Occupation <- relevel(factor(us$Occupation), "Unemployed")
us$Origin     <- relevel(factor(us$Origin), "Another region in your country")
us$Vulnerability <- relevel(factor(us$Vulnerability), "None")
us$Gender   <- factor(us$Gender); us$Religion <- factor(us$Religion)
cat("US cross-tab Language x Origin (restriction check):\n"); print(table(us$Language, us$Origin))

m_us <- feols(selected ~ Gender + Language + Occupation + Origin + Reason + Religion + Vulnerability,
              data = us, cluster = ~Response.ID)
m_us_int <- feols(selected ~ Gender + Language * Origin + Occupation + Reason + Religion + Vulnerability,
                  data = us, cluster = ~Response.ID)
print(coeftable(m_us)[grep("^Reason", names(coef(m_us))), ])
cat("US alt (with Language x Origin interaction) Reason coefs:\n")
print(round(coef(m_us_int)[grep("^Reason", names(coef(m_us_int)))], 4))

## ---------------- Germany ----------------
ger <- build_long("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
ren <- c("Beruf" = "Occupation", "Geschlecht" = "Gender", "Gründe für die Migration" = "Reason",
         "Herkunft" = "Origin", "Religion" = "Religion", "Sprachkompetenz" = "Language",
         "Zusätzliche Belastung" = "Vulnerability")
for (n in names(ren)) names(ger)[names(ger) == n] <- ren[[n]]
ger$Reason     <- relevel(factor(ger$Reason), "Wirtschaftliche Perspektive")
ger$Language   <- relevel(factor(ger$Language), "Keine")
ger$Occupation <- relevel(factor(ger$Occupation), "Arbeitslos")
ger$Origin     <- relevel(factor(ger$Origin), "Aus einem anderen Teil Ihres Landes")
ger$Vulnerability <- relevel(factor(ger$Vulnerability), "Keine")
ger$Gender <- relevel(factor(ger$Gender), "Weiblich"); ger$Religion <- factor(ger$Religion)
cat("GER cross-tab Language x Origin (restriction check):\n"); print(table(ger$Language, ger$Origin))

m_ger <- feols(selected ~ Gender + Language * Origin + Occupation + Reason + Religion + Vulnerability,
               data = ger, cluster = ~Response.ID)
m_ger_add <- feols(selected ~ Gender + Language + Occupation + Origin + Reason + Religion + Vulnerability,
                   data = ger, cluster = ~Response.ID)
print(coeftable(m_ger)[grep("^Reason", names(coef(m_ger))), ])
cat("GER alt (additive) Reason coefs:\n")
print(round(coef(m_ger_add)[grep("^Reason", names(coef(m_ger_add)))], 4))

## ---------------- Output ----------------
b_us <- coef(m_us); b_ger <- coef(m_ger)
cat(sprintf("RESULT:amce_drought_us=%.6f\n",     b_us["ReasonDrought"]))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n",    b_us["ReasonFlooding"]))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n",   b_us["ReasonWildfires"]))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", b_us["ReasonPolitical/religious/ethnic persecution"]))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n",     b_ger["ReasonDürre"]))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n",    b_ger["ReasonÜberflutung"]))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n",   b_ger["ReasonWaldbrände"]))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", b_ger["ReasonPolitische/religiöse/ethnische Verfolgung"]))
cat(sprintf("RESULT:respondents_us=%d\n", length(unique(us$Response.ID))))
cat(sprintf("RESULT:respondents_germany=%d\n", length(unique(ger$Response.ID))))
cat(sprintf("RESULT:choice_tasks_us=%d\n", nobs(m_us)))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", nobs(m_ger)))
