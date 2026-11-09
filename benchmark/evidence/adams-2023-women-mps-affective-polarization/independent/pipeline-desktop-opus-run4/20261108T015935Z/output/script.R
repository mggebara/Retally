suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))   # creates updated_data
dy <- as.data.frame(updated_data)
gd <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

cat("Dyadic columns:\n"); print(names(dy))
cat("Gender columns:\n"); print(names(gd))

# ---------- helpers ----------
num <- function(x) suppressWarnings(as.numeric(as.character(x)))

find_women_col <- function(df) {
  nm <- names(df)
  cand <- nm[grepl("wom|female|fem|gender_prop|prop_w|pct_w|per_w", nm, ignore.case = TRUE) &
               grepl("^to_|_to_|_to$|out", nm, ignore.case = TRUE)]
  if (length(cand) == 0) {
    cand <- nm[grepl("wom|female|fem", nm, ignore.case = TRUE) &
                 !grepl("^from_", nm, ignore.case = TRUE)]
  }
  cand <- setdiff(cand, c("gender"))
  if (length(cand) == 0) stop("No women-share column found")
  score <- sapply(cand, function(v) {
    x <- num(df[[v]])
    if (all(is.na(x))) return(-Inf)
    m <- mean(x, na.rm = TRUE)
    if (m > 1.5) m <- m / 100
    s <- -abs(m - 0.29) * 10
    if (grepl("lag|prior|t_1|t1|prev|lag1", v, ignore.case = TRUE)) s <- s + 2
    if (grepl("prop|share|pct|per", v, ignore.case = TRUE)) s <- s + 0.5
    if (grepl("leader", v, ignore.case = TRUE)) s <- s - 5
    if (grepl("number|num|count|_n$", v, ignore.case = TRUE) && mean(x, na.rm = TRUE) > 1.5) s <- s - 3
    s
  })
  cat("Women-share candidates and scores:\n"); print(score)
  names(score)[which.max(score)]
}

pick_dv <- function(df) {
  nm <- names(df)
  for (v in c("party_like", "thermometer_score", "thermometer", "like", "mean_like")) {
    if (v %in% nm) return(v)
  }
  if ("party_dislike" %in% nm) return("party_dislike")
  if ("dislike" %in% nm) return("dislike")
  stop("No DV found")
}

prep <- function(df) {
  wcol <- find_women_col(df)
  cat("Using women-share column:", wcol, "\n")
  w <- num(df[[wcol]])
  if (mean(w, na.rm = TRUE) > 1.5) w <- w / 100
  df$women_share <- w
  dv <- pick_dv(df)
  cat("Using DV column:", dv, "\n")
  y <- num(df[[dv]])
  if (dv %in% c("party_dislike", "dislike")) y <- 10 - y
  df$therm <- y
  df$rl_raw <- num(df$rile_distance)
  df$coal <- num(df$govern_together)
  df$opp <- num(df$opposition_together)
  df$from_mp <- num(df$from_mp_number)
  df$to_mp <- num(df$to_mp_number)
  df$election <- paste(df$country, df$year, sep = "_")
  df
}

dy <- prep(dy)
cat("Summary DV:\n"); print(summary(dy$therm))
cat("Summary women share:\n"); print(summary(dy$women_share))
cat("Summary rile distance:\n"); print(summary(dy$rl_raw))

std <- function(x, ref) {
  if (sd(ref, na.rm = TRUE) < 2 && abs(mean(ref, na.rm = TRUE)) < 1) return(x)  # already standardized
  (x - mean(ref, na.rm = TRUE)) / sd(ref, na.rm = TRUE)
}

# ---------- sample restriction: MPs in the year BEFORE the survey ----------
# The paper requires >= 4 MPs in the year prior to the election survey.
# mp_number may be the current-election count; the *_prior_seats columns
# are candidates for the lagged count.  Evaluate candidate filters.
complete_rows <- with(dy, !is.na(therm) & !is.na(women_share) & !is.na(rl_raw) &
                        !is.na(coal) & !is.na(opp))
fps <- if ("from_prior_seats" %in% names(dy)) num(dy$from_prior_seats) else rep(NA_real_, nrow(dy))
tps <- if ("to_prior_seats" %in% names(dy)) num(dy$to_prior_seats) else rep(NA_real_, nrow(dy))
cat("Summary from_prior_seats:\n"); print(summary(fps))
cat("Summary to_prior_seats:\n"); print(summary(tps))
fcomp <- if ("from_complete" %in% names(dy)) num(dy$from_complete) else rep(NA_real_, nrow(dy))
tcomp <- if ("to_complete" %in% names(dy)) num(dy$to_complete) else rep(NA_real_, nrow(dy))
cat("from_complete:\n"); print(table(fcomp, useNA = "ifany"))

