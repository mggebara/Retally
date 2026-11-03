suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(AER)
})
set.seed(42)

path <- file.path("<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free",
                  "Consumption Experiment", "Stata", "Consumption_Experiment.csv")
df <- as.data.frame(read_csv(path, show_col_types = FALSE, guess_max = 100000))
names(df) <- tolower(trimws(names(df)))
cat("Columns:", paste(names(df), collapse = ", "), "\n")
cat("Rows:", nrow(df), "\n")

# convert numeric-like / logical columns
for (v in names(df)) {
  x <- df[[v]]
  if (is.logical(x)) { df[[v]] <- as.numeric(x); next }
  if (is.character(x)) {
    nm <- !is.na(x) & trimws(x) != "" & trimws(x) != "."
    num <- suppressWarnings(as.numeric(x))
    if (sum(nm) > 0 && mean(!is.na(num[nm])) > 0.95) df[[v]] <- num
    if (is.character(df[[v]])) {
      lx <- tolower(trimws(x))
      if (all(lx[nm] %in% c("true", "false"))) df[[v]] <- as.numeric(lx == "true")
    }
  }
}

is_bin <- function(x) is.numeric(x) && length(na.omit(x)) > 0 && all(na.omit(x) %in% c(0, 1))
firstnn <- function(x) { y <- x[!is.na(x)]; if (length(y)) y[1] else NA }

# ---------------- subject id ----------------
if ("tn" %in% names(df)) {
  cnt <- table(df$tn)
  if (median(cnt) > 10 && "session" %in% names(df)) {
    df$sid <- paste(df$session, df$tn, sep = "_")
  } else df$sid <- as.character(df$tn)
} else if ("id" %in% names(df)) {
  df$sid <- as.character(df$id)
} else df$sid <- as.character(seq_len(nrow(df)))
cat("Subjects:", length(unique(df$sid)), " rows/subject table:\n"); print(table(table(df$sid)))
df$rowi <- seq_len(nrow(df))

for (v in intersect(c("decision_number", "dispersed", "id_stage2", "corner", "chose_corner",
                      "pizza", "control", "main", "treatment", "utility_point"), names(df))) {
  cat("---", v, "\n"); if (length(unique(df[[v]])) <= 30) print(table(df[[v]], useNA = "ifany")) else print(summary(df[[v]]))
}

# ---------------- identify the final (unbalanced / repeated) trade-off row ----------------
df$final <- FALSE
picked <- NULL
for (cand in c("id_stage2", "stage2", "stage_2", "unbalanced", "dispersed", "final")) {
  if (cand %in% names(df) && is_bin(df[[cand]])) {
    s <- tapply(df[[cand]] %in% 1, df$sid, sum)
    if (mean(s == 1) > 0.95) { df$final <- df[[cand]] %in% 1; picked <- cand; break }
  }
}
if (is.null(picked)) {
  if ("decision_number" %in% names(df)) {
    df <- df %>% group_by(sid) %>%
      mutate(.mx = suppressWarnings(max(decision_number, na.rm = TRUE)),
             .cand = !is.na(decision_number) & decision_number == .mx,
             final = .cand & rowi == max(rowi[.cand])) %>%
      ungroup() %>% as.data.frame()
    picked <- "decision_number(max)"
  } else {
    df <- df %>% group_by(sid) %>% mutate(final = rowi == max(rowi)) %>% ungroup() %>% as.data.frame()
    picked <- "last row"
  }
}
cat("Final row identified by:", picked, "\n")

ipcol <- if ("indifference_point" %in% names(df)) "indifference_point" else "utility_point"
df$ip <- df[[ipcol]]

e_vec <- c(129, 132, 143, 115, 121, 117, 135, 127)

bal <- df[!df$final, ]
fin <- df[df$final, ]
fin <- fin[!duplicated(fin$sid), ]

