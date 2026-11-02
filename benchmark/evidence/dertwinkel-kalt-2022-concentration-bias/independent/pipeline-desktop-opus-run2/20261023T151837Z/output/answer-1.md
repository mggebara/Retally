suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(AER)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
df <- readr::read_csv(file.path(base, "Consumption Experiment/Stata/Consumption_Experiment.csv"),
                      show_col_types = FALSE, guess_max = 100000)
df <- as.data.frame(df)
cat("Columns:\n"); print(names(df))
cat("Rows:", nrow(df), "\n")

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
has <- function(v) v %in% names(df)

# ---------- subject id ----------
cand_ids <- list()
if (has("tn") && has("session")) cand_ids[["session_tn"]] <- paste(df$session, df$tn, sep = "_")
if (has("tn")) cand_ids[["tn"]] <- as.character(df$tn)
if (has("id")) cand_ids[["id"]] <- as.character(df$id)
score_id <- function(id) {
  tb <- table(id)
  c(max = max(tb), share9 = mean(tb == 9), n = length(tb))
}
best <- NULL; best_sc <- -Inf
for (nm in names(cand_ids)) {
  s <- score_id(cand_ids[[nm]])
  cat("id candidate", nm, ": max rows", s["max"], " share with 9 rows", s["share9"], " n", s["n"], "\n")
  sc <- s["share9"] - ifelse(s["max"] > 9, 1, 0)
  if (sc > best_sc) { best_sc <- sc; best <- nm }
}
df$sid <- cand_ids[[best]]
cat("Using id:", best, "\n")

df$ip <- num(df$indifference_point)
df$dn <- if (has("decision_number")) num(df$decision_number) else NA
df$disp <- if (has("dispersed")) num(df$dispersed) else NA

# ---------- identify final (unbalanced / control-repeat) row ----------
df <- df %>% group_by(sid) %>% mutate(rowpos = row_number()) %>% ungroup() %>% as.data.frame()
df$final <- FALSE
if (!all(is.na(df$disp))) df$final <- !is.na(df$disp) & df$disp == 1
sub_has_final <- tapply(df$final, df$sid, any)
need <- names(sub_has_final)[!sub_has_final]
if (length(need) > 0) {
  cat("Subjects without dispersed flag:", length(need), "\n")
  for (s in need) {
    idx <- which(df$sid == s)
    if (length(idx) < 2) next
    dnv <- df$dn[idx]
    if (any(!is.na(dnv) & dnv == 9)) {
      df$final[idx[which(dnv == 9)[1]]] <- TRUE
    } else if (any(duplicated(dnv))) {
      dup <- dnv[duplicated(dnv)][1]
      df$final[idx[max(which(dnv == dup))]] <- TRUE
    } else {
      df$final[idx[length(idx)]] <- TRUE
    }
  }
}

bal <- df[!df$final, ]
fin <- df[df$final, ]
fin <- fin[!duplicated(fin$sid), ]
cat("Balanced ip range:", range(bal$ip, na.rm = TRUE), "\n")
cat("Final ip range:", range(fin$ip, na.rm = TRUE), "\n")

# ---------- d scale ----------
shifted <- FALSE
if (min(fin$ip, na.rm = TRUE) >= 0 && max(fin$ip, na.rm = TRUE) > 62) {
  # possibly stored on 0..125 scale; only shift if no subject exceeds 125
  if (max(fin$ip, na.rm = TRUE) <= 125 && mean(fin$ip > 62, na.rm = TRUE) > 0.4) shifted <- TRUE
}
fin$d_raw <- if (shifted) fin$ip - 63 else fin$ip
cat("Shifted d scale:", shifted, "\n")

