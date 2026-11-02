suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(AER)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
path <- file.path(base, "Consumption Experiment/Stata/Consumption_Experiment.csv")
df <- as.data.frame(read_csv(path, show_col_types = FALSE, guess_max = 100000))
names(df) <- tolower(trimws(names(df)))

cat("Columns:\n"); print(names(df))
cat("Rows:", nrow(df), "\n")
print(head(df, 12))
has <- function(x) x %in% names(df)
for (v in c("treatment", "decision_number", "dispersed", "pizza", "main", "control", "corner", "chose_corner")) {
  if (has(v)) { cat("Table of", v, ":\n"); print(table(df[[v]], useNA = "ifany")) }
}

num <- function(x) suppressWarnings(as.numeric(as.character(x)))

# ---------------- subject id ----------------
id_cands <- list(c("tn"), c("session", "tn"), c("treatment", "session", "tn"))
df$id <- NA
for (cc in id_cands) {
  if (!all(cc %in% names(df))) next
  idv <- do.call(paste, c(df[cc], sep = "_"))
  if (has("decision_number")) {
    dup <- any(duplicated(paste(idv, df$decision_number)))
  } else dup <- FALSE
  if (!dup) { df$id <- idv; cat("Subject id built from:", paste(cc, collapse = "+"), "\n"); break }
}
if (all(is.na(df$id))) df$id <- do.call(paste, c(df[intersect(c("treatment", "session", "tn"), names(df))], sep = "_"))

df$dn <- num(df$decision_number)
df$ip <- num(df$indifference_point)

# ---------------- final (unbalanced / repeated) row ----------------
maxdn <- ave(df$dn, df$id, FUN = function(z) max(z, na.rm = TRUE))
if (max(df$dn, na.rm = TRUE) >= 9) {
  df$final <- df$dn == maxdn & df$dn >= 9
} else if (has("dispersed") && any(tapply(df$dispersed, df$id, function(z) length(unique(z)) > 1))) {
  df$final <- num(df$dispersed) == 1
} else {
  df$final <- df$dn == maxdn
}
cat("Final rows:", sum(df$final, na.rm = TRUE), " subjects:", length(unique(df$id)), "\n")

# workday index j for balanced rows
jcol <- "dn"
jc <- grep("workday|^day$|^day_|_day$|tradeoff|trade_off|^j$", names(df), value = TRUE)
for (cn in jc) {
  v <- num(df[[cn]][!df$final])
  if (length(v) && all(v[!is.na(v)] %in% 1:8)) { df$jj <- num(df[[cn]]); jcol <- "jj"; cat("Workday index from", cn, "\n"); break }
}
df$j <- df[[jcol]]

bal <- df[!df$final & df$j %in% 1:8, ]
fin <- df[df$final, ]

e <- c(129, 132, 143, 115, 121, 117, 135, 127)

# ---------------- final-row d ----------------
dvals <- fin$ip
if (any(dvals < 0, na.rm = TRUE)) {
  scale_shift <- 0
} else if (any(dvals > 62, na.rm = TRUE)) {
  scale_shift <- 63
} else scale_shift <- 0
fin$d <- fin$ip - scale_shift
cat("Final-row d range:", range(fin$d, na.rm = TRUE), " shift:", scale_shift, "\n")
fin$upper_corner <- fin$d >= 62

# manually stated indifference point (upper bound)
man_cands <- grep("manual|stated|state|hypo|upper|max_|willing|wtw|ip_?2|free", names(df), value = TRUE)
man_cands <- setdiff(man_cands, c("corner", "chose_corner"))
man_cands <- unique(c(man_cands, "utility_point"))
mancol <- NA
uc <- fin[fin$upper_corner %in% TRUE, ]
for (cn in man_cands) {
  if (!has(cn)) next
  v <- num(uc[[cn]])
  if (length(v) == 0) next
  if (mean(!is.na(v)) >= 0.8 && median(v, na.rm = TRUE) >= 62) { mancol <- cn; break }
}
cat("Manual upper-bound column:", mancol, "\n")
if (!is.na(mancol)) {
  man <- num(fin[[mancol]])
  print(summary(man[fin$upper_corner %in% TRUE]))
} else {
  man <- rep(NA_real_, nrow(fin))
  cat("NOTE: no manual indifference point column identified; upper bound = lower bound\n")
}
fin$d_lower <- fin$d
fin$d_upper <- ifelse(fin$upper_corner %in% TRUE, pmax(ifelse(is.na(man), 62, man), 62), fin$d)
fin$d_mid <- ifelse(fin$upper_corner %in% TRUE, (62 + fin$d_upper) / 2, fin$d)

