suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(AER)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
df <- readr::read_csv(file.path(base, "Consumption Experiment/Stata/Consumption_Experiment.csv"),
                      show_col_types = FALSE, guess_max = 10000)
df <- as.data.frame(df)
n_loaded <- nrow(df)

has <- function(v) v %in% names(df)
num <- function(x) suppressWarnings(as.numeric(as.character(x)))

e_tasks <- c(129, 132, 143, 115, 121, 117, 135, 127)

## ---------------- condition coding ----------------
tr_raw <- df$treatment
if (has("treatment") && !is.numeric(tr_raw) && any(grepl("[A-Za-z]", tr_raw))) {
  s <- tolower(as.character(tr_raw))
  df$is_donation <- as.integer(grepl("donat|charit", s))
  df$is_mech <- as.integer(grepl("mech", s))
  df$is_control <- as.integer(grepl("control", s))
} else {
  df$is_donation <- if (has("pizza")) as.integer(num(df$pizza) == 0) else 0L
  if (has("main")) {
    m <- num(df$main)
    df$is_mech <- as.integer(!is.na(m) & m == 0 & df$is_donation == 0)
  } else df$is_mech <- 0L
  if (has("control")) {
    df$is_control <- as.integer(num(df$control) == 1)
  } else if (has("treatment")) {
    df$is_control <- as.integer(num(df$treatment) == 0)
  } else df$is_control <- 0L
}
df$is_donation[is.na(df$is_donation)] <- 0L
df$is_mech[is.na(df$is_mech)] <- 0L
df$is_control[is.na(df$is_control)] <- 0L
df$cond <- with(df, ifelse(is_donation == 1,
                           ifelse(is_control == 1, "Donation-Control", "Donation-Treatment"),
                    ifelse(is_mech == 1,
                           ifelse(is_control == 1, "Mechanism-Control", "Mechanism-Treatment"),
                           ifelse(is_control == 1, "Main-Control", "Main-Treatment"))))

## ---------------- subject-level sample restriction ----------------
df$sid <- if (has("tn")) df$tn else seq_len(nrow(df))
if (has("pap_sample")) {
  ps <- df %>% group_by(sid) %>% summarise(ps = max(num(pap_sample), na.rm = TRUE), .groups = "drop")
  keep_ids <- ps$sid[is.finite(ps$ps) & ps$ps == 1]
} else {
  bal <- if (has("dispersed")) df[num(df$dispersed) == 0 | is.na(df$dispersed), ] else df
  cc <- bal %>% group_by(sid) %>% summarise(anyc = max(num(corner), na.rm = TRUE), .groups = "drop")
  keep_ids <- cc$sid[!is.finite(cc$anyc) | cc$anyc == 0]
}

## ---------------- own relative measure (for column identification) ----------------
own_rel <- NULL
if (has("decision_number") && has("indifference_point") && has("dispersed")) {
  b <- df[!is.na(num(df$dispersed)) & num(df$dispersed) == 0, ]
  b$dn <- num(b$decision_number)
  b <- b[!is.na(b$dn) & b$dn >= 1 & b$dn <= 8, ]
  if (nrow(b) > 0) {
    b$x <- num(b$indifference_point)
    b$den <- e_tasks[b$dn] + b$x
    own_rel <- b %>% group_by(sid) %>%
      summarise(inv = if (n_distinct(dn) == 8) mean(1 / den) else NA_real_, .groups = "drop")
  }
}

## ---------------- collapse to subject level ----------------
first_nonmiss <- function(x) { y <- x[!is.na(x)]; if (length(y)) y[1] else NA }
subj_vars <- intersect(c("id_stage2", "id_stage2_upper", "avg_id_stage2",
                         "qe_ard", "qe_rad", "qe_ard_lower", "qe_rad_lower",
                         "qe_ard_upper", "qe_rad_upper", "cond", "session"), names(df))
sub <- df %>% group_by(sid) %>% summarise(across(all_of(subj_vars), first_nonmiss), .groups = "drop")
sub <- as.data.frame(sub)
for (v in setdiff(subj_vars, c("cond", "session"))) sub[[v]] <- num(sub[[v]])

sub$d_lower <- sub$id_stage2
sub$d_upper <- if ("id_stage2_upper" %in% names(sub)) sub$id_stage2_upper else sub$d_lower
sub$d_upper[is.na(sub$d_upper)] <- sub$d_lower[is.na(sub$d_upper)]
sub$d_mid <- if ("avg_id_stage2" %in% names(sub)) sub$avg_id_stage2 else (sub$d_lower + sub$d_upper) / 2
sub$d_mid[is.na(sub$d_mid)] <- ((sub$d_lower + sub$d_upper) / 2)[is.na(sub$d_mid)]

## identify which qe_* family is the relative measure
if (!is.null(own_rel)) sub <- left_join(sub, own_rel, by = "sid") else sub$inv <- NA_real_
sub$own_rel_lower <- sub$d_lower * sub$inv
sub$own_rel_mid <- sub$d_mid * sub$inv
sub$own_rel_upper <- sub$d_upper * sub$inv

