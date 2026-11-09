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

to_num <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

# ---- locate the out-party women share variable ----
find_women_var <- function(d) {
  nm <- names(d)
  low <- tolower(nm)
  cand <- nm[grepl("^to_|_to$|_to_", low) & grepl("wom|fem|female|women", low) &
               !grepl("leader|sq|squared|parity|above|below|interact|_x_|cent", low)]
  if (length(cand) == 0) {
    cand <- nm[grepl("wom|fem", low) & !grepl("^from_|from|leader|sq|squared|parity", low)]
  }
  if (length(cand) == 0) return(NULL)
  lc <- tolower(cand)
  # preference ordering: lagged share > share/prop > others; avoid counts unless needed
  score <- ifelse(grepl("lag", lc), 4, 0) +
           ifelse(grepl("prop|share|pct|perc|percent|ratio", lc), 2, 0) -
           ifelse(grepl("number|num|count|_n$", lc), 3, 0)
  cand <- cand[order(-score)]
  cat("Women-share candidates:", paste(cand, collapse = ", "), "\n")
  cand[1]
}

build_women_share <- function(d) {
  v <- find_women_var(d)
  if (is.null(v)) stop("No women-share variable found")
  x <- to_num(d[[v]])
  lv <- tolower(v)
  if (grepl("number|num|count|_n$", lv) && "to_mp_number" %in% names(d)) {
    x <- x / to_num(d$to_mp_number)
  } else if (isTRUE(max(x, na.rm = TRUE) > 1.0001)) {
    x <- x / 100
  }
  cat("Using women-share variable:", v, " range:",
      paste(round(range(x, na.rm = TRUE), 3), collapse = " - "), "\n")
  x
}

pick_dv <- function(d) {
  nm <- names(d)
  if ("party_like" %in% nm) return("party_like")
  c2 <- nm[grepl("therm|like", tolower(nm)) & !grepl("dislike", tolower(nm))]
  if (length(c2)) return(c2[1])
  stop("No DV found")
}

prep <- function(d) {
  d$women_share <- build_women_share(d)
  dvn <- pick_dv(d)
  cat("Using DV:", dvn, "\n")
  d$dv <- to_num(d[[dvn]])
  d$rile_raw <- abs(to_num(d$rile_distance))
  d$coal <- to_num(d$govern_together)
  d$opp  <- to_num(d$opposition_together)
  d$to_mp <- to_num(d$to_mp_number)
  d$from_mp <- to_num(d$from_mp_number)
  d$cy <- paste(d$country, d$year, sep = "_")
  d
}

dy <- prep(dy)

# Sample restriction: both parties >= 4 MPs (year before survey)
restrict <- function(d) {
  d %>% filter(!is.na(to_mp), !is.na(from_mp), to_mp >= 4, from_mp >= 4)
}
dyr <- restrict(dy)

std <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)

# Common sample for cols 1 and 2 (full model non-missing)
dyr <- dyr %>% filter(!is.na(dv), !is.na(women_share), !is.na(rile_raw),
                      !is.na(coal), !is.na(opp))
dyr$rile_std <- std(dyr$rile_raw)

m1 <- feols(dv ~ women_share | cy, data = dyr, cluster = ~cy)
m2 <- feols(dv ~ women_share + rile_std + coal + opp | cy, data = dyr, cluster = ~cy)
print(summary(m1)); print(summary(m2))

# ---- gender-disaggregated models ----
gd <- prep(gd)
gd <- restrict(gd)
g <- gd$gender
cat("Gender values:\n"); print(table(g, useNA = "ifany"))
if (is.factor(g) || is.character(g)) {
  gl <- tolower(as.character(g))
  is_w <- grepl("^f|wom|female", gl)
  is_m <- grepl("^m|^men|^male", gl) & !is_w
  if (!any(is_w)) {
    gn <- to_num(g); is_w <- gn %in% 2; is_m <- gn %in% 1
  }
} else {
  gn <- to_num(g)
  u <- sort(unique(gn[!is.na(gn)]))
  if (all(u %in% c(0, 1))) { is_w <- gn %in% 1; is_m <- gn %in% 0 }  # 1 = female
  else { is_w <- gn %in% 2; is_m <- gn %in% 1 }                       # CSES: 1 male, 2 female
}
is_w[is.na(is_w)] <- FALSE; is_m[is.na(is_m)] <- FALSE

fit_sub <- function(d) {
  d <- d %>% filter(!is.na(dv), !is.na(women_share), !is.na(rile_raw),
                    !is.na(coal), !is.na(opp))
  d$rile_std <- std(d$rile_raw)
  feols(dv ~ women_share + rile_std + coal + opp | cy, data = d, cluster = ~cy)
}
m3 <- fit_sub(gd[is_w, ])
m4 <- fit_sub(gd[is_m, ])
print(summary(m3)); print(summary(m4))

n_el <- length(unique(dyr$cy[obs(m2)]))

out <- function(name, val) cat(sprintf("RESULT:%s=%s\n", name, format(val, digits = 10)))
out("women_mps_coef_bivariate", unname(coef(m1)["women_share"]))
out("women_mps_coef_full", unname(coef(m2)["women_share"]))
out("women_mps_coef_women_partisans", unname(coef(m3)["women_share"]))
out("women_mps_coef_men_partisans", unname(coef(m4)["women_share"]))
out("right_left_distance_coef_full", unname(coef(m2)["rile_std"]))
out("coalition_partners_coef_full", unname(coef(m2)["coal"]))
out("opposition_partners_coef_full", unname(coef(m2)["opp"]))
out("n_directed_dyads", nobs(m2))
out("n_obs_women_partisans", nobs(m3))
out("n_obs_men_partisans", nobs(m4))
out("n_election_studies", n_el)