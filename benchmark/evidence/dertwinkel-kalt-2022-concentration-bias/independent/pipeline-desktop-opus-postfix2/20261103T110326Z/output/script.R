suppressPackageStartupMessages({
  library(readr); library(dplyr); library(fixest); library(AER); library(survival)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
path <- file.path(base, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")
df <- read_csv(path, show_col_types = FALSE, guess_max = 100000)
n_loaded <- nrow(df)

has <- function(v) v %in% names(df)
num <- function(x) suppressWarnings(as.numeric(x))
firstnn <- function(x) { x <- x[!is.na(x)]; if (length(x)) x[1] else NA }

# ---------------- subject id ----------------
id_parts <- intersect(c("study", "session", "tn"), names(df))
df$sid <- do.call(paste, c(lapply(id_parts, function(v) df[[v]]), sep = "_"))

# ---------------- parametrisation ----------------
e_t <- c(129, 132, 143, 115, 121, 117, 135, 127)

# ---------------- condition labels ----------------
df$cond <- NA_character_
if (has("treatment")) {
  tr <- df$treatment
  tr_nonnum <- is.character(tr) && any(is.na(num(tr[!is.na(tr)])))
  if (tr_nonnum) {
    t <- tolower(tr)
    fam <- ifelse(grepl("don|charit|licht", t), "Donation",
           ifelse(grepl("mech|sum|part", t), "Mechanism",
           ifelse(grepl("main|pizza|vouch|rest", t), "Main", NA)))
    arm <- ifelse(grepl("control|placebo|ctrl", t), "Control", "Treatment")
    df$cond <- ifelse(is.na(fam), NA, paste(fam, arm, sep = "-"))
  }
}
if (all(is.na(df$cond))) {
  is_ctrl <- rep(NA, nrow(df))
  if (has("control")) is_ctrl <- num(df$control) == 1
  if (all(is.na(is_ctrl)) && has("treatment")) {
    tv <- num(df$treatment)
    if (length(unique(na.omit(tv))) == 2) is_ctrl <- tv == min(tv, na.rm = TRUE)
  }
  is_main <- if (has("main")) num(df$main) == 1 else rep(NA, nrow(df))
  is_don <- rep(FALSE, nrow(df))
  if (has("pizza") && length(unique(na.omit(num(df$pizza)))) == 2) {
    is_don <- num(df$pizza) == 0
    is_don[is.na(is_don)] <- FALSE
  } else if (has("study") && has("main")) {
    st_main <- tapply(num(df$main) == 1, df$study, function(z) any(z, na.rm = TRUE))
    don_st <- names(st_main)[!st_main]
    if (length(don_st) >= 1 && length(don_st) < length(st_main)) is_don <- as.character(df$study) %in% don_st
  }
  fam <- ifelse(is_don, "Donation", ifelse(!is.na(is_main) & is_main, "Main", "Mechanism"))
  arm <- ifelse(!is.na(is_ctrl) & is_ctrl, "Control", "Treatment")
  df$cond <- paste(fam, arm, sep = "-")
}

# ---------------- subject-level measures ----------------
dn <- if (has("decision_number")) num(df$decision_number) else NA
disp <- if (has("dispersed")) num(df$dispersed) else NA
ip <- num(df$indifference_point)

own <- df %>% mutate(dn = dn, disp = disp, ip = ip) %>%
  group_by(sid) %>%
  group_modify(function(d, k) {
    bal <- d %>% filter((is.na(disp) | disp == 0) & !is.na(dn) & dn >= 1 & dn <= 8) %>%
      group_by(dn) %>% summarise(x = first(ip), .groups = "drop") %>% arrange(dn)
    stage2 <- d %>% filter((!is.na(disp) & disp == 1) | (!is.na(dn) & dn == 9))
    d2 <- if (nrow(stage2)) firstnn(stage2$ip) else NA
    xt <- rep(NA_real_, 8)
    if (nrow(bal) == 8) xt <- bal$x else if (nrow(bal) > 0) xt[seq_len(min(8, nrow(bal)))] <- bal$x[seq_len(min(8, nrow(bal)))]
    tibble(x1 = xt[1], x2 = xt[2], x3 = xt[3], x4 = xt[4], x5 = xt[5], x6 = xt[6], x7 = xt[7], x8 = xt[8],
           d_row = d2, n_bal_rows = nrow(bal))
  }) %>% ungroup()

keepvars <- intersect(c("cond", "pap_sample", "id_stage2", "id_stage2_upper", "avg_id_stage2",
                        "qe_rad", "qe_rad_lower", "qe_rad_upper", "qe_ard", "qe_ard_lower", "qe_ard_upper",
                        "corner", "chose_corner", "study", "session", "main", "control", "pizza", "treatment"),
                      names(df))
subj <- df %>% group_by(sid) %>%
  summarise(across(all_of(keepvars), firstnn),
            any_bal_corner = {
              cc <- if ("chose_corner" %in% names(cur_data())) num(chose_corner) else
                    if ("corner" %in% names(cur_data())) num(corner) else rep(NA, n())
              dd <- if ("dispersed" %in% names(cur_data())) num(dispersed) else rep(0, n())
              dnn <- if ("decision_number" %in% names(cur_data())) num(decision_number) else rep(1, n())
              sel <- (is.na(dd) | dd == 0) & (is.na(dnn) | dnn <= 8)
              any(cc[sel] == 1, na.rm = TRUE)
            }, .groups = "drop") %>%
  left_join(own, by = "sid")

# absolute measures
d_low_raw <- if ("id_stage2" %in% names(subj)) num(subj$id_stage2) else subj$d_row
d_low_raw[is.na(d_low_raw)] <- subj$d_row[is.na(d_low_raw)]
subj$d_lower <- pmin(d_low_raw, 62)
upper_corner <- d_low_raw >= 62
d_up <- if ("id_stage2_upper" %in% names(subj)) num(subj$id_stage2_upper) else rep(NA, nrow(subj))
d_up <- ifelse(is.na(d_up) | !upper_corner, subj$d_lower, pmax(d_up, subj$d_lower))
subj$d_upper <- d_up
subj$d_mid <- (subj$d_lower + subj$d_upper) / 2

# own relative measures
X <- as.matrix(subj[, paste0("x", 1:8)])
den <- sweep(X, 2, e_t, "+")
relf <- function(d) rowMeans(d / den)
subj$own_rel_lower <- relf(subj$d_lower)
subj$own_rel_mid <- relf(subj$d_mid)
subj$own_rel_upper <- relf(subj$d_upper)

# pick precomputed relative measure (qe_rad vs qe_ard) closest to own computation
pick_rel <- function(suffix, ownv) {
  cands <- paste0(c("qe_rad", "qe_ard"), suffix)
  cands <- cands[cands %in% names(subj)]
  best <- NULL; bestd <- Inf
  for (cn in cands) {
    v <- num(subj[[cn]])
    ok <- !is.na(v) & !is.na(ownv)
    if (sum(ok) < 10) next
    dist <- mean(abs(v[ok] - ownv[ok]))
    if (dist < bestd) { bestd <- dist; best <- cn }
  }
  if (is.null(best)) return(list(v = ownv, name = "own"))
  v <- num(subj[[best]]); v[is.na(v)] <- ownv[is.na(v)]
  list(v = v, name = best)
}
pl <- pick_rel("_lower", subj$own_rel_lower)
pm <- pick_rel("", subj$own_rel_mid)
pu <- pick_rel("_upper", subj$own_rel_upper)
subj$rel_lower <- pl$v; subj$rel_mid <- pm$v; subj$rel_upper <- pu$v
cat(sprintf("NOTE: relative measures from %s / %s / %s\n", pl$name, pm$name, pu$name))

# ---------------- preregistered sample ----------------
if ("pap_sample" %in% names(subj) && any(num(subj$pap_sample) == 1, na.rm = TRUE)) {
  subj$insample <- num(subj$pap_sample) == 1 & !is.na(subj$pap_sample)
} else {
  cat("DEVIATION: pap_sample unavailable; excluding subjects with any corner choice in balanced trade-offs\n")
  subj$insample <- !subj$any_bal_corner
}
cat("NOTE: subjects per condition (all / main sample):\n")
print(table(subj$cond, subj$insample, useNA = "ifany"))

samp <- subj %>% filter(insample)
cnt <- table(samp$cond)
for (cc in names(cnt)) if (cnt[cc] != 100) cat(sprintf("DEVIATION: %s main sample has %d subjects (paper: 100)\n", cc, cnt[cc]))

# ---------------- Table 2 ----------------
s_rows <- function(cond) df %>% filter(cond == !!cond) %>% nrow()
mt_all <- subj %>% filter(cond == "Main-Treatment")
mt <- samp %>% filter(cond == "Main-Treatment")
cat(sprintf("SAMPLE:table2:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:table2:main_treatment_subjects=%d\n", nrow(mt_all)))
cat(sprintf("SAMPLE:table2:exclude_balanced_corner=%d\n", nrow(mt)))

m_abs_mid <- feols(d_mid ~ 1, data = mt, vcov = "hetero")
m_abs_low <- feols(d_lower ~ 1, data = mt, vcov = "hetero")
m_abs_up <- feols(d_upper ~ 1, data = mt, vcov = "hetero")
m_rel_low <- feols(rel_lower ~ 1, data = mt, vcov = "hetero")
m_rel_mid <- feols(rel_mid ~ 1, data = mt, vcov = "hetero")
m_rel_up <- feols(rel_upper ~ 1, data = mt, vcov = "hetero")
tob <- tryCatch(AER::tobit(d_lower ~ 1, left = -63, right = 62, data = mt), error = function(e) NULL)
cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m_rel_mid)))