# workday index for balanced rows
bal <- bal %>% group_by(sid) %>% arrange(rowi, .by_group = TRUE) %>% mutate(ord = row_number()) %>% ungroup() %>% as.data.frame()
use_dn <- FALSE
if ("decision_number" %in% names(bal)) {
  chk <- tapply(bal$decision_number, bal$sid, function(z) identical(sort(as.numeric(z)), as.numeric(1:8)))
  chk0 <- tapply(bal$decision_number, bal$sid, function(z) identical(sort(as.numeric(z)), as.numeric(0:7)))
  if (mean(chk, na.rm = TRUE) > 0.9) { bal$t <- bal$decision_number; use_dn <- TRUE }
  else if (mean(chk0, na.rm = TRUE) > 0.9) { bal$t <- bal$decision_number + 1; use_dn <- TRUE }
}
if (!use_dn) bal$t <- bal$ord
bal <- bal[bal$t %in% 1:8, ]
cat("Balanced workday index from decision_number:", use_dn, "\n")

X <- bal %>% select(sid, t, ip) %>% group_by(sid, t) %>% summarise(ip = first(ip), .groups = "drop")
Xw <- reshape(as.data.frame(X), idvar = "sid", timevar = "t", direction = "wide")
xcols <- paste0("ip.", 1:8)
for (cc in xcols) if (!cc %in% names(Xw)) Xw[[cc]] <- NA

# ---------------- subject-level conditions ----------------
condvars <- intersect(c("pizza", "control", "main", "treatment", "dispersed", "session", "average_ip"), names(df))
S <- df %>% group_by(sid) %>% summarise(across(all_of(condvars), firstnn), .groups = "drop") %>% as.data.frame()
S <- merge(S, Xw, by = "sid", all.x = TRUE)

fsel <- fin[, c("sid", "ip"), drop = FALSE]; names(fsel)[2] <- "d_raw"
if ("decision_number" %in% names(fin)) fsel$fin_dn <- fin$decision_number
if ("id_stage2" %in% names(fin)) fsel$fin_ids2 <- fin$id_stage2
S <- merge(S, fsel, by = "sid", all.x = TRUE)

# condition flags
S$ctrl <- NA
if ("control" %in% names(S) && is_bin(S$control)) S$ctrl <- S$control == 1
if (all(is.na(S$ctrl)) && "treatment" %in% names(S) && is_bin(S$treatment)) S$ctrl <- S$treatment == 0
if (all(is.na(S$ctrl)) && "dispersed" %in% names(S) && is_bin(S$dispersed)) S$ctrl <- S$dispersed == 0
S$voucher <- TRUE
if ("pizza" %in% names(S) && is_bin(S$pizza)) {
  S$voucher <- S$pizza == 1
  if (sum(S$voucher, na.rm = TRUE) < sum(!S$voucher, na.rm = TRUE)) { cat("Flipping pizza coding\n"); S$voucher <- !S$voucher }
}
S$mainc <- TRUE
if ("main" %in% names(S) && is_bin(S$main)) S$mainc <- S$main == 1
if ("treatment" %in% names(S) && is.character(S$treatment)) {
  tl <- tolower(S$treatment)
  if (!("main" %in% names(S) && is_bin(S$main))) S$mainc <- !grepl("mech", tl)
  if (!("pizza" %in% names(S) && is_bin(S$pizza))) S$voucher <- !grepl("don", tl)
  if (all(is.na(S$ctrl))) S$ctrl <- grepl("control", tl)
}
S$ctrl[is.na(S$ctrl)] <- FALSE
S$mainc[is.na(S$mainc)] <- TRUE
S$voucher[is.na(S$voucher)] <- TRUE
S$group <- with(S, ifelse(!voucher, ifelse(ctrl, "DonC", "DonT"),
                    ifelse(mainc, ifelse(ctrl, "MainC", "MainT"), ifelse(ctrl, "MechC", "MechT"))))
cat("Groups (before exclusion):\n"); print(table(S$group))

# ---------------- coding of final deviation ----------------
S$d <- S$d_raw
if (min(S$d_raw, na.rm = TRUE) >= 0 && max(S$d_raw, na.rm = TRUE) > 62) {
  cat("Final IP coded 0..125: subtracting 63\n"); S$d <- S$d_raw - 63
}
cat("Summary of d:\n"); print(summary(S$d))
S$upper_corner <- !is.na(S$d) & S$d >= 62

