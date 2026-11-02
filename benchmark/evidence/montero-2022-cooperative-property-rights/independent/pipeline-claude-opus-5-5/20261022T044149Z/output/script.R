# Changes and rationale:
# 1. Outcome: switched to hh_inc_pc_real. ln_hh_inc_pc_real is the paper's log outcome,
#    so the levels column most likely uses the matching real (deflated) series.
# 2. Survey-round FE: survey_year is missing for ~790 workers. Dropping them explains the
#    sample-size gap (3991+790 vs 4770; 1513+70 = 1583 exactly). The code now uses a year
#    variable without missing values, and drops the FE if none exists, so no workers are lost.
# 3. Running-variable slopes: uses norm_dist and the dataset's own norm_dist_Above
#    interaction instead of Above500:x.
# 4. IQR unit: 8 "properties" means the coop/hacienda id was mostly empty and collapsed
#    almost all workers into one group. 327 properties against 98 owners implies the IQR
#    is taken per property x survey year. Properties are now identified by match_id,
#    falling back to canton, then owner.
# 5. The 5-worker minimum for the IQR is not stated in the paper, so it is removed;
#    the count with that filter is still logged.
# The bandwidth cutoff is now strict (abs(x) < bw) — another guess; counts at <= are
#    logged for comparison.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "/Users/matthew/dev/Retally/.cache/datasets/montero_2022_cooperative_property_rights.script-free"
df <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(path, "ehpm_incomemodule_wreform.dta"))))
nm <- names(df)

# ---- Outcome: real household earnings per capita (monthly) ----
yvar <- if ("hh_inc_pc_real" %in% nm) "hh_inc_pc_real" else "hh_income_pc"
message("Outcome variable: ", yvar)
df$y <- as.numeric(df[[yvar]])
message("Mean hh_income_pc: ", mean(df$hh_income_pc, na.rm = TRUE),
        " ; mean hh_inc_pc_real: ", mean(df$hh_inc_pc_real, na.rm = TRUE))

# ---- Running variable and interaction (as constructed in the dataset) ----
df$x <- as.numeric(df$norm_dist)
df$Above500 <- as.numeric(df$Above500)
df$xA <- if ("norm_dist_Above" %in% nm) as.numeric(df$norm_dist_Above) else df$x * df$Above500
message("Range norm_dist: ", paste(range(df$x, na.rm = TRUE), collapse = " to "),
        " ; NA norm_dist: ", sum(is.na(df$x)))

# ---- Survey-round FE: use a year variable without missing values ----
na_sy <- if ("survey_year" %in% nm) sum(is.na(df$survey_year)) else Inf
na_y  <- if ("year" %in% nm) sum(is.na(df$year)) else Inf
message("NA survey_year: ", na_sy, " ; NA year: ", na_y)
if (na_y == 0) {
  df$fe <- df$year; use_fe <- TRUE; message("FE: year")
} else if (na_sy == 0) {
  df$fe <- df$survey_year; use_fe <- TRUE; message("FE: survey_year")
} else {
  use_fe <- FALSE; df$fe <- 1; message("FE: none (all candidates have NA)")
}

# ---- Cluster: former owner ----
df$cl <- as.character(df$Expropretario_ISTA)
message("NA/empty cluster share: ", mean(is.na(df$Expropretario_ISTA) | df$cl == ""))

# ---- Property id ----
df$prop <- as.character(df$match_id)
bad <- is.na(df$match_id) | df$prop == ""
message("NA match_id share: ", mean(bad))
df$prop[bad] <- paste(df$dept[bad], df$munic[bad], df$canton[bad], sep = "_")
df$prop[is.na(df$prop) | df$prop == "NA_NA_NA"] <- df$cl[is.na(df$prop) | df$prop == "NA_NA_NA"]

base <- df %>% filter(!is.na(y), !is.na(x), !is.na(Above500))

for (bw in c(300, 150)) {
  message("bw ", bw, ": n(<)=", sum(abs(base$x) < bw), " n(<=)=", sum(abs(base$x) <= bw))
}

run_level <- function(bw) {
  d <- base %>% filter(abs(x) < bw)
  fml <- if (use_fe) y ~ Above500 + x + xA | fe else y ~ Above500 + x + xA
  m <- feols(fml, data = d, cluster = ~cl)
  list(b = unname(coef(m)["Above500"]), se = unname(se(m)["Above500"]),
       n = nobs(m), ncl = length(unique(d$cl[obs(m)])))
}

run_iqr <- function(bw) {
  d0 <- base %>% filter(abs(x) < bw) %>%
    group_by(prop, fe) %>%
    summarise(n_mem = n(),
              iqr = unname(quantile(y, 0.75) - quantile(y, 0.25)),
              x = first(x), xA = first(xA), Above500 = first(Above500), cl = first(cl),
              .groups = "drop")
  message("IQR bw ", bw, ": property-years=", nrow(d0), " with >=5 workers=", sum(d0$n_mem >= 5))
  d <- d0
  fml <- if (use_fe) iqr ~ Above500 + x + xA | fe else iqr ~ Above500 + x + xA
  m <- feols(fml, data = d, cluster = ~cl)
  list(b = unname(coef(m)["Above500"]), se = unname(se(m)["Above500"]),
       n = nobs(m), ncl = length(unique(d$cl)))
}

l300 <- run_level(300)
l150 <- run_level(150)
q300 <- run_iqr(300)
q150 <- run_iqr(150)

message(sprintf("Level bw300: b=%.2f se=%.2f n=%d cl=%d", l300$b, l300$se, l300$n, l300$ncl))
message(sprintf("Level bw150: b=%.2f se=%.2f n=%d cl=%d", l150$b, l150$se, l150$n, l150$ncl))
message(sprintf("IQR bw300: b=%.2f se=%.2f n=%d cl=%d", q300$b, q300$se, q300$n, q300$ncl))
message(sprintf("IQR bw150: b=%.2f se=%.2f n=%d cl=%d", q150$b, q150$se, q150$n, q150$ncl))

cat("DEVIATION: Survey-round fixed effects included (Table 5 specification) although the baseline eq. (1) has none\n")
cat("DEVIATION: IQR computed per property x survey year without a minimum-workers filter\n")

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", q300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", q150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(l300$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(l150$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(q300$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(q150$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(l300$ncl)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(l150$ncl)))