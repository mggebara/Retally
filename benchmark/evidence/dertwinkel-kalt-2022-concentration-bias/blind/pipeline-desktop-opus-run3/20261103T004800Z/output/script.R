suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(AER)
})
set.seed(42)

root <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
path <- file.path(root, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")
df <- as.data.frame(read_csv(path, show_col_types = FALSE, guess_max = 100000))
names(df) <- tolower(names(df))
msg <- function(...) message(paste0(...))
msg("Columns: ", paste(names(df), collapse = ", "))
msg(paste(capture.output(str(df, list.len = 200)), collapse = "\n"))

tonum <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.character(x)) {
    lx <- tolower(trimws(x))
    if (all(lx %in% c("true", "false", NA, ""))) return(as.numeric(lx == "true"))
    return(suppressWarnings(as.numeric(x)))
  }
  as.numeric(x)
}
has <- function(v) v %in% names(df)

for (v in c("dispersed", "decision_number", "indifference_point", "corner", "chose_corner",
            "pizza", "control", "main", "average_ip", "utility_point")) {
  if (has(v)) df[[v]] <- tonum(df[[v]])
}

# ---------------- subject id ----------------
nd <- length(unique(df$decision_number))
cnt <- table(df$tn)
if (max(cnt) > nd && has("session")) {
  df$sid <- paste(df$session, df$tn, sep = "_")
} else {
  df$sid <- as.character(df$tn)
}
msg("Subjects: ", length(unique(df$sid)), "; rows per subject: ",
    paste(names(table(table(df$sid))), collapse = ","))

# ---------------- conditions ----------------
cond <- rep(NA_character_, nrow(df))
ctrl <- rep(NA, nrow(df))
if (has("treatment") && is.character(df$treatment)) {
  t <- tolower(df$treatment)
  msg("treatment values: ", paste(unique(df$treatment), collapse = " | "))
  isdon <- grepl("don", t); ismech <- grepl("mech", t); isctrl <- grepl("contr", t)
  if (any(isdon | ismech | isctrl)) {
    cond <- ifelse(isdon, "Donation", ifelse(ismech, "Mechanism", "Main"))
    ctrl <- isctrl
  }
}
if (all(is.na(cond))) {
  if (has("pizza")) {
    cond <- ifelse(!is.na(df$pizza) & df$pizza == 0, "Donation",
                   ifelse(has("main") & !is.na(df$main) & df$main == 0, "Mechanism", "Main"))
  } else {
    cond <- "Main"
  }
}
if (all(is.na(ctrl))) {
  if (has("control")) {
    ctrl <- !is.na(df$control) & df$control == 1
  } else if (has("treatment")) {
    ctrl <- tonum(df$treatment) == 0
  } else ctrl <- FALSE
}
df$cond <- cond
df$ctrl <- ctrl
msg(paste(capture.output(print(table(df$cond, df$ctrl, useNA = "ifany"))), collapse = "\n"))
if (has("treatment")) msg(paste(capture.output(print(table(df$treatment, df$cond, useNA = "ifany"))), collapse = "\n"))

# ---------------- final vs balanced rows ----------------
df <- df %>% group_by(sid) %>%
  mutate(maxdn = max(decision_number, na.rm = TRUE),
         disp_var = if (has("dispersed")) n_distinct(dispersed[!is.na(dispersed)]) > 1 else FALSE,
         any_disp = if (has("dispersed")) any(dispersed == 1, na.rm = TRUE) else FALSE) %>%
  ungroup() %>% as.data.frame()
df$final <- ifelse(df$disp_var & df$any_disp,
                   !is.na(df$dispersed) & df$dispersed == 1,
                   df$decision_number == df$maxdn)
# keep only one final row per subject (max decision number among final candidates)
df <- df %>% group_by(sid) %>%
  mutate(final = final & decision_number == max(decision_number[final], na.rm = TRUE)) %>%
  ungroup() %>% as.data.frame()
df$final[is.na(df$final)] <- FALSE

e <- c(129, 132, 143, 115, 121, 117, 135, 127)

# workday index for balanced rows
bal <- df[!df$final, ]
daycol <- NULL
cands <- grep("^(work)?day$|^workday|^j$|tradeoff|trade_off|^t$|^day_", names(df), value = TRUE)
for (cc in cands) {
  v <- tonum(bal[[cc]])
  if (all(v %in% 1:8) && length(unique(v)) == 8) { daycol <- cc; break }
}
if (!is.null(daycol)) {
  bal$t <- tonum(bal[[daycol]])
} else {
  bal <- bal %>% group_by(sid) %>% mutate(t = rank(decision_number, ties.method = "first")) %>%
    ungroup() %>% as.data.frame()
}
msg("Workday column used: ", ifelse(is.null(daycol), "rank(decision_number)", daycol))
bal <- bal[bal$t %in% 1:8, ]

