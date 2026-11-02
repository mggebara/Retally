suppressPackageStartupMessages({
  library(dplyr)
})
set.seed(42)

dd <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(dd, "data_agg.RData"))
load(file.path(dd, "survey_raw.RData"))

results <- list()
add_res <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- unname(val)
}

normparty <- function(x) gsub("[^a-z]", "", tolower(as.character(x)))
to_num <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

## =========================================================
## Barangay level (Table 1): ITT = WLS with IPW weights + city FE
## (equivalent to ri::estate with X = city dummies, prob = genprobexact)
## =========================================================
da <- as.data.frame(data.all)
da$city <- as.character(da$city)
da$barangay <- as.character(da$barangay)
da$assignment <- to_num(da$assignment)
da$treatment <- to_num(da$treatment)
da$pt <- normparty(da$partytreat)

for (v in c("turnout.party", "share.treated", "share.akbayan", "share.umalabka")) {
  da[[v]] <- to_num(da[[v]])
  if (max(da[[v]], na.rm = TRUE) <= 1) da[[v]] <- da[[v]] * 100
}

agg_itt <- function(var, sub) {
  d <- da[sub & !is.na(da[[var]]), , drop = FALSE]
  p <- ave(d$assignment, d$city, FUN = mean)
  w <- d$assignment / p + (1 - d$assignment) / (1 - p)
  df <- data.frame(y = d[[var]], z = d$assignment, city = factor(d$city), w = w)
  df <- df[is.finite(df$w), ]
  fit <- lm(y ~ z + city, data = df, weights = w)
  list(coef = unname(coef(fit)["z"]), n = nrow(d))
}

tryCatch({
  r1 <- agg_itt("turnout.party", rep(TRUE, nrow(da)))
  add_res("itt_turnout_barangay_table1_col1", r1$coef)
  r2 <- agg_itt("share.treated", rep(TRUE, nrow(da)))
  add_res("itt_vote_overall_barangay_table1_col2", r2$coef)
  add_res("n_obs_barangay_table1_cols1_2", r2$n)
  r3 <- agg_itt("share.akbayan", da$pt == "akbayan")
  add_res("itt_vote_akbayan_barangay_table1_col3", r3$coef)
  add_res("n_obs_barangay_akbayan_table1_col3", r3$n)
  r4 <- agg_itt("share.umalabka", da$pt == "umalabka")
  add_res("itt_vote_umalabka_barangay_table1_col4", r4$coef)
  add_res("n_obs_barangay_umalabka_table1_col4", r4$n)
}, error = function(e) message("Barangay-level error: ", conditionMessage(e)))

## =========================================================
## Individual level: build indices (survey_clean.R)
## =========================================================
s <- as.data.frame(survey_raw)
s$city <- as.character(s$city)
s$barangay <- as.character(s$barangay)
num_cols <- c("assignment", "treatment", "vote", "vote.akbayan", "vote.umalabka",
              "turnout_pl", "attendance", "femhouse", "fempol", "equality",
              "discrimination", "harassment", "poverty", "corruption", "gap", "cct")
for (cc in num_cols) if (cc %in% names(s)) s[[cc]] <- to_num(s[[cc]])
s$pt <- normparty(s$partytreat)

standard <- function(var, treat) {
  (var - mean(var, na.rm = TRUE)) / sd(var[which(treat == 0)], na.rm = TRUE)
}
icw_index <- function(M) {
  cc <- complete.cases(M)
  Mc <- M[cc, , drop = FALSE]
  Sig <- cov(Mc)
  w <- solve(Sig, rep(1, ncol(Mc)))
  w <- w / sum(w)
  out <- rep(NA_real_, nrow(M))
  out[cc] <- as.vector(Mc %*% w)
  out
}

s$femhouse.est <- standard(s$femhouse, s$treatment)
s$fempol.est <- standard(s$fempol, s$treatment)
s$equality.est <- standard(s$equality, s$treatment)
s$discrimination.est <- standard(s$discrimination, s$treatment)
s$harassment.est <- standard(s$harassment, s$treatment)
s$sexism <- icw_index(cbind(s$femhouse.est, s$fempol.est, s$equality.est,
                            s$discrimination.est, s$harassment.est))

s$poverty.est <- standard(s$poverty, s$treatment)
s$corruption.est <- standard(s$corruption, s$treatment)
s$gap.est <- standard(s$gap, s$treatment)
s$cct.est <- standard(s$cct, s$treatment)
s$poverty.all <- icw_index(cbind(s$poverty.est, s$cct.est, s$gap.est, s$corruption.est))