# ---------- upper bound (manually stated) ----------
fin$upper_corner <- fin$d_raw >= 62
if (has("chose_corner")) {
  cc <- num(fin$chose_corner)
  cat("chose_corner on final rows:\n"); print(table(cc, useNA = "ifany"))
}
fin$d_lower <- pmin(fin$d_raw, 62)
fin$d_upper <- fin$d_raw
if (any(fin$d_raw > 62, na.rm = TRUE)) {
  cat("Final ip exceeds 62 for some subjects: treating stored value as manual upper bound\n")
  fin$upper_corner <- fin$d_raw >= 62
} else {
  pat <- "manual|upper|stated|open|max_task|how_?many|willing|ub$|maximum|corner_value|corner_tasks|tasks_corner"
  cands <- setdiff(grep(pat, names(df), ignore.case = TRUE, value = TRUE), c("chose_corner", "corner"))
  cat("Upper-bound candidate columns:", cands, "\n")
  chosen <- NULL
  for (cn in cands) {
    v <- num(fin[[cn]])
    vc <- v[fin$upper_corner]
    if (sum(!is.na(vc)) >= 0.5 * sum(fin$upper_corner, na.rm = TRUE) && sum(!is.na(vc)) > 0) {
      cat("candidate", cn, "summary among corner subjects:\n"); print(summary(vc))
      if (median(vc, na.rm = TRUE) >= 62 || median(vc, na.rm = TRUE) > 0) { chosen <- cn; break }
    }
  }
  if (!is.null(chosen)) {
    v <- num(fin[[chosen]])
    if (shifted && median(v[fin$upper_corner], na.rm = TRUE) > 125) v <- v - 63
    # if values appear to be total extra tasks rather than d, keep as is when >= 62
    up <- ifelse(fin$upper_corner & !is.na(v), pmax(v, 62), fin$d_raw)
    fin$d_upper <- up
    cat("Using upper-bound column:", chosen, "\n")
  } else {
    cat("No upper-bound column found; upper = lower\n")
  }
}
fin$d_mid <- ifelse(fin$upper_corner, (fin$d_lower + fin$d_upper) / 2, fin$d_lower)

# ---------- balanced x by workday ----------
e <- c(129, 132, 143, 115, 121, 117, 135, 127)
bal <- bal %>% group_by(sid) %>% arrange(rowpos, .by_group = TRUE) %>%
  mutate(j = if (all(!is.na(dn)) && all(sort(dn) == seq_along(dn)) && n() == 8) dn else row_number()) %>%
  ungroup() %>% as.data.frame()
bal$j[bal$j > 8] <- NA
bal$e <- e[bal$j]
xw <- bal %>% filter(!is.na(j)) %>% group_by(sid) %>%
  summarise(sum_inv = sum(1 / (e + ip)), nbal = n(),
            minip = min(ip), maxip = max(ip), .groups = "drop") %>% as.data.frame()

# ---------- corner exclusion candidates ----------
flagA <- if (has("corner")) tapply(num(bal$corner), bal$sid, function(z) any(z == 1, na.rm = TRUE)) else NULL
flagB <- if (has("chose_corner")) tapply(num(bal$chose_corner), bal$sid, function(z) any(z == 1, na.rm = TRUE)) else NULL
if (has("corner")) {
  flagA2 <- tapply(num(df$corner), df$sid, function(z) any(z == 1, na.rm = TRUE))
} else flagA2 <- NULL
flagC <- tapply(bal$ip, bal$sid, function(z) any(z <= 0 | z >= 125, na.rm = TRUE))
flagD <- tapply(bal$ip, bal$sid, function(z) any(z < 0 | z >= 125, na.rm = TRUE))
flagE <- tapply(bal$ip, bal$sid, function(z) any(z >= 125, na.rm = TRUE))
flags <- list(A = flagA, B = flagB, A2 = flagA2, C = flagC, D = flagD, E = flagE)
flags <- flags[!sapply(flags, is.null)]

# ---------- conditions ----------
sub <- df %>% group_by(sid) %>% slice(1) %>% ungroup() %>% as.data.frame()
gv <- function(v) if (has(v)) num(sub[[v]]) else rep(NA, nrow(sub))
sub$main_ <- gv("main"); sub$control_ <- gv("control"); sub$pizza_ <- gv("pizza")
if (has("treatment")) { cat("treatment table:\n"); print(table(sub$treatment, useNA = "ifany")) }
cat("main/control/pizza:\n"); print(table(sub$main_, sub$control_, sub$pizza_, useNA = "ifany"))
cond <- rep(NA_character_, nrow(sub))
trt <- if (has("treatment")) as.character(sub$treatment) else rep(NA, nrow(sub))
if (has("treatment") && any(grepl("[A-Za-z]", trt))) {
  tl <- tolower(trt)
  cond <- ifelse(grepl("donat", tl) & grepl("control", tl), "DonCtrl",
          ifelse(grepl("donat", tl), "DonTreat",
          ifelse(grepl("mech", tl) & grepl("control", tl), "MechCtrl",
          ifelse(grepl("mech", tl), "MechTreat",
          ifelse(grepl("main", tl) & grepl("control", tl), "MainCtrl",
          ifelse(grepl("main", tl), "MainTreat", NA))))))
}
if (all(is.na(cond))) {
  don <- !is.na(sub$pizza_) & sub$pizza_ == 0
  ctl <- !is.na(sub$control_) & sub$control_ == 1
  mn <- !is.na(sub$main_) & sub$main_ == 1
  cond <- ifelse(don & ctl, "DonCtrl", ifelse(don, "DonTreat",
          ifelse(mn & ctl, "MainCtrl", ifelse(mn, "MainTreat",
          ifelse(ctl, "MechCtrl", "MechTreat")))))
}
sub$cond <- cond
print(table(sub$cond, useNA = "ifany"))

