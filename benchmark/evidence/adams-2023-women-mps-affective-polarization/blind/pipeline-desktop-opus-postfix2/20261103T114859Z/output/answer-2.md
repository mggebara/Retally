suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))   # updated_data
dy <- as.data.frame(updated_data)
gd <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

cat("Dyadic columns:", paste(names(dy), collapse = ", "), "\n")
cat("Gender columns:", paste(names(gd), collapse = ", "), "\n")

to_num <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

describe <- function(df, v) {
  if (!v %in% names(df)) return(invisible(NULL))
  x <- to_num(df[[v]])
  cat(sprintf("  %s: n=%d nNA=%d min=%.3f max=%.3f mean=%.3f nuniq=%d\n", v,
              sum(!is.na(x)), sum(is.na(x)),
              suppressWarnings(min(x, na.rm = TRUE)), suppressWarnings(max(x, na.rm = TRUE)),
              mean(x, na.rm = TRUE), length(unique(x[!is.na(x)]))))
}
cat("Candidate DV columns (dyadic):\n")
for (v in c("party_like", "party_dislike", "DM", "logDM")) describe(dy, v)
cat("Candidate DV columns (gender):\n")
for (v in c("dislike", "party_like", "party_dislike")) describe(gd, v)

is_score <- function(df, v) {
  if (!v %in% names(df)) return(FALSE)
  x <- to_num(df[[v]]); xx <- x[!is.na(x)]
  length(xx) > 0 && min(xx) >= 0 && max(xx) <= 10 && length(unique(xx)) > 20
}

# ---- Dependent variable: mean 0-10 like/dislike score of i's partisans toward j ----
find_dv <- function(df) {
  for (v in c("party_like", "like", "thermometer")) if (is_score(df, v)) return(v)
  nm <- names(df)
  id_like <- c("party_number", "party_from", "party_to", "country", "year", "gender", "ID")
  for (v in setdiff(nm[grepl("like|therm", nm, ignore.case = TRUE)], id_like)) {
    if (is_score(df, v)) return(v)
  }
  stop("No dependent variable found")
}

# ---- Detect the out-party (j) women-MP share (lagged) ----
find_women <- function(df) {
  nm <- names(df)
  w <- nm[grepl("wom|fem", nm, ignore.case = TRUE)]
  w <- w[!grepl("lead|chair|resp", w, ignore.case = TRUE)]
  to_w <- w[grepl("^to_|_to_|_to$|out", w, ignore.case = TRUE)]
  if (length(to_w) == 0) to_w <- w[!grepl("^from_|_from", w, ignore.case = TRUE)]
  if (length(to_w) == 0) stop("No women-MP share variable found")
  lagw <- to_w[grepl("lag|t1|t_1|prior|prev", to_w, ignore.case = TRUE)]
  pick <- if (length(lagw) > 0) lagw[1] else to_w[1]
  prop <- to_w[grepl("prop|share|pct|perc", to_w, ignore.case = TRUE)]
  if (length(lagw) == 0 && length(prop) > 0) pick <- prop[1]
  if (length(lagw) > 0) {
    lp <- lagw[grepl("prop|share|pct|perc", lagw, ignore.case = TRUE)]
    if (length(lp) > 0) pick <- lp[1]
  }
  pick
}

prep <- function(df, dv, flip = FALSE) {
  wv <- find_women(df)
  cat("Using DV:", dv, if (flip) "(reversed: 10 - x)" else "", " women var:", wv, "\n")
  df$y <- to_num(df[[dv]])
  if (flip) df$y <- 10 - df$y
  df$women_j <- to_num(df[[wv]])
  if (max(df$women_j, na.rm = TRUE) > 1.0001) df$women_j <- df$women_j / 100
  if ("rile_distance_s" %in% names(df)) {
    df$rl_dist <- to_num(df$rile_distance_s)
  } else {
    r <- to_num(df$rile_distance)
    df$rl_dist <- (r - mean(r, na.rm = TRUE)) / sd(r, na.rm = TRUE)
  }
  df$coal <- to_num(df$govern_together)
  df$opp <- to_num(df$opposition_together)
  df$to_mp <- to_num(df$to_mp_number)
  df$from_mp <- to_num(df$from_mp_number)
  df$election <- paste(df$country, df$year, sep = "_")
  df
}