## =========================================================
## Attendance weights (self-reported vs sign-in sheets)
## =========================================================
normname <- function(x) {
  x <- as.character(x)
  x <- iconv(x, to = "ASCII//TRANSLIT")
  x[is.na(x)] <- ""
  x <- tolower(x)
  x <- gsub("barangay|brgy\\.?|city of|city", " ", x)
  x <- gsub("\\bsta\\b", "santa", x)
  x <- gsub("\\bsto\\b", "santo", x)
  x <- gsub("[^a-z0-9]", "", x)
  x
}
sdist <- function(a, b) {
  if (nchar(a) == 0 || nchar(b) == 0) return(1)
  if (grepl(a, b, fixed = TRUE) || grepl(b, a, fixed = TRUE)) return(0.05)
  as.numeric(adist(a, b)) / max(nchar(a), nchar(b))
}

s$weight.att <- NA_real_
tryCatch({
  sagg <- s %>%
    group_by(city, barangay) %>%
    summarise(obs = n(),
              att = sum(attendance, na.rm = TRUE),
              treat = max(treatment, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(attendance.agg = att / obs * 100) %>%
    filter(treat == 1)

  off <- da[da$treatment == 1, c("city", "barangay", "att.prop")]
  off$att.prop <- to_num(off$att.prop) * 100
  off$nb <- normname(off$barangay)
  off$nc <- normname(off$city)

  sagg$weight.att <- NA_real_
  for (k in seq_len(nrow(sagg))) {
    nb <- normname(sagg$barangay[k]); nc <- normname(sagg$city[k])
    db <- sapply(off$nb, function(o) sdist(nb, o))
    dc <- sapply(off$nc, function(o) sdist(nc, o))
    score <- db + 0.5 * dc
    j <- which.min(score)
    if (length(j) == 1 && db[j] <= 0.6) {
      sagg$weight.att[k] <- ifelse(sagg$attendance.agg[k] > 0,
                                   off$att.prop[j] / sagg$attendance.agg[k], 1)
    }
  }
  s <- s %>% select(-weight.att) %>%
    left_join(sagg %>% select(city, barangay, weight.att), by = c("city", "barangay"))
}, error = function(e) message("Weight construction error: ", conditionMessage(e)))
s$weight.att <- ifelse(s$treatment == 0, 1, s$weight.att)

ind_itt <- function(var, party, wvar) {
  d <- s[s$pt == party, c(var, "barangay", "assignment", "treatment", "city", wvar)]
  d <- d[complete.cases(d), ]
  df <- data.frame(y = d[[var]], z = d$assignment, city = factor(d$city), w = d[[wvar]])
  fit <- lm(y ~ z + city, data = df, weights = w)
  unname(coef(fit)["z"])
}

## Tables C.3 and C.4 (weighted attitude indices)
tryCatch(add_res("itt_poverty_index_akbayan_tableC3", ind_itt("poverty.all", "akbayan", "weight.att")),
         error = function(e) message("C3 akbayan: ", conditionMessage(e)))
tryCatch(add_res("itt_poverty_index_umalabka_tableC3", ind_itt("poverty.all", "umalabka", "weight.att")),
         error = function(e) message("C3 umalabka: ", conditionMessage(e)))
tryCatch(add_res("itt_gender_index_akbayan_tableC4", ind_itt("sexism", "akbayan", "weight.att")),
         error = function(e) message("C4 akbayan: ", conditionMessage(e)))
tryCatch(add_res("itt_gender_index_umalabka_tableC4", ind_itt("sexism", "umalabka", "weight.att")),
         error = function(e) message("C4 umalabka: ", conditionMessage(e)))

## =========================================================
## Table F.1 (unweighted for attendance; assignment-probability weights)
## =========================================================
tryCatch({
  bl <- unique(s[!is.na(s$assignment), c("city", "barangay", "assignment")])
  pc <- tapply(bl$assignment, bl$city, mean)
  s$probs.assign <- unname(pc[s$city])
  s$weight.assign <- s$assignment / s$probs.assign + (1 - s$assignment) / (1 - s$probs.assign)
  s$weight.assign[!is.finite(s$weight.assign)] <- NA
  s$vote100 <- s$vote * 100
  s$vote.akbayan100 <- s$vote.akbayan * 100

  d <- s[, c("vote100", "barangay", "city", "assignment", "treatment", "weight.assign")]
  d <- d[complete.cases(d), ]
  fit <- lm(vote100 ~ assignment + factor(city), data = d, weights = weight.assign)
  add_res("itt_vote_overall_unweighted_tableF1_col2", unname(coef(fit)["assignment"]))

  d <- s[s$pt == "akbayan", c("vote.akbayan100", "barangay", "city", "assignment", "treatment", "weight.assign")]
  d <- d[complete.cases(d), ]
  fit <- lm(vote.akbayan100 ~ assignment + factor(city), data = d, weights = weight.assign)
  add_res("itt_vote_akbayan_unweighted_tableF1_col3", unname(coef(fit)["assignment"]))
}, error = function(e) message("F1 error: ", conditionMessage(e)))

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10)))
}