# subject-level balanced info
subj <- bal %>% group_by(sid) %>%
  summarise(cond = first(cond), ctrl = first(ctrl),
            nbal = n(),
            xbar = mean(indifference_point, na.rm = TRUE),
            avg_ip = if (has("average_ip")) first(average_ip) else NA_real_,
            cornA = if (has("corner")) as.numeric(any(corner == 1, na.rm = TRUE)) else NA_real_,
            cornA_const = if (has("corner")) n_distinct(corner) == 1 else FALSE,
            cornB = if (has("chose_corner")) as.numeric(any(chose_corner == 1, na.rm = TRUE)) else NA_real_,
            minx = min(indifference_point, na.rm = TRUE),
            maxx = max(indifference_point, na.rm = TRUE),
            .groups = "drop") %>% as.data.frame()
X <- matrix(NA_real_, nrow(subj), 8)
for (i in seq_len(nrow(bal))) {
  r <- match(bal$sid[i], subj$sid)
  X[r, bal$t[i]] <- bal$indifference_point[i]
}
msg("Check xbar vs average_ip (mean abs diff): ", mean(abs(subj$xbar - subj$avg_ip), na.rm = TRUE))

# final row info
fin <- df[df$final, ]
subj$ipf <- fin$indifference_point[match(subj$sid, fin$sid)]
subj$ccf <- if (has("chose_corner")) fin$chose_corner[match(subj$sid, fin$sid)] else NA
# stated value column for upper corners
known <- c("tn", "dispersed", "age", "study", "mathgrade", "disposable_income", "raven_correct_answers",
           "math_answers_correct", "crt_answers_correct", "session", "treatment", "average_ip",
           "decision_number", "utility_point", "corner", "chose_corner", "indifference_point",
           "pizza", "control", "main", "id_stage2", "sid", "cond", "ctrl", "maxdn", "disp_var",
           "any_disp", "final")
statcands <- grep("stat|manual|open|upper|self|report|corner_|wtp|max", setdiff(names(df), known), value = TRUE)
msg("Stated-value candidates: ", paste(statcands, collapse = ", "))
stated <- rep(NA_real_, nrow(subj))
for (cc in statcands) {
  v <- tonum(fin[[cc]])[match(subj$sid, fin$sid)]
  if (sum(!is.na(v)) > 0 && any(v > 62, na.rm = TRUE)) { stated <- v; msg("Using stated column: ", cc); break }
}

# control repeated-decision index j (values in {1,4,8})
jcol <- NULL
finc <- fin[fin$ctrl %in% TRUE, ]
if (nrow(finc) > 0) {
  for (cc in setdiff(names(fin), c("sid", "cond", "ctrl", "final", "maxdn"))) {
    v <- tonum(finc[[cc]])
    if (sum(!is.na(v)) > 0.9 * nrow(finc) && all(v[!is.na(v)] %in% c(1, 4, 8)) &&
        length(unique(v[!is.na(v)])) >= 2) { jcol <- cc; break }
  }
}
msg("Control j column: ", ifelse(is.null(jcol), "none", jcol))
subj$j <- if (!is.null(jcol)) tonum(fin[[jcol]])[match(subj$sid, fin$sid)] else NA

# control final ip: deviation or level?
ci <- subj$ctrl %in% TRUE
if (any(ci) && all(subj$ipf[ci] >= 0, na.rm = TRUE) && !is.null(jcol) &&
    mean(subj$ipf[ci], na.rm = TRUE) > 25) {
  msg("Control final ip looks like a level; converting to deviation from x_j")
  for (r in which(ci)) if (!is.na(subj$j[r])) subj$ipf[r] <- subj$ipf[r] - X[r, subj$j[r]]
}

# ---------------- proxies for upper corner ----------------
up <- (!is.na(subj$ipf) & subj$ipf >= 62) |
  (!is.na(subj$ccf) & subj$ccf == 1 & !is.na(subj$ipf) & subj$ipf > 0)
upval <- ifelse(!is.na(stated), stated, ifelse(subj$ipf > 62, subj$ipf, 62))
subj$up <- up
subj$d_low <- ifelse(up, 62, subj$ipf)
subj$d_upp <- ifelse(up, pmax(upval, 62), subj$ipf)
subj$d_mid <- (subj$d_low + subj$d_upp) / 2
msg("Upper corners: ", sum(up, na.rm = TRUE))

