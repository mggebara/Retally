suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
load(path)
s <- as.data.frame(s)
nm <- names(s)
cat("Rows in s:", nrow(s), "\n")

show_matches <- function(p) {
  m <- grep(p, nm, value = TRUE, ignore.case = TRUE)
  cat("[", p, "]: ", paste(head(m, 40), collapse = ", "), "\n", sep = "")
}
for (p in c("simul", "gagn", "winn", "approb", "accept", "cible", "target", "efficac",
            "effect", "info", "gilet", "yellow", "revenu", "income", "weight", "poids",
            "modif", "variante", "single", "percentile", "progress", "feedback")) show_matches(p)

fv <- function(cands, pat = NULL) {
  for (c in cands) if (c %in% nm) return(c)
  if (!is.null(pat)) {
    m <- grep(pat, nm, value = TRUE, ignore.case = TRUE)
    if (length(m)) return(m[1])
  }
  NA_character_
}

# Strip S4 (memisc) class information without triggering S4 dispatch / class lookup
strip <- function(z) {
  if (is.null(z)) return(NULL)
  if (isS4(z)) z <- asS4(z, FALSE, complete = FALSE)
  attributes(z) <- NULL
  z
}

clean <- function(x) {
  if (isS4(x)) {
    vl <- tryCatch(attr(x, "value.labels"), error = function(e) NULL)
    codes <- strip(x)
    if (!is.null(vl)) {
      labs <- tryCatch(as.character(strip(vl)), error = function(e) character(0))
      vals <- tryCatch(strip(attr(vl, "values")), error = function(e) NULL)
      if (length(labs) > 0 && length(labs) == length(vals)) {
        nn <- codes[!is.na(codes)]
        if (length(nn) && all(nn %in% vals)) return(trimws(labs[match(codes, vals)]))
      }
    }
    if (is.character(codes)) return(trimws(codes))
    if (is.logical(codes)) return(as.numeric(codes))
    if (is.numeric(codes)) return(codes)
    return(trimws(as.character(codes)))
  }
  if (is.factor(x)) return(trimws(as.character(x)))
  if (is.character(x)) return(trimws(x))
  if (is.logical(x)) return(as.numeric(x))
  y <- x
  attributes(y) <- NULL
  if (is.numeric(y)) return(y)
  if (is.logical(y)) return(as.numeric(y))
  trimws(as.character(y))
}

getv <- function(v) if (is.na(v)) rep(NA, nrow(s)) else clean(s[[v]])

is01 <- function(x) all(na.omit(unique(x)) %in% c(0, 1))

notlose <- function(x) {
  if (is.numeric(x)) return(ifelse(is.na(x), NA, as.numeric(x >= 0)))
  l <- tolower(x)
  ifelse(is.na(x) | x == "", NA, as.numeric(!grepl("perdant|los", l)))
}
wins <- function(x) {
  if (is.numeric(x)) return(ifelse(is.na(x), NA, as.numeric(x > 0)))
  l <- tolower(x)
  ifelse(is.na(x) | x == "", NA,
         as.numeric(grepl("gagnant|win|gagne", l) & !grepl("^non|not|los|perd", l)))
}
yes <- function(x) {
  if (is.numeric(x)) {
    if (is01(x)) return(x)
    return(ifelse(is.na(x), NA, as.numeric(x > 0)))
  }
  l <- tolower(x)
  ifelse(is.na(x) | x == "", NA,
         as.numeric(grepl("^oui|^yes|^true$|^1$", l)))
}
notno <- function(x) {
  if (is.numeric(x)) {
    if (is01(x)) return(x)
    return(ifelse(is.na(x), NA, as.numeric(x >= 0)))
  }
  l <- tolower(x)
  ifelse(is.na(x) | x == "", NA, as.numeric(!grepl("^non$|^no$|^false$", l)))
}

