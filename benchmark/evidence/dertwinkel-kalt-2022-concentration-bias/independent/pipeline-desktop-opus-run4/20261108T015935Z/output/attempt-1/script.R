suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(AER)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
path <- file.path(base, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")
df <- as.data.frame(read_csv(path, show_col_types = FALSE, guess_max = 100000))

cat("nrow:", nrow(df), "\n")
cat("columns:", paste(names(df), collapse = ", "), "\n")
for (v in intersect(c("treatment", "decision_number", "corner", "chose_corner", "pizza",
                      "control", "main", "dispersed"), names(df))) {
  cat("---", v, "---\n"); print(table(df[[v]], useNA = "ifany"))
}

e_tasks <- c(129, 132, 143, 115, 121, 117, 135, 127)

# ---------------- subject id ----------------
if ("id" %in% names(df)) {
  df$sid <- as.character(df$id)
} else if (all(c("session", "tn") %in% names(df))) {
  df$sid <- paste(df$session, df$tn, sep = "_")
} else {
  df$sid <- as.character(df$tn)
}

# ---------------- decision / trade-off index ----------------
wd_cand <- grep("workday|tradeoff|trade_off", names(df), value = TRUE, ignore.case = TRUE)
cat("workday candidates:", paste(wd_cand, collapse = ", "), "\n")
df$dec <- df$decision_number

decs <- sort(unique(df$dec[!is.na(df$dec)]))
unb_dec <- max(decs)
bal_decs <- setdiff(decs, unb_dec)
if (length(bal_decs) > 8) bal_decs <- tail(bal_decs, 8)
cat("balanced decisions:", bal_decs, " unbalanced decision:", unb_dec, "\n")

first_non_na <- function(x) { x <- x[!is.na(x)]; if (length(x)) x[1] else NA }

# ---------------- condition classification ----------------
classify <- function(d) {
  out <- rep(NA_character_, nrow(d))
  tr <- d$treatment
  if (is.character(tr) || is.factor(tr)) {
    tr <- tolower(as.character(tr))
    don <- grepl("don|charit", tr)
    ctl <- grepl("contr|ctrl|placebo", tr)
    mech <- grepl("mech|disp", tr)
    out <- ifelse(don & ctl, "DonCtrl",
           ifelse(don, "DonTreat",
           ifelse(mech & ctl, "MechCtrl",
           ifelse(mech, "MechTreat",
           ifelse(ctl, "MainCtrl", "MainTreat")))))
    return(out)
  }
  has <- function(v) v %in% names(d)
  ctl <- if (has("control")) d$control == 1 else rep(FALSE, nrow(d))
  don <- if (has("pizza")) d$pizza == 0 else rep(FALSE, nrow(d))
  if (has("main") && length(unique(d$main[!don & !is.na(d$main)])) > 1) {
    mech <- d$main == 0
  } else if (has("dispersed")) {
    mech <- d$dispersed == 1
  } else mech <- rep(FALSE, nrow(d))
  ifelse(don & ctl, "DonCtrl",
  ifelse(don, "DonTreat",
  ifelse(mech & ctl, "MechCtrl",
  ifelse(mech, "MechTreat",
  ifelse(ctl, "MainCtrl", "MainTreat")))))
}

# ---------------- self-stated indifference point column ----------------
known <- c("tn", "dispersed", "age", "study", "mathgrade", "disposable_income",
           "raven_correct_answers", "math_answers_correct", "crt_answers_correct",
           "session", "treatment", "average_ip", "decision_number", "utility_point",
           "corner", "chose_corner", "indifference_point", "pizza", "control", "main",
           "id_stage2", "sid", "dec")
ub_cand <- grep("manual|stated|self|upper|wtw|hypo|unincent|open|max", names(df),
                value = TRUE, ignore.case = TRUE)
ub_cand <- setdiff(ub_cand, known)
ub_cand <- ub_cand[sapply(ub_cand, function(v) is.numeric(df[[v]]))]
cat("upper-bound candidates:", paste(ub_cand, collapse = ", "), "\n")
ub_col <- if (length(ub_cand)) ub_cand[1] else NA

# ---------------- subject-level data ----------------
subj <- df %>%
  group_by(sid) %>%
  summarise(across(any_of(c("treatment", "pizza", "control", "main", "dispersed",
                            "session", "corner", "chose_corner")), first_non_na),
            .groups = "drop") %>%
  as.data.frame()
subj$cond <- classify(subj)
print(table(subj$cond, useNA = "ifany"))

ipd <- df %>% group_by(sid, dec) %>%
  summarise(ip = first_non_na(indifference_point), .groups = "drop")

bal <- ipd %>% filter(dec %in% bal_decs)
bal$t <- match(bal$dec, bal_decs)
xw <- matrix(NA_real_, nrow = nrow(subj), ncol = 8)
idx <- match(bal$sid, subj$sid)
xw[cbind(idx, bal$t)] <- bal$ip

unb <- ipd %>% filter(dec == unb_dec)
d_raw <- unb$ip[match(subj$sid, unb$sid)]
shift <- 0
if (all(d_raw >= 0, na.rm = TRUE) && max(d_raw, na.rm = TRUE) > 62) shift <- 63
subj$d_lb <- d_raw - shift
cat("d range:", range(subj$d_lb, na.rm = TRUE), "\n")

if (!is.na(ub_col)) {
  st <- df %>% group_by(sid) %>% summarise(st = first_non_na(.data[[ub_col]]), .groups = "drop")
  stated <- st$st[match(subj$sid, st$sid)]
  cornerU <- !is.na(subj$d_lb) & subj$d_lb >= 62
  med <- median(stated[cornerU], na.rm = TRUE)
  cat("median stated among upper-corner:", med, "\n")
  if (!is.na(med) && shift == 63 && med > 125) stated <- stated - 63
  if (!is.na(med) && med < 62) stated <- stated + 62
  subj$d_ub <- ifelse(cornerU & !is.na(stated), pmax(stated, 62), subj$d_lb)
} else {
  subj$d_ub <- subj$d_lb
}
subj$d_mid <- (subj$d_lb + subj$d_ub) / 2

inv <- sweep(xw, 2, e_tasks, "+")
w <- rowMeans(1 / inv)
subj$drel_lb <- subj$d_lb * w
subj$drel_mid <- subj$d_mid * w
subj$drel_ub <- subj$d_ub * w

# ---------------- exclusion: corner choice in any balanced trade-off ----------------
excl_ip <- apply(xw, 1, function(r) any(is.na(r)) || any(r <= 0 | r >= 125))
excl_opts <- list(ip = excl_ip)
if ("corner" %in% names(subj)) excl_opts$corner <- is.na(subj$corner) | subj$corner == 1
if ("chose_corner" %in% names(subj)) excl_opts$chose_corner <- is.na(subj$chose_corner) | subj$chose_corner == 1
chosen <- "ip"
for (nm in names(excl_opts)) {
  n_main <- sum(subj$cond == "MainTreat" & !excl_opts[[nm]] & !is.na(subj$d_lb), na.rm = TRUE)
  cat("exclusion", nm, "-> Main-Treatment N =", n_main, "\n")
  if (n_main == 100 && chosen == "ip" && sum(subj$cond == "MainTreat" & !excl_ip & !is.na(subj$d_lb)) != 100)
    chosen <- nm
}
cat("using exclusion:", chosen, "\n")
s <- subj[!excl_opts[[chosen]] & !is.na(subj$d_lb) & !is.na(subj$drel_mid), ]
print(table(s$cond))

# ---------------- Table 2 ----------------
m <- s[s$cond == "MainTreat", ]
r_dmid <- feols(d_mid ~ 1, data = m, vcov = "hetero")
r_lb <- feols(drel_lb ~ 1, data = m, vcov = "hetero")
r_mid <- feols(drel_mid ~ 1, data = m, vcov = "hetero")
r_ub <- feols(drel_ub ~ 1, data = m, vcov = "hetero")
tob <- tryCatch(tobit(d_lb ~ 1, left = -63, right = 62, data = m), error = function(e) NULL)
tob_coef <- if (!is.null(tob)) unname(coef(tob)[1]) else NA

# ---------------- Table 3 ----------------
pair_reg <- function(a, b) {
  dd <- s[s$cond %in% c(a, b), ]
  dd$ind <- as.numeric(dd$cond == a)
  r <- feols(drel_mid ~ ind, data = dd, vcov = "hetero")
  list(const = unname(coef(r)[1]), diff = unname(coef(r)["ind"]),
       se = unname(sqrt(diag(vcov(r)))["ind"]), n = nobs(r))
}
t1 <- pair_reg("MainTreat", "MechTreat")
dn <- s[s$cond %in% c("DonTreat", "DonCtrl"), ]
dn$ind <- as.numeric(dn$cond == "DonTreat")
r2 <- feols(drel_mid ~ ind, data = dn, vcov = "hetero")
don_treat_mean <- unname(coef(r2)[1] + coef(r2)["ind"])
don_diff <- unname(coef(r2)["ind"])
t3 <- pair_reg("MainTreat", "MainCtrl")
t4 <- pair_reg("MechTreat", "MechCtrl")

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("abs_concentration_bias_midpoint_table2_col2", coef(r_dmid)[1])
out("abs_concentration_bias_tobit_table2_col4", tob_coef)
out("rel_concentration_bias_lower_table2_col1", coef(r_lb)[1])
out("rel_concentration_bias_midpoint_table2_col2", coef(r_mid)[1])
out("rel_concentration_bias_upper_table2_col3", coef(r_ub)[1])
out("n_obs_table2", nobs(r_mid))
out("rel_cb_mechanism_treatment_table3_col1", t1$const)
out("diff_main_minus_mechanism_table3_col1", t1$diff)
out("rel_cb_donation_treatment_table3_col2", don_treat_mean)
out("diff_donation_treatment_minus_control_table3_col2", don_diff)
out("diff_main_treatment_minus_control_table3_col3", t3$diff)
out("diff_mechanism_treatment_minus_control_table3_col4", t4$diff)
out("n_obs_table3", t1$n)