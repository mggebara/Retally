suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

load(file.path(base, "dyadic_data_1-4-22.Rdata"))   # creates updated_data
dy <- as.data.frame(updated_data)
gd <- as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds")))

strip <- function(x) { if (inherits(x, "haven_labelled")) as.vector(x) else x }
dy[] <- lapply(dy, strip)

cat("INFO: dyadic columns:", paste(names(dy), collapse = ", "), "\n")

# ---------- locate the out-party women-share variable ----------
find_women_var <- function(d) {
  nm <- names(d)
  cand <- nm[grepl("^to_", nm) & grepl("wom|fem", nm, ignore.case = TRUE) &
             !grepl("leader|lead", nm, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) is.numeric(d[[v]]))]
  if (length(cand) == 0) {
    cand <- nm[grepl("wom|fem", nm, ignore.case = TRUE) &
               !grepl("^from_|leader|lead", nm, ignore.case = TRUE)]
    cand <- cand[sapply(cand, function(v) is.numeric(d[[v]]))]
  }
  cat("INFO: women-share candidates:", paste(cand, collapse = ", "), "\n")
  if (length(cand) == 0) stop("no women-share variable found")
  score <- sapply(cand, function(v) {
    s <- 0
    if (grepl("lag", v, ignore.case = TRUE)) s <- s + 3
    if (grepl("prop|share|pct|perc|per", v, ignore.case = TRUE)) s <- s + 2
    x <- d[[v]]
    mx <- suppressWarnings(max(x, na.rm = TRUE))
    if (is.finite(mx) && mx <= 1) s <- s + 2
    if (is.finite(mx) && mx <= 100 && mx > 1) s <- s + 1
    s
  })
  cand[which.max(score)]
}

# ---------- locate MP-count variables (prefer lagged, t-1) ----------
find_mp_var <- function(d, side) {
  nm <- names(d)
  cand <- nm[grepl(paste0("^", side, "_"), nm) &
             grepl("mp|seat", nm, ignore.case = TRUE) &
             !grepl("wom|fem|share|prop|pct|perc", nm, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) is.numeric(d[[v]]))]
  cat(sprintf("INFO: %s MP-count candidates: %s\n", side, paste(cand, collapse = ", ")))
  lagc <- cand[grepl("lag|_l$|t_1|tm1|prev", cand, ignore.case = TRUE)]
  if (length(lagc) > 0) return(lagc[1])
  if (paste0(side, "_mp_number") %in% names(d)) return(paste0(side, "_mp_number"))
  if (length(cand) > 0) return(cand[1])
  NA_character_
}

prep <- function(d, wv) {
  d$women_share <- as.numeric(d[[wv]])
  mx <- max(d$women_share, na.rm = TRUE)
  if (mx > 1 && mx <= 100) {
    if (mx > 1.5) d$women_share <- d$women_share / 100
  }
  if (max(d$women_share, na.rm = TRUE) > 1.5 && "to_mp_number" %in% names(d)) {
    d$women_share <- d$women_share / d$to_mp_number
  }
  d$dv <- as.numeric(d$party_like)
  if ("rile_distance_s" %in% names(d)) {
    d$rl <- as.numeric(d$rile_distance_s)
  } else {
    d$rl <- as.numeric(d$rile_distance)
  }
  d$coal <- as.numeric(d$govern_together)
  d$opp  <- as.numeric(d$opposition_together)
  d$election <- paste(d$country, d$year, sep = "_")
  tov <- find_mp_var(d, "to"); frv <- find_mp_var(d, "from")
  cat(sprintf("INFO: MP-count vars used: to=%s from=%s\n", tov, frv))
  d$to_mps   <- as.numeric(d[[tov]])
  d$from_mps <- as.numeric(d[[frv]])
  d
}

