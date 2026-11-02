# Arias & Blair (2022) "Changing Tides" -- Study 1 conjoint, Table 2 AMCEs (reason for migration)
# Translation of Migration_Analysis_Final.R (cjoint::read.qualtrics + cjoint::amce) into base R / fixest.
# cjoint is not installed, so read.qualtrics() is re-implemented (respondent x task x profile long format)
# and amce() is estimated as OLS of `selected` on all seven attribute factors with respondent-clustered SEs.
set.seed(42)
suppressPackageStartupMessages({ library(fixest) })

D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-10-21-b/mount/arias_2022_changing_tides_climate_migration"

resp_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")

# Re-implementation of cjoint::read.qualtrics(new.format = TRUE): one row per respondent x task x profile,
# attributes matched by name from F-k-a (attribute name) and F-k-j-a (level); selected = 1 if the
# forced-choice answer equals the profile number, NA if the task was not answered.
read_qualtrics_long <- function(file) {
  x <- read.csv(file.path(D, file), stringsAsFactors = FALSE, check.names = FALSE, encoding = "UTF-8")
  x <- x[-(1:2), ]  # drop question-text and ImportId rows
  n_tasks <- length(resp_cols); n_prof <- 2; n_attr <- 7
  out <- vector("list", n_tasks * n_prof)
  idx <- 0
  for (k in 1:n_tasks) for (j in 1:n_prof) {
    idx <- idx + 1
    r <- suppressWarnings(as.numeric(x[[resp_cols[k]]]))
    d <- data.frame(resp_row = seq_len(nrow(x)), respondent = x$ResponseId, task = k, profile = j,
                    selected = ifelse(is.na(r), NA_real_, as.numeric(r == j)), stringsAsFactors = FALSE)
    for (a in 1:n_attr) {
      nm <- x[[sprintf("F-%d-%d", k, a)]]
      lv <- x[[sprintf("F-%d-%d-%d", k, j, a)]]
      for (u in unique(nm[nm != "" & !is.na(nm)])) {
        if (!u %in% names(d)) d[[u]] <- NA_character_
        d[[u]][nm == u] <- lv[nm == u]
      }
    }
    out[[idx]] <- d
  }
  allnames <- unique(unlist(lapply(out, names)))
  out <- lapply(out, function(d) { for (m in setdiff(allnames, names(d))) d[[m]] <- NA_character_; d[allnames] })
  long <- do.call(rbind, out)
  long <- long[order(long$resp_row, long$task, long$profile), ]  # respondent-major ordering as in cjoint
  rownames(long) <- NULL
  long
}

amce_fit <- function(dat, fml) {
  feols(fml, data = dat, cluster = ~respondent)
}

# ---------------- US ----------------
us <- read_qualtrics_long("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
names(us) <- make.names(names(us))
us <- us[!is.na(us$selected), ]
us <- us[us$Occupation != "Unemployer", ]
us <- us[5:nrow(us), ]   # as in the authors' script: cjt_us_data[5:nrow(cjt_us_data), ]
us$Reason.for.migration <- relevel(factor(us$Reason.for.migration), ref = "Economic opportunity")
us$Vulnerability <- relevel(factor(us$Vulnerability), ref = "None")
us$Occupation <- relevel(factor(us$Occupation), ref = "Unemployed")
us$Language.Fluency <- relevel(factor(us$Language.Fluency), ref = "None")
us$Origin <- relevel(factor(us$Origin), ref = "Another region in your country")
us$Gender <- factor(us$Gender); us$Religion <- factor(us$Religion)
cat("US levels check:\n"); print(lapply(us[, c("Reason.for.migration", "Occupation")], table))
cat("US Language x Origin:\n"); print(table(us$Language.Fluency, us$Origin))

m_us <- amce_fit(us, selected ~ Gender + Language.Fluency + Occupation + Origin +
                   Reason.for.migration + Religion + Vulnerability)
print(coeftable(m_us))

# ---------------- Germany ----------------
ger <- read_qualtrics_long("Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
map <- c("Beruf" = "Occupation", "Geschlecht" = "Gender", "Gründe für die Migration" = "Reason.for.migration",
         "Herkunft" = "Origin", "Religion" = "Religion", "Sprachkompetenz" = "Language.Fluency",
         "Zusätzliche Belastung" = "Vulnerability")
for (g in names(map)) names(ger)[names(ger) == g] <- map[[g]]
stopifnot(all(map %in% names(ger)))
ger <- ger[!is.na(ger$selected), ]
ger$Reason.for.migration <- relevel(factor(ger$Reason.for.migration), ref = "Wirtschaftliche Perspektive")
ger$Vulnerability <- relevel(factor(ger$Vulnerability), ref = "Keine")
ger$Occupation <- relevel(factor(ger$Occupation), ref = "Arbeitslos")
ger$Language.Fluency <- relevel(factor(ger$Language.Fluency), ref = "Keine")
ger$Origin <- relevel(factor(ger$Origin), ref = "Aus einem anderen Teil Ihres Landes")
ger$Gender <- relevel(factor(ger$Gender), ref = "Weiblich")
ger$Religion <- factor(ger$Religion)
cat("GER levels:\n"); print(lapply(ger[, c("Reason.for.migration", "Occupation", "Religion")], table))
cat("GER Language x Origin:\n"); print(table(ger$Language.Fluency, ger$Origin))

m_ger <- amce_fit(ger, selected ~ Gender + Language.Fluency + Occupation + Origin +
                    Reason.for.migration + Religion + Vulnerability)
print(coeftable(m_ger))
# cjoint's design file for Germany declares a Language Fluency x Origin restriction; with dependent
# attributes cjoint adds their interaction to the regression. Shown for reference.
m_ger_int <- amce_fit(ger, selected ~ Gender + Language.Fluency * Origin + Occupation +
                        Reason.for.migration + Religion + Vulnerability)
cat("GER reason coefs with Language x Origin interaction:\n")
print(coeftable(m_ger_int)[grep("Reason", names(coef(m_ger_int))), ])

b_us <- coef(m_us); b_ger <- coef(m_ger)
r <- "Reason.for.migration"
out <- c(
  amce_drought_us        = b_us[paste0(r, "Drought")],
  amce_flooding_us       = b_us[paste0(r, "Flooding")],
  amce_wildfires_us      = b_us[paste0(r, "Wildfires")],
  amce_persecution_us    = b_us[paste0(r, "Political/religious/ethnic persecution")],
  amce_drought_germany   = b_ger[paste0(r, "Dürre")],
  amce_flooding_germany  = b_ger[paste0(r, "Überflutung")],
  amce_wildfires_germany = b_ger[paste0(r, "Waldbrände")],
  amce_persecution_germany = b_ger[paste0(r, "Politische/religiöse/ethnische Verfolgung")],
  respondents_us      = length(unique(us$respondent)),
  respondents_germany = length(unique(ger$respondent)),
  choice_tasks_us      = nobs(m_us),
  choice_tasks_germany = nobs(m_ger)
)
names(out) <- sub("\\..*$", "", names(out))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
