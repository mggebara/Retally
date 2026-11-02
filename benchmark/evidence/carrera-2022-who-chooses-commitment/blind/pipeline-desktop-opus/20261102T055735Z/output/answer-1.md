suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
raw <- haven::read_dta(f)
d <- as.data.frame(raw)
nm <- names(d)
cat("Columns:\n"); print(nm)

num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) x <- suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", x)))
  as.numeric(x)
}

rates <- c(1, 2, 3, 5, 7, 12)

# ---- detect forecast-at-piece-rate columns ----
find_forecast_prefix <- function(nm, d) {
  pref <- unique(sub("[0-9]+$", "", nm[grepl("[0-9]+$", nm)]))
  pref <- pref[!grepl("wtp|previsits|^days|slider|commit|past|percent", pref, ignore.case = TRUE)]
  ok <- pref[sapply(pref, function(p) all(paste0(p, rates) %in% nm))]
  if (length(ok) == 0) return(NA_character_)
  score <- sapply(ok, function(p) {
    v <- unlist(lapply(paste0(p, rates), function(k) num(d[[k]])))
    v <- v[!is.na(v)]
    s <- 0
    if (grepl("visit|exp|fore|pred|guess|belief", p, ignore.case = TRUE)) s <- s + 2
    if (length(v) > 0 && min(v) >= 0 && max(v) <= 28) s <- s + 3
    if (length(v) > 0) s <- s + length(v) / 1e6
    s
  })
  ok[which.max(score)]
}
fp <- find_forecast_prefix(nm, d)
cat("Forecast prefix:", fp, "\n")

wave <- num(d$wave)
treat <- num(d$treatment)
if (all(is.na(treat)) && "type_of_info" %in% nm) treat <- as.numeric(num(d$type_of_info) > 0)
treat[is.na(treat)] <- 0
treat <- as.numeric(treat > 0)

wtp <- sapply(rates, function(r) num(d[[paste0("wtp", r)]]))
colnames(wtp) <- paste0("w", rates)
if (!is.na(fp)) {
  fc <- sapply(rates, function(r) num(d[[paste0(fp, r)]]))
} else {
  fc <- matrix(NA_real_, nrow(d), length(rates))
}
colnames(fc) <- paste0("f", rates)

# conservative BCP: average over adjacent pairs above $1 ($1-2, 2-3, 3-5, 5-7, 7-12)
pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bcp_mat <- sapply(pairs, function(pr) {
  i <- match(pr[1], rates); j <- match(pr[2], rates)
  (wtp[, j] - wtp[, i]) / (pr[2] - pr[1]) - (fc[, j] + fc[, i]) / 2
})
bcp <- rowMeans(bcp_mat, na.rm = FALSE)

exp0 <- num(d$visits_next4weeks)
goal <- num(d$goal)
visits <- num(d$visits)
inc <- num(d$incentive)
inctext <- if ("incentivetext" %in% nm) tolower(as.character(haven::as_factor(d$incentivetext))) else rep("", nrow(d))
inctext[is.na(inctext)] <- ""
cat("Incentive table:\n"); print(table(inc, wave, useNA = "ifany"))
cat("Incentive text sample:\n"); print(head(table(inctext), 20))

is_commit <- grepl("commit|conditional|\\$80|80 ", inctext) | is.na(inc) | !(inc %in% c(0, rates))
# expected attendance under assigned incentive
exp_inc <- rep(NA_real_, nrow(d))
exp_inc[!is_commit & inc == 0] <- exp0[!is_commit & inc == 0]
for (k in seq_along(rates)) {
  s <- !is_commit & !is.na(inc) & inc == rates[k]
  exp_inc[s] <- fc[s, k]
}

flag <- if ("flag_exclude_exog" %in% nm) num(d$flag_exclude_exog) else rep(0, nrow(d))
flag[is.na(flag)] <- 0

df <- data.frame(id = seq_len(nrow(d)), wave = wave,
                 basic = treat * (wave == 1), enhanced = treat * (wave >= 2),
                 bcp = bcp, gme = goal - exp0, ame = visits - exp_inc,
                 commit = is_commit, flag = flag)