# ---------------- variables ----------------
v_w      <- fv(c("weight", "poids", "weights"))
v_sg     <- fv(c("simule_gain", "simulated_gain", "gain_simule", "estimated_gain", "simule_gain_uc"))
v_pw     <- fv(c("simule_gagnant", "predicted_winner", "simulated_winner"))
v_cat0   <- fv(c("gagnant_categorie", "winning_category"))
v_catf   <- fv(c("gagnant_feedback_categorie", "winning_feedback_category"), "feedback_categ")
v_var    <- fv(c("variante_taxe_info"))
v_appr   <- fv(c("taxe_approbation", "tax_approval"))
v_acc    <- fv(c("tax_acceptance", "taxe_acceptation", "taxe_acceptance"))
v_gj     <- fv(c("Gilets_jaunes", "gilets_jaunes", "yellow_vests", "Yellow_vests"))
v_eff    <- fv(c("taxe_efficace", "tax_effective", "effective"), "efficace")
v_prog   <- fv(c("progressivite", "taxe_progressive", "progressivity"), "progressiv")
v_cappr  <- fv(c("taxe_cible_approbation", "targeted_tax_approval"), "cible.*approbation")
v_ccat   <- fv(c("gagnant_cible_categorie", "winning_targeted_category"), "cible.*categorie")
v_tc     <- fv(c("traite_cible", "eligible", "treated_target"))
v_tcc    <- fv(c("traite_cible_conjoint", "eligible_conjoint", "treated_target_spouse"))
v_cible  <- fv(c("cible", "target", "threshold"))
v_single <- fv(c("single", "seul"))
v_sci    <- fv(c("apres_modifs", "info_efficacite", "info_scientists", "info_science"), "modif")
v_cc     <- fv(c("info_CC", "info_cc", "info_climate"))
v_pct    <- fv(c("percentile_revenu", "income_percentile"))
v_pctc   <- fv(c("percentile_revenu_conjoint", "income_percentile_conjoint"))
v_rev    <- fv(c("revenu", "income"))
v_revc   <- fv(c("revenu_conjoint", "rev_conjoint"))
v_revt   <- fv(c("rev_tot", "revenu_tot", "household_income"))

cat("Resolved:", paste(c(w = v_w, sg = v_sg, pw = v_pw, cat0 = v_cat0, catf = v_catf, var = v_var,
                          appr = v_appr, acc = v_acc, gj = v_gj, eff = v_eff, prog = v_prog,
                          cappr = v_cappr, ccat = v_ccat, tc = v_tc, tcc = v_tcc, cible = v_cible,
                          single = v_single, sci = v_sci, cc = v_cc, pct = v_pct, pctc = v_pctc,
                          rev = v_rev, revc = v_revc, revt = v_revt), collapse = " | "), "\n")

d <- data.frame(row = seq_len(nrow(s)))
d$w <- if (is.na(v_w)) 1 else suppressWarnings(as.numeric(getv(v_w)))
d$w[is.na(d$w)] <- NA

d$sg  <- suppressWarnings(as.numeric(getv(v_sg)))
d$sg2 <- d$sg^2
d$pw  <- if (!is.na(v_pw)) {
  pwr <- getv(v_pw)
  if (is.character(pwr) && any(grepl("gagn|win", tolower(pwr)))) wins(pwr) else yes(pwr)
} else as.numeric(d$sg > 0)
if (all(is.na(d$pw)) || length(unique(na.omit(d$pw))) < 2) d$pw <- as.numeric(d$sg > 0)

cat0 <- getv(v_cat0)
d$g0   <- notlose(cat0)
d$cat0 <- as.character(cat0)
catf <- getv(v_catf)
d$y_nl <- notlose(catf)
d$y_w  <- wins(catf)

if (!is.na(v_acc)) {
  d$acc0 <- notno(getv(v_acc))
} else {
  d$acc0 <- notno(getv(v_appr))
}
d$appr0 <- yes(getv(v_appr))

