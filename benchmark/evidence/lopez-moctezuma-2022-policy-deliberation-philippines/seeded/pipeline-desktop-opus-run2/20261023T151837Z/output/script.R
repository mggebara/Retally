suppressPackageStartupMessages({
  library(dplyr)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines"

results <- list()
add_result <- function(name, value) {
  results[[name]] <<- value
}

tonum <- function(x) {
  if (is.factor(x)) return(suppressWarnings(as.numeric(as.character(x))))
  suppressWarnings(as.numeric(unclass(x)))
}

norm_party <- function(x) tolower(gsub("[^A-Za-z]", "", as.character(x)))

## ------------------------------------------------------------------
## Barangay-level analysis (Table 1)
## ------------------------------------------------------------------
load(file.path(base_dir, "data_agg.RData"))  # creates data.all
data.all <- as.data.frame(data.all)
data.all$assignment <- tonum(data.all$assignment)
data.all$treatment <- tonum(data.all$treatment)
data.all$city <- as.character(data.all$city)
data.all$barangay <- as.character(data.all$barangay)
data.all$party.norm <- norm_party(data.all$partytreat)

agg_vars <- c("turnout.party", "share.treated", "share.akbayan", "share.umalabka")
agg_names <- c("itt_turnout_barangay_table1_col1",
               "itt_vote_overall_barangay_table1_col2",
               "itt_vote_akbayan_barangay_table1_col3",
               "itt_vote_umalabka_barangay_table1_col4")
agg_n <- list()

for (i in seq_along(agg_vars)) {
  tryCatch({
    v <- agg_vars[i]
    data.all[[v]] <- tonum(data.all[[v]])
    if (v %in% c("turnout.party", "share.treated")) {
      data.reg <- data.all[!is.na(data.all[[v]]), ]
    } else if (v == "share.akbayan") {
      data.reg <- data.all[!is.na(data.all[[v]]) & data.all$party.norm == "akbayan", ]
    } else {
      data.reg <- data.all[!is.na(data.all[[v]]) & data.all$party.norm == "umalabka", ]
    }
    ## exact treatment probability within block (city), clusters = barangays
    data.reg <- data.reg %>%
      group_by(city) %>%
      mutate(prob = sum(assignment) / n()) %>%
      ungroup() %>%
      as.data.frame()
    data.reg$w <- data.reg$assignment / data.reg$prob +
      (1 - data.reg$assignment) / (1 - data.reg$prob)
    data.reg$cityf <- factor(data.reg$city)
    data.reg$y <- data.reg[[v]]
    fit <- lm(y ~ assignment + cityf, weights = w, data = data.reg)
    add_result(agg_names[i], unname(coef(fit)["assignment"]))
    agg_n[[v]] <- nrow(data.reg)
  }, error = function(e) message("Barangay model failed for ", agg_vars[i], ": ", conditionMessage(e)))
}

if (!is.null(agg_n[["share.treated"]])) {
  add_result("n_obs_barangay_table1_cols1_2", agg_n[["share.treated"]])
} else if (!is.null(agg_n[["turnout.party"]])) {
  add_result("n_obs_barangay_table1_cols1_2", agg_n[["turnout.party"]])
}
if (!is.null(agg_n[["share.akbayan"]])) add_result("n_obs_barangay_akbayan_table1_col3", agg_n[["share.akbayan"]])
if (!is.null(agg_n[["share.umalabka"]])) add_result("n_obs_barangay_umalabka_table1_col4", agg_n[["share.umalabka"]])

## ------------------------------------------------------------------
## Individual-level data: build indices (survey_clean.R)
## ------------------------------------------------------------------
load(file.path(base_dir, "survey_raw.RData"))  # creates survey_raw
sv <- as.data.frame(survey_raw)

num_cols <- c("assignment", "treatment", "vote", "vote.akbayan", "vote.umalabka",
              "turnout_pl", "attendance", "femhouse", "fempol", "equality",
              "discrimination", "harassment", "poverty", "corruption", "gap", "cct")
for (cc in num_cols) if (cc %in% names(sv)) sv[[cc]] <- tonum(sv[[cc]])
sv$city <- as.character(sv$city)
sv$barangay <- as.character(sv$barangay)
sv$party.norm <- norm_party(sv$partytreat)

standard <- function(var, treat) {
  (var - mean(var, na.rm = TRUE)) / sd(var[treat == 0], na.rm = TRUE)
}
icw_index <- function(mat) {
  cc <- complete.cases(mat)
  mc <- mat[cc, , drop = FALSE]
  sigma <- cov(mc)
  si <- solve(sigma)
  wv <- colSums(si)
  out <- rep(NA_real_, nrow(mat))
  out[cc] <- as.numeric(mc %*% wv) / sum(wv)
  out
}

sv$femhouse.est <- standard(sv$femhouse, sv$treatment)
sv$fempol.est <- standard(sv$fempol, sv$treatment)
sv$equality.est <- standard(sv$equality, sv$treatment)
sv$discrimination.est <- standard(sv$discrimination, sv$treatment)
sv$harassment.est <- standard(sv$harassment, sv$treatment)
sv$sexism <- icw_index(cbind(sv$femhouse.est, sv$fempol.est, sv$equality.est,
                             sv$discrimination.est, sv$harassment.est))

sv$poverty.est <- standard(sv$poverty, sv$treatment)
sv$corruption.est <- standard(sv$corruption, sv$treatment)
sv$gap.est <- standard(sv$gap, sv$treatment)
sv$cct.est <- standard(sv$cct, sv$treatment)
sv$poverty.all <- icw_index(cbind(sv$poverty.est, sv$cct.est, sv$gap.est, sv$corruption.est))

## ------------------------------------------------------------------
## Attendance weights (survey self-reported vs. official attendance)
## ------------------------------------------------------------------
norm_name <- function(x) {
  x <- tolower(as.character(x))
  x <- iconv(x, to = "ASCII//TRANSLIT")
  x <- gsub("\\bsta\\.?\\b", "santa", x)
  x <- gsub("\\bsto\\.?\\b", "santo", x)
  x <- gsub("\\bbrgy\\.?\\b|\\bbarangay\\b|\\bcity\\b|\\bof\\b", "", x)
  x <- gsub("[^a-z0-9]", "", x)
  x
}
sdist <- function(a, b) {
  if (nchar(a) == 0 || nchar(b) == 0) return(1)
  if (grepl(a, b, fixed = TRUE) || grepl(b, a, fixed = TRUE)) return(0)
  as.numeric(adist(a, b)) / max(nchar(a), nchar(b))
}

survey.agg <- sv %>%
  group_by(city, barangay) %>%
  summarise(obs = n(),
            attendance = sum(attendance, na.rm = TRUE),
            treat.s = max(treatment, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(attendance.agg = attendance / obs * 100) %>%
  as.data.frame()

official.t <- data.all[data.all$treatment == 1, ]
official.t$att.prop100 <- tonum(official.t$att.prop) * 100
off_b <- norm_name(official.t$barangay)
off_c <- norm_name(official.t$city)

survey.agg$weight.att <- NA_real_
st <- which(survey.agg$treat.s == 1)
for (k in st) {
  sb <- norm_name(survey.agg$barangay[k])
  sc <- norm_name(survey.agg$city[k])
  d <- sapply(seq_len(nrow(official.t)), function(j) sdist(sb, off_b[j]) + 0.5 * sdist(sc, off_c[j]))
  j <- which.min(d)
  if (length(j) == 1 && d[j] < 0.9) {
    ap <- official.t$att.prop100[j]
    survey.agg$weight.att[k] <- ifelse(survey.agg$attendance.agg[k] > 0,
                                       ap / survey.agg$attendance.agg[k], 1)
  }
}

sv <- left_join(sv, survey.agg[, c("city", "barangay", "weight.att")],
                by = c("city", "barangay"))
sv$weight.att <- ifelse(sv$treatment == 0, 1, sv$weight.att)

## ------------------------------------------------------------------
## Attitude indices ITT (Tables C.3 and C.4)
## ------------------------------------------------------------------
fit_itt <- function(dat, yvar, wvar) {
  d <- dat[, c(yvar, "barangay", "assignment", "treatment", "city", wvar)]
  d <- d[complete.cases(d), ]
  d$y <- d[[yvar]]
  d$w <- d[[wvar]]
  d$cityf <- factor(d$city)
  fit <- lm(y ~ assignment + cityf, weights = w, data = d)
  list(coef = unname(coef(fit)["assignment"]), n = nrow(d))
}

party_list <- c(akbayan = "akbayan", umalabka = "umalabka")
for (p in names(party_list)) {
  dp <- sv[sv$party.norm == party_list[p], ]
  tryCatch({
    r <- fit_itt(dp, "poverty.all", "weight.att")
    add_result(paste0("itt_poverty_index_", p, "_tableC3"), r$coef)
  }, error = function(e) message("Poverty index failed (", p, "): ", conditionMessage(e)))
  tryCatch({
    r <- fit_itt(dp, "sexism", "weight.att")
    add_result(paste0("itt_gender_index_", p, "_tableC4"), r$coef)
  }, error = function(e) message("Gender index failed (", p, "): ", conditionMessage(e)))
}

## ------------------------------------------------------------------
## Unweighted (assignment-probability weighted) results (Table F.1)
## ------------------------------------------------------------------
sv2 <- sv
bar_assign <- sv2 %>%
  filter(!is.na(assignment)) %>%
  group_by(city, barangay) %>%
  summarise(a = max(assignment), .groups = "drop") %>%
  group_by(city) %>%
  summarise(probs.assign = sum(a) / n(), .groups = "drop")
sv2 <- left_join(sv2, bar_assign, by = "city")
sv2$weight.assign <- (sv2$assignment / sv2$probs.assign) +
  ((1 - sv2$assignment) / (1 - sv2$probs.assign))
sv2$weight.assign[!is.finite(sv2$weight.assign)] <- NA

sv2$vote <- sv2$vote * 100
sv2$vote.akbayan <- sv2$vote.akbayan * 100

tryCatch({
  r <- fit_itt(sv2, "vote", "weight.assign")
  add_result("itt_vote_overall_unweighted_tableF1_col2", r$coef)
}, error = function(e) message("F.1 vote failed: ", conditionMessage(e)))

tryCatch({
  r <- fit_itt(sv2[sv2$party.norm == "akbayan", ], "vote.akbayan", "weight.assign")
  add_result("itt_vote_akbayan_unweighted_tableF1_col3", r$coef)
}, error = function(e) message("F.1 vote akbayan failed: ", conditionMessage(e)))

## ------------------------------------------------------------------
## Output
## ------------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}