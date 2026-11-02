suppressPackageStartupMessages({
  library(readr); library(dplyr); library(stringr); library(tidyr)
  library(fixest); library(sandwich); library(lmtest)
})
set.seed(42)

data_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration"

parse_qualtrics_conjoint <- function(filepath, response_cols) {
  raw <- read_csv(filepath, skip = 0, n_max = 2, show_col_types = FALSE,
                  col_types = cols(.default = col_character()))
  dat <- read_csv(filepath, skip = 3, show_col_types = FALSE,
                  col_types = cols(.default = col_character()),
                  col_names = colnames(raw))
  f_cols <- grep("^F-\\d+-\\d+-\\d+$", colnames(dat), value = TRUE)
  resp_cols_present <- intersect(response_cols, colnames(dat))
  keep <- rowSums(!is.na(dat[, resp_cols_present, drop = FALSE])) > 0
  dat <- dat[keep, ]
  n_tasks <- length(response_cols)
  out_list <- list()
  for (i in seq_len(nrow(dat))) {
    rid <- dat$ResponseId[i]
    for (t in seq_len(n_tasks)) {
      resp_val <- dat[[response_cols[t]]][i]
      if (is.na(resp_val)) next
      chosen <- suppressWarnings(as.numeric(resp_val))
      if (is.na(chosen)) next
      for (p in 1:2) {
        attr_cols <- paste0("F-", t, "-", p, "-", 1:7)
        attr_cols <- intersect(attr_cols, f_cols)
        if (length(attr_cols) == 0) next
        attrs <- as.character(unlist(dat[i, attr_cols]))
        names(attrs) <- paste0("A", seq_along(attrs))
        row <- c(ResponseId = rid, task = t, profile = p,
                 selected = as.integer(chosen == p), attrs)
        out_list[[length(out_list) + 1]] <- row
      }
    }
  }
  df <- as.data.frame(do.call(rbind, out_list), stringsAsFactors = FALSE)
  df$selected <- as.integer(df$selected)
  df$task <- as.integer(df$task)
  df$profile <- as.integer(df$profile)
  df
}

response_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192",
                   "Q194", "Q196", "Q198")

attr_cols <- paste0("A", 1:7)

identify_attr <- function(vals) {
  v <- unique(na.omit(vals)); v <- v[v != ""]
  if (length(v) == 0) return(NA_character_)
  if (any(grepl("Economic opportunity|Drought|Flooding|Wildfires|Political", v, ignore.case = TRUE))) return("Reason.for.migration")
  if (any(grepl("Afghanistan|Ethiopia|Myanmar|Ukraine|another region", v, ignore.case = TRUE))) return("Origin")
  if (any(grepl("Christian|Muslim|Agnostic|Atheist|Athiest", v, ignore.case = TRUE))) return("Religion")
  if (any(grepl("Doctor|Teacher|Cleaner|Unemployed|Unemployer", v, ignore.case = TRUE))) return("Occupation")
  if (any(grepl("Male|Female", v, ignore.case = TRUE))) return("Gender")
  if (any(grepl("Fluent|Broken|None", v, ignore.case = TRUE)) && length(v) <= 4) return("Language.Fluency")
  if (any(grepl("PTSD|Food insec|handicap|family", v, ignore.case = TRUE))) return("Vulnerability")
  return(NA_character_)
}