score_family <- function(pre) {
  cols <- c(paste0(pre, "_lower"), pre, paste0(pre, "_upper"))
  if (!all(cols %in% names(sub))) return(Inf)
  mt <- sub$cond == "Main-Treatment" & sub$sid %in% keep_ids
  d <- c(abs(sub[[cols[1]]] - sub$own_rel_lower)[mt],
         abs(sub[[cols[2]]] - sub$own_rel_mid)[mt],
         abs(sub[[cols[3]]] - sub$own_rel_upper)[mt])
  if (all(is.na(d))) {
    # fallback: relative measure should be on a share scale (much smaller than d)
    v <- sub[[cols[2]]][mt]
    return(1e3 + mean(abs(v), na.rm = TRUE))
  }
  mean(d, na.rm = TRUE)
}
fams <- c("qe_rad", "qe_ard")
sc <- sapply(fams, score_family)
if (all(!is.finite(sc))) {
  sub$rel_lower <- sub$own_rel_lower; sub$rel_mid <- sub$own_rel_mid; sub$rel_upper <- sub$own_rel_upper
} else {
  f <- fams[which.min(sc)]
  sub$rel_lower <- sub[[paste0(f, "_lower")]]
  sub$rel_mid <- sub[[f]]
  sub$rel_upper <- sub[[paste0(f, "_upper")]]
  # fill any gaps with own computation
  sub$rel_lower[is.na(sub$rel_lower)] <- sub$own_rel_lower[is.na(sub$rel_lower)]
  sub$rel_mid[is.na(sub$rel_mid)] <- sub$own_rel_mid[is.na(sub$rel_mid)]
  sub$rel_upper[is.na(sub$rel_upper)] <- sub$own_rel_upper[is.na(sub$rel_upper)]
}

## ---------------- Table 2: Main-Treatment ----------------
cat(sprintf("SAMPLE:table2:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:table2:collapse_to_subjects=%d\n", nrow(sub)))
t2 <- sub[sub$cond == "Main-Treatment", ]
cat(sprintf("SAMPLE:table2:main_treatment=%d\n", nrow(t2)))
t2 <- t2[t2$sid %in% keep_ids, ]
cat(sprintf("SAMPLE:table2:exclude_balanced_corner=%d\n", nrow(t2)))

m_dmid <- feols(d_mid ~ 1, data = t2, vcov = "hetero")
m_rl <- feols(rel_lower ~ 1, data = t2, vcov = "hetero")
m_rm <- feols(rel_mid ~ 1, data = t2, vcov = "hetero")
m_ru <- feols(rel_upper ~ 1, data = t2, vcov = "hetero")
lo <- min(-63, min(t2$d_lower, na.rm = TRUE))
lo <- -63
m_tob <- AER::tobit(d_lower ~ 1, left = lo, right = 62, data = t2[!is.na(t2$d_lower), ])
cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m_rm)))

## ---------------- Table 3 ----------------
t3_sample <- function(name, c1, c0) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, n_loaded))
  cat(sprintf("SAMPLE:%s:collapse_to_subjects=%d\n", name, nrow(sub)))
  s <- sub[sub$cond %in% c(c1, c0), ]
  cat(sprintf("SAMPLE:%s:conditions=%d\n", name, nrow(s)))
  s <- s[s$sid %in% keep_ids, ]
  cat(sprintf("SAMPLE:%s:exclude_balanced_corner=%d\n", name, nrow(s)))
  s$ind <- as.integer(s$cond == c1)
  m <- feols(rel_mid ~ ind, data = s, vcov = "hetero")
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  m
}
m31 <- t3_sample("table3_col1", "Main-Treatment", "Mechanism-Treatment")
m32 <- t3_sample("table3_col2", "Donation-Treatment", "Donation-Control")
m33 <- t3_sample("table3_col3", "Main-Treatment", "Main-Control")
m34 <- t3_sample("table3_col4", "Mechanism-Treatment", "Mechanism-Control")

## ---------------- Results ----------------
pr <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(v)))
pr("abs_concentration_bias_midpoint_table2_col2", coef(m_dmid)[1])
pr("abs_concentration_bias_tobit_table2_col4", coef(m_tob)[1])
pr("rel_concentration_bias_lower_table2_col1", coef(m_rl)[1])
pr("rel_concentration_bias_midpoint_table2_col2", coef(m_rm)[1])
pr("rel_concentration_bias_upper_table2_col3", coef(m_ru)[1])
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m_rm)))
pr("rel_cb_mechanism_treatment_table3_col1", coef(m31)["(Intercept)"])
pr("diff_main_minus_mechanism_table3_col1", coef(m31)["ind"])
pr("rel_cb_donation_treatment_table3_col2", coef(m32)["(Intercept)"] + coef(m32)["ind"])
pr("diff_donation_treatment_minus_control_table3_col2", coef(m32)["ind"])
pr("diff_main_treatment_minus_control_table3_col3", coef(m33)["ind"])
pr("diff_mechanism_treatment_minus_control_table3_col4", coef(m34)["ind"])
cat(sprintf("RESULT:n_obs_table3=%d\n", nobs(m31)))