# ---------------- balanced indifference points ----------------
bal <- bal[order(bal$id, bal$j), ]
xw <- reshape(bal[, c("id", "j", "ip")], idvar = "id", timevar = "j", direction = "wide")
xcols <- paste0("ip.", 1:8)
for (xc in xcols) if (!xc %in% names(xw)) xw[[xc]] <- NA
X <- as.matrix(xw[, xcols])

# corner exclusion candidates
corner_any <- function(col) {
  if (!has(col)) return(NULL)
  v <- num(bal[[col]]); v[is.na(v)] <- 0
  tapply(v != 0, bal$id, any)
}
ex_a <- corner_any("corner")
ex_b <- if (has("chose_corner")) tapply(num(df$chose_corner) %in% 1 | (num(df$chose_corner) != 0 & !is.na(num(df$chose_corner))), df$id, any) else NULL
ex_c <- tapply(bal$ip <= 0 | bal$ip >= 125, bal$id, any)

# ---------------- conditions ----------------
subj <- df[!duplicated(df$id), ]
tr <- as.character(subj$treatment)
cond <- rep(NA_character_, nrow(subj))
if (!is.null(tr) && any(grepl("[A-Za-z]", tr))) {
  mech <- grepl("mech", tr, ignore.case = TRUE)
  don <- grepl("don|char|spend", tr, ignore.case = TRUE)
  ctl <- grepl("contr|ctrl", tr, ignore.case = TRUE)
  if (any(mech) || any(don) || any(ctl)) {
    cond <- paste0(ifelse(don, "Donation", ifelse(mech, "Mechanism", "Main")), "-", ifelse(ctl, "Control", "Treatment"))
  }
}
if (all(is.na(cond))) {
  pz <- if (has("pizza")) num(subj$pizza) else rep(1, nrow(subj))
  mn <- if (has("main")) num(subj$main) else rep(1, nrow(subj))
  ct <- if (has("control")) num(subj$control) else 1 - num(subj$dispersed)
  cond <- paste0(ifelse(pz %in% 0, "Donation", ifelse(mn %in% 0, "Mechanism", "Main")), "-",
                 ifelse(ct %in% 1, "Control", "Treatment"))
}
cmap <- setNames(cond, subj$id)
cat("Conditions (all subjects):\n"); print(table(cond))

# ---------------- assemble subject-level data ----------------
S <- data.frame(id = fin$id, d_lower = fin$d_lower, d_mid = fin$d_mid, d_upper = fin$d_upper,
                stringsAsFactors = FALSE)
S$cond <- cmap[S$id]
mi <- match(S$id, xw$id)
Xs <- X[mi, , drop = FALSE]
den <- sweep(Xs, 2, e, "+")
relf <- function(d) rowMeans(matrix(d, nrow = length(d), ncol = 8) / den)
S$rel_lower <- relf(S$d_lower)
S$rel_mid <- relf(S$d_mid)
S$rel_upper <- relf(S$d_upper)

pick_ex <- function(ex) { if (is.null(ex)) return(NULL); v <- ex[S$id]; v[is.na(v)] <- TRUE; v }
cands <- list(a = pick_ex(ex_a), b = pick_ex(ex_b), c = pick_ex(ex_c))
cands <- cands[!sapply(cands, is.null)]
chosen <- names(cands)[1]
for (nm in names(cands)) {
  nmt <- sum(!cands[[nm]] & S$cond == "Main-Treatment" & !is.na(S$rel_mid))
  cat("Exclusion rule", nm, "-> Main-Treatment N =", nmt, "\n")
}
for (nm in names(cands)) {
  nmt <- sum(!cands[[nm]] & S$cond == "Main-Treatment" & !is.na(S$rel_mid))
  if (nmt == 100) { chosen <- nm; break }
}
cat("Using exclusion rule:", chosen, "\n")
S <- S[!cands[[chosen]] & !is.na(S$rel_mid), ]
cat("Main sample by condition:\n"); print(table(S$cond))