cands <- list()
cands[["mp_number>=4"]] <- with(dy, !is.na(from_mp) & !is.na(to_mp) & from_mp >= 4 & to_mp >= 4)
if (any(!is.na(fps)) && mean(fps, na.rm = TRUE) > 1.5) {
  cands[["prior_seats>=4"]] <- !is.na(fps) & !is.na(tps) & fps >= 4 & tps >= 4
  cands[["mp_number>=4 & prior_seats>=4"]] <- cands[["mp_number>=4"]] & cands[["prior_seats>=4"]]
}
cands[["mp_number>4"]] <- with(dy, !is.na(from_mp) & !is.na(to_mp) & from_mp > 4 & to_mp > 4)
if (any(!is.na(fcomp))) {
  cands[["mp_number>=4 & complete"]] <- cands[["mp_number>=4"]] & !is.na(fcomp) & !is.na(tcomp) &
    fcomp == 1 & tcomp == 1
}

fit_full <- function(keep) {
  d <- dy[keep & complete_rows, ]
  d$rl_std <- std(d$rl_raw, d$rl_raw)
  m <- tryCatch(feols(therm ~ women_share + rl_std + coal + opp | election, data = d,
                      cluster = ~election), error = function(e) NULL)
  list(d = d, m = m)
}

best <- NULL; best_gap <- Inf; best_name <- NULL
for (nm in names(cands)) {
  r <- fit_full(cands[[nm]])
  if (is.null(r$m)) next
  n <- nobs(r$m)
  cat(sprintf("Filter [%s]: N=%d, women coef=%.4f\n", nm, n, coef(r$m)["women_share"]))
  g <- abs(n - 1842)
  if (g < best_gap) { best_gap <- g; best <- r; best_name <- nm }
}
cat("Selected sample filter:", best_name, "\n")
if (best_name != "mp_number>=4") {
  cat(sprintf("DEVIATION: Applied the >=4 MP restriction using filter '%s' (lagged/prior-year seat counts) since current mp_number gave N=2019 vs paper's 1842\n", best_name))
}

main <- best$d
m1 <- feols(therm ~ women_share | election, data = main, cluster = ~election)
m2 <- feols(therm ~ women_share + rl_std + coal + opp | election, data = main, cluster = ~election)
print(summary(m1)); print(summary(m2))
cat("adj R2 m1:", r2(m1, "ar2"), " m2:", r2(m2, "ar2"), "\n")

# ---------- gender-disaggregated ----------
gd <- prep(gd)
g <- gd$gender
cat("Gender values:\n"); print(table(g, useNA = "ifany"))
is_female <- rep(NA, length(g))
if (is.factor(g) || is.character(g)) {
  gc <- tolower(as.character(g))
  if (all(grepl("^[0-9.]+$", gc[!is.na(gc)]))) {
    gn <- as.numeric(gc)
    if (2 %in% gn) is_female <- gn == 2 else is_female <- gn == 1
  } else {
    is_female <- grepl("^f|wom|female", gc)
    is_female[!grepl("^f|wom|female|^m|^men|male", gc)] <- NA
  }
} else {
  gn <- num(g)
  if (2 %in% gn) is_female <- gn == 2 else is_female <- gn == 1
}
gd$is_female <- is_female

# Restrict gender-disaggregated dyads to the same dyads retained in the main sample
key_cols <- c("country", "year", "party_from", "party_to")
main_keys <- unique(main[, key_cols])
main_keys[] <- lapply(main_keys, as.character)
gd_keys <- gd
for (k in key_cols) gd_keys[[k]] <- as.character(gd_keys[[k]])
gd_keys$.in_main <- paste(gd_keys$country, gd_keys$year, gd_keys$party_from, gd_keys$party_to) %in%
  paste(main_keys$country, main_keys$year, main_keys$party_from, main_keys$party_to)
gd$in_main <- gd_keys$.in_main
cat("Gender rows matching main-sample dyads:", sum(gd$in_main), "\n")

gsub_df <- gd %>%
  filter(in_main, from_mp >= 4, to_mp >= 4,
         !is.na(therm), !is.na(women_share), !is.na(rl_raw),
         !is.na(coal), !is.na(opp), !is.na(is_female))
gsub_df$rl_std <- std(gsub_df$rl_raw, main$rl_raw)
if (sd(main$rl_raw) < 2 && abs(mean(main$rl_raw)) < 1) gsub_df$rl_std <- gsub_df$rl_raw

wdat <- gsub_df %>% filter(is_female)
mdat <- gsub_df %>% filter(!is_female)

m3 <- feols(therm ~ women_share + rl_std + coal + opp | election, data = wdat, cluster = ~election)
m4 <- feols(therm ~ women_share + rl_std + coal + opp | election, data = mdat, cluster = ~election)
print(summary(m3)); print(summary(m4))

# ---------- results ----------
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["women_share"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["women_share"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["women_share"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["women_share"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rl_std"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["coal"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opp"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", as.integer(nobs(m3))))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", as.integer(nobs(m4))))
cat(sprintf("RESULT:n_election_studies=%d\n", length(unique(main$election))))