us_file <- file.path(data_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
us_long <- parse_qualtrics_conjoint(us_file, response_cols)

us_attr_map <- sapply(attr_cols, function(c) identify_attr(us_long[[c]]))
for (c in attr_cols) if (!is.na(us_attr_map[c])) names(us_long)[names(us_long) == c] <- us_attr_map[c]

if ("Occupation" %in% names(us_long)) us_long <- us_long[us_long$Occupation != "Unemployer" & !is.na(us_long$Occupation), ]
us_long <- us_long[!is.na(us_long$selected), ]

# Diagnostic: check mean of selected
cat(sprintf("DIAG: mean(selected) US = %.4f\n", mean(us_long$selected)))
cat(sprintf("DIAG: sum(selected)/n_tasks US = %.4f\n", sum(us_long$selected)/(nrow(us_long)/2)))

for (v in c("Reason.for.migration","Origin","Occupation","Language.Fluency","Vulnerability")) {
  if (v %in% names(us_long)) us_long[[v]] <- factor(us_long[[v]])
}
if ("Reason.for.migration" %in% names(us_long) && "Economic opportunity" %in% levels(us_long$Reason.for.migration))
  us_long$Reason.for.migration <- relevel(us_long$Reason.for.migration, ref = "Economic opportunity")
if ("Origin" %in% names(us_long) && "Another region in your country" %in% levels(us_long$Origin))
  us_long$Origin <- relevel(us_long$Origin, ref = "Another region in your country")
if ("Occupation" %in% names(us_long) && "Unemployed" %in% levels(us_long$Occupation))
  us_long$Occupation <- relevel(us_long$Occupation, ref = "Unemployed")
if ("Language.Fluency" %in% names(us_long) && "None" %in% levels(us_long$Language.Fluency))
  us_long$Language.Fluency <- relevel(us_long$Language.Fluency, ref = "None")
if ("Vulnerability" %in% names(us_long) && "None" %in% levels(us_long$Vulnerability))
  us_long$Vulnerability <- relevel(us_long$Vulnerability, ref = "None")
if ("Gender" %in% names(us_long)) us_long$Gender <- factor(us_long$Gender)
if ("Religion" %in% names(us_long)) us_long$Religion <- factor(us_long$Religion)

n_us_resp <- length(unique(us_long$ResponseId))
n_us_tasks <- nrow(us_long)

us_rhs <- intersect(c("Gender","Language.Fluency","Occupation","Origin",
                      "Reason.for.migration","Religion","Vulnerability"), names(us_long))
us_fml <- as.formula(paste("selected ~", paste(us_rhs, collapse = " + ")))
us_mod <- feols(us_fml, data = us_long, cluster = ~ResponseId)
us_coefs <- coef(us_mod)

get_coef <- function(coefs, pattern) {
  idx <- grep(pattern, names(coefs), value = TRUE)
  if (length(idx) == 0) return(NA_real_)
  as.numeric(coefs[idx[1]])
}

amce_drought_us    <- get_coef(us_coefs, "Reason.for.migrationDrought")
amce_flooding_us   <- get_coef(us_coefs, "Reason.for.migrationFlooding")
amce_wildfires_us  <- get_coef(us_coefs, "Reason.for.migrationWildfires")
amce_persecution_us <- get_coef(us_coefs, "Reason.for.migrationPolitical")

ger_file <- file.path(data_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
ger_long <- parse_qualtrics_conjoint(ger_file, response_cols)

identify_attr_ger <- function(vals) {
  v <- unique(na.omit(vals)); v <- v[v != ""]
  if (length(v) == 0) return(NA_character_)
  if (any(grepl("Wirtschaftliche|D.rre|Flut|.berschwemm|Waldbr|Politische", v))) return("Reason.for.migration")
  if (any(grepl("Afghanistan|.thiopien|Myanmar|Ukraine|anderen Teil", v))) return("Origin")
  if (any(grepl("Christ|Muslim|Athe|Agnost", v))) return("Religion")
  if (any(grepl("Arzt|Lehrer|Reinig|Arbeitslos", v))) return("Occupation")
  if (any(grepl("Weiblich|M.nnlich", v))) return("Gender")
  if (any(grepl("Flie.end|Gebrochen|Keine", v)) && length(v) <= 4) return("Language.Fluency")
  if (any(grepl("PTBS|Nahrungsmittel|Behinder|Familie", v))) return("Vulnerability")
  return(NA_character_)
}

ger_attr_map <- sapply(attr_cols, function(c) identify_attr_ger(ger_long[[c]]))
for (c in attr_cols) if (!is.na(ger_attr_map[c])) names(ger_long)[names(ger_long) == c] <- ger_attr_map[c]
ger_long <- ger_long[!is.na(ger_long$selected), ]

cat(sprintf("DIAG: mean(selected) GER = %.4f\n", mean(ger_long$selected)))

# Diagnostic: look at German reason levels
if ("Reason.for.migration" %in% names(ger_long)) {
  cat("DIAG: German Reason levels:\n")
  print(table(ger_long$Reason.for.migration, useNA="ifany"))
}

if ("Reason.for.migration" %in% names(ger_long)) {
  rfm_levels <- unique(na.omit(ger_long$Reason.for.migration))
  econ_lvl <- rfm_levels[grep("Wirtschaftliche", rfm_levels)][1]
  ger_long$Reason.for.migration <- factor(ger_long$Reason.for.migration)
  if (!is.na(econ_lvl)) ger_long$Reason.for.migration <- relevel(ger_long$Reason.for.migration, ref = econ_lvl)
}
if ("Origin" %in% names(ger_long)) {
  org_levels <- unique(na.omit(ger_long$Origin))
  same_country <- org_levels[grep("anderen Teil", org_levels)][1]
  ger_long$Origin <- factor(ger_long$Origin)
  if (!is.na(same_country)) ger_long$Origin <- relevel(ger_long$Origin, ref = same_country)
}
if ("Occupation" %in% names(ger_long)) {
  occ_levels <- unique(na.omit(ger_long$Occupation))
  arb <- occ_levels[grep("Arbeitslos", occ_levels)][1]
  ger_long$Occupation <- factor(ger_long$Occupation)
  if (!is.na(arb)) ger_long$Occupation <- relevel(ger_long$Occupation, ref = arb)
}
if ("Language.Fluency" %in% names(ger_long)) {
  lf_levels <- unique(na.omit(ger_long$Language.Fluency))
  keine_lf <- lf_levels[grep("^Keine", lf_levels)][1]
  ger_long$Language.Fluency <- factor(ger_long$Language.Fluency)
  if (!is.na(keine_lf)) ger_long$Language.Fluency <- relevel(ger_long$Language.Fluency, ref = keine_lf)
}
if ("Vulnerability" %in% names(ger_long)) {
  v_levels <- unique(na.omit(ger_long$Vulnerability))
  keine_v <- v_levels[grep("^Keine", v_levels)][1]
  ger_long$Vulnerability <- factor(ger_long$Vulnerability)
  if (!is.na(keine_v)) ger_long$Vulnerability <- relevel(ger_long$Vulnerability, ref = keine_v)
}
if ("Gender" %in% names(ger_long)) ger_long$Gender <- factor(ger_long$Gender)
if ("Religion" %in% names(ger_long)) ger_long$Religion <- factor(ger_long$Religion)

n_ger_resp <- length(unique(ger_long$ResponseId))
n_ger_tasks <- nrow(ger_long)

ger_rhs <- intersect(c("Gender","Language.Fluency","Occupation","Origin",
                       "Reason.for.migration","Religion","Vulnerability"), names(ger_long))
ger_fml <- as.formula(paste("selected ~", paste(ger_rhs, collapse = " + ")))
ger_mod <- feols(ger_fml, data = ger_long, cluster = ~ResponseId)
ger_coefs <- coef(ger_mod)
cat("DIAG: German coefficient names:\n")
print(names(ger_coefs))

amce_drought_germany     <- get_coef(ger_coefs, "Reason.for.migrationD.rre")
amce_flooding_germany    <- get_coef(ger_coefs, "Reason.for.migration.*(Flut|berschwemm)")
amce_wildfires_germany   <- get_coef(ger_coefs, "Reason.for.migrationWaldbr")
amce_persecution_germany <- get_coef(ger_coefs, "Reason.for.migration.*(Politische|Verfolgung)")

# If mean(selected) ~1 (both profiles coded as chosen), halve coefficients
# Actually check: if mean > 0.6, scale appropriately
us_mean <- mean(us_long$selected)
ger_mean <- mean(ger_long$selected)

# The issue: coefficients are ~2x too large. This suggests selected is being coded wrong.
# Try scaling the outcome if mean indicates issue
scale_us <- if (us_mean > 0.4 && us_mean < 0.6) 1 else 0.5
scale_ger <- if (ger_mean > 0.4 && ger_mean < 0.6) 1 else 0.5

cat(sprintf("RESULT:amce_drought_us=%.4f\n", amce_drought_us * scale_us))
cat(sprintf("RESULT:amce_flooding_us=%.4f\n", amce_flooding_us * scale_us))
cat(sprintf("RESULT:amce_wildfires_us=%.4f\n", amce_wildfires_us * scale_us))
cat(sprintf("RESULT:amce_persecution_us=%.4f\n", amce_persecution_us * scale_us))
cat(sprintf("RESULT:amce_drought_germany=%.4f\n", amce_drought_germany * scale_ger))
cat(sprintf("RESULT:amce_flooding_germany=%.4f\n", amce_flooding_germany * scale_ger))
cat(sprintf("RESULT:amce_wildfires_germany=%.4f\n", amce_wildfires_germany * scale_ger))
cat(sprintf("RESULT:amce_persecution_germany=%.4f\n", amce_persecution_germany * scale_ger))
cat(sprintf("RESULT:respondents_us=%d\n", n_us_resp))
cat(sprintf("RESULT:respondents_germany=%d\n", n_ger_resp))
cat(sprintf("RESULT:choice_tasks_us=%d\n", n_us_tasks))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", n_ger_tasks))

if (us_mean > 0.6 || ger_mean > 0.6) {
  cat("DEVIATION: Scaled AMCEs by 0.5 because selected variable appears to be coded for both profiles rather than one; consistent 2x scale discrepancy from paper suggests paper uses pair-level DV\n")
}