# ---------------- Table 2 ----------------
M <- S[S$cond == "Main-Treatment", ]
ols_mean <- function(y) {
  m <- lm(y ~ 1)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))[1]
  c(coef(m)[1], se)
}
t2_abs_mid <- ols_mean(M$d_mid)
t2_rel_low <- ols_mean(M$rel_lower)
t2_rel_mid <- ols_mean(M$rel_mid)
t2_rel_up <- ols_mean(M$rel_upper)
cat("Table2 abs: lower", ols_mean(M$d_lower), " mid", t2_abs_mid, " upper", ols_mean(M$d_upper), "\n")
cat("Table2 rel: lower", t2_rel_low, " mid", t2_rel_mid, " upper", t2_rel_up, "\n")

tob_coef <- tryCatch({
  lft <- min(-63, min(M$d_lower, na.rm = TRUE))
  tm <- AER::tobit(d_lower ~ 1, left = lft, right = 62, data = M)
  print(summary(tm))
  unname(coef(tm)[1])
}, error = function(err) { cat("Tobit error:", conditionMessage(err), "\n"); NA_real_ })

cat("Share rel_mid > 0:", mean(M$rel_mid > 0), "\n")

# ---------------- Table 3 ----------------
t3 <- function(a, b) {
  # returns mean of a-group as 'level' and diff a - b
  D <- S[S$cond %in% c(a, b), ]
  D$ind <- as.numeric(D$cond == a)
  m <- lm(rel_mid ~ ind, data = D)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))
  list(const = unname(coef(m)[1]), diff = unname(coef(m)[2]), n = nrow(D),
       mean_a = mean(D$rel_mid[D$ind == 1]), mean_b = mean(D$rel_mid[D$ind == 0]), se = se)
}
c1 <- t3("Main-Treatment", "Mechanism-Treatment")
c2 <- t3("Donation-Treatment", "Donation-Control")
c3 <- t3("Main-Treatment", "Main-Control")
c4 <- t3("Mechanism-Treatment", "Mechanism-Control")
cat("Table3 N per column:", c1$n, c2$n, c3$n, c4$n, "\n")
cat("Col1 const(Mech)", c1$const, "diff", c1$diff, "\n")
cat("Col2 DT mean", c2$mean_a, "DC mean", c2$mean_b, "diff", c2$diff, "\n")
cat("Col3 MC mean", c3$const, "diff", c3$diff, "\n")
cat("Col4 MechC mean", c4$const, "diff", c4$diff, "\n")

f <- function(x) format(x, digits = 8)
cat(paste0("RESULT:abs_concentration_bias_midpoint_table2_col2=", f(t2_abs_mid[1]), "\n"))
cat(paste0("RESULT:abs_concentration_bias_tobit_table2_col4=", f(tob_coef), "\n"))
cat(paste0("RESULT:rel_concentration_bias_lower_table2_col1=", f(t2_rel_low[1]), "\n"))
cat(paste0("RESULT:rel_concentration_bias_midpoint_table2_col2=", f(t2_rel_mid[1]), "\n"))
cat(paste0("RESULT:rel_concentration_bias_upper_table2_col3=", f(t2_rel_up[1]), "\n"))
cat(paste0("RESULT:n_obs_table2=", nrow(M), "\n"))
cat(paste0("RESULT:rel_cb_mechanism_treatment_table3_col1=", f(c1$mean_b), "\n"))
cat(paste0("RESULT:diff_main_minus_mechanism_table3_col1=", f(c1$diff), "\n"))
cat(paste0("RESULT:rel_cb_donation_treatment_table3_col2=", f(c2$mean_a), "\n"))
cat(paste0("RESULT:diff_donation_treatment_minus_control_table3_col2=", f(c2$diff), "\n"))
cat(paste0("RESULT:diff_main_treatment_minus_control_table3_col3=", f(c3$diff), "\n"))
cat(paste0("RESULT:diff_mechanism_treatment_minus_control_table3_col4=", f(c4$diff), "\n"))
cat(paste0("RESULT:n_obs_table3=", c1$n, "\n"))