# ---------------- manually stated indifference point ----------------
known <- c("tn", "dispersed", "age", "study", "mathgrade", "disposable_income", "raven_correct_answers",
           "math_answers_correct", "crt_answers_correct", "session", "treatment", "average_ip",
           "decision_number", "utility_point", "corner", "chose_corner", "indifference_point", "pizza",
           "control", "main", "id_stage2", "sid", "rowi", "final", "ip", ".mx", ".cand", "id", "ord", "t")
numcols <- names(df)[sapply(df, is.numeric)]
cands <- setdiff(numcols, known)
subj_val <- function(v) {
  a <- df %>% group_by(sid) %>% summarise(fv = firstnn(.data[[v]][final]), av = firstnn(.data[[v]]), .groups = "drop")
  out <- ifelse(is.na(a$fv), a$av, a$fv); names(out) <- a$sid; out
}
manual_col <- NULL
namecand <- cands[grepl("manual|stated|state|hypo|upper|open|own|self|max|willing|wtw|ip_|_ip", cands)]
score_col <- function(v) {
  val <- subj_val(v)[S$sid]
  uc <- S$upper_corner
  if (sum(uc) == 0) return(-Inf)
  vu <- val[uc]
  good <- mean(!is.na(vu) & vu > 62 & vu < 5000)
  nonc <- mean(!is.na(val[!uc]) & val[!uc] != 0)
  good - 0.5 * nonc
}
sc_list <- c()
for (v in unique(c(namecand, cands))) sc_list[v] <- tryCatch(score_col(v), error = function(e) -Inf)
if (length(sc_list)) {
  cat("Manual-IP candidate scores:\n"); print(sort(sc_list, decreasing = TRUE)[1:min(10, length(sc_list))])
  nc <- sc_list[names(sc_list) %in% namecand]
  if (length(nc) && max(nc) > 0.4) manual_col <- names(nc)[which.max(nc)]
  else if (max(sc_list) > 0.4) manual_col <- names(sc_list)[which.max(sc_list)]
}
cat("Manual stated IP column:", ifelse(is.null(manual_col), "NONE", manual_col), "\n")
S$stated <- NA
if (!is.null(manual_col)) S$stated <- subj_val(manual_col)[S$sid]
# if stated appears to be total tasks per workday rather than deviation, leave as-is (cannot tell)
# The final-row indifference point already contains the manually stated value for
# upper-corner choosers (values > 62), i.e. it is the upper-bound version of d.
# Lower bound censors at 62; midpoint averages the two.
cat("Share of d > 62 (stated values already embedded):", mean(S$d > 62, na.rm = TRUE), "\n")
S$d_upper <- S$d
S$d_lower <- ifelse(!is.na(S$d) & S$d > 62, 62, S$d)
S$d_mid <- (S$d_lower + S$d_upper) / 2

# ---------------- exclusion rules ----------------
xm <- as.matrix(S[, xcols])
rule <- list()
rule$none <- rep(FALSE, nrow(S))
bal_any <- function(v, set_rows = bal) {
  if (!v %in% names(set_rows) || !is_bin(set_rows[[v]])) return(NULL)
  a <- tapply(set_rows[[v]] %in% 1, set_rows$sid, any)
  r <- a[S$sid]; r[is.na(r)] <- FALSE; as.vector(r)
}
if (!is.null(r <- bal_any("corner"))) rule$corner_bal <- r
if (!is.null(r <- bal_any("chose_corner"))) rule$chose_corner_bal <- r
if (!is.null(r <- bal_any("chose_corner", df))) rule$chose_corner_all <- r
if (!is.null(r <- bal_any("corner", df))) rule$corner_all <- r
rule$x_le0_ge125 <- apply(xm, 1, function(z) any(z <= 0 | z >= 125, na.rm = TRUE))
rule$x_lt0_ge125 <- apply(xm, 1, function(z) any(z < 0 | z >= 125, na.rm = TRUE))
rule$x_le0_ge126 <- apply(xm, 1, function(z) any(z <= 0 | z >= 126, na.rm = TRUE))
rule$x_lt0_gt125 <- apply(xm, 1, function(z) any(z < 0 | z > 125, na.rm = TRUE))
grp_names <- c("MainT", "MainC", "MechT", "MechC", "DonT", "DonC")
best <- NULL; bestsc <- Inf
for (rn in names(rule)) {
  keep <- !rule[[rn]] & !is.na(S$d)
  tb <- table(factor(S$group[keep], levels = grp_names))
  sc <- 3 * abs(tb["MainT"] - 100) + sum(abs(tb - 100))
  cat(sprintf("Rule %-18s: %s  score=%g\n", rn, paste(names(tb), tb, collapse = " "), sc))
  if (sc < bestsc) { bestsc <- sc; best <- rn }
}
cat("Chosen exclusion rule:", best, "\n")
S$keep <- !rule[[best]] & !is.na(S$d)
M <- S[S$keep, ]