gj <- getv(v_gj)
if (is.numeric(gj)) {
  d$yv <- ifelse(is.na(gj), NA, as.numeric(gj >= 1))
} else {
  d$yv <- ifelse(is.na(gj) | gj == "", NA,
                 as.numeric(grepl("soutien|dedans|support|part", tolower(gj))))
}
# fall back to dummy columns if available
if (all(is.na(d$yv)) || sum(d$yv, na.rm = TRUE) == 0) {
  a <- fv(c("gilets_jaunes_soutien")); b <- fv(c("gilets_jaunes_dedans"))
  if (!is.na(a)) d$yv <- pmax(yes(getv(a)), if (!is.na(b)) yes(getv(b)) else 0, na.rm = TRUE)
}

d$eff  <- yes(getv(v_eff))
d$prog <- yes(getv(v_prog))

# feedback subset
fb <- rep(FALSE, nrow(s))
if (!is.na(v_var)) fb <- getv(v_var) %in% c("f", "F")
if (sum(fb) < 1000 || sum(fb) > 2600) fb <- !is.na(d$y_nl)
fb <- fb & !is.na(d$y_nl)
cat("Feedback subsample:", sum(fb), "\n")
d$fb <- fb

# controls
bad_pat <- "approb|gagnant|gain|gilet|taxe|tax_|winning|accept|efficac|progress|cible|feedback|info|variante"
demo_c <- character(0)
if (exists("variables_demo") && is.character(variables_demo)) {
  demo_c <- intersect(variables_demo, nm)
  demo_c <- demo_c[!grepl(bad_pat, demo_c, ignore.case = TRUE)]
}
if (length(demo_c) < 3) {
  demo_c <- intersect(c("sexe", "age", "diplome4", "statut_emploi", "csp", "region",
                        "taille_agglo", "taille_menage", "nb_14_et_plus"), nm)
}
cat("Demo controls:", paste(demo_c, collapse = ", "), "\n")
ctrl_names <- character(0)
for (i in seq_along(demo_c)) {
  x <- clean(s[[demo_c[i]]])
  if (length(unique(na.omit(x))) < 2) next
  nmc <- paste0("c_", i)
  if (is.character(x)) x[is.na(x) | x == ""] <- "missing"
  d[[nmc]] <- x
  ctrl_names <- c(ctrl_names, nmc)
}
inc_names <- character(0)
for (v in unique(na.omit(c(v_rev, v_revt)))) {
  x <- suppressWarnings(as.numeric(clean(s[[v]])))
  if (all(is.na(x))) next
  n1 <- paste0("inc_", make.names(v)); n2 <- paste0(n1, "_sq")
  d[[n1]] <- x; d[[n2]] <- x^2
  inc_names <- c(inc_names, n1, n2)
}
mot_names <- character(0)
if (!all(is.na(d$eff))) mot_names <- c(mot_names, "eff")
if (!all(is.na(d$prog))) mot_names <- c(mot_names, "prog")

# replace NA in controls (numeric) with mean + flag to avoid sample loss
fix_na <- function(vars) {
  for (v in vars) {
    if (is.numeric(d[[v]]) && any(is.na(d[[v]]))) {
      d[[paste0(v, "_na")]] <<- as.numeric(is.na(d[[v]]))
      d[[v]][is.na(d[[v]])] <<- mean(d[[v]], na.rm = TRUE)
    }
  }
}
fix_na(c(ctrl_names, inc_names, mot_names))
na_flags <- grep("_na$", names(d), value = TRUE)
na_flags <- na_flags[sapply(na_flags, function(v) length(unique(d[[v]])) > 1)]

all_ctrls <- c(ctrl_names, inc_names, mot_names, na_flags)
ctrl_str <- if (length(all_ctrls)) paste("+", paste(all_ctrls, collapse = " + ")) else ""

res <- list()
getc <- function(m, nmv) {
  cf <- coef(m)
  if (nmv %in% names(cf)) unname(cf[nmv]) else NA_real_
}

# ---------------- Table 4 ----------------
d4 <- d[d$fb & !is.na(d$w), ]
d4_50 <- d4[!is.na(d4$sg) & abs(d4$sg) < 50, ]
cat("Table4 col1 sample:", nrow(d4_50), "\n")