# Paper: both parties must have >= 4 MPs; if MP counts are not populated
# for a party, its seat count cannot be verified and the dyad is dropped.
# Also the out-party women share must be observed (it is the key regressor),
# and the in-party must be a party with an observed women share (i.e. it is
# in the 125-party women-MP dataset).
build_sample <- function(d, nm) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", nm, nrow(d)))
  cat(sprintf("INFO: %s to_mps range: %s; from_mps range: %s\n", nm,
              paste(range(d$to_mps, na.rm = TRUE), collapse = "-"),
              paste(range(d$from_mps, na.rm = TRUE), collapse = "-")))
  d <- d %>% filter(!is.na(to_mps), !is.na(from_mps), to_mps >= 4, from_mps >= 4)
  cat(sprintf("SAMPLE:%s:both_parties_at_least_4_mps=%d\n", nm, nrow(d)))
  d <- d %>% filter(!is.na(rl))
  cat(sprintf("SAMPLE:%s:nonmissing_cmp_positions=%d\n", nm, nrow(d)))
  d <- d %>% filter(!is.na(dv))
  cat(sprintf("SAMPLE:%s:nonmissing_partisan_ratings=%d\n", nm, nrow(d)))
  d <- d %>% filter(!is.na(women_share), !is.na(coal), !is.na(opp))
  cat(sprintf("SAMPLE:%s:nonmissing_women_share_controls=%d\n", nm, nrow(d)))
  # in-party must also have an observed women share (party in women-MP data)
  fw <- names(d)[grepl("^from_", names(d)) & grepl("wom|fem", names(d), ignore.case = TRUE) &
                 !grepl("leader|lead", names(d), ignore.case = TRUE)]
  fw <- fw[sapply(fw, function(v) is.numeric(d[[v]]))]
  if (length(fw) > 0) {
    n0 <- nrow(d)
    d <- d[!is.na(d[[fw[1]]]), ]
    cat(sprintf("SAMPLE:%s:inparty_women_share_observed=%d\n", nm, nrow(d)))
    if (nrow(d) < n0)
      cat(sprintf("DEVIATION: %s dropped %d dyads whose in-party lacks women-MP data (%s)\n",
                  nm, n0 - nrow(d), fw[1]))
  }
  # drop duplicate directed dyads within an election
  key_from <- intersect(c("from_party", "from_partyid", "from_cmp", "from_id", "from"), names(d))
  key_to   <- intersect(c("to_party", "to_partyid", "to_cmp", "to_id", "to"), names(d))
  if (length(key_from) > 0 && length(key_to) > 0) {
    n0 <- nrow(d)
    d <- d[!duplicated(d[, c("election", key_from[1], key_to[1])]), ]
    cat(sprintf("SAMPLE:%s:dedup_directed_dyads=%d\n", nm, nrow(d)))
    if (nrow(d) < n0)
      cat(sprintf("DEVIATION: %s dropped %d duplicate directed dyads\n", nm, n0 - nrow(d)))
  }
  d
}

wv <- find_women_var(dy)
cat("INFO: using women-share variable:", wv, "\n")
dy <- prep(dy, wv)

# ---------- main sample ----------
main <- build_sample(dy, "main")

sd_rl <- sd(main$rl, na.rm = TRUE)
cat(sprintf("INFO: rl distance mean=%.3f sd=%.3f\n", mean(main$rl), sd_rl))
if (abs(sd_rl - 1) > 0.15) {
  main$rl <- main$rl / sd_rl
}
rl_sd_ref <- if (abs(sd_rl - 1) > 0.15) sd_rl else 1

m1 <- feols(dv ~ women_share | election, data = main, cluster = ~election)
m2 <- feols(dv ~ women_share + rl + coal + opp | election, data = main, cluster = ~election)
cat(sprintf("SAMPLE:main:estimation=%d\n", nobs(m2)))
print(summary(m1)); print(summary(m2))
n_elec <- length(unique(main$election[obs(m2)]))

# ---------- gender-disaggregated samples ----------
gd[] <- lapply(gd, function(x) {
  if (inherits(x, "haven_labelled")) haven::as_factor(x) else x
})
cat("INFO: gender-data columns:", paste(names(gd), collapse = ", "), "\n")
wvg <- if (wv %in% names(gd)) wv else find_women_var(gd)
gd <- prep(gd, wvg)
if (!("rile_distance_s" %in% names(gd))) gd$rl <- gd$rl / rl_sd_ref

g <- gd$gender
cat("INFO: gender values:", paste(names(table(g, useNA = "ifany")), table(g, useNA = "ifany"),
                                 sep = "=", collapse = "; "), "\n")
gl <- tolower(as.character(g))
lev <- unique(gl[!is.na(gl)])
women_lev <- lev[grepl("^f|wom", lev)]
men_lev   <- lev[grepl("^m|^men", lev) & !grepl("wom", lev)]
if (length(women_lev) != 1 || length(men_lev) != 1) {
  if (all(lev %in% c("1", "2"))) { men_lev <- "1"; women_lev <- "2" }
  else if (all(lev %in% c("0", "1"))) { men_lev <- "0"; women_lev <- "1"
    cat("DEVIATION: gender coded 0/1 without labels; assuming 1 = female\n") }
  else stop("cannot identify gender coding")
}

run_gender <- function(levl, nm) {
  d <- gd[!is.na(gl) & gl == levl, ]
  d <- build_sample(d, nm)
  m <- feols(dv ~ women_share + rl + coal + opp | election, data = d, cluster = ~election)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, nobs(m)))
  print(summary(m))
  m
}
mw <- run_gender(women_lev, "women_partisans")
mm <- run_gender(men_lev, "men_partisans")

se <- function(m, v) sqrt(diag(vcov(m)))[v]

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["women_share"]))
cat(sprintf("RESULT:women_mps_se_bivariate=%.6f\n", se(m1, "women_share")))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["women_share"]))
cat(sprintf("RESULT:women_mps_se_full=%.6f\n", se(m2, "women_share")))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(mw)["women_share"]))
cat(sprintf("RESULT:women_mps_se_women_partisans=%.6f\n", se(mw, "women_share")))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(mm)["women_share"]))
cat(sprintf("RESULT:women_mps_se_men_partisans=%.6f\n", se(mm, "women_share")))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rl"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["coal"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opp"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(mw)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(mm)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_elec))