dv_main <- find_dv(dy)
dy <- prep(dy, dv_main)

# ---- Main sample ----
cat(sprintf("SAMPLE:main:loaded=%d\n", nrow(dy)))
main <- dy %>% filter(!is.na(to_mp), !is.na(from_mp), to_mp >= 4, from_mp >= 4)
cat(sprintf("SAMPLE:main:both_parties_at_least_4_mps=%d\n", nrow(main)))

m1 <- feols(y ~ women_j | election, data = main, cluster = ~election)
m2 <- feols(y ~ women_j + rl_dist + coal + opp | election, data = main, cluster = ~election)
cat(sprintf("SAMPLE:main:estimation=%d\n", nobs(m2)))
cat(sprintf("SAMPLE:bivariate:loaded=%d\n", nrow(dy)))
cat(sprintf("SAMPLE:bivariate:both_parties_at_least_4_mps=%d\n", nrow(main)))
cat(sprintf("SAMPLE:bivariate:estimation=%d\n", nobs(m1)))

# ---- Gender-disaggregated samples ----
# The gender file carries a respondent-gender-specific score ("dislike"); orient it the
# same way as the main DV (higher = warmer) by checking its correlation with the
# dyad-level like score when available.
if ("dislike" %in% names(gd) && is_score(gd, "dislike")) {
  dv_g <- "dislike"
  flip_g <- FALSE
  if (dv_main %in% names(gd)) {
    cc <- suppressWarnings(cor(to_num(gd$dislike), to_num(gd[[dv_main]]), use = "complete.obs"))
    cat(sprintf("cor(gender dislike, %s) = %.3f\n", dv_main, cc))
    if (!is.na(cc) && cc < 0) flip_g <- TRUE
  } else if ("party_dislike" %in% names(gd)) {
    cc <- suppressWarnings(cor(to_num(gd$dislike), to_num(gd$party_dislike), use = "complete.obs"))
    cat(sprintf("cor(gender dislike, party_dislike) = %.3f\n", cc))
    if (!is.na(cc) && cc > 0) flip_g <- TRUE
  }
} else {
  dv_g <- if (dv_main %in% names(gd)) dv_main else find_dv(gd)
  flip_g <- FALSE
}
gd <- prep(gd, dv_g, flip = flip_g)
g <- gd$gender
gchar <- tolower(trimws(as.character(g)))
gnum <- suppressWarnings(as.numeric(gchar))
if (all(is.na(gnum[!is.na(g)]))) {
  is_female <- grepl("^f|wom", gchar)
  is_male <- grepl("^m|^men", gchar) & !is_female
} else {
  vals <- sort(unique(gnum[!is.na(gnum)]))
  if (all(vals %in% c(1, 2))) {        # CSES coding: 1 = male, 2 = female
    is_female <- gnum == 2; is_male <- gnum == 1
  } else {                              # 0/1 female dummy
    is_female <- gnum == 1; is_male <- gnum == 0
  }
}
is_female[is.na(is_female)] <- FALSE
is_male[is.na(is_male)] <- FALSE
cat("Gender values:", paste(unique(gchar), collapse = ", "), "\n")

run_sub <- function(sub, name) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(gd)))
  cat(sprintf("SAMPLE:%s:respondent_gender_subgroup=%d\n", name, nrow(sub)))
  s <- sub %>% filter(!is.na(to_mp), !is.na(from_mp), to_mp >= 4, from_mp >= 4)
  cat(sprintf("SAMPLE:%s:both_parties_at_least_4_mps=%d\n", name, nrow(s)))
  m <- feols(y ~ women_j + rl_dist + coal + opp | election, data = s, cluster = ~election)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  m
}
m3 <- run_sub(gd[is_female, ], "women_partisans")
m4 <- run_sub(gd[is_male, ], "men_partisans")

print(etable(m1, m2, m3, m4))

used <- main[obs(m2), ]
n_elec <- length(unique(used$election))

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["women_j"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["women_j"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["women_j"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["women_j"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rl_dist"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["coal"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opp"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_elec))