tryCatch({
  f1 <- as.formula(paste("y_nl ~ pw + sg + sg2 + acc0", ctrl_str))
  m1 <- feols(f1, data = d4_50, weights = ~w, vcov = "hetero")
  print(coeftable(m1)[1:4, ])
  res$predicted_winner_believes_not_lose_table4_col1 <- getc(m1, "pw")
  res$initial_acceptance_believes_not_lose_table4_col1 <- getc(m1, "acc0")
  res$n_obs_table4_col1 <- nobs(m1)
}, error = function(e) cat("T4c1 error:", conditionMessage(e), "\n"))

tryCatch({
  f2 <- as.formula(paste("y_nl ~ pw + sg + sg2 + acc0", ctrl_str))
  m2 <- feols(f2, data = d4, weights = ~w, vcov = "hetero")
  res$predicted_winner_believes_not_lose_full_sample_table4_col2 <- getc(m2, "pw")
}, error = function(e) cat("T4c2 error:", conditionMessage(e), "\n"))

tryCatch({
  d4_50$pw_acc <- d4_50$pw * d4_50$acc0
  d4_50$pw_yv  <- d4_50$pw * d4_50$yv
  d4_50$pw_g0  <- d4_50$pw * d4_50$g0
  f3 <- as.formula(paste("y_nl ~ pw + acc0 + yv + g0 + pw_acc + pw_yv + pw_g0 + sg + sg2 + i(cat0)", ctrl_str))
  m3 <- tryCatch(feols(f3, data = d4_50, weights = ~w, vcov = "hetero"),
                 error = function(e) {
                   f3b <- as.formula(paste("y_nl ~ pw + acc0 + yv + g0 + pw_acc + pw_yv + pw_g0 + sg + sg2", ctrl_str))
                   feols(f3b, data = d4_50, weights = ~w, vcov = "hetero")
                 })
  print(coeftable(m3)[1:8, ])
  res$predicted_winner_heterogeneity_table4_col3 <- getc(m3, "pw")
  res$initial_acceptance_heterogeneity_table4_col3 <- getc(m3, "acc0")
  res$yellow_vests_supporter_heterogeneity_table4_col3 <- getc(m3, "yv")
  res$winner_x_initial_acceptance_table4_col3 <- getc(m3, "pw_acc")
  res$winner_x_yellow_vests_supporter_table4_col3 <- getc(m3, "pw_yv")
  res$winner_x_initial_win_belief_table4_col3 <- getc(m3, "pw_g0")
}, error = function(e) cat("T4c3 error:", conditionMessage(e), "\n"))

tryCatch({
  f4 <- as.formula(paste("y_w ~ pw + sg + sg2 + acc0", ctrl_str))
  m4 <- feols(f4, data = d4_50, weights = ~w, vcov = "hetero")
  res$predicted_winner_believes_wins_table4_col4 <- getc(m4, "pw")
}, error = function(e) cat("T4c4 error:", conditionMessage(e), "\n"))