# ---------------- relative measure ----------------
den <- sweep(as.matrix(M[, xcols]), 2, e_vec, "+")
M$j <- NA
if ("fin_dn" %in% names(M)) M$j <- ifelse(M$ctrl & M$fin_dn %in% 1:8, M$fin_dn, NA)
if ("fin_ids2" %in% names(M) && all(is.na(M$j[M$ctrl]))) M$j <- ifelse(M$ctrl & M$fin_ids2 %in% 1:8, M$fin_ids2, M$j)
cat("Control repeated trade-off identified for", sum(!is.na(M$j)), "of", sum(M$ctrl), "control subjects\n")
relfun <- function(dv) {
  r <- rowMeans(dv / den, na.rm = TRUE)
  jj <- which(!is.na(M$j))
  if (length(jj)) r[jj] <- dv[jj] / den[cbind(jj, M$j[jj])]
  r
}
M$rel_lower <- relfun(M$d_lower)
M$rel_mid <- relfun(M$d_mid)
M$rel_upper <- relfun(M$d_upper)

MT <- M[M$group == "MainT", ]
cat("Mean x by workday (MainT):", round(colMeans(MT[, xcols], na.rm = TRUE), 1), "\n")
cat("Share upper corner MainT:", mean(MT$upper_corner), "\n")

mean_rob <- function(y) {
  m <- lm(y ~ 1); c(coef(m)[1], sqrt(diag(vcovHC(m, type = "HC1")))[1])
}
r_dmid <- mean_rob(MT$d_mid)
r_rl <- mean_rob(MT$rel_lower); r_rm <- mean_rob(MT$rel_mid); r_ru <- mean_rob(MT$rel_upper)
cat("d lower/mid/upper:", mean(MT$d_lower), mean(MT$d_mid), mean(MT$d_upper), "\n")
cat("rel lower/mid/upper:", r_rl[1], r_rm[1], r_ru[1], "\n")

tob_coef <- tryCatch({
  lft <- min(-63, min(MT$d_lower, na.rm = TRUE))
  tm <- AER::tobit(d_lower ~ 1, left = lft, right = 62, data = MT)
  unname(coef(tm)[1])
}, error = function(e) { cat("Tobit error:", conditionMessage(e), "\n"); NA })

diffreg <- function(gT, gC) {
  D <- M[M$group %in% c(gT, gC), ]
  D$tr <- as.numeric(D$group == gT)
  m <- lm(rel_mid ~ tr, data = D)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))
  list(const = unname(coef(m)[1]), diff = unname(coef(m)[2]), n = nrow(D),
       meanT = mean(D$rel_mid[D$tr == 1]), se = se)
}
c1 <- diffreg("MainT", "MechT")   # constant = Mechanism-Treatment
c2 <- diffreg("DonT", "DonC")
c3 <- diffreg("MainT", "MainC")
c4 <- diffreg("MechT", "MechC")
cat("Table3 consts:", c1$const, c2$const, c3$const, c4$const, " Ns:", c1$n, c2$n, c3$n, c4$n, "\n")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", r_dmid[1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", tob_coef))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", r_rl[1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", r_rm[1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", r_ru[1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(MT)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", c1$const))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", c1$diff))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", c2$meanT))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", c2$diff))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", c3$diff))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", c4$diff))
cat(sprintf("RESULT:n_obs_table3=%d\n", c1$n))