relfun <- function(d) {
  out <- numeric(nrow(subj))
  for (r in seq_len(nrow(subj))) {
    if (isTRUE(subj$ctrl[r]) && !is.na(subj$j[r])) {
      out[r] <- d[r] / (e[subj$j[r]] + X[r, subj$j[r]])
    } else {
      out[r] <- mean(d[r] / (e + X[r, ]))
    }
  }
  out
}
subj$rel_low <- relfun(subj$d_low)
subj$rel_mid <- relfun(subj$d_mid)
subj$rel_upp <- relfun(subj$d_upp)

# ---------------- exclusion rule ----------------
ismainT <- subj$cond == "Main" & !(subj$ctrl %in% TRUE)
rules <- list()
if (has("corner") && all(subj$cornA_const)) rules$A <- subj$cornA == 1
if (has("corner")) rules$A2 <- subj$cornA == 1
if (has("chose_corner")) rules$B <- subj$cornB == 1
gmin <- min(bal$indifference_point, na.rm = TRUE); gmax <- max(bal$indifference_point, na.rm = TRUE)
rules$C <- subj$minx <= gmin | subj$maxx >= gmax
rules$D <- rep(FALSE, nrow(subj))
best <- NULL; bestdist <- Inf
for (nm in names(rules)) {
  ex <- rules[[nm]]; ex[is.na(ex)] <- FALSE
  n <- sum(ismainT & !ex & !is.na(subj$ipf))
  msg("Rule ", nm, ": Main-Treatment n = ", n)
  if (abs(n - 100) < bestdist) { bestdist <- abs(n - 100); best <- nm }
}
msg("Chosen exclusion rule: ", best)
excl <- rules[[best]]; excl[is.na(excl)] <- FALSE
S <- subj[!excl & !is.na(subj$ipf) & apply(X, 1, function(z) all(!is.na(z))), ]
msg(paste(capture.output(print(table(S$cond, S$ctrl))), collapse = "\n"))

# ---------------- Table 2 ----------------
mT <- S[S$cond == "Main" & !(S$ctrl %in% TRUE), ]
olsc <- function(y) {
  m <- lm(y ~ 1)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))
  c(coef(m)[1], se[1])
}
res <- list()
r1 <- olsc(mT$d_mid); res$abs_concentration_bias_midpoint_table2_col2 <- r1[1]
msg("abs mid SE: ", r1[2])
left <- min(-63, min(mT$d_low, na.rm = TRUE))
tb <- tryCatch(AER::tobit(d_low ~ 1, left = left, right = 62, data = mT), error = function(e) NULL)
res$abs_concentration_bias_tobit_table2_col4 <- if (!is.null(tb)) coef(tb)[1] else NA
res$rel_concentration_bias_lower_table2_col1 <- olsc(mT$rel_low)[1]
res$rel_concentration_bias_midpoint_table2_col2 <- olsc(mT$rel_mid)[1]
res$rel_concentration_bias_upper_table2_col3 <- olsc(mT$rel_upp)[1]
res$n_obs_table2 <- nrow(mT)

# ---------------- Table 3 ----------------
pair <- function(a, b) {
  # a: indicator group (coefficient), b: baseline (constant)
  d <- rbind(cbind(a, ind = 1), cbind(b, ind = 0))
  m <- lm(rel_mid ~ ind, data = d)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))
  list(const = unname(coef(m)[1]), diff = unname(coef(m)[2]), n = nrow(d),
       se = se)
}
g <- function(cn, ct) S[S$cond == cn & ((S$ctrl %in% TRUE) == ct), ]
p1 <- pair(g("Main", FALSE), g("Mechanism", FALSE))
p2 <- pair(g("Donation", FALSE), g("Donation", TRUE))
p3 <- pair(g("Main", FALSE), g("Main", TRUE))
p4 <- pair(g("Mechanism", FALSE), g("Mechanism", TRUE))
res$rel_cb_mechanism_treatment_table3_col1 <- p1$const
res$diff_main_minus_mechanism_table3_col1 <- p1$diff
res$rel_cb_donation_treatment_table3_col2 <- mean(g("Donation", FALSE)$rel_mid)
res$diff_donation_treatment_minus_control_table3_col2 <- p2$diff
res$diff_main_treatment_minus_control_table3_col3 <- p3$diff
res$diff_mechanism_treatment_minus_control_table3_col4 <- p4$diff
msg("Table 3 n per column: ", p1$n, ", ", p2$n, ", ", p3$n, ", ", p4$n)
res$n_obs_table3 <- p1$n

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(unname(as.numeric(res[[nm]])), digits = 8)))
}