# ---------------- Table 6 ----------------
tryCatch({
  d6 <- d
  d6$y6 <- notno(getv(v_cappr))
  d6$x6 <- notlose(getv(v_ccat))
  tc  <- yes(getv(v_tc));  tc[is.na(tc)] <- 0
  tcc <- if (!is.na(v_tcc)) yes(getv(v_tcc)) else rep(0, nrow(s)); tcc[is.na(tcc)] <- 0
  d6$tc <- tc; d6$tcc <- tcc; d6$tc_tcc <- tc * tcc
  d6$cible <- as.character(getv(v_cible))
  d6$single <- if (!is.na(v_single)) as.numeric(yes(getv(v_single))) else 0
  inc6 <- character(0)
  for (v in unique(na.omit(c(v_pct, v_pctc)))) {
    x <- suppressWarnings(as.numeric(clean(s[[v]]))); if (all(is.na(x))) next
    x[is.na(x)] <- 0
    n1 <- paste0("p_", make.names(v)); n2 <- paste0(n1, "_sq"); n3 <- paste0(n1, "_cu")
    d6[[n1]] <- x; d6[[n2]] <- x^2; d6[[n3]] <- x^3
    inc6 <- c(inc6, n1, n2, n3)
  }
  if (length(inc6) == 0) {
    for (v in unique(na.omit(c(v_rev, v_revc)))) {
      x <- suppressWarnings(as.numeric(clean(s[[v]]))); if (all(is.na(x))) next
      x[is.na(x)] <- 0
      n1 <- paste0("r_", make.names(v)); n2 <- paste0(n1, "_sq")
      d6[[n1]] <- x; d6[[n2]] <- x^2
      inc6 <- c(inc6, n1, n2)
    }
  }
  c6 <- c("acc0", if (length(unique(na.omit(d6$single))) > 1) "single", inc6)
  fe6 <- if (length(unique(na.omit(d6$cible))) > 1) "| cible" else ""
  f6 <- as.formula(paste("y6 ~", paste(c6, collapse = " + "), fe6, "| x6 ~ tc + tcc + tc_tcc"))
  d6 <- d6[!is.na(d6$w), ]
  m6 <- feols(f6, data = d6, weights = ~w, vcov = "hetero")
  print(summary(m6, stage = 1))
  print(coeftable(m6)[1:3, ])
  res$believes_not_lose_on_acceptance_iv_table6_col1 <- getc(m6, "fit_x6")
}, error = function(e) cat("T6 error:", conditionMessage(e), "\n"))

# ---------------- Table 8 ----------------
tryCatch({
  d8 <- d
  d8$y8 <- d8$appr0
  d8$x8 <- d8$eff
  d8$z_sci <- yes(getv(v_sci))
  d8$z_cc  <- yes(getv(v_cc))
  if (all(is.na(d8$z_cc)) && !is.na(v_var)) {
    vv <- tolower(getv(v_var))
    d8$z_cc <- as.numeric(grepl("cc", vv))
  }
  sg8 <- d8$sg; d8$sg_na8 <- as.numeric(is.na(sg8)); sg8[is.na(sg8)] <- mean(sg8, na.rm = TRUE)
  d8$sg8 <- sg8
  c8 <- c(ctrl_names, inc_names, "sg8", if (sum(d8$sg_na8) > 0) "sg_na8",
          if (!all(is.na(d8$prog))) "prog", "g0")
  c8 <- c(c8, intersect(na_flags, paste0(c(ctrl_names, inc_names), "_na")))
  if ("prog_na" %in% na_flags) c8 <- c(c8, "prog_na")
  f8 <- as.formula(paste("y8 ~", paste(c8, collapse = " + "), "| x8 ~ z_sci + z_cc"))
  d8 <- d8[!is.na(d8$w), ]
  m8 <- feols(f8, data = d8, weights = ~w, vcov = "hetero")
  print(summary(m8, stage = 1))
  res$believes_effective_on_approval_iv_table8_col1 <- getc(m8, "fit_x8")
}, error = function(e) cat("T8 error:", conditionMessage(e), "\n"))

# ---------------- output ----------------
out_names <- c("predicted_winner_believes_not_lose_table4_col1",
               "initial_acceptance_believes_not_lose_table4_col1",
               "predicted_winner_believes_not_lose_full_sample_table4_col2",
               "predicted_winner_heterogeneity_table4_col3",
               "initial_acceptance_heterogeneity_table4_col3",
               "yellow_vests_supporter_heterogeneity_table4_col3",
               "winner_x_initial_acceptance_table4_col3",
               "winner_x_yellow_vests_supporter_table4_col3",
               "winner_x_initial_win_belief_table4_col3",
               "predicted_winner_believes_wins_table4_col4",
               "n_obs_table4_col1",
               "believes_not_lose_on_acceptance_iv_table6_col1",
               "believes_effective_on_approval_iv_table8_col1")
for (n in out_names) {
  v <- res[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(round(v, 6), scientific = FALSE))))
}
