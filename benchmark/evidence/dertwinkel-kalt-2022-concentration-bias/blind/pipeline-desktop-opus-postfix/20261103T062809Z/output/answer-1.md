suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(AER)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
df <- readr::read_csv(file.path(base, "Consumption Experiment/Stata/Consumption_Experiment.csv"),
                      show_col_types = FALSE, guess_max = 100000)
df <- as.data.frame(df)
n_loaded <- nrow(df)
cat("Columns:", paste(names(df), collapse = ", "), "\n")

has <- function(v) v %in% names(df)
first_nonNA <- function(x) { y <- x[!is.na(x)]; if (length(y) == 0) x[1] else y[1] }

# ---- subject identifier ----
if (has("session")) {
  df$sid <- paste(df$session, df$tn, sep = "_")
} else {
  df$sid <- as.character(df$tn)
}

# ---- balanced corner flag (for fallback exclusion) ----
if (has("dispersed") && has("corner")) {
  df$bal_corner <- ifelse(!is.na(df$dispersed) & df$dispersed == 0 & !is.na(df$corner) & df$corner == 1, 1, 0)
} else if (has("corner")) {
  df$bal_corner <- ifelse(!is.na(df$corner) & df$corner == 1, 1, 0)
} else {
  df$bal_corner <- 0
}

keep_vars <- intersect(c("treatment", "control", "main", "pizza", "study", "pap_sample",
                         "id_stage2", "id_stage2_upper", "avg_id_stage2",
                         "qe_ard", "qe_rad", "qe_ard_lower", "qe_rad_lower",
                         "qe_ard_upper", "qe_rad_upper", "chose_corner"), names(df))

subj <- df %>%
  group_by(sid) %>%
  summarise(across(all_of(keep_vars), first_nonNA),
            any_bal_corner = max(bal_corner, na.rm = TRUE),
            .groups = "drop") %>%
  as.data.frame()
cat(sprintf("Subjects: %d\n", nrow(subj)))

# ---- condition assignment ----
cond <- rep(NA_character_, nrow(subj))
if (has("treatment") && is.character(subj$treatment)) {
  tl <- tolower(subj$treatment)
  don <- grepl("don", tl); mech <- grepl("mech", tl); ctr <- grepl("contr", tl)
  if (any(don) || any(mech) || any(ctr)) {
    cond <- paste0(ifelse(don, "Donation", ifelse(mech, "Mechanism", "Main")),
                   ifelse(ctr, "-Control", "-Treatment"))
  }
}
if (all(is.na(cond)) && has("control")) {
  ctr <- !is.na(subj$control) & subj$control == 1
  if (has("pizza") && length(unique(na.omit(subj$pizza))) == 2) {
    don <- !is.na(subj$pizza) & subj$pizza == 0
  } else if (has("main")) {
    don <- is.na(subj$main)
  } else {
    don <- rep(FALSE, nrow(subj))
  }
  mech <- !don & has("main") & !is.na(subj$main) & subj$main == 0
  cond <- paste0(ifelse(don, "Donation", ifelse(mech, "Mechanism", "Main")),
                 ifelse(ctr, "-Control", "-Treatment"))
}
subj$cond <- cond
if (has("treatment")) print(table(subj$treatment, subj$cond, useNA = "ifany"))

# ---- preregistered sample restriction ----
if ("pap_sample" %in% names(subj) && any(!is.na(subj$pap_sample))) {
  subj$insample <- !is.na(subj$pap_sample) & subj$pap_sample == 1
} else {
  subj$insample <- subj$any_bal_corner == 0
}
print(table(subj$cond, subj$insample, useNA = "ifany"))

# ---- measures ----
pick_rel_abs <- function(a, b) {
  # returns list(rel=, abs=) prefix names among "qe_ard","qe_rad"
  sa <- sd(subj[[paste0(a, "_lower")]], na.rm = TRUE)
  sb <- sd(subj[[paste0(b, "_lower")]], na.rm = TRUE)
  if (is.na(sa) || is.na(sb)) return(list(rel = "qe_rad", abs = "qe_ard"))
  if (sa < sb) list(rel = a, abs = b) else list(rel = b, abs = a)
}
pr <- pick_rel_abs("qe_ard", "qe_rad")
cat("Relative measure prefix:", pr$rel, "\n")