dat <- sub[, c("sid", "cond")] %>%
  inner_join(fin[, c("sid", "d_lower", "d_mid", "d_upper", "upper_corner")], by = "sid") %>%
  inner_join(xw, by = "sid")
dat <- dat[dat$nbal == 8, ]

# choose exclusion rule matching preregistered N = 100 in Main-Treatment
bestf <- NULL; bestdiff <- Inf
for (nm in names(flags)) {
  f <- flags[[nm]]
  keep <- !as.logical(f[dat$sid]); keep[is.na(keep)] <- TRUE
  nmain <- sum(keep & dat$cond == "MainTreat", na.rm = TRUE)
  cat("Exclusion rule", nm, ": N Main-Treatment =", nmain, "\n")
  if (abs(nmain - 100) < bestdiff) { bestdiff <- abs(nmain - 100); bestf <- nm }
}
cat("Using exclusion rule", bestf, "\n")
f <- flags[[bestf]]
keep <- !as.logical(f[dat$sid]); keep[is.na(keep)] <- TRUE
dat <- dat[keep, ]
print(table(dat$cond))

dat$rel_lower <- dat$d_lower * dat$sum_inv / 8
dat$rel_mid <- dat$d_mid * dat$sum_inv / 8
dat$rel_upper <- dat$d_upper * dat$sum_inv / 8

m <- dat[dat$cond == "MainTreat", ]
ols1 <- function(y) {
  fit <- lm(y ~ 1)
  c(coef(fit)[1], sqrt(diag(vcovHC(fit, type = "HC1")))[1])
}
r_dl <- ols1(m$d_lower); r_dm <- ols1(m$d_mid); r_du <- ols1(m$d_upper)
r_rl <- ols1(m$rel_lower); r_rm <- ols1(m$rel_mid); r_ru <- ols1(m$rel_upper)
cat("d lower/mid/upper:", r_dl[1], r_dm[1], r_du[1], "\n")
cat("rel lower/mid/upper:", r_rl[1], r_rm[1], r_ru[1], "\n")

lo <- min(-63, min(m$d_lower, na.rm = TRUE))
tob <- tryCatch(AER::tobit(d_lower ~ 1, left = lo, right = 62, data = m), error = function(e) NULL)
tob_coef <- if (!is.null(tob)) coef(tob)[1] else NA
cat("Tobit:", tob_coef, "\n")

pair <- function(treat, ctrl) {
  dd <- dat[dat$cond %in% c(treat, ctrl), ]
  dd$T <- as.numeric(dd$cond == treat)
  fit <- lm(rel_mid ~ T, data = dd)
  se <- sqrt(diag(vcovHC(fit, type = "HC1")))
  list(const = unname(coef(fit)[1]), diff = unname(coef(fit)[2]), se = se, n = nrow(dd))
}
c1 <- pair("MainTreat", "MechTreat")
c2 <- pair("DonTreat", "DonCtrl")
c3 <- pair("MainTreat", "MainCtrl")
c4 <- pair("MechTreat", "MechCtrl")
cat("Table3 Ns:", c1$n, c2$n, c3$n, c4$n, "\n")

donT <- mean(dat$rel_mid[dat$cond == "DonTreat"], na.rm = TRUE)

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.4f\n", r_dm[1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.4f\n", tob_coef))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.4f\n", r_rl[1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.4f\n", r_rm[1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.4f\n", r_ru[1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(m)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.4f\n", c1$const))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.4f\n", c1$diff))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.4f\n", donT))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.4f\n", c2$diff))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.4f\n", c3$diff))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.4f\n", c4$diff))
cat(sprintf("RESULT:n_obs_table3=%d\n", c1$n))
