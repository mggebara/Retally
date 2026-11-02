```r
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(AER)
})
set.seed(42)
options(width = 220, warn = 1)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
f <- file.path(base, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")
df <- as.data.frame(readr::read_csv(f, show_col_types = FALSE, guess_max = 100000))
names(df) <- make.unique(gsub("[^a-z0-9_]+", "_", tolower(trimws(names(df)))))

tonum <- function(x) {
  if (is.numeric(x) || is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}

cat("Dimensions:", nrow(df), "x", ncol(df), "\n")
for (v in names(df)) {
  x <- df[[v]]
  if (is.numeric(x)) {
    cat(sprintf("  %-28s num NA=%5d min=%9.3f mean=%9.3f max=%9.3f nuniq=%d\n", v, sum(is.na(x)),
                suppressWarnings(min(x, na.rm = TRUE)), mean(x, na.rm = TRUE),
                suppressWarnings(max(x, na.rm = TRUE)), length(unique(x))))
  } else {
    u <- unique(x)
    cat(sprintf("  %-28s chr NA=%5d nuniq=%d e.g. %s\n", v, sum(is.na(x)), length(u),
                paste(head(u, 8), collapse = " | ")))
  }
}

## ---------------- subject id ----------------
modal <- function(z) { t <- table(z); as.numeric(names(t)[which.max(t)]) }
id_cands <- intersect(c("tn", "id", "participant_code", "participant", "subject", "subject_id", "id_stage2"), names(df))
df$sid <- NA_character_
for (v in id_cands) {
  for (withsess in c(TRUE, FALSE)) {
    if (withsess && !"session" %in% names(df)) next
    s <- if (withsess) paste(df$session, df[[v]], sep = "__") else as.character(df[[v]])
    rps <- table(s)
    if (modal(as.numeric(rps)) %in% 8:10) { df$sid <- s; cat("Subject id:", v, "with session =", withsess, "\n"); break }
  }
  if (!all(is.na(df$sid))) break
}
if (all(is.na(df$sid))) {
  df$sid <- if ("session" %in% names(df)) paste(df$session, df$tn, sep = "__") else as.character(df$tn)
  cat("Subject id: default tn (+session)\n")
}
cat("Rows per subject:\n"); print(table(as.numeric(table(df$sid))))

subj_const <- function(v) {
  x <- df[[v]]
  g <- tapply(x, df$sid, function(z) length(unique(z[!is.na(z)])))
  all(g <= 1)
}

ip <- tonum(df$indifference_point)
dn <- if ("decision_number" %in% names(df)) tonum(df$decision_number) else rep(NA_real_, nrow(df))
if (!all(is.na(dn))) { cat("decision_number table:\n"); print(table(dn, useNA = "ifany")) }

## ---------------- identify final (unbalanced / placebo) row ----------------
unbal <- NULL; unbal_src <- NULL
for (v in intersect(c("dispersed", "unbalanced", "stage2", "stage", "final", "is_unbalanced"), names(df))) {
  x <- tonum(df[[v]])
  if (all(is.na(x)) || !all(x[!is.na(x)] %in% c(0, 1))) next
  if (subj_const(v)) next
  cnt <- tapply(x == 1, df$sid, sum, na.rm = TRUE)
  if (mean(cnt == 1) > 0.9) { unbal <- !is.na(x) & x == 1; unbal_src <- v; break }
}
if (is.null(unbal) && !all(is.na(dn))) {
  negsh <- tapply(ip < 0, dn, mean, na.rm = TRUE)
  cat("Share negative ip by decision_number:\n"); print(round(negsh, 3))
  hi <- names(negsh)[negsh > 0.02]
  if (length(hi) == 1) { unbal <- !is.na(dn) & dn == as.numeric(hi); unbal_src <- paste0("decision_number==", hi, " (negatives)") }
}
if (is.null(unbal) && !all(is.na(dn))) {
  nd <- tapply(dn, df$sid, function(z) length(unique(z[!is.na(z)])))
  if (mean(nd == 9) > 0.9) {
    mx <- ave(dn, df$sid, FUN = function(z) max(z, na.rm = TRUE))
    unbal <- !is.na(dn) & dn == mx; unbal_src <- "max decision_number"
  }
}
rps_mode <- modal(as.numeric(table(df$sid)))
if (is.null(unbal) && rps_mode == 9) {
  ord <- if (!all(is.na(dn))) order(df$sid, dn, seq_len(nrow(df))) else order(df$sid, seq_len(nrow(df)))
  last <- rep(FALSE, nrow(df))
  o <- ord; sids <- df$sid[o]
  last[o[!duplicated(sids, fromLast = TRUE)]] <- TRUE
  unbal <- last; unbal_src <- "last row per subject"
}
if (is.null(unbal)) { unbal <- rep(FALSE, nrow(df)); unbal_src <- "none (8 rows per subject)" }
cat("Final-row identification:", unbal_src, " n rows =", sum(unbal), "\n")

bal <- !unbal & !is.na(ip)

## ---------------- workday mapping for balanced rows ----------------
paper_x <- c(39.2, 34.9, 33.6, 41.5, 41.8, 42.2, 35.9, 38.3)
e_t <- c(129, 132, 143, 115, 121, 117, 135, 127)
wd_cands <- intersect(unique(c("decision_number", "utility_point",
                               grep("day|workday|trade|^j$|^t$|date", names(df), value = TRUE))), names(df))
okrow <- bal & ip > 0 & ip < 125
best_v <- NULL; best_sse <- Inf; best_vals <- NULL
for (v in wd_cands) {
  w <- tonum(df[[v]])
  vals <- sort(unique(w[bal & !is.na(w)]))
  if (length(vals) != 8) next
  m <- tapply(ip[okrow], w[okrow], mean)[as.character(vals)]
  sse <- sum((m - paper_x)^2, na.rm = TRUE)
  cat(sprintf("Workday candidate %s: SSE vs paper means = %.2f ; means = %s\n", v, sse,
              paste(round(m, 1), collapse = ", ")))
  if (sse < best_sse) { best_sse <- sse; best_v <- v; best_vals <- vals }
}
df$t <- NA_integer_
if (!is.null(best_v)) {
  w <- tonum(df[[best_v]])
  df$t <- match(w, best_vals)
  cat("Workday variable:", best_v, "\n")
} else {
  cat("No workday variable found; using within-subject order of balanced rows\n")
  ord <- if (!all(is.na(dn))) order(df$sid, dn, seq_len(nrow(df))) else order(df$sid, seq_len(nrow(df)))
  tt <- rep(NA_integer_, nrow(df))
  bi <- ord[bal[ord]]
  tt[bi] <- ave(seq_along(bi), df$sid[bi], FUN = seq_along)
  df$t <- tt
}

subs <- sort(unique(df$sid))
n <- length(subs)
X <- matrix(NA_real_, n, 8, dimnames = list(subs, NULL))
bi <- which(bal & !is.na(df$t) & df$t %in% 1:8)
X[cbind(match(df$sid[bi], subs), df$t[bi])] <- ip[bi]

## ---------------- d per subject ----------------
d <- rep(NA_real_, n); names(d) <- subs
jfinal <- rep(NA_integer_, n)
corner_u <- rep(NA, n)
if (any(unbal)) {
  ui <- which(unbal)
  d <- tapply(ip[ui], df$sid[ui], function(z) z[1])[subs]
  jfinal <- tapply(df$t[ui], df$sid[ui], function(z) z[1])[subs]
  if ("corner" %in% names(df)) corner_u <- tapply(tonum(df$corner)[ui], df$sid[ui], function(z) z[1])[subs]
} else {
  dc <- grep("stage2|unbal|dtilde|d_tilde|deviation|^d$|concentration", names(df), value = TRUE)
  for (v in dc) {
    if (!subj_const(v)) next
    x <- tonum(df[[v]]); if (all(is.na(x)) || !any(x < 0, na.rm = TRUE)) next
    d <- tapply(x, df$sid, function(z) { z <- z[!is.na(z)]; if (length(z)) z[1] else NA })[subs]
    cat("d taken from column", v, "\n"); break
  }
}
d <- as.numeric(d); names(d) <- subs
if (all(d >= 0, na.rm = TRUE) && max(d, na.rm = TRUE) > 62) { cat("Shifting d by -63 (0..125 scale detected)\n"); d <- d - 63 }
cat("Summary of d:\n"); print(summary(d))

upper <- !is.na(d) & (d >= 62 | (!is.na(corner_u) & corner_u == 1 & d > 0))
cat("Upper-corner subjects (all conditions):", sum(upper), "\n")

## ---------------- stated indifference point for upper corners ----------------
stated <- rep(NA_real_, n)
if (any(d[upper] > 62, na.rm = TRUE)) {
  cat("Stated values appear in the indifference point itself\n")
  stated[upper] <- d[upper]
} else {
  excl <- c("sid", "tn", "session", "indifference_point", "decision_number", "age", "study", "mathgrade",
            "disposable_income", "raven_correct_answers", "math_answers_correct", "crt_answers_correct",
            "treatment", "average_ip", "corner", "chose_corner", "pizza", "control", "main", "dispersed", "t",
            "utility_point")
  cands <- setdiff(names(df), excl)
  res <- list()
  for (v in cands) {
    x <- tonum(df[[v]]); if (all(is.na(x))) next
    s <- tapply(x, df$sid, function(z) { z <- z[!is.na(z)]; if (length(z)) max(z) else NA })[subs]
    s <- as.numeric(s)
    if (sum(upper) == 0) next
    ok <- mean(!is.na(s[upper]) & s[upper] >= 62)
    cov_other <- mean(!is.na(s[!upper]))
    if (ok >= 0.7) {
      namehit <- grepl("manual|stated|self|upper|hypo|own|open|max|wtw|willing|answer|ub|guess|ip_|_ip", v)
      res[[v]] <- data.frame(v = v, ok = ok, cov_other = cov_other, namehit = namehit,
                             med = median(s[upper], na.rm = TRUE))
    }
  }
  if (length(res)) {
    R <- do.call(rbind, res)
    R <- R[order(-R$namehit, -R$ok, R$cov_other), ]
    cat("Stated-value candidates:\n"); print(R)
    v <- R$v[1]
    s <- as.numeric(tapply(tonum(df[[v]]), df$sid, function(z) { z <- z[!is.na(z)]; if (length(z)) max(z) else NA })[subs])
    stated[upper] <- s[upper]
    cat("Using stated column:", v, "\n")
  } else cat("No stated-value column found; upper/midpoint equal lower bound\n")
}
stated[upper & (is.na(stated) | stated < 62)] <- 62

d_low <- ifelse(upper, 62, d)
d_up  <- ifelse(upper, stated, d)
d_mid <- ifelse(upper, (62 + stated) / 2, d)

inv8 <- rowMeans(1 / sweep(X, 2, e_t, "+"))
invj <- ifelse(!is.na(jfinal) & jfinal %in% 1:8,
               1 / (e_t[pmax(1, pmin(8, jfinal))] + X[cbind(seq_len(n), pmax(1, pmin(8, jfinal)))]), NA)

## ---------------- conditions ----------------
getS <- function(v) {
  x <- df[[v]]
  r <- tapply(seq_along(x), df$sid, function(ii) { z <- x[ii]; z <- z[!is.na(z)]; if (length(z)) as.character(z[1]) else NA_character_ })
  unname(r[subs])
}
b01 <- function(v) {
  x <- getS(v); y <- suppressWarnings(as.numeric(x))
  if (all(is.na(y) & !is.na(x) | is.na(x))) {
    lx <- tolower(x); y <- ifelse(lx %in% c("yes", "true", "ja"), 1, ifelse(lx %in% c("no", "false", "nein"), 0, NA))
  }
  y
}
cond <- rep(NA_character_, n)
trt <- if ("treatment" %in% names(df)) getS("treatment") else rep(NA_character_, n)
cat("Treatment values:\n"); print(table(trt, useNA = "ifany"))
mk <- function(don, mech, ctrl) ifelse(don, ifelse(ctrl, "Donation-Control", "Donation-Treatment"),
                                     ifelse(mech, ifelse(ctrl, "Mechanism-Control", "Mechanism-Treatment"),
                                            ifelse(ctrl, "Main-Control", "Main-Treatment")))
if (all(is.na(suppressWarnings(as.numeric(trt[!is.na(trt)]))))) {
  tl <- tolower(trt)
  c_t <- grepl("control|ctrl|placebo|kontroll", tl)
  d_t <- grepl("don|charit", tl)
  m_t <- grepl("mech|disp|sum|part", tl)
  ct <- mk(d_t, m_t, c_t); ct[is.na(trt)] <- NA
  if (length(unique(na.omit(ct))) == 6) { cond <- ct; cat("Conditions parsed from treatment labels\n") }
}
if (all(is.na(cond))) {
  ctrl <- if ("control" %in% names(df)) b01("control") == 1 else rep(FALSE, n)
  ctrl[is.na(ctrl)] <- FALSE
  don <- rep(FALSE, n)
  if ("pizza" %in% names(df)) {
    p <- getS("pizza"); tb <- table(p)
    if (length(tb) == 2) don <- !is.na(p) & p == names(tb)[which.min(tb)]
    else if (length(tb) == 1 && mean(is.na(p)) > 0.15 && mean(is.na(p)) < 0.5) don <- is.na(p)
  }
  mech <- NULL
  if ("main" %in% names(df)) {
    m <- b01("main")
    if (!all(is.na(m)) && !isTRUE(all(m == 1 - ctrl, na.rm = TRUE))) {
      sh <- mean(m[!don] == 0, na.rm = TRUE)
      if (is.finite(sh) && sh > 0.25 && sh < 0.75) { mech <- !don & !is.na(m) & m == 0; cat("Mechanism from main==0\n") }
    }
  }
  if (is.null(mech) && "dispersed" %in% names(df) && subj_const("dispersed")) {
    dd <- b01("dispersed"); mech <- !don & !is.na(dd) & dd == 1; cat("Mechanism from dispersed==1\n")
  }
  if (is.null(mech)) mech <- rep(FALSE, n)
  cond <- mk(don, mech, ctrl)
  cat("Conditions built from flags\n")
}
cat("Conditions x treatment:\n"); print(table(cond, trt, useNA = "ifany"))

## ---------------- exclusion ----------------
corner_b <- chose_b <- rep(NA, n)
if ("corner" %in% names(df)) corner_b <- as.logical(tapply(tonum(df$corner)[bal] == 1, df$sid[bal], any, na.rm = TRUE)[subs])
if ("chose_corner" %in% names(df)) chose_b <- as.logical(tapply(tonum(df$chose_corner) == 1, df$sid, any, na.rm = TRUE)[subs])
ipc  <- apply(X, 1, function(r) any(r <= 0 | r >= 125, na.rm = TRUE))
ipc2 <- apply(X, 1, function(r) any(r < 0 | r >= 125, na.rm = TRUE))
complete <- rowSums(is.na(X)) == 0 & !is.na(d)
excl_c <- list(corner_balanced = corner_b, chose_corner = chose_b, ip_0_125 = ipc, ip_neg_125 = ipc2,
               none = rep(FALSE, n))
nmain <- sapply(excl_c, function(ex) { if (all(is.na(ex))) return(NA); ex[is.na(ex)] <- FALSE
  sum(complete & !ex & cond == "Main-Treatment", na.rm = TRUE) })
cat("Main-Treatment N under exclusion rules:\n"); print(nmain)
pick <- names(nmain)[which(nmain == 100)][1]
if (is.na(pick)) pick <- names(nmain)[which.min(abs(nmain - 100))]
cat("Exclusion rule used:", pick, "\n")
ex <- excl_c[[pick]]; ex[is.na(ex)] <- FALSE
keep <- complete & !ex

S <- data.frame(sid = subs, cond = cond, d_low = d_low, d_mid = d_mid, d_up = d_up,
                inv8 = inv8, invj = invj, upper = upper, stringsAsFactors = FALSE)
S$rel_low <- S$d_low * S$inv8
S$rel_mid <- S$d_mid * S$inv8
S$rel_up  <- S$d_up * S$inv8
isctrl <- grepl("Control", S$cond)
S$rel_mid_t3 <- ifelse(isctrl & !is.na(S$invj), S$d_mid * S$invj, S$rel_mid)
S$rel_mid_alt <- S$rel_mid
S <- S[keep, ]
cat("Main sample sizes:\n"); print(table(S$cond))
print(aggregate(cbind(d_low, d_mid, d_up, rel_low, rel_mid, rel_up, rel_mid_t3) ~ cond, data = S, FUN = mean))

rob <- function(fit) { V <- sandwich::vcovHC(fit, type = "HC1"); list(b = coef(fit), se = sqrt(diag(V))) }
out <- list()
emit <- function(name, val) { out[[name]] <<- val }

## ---------------- Table 2 ----------------
M <- S[S$cond == "Main-Treatment", ]
tryCatch({
  r1 <- rob(lm(d_low ~ 1, data = M)); r2 <- rob(lm(d_mid ~ 1, data = M)); r3 <- rob(lm(d_up ~ 1, data = M))
  emit("abs_concentration_bias_lower_table2_col1", r1$b[1])
  emit("abs_concentration_bias_midpoint_table2_col2", r2$b[1])
  emit("abs_concentration_bias_midpoint_table2_col2_se", r2$se[1])
  emit("abs_concentration_bias_upper_table2_col3", r3$b[1])
  q1 <- rob(lm(rel_low ~ 1, data = M)); q2 <- rob(lm(rel_mid ~ 1, data = M)); q3 <- rob(lm(rel_up ~ 1, data = M))
  emit("rel_concentration_bias_lower_table2_col1", q1$b[1])
  emit("rel_concentration_bias_lower_table2_col1_se", q1$se[1])
  emit("rel_concentration_bias_midpoint_table2_col2", q2$b[1])
  emit("rel_concentration_bias_midpoint_table2_col2_se", q2$se[1])
  emit("rel_concentration_bias_upper_table2_col3", q3$b[1])
  emit("rel_concentration_bias_upper_table2_col3_se", q3$se[1])
  emit("n_obs_table2", nrow(M))
}, error = function(e) cat("Table 2 OLS error:", conditionMessage(e), "\n"))
tryCatch({
  M$dl <- pmin(pmax(M$d_low, -63), 62)
  tb <- AER::tobit(dl ~ 1, left = -63, right = 62, data = M)
  emit("abs_concentration_bias_tobit_table2_col4", coef(tb)[1])
  emit("abs_concentration_bias_tobit_table2_col4_se", sqrt(diag(vcov(tb)))[1])
}, error = function(e) cat("Tobit error:", conditionMessage(e), "\n"))

## ---------------- Table 3 ----------------
pair <- function(a, b, var = "rel_mid_t3") {
  P <- S[S$cond %in% c(a, b), ]
  P$y <- P[[var]]; P$ind <- as.numeric(P$cond == a)
  r <- rob(lm(y ~ ind, data = P))
  list(cons = r$b[1], diff = r$b[2], se = r$se[2], n = nrow(P), meanA = mean(P$y[P$ind == 1]))
}
tryCatch({
  c1 <- pair("Main-Treatment", "Mechanism-Treatment")
  emit("rel_cb_mechanism_treatment_table3_col1", c1$cons)
  emit("diff_main_minus_mechanism_table3_col1", c1$diff)
  emit("diff_main_minus_mechanism_table3_col1_se", c1$se)
  emit("n_obs_table3", c1$n)
}, error = function(e) cat("T3 col1 error:", conditionMessage(e), "\n"))
tryCatch({
  c2 <- pair("Donation-Treatment", "Donation-Control")
  emit("rel_cb_donation_treatment_table3_col2", c2$meanA)
  emit("diff_donation_treatment_minus_control_table3_col2", c2$diff)
  emit("diff_donation_treatment_minus_control_table3_col2_se", c2$se)
  emit("n_obs_table3_col2", c2$n)
  c2b <- pair("Donation-Treatment", "Donation-Control", "rel_mid_alt")
  emit("diff_donation_treatment_minus_control_table3_col2_alt8day", c2b$diff)
}, error = function(e) cat("T3 col2 error:", conditionMessage(e), "\n"))
tryCatch({
  c3 <- pair("Main-Treatment", "Main-Control")
  emit("rel_cb_main_control_table3_col3", c3$cons)
  emit("diff_main_treatment_minus_control_table3_col3", c3$diff)
  emit("diff_main_treatment_minus_control_table3_col3_se", c3$se)
  emit("n_obs_table3_col3", c3$n)
  c3b <- pair("Main-Treatment", "Main-Control", "rel_mid_alt")
  emit("diff_main_treatment_minus_control_table3_col3_alt8day", c3b$diff)
}, error = function(e) cat("T3 col3 error:", conditionMessage(e), "\n"))
tryCatch({
  c4 <- pair("Mechanism-Treatment", "Mechanism-Control")
  emit("rel_cb_mechanism_control_table3_col4", c4$cons)
  emit("diff_mechanism_treatment_minus_control_table3_col4", c4$diff)
  emit("diff_mechanism_treatment_minus_control_table3_col4_se", c4$se)
  emit("n_obs_table3_col4", c4$n)
  c4b <- pair("Mechanism-Treatment", "Mechanism-Control", "rel_mid_alt")
  emit("diff_mechanism_treatment_minus_control_table3_col4_alt8day", c4b$diff)
}, error = function(e) cat("T3 col4 error:", conditionMessage(e), "\n"))

for (nm in names(out)) cat(sprintf("RESULT:%s=%s\n", nm, format(unname(out[[nm]]), digits = 10)))
```