rel_l <- subj[[paste0(pr$rel, "_lower")]]
rel_u <- subj[[paste0(pr$rel, "_upper")]]
if (is.null(rel_u)) rel_u <- rel_l
rel_u <- ifelse(is.na(rel_u), rel_l, rel_u)
subj$rel_lower <- rel_l
subj$rel_upper <- rel_u
subj$rel_mid <- (rel_l + rel_u) / 2
if (pr$rel %in% names(subj)) {
  subj$rel_mid <- ifelse(is.na(subj$rel_mid), subj[[pr$rel]], subj$rel_mid)
}

# absolute d~: lower bound and stated upper bound
d_l <- subj$id_stage2
d_u <- if ("id_stage2_upper" %in% names(subj)) subj$id_stage2_upper else d_l
d_u <- ifelse(is.na(d_u), d_l, d_u)
# guard: lower bound should never exceed 62 for corner subjects
d_l2 <- pmin(d_l, d_u)
subj$d_lower <- d_l2
subj$d_upper <- pmax(d_l, d_u)
subj$d_mid <- (subj$d_lower + subj$d_upper) / 2

# ---- Table 2: Main-Treatment ----
mt <- subj %>% filter(cond == "Main-Treatment")
cat(sprintf("SAMPLE:table2:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:table2:collapse_to_subjects=%d\n", nrow(subj)))
cat(sprintf("SAMPLE:table2:main_treatment=%d\n", nrow(mt)))
mt <- mt %>% filter(insample)
cat(sprintf("SAMPLE:table2:exclude_balanced_corner=%d\n", nrow(mt)))

m_abs_mid <- feols(d_mid ~ 1, data = mt, vcov = "hetero")
m_rel_low <- feols(rel_lower ~ 1, data = mt, vcov = "hetero")
m_rel_mid <- feols(rel_mid ~ 1, data = mt, vcov = "hetero")
m_rel_up  <- feols(rel_upper ~ 1, data = mt, vcov = "hetero")
cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m_rel_mid)))

lo_cens <- min(-63, min(mt$d_lower, na.rm = TRUE))
hi_cens <- 62
tob <- AER::tobit(d_lower ~ 1, left = lo_cens, right = hi_cens, data = mt)
tob_coef <- unname(coef(tob)[1])

# ---- Table 3 ----
run_pair <- function(name, treat_cond, base_cond) {
  s <- subj %>% filter(cond %in% c(treat_cond, base_cond))
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, n_loaded))
  cat(sprintf("SAMPLE:%s:collapse_to_subjects=%d\n", name, nrow(subj)))
  cat(sprintf("SAMPLE:%s:conditions=%d\n", name, nrow(s)))
  s <- s %>% filter(insample)
  cat(sprintf("SAMPLE:%s:exclude_balanced_corner=%d\n", name, nrow(s)))
  s$treat <- as.integer(s$cond == treat_cond)
  m <- feols(rel_mid ~ treat, data = s, vcov = "hetero")
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  list(const = unname(coef(m)["(Intercept)"]), diff = unname(coef(m)["treat"]),
       treat_mean = unname(coef(m)["(Intercept)"] + coef(m)["treat"]), n = nobs(m))
}
t3c1 <- run_pair("table3_col1", "Main-Treatment", "Mechanism-Treatment")
t3c2 <- run_pair("table3_col2", "Donation-Treatment", "Donation-Control")
t3c3 <- run_pair("table3_col3", "Main-Treatment", "Main-Control")
t3c4 <- run_pair("table3_col4", "Mechanism-Treatment", "Mechanism-Control")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", unname(coef(m_abs_mid)[1])))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", tob_coef))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", unname(coef(m_rel_low)[1])))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", unname(coef(m_rel_mid)[1])))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", unname(coef(m_rel_up)[1])))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m_rel_mid)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", t3c1$const))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", t3c1$diff))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", t3c2$treat_mean))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", t3c2$diff))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", t3c3$diff))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", t3c4$diff))
cat(sprintf("RESULT:n_obs_table3=%d\n", t3c1$n))