# ---------------- Table 3 ----------------
t3 <- function(name, a, b) {
  allr <- subj %>% filter(cond %in% c(a, b))
  d <- samp %>% filter(cond %in% c(a, b)) %>% mutate(ind = as.numeric(cond == a))
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, n_loaded))
  cat(sprintf("SAMPLE:%s:two_conditions_subjects=%d\n", name, nrow(allr)))
  cat(sprintf("SAMPLE:%s:exclude_balanced_corner=%d\n", name, nrow(d)))
  m <- feols(rel_mid ~ ind, data = d, vcov = "hetero")
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  m
}
# col1: constant = Mechanism-Treatment, ind = Main-Treatment
m1 <- t3("table3_col1", "Main-Treatment", "Mechanism-Treatment")
m2 <- t3("table3_col2", "Donation-Treatment", "Donation-Control")
m3 <- t3("table3_col3", "Main-Treatment", "Main-Control")
m4 <- t3("table3_col4", "Mechanism-Treatment", "Mechanism-Control")
c2 <- samp %>% filter(cond == "Donation-Treatment")

se <- function(m, v) sqrt(diag(vcov(m)))[v]
out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(v)))

out("abs_concentration_bias_midpoint_table2_col2", coef(m_abs_mid)[1])
out("abs_concentration_bias_midpoint_table2_col2_se", se(m_abs_mid, 1))
out("abs_concentration_bias_lower_table2_col1", coef(m_abs_low)[1])
out("abs_concentration_bias_upper_table2_col3", coef(m_abs_up)[1])
if (!is.null(tob)) out("abs_concentration_bias_tobit_table2_col4", coef(tob)[1])
out("rel_concentration_bias_lower_table2_col1", coef(m_rel_low)[1])
out("rel_concentration_bias_lower_table2_col1_se", se(m_rel_low, 1))
out("rel_concentration_bias_midpoint_table2_col2", coef(m_rel_mid)[1])
out("rel_concentration_bias_midpoint_table2_col2_se", se(m_rel_mid, 1))
out("rel_concentration_bias_upper_table2_col3", coef(m_rel_up)[1])
out("rel_concentration_bias_upper_table2_col3_se", se(m_rel_up, 1))
out("n_obs_table2", nobs(m_rel_mid))
out("rel_cb_mechanism_treatment_table3_col1", coef(m1)["(Intercept)"])
out("diff_main_minus_mechanism_table3_col1", coef(m1)["ind"])
out("diff_main_minus_mechanism_table3_col1_se", se(m1, "ind"))
out("rel_cb_donation_treatment_table3_col2", mean(c2$rel_mid, na.rm = TRUE))
out("diff_donation_treatment_minus_control_table3_col2", coef(m2)["ind"])
out("diff_donation_treatment_minus_control_table3_col2_se", se(m2, "ind"))
out("rel_cb_main_control_table3_col3", coef(m3)["(Intercept)"])
out("diff_main_treatment_minus_control_table3_col3", coef(m3)["ind"])
out("diff_main_treatment_minus_control_table3_col3_se", se(m3, "ind"))
out("rel_cb_mechanism_control_table3_col4", coef(m4)["(Intercept)"])
out("diff_mechanism_treatment_minus_control_table3_col4", coef(m4)["ind"])
out("diff_mechanism_treatment_minus_control_table3_col4_se", se(m4, "ind"))
out("n_obs_table3", nobs(m1))