samp <- df %>% filter(flag == 0, !commit, !is.na(bcp), !is.na(gme), !is.na(ame), !is.na(wave))
z <- function(x) (x - mean(x)) / sd(x)
samp$bcp_z <- z(samp$bcp); samp$gme_z <- z(samp$gme); samp$ame_z <- z(samp$ame)
cat("Table 3 N:", nrow(samp), "\n")

getc <- function(m, v) tryCatch(unname(coef(m)[v]), error = function(e) NA_real_)
res <- list()
m1 <- tryCatch(feols(bcp ~ basic + enhanced | wave, data = samp, vcov = "hetero"), error = function(e) NULL)
m2 <- tryCatch(feols(bcp ~ basic + enhanced + gme_z | wave, data = samp, vcov = "hetero"), error = function(e) NULL)
m3 <- tryCatch(feols(bcp ~ basic + enhanced + ame_z | wave, data = samp, vcov = "hetero"), error = function(e) NULL)
if (!is.null(m1)) print(summary(m1))
res$bcp_basic_info_treatment_col1 <- getc(m1, "basic")
res$bcp_enhanced_info_treatment_col1 <- getc(m1, "enhanced")
res$bcp_goal_minus_expected_attendance_col2 <- getc(m2, "gme_z")
res$bcp_actual_minus_expected_attendance_col3 <- getc(m3, "ame_z")
res$bcp_regression_observations <- if (!is.null(m1)) nobs(m1) else nrow(samp)

# ---- Table 4: "more" commitment contracts ----
find_commit_col <- function(thr) {
  c1 <- paste0("chose_commit", thr)
  if (c1 %in% nm) return(c1)
  cand <- nm[grepl("commit", nm, ignore.case = TRUE) & grepl(paste0("(^|[^0-9])", thr, "($|[^0-9])"), nm) &
               !grepl("less|fewer|meet|percent|prob|lt|under|max", nm, ignore.case = TRUE)]
  if (length(cand)) cand[1] else NA_character_
}
long <- list()
for (thr in c(8, 12, 16)) {
  cc <- find_commit_col(thr)
  cat("Threshold", thr, "column:", cc, "\n")
  if (is.na(cc)) next
  v <- num(d[[cc]])
  uv <- sort(unique(v[!is.na(v)]))
  if (length(uv) == 2 && all(uv == c(1, 2))) v <- as.numeric(v == 1) else v <- as.numeric(v > 0)
  long[[length(long) + 1]] <- data.frame(id = seq_len(nrow(d)), thr = thr, choice = v)
}
long <- do.call(rbind, long)
L <- merge(samp[, c("id", "wave", "basic", "enhanced", "bcp_z", "gme_z", "ame_z")], long, by = "id")
L <- L[!is.na(L$choice), ]
cat("Table 4 N:", nrow(L), "\n")

t1 <- tryCatch(feols(choice ~ basic + enhanced | wave + thr, data = L, cluster = ~id), error = function(e) NULL)
t2 <- tryCatch(feols(choice ~ basic + enhanced + bcp_z | wave + thr, data = L, cluster = ~id), error = function(e) NULL)
t3 <- tryCatch(feols(choice ~ basic + enhanced + gme_z | wave + thr, data = L, cluster = ~id), error = function(e) NULL)
t4 <- tryCatch(feols(choice ~ basic + enhanced + ame_z | wave + thr, data = L, cluster = ~id), error = function(e) NULL)
if (!is.null(t1)) print(summary(t1))
res$takeup_more_basic_info_treatment_col1 <- getc(t1, "basic")
res$takeup_more_enhanced_info_treatment_col1 <- getc(t1, "enhanced")
res$takeup_more_behavior_change_premium_col2 <- getc(t2, "bcp_z")
res$takeup_more_goal_minus_expected_attendance_col3 <- getc(t3, "gme_z")
res$takeup_more_actual_minus_expected_attendance_col4 <- getc(t4, "ame_z")
res$takeup_more_regression_observations <- if (!is.null(t1)) nobs(t1) else nrow(L)

for (k in names(res)) cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 10)))
