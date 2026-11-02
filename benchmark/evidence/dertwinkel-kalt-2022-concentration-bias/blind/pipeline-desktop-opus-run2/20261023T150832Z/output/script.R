suppressPackageStartupMessages({
  library(readr)
  library(sandwich)
  library(AER)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
path <- file.path(base, "Consumption Experiment/Stata/Consumption_Experiment.csv")
df <- as.data.frame(read_csv(path, show_col_types = FALSE, guess_max = 100000))
names(df) <- trimws(names(df))
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")
cat("Columns:", paste(names(df), collapse = ", "), "\n")

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
has <- function(v) v %in% names(df)

e_vec <- c(129, 132, 143, 115, 121, 117, 135, 127)

# ---------------- subject id ----------------
if (has("session")) {
  df$sid <- paste(df$session, df$tn, sep = "_")
} else {
  df$sid <- as.character(df$tn)
}
df$ip <- num(df$indifference_point)
df$dn <- if (has("decision_number")) num(df$decision_number) else ave(seq_len(nrow(df)), df$sid, FUN = seq_along)
df$disp <- if (has("dispersed")) num(df$dispersed) else NA
df$cc <- if (has("chose_corner")) num(df$chose_corner) else NA
df$crn <- if (has("corner")) num(df$corner) else NA
df$.row <- seq_len(nrow(df))

cat("Rows per subject table:\n"); print(table(table(df$sid)))
for (v in c("dispersed", "decision_number", "corner", "chose_corner", "pizza", "control", "main", "treatment", "utility_point")) {
  if (has(v)) { cat("Values of", v, ":\n"); print(head(sort(table(df[[v]], useNA = "ifany"), decreasing = TRUE), 20)) }
}

# ---------------- identify final (stage 2) row per subject ----------------
spl <- split(df$.row, df$sid)
final_row <- sapply(spl, function(r) {
  d <- df$disp[r]
  if (!all(is.na(d)) && sum(d == 1, na.rm = TRUE) == 1 && length(r) > 1) return(r[which(d == 1)])
  n <- df$dn[r]
  mx <- which(n == max(n, na.rm = TRUE))
  if (length(mx) == 1) return(r[mx])
  r[length(r)]
})
df$is_final <- df$.row %in% final_row
df$is_bal <- !df$is_final
cat("Final rows:", sum(df$is_final), " balanced rows:", sum(df$is_bal), "\n")

# ---------------- map balanced rows to workday t ----------------
bal <- df[df$is_bal, ]
excl <- c("tn", "session", "sid", "ip", "dn", "disp", "cc", "crn", ".row", "is_final", "is_bal",
          "indifference_point", "average_ip", "age")
ecol <- NULL
for (col in setdiff(names(df), excl)) {
  v <- num(bal[[col]])
  if (all(!is.na(v)) && all(v %in% e_vec) && length(unique(v)) == 8) { ecol <- col; break }
}
idxcol <- NULL; idx_off <- 0
if (is.null(ecol)) {
  cand <- c()
  for (col in setdiff(names(df), excl)) {
    v <- num(bal[[col]])
    if (any(is.na(v))) next
    for (off in c(0, 1)) {
      vv <- v + off
      if (all(vv %in% 1:8)) {
        ok <- tapply(vv, bal$sid, function(z) length(z) == 8 && all(sort(z) == 1:8))
        if (mean(ok) > 0.95) cand <- rbind(cand, data.frame(col = col, off = off, stringsAsFactors = FALSE))
      }
    }
  }
  cat("Index candidates:\n"); print(cand)
  if (!is.null(cand) && nrow(cand) > 0) {
    pri <- grepl("trade|workday|^day|day_|_day|^j$|^t$|index", tolower(cand$col))
    if (any(pri)) k <- which(pri)[1] else if (any(cand$col == "dn")) k <- which(cand$col == "dn")[1] else k <- 1
    idxcol <- cand$col[k]; idx_off <- cand$off[k]
  }
}
if (!is.null(ecol)) {
  df$e_t <- NA; df$e_t[df$is_bal] <- num(bal[[ecol]])
  cat("Using mandatory-task column:", ecol, "\n")
} else if (!is.null(idxcol)) {
  df$e_t <- NA; df$e_t[df$is_bal] <- e_vec[num(bal[[idxcol]]) + idx_off]
  cat("Using trade-off index column:", idxcol, " offset", idx_off, "\n")
} else {
  df$e_t <- NA
  df$e_t[df$is_bal] <- e_vec[pmin(pmax(ave(df$dn[df$is_bal], df$sid[df$is_bal], FUN = function(z) rank(z, ties.method = "first")), 1), 8)]
  cat("DEVIATION: no trade-off index found; mapping by order of decision_number\n")
}

# ---------------- manual (self-stated) indifference point ----------------
known <- c("tn", "dispersed", "age", "study", "mathgrade", "disposable_income", "raven_correct_answers",
           "math_answers_correct", "crt_answers_correct", "session", "treatment", "average_ip",
           "decision_number", "corner", "chose_corner", "indifference_point", "pizza", "control", "main", "id_stage2")
mcands <- setdiff(names(df)[grepl("manual|stated|self|unincent|hypo|open|state|guess|upper|max", tolower(names(df)))], known)
mcands <- setdiff(mcands, c("sid", "ip", "dn", "disp", "cc", "crn", ".row", "is_final", "is_bal", "e_t"))
cat("Manual IP candidates:", paste(mcands, collapse = ", "), "\n")

# ---------------- subject-level dataset ----------------
fin <- df[df$is_final, ]
dfin <- fin$ip
if (min(dfin, na.rm = TRUE) >= 0 && max(dfin, na.rm = TRUE) > 62) {
  cat("DEVIATION: final indifference points look 0-125 coded; subtracting 63\n")
  dfin <- dfin - 63
}
names(dfin) <- fin$sid
cat("Summary final d:\n"); print(summary(dfin))

subj_val <- function(col, s) {
  r <- spl[[s]]
  v <- num(df[[col]][r])
  fv <- num(df[[col]][final_row[s]])
  if (!is.na(fv)) return(fv)
  v <- v[!is.na(v)]
  if (length(v)) v[1] else NA
}

sids <- names(spl)
S <- data.frame(sid = sids, stringsAsFactors = FALSE)
S$d <- dfin[sids]
S$cc_final <- df$cc[final_row[sids]]
S$up <- !is.na(S$d) & (S$d >= 62 | (!is.na(S$cc_final) & S$cc_final == 1 & S$d > 0))

mcol <- NULL
for (col in c(mcands, if (has("utility_point")) "utility_point")) {
  mv <- sapply(sids, function(s) subj_val(col, s))
  mv_up <- mv[S$up]
  if (sum(!is.na(mv_up)) >= 0.7 * sum(S$up) && sum(S$up) > 0 && median(mv_up, na.rm = TRUE) >= 50) {
    mcol <- col; S$manual <- mv; break
  }
}
if (is.null(mcol)) {
  S$manual <- NA
  cat("DEVIATION: no self-stated indifference point column found; upper bound = lower bound\n")
} else cat("Using manual IP column:", mcol, "\n")

# conditions
getsub <- function(col) if (has(col)) sapply(sids, function(s) { v <- df[[col]][spl[[s]]]; v[!is.na(v)][1] }) else rep(NA, length(sids))
trt <- getsub("treatment"); pz <- num(getsub("pizza")); ctl <- num(getsub("control")); mn <- num(getsub("main"))
lab <- tolower(as.character(trt))
mechcol <- names(df)[grepl("mech", tolower(names(df)))]
if (any(grepl("mech", lab, fixed = TRUE))) {
  S$mech <- grepl("mech", lab); S$don <- grepl("don|char", lab); S$ctrl <- grepl("contr", lab)
  cat("Conditions from treatment labels\n")
} else {
  S$don <- !is.na(pz) & pz == 0
  S$ctrl <- !is.na(ctl) & ctl == 1
  if (length(mechcol) > 0) {
    S$mech <- num(getsub(mechcol[1])) == 1
  } else {
    S$mech <- !S$don & !is.na(mn) & mn == 0
  }
  cat("Conditions from flags (pizza/control/main)\n")
}
S$cond <- ifelse(S$don, ifelse(S$ctrl, "Donation-Control", "Donation-Treatment"),
           ifelse(S$mech, ifelse(S$ctrl, "Mechanism-Control", "Mechanism-Treatment"),
                  ifelse(S$ctrl, "Main-Control", "Main-Treatment")))
cat("Conditions (all subjects):\n"); print(table(S$cond))

# per-subject balanced info
S$x_ok <- TRUE
xb <- lapply(sids, function(s) { r <- spl[[s]]; r <- r[df$is_bal[r]]; list(x = df$ip[r], e = df$e_t[r], cc = df$cc[r], crn = df$crn[r]) })
names(xb) <- sids
ruleA <- sapply(xb, function(z) any(!is.na(z$cc) & z$cc == 1))
ruleB <- sapply(xb, function(z) any(!is.na(z$crn) & z$crn == 1))
ruleB2 <- sapply(sids, function(s) any(!is.na(df$crn[spl[[s]]]) & df$crn[spl[[s]]] == 1))
ruleC <- sapply(xb, function(z) any(is.na(z$x) | z$x >= 125 | z$x < 0))
ruleD <- sapply(xb, function(z) any(is.na(z$x) | z$x >= 125 | z$x <= 0))
rules <- list(A = ruleA, B = ruleB, B2 = ruleB2, C = ruleC, D = ruleD)
nmt <- sapply(rules, function(rl) sum(!rl & S$cond == "Main-Treatment"))
cat("Main-Treatment N under exclusion rules:\n"); print(nmt)
valid <- sapply(rules, function(rl) any(rl))
dist <- abs(nmt - 100); dist[!valid] <- dist[!valid] + 1000
chosen <- names(rules)[which.min(dist)]
cat("Chosen exclusion rule:", chosen, "\n")
S$excl <- rules[[chosen]]
M <- S[!S$excl, ]
cat("Main sample by condition:\n"); print(table(M$cond))

# measures
M$d_lb <- ifelse(M$up, 62, M$d)
M$d_ub <- ifelse(M$up & !is.na(M$manual), M$manual, M$d_lb)
M$d_mid <- ifelse(M$up & !is.na(M$manual), (62 + M$manual) / 2, M$d_lb)
relf <- function(dv) sapply(seq_len(nrow(M)), function(i) { z <- xb[[M$sid[i]]]; mean(dv[i] / (z$e + z$x)) })
M$rel_lb <- relf(M$d_lb); M$rel_mid <- relf(M$d_mid); M$rel_ub <- relf(M$d_ub)
cat("Upper corners in main sample:", sum(M$up), "\n")

olsm <- function(y) { m <- lm(y ~ 1); c(coef(m)[1], sqrt(diag(vcovHC(m, type = "HC1")))[1]) }
MT <- M[M$cond == "Main-Treatment", ]
r_abs_mid <- olsm(MT$d_mid)
r_rel_lb <- olsm(MT$rel_lb); r_rel_mid <- olsm(MT$rel_mid); r_rel_ub <- olsm(MT$rel_ub)
yt <- pmin(pmax(MT$d_lb, -63), 62)
tb <- tobit(yt ~ 1, left = -63, right = 62)
tb_coef <- coef(tb)[1]
cat("abs mid:", r_abs_mid, " rel lb:", r_rel_lb, " rel mid:", r_rel_mid, " rel ub:", r_rel_ub, " tobit:", tb_coef, "\n")

pairreg <- function(a, b) {
  # a = condition whose indicator is included; b = base (constant)
  d <- M[M$cond %in% c(a, b), ]
  d$ind <- as.numeric(d$cond == a)
  m <- lm(rel_mid ~ ind, data = d)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))
  list(const = unname(coef(m)[1]), diff = unname(coef(m)[2]), se = se, n = nrow(d))
}
c1 <- pairreg("Main-Treatment", "Mechanism-Treatment")
c2a <- pairreg("Donation-Treatment", "Donation-Control")
c2_mean <- olsm(M$rel_mid[M$cond == "Donation-Treatment"])[1]
c3 <- pairreg("Main-Treatment", "Main-Control")
c4 <- pairreg("Mechanism-Treatment", "Mechanism-Control")
cat("Table 3 N:", c1$n, c2a$n, c3$n, c4$n, "\n")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", r_abs_mid[1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", tb_coef))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", r_rel_lb[1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", r_rel_mid[1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", r_rel_ub[1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(MT)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", c1$const))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", c1$diff))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", c2_mean))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", c2a$diff))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", c3$diff))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", c4$diff))
cat(sprintf("RESULT:n_obs_table3=%d\n", c1$n))